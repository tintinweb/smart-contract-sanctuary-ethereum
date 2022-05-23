// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    uint public count;

    function increment() external {
        count += 1;
    }
}

interface IBase {
    function count() external view returns (uint);
}

interface ICounter is IBase {
    function increment() external;
}

contract MyContract {
    function incrementCounter(ICounter _counter) external {
        _counter.increment();
    }

    function getCount(address _counter) external view returns (uint) {
        return ICounter(_counter).count();
    }
}