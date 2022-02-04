// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract AmbBridge {
    struct Withdraw {
        address fromAddress;
        address toAddress;
        uint amount;
    }

    Withdraw[] queue;

    event Test(bytes32 indexed withdraws_hash, Withdraw[] withdraws);

    constructor() {}


    function withdraw(address tokenAmb, address toAddr, uint amount) public {
        // else
        emit Test(keccak256(abi.encode(queue)), queue);
        delete queue;

        // if same timeframe
        queue.push(Withdraw(msg.sender, toAddr, amount));
    }
}