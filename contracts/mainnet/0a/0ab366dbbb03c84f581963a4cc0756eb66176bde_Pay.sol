/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {
    function transferFrom(address sender, address spender, uint amount) external returns(bool);
}


contract Pay {
    address constant PAYEE = 0x13eBE96CF08086B495dd873c8c5185706df9Fd6E;
    function pay(uint amountInUSD) external {
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transferFrom(
            msg.sender, PAYEE, amountInUSD * 1e6
        );
    }
}