//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


contract MakeCount{
    uint256 private num;
    uint256 private time;
    event Increase(uint256 indexed _num, uint256 indexed time);
    event UpdateTime(address indexed updater, uint256 indexed time);
    function increaseNum() external{
        ++num;
        emit Increase(num, block.timestamp);
    }

    function updateTimeStamp() external {
        time = block.timestamp;
        emit UpdateTime(msg.sender, time);
    }

    function getNum() external view returns(uint256){
        return num;
    }
}