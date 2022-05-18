/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

contract ATM{
    uint value;


    function add(uint balance) external {
        value+= balance;
    }

    function withdraw(uint balance) external {
        require(value < balance, "withdraw:Unsufficient Fund");
        value-= balance;
        
    }

    function getBalance() external view returns(uint){
        return value;
    }
    
}