/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
//0xd50a9a933665a1c2e39AaE1Cb82D858cA1e198A7
pragma solidity ^0.8.16;
contract ceshi {
    uint256 private count=0;
    mapping (address => uint256) private balance;
    function increa (uint256 id) public returns (uint256) {
        balance[msg.sender]=id**6;
        count +=1;
        return count;
    }
    function counters () public view returns(uint256) {
        return count;
    }
    function balances() public view returns(uint256) {
        return balance[msg.sender];
    }
}