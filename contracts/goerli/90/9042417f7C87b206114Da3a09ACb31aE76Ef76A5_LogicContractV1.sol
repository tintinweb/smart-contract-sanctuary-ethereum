// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LogicContractV1 {
    uint256 private value;

    //constructor are only call during deployment so the proxy will not get this initial value
    function initialize(uint256 _value) external{
        value = _value;
    }

    // Stores a new value in the contract
    function store(uint256 _newValue) public {
        value = _newValue;
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // returns the square of the _input
    function square(uint256 _input) public pure returns (uint256) {
        return _input; // implementation error
    }
}