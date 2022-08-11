// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brilliant
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    BRILLIANT    //
//                 //
//                 //
/////////////////////


contract BRN is ERC721Creator {
    constructor() ERC721Creator("Ladacoin", "LDN") {}
}