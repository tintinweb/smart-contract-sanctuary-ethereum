/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Voucher {

    mapping (address => uint) public balance;

    constructor () {
        balance[msg.sender] = 100;
    }

    function transfer(uint amount, address target) public {
        require(balance[msg.sender] >= amount, "Non hai abbastanza voucher! :(");
        balance[msg.sender] -= amount;
        balance[target] += amount;
    }

}