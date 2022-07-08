/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Demo {
    uint256 num1;

    function setter(uint256 _num) public {
        num1 = _num;
    }

    function getter() public view returns(uint256) {
        return num1;
    }
}