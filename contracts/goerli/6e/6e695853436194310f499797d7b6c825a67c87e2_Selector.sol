/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Selector {
    constructor() {}

    function getSelector(string memory signature) public pure returns(bytes4) {
        return bytes4(keccak256(bytes(signature)));
    }
}