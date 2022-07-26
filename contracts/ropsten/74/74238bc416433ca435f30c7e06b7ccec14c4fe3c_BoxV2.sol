// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract BoxV2 {
    uint256 private value;

    enum CurrentStatus {
        TurnOff,
        TurnOn
    }
    
    CurrentStatus public currentStatus;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
        currentStatus = CurrentStatus.TurnOff;
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function statusToggle() public {
        if(currentStatus == CurrentStatus.TurnOff){
            currentStatus = CurrentStatus.TurnOn;
        }else{
            currentStatus = CurrentStatus.TurnOff;
        }
    }
}