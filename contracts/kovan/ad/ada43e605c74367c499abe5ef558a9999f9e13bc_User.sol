/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract User {
    uint256 private num;

    function set(uint256 _num) external {
        num = _num;
    }

    function get() public view returns (uint256) {
        return num;
    }
}