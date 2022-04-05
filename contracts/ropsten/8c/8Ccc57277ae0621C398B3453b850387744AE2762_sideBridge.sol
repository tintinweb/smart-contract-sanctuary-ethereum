/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract sideBridge {
    address gateway;
    address owner;
    constructor (address _gateway) {
        gateway = _gateway;
        owner = msg.sender;
    }

}