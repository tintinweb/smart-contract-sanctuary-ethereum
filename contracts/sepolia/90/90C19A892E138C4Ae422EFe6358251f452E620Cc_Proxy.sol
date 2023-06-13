// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Proxy {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function callContract(address target, bytes memory data) external {
        (bool success, ) = target.call(data);
        require(success);
    }
}