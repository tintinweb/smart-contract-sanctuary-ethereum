// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract testing123 {
    function testing(string calldata test) external {
        response = keccak256(abi.encode(test));
    }
    
    bytes32 public response;
    
}