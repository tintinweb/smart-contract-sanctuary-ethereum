// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import './ERC721A.sol';
error SoldOut();
error InvalidPrice();
error InvalidQuantity();

contract BOX_V2 is ERC721A {
    uint256 public immutable maxSupply = 333; 
    uint256 public price = 0.001 ether;
    uint256 public maxPerWallet = 5;
    mapping(address => uint256) public addressMintBalance;

    function mint(uint256 qty) external payable {
        if (totalSupply() + qty  > maxSupply) revert SoldOut();
        if (msg.value < price * qty) revert InvalidPrice();
        if (addressMintBalance[msg.sender] + qty > maxPerWallet) revert InvalidQuantity();
        addressMintBalance[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }
    
    address _owner;
    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("It's a box II", "BOX") {
        _owner = msg.sender;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "ipfs://QmWtJEVnUHfGTBBdcZVsrrYFJiiZ6o9X65ZRo8wv5oWx6T/hidden.json";
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}