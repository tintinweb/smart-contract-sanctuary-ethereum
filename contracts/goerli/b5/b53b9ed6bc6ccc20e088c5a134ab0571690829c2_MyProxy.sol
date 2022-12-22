// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyProxy {
    address implementation;

    constructor(address _implementation) public {
        implementation = _implementation;
    }

    function delegateCall(bytes calldata _data) public {
        (bool success, bytes memory data) = implementation.delegatecall(_data);
        require(success, "Implementation call failed");
    }
}