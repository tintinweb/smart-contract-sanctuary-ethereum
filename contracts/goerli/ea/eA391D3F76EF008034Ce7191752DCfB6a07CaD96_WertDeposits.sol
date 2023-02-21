/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Receivable
 * @dev Implements receivable contract for eth payments through Wert
 */
contract WertDeposits {
    mapping(address => uint) balances;

    function deposit() payable external {
        // record the value sent 
        // to the address that sent it
        balances[msg.sender] += msg.value;
    }
}