/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract FavNumbers {

    mapping(address => uint256) private userToNumber;

    function set(uint256 number) public {
        userToNumber[msg.sender] = number;
    }

    function get(address user) public view returns(uint256) {
        return userToNumber[user];
    }

}