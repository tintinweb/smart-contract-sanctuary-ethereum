/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract CoinFlip {

    string public name;
    address public ownerAddress;
    address public msgSender;
    address public txOrigin;

    constructor() {
        name = 'CoinFlip';
        ownerAddress = msg.sender;
    }

    // 该函数可以直接调用，也可能从另一个合约中调用该函数
    // 0. tx.origin 指向原始交易的 tx.from (即对原始交易签名的地址)
    // 1. 如果直接调用该函数时, tx.origin == msg.sender
    // 2. 当从另一个合约中调用该函数时, msg.sender 是那个合约地址
    function changeOwner(address newOwner) external payable returns (bool) {
        ownerAddress = newOwner;
        msgSender = msg.sender;
        txOrigin = tx.origin; 
    }

    receive() external payable {}
    
}