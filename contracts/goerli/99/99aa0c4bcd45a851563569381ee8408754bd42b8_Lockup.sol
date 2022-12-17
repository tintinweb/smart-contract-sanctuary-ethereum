/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

pragma solidity ^0.6.0;

contract Lockup {
    // The address of the owner of the contract
    address private owner;

    // The amount of funds deposited in the contract
    uint private balance;

    // The timestamp of the last deposit or withdrawal
    uint private lastActionTime;

    // The lock-up period in seconds
    uint private lockupPeriod;

    constructor(uint _lockupPeriod) public {
        owner = msg.sender;
        lockupPeriod = _lockupPeriod;
    }

    // Deposit funds into the contract
    function deposit() public payable {
        require(msg.value > 0, "Cannot deposit 0 or negative value");
        balance += msg.value;
        lastActionTime = now;
    }

    // Withdraw funds from the contract
    function withdraw() public {
        require(now >= lastActionTime + lockupPeriod, "Cannot withdraw before lock-up period has ended");
        require(balance > 0, "Cannot withdraw more than the current balance");
        
        balance = 0;
        lastActionTime = now;
    }
}