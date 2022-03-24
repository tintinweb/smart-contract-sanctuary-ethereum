/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title BalanceCounter
 * @dev BalanceCounter & retrieve value in a variable
 */

contract BalanceCounter {
    mapping(address => int) public balances;

    function incrementCounter() public {
        balances[msg.sender] += 1;
    }
    function decrementCounter() public {
        balances[msg.sender] = -1;
    }

    function getCount() public view returns (int) {
        return balances[msg.sender];
    }
}