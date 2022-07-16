pragma solidity ^0.8.9;

contract Sum{
    int result = 0;

    function sum(int a, int b) public{
        result = a + b;
    }

    function getSum() view public returns(int){
        return result;
    }
}