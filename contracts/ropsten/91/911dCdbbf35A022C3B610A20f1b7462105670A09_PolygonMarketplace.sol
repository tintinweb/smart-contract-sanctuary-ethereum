// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract PolygonMarketplace is  Pausable, Ownable , ERC721Enumerable{
    using Counters for Counters.Counter;

    uint256 public  maxSupply = 0;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("polygonMarketplace", "PM") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        require (totalSupply() < maxSupply , "Exceed Total Supply");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setmaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}