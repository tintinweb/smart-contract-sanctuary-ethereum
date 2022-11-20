// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Challenge.sol";

contract ChallengeWin {
    Challenge challenge;

    constructor(address ChallengeToWin) {
        challenge = Challenge(ChallengeToWin);
    }

    function callExploitMe() public {
        challenge.exploit_me(msg.sender);
    }

    fallback() external {
        challenge.lock_me();
    }
}