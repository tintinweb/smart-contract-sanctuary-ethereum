/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IUSDT {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract preSale {
    constructor() {}
    function getDeposit(uint256 _amount) public returns (bool) {
        IUSDT usdt = IUSDT(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        usdt.transferFrom(msg.sender, address(this), _amount);
    }
}