// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Demo {
    function payCoinbase() public payable {
        if (msg.value > 0) {
            payable(block.coinbase).transfer(msg.value);
        }
    }
}