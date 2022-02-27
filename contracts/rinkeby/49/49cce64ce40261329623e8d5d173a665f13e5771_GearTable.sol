// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Dungeon.sol";

contract GearTable is Ownable {
    
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

    function getShirt(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Plain Shirt", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getPants(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Leather Pants", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getHead(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Crown", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getFeet(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Boots", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getChest(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Satin Tunic", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getShoulders(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Leather Pads", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getRing(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == address(this));
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Copper Ring", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getMainhand(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);        
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Battle Axe", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getOffhand(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Dagger", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getArtifact(uint16 level) external view returns(Dungeon.Gear memory) {
        require(msg.sender == dungeonAddress);
        uint16 tier = getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Dungeon.Gear("Treasure", tier, 1, GearMapping[tier].minSoulScore + uint16(seed) );
    }

    function getTier(uint16 level) internal view returns (uint16 tier) {
        DungeonInfo memory _dungeon = DungeonMapping[level];
        uint256 seed = _rand() % 100;
        if(seed < _dungeon.gearTierOneChance){ return _dungeon.gearTierOne; }
        else if(seed < _dungeon.gearTierTwoChance){ return _dungeon.gearTierTwo; }
        else if(seed < _dungeon.gearTierThreeChance){ return _dungeon.gearTierThree; }
        else { return _dungeon.gearTierFour; }
    }

    function _rand() internal view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp))));
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