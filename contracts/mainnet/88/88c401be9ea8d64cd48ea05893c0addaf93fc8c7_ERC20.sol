/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

/**

🔥 Welcome to DORAGON $DORA 🔥

Doragon is an ETH-based passive income, miner eco-system that enables sustainable, yet exciting passive income returns through a gamified front 🐉

Website: http://www.doragonearn.com

Telegram: https://t.me/DoragonETH

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.16;

 
contract ERC20 {
    string public constant name = "DORAGON";//
    string public constant symbol = "$DORA";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**9;   
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}