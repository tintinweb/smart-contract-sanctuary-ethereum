/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Counter {
    uint256 public count;

    function add() public {
        count++;
    }

    function value() public view returns (uint256) {
        return count;
    }
}