/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FavoritePorn {
    mapping (address => mapping (string => string)) favorites;

    function put(string memory name, string memory url) public {
        favorites[msg.sender][name] = url;
    }

    function get(string memory name) public view returns
    (string memory)
    {
        return favorites[msg.sender][name];
    }
}