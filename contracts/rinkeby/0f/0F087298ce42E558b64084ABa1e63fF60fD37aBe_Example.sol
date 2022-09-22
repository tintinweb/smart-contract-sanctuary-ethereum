// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";

contract Example is ERC721, Ownable {
    constructor() ERC721("nameByYh", "symbolByYh") {
    }
}