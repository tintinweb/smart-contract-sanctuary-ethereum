pragma solidity >=0.7.3;

contract Counter {
    uint counter;

    event Increment(uint256 value);
    event Decrement(uint256 value);

    constructor() {
        counter = 0;
    }

    function getCounter() view public returns(uint256) {
        return counter;
    }

    function increment() public {
        counter += 1;
        emit Increment(counter);
    }

    function decrement() public {
        counter -= 1;
        emit Decrement(counter);
    }

}