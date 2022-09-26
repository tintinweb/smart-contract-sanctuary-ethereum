// SPDX-License-Identifier: GPL-3.0

/*
 * Real Bullish NFT                
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";

error SoldOut();
error InvalidPrice();
error InvalidQuantity();

contract Bullish is ERC721A {
    
    uint256 public immutable maxSupply = 666; 
    uint256 public price = 0.001 ether;
    uint256 public maxPerWallet = 5;
    mapping(address => uint256) public addressMintBalance;
    string public _baseTokenURI;

    function mint(uint256 qty) external payable {
        if (totalSupply() + qty  > maxSupply) revert SoldOut();
        if (msg.value < price * qty) revert InvalidPrice();
        if (addressMintBalance[msg.sender] + qty > maxPerWallet) revert InvalidQuantity();
        addressMintBalance[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function ownerMint(uint256 qty, address recipient) external onlyOwner {
        if (totalSupply() + qty > maxSupply) revert SoldOut();
        _safeMint(recipient, qty);
    }
    
    address _owner;
    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("Real Bullish", "BULL") {
        _owner = msg.sender;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}