// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs
import "./ERC721A.sol";
pragma solidity ^0.8.4;

contract AT is ERC721A{
    constructor() ERC721A("_hi","very HI"){
        _mintERC2309(msg.sender,5000);
    }
}