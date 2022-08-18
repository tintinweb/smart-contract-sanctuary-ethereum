pragma solidity ^0.8.0;

contract Counter {
    uint256 public count;

    event OneAdded(address adder);

    constructor () {
        count = 0;
    }

    function addOne() external {
        count += 1;
        emit OneAdded(msg.sender);
    }
}