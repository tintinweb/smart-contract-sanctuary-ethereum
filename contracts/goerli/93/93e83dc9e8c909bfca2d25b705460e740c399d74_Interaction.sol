/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

interface ICounter {
    function count() external view returns (uint);
    function increment() external;
}

contract Interaction {
    address counterAddr;

    function setCounterAddr(address _counter) public payable {
       counterAddr = _counter;
    }

    function getCount() external view returns (uint) {
        return ICounter(counterAddr).count();
    }
}