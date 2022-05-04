// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleStore {
    event valueChanged(address author, string oldValue, string newValue);

    address _author;
    string _value;

    function setValue(string calldata value) public {
        _author = msg.sender;
        _value = value;
        emit valueChanged(_author, _value, value);
    }

    function getValue() public view returns (string memory value) {
        return _value;
    }

    function getAuthorAndValue() public view returns (address author, string memory value) {
        return (_author, _value);
    }
}