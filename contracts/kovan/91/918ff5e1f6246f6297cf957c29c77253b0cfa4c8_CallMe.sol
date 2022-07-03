/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CallMe {
    uint256 public x;

    event Log(uint256);

    constructor() {
        x = 0;
    }

    function getx() public view returns (uint256) {
        return x;
    }

    function plus() external {
        x = x + 1;
        emit Log(x);
    }

    function pluz() external {
        x += 1;
        emit Log(x);
    }

    function blus() external {
        x++;
        emit Log(x);
    }

    function bluz() external {
        ++x;
        emit Log(x);
    }

    function reset() external {
        x = 0;
    }

    function helper() external pure returns (bytes memory) {
        // return abi.encodeWithSignature("plus()");
        return abi.encodeWithSelector(this.plus.selector);
    }

}