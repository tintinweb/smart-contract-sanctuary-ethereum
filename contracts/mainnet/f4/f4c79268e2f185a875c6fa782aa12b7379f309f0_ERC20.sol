/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

/**

SHIBFLIX is a Watch 2 Earn entertainment platform on the Ethereum Network. 📺

Website: https://www.shibflix.net/

Telegram: https://t.me/Shibflix

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.16;

 
contract ERC20 {
    string public constant name = "SHIBFLIX";//
    string public constant symbol = "$SHIBFLIX";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**9;   
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}