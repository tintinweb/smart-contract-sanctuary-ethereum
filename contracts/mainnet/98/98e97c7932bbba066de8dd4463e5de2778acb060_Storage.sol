/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract Storage {

   mapping(address => mapping(uint256 => string)) public data;

    function save(uint256 time, string memory txt) public {
        data[msg.sender][time]=txt;
    }
}