/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// File: contracts/Interface.sol

pragma solidity ^0.6.12;

 //SPDX-License-Identifier: UNLICENSED

interface ICounter {
    function count() external view returns (uint);
    function increment() external;
}

contract Interaction {
    address counterAddr;

    function setCounterAddr(address _counter) public payable {
        counterAddr =_counter;
    }

    function getCount() external view returns (uint) {
        return ICounter(counterAddr).count();
    }

    function RemoteIncrease() external {
        ICounter(counterAddr).increment();
    }
}