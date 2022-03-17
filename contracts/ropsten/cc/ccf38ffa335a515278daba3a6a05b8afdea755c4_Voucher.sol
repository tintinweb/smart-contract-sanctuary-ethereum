/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Voucher {

    // tabella dei saldi
    mapping (address => uint) public balances;

    constructor () {
        balances[0xaFdA3BF7ed0428bA9302962aD4CBFE037612F0E3] = 100;
    }

    // per trasferire voucher
    function transfer (address destinatario, uint amount) public {
        require(balances[msg.sender] >= amount, "Non hai abbastanza voucher!");
        balances[msg.sender] -= amount;
        balances[destinatario] += amount;
    }

}