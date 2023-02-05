/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

pragma solidity ^0.8.9;


contract Calculator {
    // Set to 25 for testing 
    int256 public result;

    function equals() public view returns (int256) {
        return result;
    }

    function clear() public returns (int256) {
        return result = 0;
    }

    function add(int256 _num) public returns (int256) {
        return result = result + _num;
    }

    function subtract(int256 _num) public returns (int256) {
        return result = result - _num;
    }

    function multiply(int256 _num) public returns (int256) {
        return result = result * _num;
    }

    function divide(int256 _num) public returns (int256) {
        return result = result / _num;
    }
}