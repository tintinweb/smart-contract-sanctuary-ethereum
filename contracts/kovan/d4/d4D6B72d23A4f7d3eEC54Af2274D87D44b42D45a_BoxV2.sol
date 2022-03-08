//store and retrieve some type of value
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //oftentimes, I need to quickly

//pick up new version of solidiyt

contract BoxV2 {
    uint256 private value;
    event ValueChanged(uint256 newValue);

    //a public function that anybody can call
    function store(uint256 newValue) public {
        value = newValue;
        //emit a new event
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    //new function that does not exist in Box.sol
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}