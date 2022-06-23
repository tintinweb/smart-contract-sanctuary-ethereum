/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Simple {

    mapping(address => uint256) public calledTimes;
    event Hello(address indexed wisher, address indexed wished,uint256 count);

    function wishMe() external returns(bool) {
        calledTimes[msg.sender]++;
        emit Hello(msg.sender, msg.sender, calledTimes[msg.sender]);
        return true;
    }

    function wishOthers(address toWish) external returns(bool) {
        calledTimes[toWish]++;
        emit Hello(msg.sender, toWish, calledTimes[toWish]);
        return true;
    }
}