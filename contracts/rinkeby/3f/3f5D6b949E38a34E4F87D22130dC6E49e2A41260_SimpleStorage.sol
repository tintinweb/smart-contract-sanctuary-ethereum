/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.24;

contract SimpleStorage {

    event ValueChanged(address indexed author, string oldValue, string newValue);

    string _value;

    constructor(string value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }

    function getValue() view public returns (string) {
        return _value;
    }

    function setValue(string value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }
}