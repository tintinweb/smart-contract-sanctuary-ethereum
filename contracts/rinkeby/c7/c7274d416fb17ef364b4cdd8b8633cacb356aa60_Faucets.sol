/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.4;

contract Faucets {
    receive () external payable{}

    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 200000000000000000);
        msg.sender.transfer(withdraw_amount);
    }
}