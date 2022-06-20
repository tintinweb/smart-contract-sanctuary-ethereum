// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract SampleItem is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIDCounter;

    constructor() ERC721("SampleItem", "ITM") {}

    function mint(address to, string memory tokenURI)
        external
        returns (uint256)
    {
        uint256 tokenID = _tokenIDCounter.current();

        _mint(to, tokenID);
        _setTokenURI(tokenID, tokenURI);
        _tokenIDCounter.increment();

        return tokenID;
    }
}