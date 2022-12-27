// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Test {
    uint8 public i = 254;

    function test() public returns(uint8){
        i++;
        return i;
    }

}