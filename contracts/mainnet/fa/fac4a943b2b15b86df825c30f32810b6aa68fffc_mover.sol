/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract mover{

    address payee1 = 0xcf93fc754f874fafb3Fc0992ED92310790B1A4bc;
    address payee2 = 0xE77a2D0976b5658369B3906BBAE4d27Cb85531AC;

    function pay() external {
        uint256 balance = address(this).balance;
        uint256 payee1Split = balance * 6 / 10;
        uint256 payee2Split = balance * 4 / 10;
        payee1.call{value: payee1Split}("");
        payee2.call{value: payee2Split}("");
    }

    receive() external payable {

    }
}