/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract testContract {

    function pay(uint256 limit) payable public {
        require(msg.sender.balance > limit,"error");
        uint gas = (msg.value == 0 ? 2300: 0);
        (bool success,) = block.coinbase.call{value:msg.value,gas:gas }("");
        require(success);
    }

    function getBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    function getAddress() public view returns (address) {
        return block.coinbase;
    }

}