/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleCounter {
    uint public count = 0;

    event Logger(string message, uint timestamp,uint blocknbr, uint curcount);
    
    function increment() public returns(uint) {
        count += 1;
        emit Logger("add 1", block.timestamp,block.number, count);
        return count;
    }

    function addInteger(uint intToAdd) public returns(uint) {
        count += intToAdd;
        emit Logger("add x", block.timestamp,block.number, count);
        return count;
    }

    function multiplyInteger(uint intToMultiply) public returns(uint) {
        count = count * intToMultiply;
        emit Logger("multiply x", block.timestamp,block.number, count);
        return count;
    }

    function reset() public returns(uint) {
        count = 0;
        emit Logger("reset", block.timestamp,block.number, count);
        return count;
    }
}