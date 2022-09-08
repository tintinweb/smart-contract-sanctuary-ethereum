/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Counter {

    uint256 public count;
    uint256 public element;

    function increaseCount() public {
        count++;
    }

    function addElement(uint256 _element) public {
        element = _element;
    }

}