/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

/**

http://t.me/Portal0xDegen

https://0xdegen.net/

https://twitter.com/0xdegenprotocol

KYC ✅

*/
// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.20;

contract OxDegen {
    string public constant name = "0xDegen";//
    string public constant symbol = "0xDEGEN";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**decimals;
    event Transfer(address, address, uint256);
    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}