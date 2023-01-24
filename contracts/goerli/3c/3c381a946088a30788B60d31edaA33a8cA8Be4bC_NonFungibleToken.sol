// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NonFungibleToken is ERC721, Ownable {
    constructor() ERC721("Non Fungible Token", "NFT") {}

    function safeMint(
        address to,
        uint256 first,
        uint256 last
    ) public onlyOwner {
        for (uint256 i = first; i <= last; i++) {
            _safeMint(to, i);
        }
    }
}