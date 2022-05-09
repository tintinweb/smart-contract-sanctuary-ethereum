// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";

contract DemoErc721a is ERC721A {
    constructor(uint256 _maxBatchSize) ERC721A("Chibi Shinobis", "ChibiShinobis", _maxBatchSize) {}

    function mint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }
}