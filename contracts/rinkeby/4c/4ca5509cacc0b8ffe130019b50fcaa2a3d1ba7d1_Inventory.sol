// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./Traits.sol";


interface IFallen {
    function safeTransferFrom(address from, address to, uint256 tokenId) external; 
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface ISouls {
    function mint(address to, uint256 value) external;
    function burn(address user, uint256 amount) external;
}

contract Inventory is Ownable, IERC721Receiver {
    IFallen public Fallen;
    ISouls public Souls;

    event GearObtained(address user, Gear gear);
 
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
        uint256 lastTimeClaimed;
        bool stakeLocked;
    }   

    mapping(uint256 => FallenInventory) tokenInventory;
    mapping(address => bool) public allowedAddresses;
    mapping(address => uint256) public outstandingSouls;

    uint256 stakeLockCost = 0.08 ether;

    bool public stakingActive = false;

    function claimSouls(uint256[] calldata ids) external {
        uint256 owedSouls = outstandingSouls[msg.sender];
        outstandingSouls[msg.sender] = 0;
        for(uint256 i = 0; i < ids.length; i++){
            require(tokenInventory[ids[i]].owner == msg.sender, "You do not own this Fallen");
            require(Fallen.ownerOf(ids[i]) == address(this), "You Fallen is not staked");
            require(stakingActive, "Activity is paused");
            owedSouls += getOwedSouls(ids[i]);
            tokenInventory[ids[i]].lastTimeClaimed = block.timestamp;
        }
        Souls.mint(msg.sender, owedSouls);
    }

    function getOwedSouls(uint256 id) public view returns(uint256) {
        return((block.timestamp - tokenInventory[id].lastTimeClaimed) * (getSoulScore(id) * 100 ether / 1 days));
    }

    function updateOutstandingSouls(address user, uint256 _outstandingSouls) external {
        require(allowedAddresses[msg.sender], "Address cannot update outstanding souls");
        outstandingSouls[user] += _outstandingSouls;
    }

    function unstakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(tokenInventory[ids[i]].owner == msg.sender, "You do not own this Fallen");
            require(Fallen.ownerOf(ids[i]) == address(this), "You Fallen is not staked");
            require(tokenInventory[ids[i]].stakeLocked == false, "Fallen is locked");
            require(stakingActive, "Activity is paused");
            Fallen.safeTransferFrom(address(this), msg.sender, ids[i]);
        }
    }

    function stakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(Fallen.ownerOf(ids[i]) == msg.sender, "You do not own this Fallen");
            require(stakingActive, "Activity is paused");
            tokenInventory[ids[i]].owner = msg.sender;
            Fallen.safeTransferFrom(msg.sender, address(this), ids[i]);
        }
    }

    function removeStakelock(uint256[] calldata ids) external payable{
        require(msg.value > stakeLockCost * ids.length);
        for(uint256 i = 0; i < ids.length; i++){
            require(tokenInventory[ids[i]].owner == msg.sender, "You do not own this fallen");
            require(Fallen.ownerOf(ids[i]) == address(this), "Token is not staked");
            require(tokenInventory[ids[i]].stakeLocked == true, "Token is locked");
            tokenInventory[ids[i]].stakeLocked = false;
        }
    }

    function updateGear(address owner, uint256 tokenId, uint256 slot, Gear memory newGear) external {
        require(allowedAddresses[msg.sender], "Address cannot update gear");
        if(slot==1){ tokenInventory[tokenId].head = newGear; emit GearObtained(owner, newGear); }
        else if(slot==2){ tokenInventory[tokenId].shoulders = newGear; emit GearObtained(owner, newGear); }
        else if(slot==3){ tokenInventory[tokenId].chest = newGear; emit GearObtained(owner, newGear); }
        else if(slot==4){ tokenInventory[tokenId].shirt = newGear; emit GearObtained(owner, newGear); }
        else if(slot==5){ tokenInventory[tokenId].pants = newGear; emit GearObtained(owner, newGear); }
        else if(slot==6){ tokenInventory[tokenId].feet = newGear; emit GearObtained(owner, newGear); }
        else if(slot==7){ tokenInventory[tokenId].ring = newGear; emit GearObtained(owner, newGear); }
        else if(slot==8){ tokenInventory[tokenId].artifact = newGear; emit GearObtained(owner, newGear); }
        else if(slot==9){ tokenInventory[tokenId].mainhand = newGear; emit GearObtained(owner, newGear); }
        else if(slot==10){ tokenInventory[tokenId].offhand = newGear; emit GearObtained(owner, newGear); }
        tokenInventory[tokenId].lastTimeClaimed = block.timestamp;
    }
    
    function generateTokenInfo(uint256 tokenId, address owner, bool _stakeLocked) external {
        require(msg.sender == address(Fallen), "You do not have permission to generate an inventory for that token");
        tokenInventory[tokenId].owner = owner;
        tokenInventory[tokenId].base = getBase(_rand(tokenId) % 1000);
        tokenInventory[tokenId].lastTimeClaimed = block.timestamp;
        tokenInventory[tokenId].stakeLocked = _stakeLocked;
    }

    function getBase(uint256 seed) internal pure returns(uint256 base) {
        if (seed <= 400){ return 1; }
        else if (seed <= 650){ return 2;}
        else if (seed <= 800){ return 3;}
        else if (seed <= 910){ return 5;}
        else if (seed <= 975){ return 8;}
        else if (seed <= 990){ return 12;}
        else if (seed <= 999){ return 20;}
    }

    function getSoulScore(uint256 tokenId) public view returns (uint256 soulScore) {
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
        + tokenInventory[tokenId].base);
    }

    function getInventory(uint256 tokenId) external view returns(FallenInventory memory) {
        return tokenInventory[tokenId];
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return Traits.getTokenURI(tokenInventory[tokenId], getSoulScore(tokenId), tokenId);
    }
    
    function setFallenAddress(address _fallenAddress) external onlyOwner {
        Fallen = IFallen(_fallenAddress);
    }

    function setSoulsAddress(address _soulsAddress) external onlyOwner {
        Souls = ISouls(_soulsAddress);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function _rand(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, seed)));
    }

    function toggleStakingActive() public onlyOwner {
        stakingActive = !stakingActive;
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

        return resizeArray(temp, count);
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

        return resizeArray(temp, count);
    }

    function resizeArray(uint256[] memory oldArray, uint256 size) internal pure returns (uint256[] memory array){
        uint256[] memory newArray = new uint256[](size);
        for(uint i = 0; i < size; i++) {
            newArray[i] = oldArray[i];
        }
        return newArray;
    }

    function withdrawMoney() external onlyOwner {
        require(address(this).balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }

    constructor(){}
}