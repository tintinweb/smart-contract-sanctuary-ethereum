/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.4.24;
contract Calculator {
    int private lastValue = 0;
    function Add(int a, int b) public returns (int) {
        lastValue = a + b;
        return lastValue;
    }
    function Subtract(int a, int b) public returns (int) {
        lastValue = a - b;
        return lastValue;
    }
    function LastOperation() public constant returns (int) {
        return lastValue;
    }
}