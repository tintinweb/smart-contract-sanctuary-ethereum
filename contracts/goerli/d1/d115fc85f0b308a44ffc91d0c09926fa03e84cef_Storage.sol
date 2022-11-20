/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Storage {

    mapping(address => uint256) private favorite_numbers;

    function get(address some_address) public view returns(uint256) {
        return favorite_numbers[some_address];
    }

    function store(uint256 favorite_number) public {
        favorite_numbers[msg.sender] = favorite_number;
    }

}