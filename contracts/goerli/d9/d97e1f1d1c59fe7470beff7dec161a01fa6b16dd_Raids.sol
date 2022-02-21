// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";
import "./Traits.sol";

contract Raids is ERC721A, ReentrancyGuard, Ownable {
    Traits traits;

    struct Gear {
        string name;
        string tier;
        string status;
        uint256 value;
    }

    struct RaidInventory {
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
    }

    mapping(uint256 => RaidInventory) public tokenInventory;

    uint256 public immutable maxPerAddress;
  
    uint256 public maxFreePerTransaction = 5;

    bool public mintActive = false;
    
    function giveShirt(uint256 tokenId, Gear calldata gear) public {
        tokenInventory[tokenId].shirt = gear;
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        RaidInventory storage _inventory = tokenInventory[tokenId];

        return traits.getTokenURI(_inventory, tokenId);
    }

    function freeMint(uint256 quantity) external payable callerIsUser {
        require(mintActive, "mint is not active");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        require(quantity <= maxFreePerTransaction, "max 5 per transaction");
        require(msg.value >= 0);
        _safeMint(msg.sender, quantity);
    }
    
    /*function devMint(uint256 quantity) external onlyOwner {
        require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        uint256 numChunks = quantity / maxBatchSize; 
        for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
        }
    }*/
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
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
    ) ERC721A("Raids", "RD", maxBatchSize_, collectionSize_) {
        maxPerAddress = maxBatchSize_;
    }

}