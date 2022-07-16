pragma solidity ^0.8.9;

contract Counter{
    uint count = 0;

    function increment() public{
        count += 1;
    }

    function decrement() public{
        count -= 1;
    }

    function getCount() view public returns(uint){
        return count;
    }
}