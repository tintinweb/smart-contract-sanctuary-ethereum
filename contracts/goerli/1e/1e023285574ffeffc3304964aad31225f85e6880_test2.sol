// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "./contract1.sol";

contract test2 is test1 {

    uint hello;
    uint32 public hi;

    function aaa(string memory _abc) public returns (uint) {
        hello = uint(keccak256(abi.encodePacked(_abc, a, b, c, d)));
        return hello;
    }

    

}