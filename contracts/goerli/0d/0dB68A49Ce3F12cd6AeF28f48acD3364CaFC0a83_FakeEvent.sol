/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FakeEvent {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event FakeTransfer(
        bytes32 indexed fakeSelector,
        address indexed from,
        address indexed to,
        uint256 amount
    ) anonymous;

    function transfer(address to, uint256 amount) external {
        // transfer logic
        emit Transfer(msg.sender, to, amount);
    }

    function toto(address to, uint256 amount) external {
        // custom logic
        emit FakeTransfer(keccak256("Transfer(address,address,uint256)"), msg.sender, to, amount);
    }
}