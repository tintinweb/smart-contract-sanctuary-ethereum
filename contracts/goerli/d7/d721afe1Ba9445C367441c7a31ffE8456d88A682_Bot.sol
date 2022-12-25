/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDemo {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
}

contract Bot {
    IDemo demo;

    event MsgSender(address indexed msgSender);
    event TxOrigin(address indexed txOrigin);

    constructor(address demoContract) {
        demo = IDemo(demoContract);
    }

    function transfer(address to, uint256 amount) public {
        demo.transfer(to, amount);

        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        demo.transferFrom(from, to, amount);

        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }
}