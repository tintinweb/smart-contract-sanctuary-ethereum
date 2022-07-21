// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IInventory {
    struct Gear {
        string name;
        uint16 tier;
        uint16 status;
        uint16 soulScore;
    }

    struct FallenInventory {
        address owner;
        Gear head;
        Gear chest;
        Gear shoulders;
        Gear shirt;
        Gear pants;
        Gear feet;
        Gear ring;
        Gear artifact;
        Gear mainhand;
        Gear offhand;
        uint256 base;
    }  

    function updateGear(uint256 tokenId, uint256 slot, Gear memory newGear) external;
    function getInventory(uint256 tokenId) external view returns(FallenInventory memory);
    function verifyOwnership(uint256 tokenId, address owner) external view;
}

interface IGearTable {
    function getDungeonGear(uint16 level, uint256 slot) external returns(IInventory.Gear memory gear);
}

interface ISouls {
    function burn(address user, uint256 amount) external;
}

interface IFallen {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Dungeon is Ownable {

    IGearTable public GearTable;
    ISouls public Souls;
    IInventory public Inventory;
    IFallen public Fallen;

    struct RaidInfo {
        uint256 cost;
        IInventory.Gear gear;
        uint16 slot;
        uint16 dropChance;
        uint16 runsLeft;
    }
    
    mapping(uint256 => RaidInfo) public RaidMapping;

    uint256 entropy = 0;

    bool public dungeonActive = false;

    RaidInfo raidOne = RaidInfo({
                                        cost: 1 ether, 
                                        gear: IInventory.Gear("Fallen Blade", 3, 1, 7),
                                        slot: 9,
                                        dropChance: 10,
                                        runsLeft: 250
                                    });
    
    RaidInfo raidTwo = RaidInfo({
                                        cost: 5 ether, 
                                        gear: IInventory.Gear("Helm of Darkness", 4, 1, 12),
                                        slot: 1,
                                        dropChance: 15,
                                        runsLeft: 500  
                                    });

    RaidInfo raidThree = RaidInfo({
                                        cost: 12 ether, 
                                        gear: IInventory.Gear("Dragonhide Breastplate", 5, 1, 20),
                                        slot: 3,
                                        dropChance: 20,
                                        runsLeft: 750   
                                    });

    RaidInfo raidFour = RaidInfo({
                                        cost: 30 ether, 
                                        gear: IInventory.Gear("Enigma of the Mind", 6, 1, 35),
                                        slot: 8,
                                        dropChance: 25,
                                        runsLeft: 500   
                                    });

    RaidInfo raidFive = RaidInfo({
                                        cost: 50 ether, 
                                        gear: IInventory.Gear("Invisible Dagger", 7, 1, 75),
                                        slot: 10,
                                        dropChance: 20,
                                        runsLeft: 250   
                                    });

    RaidInfo raidSix = RaidInfo({
                                        cost: 30 ether, 
                                        gear: IInventory.Gear("Spaulders of Atlas", 8, 1, 125),
                                        slot: 2,
                                        dropChance: 8,
                                        runsLeft: 100   
                                    });

    /**
     * @dev 
     
     Send an array of Token IDs to explore a dungeon.

     Level Correspondence:
        1: Halls
        2: Monastery
        3: Graveyard
        4: Catacombs
        5: Armory
        6: Castle
        7: Throne

     Entering a Dungeon will cost $Souls.

     Running a Dungeon will also send all $Souls owed to a Token ID into the outstandingSouls mapping on the Inventory Contract.
     This is done to ensure accurate earning of $Souls upon a change in the Soul Score of a Fallen.
     */

    function runDungeon(uint256[] memory tokenIds, uint16 level, uint256[] calldata gearType) public {
        Souls.burn(msg.sender, getDungeonCost(level) * tokenIds.length * gearType.length);
        require(dungeonActive, "Activity is paused");
        for(uint256 x = 0; x < tokenIds.length; x++) {
            Inventory.verifyOwnership(tokenIds[x], msg.sender);
            for(uint256 i = 0; i < gearType.length; i++) { 
                Inventory.updateGear(tokenIds[x], gearType[i], GearTable.getDungeonGear(level, gearType[i]));
            }
        }
    }

    /**
     * @dev 
     
     Send an array of Token IDs to conquer a Raid

     Raids are 

     Entering a Raid will cost $Souls.

     Running a Raid will also send all $Souls owed to a Token ID into the outstandingSouls mapping on the Inventory Contract.
     This is done to ensure accurate earning of $Souls upon a change in the Soul Score of a Fallen.
     */
    function enterRaid(uint256[] memory tokenIds, uint256 _raidId) public {
        RaidInfo memory _raid = RaidMapping[_raidId];
        require(_raid.runsLeft - tokenIds.length >= 0);
        require(dungeonActive, "Activity is paused");
        Souls.burn(msg.sender, _raid.cost * tokenIds.length);
        for(uint256 x = 0; x < tokenIds.length; x++) {
            //IInventory.FallenInventory memory _inventory = Inventory.getInventory(tokenIds[x]);
            Inventory.verifyOwnership(tokenIds[x], msg.sender);
            uint256 _seed = _rand(tokenIds[x]) % 100;
            if(_seed < _raid.dropChance){
                Inventory.updateGear(tokenIds[x],_raid.slot,_raid.gear);
            } else {
                Inventory.updateGear(tokenIds[x], 11, _raid.gear);
            }
        }
        RaidMapping[_raidId].runsLeft -= uint8(tokenIds.length);

    }

    function createRaid(RaidInfo memory _info, uint256 _raidId) external onlyOwner {
        RaidMapping[_raidId] = _info;
    }

    function getDungeonCost(uint256 level) internal pure returns (uint256 cost) {
        if(level==1){ return 1 ether; }
        else if(level==2){return 8 ether; }
        else if(level==3){ return 20 ether; }
        else if(level==4){ return 40 ether; }
        else if(level==5){ return 80 ether; }
        else if(level==6){ return 150 ether; }
        else if(level==7){ return 250 ether; }
        else { return 100000000000 ether; }  
    }

    function _rand(uint256 entropyModifier) internal returns (uint256) {
        entropy += entropyModifier;
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropy)));
    }

    function toggleDungeonActive() public onlyOwner {
        dungeonActive = !dungeonActive;
    }

    function setGearTableAddress(address _gearTableAddress) external onlyOwner {
        GearTable = IGearTable(_gearTableAddress);
    }

    function setSoulsAddress(address _soulsAddress) external onlyOwner {
        Souls = ISouls(_soulsAddress);
    }

    function setFallenAddress(address _fallenAddress) external onlyOwner {
        Fallen = IFallen(_fallenAddress);
    }

    function setInventoryAddress(address _inventoryAddress) external onlyOwner {    
        Inventory = IInventory(_inventoryAddress);
    }
    
    constructor(){
        RaidMapping[1] = raidOne;
        RaidMapping[2] = raidTwo;
        RaidMapping[3] = raidThree;
        RaidMapping[4] = raidFour;
        RaidMapping[5] = raidFive;
        RaidMapping[6] = raidSix;
    }

}