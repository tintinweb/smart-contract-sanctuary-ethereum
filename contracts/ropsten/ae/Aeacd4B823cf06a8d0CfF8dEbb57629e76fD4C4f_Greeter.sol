//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Greeter {
    uint private x;
    function name() external view returns(uint256) {
        return x;
    }
}