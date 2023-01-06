/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TradeAPI {
    address private implementation;

    event ret(bool, bytes);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function setImplementation(address _implementation) public {
        implementation = _implementation;
    }

    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
        emit ret(success, data);
    }
}