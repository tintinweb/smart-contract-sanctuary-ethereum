/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract Parent {

    int256 number;

    constructor(int256 _number) {
        number = _number;
    }

    function getNumber() external view returns(int256){
        return number;
    }

    function setNumber(int256 _number)  external virtual{
        number = _number;
    }
}

contract Child is Parent {
    int256 value;

    constructor(int256 _number, int256 _value) Parent (_number){
        value = _value;
    }
    function setValue(int256  _value) public{
        value = _value;
    }
    function getValue() public view returns(int256){
        return value;
    }
    function setNumber(int256  _number ) public override{
        number = _number * 2;
    }
}