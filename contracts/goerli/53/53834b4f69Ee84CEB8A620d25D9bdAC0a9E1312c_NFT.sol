// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";

// For testing with Omnihorse breeding contract only
contract NFT is ERC721A {
    constructor(string memory name, string memory symbol) ERC721A(name,symbol) {

    }

    function mint(uint256 amount) external {
        _safeMint(msg.sender, amount);
    }
}