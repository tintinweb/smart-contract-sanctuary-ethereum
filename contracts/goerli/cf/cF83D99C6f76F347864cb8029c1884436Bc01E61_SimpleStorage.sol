// SPDX-License-Identifier: undefined

pragma solidity >= 0.5.7 <=0.8.17;

contract SimpleStorage {
    uint public _value;

    event ValueChangeEvent(address indexed owner, uint oldValue, uint newValue);

    constructor(uint _val) {
        emit ValueChangeEvent(msg.sender, _value, _val);
        _value = _val;
    }

    function getValue() external view returns(uint) {
        return _value;
    }

    function setValue(uint _val) external {
        emit ValueChangeEvent(msg.sender, _value, _val);
        _value = _val;
    }
}