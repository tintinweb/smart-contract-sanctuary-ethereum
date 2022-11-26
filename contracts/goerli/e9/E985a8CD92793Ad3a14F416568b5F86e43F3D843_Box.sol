// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Box {
    uint256 public val;

    // constructor (uint _val){
    //     val = _val;
    // }

    function initialize(uint256 _val) external {
        val = _val;
    }
}
//0x338E88ABbAa0bB827Dc03388d9Ff3dF9a456C373