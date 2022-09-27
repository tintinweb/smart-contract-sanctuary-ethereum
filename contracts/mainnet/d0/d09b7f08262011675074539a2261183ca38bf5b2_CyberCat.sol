// SPDX-License-Identifier: MIT

/*
 * CyberCat            
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";

contract CyberCat is ERC721A {
    uint256 public immutable maxSupply = 333; 
    uint256 public price = 0.003 ether;

    function mint(uint256 amount) payable public {
        if (totalSupply() < maxSupply / 2) {
            _safeMint(msg.sender, 1);
            return;
        }
        require(totalSupply() + amount <= maxSupply, "Sold Out");
        require(msg.value >= amount * price, "Pay For");
        _safeMint(msg.sender, amount);
    }

    address _owner;
    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("CyberCat", "CCT") {
        _owner = msg.sender;
        _safeMint(msg.sender, 5);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmeS4nSorJhw3QPVfaYLQ7RBggcMZkJNKGsM38mbUHhZbr/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}