// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 *    ________  ________  ________  _____ ______   ___  ________               
 *   |\   ____\|\   __  \|\   ____\|\   _ \  _   \|\  \|\   ____\              
 *   \ \  \___|\ \  \|\  \ \  \___|\ \  \\\__\ \  \ \  \ \  \___|              
 *    \ \  \    \ \  \\\  \ \_____  \ \  \\|__| \  \ \  \ \  \                 
 *     \ \  \____\ \  \\\  \|____|\  \ \  \    \ \  \ \  \ \  \____            
 *      \ \_______\ \_______\____\_\  \ \__\    \ \__\ \__\ \_______\          
 *       \|_______|\|_______|\_________\|__|     \|__|\|__|\|_______|          
 *                          \|_________|                                                                                             
 *    _____ ______   ___  ___  ________ ________ ___  ________   ________      
 *   |\   _ \  _   \|\  \|\  \|\  _____\\  _____\\  \|\   ___  \|\   ____\     
 *   \ \  \\\__\ \  \ \  \\\  \ \  \__/\ \  \__/\ \  \ \  \\ \  \ \  \___|_    
 *    \ \  \\|__| \  \ \  \\\  \ \   __\\ \   __\\ \  \ \  \\ \  \ \_____  \   
 *     \ \  \    \ \  \ \  \\\  \ \  \_| \ \  \_| \ \  \ \  \\ \  \|____|\  \  
 *      \ \__\    \ \__\ \_______\ \__\   \ \__\   \ \__\ \__\\ \__\____\_\  \ 
 *       \|__|     \|__|\|_______|\|__|    \|__|    \|__|\|__| \|__|\_________\
 *                                                                 \|_________|
 *   Creator/author/artist @brokenreality
 *   Dev @notmokk
*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract CosmicMuffins is ERC721A, Ownable, ReentrancyGuard {

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    constructor() ERC721A("Cosmic Muffins", "MUFFINS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(block.timestamp >= publicSaleStartTime, "Sale has not started");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice*quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    function setPublicPrice(uint64 price) external onlyOwner {
        saleConfig.publicPrice = price;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getOwnershipData(uint256 tokenId)  external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

}