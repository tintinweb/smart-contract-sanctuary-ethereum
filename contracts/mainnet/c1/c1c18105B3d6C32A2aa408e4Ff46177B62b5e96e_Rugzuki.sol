// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Rugzuki is ERC721A, Ownable {

    uint256 public price = 0.01 ether;
    uint256 public maxTotalSupply = 10000;
    uint256 public saleStartTime;
    string private baseURI;

    constructor() ERC721A("Rugzuki", "RUGZUKI") {
        saleStartTime = block.timestamp;
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= maxTotalSupply,
            "Over maximum supply."
        );
        _;
    }

    modifier saleActive() {
        require(
            saleStartTime <= block.timestamp,
            "Sale not start yet."
        );
        _;
    }

    function setSaleTime(uint256 _time) external onlyOwner {
        saleStartTime = _time;
    }

    function mintRugzuki(uint256 _quantity)
        external
        payable
        saleActive
        mintableSupply(_quantity)
    {
        require(msg.value >= price * _quantity, "Insufficent funds.");
        
        _safeMint(msg.sender, _quantity);
    }


    function setMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}