import "@stdlib/deploy";
import "./nft_messages.tact";
import "./timestamped_jetton.tact";

// ==================== Messages ====================

message Purchase {
    nftAddress: Address;
}

message CancelListing {
    nftAddress: Address;
}

message ClaimRefund {
    nftAddress: Address;
}

message MarketplaceWithdraw {
    destination: Address;
}

message SetFeePercentage {
    newFee: Int as uint8;
}

message AdminReturnNft {
    nftAddress: Address;
    to: Address;
}

// ==================== Structs ====================

struct ListingInfo {
    exists: Bool;
    price: Int;
    seller: Address;
}

struct PendingPurchaseInfo {
    exists: Bool;
    buyer: Address;
    payment: Int;
    startTime: Int;
    refundStarted: Bool;
}

struct MarketplaceData {
    owner: Address;
    collectionAddress: Address;
    feePercentage: Int;
    listingCount: Int;
    pendingCount: Int;
    balance: Int;
}

const LISTING_OP: Int = 0xA5A5A5A5;

const PURCHASE_QID_FLAG: Int  = 0;
const REFUND_QID_FLAG: Int    = (1 << 32);

// ==================== NftMarketplace Contract ====================
//
// TEP-62 compliant two-phase purchase:
//   - NftOwnershipAssigned (0x05138d91) → sent to new_owner → used for LISTING
//   - NftExcesses (0xd53276db) → sent to responseDestination → used for PURCHASE CONFIRMATION
//   - bounced<NftTransfer> → used for PURCHASE FAILURE / REFUND PROBE
//
// Gas flows via SendRemainingValue through the entire message chain.
// Fair ClaimRefund probes NFT ownership to determine who gets the money.

contract NftMarketplace with Deployable {
    owner: Address;
    collectionAddress: Address;
    feePercentage: Int as uint8;

    prices:      map<Address, Int>;
    sellers:     map<Address, Address>;
    nftIndexes:  map<Address, Int>;
    listingFees: map<Address, Int>;

    pendingBuyers:   map<Address, Address>;
    pendingPayments: map<Address, Int>;
    pendingTimes:    map<Address, Int>;
    refundStarted:   map<Address, Bool>;

    nextQueryId: Int as uint64;
    queryToNft:  map<Int, Address>;

    listingCount: Int as uint32;
    pendingCount: Int as uint32;

    const MIN_GAS_FOR_PURCHASE: Int = ton("0.15");
    const NFT_TRANSFER_GAS: Int     = ton("0.1");
    const MIN_LISTING_PRICE: Int    = ton("0.1");
    const PURCHASE_TIMEOUT: Int     = 3600;

    init(owner: Address, collectionAddress: Address, feePercentage: Int) {
        require(feePercentage >= 0 && feePercentage <= 50, "FEE_OUT_OF_RANGE");
        self.owner = owner;
        self.collectionAddress = collectionAddress;
        self.feePercentage = feePercentage;
        self.prices = emptyMap();
        self.sellers = emptyMap();
        self.nftIndexes = emptyMap();
        self.listingFees = emptyMap();
        self.pendingBuyers = emptyMap();
        self.pendingPayments = emptyMap();
        self.pendingTimes = emptyMap();
        self.refundStarted = emptyMap();
        self.queryToNft = emptyMap();
        self.nextQueryId = 1;
        self.listingCount = 0;
        self.pendingCount = 0;
    }

    // ==================== Listing: NftOwnershipAssigned (TEP-62) ====================
    //
    // Per TEP-62: ownership_assigned is sent to new_owner when forward_amount > 0.
    // When seller lists NFT: new_owner = marketplace → we receive this.
    //
    // Also handles refund probe success (marketplace tried NftTransfer to seller,
    // and it succeeded → NftOwnershipAssigned comes to marketplace as the new callback).

    receive(msg: NftOwnershipAssigned) {
        let nftAddress: Address = sender();

        // --- Refund probe success: marketplace owned NFT, now seller got it back ---
        let refundFlag: Bool? = self.refundStarted.get(nftAddress);
        if (refundFlag != null && refundFlag == true) {
            self._completeRefundNftReturned(nftAddress);
            return;
        }

        // --- Listing request ---
        let sellerAddress: Address = msg.previousOwner;
        let payload: Slice = msg.forwardPayload;

        if (payload.bits() < 32) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }
        let op: Int = payload.loadUint(32);

        if (op != LISTING_OP) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }

        if (payload.bits() < 4 + 64) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }
        let price: Int = payload.loadCoins();
        let nftIndex: Int = payload.loadUint(64);

        // Require transferType in payload; reject non-transferable NFTs
        if (payload.bits() < 8) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }
        let transferType: Int = payload.loadUint(8);
        if (transferType != 0) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }

        if (price < self.MIN_LISTING_PRICE) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }

        let expectedAddr: Address = contractAddress(initOf TimestampedJetton(self.collectionAddress, nftIndex));
        if (nftAddress != expectedAddr) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }

        let existingPrice: Int? = self.prices.get(nftAddress);
        if (existingPrice != null) {
            self._returnNft(nftAddress, sellerAddress);
            return;
        }

        self.prices.set(nftAddress, price);
        self.sellers.set(nftAddress, sellerAddress);
        self.nftIndexes.set(nftAddress, nftIndex);
        self.listingFees.set(nftAddress, self.feePercentage);
        self.listingCount = self.listingCount + 1;
    }

    // ==================== Purchase confirmation: NftExcesses (TEP-62) ====================
    //
    // Per TEP-62: excesses (0xd53276db) is sent to responseDestination.
    // In Purchase, we set responseDestination = myAddress() → this confirms NFT transfer.
    // sender() = NFT address. msg.queryId matches our purchase queryId.

    receive(msg: NftExcesses) {
        let qid: Int = msg.queryId;
        let nftOpt: Address? = self.queryToNft.get(qid);
        if (nftOpt == null) { return; }
        let nftAddress: Address = nftOpt!!;

        // Verify sender is the NFT contract
        if (sender() != nftAddress) { return; }

        let pendingBuyer: Address? = self.pendingBuyers.get(nftAddress);
        if (pendingBuyer == null) { return; }

        self.queryToNft.set(qid, null);
        self._completePurchase(nftAddress);
    }

    // ==================== Purchase (Phase 1): Hold funds, send NftTransfer ====================
    //
    // Gas flow: buyer → marketplace → NftTransfer (SendRemainingValue) →
    //           NFT → NftExcesses (to responseDestination=marketplace) → _completePurchase

    receive(msg: Purchase) {
        let nftAddress: Address = msg.nftAddress;
        let buyer: Address = sender();

        let priceOpt: Int? = self.prices.get(nftAddress);
        require(priceOpt != null, "NOT_LISTED");
        let price: Int = priceOpt!!;

        require(self.pendingBuyers.get(nftAddress) == null, "PURCHASE_IN_PROGRESS");

        let msgValue: Int = context().value;
        require(msgValue >= price + self.MIN_GAS_FOR_PURCHASE, "INSUFFICIENT_PAYMENT");

        let qid: Int = self.nextQueryId + PURCHASE_QID_FLAG;
        self.nextQueryId = self.nextQueryId + 1;

        self.pendingBuyers.set(nftAddress, buyer);
        self.pendingPayments.set(nftAddress, msgValue);
        self.pendingTimes.set(nftAddress, now());
        self.queryToNft.set(qid, nftAddress);
        self.pendingCount = self.pendingCount + 1;

        // Forward ALL remaining gas. forwardAmount=0 means no NftOwnershipAssigned to buyer.
        // NftExcesses will come back to us (responseDestination=myAddress) with remaining gas.
        send(SendParameters{
            to: nftAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: NftTransfer{
                queryId: qid,
                newOwner: buyer,
                responseDestination: myAddress(),
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
            }.toCell()
        });
    }

    // ==================== Purchase (Phase 2): pay seller ====================

    fun _completePurchase(nftAddress: Address) {
        let buyer: Address = self.pendingBuyers.get(nftAddress)!!;
        let payment: Int = self.pendingPayments.get(nftAddress)!!;
        let price: Int = self.prices.get(nftAddress)!!;
        let seller: Address = self.sellers.get(nftAddress)!!;
        let feePercent: Int = self.listingFees.get(nftAddress)!!;

        let fee: Int = (price * feePercent) / 100;
        let sellerPayment: Int = price - fee;

        self.prices.set(nftAddress, null);
        self.sellers.set(nftAddress, null);
        self.nftIndexes.set(nftAddress, null);
        self.listingFees.set(nftAddress, null);
        self.pendingBuyers.set(nftAddress, null);
        self.pendingPayments.set(nftAddress, null);
        self.pendingTimes.set(nftAddress, null);
        self.refundStarted.set(nftAddress, null);
        self.listingCount = self.listingCount - 1;
        self.pendingCount = self.pendingCount - 1;

        send(SendParameters{
            to: seller,
            value: sellerPayment,
            mode: SendPayGasSeparately + SendIgnoreErrors,
            bounce: false,
            body: "Marketplace sale".asComment()
        });

        let excess: Int = payment - price;
        if (excess > ton("0.01")) {
            send(SendParameters{
                to: buyer,
                value: excess,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: "Purchase change".asComment()
            });
        }
    }

    // ==================== Bounce handler ====================

    bounced(msg: bounced<NftTransfer>) {
        let qid: Int = msg.queryId;
        let nftOpt: Address? = self.queryToNft.get(qid);
        if (nftOpt == null) { return; }
        let nftAddress: Address = nftOpt!!;

        let buyerOpt: Address? = self.pendingBuyers.get(nftAddress);
        if (buyerOpt == null) { return; }

        self.queryToNft.set(qid, null);

        if (qid >= REFUND_QID_FLAG) {
            // Refund probe bounced → marketplace doesn't own NFT → buyer has it → pay seller
            self._completeRefundNftGone(nftAddress);
        } else {
            // Purchase NftTransfer bounced → refund buyer
            let buyer: Address = buyerOpt!!;
            let payment: Int = self.pendingPayments.get(nftAddress)!!;

            self.pendingBuyers.set(nftAddress, null);
            self.pendingPayments.set(nftAddress, null);
            self.pendingTimes.set(nftAddress, null);
            self.refundStarted.set(nftAddress, null);
            self.pendingCount = self.pendingCount - 1;

            send(SendParameters{
                to: buyer,
                value: payment,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: "Purchase failed - refund".asComment()
            });
        }
    }

    // ==================== ClaimRefund: fair two-step resolution ====================

    receive(msg: ClaimRefund) {
        let nftAddress: Address = msg.nftAddress;

        let buyerOpt: Address? = self.pendingBuyers.get(nftAddress);
        require(buyerOpt != null, "NO_PENDING");

        let startTime: Int = self.pendingTimes.get(nftAddress)!!;
        require(now() - startTime > self.PURCHASE_TIMEOUT, "TOO_EARLY");

        let refundFlag: Bool? = self.refundStarted.get(nftAddress);
        require(refundFlag == null || refundFlag == false, "REFUND_ALREADY_STARTED");

        let sellerOpt: Address? = self.sellers.get(nftAddress);
        require(sellerOpt != null, "NO_SELLER");
        let seller: Address = sellerOpt!!;

        let qid: Int = self.nextQueryId + REFUND_QID_FLAG;
        self.nextQueryId = self.nextQueryId + 1;

        self.refundStarted.set(nftAddress, true);
        self.queryToNft.set(qid, nftAddress);

        send(SendParameters{
            to: nftAddress,
            value: self.NFT_TRANSFER_GAS,
            mode: SendPayGasSeparately,
            bounce: true,
            body: NftTransfer{
                queryId: qid,
                newOwner: seller,
                responseDestination: myAddress(),
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
            }.toCell()
        });
    }

    // Refund probe succeeded: NFT returned to seller → refund buyer
    fun _completeRefundNftReturned(nftAddress: Address) {
        let buyer: Address = self.pendingBuyers.get(nftAddress)!!;
        let payment: Int = self.pendingPayments.get(nftAddress)!!;

        self.prices.set(nftAddress, null);
        self.sellers.set(nftAddress, null);
        self.nftIndexes.set(nftAddress, null);
        self.listingFees.set(nftAddress, null);
        self.pendingBuyers.set(nftAddress, null);
        self.pendingPayments.set(nftAddress, null);
        self.pendingTimes.set(nftAddress, null);
        self.refundStarted.set(nftAddress, null);
        self.listingCount = self.listingCount - 1;
        self.pendingCount = self.pendingCount - 1;

        send(SendParameters{
            to: buyer,
            value: payment,
            mode: SendPayGasSeparately + SendIgnoreErrors,
            bounce: false,
            body: "Purchase timeout refund".asComment()
        });
    }

    // Refund probe bounced: buyer already has NFT → pay seller
    fun _completeRefundNftGone(nftAddress: Address) {
        let payment: Int = self.pendingPayments.get(nftAddress)!!;
        let price: Int = self.prices.get(nftAddress)!!;
        let seller: Address = self.sellers.get(nftAddress)!!;
        let buyer: Address = self.pendingBuyers.get(nftAddress)!!;
        let feePercent: Int = self.listingFees.get(nftAddress)!!;

        let fee: Int = (price * feePercent) / 100;
        let sellerPayment: Int = price - fee;

        self.prices.set(nftAddress, null);
        self.sellers.set(nftAddress, null);
        self.nftIndexes.set(nftAddress, null);
        self.listingFees.set(nftAddress, null);
        self.pendingBuyers.set(nftAddress, null);
        self.pendingPayments.set(nftAddress, null);
        self.pendingTimes.set(nftAddress, null);
        self.refundStarted.set(nftAddress, null);
        self.listingCount = self.listingCount - 1;
        self.pendingCount = self.pendingCount - 1;

        send(SendParameters{
            to: seller,
            value: sellerPayment,
            mode: SendPayGasSeparately + SendIgnoreErrors,
            bounce: false,
            body: "Marketplace sale (resolved)".asComment()
        });

        let excess: Int = payment - price;
        if (excess > ton("0.01")) {
            send(SendParameters{
                to: buyer,
                value: excess,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: "Purchase change".asComment()
            });
        }
    }

    // ==================== Cancel Listing ====================

    receive(msg: CancelListing) {
        let nftAddress: Address = msg.nftAddress;
        let callerAddress: Address = sender();

        let sellerOpt: Address? = self.sellers.get(nftAddress);
        require(sellerOpt != null, "NOT_LISTED");
        let sellerAddr: Address = sellerOpt!!;
        require(callerAddress == sellerAddr, "NOT_SELLER");

        require(self.pendingBuyers.get(nftAddress) == null, "PURCHASE_IN_PROGRESS");

        self.prices.set(nftAddress, null);
        self.sellers.set(nftAddress, null);
        self.nftIndexes.set(nftAddress, null);
        self.listingFees.set(nftAddress, null);
        self.listingCount = self.listingCount - 1;

        self._returnNft(nftAddress, sellerAddr);
    }

    // ==================== Admin ====================

    receive(msg: MarketplaceWithdraw) {
        require(sender() == self.owner, "NOT_OWNER");
        require(self.pendingCount == 0, "HAS_PENDING_PURCHASES");
        send(SendParameters{
            to: msg.destination,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false
        });
    }

    receive(msg: SetFeePercentage) {
        require(sender() == self.owner, "NOT_OWNER");
        require(msg.newFee >= 0 && msg.newFee <= 50, "FEE_OUT_OF_RANGE");
        self.feePercentage = msg.newFee;
    }

    receive(msg: AdminReturnNft) {
        require(sender() == self.owner, "NOT_OWNER");
        require(self.pendingBuyers.get(msg.nftAddress) == null, "PURCHASE_PENDING");
        let priceOpt: Int? = self.prices.get(msg.nftAddress);
        require(priceOpt == null, "USE_CANCEL_FOR_LISTED");
        self._returnNft(msg.nftAddress, msg.to);
    }

    receive() {}

    // ==================== Helpers ====================

    fun _returnNft(nftAddress: Address, to: Address) {
        send(SendParameters{
            to: nftAddress,
            value: self.NFT_TRANSFER_GAS,
            mode: SendPayGasSeparately,
            bounce: true,
            body: NftTransfer{
                queryId: 0,
                newOwner: to,
                responseDestination: to,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
            }.toCell()
        });
    }

    // ==================== Getters ====================

    get fun get_listing_data(nftAddress: Address): ListingInfo {
        let priceOpt: Int? = self.prices.get(nftAddress);
        if (priceOpt == null) {
            return ListingInfo{
                exists: false,
                price: 0,
                seller: myAddress()
            };
        }
        return ListingInfo{
            exists: true,
            price: priceOpt!!,
            seller: self.sellers.get(nftAddress)!!
        };
    }

    get fun get_pending_purchase(nftAddress: Address): PendingPurchaseInfo {
        let buyerOpt: Address? = self.pendingBuyers.get(nftAddress);
        if (buyerOpt == null) {
            return PendingPurchaseInfo{
                exists: false,
                buyer: myAddress(),
                payment: 0,
                startTime: 0,
                refundStarted: false
            };
        }
        let rf: Bool? = self.refundStarted.get(nftAddress);
        return PendingPurchaseInfo{
            exists: true,
            buyer: buyerOpt!!,
            payment: self.pendingPayments.get(nftAddress)!!,
            startTime: self.pendingTimes.get(nftAddress)!!,
            refundStarted: rf != null && rf == true
        };
    }

    get fun get_marketplace_data(): MarketplaceData {
        return MarketplaceData{
            owner: self.owner,
            collectionAddress: self.collectionAddress,
            feePercentage: self.feePercentage,
            listingCount: self.listingCount,
            pendingCount: self.pendingCount,
            balance: myBalance()
        };
    }

    get fun get_fee_percentage(): Int {
        return self.feePercentage;
    }

    get fun get_owner(): Address {
        return self.owner;
    }
}
