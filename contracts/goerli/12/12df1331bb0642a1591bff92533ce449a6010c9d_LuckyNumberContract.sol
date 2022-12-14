/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LuckyNumberContract {

    mapping(address => uint256) private userToNumber;

    function setLuckyNumber(uint256 number) public {
        userToNumber[msg.sender] = number;
    }

    function getLuckyNumber() public view returns (uint256){
        return userToNumber[msg.sender];
    }

}