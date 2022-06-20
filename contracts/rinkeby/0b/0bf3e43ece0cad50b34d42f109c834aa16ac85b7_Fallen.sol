// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";


interface IInventory {
    function generateTokenInventory(uint256 tokenId, address owner) external;
    function generateTokenInfo(uint256 tokenId, address owner, bool _stakeLocked) external;
    function getTokenURI(uint256 tokenId) external view returns (string memory);
}

contract Fallen is ERC721A, ReentrancyGuard, Ownable {
    IInventory public InventoryInterface;

    uint256 public immutable maxPerAddress;
  
    uint256 public maxFreePerTransaction = 2;

    bool public mintActive = false;

    uint256 public cost = 0.05 ether;

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return InventoryInterface.getTokenURI(tokenId);
    }

     /**
     * @dev 
     
     Free mint a Fallen.

     Fallen minted for free are automatically staked in the Inventory Contract.

     These Fallen can fully participate in all aspects of the Fallen Ecosystem.

     However, there is a one time 0.08 ether cost to remove the Stake Lock from a free minted Fallen.

     This is only necessary should you want to unstake the Fallen from the Inventory Contract.
     */
    function freeMint(uint256 quantity) external {
        require(mintActive, "mint is not active");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        require(quantity <= maxFreePerTransaction, "max 2 per transaction");
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + i;
            InventoryInterface.generateTokenInfo(tokenId, msg.sender, true);
        }
        _safeMint(address(InventoryInterface), quantity);
    }

    /**
     * @dev 
     
     Mint a Fallen for 0.05 ether.

     If you wish to automatically stake the Fallen in the Inventory Contract, set the stake variable to true.

     If you wish to mint the Fallen directly to your wallet, set the stake variable to false.
     */
    function paidMint(uint256 quantity, bool stake) external payable {
        require(mintActive, "mint is not active");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        require(quantity <= maxPerAddress, "max 5 per transaction");
        require(msg.value >= cost * quantity);
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + i;
            InventoryInterface.generateTokenInfo(tokenId, msg.sender, false);
        }
        if(stake){
             _safeMint(address(InventoryInterface), quantity);
        }
        else {
             _safeMint(msg.sender, quantity);
        }
    }
    
    function devMint(uint256 quantity) external onlyOwner {
        require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        uint256 numChunks = quantity / maxBatchSize; 
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + i;
            InventoryInterface.generateTokenInfo(tokenId, msg.sender, false);
        }
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function setInventoryAddress(address _inventoryAddress) external onlyOwner {
        InventoryInterface = IInventory(_inventoryAddress);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
    
    function withdrawMoney() external onlyOwner nonReentrant {
        require(address(this).balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("Fallen", "FALLEN", maxBatchSize_, collectionSize_) {
        maxPerAddress = maxBatchSize_;
    }

}