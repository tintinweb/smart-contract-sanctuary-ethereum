/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract MockVault {


    event Deposit(address to, uint256 value);


    function deposit() external payable  {

        emit Deposit(msg.sender, msg.value); 


    }

 
}