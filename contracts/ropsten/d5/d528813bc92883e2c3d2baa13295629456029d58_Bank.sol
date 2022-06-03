/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Bank {
    address private MyAddress;

    function getBalance() public view returns(uint256){
        return MyAddress.balance;
    }
}