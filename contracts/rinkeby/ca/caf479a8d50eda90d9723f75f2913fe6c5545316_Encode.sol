/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.10;

contract Encode {
    uint256 public x;

    constructor() {
        x = 0;
    }

    function increaseX() external {
        x += 1;
    }

    function encode() external pure returns (bytes memory) {
        return abi.encode("increaseX()");
    }

    function encodePacked() external pure returns (bytes memory) {
        return abi.encodePacked("increaseX()");
    }

    function encodeWithSelector() external pure returns (bytes memory) {
        return abi.encodeWithSelector(this.increaseX.selector);
    }

    function encodeWithSignature() external pure returns (bytes memory) {
        return abi.encodeWithSignature("increaseX()");
    }

    function getSelector() external pure returns (bytes32) {
        return this.increaseX.selector;
    }

}