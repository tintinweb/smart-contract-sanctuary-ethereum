// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 *Submitted for verification at Etherscan.io on 2023-03-09
 */

contract Test {
    function checkEncode(address _address) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }
}