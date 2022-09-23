// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";

contract Wcraft is ERC721, Ownable {
    uint256 public totalSupply;
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) ERC721("testName", "testSymbol") {
        setBaseURI(_baseTokenURI);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId))) : "";
    }

    function mint(address _to) external onlyOwner {  // itemId
        _safeMint(_to, totalSupply);
        totalSupply++;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}