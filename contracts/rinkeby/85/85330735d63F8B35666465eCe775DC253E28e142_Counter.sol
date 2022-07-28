// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

/// @title Counter Contract - A simple counter contract for the safe apps workshop
/// @author Daniel Somoza - <[email protected]>
contract Counter {
    event CounterChanged(
        string eventType,
        int256 prevCounter,
        int256 newCounter
    );

    mapping(address => int256) private addressToCounter;

    function increment() external {
        int256 prevCounter = addressToCounter[msg.sender];
        addressToCounter[msg.sender] = prevCounter + 1;
        emit CounterChanged(
            "increment",
            prevCounter,
            addressToCounter[msg.sender]
        );
    }

    function decrement() external {
        int256 prevCounter = addressToCounter[msg.sender];
        addressToCounter[msg.sender] = prevCounter - 1;
        emit CounterChanged(
            "decrement",
            prevCounter,
            addressToCounter[msg.sender]
        );
    }

    function reset() external {
        int256 prevCounter = addressToCounter[msg.sender];
        addressToCounter[msg.sender] = 0;
        emit CounterChanged("reset", prevCounter, addressToCounter[msg.sender]);
    }

    function setCounter(int256 _newValue) external {
        int256 prevCounter = addressToCounter[msg.sender];
        addressToCounter[msg.sender] = _newValue;
        emit CounterChanged(
            "setCounter",
            prevCounter,
            addressToCounter[msg.sender]
        );
    }

    function getCounter() public view returns (int256) {
        return addressToCounter[msg.sender];
    }
}