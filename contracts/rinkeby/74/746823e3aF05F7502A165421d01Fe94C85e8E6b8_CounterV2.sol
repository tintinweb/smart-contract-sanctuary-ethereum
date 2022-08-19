/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CounterV2 {
    uint256 public counter;

    event AfterIncrement(address caller, uint256 currentValue);
    event AfterDecrement(address caller, uint256 currentValue);

    modifier greaterThanOne() {
        require(counter > 0, "Cannot decrement, because counter is already 0.");
        _;
    }

    function setCounter(uint256 value) external {
        counter = value;
    }

    function addTwo() external {
        counter += 2;
        emit AfterIncrement(msg.sender, counter);
    }

    function decrementCounter() external greaterThanOne {
        counter--;
        emit AfterDecrement(msg.sender, counter);
    }
}