// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

contract SimpleContract {
    uint a = 0;
    event Increment(uint a, address sender_address);
    event Decrement(uint a, address sender_address);

    function decrement() public {
        a = a - 1;
        emit Decrement(a, msg.sender);
    }

    function increment() external {
        a = a + 1;
        emit Increment(a, msg.sender);
    }
}