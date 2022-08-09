/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

contract TrustlessGiveaway {
    enum GivewayStatus {
        NEW_RECORD,
        CREATED,
        ENTRANTS_LOCKED,
        DETERMINING_BLOCK_LOCKED,
        GIVEAWAY_COMPLETE
    }
    
    struct Giveaway {
        string name;
        string listOfEntrantsCID; // IPFS CID of spreadsheet containing list of entrants
        uint16 entrantsCount;
        uint32 determiningBlockNumber;
        bytes32 determiningBlockHash;
        uint16 finalOutcome;
        address creator;
        GivewayStatus status;
    }
    
    event GiveawayCreated(
        uint giveawayId,
        string name,
        string listOfEntrantsCID,
        uint16 entrantsCount,
        address creator
    );
    
    event GiveawayUpdated(
        uint giveawayId,
        string name,
        string listOfEntrantsCID,
        uint16 entrantsCount,
        address creator
    );
    
    event DeterminingBlockLocked(
        uint giveawayId,
        uint32 determiningBlockNumber
    );
    
    event GiveawayComplete(
        uint giveawayId,
        uint16 finalOutcome,
        address winner
    );
    
    Giveaway[] public giveaways;
    
    constructor() {}
    
    modifier ownerOnly(uint giveawayId) {
        Giveaway memory giveaway = giveaways[giveawayId];
        require(msg.sender == giveaway.creator);
        
        _;
    }
    
    function createGiveaway(
        string calldata name,
        uint16 entrantsCount,
        string calldata listOfEntrantsCID
    ) public returns (uint) {
        giveaways.push(Giveaway({
            name: name,
            listOfEntrantsCID: listOfEntrantsCID,
            determiningBlockNumber: 0,
            entrantsCount: entrantsCount,
            determiningBlockHash: bytes32(0),
            finalOutcome: 0,
            creator: msg.sender,
            status: GivewayStatus.CREATED
        }));
        
        emit GiveawayCreated(giveaways.length - 1, name, listOfEntrantsCID, entrantsCount, msg.sender);
        
        return giveaways.length - 1;
    }
    
    function updateGiveaway(
        uint giveawayId,
        string calldata name,
        uint16 entrantsCount,
        string calldata listOfEntrantsCID
    ) public ownerOnly(giveawayId) {
        Giveaway storage giveaway = giveaways[giveawayId];
        
        require(giveaway.status == GivewayStatus.CREATED);
        
        giveaway.name = name;
        giveaway.entrantsCount = entrantsCount;
        giveaway.listOfEntrantsCID = listOfEntrantsCID;
    }
    
    function lockEntrants(uint giveawayId) public ownerOnly(giveawayId) {
        Giveaway storage giveaway = giveaways[giveawayId];
        
        require(giveaway.status == GivewayStatus.CREATED);
        require(giveaway.entrantsCount > 0, "Need entrants");
        // require(bytes(giveaway.listOfEntrantsCID).length == 46, "Invalid IPFS CID length");
        
        giveaway.status = GivewayStatus.ENTRANTS_LOCKED;
    }
    
    function lockDeterminingBlock(uint giveawayId) public ownerOnly(giveawayId) {
        Giveaway storage giveaway = giveaways[giveawayId];
        
        require(giveaway.status == GivewayStatus.ENTRANTS_LOCKED);
        
        giveaway.determiningBlockNumber = uint32(block.number + 1);
        giveaway.status = GivewayStatus.DETERMINING_BLOCK_LOCKED;
        
        emit DeterminingBlockLocked(giveawayId, giveaway.determiningBlockNumber);
    }
    
    function recordWinner(uint giveawayId) public {
        Giveaway storage giveaway = giveaways[giveawayId];
        bytes32 determiningHash = blockhash(giveaway.determiningBlockNumber);
        
        require(giveaway.status == GivewayStatus.DETERMINING_BLOCK_LOCKED);
        require(determiningHash != bytes32(0));
        
        giveaway.determiningBlockHash = determiningHash;
        giveaway.finalOutcome = uint16(uint(determiningHash) % giveaway.entrantsCount) + 1;
        giveaway.status = GivewayStatus.GIVEAWAY_COMPLETE;
    }
}