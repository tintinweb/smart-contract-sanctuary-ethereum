// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract JustTest721A is ERC721A {
    uint public price = 0.005 ether;
    uint public maxSupply = 10000;
    uint public maxTx = 20;

    bool private mintOpen = false;

    string internal baseTokenURI = '';

    constructor() ERC721A("JustTest721A", "JustTest721A") {}

    function toggleMint() external {
        mintOpen = !mintOpen;
    }
    
    function setPrice(uint newPrice) external {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external {
        _mintTo(to, qty);
    }

    function buy(uint qty) external payable {
        require(mintOpen, "Sale not active");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "Not Allowed");
        uint free = balanceOf(_msgSenderERC721A()) == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free), "Invalid Value");
        _mintTo(_msgSenderERC721A(), qty);
    }

    function mint(uint qty) external payable {
        require(qty <= maxTx && qty > 0, "Not Allowed");
        require(msg.value >= price * qty, "Invalid Value");
        _mintTo(_msgSenderERC721A(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "Exceeds Total Supply");
        _mint(to, qty);
    }
    
    function withdraw() external {
        payable(_msgSenderERC721A()).transfer(address(this).balance);
    }
}