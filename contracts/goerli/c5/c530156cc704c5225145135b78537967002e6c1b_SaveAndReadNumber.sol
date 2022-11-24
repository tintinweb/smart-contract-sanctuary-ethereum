/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SaveAndReadNumber {
    mapping(address => uint256) balances;

    function saveNumber(uint256 value) public {
        balances[address(msg.sender)] = value;
    }

    function readNumber(address someAddress) view public returns(uint256) {
        return balances[someAddress];
    }
}