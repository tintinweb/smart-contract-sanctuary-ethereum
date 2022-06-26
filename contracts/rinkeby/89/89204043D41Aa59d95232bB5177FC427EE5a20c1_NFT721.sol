// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFT721 is Ownable, ERC721 {
    string _baseTokenURI;
    uint256 index;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        index = 1;
    }

    function mint() external onlyOwner {
        _safeMint(tx.origin, index);
        index++;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}