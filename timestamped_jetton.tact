import "@stdlib/deploy";
import "./jetton_messages.tact";
import "./nft_messages.tact";

struct JettonContractData {
    active: Bool;
    owner: Address;
    factoryOwner: Address;
    name: String;
    targetAmount: Int;
    depositAmount: Int;
    interval: Int;
    intervalEndTime: Int;
    totalDeposits: Int;
    createdAt: Int;
    jettonMaster: Address?;
    jettonWallet: Address?;
    isJetton: Bool;
    depositMadeInCurrentInterval: Bool;
    nativeBalance: Int;
    transferType: Int;
}

struct NftData {
    isInitialized: Bool;
    index: Int;
    collectionAddress: Address;
    ownerAddress: Address;
    individualContent: Cell;
}

message NftInit {
    owner: Address;
    factoryOwner: Address;
    name: String;
    targetAmount: Int as coins;
    depositAmount: Int as coins;
    interval: Int as uint64;
    timestamp: Int as uint64;
    jettonMaster: Address?;
    transferType: Int as uint8;
    imageActive: String;
    imageCompleted: String;
    imageFailed: String;
}

inline extends fun asMetadataCell(self: String): Cell {
    return beginTailString().concat(self).toCell();
}

contract TimestampedJetton {
    // NFT identity (deterministic — used in init)
    collectionAddress: Address;
    index: Int as uint64;

    // Initialization flag
    isNftInitialized: Bool;

    // Savings state
    active: Bool;
    owner: Address;
    factoryOwner: Address;
    name: String;
    targetAmount: Int as coins;
    depositAmount: Int as coins;
    interval: Int as uint64;
    intervalEndTime: Int as uint64;
    totalDeposits: Int as coins;
    createdAt: Int as uint64;

    jettonMaster: Address?;
    jettonWallet: Address?;
    isJetton: Bool;

    depositMadeInCurrentInterval: Bool;

    // 0 = transferable, 1 = gift (одна передача), 2 = soulbound (передача только после завершения)
    transferType: Int as uint8;

    imageActive: String;
    imageCompleted: String;
    imageFailed: String;

    const GRACE_PERIOD: Int = 600;
    const MIN_TON_FOR_STORAGE: Int = ton("0.05");
    const GAS_CONSUMPTION: Int = ton("0.03");

    // Only collectionAddress and index in init — deterministic addressing
    init(collectionAddress: Address, index: Int) {
        self.collectionAddress = collectionAddress;
        self.index = index;
        self.isNftInitialized = false;

        self.active = false;
        self.owner = collectionAddress;
        self.factoryOwner = collectionAddress;
        self.name = "";
        self.targetAmount = 0;
        self.depositAmount = 0;
        self.interval = 0;
        self.intervalEndTime = 0;
        self.totalDeposits = 0;
        self.createdAt = 0;
        self.jettonMaster = null;
        self.jettonWallet = null;
        self.isJetton = false;
        self.depositMadeInCurrentInterval = false;
        self.transferType = 0;
        self.imageActive = "";
        self.imageCompleted = "";
        self.imageFailed = "";
    }

    // Initialization message — only from collection (factory)
    receive(msg: NftInit) {
        require(sender() == self.collectionAddress, "NOT_COLLECTION");
        require(!self.isNftInitialized, "ALREADY_INITIALIZED");

        require(msg.targetAmount > 0, "TARGET_ZERO");
        require(msg.depositAmount > 0, "DEPOSIT_ZERO");
        require(msg.interval > 0, "INTERVAL_ZERO");
        require(msg.targetAmount >= msg.depositAmount, "TARGET_LT_DEPOSIT");

        self.isNftInitialized = true;
        self.active = true;
        self.owner = msg.owner;
        self.factoryOwner = msg.factoryOwner;
        self.name = msg.name;
        self.targetAmount = msg.targetAmount;
        self.depositAmount = msg.depositAmount;
        self.interval = msg.interval;
        self.createdAt = msg.timestamp;
        self.intervalEndTime = msg.timestamp + msg.interval;
        self.totalDeposits = 0;

        self.jettonMaster = msg.jettonMaster;
        self.jettonWallet = null;
        self.isJetton = msg.jettonMaster != null;
        self.depositMadeInCurrentInterval = false;
        self.transferType = msg.transferType;
        self.imageActive = msg.imageActive;
        self.imageCompleted = msg.imageCompleted;
        self.imageFailed = msg.imageFailed;
    }

    // Accept plain TON — motivational bonus (no op-code)
    receive() {}

    receive(msg: SetJettonWallet) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(sender() == self.owner, "NOT_OWNER");
        require(self.isJetton, "NOT_JETTON_MODE");
        require(self.jettonWallet == null, "ALREADY_SET");
        self.jettonWallet = msg.jettonWalletAddress;
    }

    receive(msg: String) {
        if (msg == "deposit") {
            require(self.isNftInitialized, "NOT_INITIALIZED");
            require(sender() == self.owner, "NOT_OWNER");
            require(!self.isJetton, "USE_JETTON_DEPOSIT");
            self._processDeposit(context().value);
        } else if (msg == "lose") {
            require(self.isNftInitialized, "NOT_INITIALIZED");
            self._processLose();
        }
    }

    receive(msg: JettonTransferNotification) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(self.isJetton, "NOT_JETTON_MODE");

        let jettonWallet: Address = self.jettonWallet!!;
        require(sender() == jettonWallet, "INVALID_JETTON_WALLET");

        if (msg.sender != self.owner) {
            return;
        }
        if (!self.active) {
            return;
        }
        let currentTime: Int = now();
        if (currentTime <= self.intervalEndTime - self.interval) {
            return;
        }
        if (msg.amount < self.depositAmount) {
            return;
        }
        if (self.depositMadeInCurrentInterval) {
            return;
        }

        self._processJettonDeposit(msg.amount);
    }

    fun _processDeposit(amount: Int) {
        require(self.active, "NOT_ACTIVE");

        let currentTime: Int = now();
        require(
            currentTime > self.intervalEndTime - self.interval,
            "TOO_EARLY"
        );

        require(amount >= self.depositAmount, "WRONG_AMOUNT");
        require(!self.depositMadeInCurrentInterval, "ALREADY_DEPOSITED");

        self.totalDeposits = self.totalDeposits + self.depositAmount;
        self.depositMadeInCurrentInterval = true;

        if (self.totalDeposits >= self.targetAmount) {
            self.active = false;

            send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance,
                bounce: false
            });
        } else {
            self.intervalEndTime = self.intervalEndTime + self.interval;
            self.depositMadeInCurrentInterval = false;
        }
    }

    fun _processJettonDeposit(amount: Int) {
        self.totalDeposits = self.totalDeposits + self.depositAmount;
        self.depositMadeInCurrentInterval = true;

        if (self.totalDeposits >= self.targetAmount) {
            self.active = false;
        } else {
            self.intervalEndTime = self.intervalEndTime + self.interval;
            self.depositMadeInCurrentInterval = false;
        }
    }

    fun _processLose() {
        require(self.active, "NOT_ACTIVE");

        let currentTime: Int = now();
        require(currentTime > self.intervalEndTime + self.GRACE_PERIOD, "NOT_LATE");
        require(self.totalDeposits < self.targetAmount, "ALREADY_COMPLETED");

        self.active = false;

        if (!self.isJetton) {
            send(SendParameters{
                to: self.factoryOwner,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: false
            });
        }
    }

    fun _sendJettonsTo(destination: Address, amount: Int) {
        let jettonWallet: Address = self.jettonWallet!!;

        let body: Cell = beginCell()
            .storeUint(0x0f8a7ea5, 32)
            .storeUint(0, 64)
            .storeCoins(amount)
            .storeAddress(destination)
            .storeAddress(destination)
            .storeUint(0, 1)
            .storeCoins(1)
            .storeUint(0, 1)
            .endCell();

        send(SendParameters{
            to: jettonWallet,
            value: ton("0.06"),
            mode: SendIgnoreErrors,
            bounce: true,
            body: body
        });
    }

    receive(msg: WithdrawJettons) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(self.isJetton, "NOT_JETTON_MODE");
        require(!self.active, "STILL_ACTIVE");
        require(self.jettonWallet != null, "JETTON_WALLET_NOT_SET");

        if (self.totalDeposits >= self.targetAmount) {
            require(sender() == self.owner, "NOT_BENEFICIARY");
        } else {
            require(sender() == self.factoryOwner, "NOT_BENEFICIARY");
        }

        self._sendJettonsTo(msg.destination, msg.amount);
    }

    receive(msg: WithdrawTon) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(!self.active, "STILL_ACTIVE");

        if (self.totalDeposits >= self.targetAmount) {
            require(sender() == self.owner, "NOT_BENEFICIARY");
        } else {
            require(sender() == self.factoryOwner, "NOT_BENEFICIARY");
        }

        send(SendParameters{
            to: msg.destination,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false
        });
    }

    receive(msg: WithdrawAnyJetton) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(!self.active, "STILL_ACTIVE");

        if (self.totalDeposits >= self.targetAmount) {
            require(sender() == self.owner, "NOT_BENEFICIARY");
        } else {
            require(sender() == self.factoryOwner, "NOT_BENEFICIARY");
        }

        let body: Cell = beginCell()
            .storeUint(0x0f8a7ea5, 32)
            .storeUint(0, 64)
            .storeCoins(msg.amount)
            .storeAddress(msg.destination)
            .storeAddress(msg.destination)
            .storeUint(0, 1)
            .storeCoins(1)
            .storeUint(0, 1)
            .endCell();

        send(SendParameters{
            to: msg.jettonWalletAddress,
            value: ton("0.06"),
            mode: SendIgnoreErrors,
            bounce: true,
            body: body
        });
    }

    // ==================== TEP-62: NFT Transfer ====================

    receive(msg: NftTransfer) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(sender() == self.owner, "NOT_OWNER");

        if (self.transferType == 2) {
            require(!self.active, "SOULBOUND_ACTIVE");
        } else if (self.transferType == 1) {
            // gift: allowed once, then becomes soulbound
        }
        // transferType == 0: always allowed

        let ctx: Context = context();
        let fwdFees: Int = ctx.readForwardFee();
        let msgValue: Int = ctx.value;

        let requiredGas: Int = self.GAS_CONSUMPTION
            + self.MIN_TON_FOR_STORAGE
            + (2 * fwdFees);

        require(msgValue > requiredGas + msg.forwardAmount, "INSUFFICIENT_GAS");

        let prevOwner: Address = self.owner;
        self.owner = msg.newOwner;

        if (self.transferType == 1) {
            self.transferType = 2;
        }

        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: NftOwnershipAssigned{
                    queryId: msg.queryId,
                    previousOwner: prevOwner,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        send(SendParameters{
            to: msg.responseDestination,
            value: msgValue - self.GAS_CONSUMPTION - self.MIN_TON_FOR_STORAGE - msg.forwardAmount - fwdFees,
            mode: SendPayGasSeparately,
            bounce: true,
            body: NftExcesses{ queryId: msg.queryId }.toCell()
        });
    }

    // ==================== TEP-62: Get Static Data ====================

    receive(msg: ChangeTransferType) {
        require(self.isNftInitialized, "NOT_INITIALIZED");
        require(sender() == self.owner, "NOT_OWNER");
        let newType: Int = msg.newTransferType;
        require(newType >= 0 && newType <= 2, "INVALID_TYPE");
        require(newType > self.transferType, "CANNOT_UPGRADE");
        self.transferType = newType;
    }

    receive(msg: NftGetStaticData) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: NftReportStaticData{
                queryId: msg.queryId,
                index: self.index,
                collection: self.collectionAddress
            }.toCell()
        });
    }

    // ==================== Dynamic Metadata ====================

    fun _buildIndividualContent(): Cell {
        if (!self.isNftInitialized) {
            return beginCell().storeUint(0, 8).endCell();
        }

        let totalSteps: Int = self.targetAmount / self.depositAmount;
        let currentStep: Int = self.totalDeposits / self.depositAmount;

        let statusStr: String = "active";
        if (!self.active) {
            if (self.totalDeposits >= self.targetAmount) {
                statusStr = "completed";
            } else {
                statusStr = "failed";
            }
        }

        let progressStr: StringBuilder = beginString();
        progressStr.append(currentStep.toString());
        progressStr.append("/");
        progressStr.append(totalSteps.toString());

        let descBuilder: StringBuilder = beginString();
        descBuilder.append(self.name);
        descBuilder.append(" | Progress: ");
        descBuilder.append(progressStr.toString());
        descBuilder.append(" steps | Status: ");
        descBuilder.append(statusStr);

        let imageUrl: String = self.imageActive;
        if (!self.active) {
            if (self.totalDeposits >= self.targetAmount) {
                imageUrl = self.imageCompleted;
            } else {
                imageUrl = self.imageFailed;
            }
        }

        let dict: map<Int as uint256, Cell> = emptyMap();
        dict.set(sha256("name"), self.name.asMetadataCell());
        dict.set(sha256("description"), descBuilder.toString().asMetadataCell());
        dict.set(sha256("image"), imageUrl.asMetadataCell());

        return beginCell()
            .storeUint(0, 8)
            .storeMaybeRef(dict.asCell()!!)
            .endCell();
    }

    // ==================== TEP-62 Getter: get_nft_data ====================

    get fun get_nft_data(): NftData {
        return NftData{
            isInitialized: self.isNftInitialized,
            index: self.index,
            collectionAddress: self.collectionAddress,
            ownerAddress: self.owner,
            individualContent: self._buildIndividualContent()
        };
    }

    // ==================== Savings Getters ====================

    get fun getContractData(): JettonContractData {
        return JettonContractData{
            active: self.active,
            owner: self.owner,
            factoryOwner: self.factoryOwner,
            name: self.name,
            targetAmount: self.targetAmount,
            depositAmount: self.depositAmount,
            interval: self.interval,
            intervalEndTime: self.intervalEndTime,
            totalDeposits: self.totalDeposits,
            createdAt: self.createdAt,
            jettonMaster: self.jettonMaster,
            jettonWallet: self.jettonWallet,
            isJetton: self.isJetton,
            depositMadeInCurrentInterval: self.depositMadeInCurrentInterval,
            nativeBalance: myBalance(),
            transferType: self.transferType
        };
    }

    get fun isReady(): Bool {
        if (!self.isNftInitialized) {
            return false;
        }
        if (self.isJetton) {
            return self.jettonWallet != null;
        }
        return true;
    }
}
