/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string_0 = "My first step!";
    string public _string_1 = "Goal, creat an shit nft in the next bull! ";
    uint public _number = 5;
    uint public number_1 = _number + 1 ;
    uint public number_2 = 2**3;
    uint public number_3 =7%3;
    bool public number_4 = number_2>=number_3;
    function minusPayable() external payable returns(uint256 balance) {
    balance = address(this).balance;
    }

}