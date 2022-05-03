/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract OriginTester {

    address public constructorSender;
    address public constructorTxOrigin;

    address public lastSender;
    address public lastTxOrigin;

    constructor() {
        constructorSender = msg.sender;
        constructorTxOrigin = tx.origin;

        lastSender = msg.sender;
        lastTxOrigin = tx.origin;
    }
    
    function update() public {
        lastSender = msg.sender;
        lastTxOrigin = tx.origin;
    }
}