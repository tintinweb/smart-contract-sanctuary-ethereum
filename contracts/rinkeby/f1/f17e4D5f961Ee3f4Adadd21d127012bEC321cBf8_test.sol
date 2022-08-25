// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test {


    function testFunc() public view returns (bool) {
        return block.timestamp < 0;
    }
}