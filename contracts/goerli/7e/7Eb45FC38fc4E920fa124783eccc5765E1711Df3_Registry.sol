/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Registry {

    event CIDStored(address indexed owner, string indexed cid);

    function store(string calldata cid) external {
        emit CIDStored(msg.sender, cid);
    }
}