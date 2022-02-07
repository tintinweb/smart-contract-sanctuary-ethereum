/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Naive {
    bytes32 public hash;

    constructor(bytes32 _hash) payable {
        hash = _hash;
    }

    function take(string calldata _secret) external {
        if (keccak256(abi.encodePacked(_secret)) == hash) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}