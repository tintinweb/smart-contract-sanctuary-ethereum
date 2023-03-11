// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Proxy {
    address public implementation;
    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external payable {
        (bool s, ) = implementation.delegatecall(msg.data);
        require(s);
    }

    receive() external payable {

    }
}