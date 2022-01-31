/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
contract SimpleContract {
    uint balance = 1000;
    
    function getBalance() public view returns (uint) {
        return balance;
    }  
}