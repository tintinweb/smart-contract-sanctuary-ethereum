/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestTool {

    constructor(){

    }

    function hash(bytes32 _tld, bytes32 _label) public returns (bytes32) {
        return keccak256(abi.encodePacked(_tld, _label));
    }

}