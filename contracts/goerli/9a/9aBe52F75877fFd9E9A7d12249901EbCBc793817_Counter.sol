pragma solidity ^0.8.17;

contract Counter {
    uint256 private count;

    function getCount() view external returns(uint256) {
        return count;
    }

    function increment() external {
        count += 2;
    }

    function decrement() external {
        count -= 2;
    }

    fallback() external {
        require(false, "Reached Fallback");
    }
}