pragma solidity ^0.8.0;

contract Counter {
    uint256 private count;

    function increment(uint256 value ) public {
        count += value;
    }

    function decrement() public {
        count--;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}