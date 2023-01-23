// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EventEmittor {

    enum Operators {
        Add,
        Substract,
        Multiple,
        Divide
    }
    event AddOper(address indexed caller, uint256 time, uint256 value, Operators indexed operator);
    event SubOper(address indexed caller, uint256 time, uint256 value, Operators indexed operator);
    event MultiOper(address indexed caller, uint256 time, uint256 value, Operators indexed operator);
    event DivOper(address indexed caller, uint256 time, uint256 value, Operators indexed operator);

    uint256 StateValue;

    function add_number(uint256 _value) external {
        StateValue += _value;
        emit AddOper(msg.sender, block.timestamp, _value, Operators.Add);
    }

    function sub_number(uint256 _value) external {
        StateValue -= _value;
        emit SubOper(msg.sender, block.timestamp, _value, Operators.Substract);
    }

    function multi_number(uint256 _value) external {
        StateValue *= _value;
        emit MultiOper(msg.sender, block.timestamp, _value, Operators.Multiple);
    }

    function div_number(uint256 _value) external {
        StateValue /= _value;
        emit DivOper(msg.sender, block.timestamp, _value, Operators.Divide);
    }
}