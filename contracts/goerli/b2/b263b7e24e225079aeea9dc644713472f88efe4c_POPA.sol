// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";

contract POPA is ERC721 {

    address owner;

    constructor() ERC721("ColorToken", "CT") {
        owner = msg.sender;
    }

    function createToken() public {
        require(msg.sender == owner);
        _mint(msg.sender, 1);
    }
}