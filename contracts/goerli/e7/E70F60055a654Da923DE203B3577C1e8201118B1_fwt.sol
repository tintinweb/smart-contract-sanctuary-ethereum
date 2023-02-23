// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract fwt is ERC721A, Ownable {

    uint256 constant _collectionSize = 5000;

    constructor(
    ) ERC721A("FinWhitelist", "FWT") {
    }

    function mint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        // require(_totalMinted() + quatity <= CollectionSize, "Exceed Collection Size");  
        require(_totalMinted() <= _collectionSize, "Collection Size reached!");
        if (_totalMinted() + quantity > _collectionSize) {
            quantity = _collectionSize - _totalMinted();
        }
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}