/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract StoreNumbers {
    mapping(address => uint256) favorite_numbers;

    function set_number(uint256 number) public {
        favorite_numbers[msg.sender] = number;
    }

    function get_number(address who) public view returns(uint256) {
        return favorite_numbers[who];
    }
}