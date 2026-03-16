import "@stdlib/deploy";
import "./timestamped_jetton.tact";
import "./nft_messages.tact";

message CreateJettonContract {
    name: String;
    targetAmount: Int as coins;
    regularDeposite: Int as coins;
    interval: Int as uint64;
    jettonMaster: Address?;
    transferType: Int as uint8;
}

struct CollectionData {
    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;
}

contract ArrayJetton with Deployable {
    owner: Address;
    version: Int as uint32;
    nextItemIndex: Int as uint64;
    collectionContent: Cell;

    imageActive: String;
    imageCompleted: String;
    imageFailed: String;

    const MIN_CREATE_VALUE: Int = ton("0.15");

    init(owner: Address, collectionContent: Cell) {
        self.owner = owner;
        self.version = 7;
        self.nextItemIndex = 0;
        self.collectionContent = collectionContent;
        self.imageActive = "https://coral-elegant-echidna-219.mypinata.cloud/ipfs/bafkreidyxfrovau2spmg6lwwsvdsgomkrzr73f6p6mqdrnja4csd23h77y";
        self.imageCompleted = "https://coral-elegant-echidna-219.mypinata.cloud/ipfs/bafkreieqetixwi23ahnjsuqgckmxqjxm7mjxm4gel523yj7es5yqvtitgm";
        self.imageFailed = "https://coral-elegant-echidna-219.mypinata.cloud/ipfs/bafkreicb3ucaitkk3cxgyirut4ykkk65kcarfkjnys57jgxp3kxkjthpcu";
    }

    receive() {}

    receive(msg: CreateJettonContract) {
        let msgValue: Int = context().value;
        require(msgValue >= self.MIN_CREATE_VALUE, "INSUFFICIENT_GAS");

        let senderAddress: Address = sender();
        let currentTime: Int = now();
        let itemIndex: Int = self.nextItemIndex;

        let nftInit: StateInit = initOf TimestampedJetton(myAddress(), itemIndex);
        let contractAddr: Address = contractAddress(nftInit);

        self.nextItemIndex = self.nextItemIndex + 1;

        send(SendParameters{
            to: contractAddr,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: NftInit{
                owner: senderAddress,
                factoryOwner: self.owner,
                name: msg.name,
                targetAmount: msg.targetAmount,
                depositAmount: msg.regularDeposite,
                interval: msg.interval,
                timestamp: currentTime,
                jettonMaster: msg.jettonMaster,
                transferType: msg.transferType,
                imageActive: self.imageActive,
                imageCompleted: self.imageCompleted,
                imageFailed: self.imageFailed
            }.toCell(),
            code: nftInit.code,
            data: nftInit.data
        });
    }

    receive(msg: WithdrawTon) {
        require(sender() == self.owner, "NOT_OWNER");
        send(SendParameters{
            to: msg.destination,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false
        });
    }

    receive(msg: WithdrawAnyJetton) {
        require(sender() == self.owner, "NOT_OWNER");
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

    receive(msg: UpdateImages) {
        require(sender() == self.owner, "NOT_OWNER");
        self.imageActive = msg.imageActive;
        self.imageCompleted = msg.imageCompleted;
        self.imageFailed = msg.imageFailed;
    }

    // ==================== TEP-62 Collection Getters ====================

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            nextItemIndex: self.nextItemIndex,
            collectionContent: self.collectionContent,
            ownerAddress: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let nftInit: StateInit = initOf TimestampedJetton(myAddress(), index);
        return contractAddress(nftInit);
    }

    get fun get_nft_content(index: Int, individualContent: Cell): Cell {
        return individualContent;
    }
}
