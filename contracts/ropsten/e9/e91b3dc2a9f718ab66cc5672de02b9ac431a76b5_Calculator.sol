/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Calculator {
    uint256 public number;

    function add(uint256 addNumber) public {
        number = number + addNumber;
    }

    function minus(uint256 minusNumber) public {
        number = number + minusNumber;
    }

    function answer() public view returns (uint256) {
        return number;
    }
}