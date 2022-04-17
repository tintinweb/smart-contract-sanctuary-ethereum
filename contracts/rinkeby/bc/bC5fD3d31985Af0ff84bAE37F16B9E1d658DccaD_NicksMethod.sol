// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NicksMethod {
    uint256 public a;
    bytes4 public selector;
    constructor() {
        a = 3456;
        // bytes memory signaturehash = abi.encodeWithSignature("increment()");
        // selector = bytes4(bytes32(abi.encode(signaturehash)));
    }

    function increment() external {
        a+=1;
    }
}