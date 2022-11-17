/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract DuplicateContractExample {

    mapping(address => uint256) public tokenBalance;
    uint256 internalAmount;

    constructor() {
        tokenBalance[msg.sender] = 3000;
    }

    function transfer(address _to, uint _amount) public {
        tokenBalance[_to] += _amount;
    }
    function funkyFunctionCallUnfound(uint _amount) public pure returns (uint) {
        return 1e10 * _amount;
    }
}