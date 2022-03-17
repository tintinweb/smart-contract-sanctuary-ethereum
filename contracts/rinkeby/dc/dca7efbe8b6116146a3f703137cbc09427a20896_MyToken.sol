/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyToken  {
    uint256 public num;

    function setNum(uint256 newNum) public {
        num = newNum;
    }
}