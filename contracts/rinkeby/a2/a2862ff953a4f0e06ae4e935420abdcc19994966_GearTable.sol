// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Inventory.sol";

contract GearTable is Ownable {
    string[] private head = [
        "Helmet",
        "Crown"
    ];

    string[] private chest = [
        "Brestplate",
        "Chestplate"
    ];

    string[] private shoulders = [
        "Dragonhide",
        "Demonskin"
    ];

    string[] private shirt = [
        "Leather Tunic",
        "Vest"
    ];

    string[] private pants = [
        "Leather Pants",
        "Bone Trousers",
        "Runed Leggings",
        "Hide Pants",
        "Chainmail Leggings",
        "Chainmail Pants",
        "Runed Pants",
        "Bone Leggings",
        "Dragonhide Pants"
    ];

    string[] private feet = [
        "Climbing Boots",
        "Fancy Boots",
        "Fighting Boots",
        "Iron Boots",
        "Steadfast Boots",
        "Insulated Boots",
        "Trickster Boots",
        "Leather Sandals",
        "Swanky Sandals",
        "Tough Sandals"
    ];

    string[] private ring = [
        "Copper Ring",
        "Iron Ring",
        "Gold Ring",
        "Silver Ring",
        "Diamond Ring",
        "Emerald Ring",
        "Copper Band",
        "Iron Band",
        "Gold Band",
        "Silver Band",
        "Diamond Band",
        "Emerald Band"
    ];

    string[] private artifact = [
        "Amulet",
        "Ruby",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Emerald"
    ];

    string[] private mainhand = [
        "Battleaxe",
        "Longsword",
        "Claymore",
        "Cutlass",
        "Rapier",
        "Broadsword",
        "Saber",
        "Katana",
        "Scimitar",
        "Halberd",
        "Spear"
    ];

    string[] private offhand = [
        "Dagger",
        "Shank",
        "Whip",
        "Wand",
        "Shield",
        "Shortsword",
        "Buckler"
    ];

    string[] private prefix = [
        "Broken ",
        "Common ",
        "Uncommon ",
        "Unusual ",
        "Rare ",
        "Epic ",
        "Mythic ",
        "Extotic ",
        "Legendary "
    ];

    mapping(uint256 => GearInfo) public GearMapping;
    mapping(uint256 => DungeonInfo) public DungeonMapping;

    address public dungeonAddress;

    struct GearInfo {
        uint16 minSoulScore;
        uint16 range;
    }

    struct DungeonInfo {
        uint256 cost;
        uint16 gearTierOne;
        uint16 gearTierOneChance;
        uint16 gearTierTwo;
        uint16 gearTierTwoChance;
        uint16 gearTierThree;
        uint16 gearTierThreeChance;
        uint16 gearTierFour;
        uint16 gearTierFourChance;
    }

    uint256 entropy = 0;

    GearInfo tierOne = GearInfo({
                                minSoulScore: 1,
                                range: 3
    });

    GearInfo tierTwo = GearInfo({
                                minSoulScore: 3,
                                range: 3
    });

    GearInfo tierThree = GearInfo({
                                minSoulScore: 5,
                                range: 6
    });

    GearInfo tierFour = GearInfo({
                                minSoulScore: 10,
                                range: 6
    });

    GearInfo tierFive = GearInfo({
                                minSoulScore: 20,
                                range: 6
    });

    GearInfo tierSix = GearInfo({
                                minSoulScore: 30,
                                range: 11
    });

    GearInfo tierSeven = GearInfo({
                                minSoulScore: 50,
                                range: 26
    });

    GearInfo tierEight = GearInfo({
                                minSoulScore: 100,
                                range: 26
    });

    GearInfo tierNine = GearInfo({
                                minSoulScore: 150,
                                range: 101
    });

    DungeonInfo levelOne = DungeonInfo({
                                        cost: 1 ether, 
                                        gearTierOne: 1,
                                        gearTierOneChance: 75,
                                        gearTierTwo: 2,
                                        gearTierTwoChance: 95,
                                        gearTierThree: 3,
                                        gearTierThreeChance: 100,
                                        gearTierFour: 4,
                                        gearTierFourChance: 0
                                    });

    DungeonInfo levelTwo = DungeonInfo({
                                        cost: 2 ether, 
                                        gearTierOne: 1,
                                        gearTierOneChance: 25,
                                        gearTierTwo: 2,
                                        gearTierTwoChance: 75,
                                        gearTierThree: 3,
                                        gearTierThreeChance: 95,
                                        gearTierFour: 4,
                                        gearTierFourChance: 100
                                    });

    DungeonInfo levelThree = DungeonInfo({
                                        cost: 4 ether, 
                                        gearTierOne: 2,
                                        gearTierOneChance: 25,
                                        gearTierTwo: 3,
                                        gearTierTwoChance: 75,
                                        gearTierThree: 4,
                                        gearTierThreeChance: 95,
                                        gearTierFour: 5,
                                        gearTierFourChance: 100
                                    });

    DungeonInfo levelFour = DungeonInfo({
                                        cost: 8 ether, 
                                        gearTierOne: 3,
                                        gearTierOneChance: 25,
                                        gearTierTwo: 4,
                                        gearTierTwoChance: 75,
                                        gearTierThree: 5,
                                        gearTierThreeChance: 95,
                                        gearTierFour: 6,
                                        gearTierFourChance: 100
                                    });

    DungeonInfo levelFive = DungeonInfo({
                                        cost: 16 ether, 
                                        gearTierOne: 4,
                                        gearTierOneChance: 25,
                                        gearTierTwo: 5,
                                        gearTierTwoChance: 75,
                                        gearTierThree: 6,
                                        gearTierThreeChance: 100,
                                        gearTierFour: 7,
                                        gearTierFourChance: 0
                                    });

    DungeonInfo levelSix = DungeonInfo({
                                        cost: 50 ether, 
                                        gearTierOne: 5,
                                        gearTierOneChance: 25,
                                        gearTierTwo: 6,
                                        gearTierTwoChance: 100,
                                        gearTierThree: 7,
                                        gearTierThreeChance: 0,
                                        gearTierFour: 8,
                                        gearTierFourChance: 0
                                    });

    DungeonInfo levelSeven = DungeonInfo({
                                        cost: 250 ether, 
                                        gearTierOne: 6,
                                        gearTierOneChance: 75,
                                        gearTierTwo: 7,
                                        gearTierTwoChance: 100,
                                        gearTierThree: 8,
                                        gearTierThreeChance: 0,
                                        gearTierFour: 9,
                                        gearTierFourChance: 0
                                    });

    function getDungeonGear(uint16 level, uint256 slot) external returns(Inventory.Gear memory gear) {
        require(msg.sender == dungeonAddress);
        if(slot==1){return getHead(level);  }
        else if(slot==2){ return getShoulders(level);  }
        else if(slot==3){ return getChest(level); }
        else if(slot==4){ return getShirt(level); }
        else if(slot==5){ return getPants(level); }
        else if(slot==6){ return getFeet(level); }
        else if(slot==7){ return getRing(level); }
        else if(slot==8){ return getArtifact(level); }
        else if(slot==9){ return getMainhand(level); }
        else if(slot==10){ return getOffhand(level); }
    }

    function getShirt(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(1);
        uint16 tier = getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], shirt[seed % shirt.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getPants(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(2);
        uint16 tier = getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], pants[seed % pants.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getHead(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(3);
        uint16 tier = getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], head[seed % head.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getFeet(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(4);
        uint16 tier = getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], feet[seed % feet.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getChest(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(5);
        uint16 tier =  getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], chest[seed % chest.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getShoulders(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(6);
        uint16 tier =  getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], shoulders[seed % shoulders.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getRing(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(7);
        uint16 tier =  getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], ring[seed % ring.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getMainhand(uint16 level) internal returns(Inventory.Gear memory) {      
        uint256 seed = _rand(8);
        uint16 tier =  getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], mainhand[seed % mainhand.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getOffhand(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(9);
        uint16 tier =  getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], offhand[seed % offhand.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range));
    }

    function getArtifact(uint16 level) internal returns(Inventory.Gear memory) {
        uint256 seed = _rand(10);
        uint16 tier = getTier(level, seed);
        return Inventory.Gear(string(abi.encodePacked(prefix[tier-1], artifact[seed % artifact.length])), tier, 1, GearMapping[tier].minSoulScore + uint16(seed % GearMapping[tier].range) );
    }

    function getTier(uint16 level, uint256 seed) public view returns (uint16 tier) {
        if(seed % 100< DungeonMapping[level].gearTierOneChance){ return DungeonMapping[level].gearTierOne; }
        else if(seed % 100< DungeonMapping[level].gearTierTwoChance){ return DungeonMapping[level].gearTierTwo; }
        else if(seed % 100< DungeonMapping[level].gearTierThreeChance){ return DungeonMapping[level].gearTierThree; }
        else { return DungeonMapping[level].gearTierFour; }
    }

    function _rand(uint256 entropyModifier) internal returns (uint16) {
        entropy += entropyModifier;
        return uint16(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropy))));
    }

    function setDungeonAddress(address _dungeonAddress) external onlyOwner {
        dungeonAddress = _dungeonAddress;
    }

    constructor(){

        GearMapping[1] = tierOne;
        GearMapping[2] = tierTwo;
        GearMapping[3] = tierThree;
        GearMapping[4] = tierFour;
        GearMapping[5] = tierFive;
        GearMapping[6] = tierSix;
        GearMapping[7] = tierSeven;
        GearMapping[8] = tierSix;
        GearMapping[9] = tierSeven;

        DungeonMapping[1] = levelOne;
        DungeonMapping[2] = levelTwo;
        DungeonMapping[3] = levelThree;
        DungeonMapping[4] = levelFour;
        DungeonMapping[5] = levelFive;
        DungeonMapping[6] = levelSix;
        DungeonMapping[7] = levelSeven;
    }
}