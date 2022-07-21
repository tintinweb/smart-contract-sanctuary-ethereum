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
    function startDripping(address addr, uint128 multiplier) external;
    function stopDripping(address addr, uint128 multiplier) external;
    function burn(address user, uint256 amount) external;
}

contract Inventory is Ownable, IERC721Receiver {
    IFallen public Fallen;
    ISouls public Souls;

    /**

    Structure that defines Gear

    **/
    struct Gear {
        string name;
        uint16 tier;
        uint16 status;
        uint16 soulScore;
    }

    /**

    Structure that defines the Inventory of a Fallen.

    **/
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
        uint256 soulScore;
    }   

    /**

    Mapping to track the Inventory of each Fallen by Token ID.

    **/
    mapping(uint256 => FallenInventory) tokenInventory;

    /**

    Mapping to track addresses of auxiliary contracts that can modify aspects of a Fallen's Inventory.

    **/
    mapping(address => bool) public allowedAddresses;

    bool public stakingActive = false;

    /**

     * @dev 
     
     Unstakes Fallen corresponding to an array of Token IDs.

     Set claim boolean value to true if you would like to also claim $Souls earned by those Token IDs.
     */
    function unstakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(tokenInventory[ids[i]].owner == msg.sender, "You do not own this Fallen");
            require(Fallen.ownerOf(ids[i]) == address(this), "You Fallen is not staked");
            require(stakingActive, "Activity is paused");
            Fallen.safeTransferFrom(address(this), msg.sender, ids[i]);
        }
    }

    /**
     * @dev 
     
     Stakes Fallen corresponding to an array of Token IDs.
     */
    function stakeManyFallen(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(Fallen.ownerOf(ids[i]) == msg.sender, "You do not own this Fallen");
            require(stakingActive, "Activity is paused");
            tokenInventory[ids[i]].owner = msg.sender;
            Fallen.safeTransferFrom(msg.sender, address(this), ids[i]);
        }
    }

    /**
     * @dev 
     
     Updates gear slots for a corresponding Token ID.

     On deployment this is only called when a Token runs a Dungeon or Raid.
     */
    function updateGear(uint256 tokenId, uint256 slot, Gear memory newGear) external {
        require(allowedAddresses[msg.sender], "Address cannot update gear");
        if(slot==1){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].head.soulScore);  
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].head.soulScore));
                    tokenInventory[tokenId].head = newGear; 
                    }
        else if(slot==2){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].shoulders.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].shoulders.soulScore));
                    tokenInventory[tokenId].shoulders = newGear;  
                    }
        else if(slot==3){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].chest.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].chest.soulScore));
                    tokenInventory[tokenId].chest = newGear; 
                    }
        else if(slot==4){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].shirt.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].shirt.soulScore));
                    tokenInventory[tokenId].shirt = newGear; 
                    }
        else if(slot==5){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].pants.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].pants.soulScore));
                    tokenInventory[tokenId].pants = newGear; 
                    }
        else if(slot==6){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].feet.soulScore);
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].feet.soulScore));
                    tokenInventory[tokenId].feet = newGear; 
                    }
        else if(slot==7){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].ring.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].ring.soulScore));
                    tokenInventory[tokenId].ring = newGear; 
                    }
        else if(slot==8){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].artifact.soulScore); 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].artifact.soulScore));
                    tokenInventory[tokenId].artifact = newGear; 
                    }
        else if(slot==9){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].mainhand.soulScore) ; 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].mainhand.soulScore));
                    tokenInventory[tokenId].mainhand = newGear; 
                    }
        else if(slot==10){ 
                    tokenInventory[tokenId].soulScore += (newGear.soulScore - tokenInventory[tokenId].offhand.soulScore) ; 
                    Souls.startDripping(tokenInventory[tokenId].owner, (newGear.soulScore - tokenInventory[tokenId].offhand.soulScore));
                    tokenInventory[tokenId].offhand = newGear; 
                    }
        //Used to keep gas costs consistent on failed raid attempts
        else if(slot==11){ 
                    tokenInventory[tokenId].soulScore += (tokenInventory[tokenId].offhand.soulScore - tokenInventory[tokenId].offhand.soulScore) ; 
                    Souls.startDripping(tokenInventory[tokenId].owner, (tokenInventory[tokenId].offhand.soulScore - tokenInventory[tokenId].offhand.soulScore));
                    tokenInventory[tokenId].offhand = tokenInventory[tokenId].offhand; 
                    }
    }
    
    /**
     * @dev 
     
     Generates the Inventory for a newly minted Fallen.

     This can only be called by the Fallen ERC721A Contract.
     */
    function generateTokenInfo(uint256 tokenId, address owner) external {
        require(msg.sender == address(Fallen), "You do not have permission to generate an inventory for that token");
        uint256 seed = _rand(tokenId);
        tokenInventory[tokenId].owner = owner;
        tokenInventory[tokenId].base = getBase(seed % 1000);
        if (seed % 100 > 98) {tokenInventory[tokenId].artifact = Gear("Genesis Aura", 3, 1, 8); tokenInventory[tokenId].soulScore = tokenInventory[tokenId].base + 18; }
        else if (seed % 100 > 90) {tokenInventory[tokenId].mainhand = Gear("Genesis Sword", 2, 1, 5); tokenInventory[tokenId].soulScore = tokenInventory[tokenId].base + 10; }
        else if (seed % 100 > 75) {tokenInventory[tokenId].head = Gear("Genesis Helm", 2, 1, 3); tokenInventory[tokenId].soulScore = tokenInventory[tokenId].base + 5; }
        else if (seed % 100 > 50) {tokenInventory[tokenId].chest = Gear("Genesis Brestplate", 1, 1, 2); tokenInventory[tokenId].soulScore = tokenInventory[tokenId].base + 2; }
        else {tokenInventory[tokenId].chest = Gear("", 0, 0, 0); tokenInventory[tokenId].soulScore = tokenInventory[tokenId].base + 0; }
        Souls.startDripping(owner, uint128(tokenInventory[tokenId].soulScore));
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

    /**
     * @dev 
     
     Returns the Inventory of a Token ID.
     */
    function getInventory(uint256 tokenId) external view returns(FallenInventory memory) {
        return tokenInventory[tokenId];
    }

    function getSoulScore(uint256 tokenId) external view returns(uint256 SoulScore) {
        return tokenInventory[tokenId].soulScore;
    }

    function verifyOwnership(uint256 tokenId, address owner) external view {
        require(owner == tokenInventory[tokenId].owner);
        require(Fallen.ownerOf(tokenId) == address(this));
    }
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return Traits.getTokenURI(tokenInventory[tokenId], tokenInventory[tokenId].soulScore, tokenId);
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