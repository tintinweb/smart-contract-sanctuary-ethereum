pragma solidity ^0.8.7;


contract Counter{

    uint public count; 

    function addCount() external{
        count++;
    }
    function subCount() external{
        count--;
    }
}