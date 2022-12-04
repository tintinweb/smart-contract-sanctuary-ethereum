// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract FortuneWheel {
    uint capacity;
    uint counter;
    address[] pool;

    constructor(uint _num) {
        capacity = _num;
    }

    function play() external payable onlyOneChance {
        uint256 amount = 1e16;
        require(msg.value == amount, "Transfer exactly 0.01ETH to play");
        pool.push(msg.sender);
        counter++;

        if (counter == capacity) {
            (bool callSuccess, ) = msg.sender.call{value: address(this).balance}("");
            require(callSuccess, "Transfer failed");
            counter = 0;
            delete pool;
        }

    }

    modifier onlyOneChance {
        bool alreadyInThePool;
        for(uint i = 0; i < pool.length; i++) {
            if(pool[i] == msg.sender) {
                alreadyInThePool = true;
            }
        }
        require(!alreadyInThePool, "Your address is already in the pool.");
        _;
    }
}