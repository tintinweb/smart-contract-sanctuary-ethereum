/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public storedData;
    event ValueChanged(
        address indexed author,
        string oldValue,
        string newValue
    );
    string public _value;
    constructor(string memory value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }

    function set(uint256 x) public {
        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }

    function getValue() public view returns (string memory) {
        return _value;
    }

    function setValue(string memory value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }
}