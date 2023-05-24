// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ChangeValue {
    // declare the int that will be increased/decreased
    uint256 public num = 0;

    // increment the value function
    function increment() public {
        num += 1;
    }

    // decrement the value function
    function decrement() public {
        num -= 1;
    }
}