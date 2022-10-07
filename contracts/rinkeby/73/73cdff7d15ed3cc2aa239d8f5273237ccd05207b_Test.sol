/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Test {
    mapping(address => uint) public balances;
    event Claimed(string message, address sender);


    function claim() external {
        balances[msg.sender] += 100;
        emit Claimed("Claimed successfully to address", msg.sender);
    }
}