// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Feed {
    function feed(address payable to) public {
        selfdestruct(to);
    }
    receive() external payable {

    }
}