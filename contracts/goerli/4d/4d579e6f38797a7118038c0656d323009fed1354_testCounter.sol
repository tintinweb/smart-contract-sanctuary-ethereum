/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract testCounter {
    uint256 public count;

    function increaseCount() public {
        count++;
    }
}