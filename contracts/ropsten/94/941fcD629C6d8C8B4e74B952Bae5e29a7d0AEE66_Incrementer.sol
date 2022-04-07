/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.6.0;

contract Incrementer {
    uint256 public number;
    uint256 public number2;

    constructor(uint256 _initialNumber, uint256 _secondNumber) public {
        number = _initialNumber;
        number2 = _secondNumber;
    }

    function increment(uint256 _value) public {
        number = number + _value;
    }

    function reset() public {
        number = 0;
        number2 = 0;
    }
}