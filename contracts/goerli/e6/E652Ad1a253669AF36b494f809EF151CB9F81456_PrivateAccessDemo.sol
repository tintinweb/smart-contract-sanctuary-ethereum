/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract PrivateAccessDemo {
    string private privateVariable;
    string public publicVariable;

    constructor(string memory privateValue, string memory publicValue) {
        privateVariable = privateValue;
        publicVariable = publicValue;
    }

    function setPrivate (string memory _new) external {
        privateVariable = _new;
    }
}