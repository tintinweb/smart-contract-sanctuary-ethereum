// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

contract APSTest is ERC721A, Ownable, ReentrancyGuard {

    uint public price = 0.0 ether;
    uint public maxSupply = 3333;
    uint public maxTx = 2;

    bool private mintOpen = false;

    string internal baseTokenURI = "https://apstest3333.000webhostapp.com/";

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    constructor() ERC721A("APS Test", "APSTest") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function mintTo(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function mint(uint qty) external payable callerIsUser nonReentrant {
        require(mintOpen, "Sale not active");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "Not Allowed");
        uint free = balanceOf(_msgSender()) == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free), "Invalid Value");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "Exceeds Total Supply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}