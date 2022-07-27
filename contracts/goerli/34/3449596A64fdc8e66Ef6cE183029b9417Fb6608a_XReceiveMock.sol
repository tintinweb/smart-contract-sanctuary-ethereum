// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract XReceiveMock {
    address public xprovider;
    uint256 public value;

    modifier onlyXProvider() {
        require(msg.sender == xprovider);
        _;
    }

    constructor(
        address _xprovider
    ){
        xprovider = _xprovider;
    }

    function xReceiveAndSetSomeValue(uint256 _value)  external onlyXProvider {
        value = _value;
    }
}