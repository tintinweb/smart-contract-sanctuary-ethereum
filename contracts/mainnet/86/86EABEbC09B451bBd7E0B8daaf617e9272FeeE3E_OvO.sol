//SPDX-License-Identifier: MIT
// OvO
// OvO NFT, Produced by dLab.
pragma solidity ^0.8.12;
import "./ERC721.sol";
import "./Ownable.sol";

contract OvO is ERC721, Ownable
{
    string private baseURI;
    uint256 public tokenId = 0;
    uint256 public total = 5000;

    constructor(
        string memory baseURI_
    ) ERC721("OvO", "OvO") {
        baseURI = baseURI_;
    }

    function mint(address recipient) external onlyOwner {
        require(tokenId + 1 <= total, "Max supply exceed");
        tokenId += 1;
        _safeMint(recipient, tokenId);
    }

    function batchMint(address recipient, uint256 num) external onlyOwner{
        require(tokenId + num <= total, "Max supply exceed");
        for (uint256 index = 0; index < num; index++) {
            tokenId += 1;
            _safeMint(recipient, tokenId);
        }
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}