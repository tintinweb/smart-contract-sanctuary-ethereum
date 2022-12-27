// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyProxy {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function delegateCall(bytes calldata _data) public {
        (bool success, bytes memory data) = implementation.delegatecall(_data);
        require(success, "Implementation call failed");
    }

    function changeImplementation(address _newImplementation) public {
        implementation = _newImplementation;
    }
}