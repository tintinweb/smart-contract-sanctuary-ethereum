// SPDX-License-Identifier: MIT

/*
 * RoyalAngle            
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";

error SoldOut();
error InvalidPrice();
error InvalidQuantity();

contract RoyalAngle is ERC721A {
    uint256 public immutable maxSupply = 999; 
    uint256 public price = 0.001 ether;
    uint256 maxFreePerBlock = 10;
    uint256 public maxPerTx = 10;
    string public _baseTokenURI;
    mapping(uint256 => uint256) _freeForBlock;

    /**
     *  PAY ATTENTION
     *  ONLY LIMITED FREEMINTS FOR EACH BLOCK. ERALY ARRIVE. ERALY GOT
     *  IF YOU WANT GOT ONE FOR FREE, YOU MAY RISE A BIT OF GASPRICE OR PAY 0.001 FOR EACH ONE
     */
    function mint(uint256 amount) payable public {
        require(msg.sender == tx.origin, "No Bot");
        if (msg.value == 0) {
            require(_freeForBlock[block.number] < maxFreePerBlock, "No More Free For This Block");
            require(totalSupply() + 1 <= maxSupply, "Sold Out");
            require(amount == 1);
            _freeForBlock[block.number]++;
            _safeMint(msg.sender, 1);
        } else {
            require(totalSupply() + amount <= maxSupply, "Sold Out");
            require(amount <= maxPerTx);
            uint256 cost = amount * price;
            require(msg.value >= cost, "Pay For");
            _safeMint(msg.sender, amount);
        }
    }

    address _owner;
    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("Royal Angle", "RAngle") {
        _owner = msg.sender;
    }

    function setPrice(uint256 newPrice, uint256 maxW) external onlyOwner {
        price = newPrice;
        maxPerTx = maxW;
    }

    function setMaxFreeBlocl(uint256 maxF) external onlyOwner {
        maxFreePerBlock = maxF;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}