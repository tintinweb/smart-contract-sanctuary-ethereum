/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//Dummy contract that just adds to the value of *num* whenever *setNum* function is called.
contract Impl_A {
    uint256 public num;

    function setNum(uint256 _num) public {
        num += _num;
    }

    function getNum() public view returns (uint256) {
        return num;
    }
}