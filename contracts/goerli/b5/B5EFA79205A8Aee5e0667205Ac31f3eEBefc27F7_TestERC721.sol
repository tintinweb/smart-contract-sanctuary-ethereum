// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";

contract TestERC721 is ERC721 {

    constructor() ERC721("Test ERC721", "RX") {

    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}