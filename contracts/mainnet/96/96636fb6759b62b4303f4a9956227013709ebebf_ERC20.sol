/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

/**
Welcome to ShibX, a decentralized social media platform that aims to revolutionize the way we share and consume content on the internet. 


Website:https://www.shibxproject.com/

Telegram: https://t.me/ShibXETH

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.16;

 
contract ERC20 {
    string public constant name = "SHIBX";//
    string public constant symbol = "$SHIBX";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**9;   
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}