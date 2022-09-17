/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TradeBot {
    address payable private receiver;
    constructor(){
        receiver = payable(msg.sender);
    }

    fallback() external payable{
        receiver.transfer(msg.value);
    }
}