// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract GENESIS is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("GENESIS", "GENESIS") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeicgyj7d5rtfuq3sj2davgf4xizucx5tge4y6kte6n4dii3peduozi.ipfs.nftstorage.link";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}