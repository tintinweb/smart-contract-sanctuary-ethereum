// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract fagenesis is ERC721A, Ownable {

    uint256 public constant collectionSize = 1000;
    uint256 public constant mintPrice = 0.1 ether;

    constructor(
    ) ERC721A("FinanceApe Genesis Test", "FGT") {
    }

    function mint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        require(_totalMinted() < collectionSize, "Collection Size reached!");
        
        if (_totalMinted() + quantity > collectionSize) {
            quantity = collectionSize - _totalMinted();
        }
        
        uint256 requiredPayment = quantity * mintPrice;
        require(msg.value >= requiredPayment, "ETH insufficient.");
        
        _mint(msg.sender, quantity);
        
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }

    }

    string private _baseTokenURI;
    string private _unrevealedURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : _unrevealedURI;
    }

    function setUnrevealedURI(string calldata unrevealedURI) external onlyOwner {
        _unrevealedURI = unrevealedURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}