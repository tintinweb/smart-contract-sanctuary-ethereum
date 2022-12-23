/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

/**

Welcome to Shumo, the native token that powers ShumoSwap, an autonomous trading bot in your browser that helps to build passive income at little risk! 🤖

Website: http://www.shumoproject.com

Telegram: https://t.me/ShumoETH

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.16;

 
contract ERC20 {
    string public constant name = "SHUMO";//
    string public constant symbol = "$SHUMO";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**9;   
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}