// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ModzShares {

    function withdraw() external {
        uint balance = address(this).balance;
        payable(0xca4BF72AE1b9C050729931e715Bd6653df951848).transfer(balance * 65 / 100);
        payable(0x8fcaa2Cc1bbF08ca3c60C2527dcf922A749cCB1c).transfer(balance * 35 / 100);
    }

    receive() external payable {

    }

}