// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Base64.sol";
import "./Traits.sol";

interface IGold {
    function mint(address to, uint256 value) external;
    function burn(address user, uint256 amount) external;
}

interface IFallen {
    function safeTransferFrom(address from, address to, uint256 tokenId) external; 
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

contract Dungeon is Ownable, IERC721Receiver {
    address public raidsAddress;

    IGold public Gold;
    IFallen public Fallen;

    event GearObtained(address user, Gear gear);

    struct Gear {
        string name;
        uint16 tier;
        uint16 status;
        uint16 soulScore;
    }

    struct RaidInventory {
        address owner;
        Gear shirt;
        Gear pants;
        Gear head;
        Gear feet;
        Gear chest;
        Gear shoulders;
        Gear ring;
        Gear mainhand;
        Gear offhand;
        Gear artifact;
        uint256 soulScore;
    }

    struct DungeonInfo {
        uint16 cost;
        uint16 gearTierOne;
        uint16 gearTierOneChance;
        uint16 gearTierTwo;
        uint16 gearTierTwoChance;
        uint16 gearTierThree;
        uint16 gearTierThreeChance;
        uint16 gearTierFour;
        uint16 gearTierFourChance;
    }

    struct GearInfo {
        uint8 minSoulScore;
        uint8 range;
    }

    
    mapping(uint256 => RaidInventory) public tokenInventory;
    mapping(uint256 => uint256) public LastDungeonRun;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => DungeonInfo) public DungeonMapping;
    mapping(uint256 => GearInfo) public GearMapping;

    DungeonInfo levelOne = DungeonInfo({
                                        cost: 1, 
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
                                        cost: 2, 
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
                                        cost: 4, 
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
                                        cost: 8, 
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
                                        cost: 16, 
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
                                        cost: 50, 
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
                                        cost: 250, 
                                        gearTierOne: 6,
                                        gearTierOneChance: 75,
                                        gearTierTwo: 7,
                                        gearTierTwoChance: 100,
                                        gearTierThree: 8,
                                        gearTierThreeChance: 0,
                                        gearTierFour: 9,
                                        gearTierFourChance: 0
                                    });

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

    function runDungeon(uint256 tokenId, uint16 level, uint256[] calldata gearType) public {
        //require(msg.sender == tokenInventory[tokenId].owner);
        //Gold.burn(msg.sender, getDungeonCost(level));
        for(uint256 i = 0; i < gearType.length; i++) { 
            if(gearType[i]==1){ tokenInventory[tokenId].shirt = getShirt(level); emit GearObtained(msg.sender, tokenInventory[tokenId].shirt); }
            else if(gearType[i]==2){ tokenInventory[tokenId].pants = getPants(level); emit GearObtained(msg.sender, tokenInventory[tokenId].pants); }
            else if(gearType[i]==3){ tokenInventory[tokenId].head = getHead(level); emit GearObtained(msg.sender, tokenInventory[tokenId].head); }
            else if(gearType[i]==4){ tokenInventory[tokenId].feet = getFeet(level); emit GearObtained(msg.sender, tokenInventory[tokenId].feet); }
            else if(gearType[i]==5){ tokenInventory[tokenId].chest = getChest(level); emit GearObtained(msg.sender, tokenInventory[tokenId].chest); }
            else if(gearType[i]==6){ tokenInventory[tokenId].shoulders = getShoulders(level); emit GearObtained(msg.sender, tokenInventory[tokenId].shoulders); }
            else if(gearType[i]==7){ tokenInventory[tokenId].ring = getRing(level); emit GearObtained(msg.sender, tokenInventory[tokenId].ring); }
            else if(gearType[i]==8){ tokenInventory[tokenId].mainhand = getMainhand(level); emit GearObtained(msg.sender, tokenInventory[tokenId].mainhand); }
            else if(gearType[i]==9){ tokenInventory[tokenId].offhand = getOffhand(level); emit GearObtained(msg.sender, tokenInventory[tokenId].offhand); }
            else if(gearType[i]==10){ tokenInventory[tokenId].artifact = getArtifact(level); emit GearObtained(msg.sender, tokenInventory[tokenId].artifact); }
        }
        tokenInventory[tokenId].soulScore = getTokenOverall(tokenId);
    }

    function unstakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(tokenInventory[ids[i]].owner == msg.sender, "You do not own this fallen");
            require(Fallen.ownerOf(ids[i]) == address(this), "");
            //require(staking, "Staking is paused");
            Fallen.safeTransferFrom(address(this), msg.sender, ids[i]);
        }
    }

    function stakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(Fallen.ownerOf(ids[i]) == msg.sender, "");
            //require(staking, "Staking is paused");
            tokenInventory[ids[i]].owner = msg.sender;
            Fallen.safeTransferFrom(msg.sender, address(this), ids[i]);
        }
    }

    function setTokenOwner(uint256 tokenId, address owner) external {
        //require(msg.sender == raidsAddress, "You do not have permission to generate an inventory for that token");
        tokenInventory[tokenId].owner = owner;
    }
    
    /*function generateTokenInventory(uint256 tokenId) external{
        //require(msg.sender == tokenInventory[tokenId].owner, "You do not have permission to generate an inventory for that token");
        //tokenInventory[tokenId] = RaidInventory(tokenInventory[tokenId].owner,Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),0);
    }*/

    function getTokenOverall(uint256 tokenId) internal view returns (uint256 soulScore) {
        return (tokenInventory[tokenId].shirt.soulScore 
        + tokenInventory[tokenId].pants.soulScore 
        + tokenInventory[tokenId].head.soulScore 
        + tokenInventory[tokenId].feet.soulScore
        + tokenInventory[tokenId].chest.soulScore
        + tokenInventory[tokenId].shoulders.soulScore
        + tokenInventory[tokenId].ring.soulScore
        + tokenInventory[tokenId].mainhand.soulScore
        + tokenInventory[tokenId].offhand.soulScore
        + tokenInventory[tokenId].artifact.soulScore
        );
    }

    function getShirt(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Plain Shirt", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getPants(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Leather Pants", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getHead(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Crown", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getFeet(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Boots", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getChest(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Satin Tunic", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getShoulders(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Leather Pads", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getRing(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Copper Ring", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getMainhand(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Battle Axe", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getOffhand(uint16 level) internal view returns(Gear memory) {
        uint16 tier =  getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Dagger", tier, 1, GearMapping[tier].minSoulScore + uint16(seed));
    }

    function getArtifact(uint16 level) internal view returns(Gear memory) {
        uint16 tier = getTier(level);
        uint256 seed = _rand() % GearMapping[tier].range;
        return Gear("Treasure", tier, 1, GearMapping[tier].minSoulScore + uint16(seed) );
    }

    function  getTier(uint16 level) internal view returns (uint16 tier) {
        DungeonInfo memory _dungeon = DungeonMapping[level];
        uint256 seed = _rand() % 100;
        if(seed < _dungeon.gearTierOneChance){ return _dungeon.gearTierOne; }
        else if(seed < _dungeon.gearTierTwoChance){ return _dungeon.gearTierTwo; }
        else if(seed < _dungeon.gearTierThreeChance){ return _dungeon.gearTierThree; }
        else { return _dungeon.gearTierFour; }
    }

    function setRaidsAddress(address _raidsAddress) external onlyOwner {
        raidsAddress = _raidsAddress;
    }

    function getDungeonCost(uint256 level) internal view returns (uint256 cost) {
        if(level==1){ return levelOne.cost; }
        else if(level==2){return levelTwo.cost; }
        else if(level==3){ return levelThree.cost; }
        else if(level==4){ return levelFour.cost; }
        else if(level==5){ return levelFive.cost; }
        else if(level==6){ return levelSix.cost; }
        else if(level==7){ return levelSeven.cost; }
        else { return 100000000000; }
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp)));
    }

    function setGoldAddress(address _goldAddress) external onlyOwner {
        Gold = IGold(_goldAddress);
    }

    function setFallenAddress(address _fallenAddress) external onlyOwner {
        Fallen = IFallen(_fallenAddress);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return Traits.getTokenURI(tokenInventory[tokenId], tokenId);
    }

    function getStakedFallen(address owner) public view returns (uint256[] memory ids) {
        uint256 fallenSupply = Fallen.totalSupply();
        uint256[] memory temp = new uint256[](fallenSupply);
        uint256 count = 0;

        for(uint256 i = 0; i < fallenSupply; i++){
            if(owner == tokenInventory[i].owner){
                temp[count] = i;
                count += 1;
            }
        }

        uint256[] memory fallen = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            fallen[i] = temp[i];
        }
        return fallen;
    }

    function getUnstakedFallen(address owner) public view returns (uint256[] memory ids) {
        uint256 fallenSupply = Fallen.totalSupply();
        uint256[] memory temp = new uint256[](fallenSupply);
        uint256 count = 0;

        for(uint256 i = 0; i < fallenSupply; i++){
            if(owner == Fallen.ownerOf(i)){
                temp[count] = i;
                count += 1;
            }
        }

        uint256[] memory fallen = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            fallen[i] = temp[i];
        }

        return fallen;
    }

    function getAllStakedTokenURIs(address owner) external view returns(string[] memory) {
        uint256[] memory fallenStaked = getStakedFallen(owner);
        string[] memory tokenURIs = new string[](fallenStaked.length);
        for (uint256 i=0; i < fallenStaked.length; i++){
            tokenURIs[i] = (getTokenURI(fallenStaked[i]));
        } 
        return tokenURIs;

    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }

    constructor(){
        DungeonMapping[1] = levelOne;
        DungeonMapping[2] = levelTwo;
        DungeonMapping[3] = levelThree;
        DungeonMapping[4] = levelFour;
        DungeonMapping[5] = levelFive;
        DungeonMapping[6] = levelSix;
        DungeonMapping[7] = levelSeven;

        GearMapping[1] = tierOne;
        GearMapping[2] = tierTwo;
        GearMapping[3] = tierThree;
        GearMapping[4] = tierFour;
        GearMapping[5] = tierFive;
        GearMapping[6] = tierSix;
        GearMapping[7] = tierSeven;
        GearMapping[8] = tierSix;
        GearMapping[9] = tierSeven;
    }

}