/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract FavouriteNumberStorage {

    mapping(address => uint256) public numbers;

    function set(uint256 number) public {
        numbers[msg.sender] = number;
    }

    function get(address someAddress) public view returns(uint256) {
        return numbers[someAddress];
    }

}