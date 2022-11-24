/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Assignment1 {
    
    mapping(address => uint256) public favoriteNumbers;

    function setMyNumber(uint256 number) public {
        favoriteNumbers[msg.sender] = number;
    }

    function getNumber(address a) public view returns (uint256) {
        return favoriteNumbers[a];
    }

    function getMyNumber() public returns (uint256) {
        return getNumber(msg.sender);
    }
    
}