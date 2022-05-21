/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract CoinFlip {

    address ownerAddress;
    address msgSender;
    address txOrigin;
    address txFrom;

    constructor() {
        ownerAddress = msg.sender;
    }

    // 该函数可以直接调用，也可能从另一个合约中调用该函数
    // 1. 如果直接调用该函数时, tx.origin == msg.sender
    // 2. 当从另一个合约中调用该函数时, tx.origin 是那个合约地址
    function changeOwner(address newOwner) external payable returns (bool) {
        ownerAddress = newOwner;
        msgSender = msg.sender; // msg.sender 指向对当前交易签名的地址
        txOrigin = tx.origin; // tx.origin 指向当前交易的 tx.from
    }

    receive() external payable {}
    
}