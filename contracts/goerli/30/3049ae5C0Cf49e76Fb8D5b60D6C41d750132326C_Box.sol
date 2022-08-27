pragma solidity ^0.8.9;

contract Box {

    uint public value;

    function init(uint _value) external {
        value = _value;
    }
}