/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity >=0.4.21 <0.6.0;

contract Value {

    uint256 public value;
    uint256 public value2;

    event updateValue(uint256 value);
    event updateValue2(uint256 value);

    function setValue(uint256 newValue) public {
        value = newValue;

        emit updateValue(newValue);
    }

    function setValue2(uint256 newValue) public {
        value2 = newValue;

        emit updateValue2(newValue);
    }
}