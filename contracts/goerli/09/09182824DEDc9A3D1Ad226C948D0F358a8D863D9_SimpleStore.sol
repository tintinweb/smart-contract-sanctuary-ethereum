//SPDX-License-Identifier:MIT
pragma solidity ^0.5.7;

contract SimpleStore {
    event ValueChanged(
        address indexed author,
        string oldValue,
        string newValue
    );
    string _value = "First!!1";

    function setValue(string memory value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }

    function value() public view returns (string memory) {
        return _value;
    }
}