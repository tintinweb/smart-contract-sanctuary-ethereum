/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;
contract Balance {

    function getBalance(address addr) public view returns (uint) {
        return addr.balance;
    }
}