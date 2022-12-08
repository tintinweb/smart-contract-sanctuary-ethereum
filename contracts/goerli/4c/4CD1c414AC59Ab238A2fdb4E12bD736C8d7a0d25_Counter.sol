pragma solidity ^0.8.0;

contract Counter {
    uint256 public number;
    uint256 public lastIncremented;

    function increment() public {
        require(block.timestamp >= lastIncremented + 300, "5 minutes must have passed after last increment");
        number = number + 1;
        lastIncremented = block.timestamp;
    }
}