//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Counter {

    uint256 public counter;

    event Increment(address _address);

    function increment() public {
        counter++;
        emit Increment(msg.sender);
    }


}