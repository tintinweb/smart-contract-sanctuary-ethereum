/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyBank {

    uint256 money;

    function balance() public view returns (uint256){
       return money;
    } 

    function deposit(uint256 amount) public {
        money+=amount;
    }

    function withdraw(uint256 amount2) public {
        money-=amount2;
    }  
  
}