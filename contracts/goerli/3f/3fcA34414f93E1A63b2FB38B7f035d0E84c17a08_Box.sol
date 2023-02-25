// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Box {
    uint256 private _value;

    event ValueChanged(uint256 value);

    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }


    string private _stringValue;

    event StringValueChanged(string stringValue);

    function storeString(string memory stringValue) public {
        _stringValue = stringValue;
        emit StringValueChanged(stringValue);
    }

    function retrieveString() public view returns (string memory) {
        return _stringValue;
    }
}