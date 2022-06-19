/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TestMultiCall {
    bool public valid;
    uint256 public x;

    constructor() {
        valid = true;
        x = 0;
    }

    function func1() external returns (uint, uint) {
        x = x + 1;
        return (1, block.timestamp);
    }

    function func2() external returns (uint, uint) {
        require(valid, "valid not valid");
        x = x + 1;
        return (2, block.timestamp);
    }

    function changeValidity() external {
        valid = !valid;
    }

    function getData1() external pure returns (bytes memory) {
        // abi.encodeWithSignature("func1()")
        return abi.encodeWithSelector(this.func1.selector);
    }

    function getData2() external pure returns (bytes memory) {
        // abi.encodeWithSignature("func1()")
        return abi.encodeWithSelector(this.func2.selector);
    }
}