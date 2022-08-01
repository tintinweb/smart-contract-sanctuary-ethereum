/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity ^0.8.15;

contract adder {
    uint number;
    uint value;
 
    function summand(uint _number) public {
        number = _number;
    }
    function addend(uint _value) public {
        value = _value;
    }
    function sum() public view returns(uint){
        return (number + value); 
    }  
}