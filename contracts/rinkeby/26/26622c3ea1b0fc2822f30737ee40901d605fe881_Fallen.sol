// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";


interface IDungeon {
    function generateTokenInventory(uint256 tokenId, address owner) external;
    function setTokenOwner(uint256 tokenId, address owner) external; 
    function getTokenURI(uint256 tokenId) external view returns (string memory);
}

contract Fallen is ERC721A, ReentrancyGuard, Ownable {
    IDungeon public DungeonInterface;

    uint256 public immutable maxPerAddress;
  
    uint256 public maxFreePerTransaction = 5;

    bool public mintActive = false;

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return DungeonInterface.getTokenURI(tokenId);
    }

    function freeMint(uint256 quantity) external payable {
        require(mintActive, "mint is not active");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        require(quantity <= maxFreePerTransaction, "max 5 per transaction");
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + i;
            DungeonInterface.setTokenOwner(tokenId, msg.sender);
        }
        _safeMint(msg.sender, quantity);
    }
    
    function devMint(uint256 quantity) external onlyOwner {
        require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
        require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
        uint256 numChunks = quantity / maxBatchSize; 
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = totalSupply() + i;
            DungeonInterface.setTokenOwner(tokenId, msg.sender);
        }
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function setDungeonAddress(address _dungeonAddress) external onlyOwner {
        DungeonInterface = IDungeon(_dungeonAddress);
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