// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Counter {
    int256 public counter;

    event CounterCreated(address userAddress, address counterAddress);

    event CounterChanged(string eventType, int256 counter, address userAddress);

    constructor() {
        counter = 0;
        emit CounterCreated(msg.sender, address(this));
    }

    function increment() public {
        counter = counter + 1;
        emit CounterChanged("increment", counter, msg.sender);
    }

    function decrement() public {
        counter = counter - 1;
        emit CounterChanged("decrement", counter, msg.sender);
    }

    function reset() public {
        counter = 0;
        emit CounterChanged("reset", counter, msg.sender);
    }

    function setCounter(int256 value) public {
        counter = value;
        emit CounterChanged("setCounter", counter, msg.sender);
    }
}

pragma solidity ^0.8.0;

import "./Counter.sol";

contract CounterFactory {
    mapping(address => Counter[]) userCounterContracts;

    function createCounter() public {
        Counter counter = new Counter();
        userCounterContracts[msg.sender].push(counter);
    }

    function findCounterContracts(address userAddress)
        public
        view
        returns (Counter[] memory)
    {
        return userCounterContracts[userAddress];
    }
}