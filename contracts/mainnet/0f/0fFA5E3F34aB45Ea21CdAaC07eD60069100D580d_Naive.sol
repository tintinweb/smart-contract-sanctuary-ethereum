/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Naive {
    bytes32 public hash;

    constructor(bytes32 _hash) payable {
        hash = _hash;
    }

    function withdraw(string calldata _secret) checkSecret(_secret) external {
        payable(tx.origin).transfer(address(this).balance);
    }

    modifier checkSecret(string calldata _secret) {
        require(keccak256(abi.encodePacked(_secret)) == hash, 'bad secret');
        _;
    }
}