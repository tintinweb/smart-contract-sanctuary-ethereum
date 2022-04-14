/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity ^0.8.13;

// SPDX-License-Identifier: GPL-3.0-or-later

contract orthoverseTalk  {

/* Copyright Secret Beach Solutions 2022 */
/* John Rigler [email protected] */

address public owner;

constructor() {
    owner = msg.sender;
   }

function talk(

    string memory message,
    address payable receiver

) public
    {
    payable(receiver).transfer(0);
    }

function cashout ( uint256 amount ) public
    {
    address payable Payment = payable(owner);
       if(msg.sender == owner)
            Payment.transfer(amount);
    }
    fallback () external payable {}
    receive () external payable {}
}