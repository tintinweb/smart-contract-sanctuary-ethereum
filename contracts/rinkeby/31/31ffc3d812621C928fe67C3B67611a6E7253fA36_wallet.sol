/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract wallet {

    uint256 total;
    function transfer(uint256 number1) public {
        total=total-number1; 
    }
    function retrieve(uint256 number2) public {
         total=total+number2;
    }

   
    function balance() public view returns (uint256){
        return total;
    }
}