// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Demo {
    struct Stock {
        uint8[] Days;
        uint16[] fixSum;
        address user;
        mapping(uint16 => uint16) index;
    }

    mapping(uint256 => Stock) public Stocks;

    function setData(uint256 i) public {
        Stocks[i].Days.push(1);
        Stocks[i].fixSum.push(2);
        Stocks[i].user = msg.sender;
        Stocks[i].index[uint16(i)] = uint16(i);
    }
}