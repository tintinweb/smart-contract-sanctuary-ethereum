/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract mover{

    address payee1 = 0x1078471d1d3897B5C29570953d8299F42b6A9110;
    address payee2 = 0x1Fa68c49d31F4b1e7F5DFbCB58cc580B7A5aAEf4;

    function pay() external {
        uint256 balance = address(this).balance;
        uint256 availBalance = balance - .005 ether;
        uint256 payee1Split = availBalance * 6 / 10;
        uint256 payee2Split = availBalance * 4 / 10;
        payee1.call{value: payee1Split}("");
        payee2.call{value: payee2Split}("");
    }

    receive() external payable {
        
    }
}