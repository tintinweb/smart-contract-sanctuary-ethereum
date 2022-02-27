// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Base64.sol";
import "./Traits.sol";

interface ISouls {
    function mint(address to, uint256 value) external;
    function burn(address user, uint256 amount) external;
}

interface IFallen {
    function safeTransferFrom(address from, address to, uint256 tokenId) external; 
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface IGearTable {
    function getHead(uint16 level) external view returns(Dungeon.Gear memory);
    function getShoulders(uint16 level) external view returns(Dungeon.Gear memory);
    function getChest(uint16 level) external view returns(Dungeon.Gear memory);
    function getShirt(uint16 level) external view returns(Dungeon.Gear memory);
    function getPants(uint16 level) external view returns(Dungeon.Gear memory);
    function getFeet(uint16 level) external view returns(Dungeon.Gear memory);
    function getRing(uint16 level) external view returns(Dungeon.Gear memory);
    function getArtifact(uint16 level) external view returns(Dungeon.Gear memory);
    function getMainhand(uint16 level) external view returns(Dungeon.Gear memory);
    function getOffhand(uint16 level) external view returns(Dungeon.Gear memory);
}

contract Dungeon is Ownable, IERC721Receiver {

    ISouls public Souls;
    IFallen public Fallen;
    IGearTable public GearTable;

    event GearObtained(address user, Gear gear);
 
    struct Gear {
        string name;
        uint16 tier;
        uint16 status;
        uint16 soulScore;
    }

    struct FallenInventory {
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

    struct RaidInfo {
        Gear gear;
        uint256 cost;
        uint8 slot;
        uint8 runs;
        uint8 maxDrops;
    }
    
    mapping(uint256 => FallenInventory) public tokenInventory;
    mapping(string => RaidInfo) public RaidMapping;

    mapping(uint256 => uint256) public soulScoreIndices;

    uint256 totalSoulScoreInRaid = 0;

    bool public raidActive;

    RaidInfo public currentRaid;

    uint256[] raidWinners;

    function runDungeon(uint256[] memory tokenIds, uint16 level, uint256[] calldata gearType) public {
        //Souls.burn(msg.sender, getDungeonCost(level) * tokenIds.length);

        for(uint256 x = 0; x < tokenIds.length; x++) {
            //require(msg.sender == tokenInventory[tokenIds[x]].owner);
            //require(Fallen.ownerOf(tokenIds[x]) == address(this));
            
            for(uint256 i = 0; i < gearType.length; i++) { 
                if(gearType[i]==1){ tokenInventory[tokenIds[x]].head = GearTable.getHead(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].head); }
                else if(gearType[i]==2){ tokenInventory[tokenIds[x]].shoulders = GearTable.getShoulders(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].shoulders); }
                else if(gearType[i]==3){ tokenInventory[tokenIds[x]].chest = GearTable.getChest(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].chest); }
                else if(gearType[i]==4){ tokenInventory[tokenIds[x]].shirt = GearTable.getShirt(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].shirt); }
                else if(gearType[i]==5){ tokenInventory[tokenIds[x]].pants = GearTable.getPants(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].pants); }
                else if(gearType[i]==6){ tokenInventory[tokenIds[x]].feet = GearTable.getFeet(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].feet); }
                else if(gearType[i]==7){ tokenInventory[tokenIds[x]].ring = GearTable.getRing(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].ring); }
                else if(gearType[i]==8){ tokenInventory[tokenIds[x]].artifact = GearTable.getArtifact(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].artifact); }
                else if(gearType[i]==9){ tokenInventory[tokenIds[x]].mainhand = GearTable.getMainhand(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].mainhand); }
                else if(gearType[i]==10){ tokenInventory[tokenIds[x]].offhand = GearTable.getOffhand(level); emit GearObtained(msg.sender, tokenInventory[tokenIds[x]].offhand); }
            }
            tokenInventory[tokenIds[x]].soulScore = getTokenOverall(tokenIds[x]);
        }
    }

    function enterRaid(uint256[] memory tokenIds, string calldata raid) public {
        RaidInfo memory _raid = RaidMapping[raid];
        require(raidActive);
        Souls.burn(msg.sender, _raid.cost * tokenIds.length);

        for(uint256 x = 0; x < tokenIds.length; x++) {
            require(Fallen.ownerOf(tokenIds[x]) == address(this));
            require(tokenInventory[tokenIds[x]].owner == msg.sender);
        }

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

    function createRaid(RaidInfo memory _info, string memory _name) external onlyOwner {
        RaidMapping[_name] = _info;
    }

    function setTokenOwner(uint256 tokenId, address owner) external {
        require(msg.sender == address(Fallen), "You do not have permission to generate an inventory for that token");
        tokenInventory[tokenId].owner = owner;
    }
    
    /*function generateTokenInventory(uint256 tokenId) external{
        //require(msg.sender == tokenInventory[tokenId].owner, "You do not have permission to generate an inventory for that token");
        //tokenInventory[tokenId] = FallenInventory(tokenInventory[tokenId].owner,Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),Gear("","","",0),0);
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


    function getDungeonCost(uint256 level) internal pure returns (uint256 cost) {
        if(level==1){ return 1 ether; }
        else if(level==2){return 2 ether; }
        else if(level==3){ return 4 ether; }
        else if(level==4){ return 8 ether; }
        else if(level==5){ return 16 ether; }
        else if(level==6){ return 50 ether; }
        else if(level==7){ return 150 ether; }
        else { return 100000000000 ether; }
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp)));
    }

    function setSoulsAddress(address _soulsAddress) external onlyOwner {
        Souls = ISouls(_soulsAddress);
    }

    function setFallenAddress(address _fallenAddress) external onlyOwner {
        Fallen = IFallen(_fallenAddress);
    }

    function setGearTableAddress(address _gearTableAddress) external onlyOwner {
        GearTable = IGearTable(_gearTableAddress);
    }
    
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return Traits.getTokenURI(tokenInventory[tokenId], tokenId);
    }

    function getStakedFallen(address owner) public view returns (uint256[] memory ids) {
        uint256 fallenSupply = Fallen.totalSupply();
        uint256[] memory temp = new uint256[](fallenSupply);
        uint256 count = 0;

        for(uint256 i = 0; i < fallenSupply; i++){
            if(owner == tokenInventory[i].owner && address(this) == Fallen.ownerOf(i)){
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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }

    constructor(){
    }

}