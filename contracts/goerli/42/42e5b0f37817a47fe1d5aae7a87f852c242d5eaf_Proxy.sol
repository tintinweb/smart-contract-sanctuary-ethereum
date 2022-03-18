/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/// SPDX-License-Identifier: GPL-3
pragma solidity = 0.8.13;

contract Proxy {
    address public implementation;

    event DelegatedCallStatus(bool indexed success);

    constructor(address imp) {
        implementation = imp;
    }

    function setImplementation(address imp) external {
        implementation = imp;
    }

    fallback() external {
        (bool success, ) = implementation.delegatecall(msg.data);
        emit DelegatedCallStatus(success);
    }
}