pragma solidity 0.8.17;

contract Counter {
    uint256 public count;

    function increment() public {
        count += 1;
    }
}