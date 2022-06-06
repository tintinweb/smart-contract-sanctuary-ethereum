/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract FrontEndTest {

    uint256 number;
    mapping(address => uint256) public balance;


    function updateBal(uint newBal) public {
      balance[msg.sender] = newBal;
    }

    
    function retrieveBal(address addy) public view returns(uint256){
        return balance[addy];
    }

}