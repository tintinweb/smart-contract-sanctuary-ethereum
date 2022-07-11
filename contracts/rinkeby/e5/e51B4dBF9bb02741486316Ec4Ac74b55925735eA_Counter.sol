//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
interface ICounter {
    function count() external view returns (uint);
    function increment() external;
}

contract Counter {
    function incrementCounter(address _counter) external {
        ICounter(_counter).increment();
    }

    function getCount(address _counter) external view returns (uint) {
        return ICounter(_counter).count();
        
    }
}