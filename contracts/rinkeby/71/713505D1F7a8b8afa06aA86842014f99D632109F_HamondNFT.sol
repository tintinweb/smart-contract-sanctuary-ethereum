// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract HamondNFT is ERC721, Ownable {

    uint256 public totalSupply;

    constructor() ERC721("HamondNFT", "HMNFT") {}

    function safeMint(address to) public {
        totalSupply++;
        _safeMint(to, totalSupply);
    }
}