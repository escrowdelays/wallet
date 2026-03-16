// TEP-62 NFT Standard messages

// NFT Item transfer (owner → NFT contract)
// opcode: 0x5fcc3d14
message(0x5fcc3d14) NftTransfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Notification sent to new owner after transfer
// opcode: 0x05138d91
message(0x05138d91) NftOwnershipAssigned {
    queryId: Int as uint64;
    previousOwner: Address;
    forwardPayload: Slice as remaining;
}

// Excesses message — returns remaining gas
// opcode: 0xd53276db
message(0xd53276db) NftExcesses {
    queryId: Int as uint64;
}

// Request static data from NFT item
// opcode: 0x2fcb26a2
message(0x2fcb26a2) NftGetStaticData {
    queryId: Int as uint64;
}

// Response with static data from NFT item
// opcode: 0x8b771735
message(0x8b771735) NftReportStaticData {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

// Change NFT transfer type (owner only)
// 0 = transferable, 1 = gift, 2 = soulbound
// Allowed: 0→1, 0→2, 1→2. Soulbound (2) is final.
message(0x7e8a1c3f) ChangeTransferType {
    queryId: Int as uint64;
    newTransferType: Int as uint8;
}

// Update NFT image set on factory (owner only)
message(0x4a2b3c5d) UpdateImages {
    imageActive: String;
    imageCompleted: String;
    imageFailed: String;
}
