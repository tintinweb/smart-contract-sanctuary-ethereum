/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
// ERC721S Contracts v2.0 Created by StarBit
pragma solidity ^0.8.15;

contract ERC721S {

    mapping (uint => address) private _owner;

    function transfer(address to, uint tokenId) public {

        // a lot of code...

        _owner[tokenId] = to;
    }

}