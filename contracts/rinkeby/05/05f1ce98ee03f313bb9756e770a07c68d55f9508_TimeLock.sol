/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;

    constructor() payable {}

    function deposit() public payable {
        require(balances[msg.sender] == 0);
        require(msg.value > 0);
        balances[msg.sender] = msg.value;
        lockTime[msg.sender] = block.timestamp + 200 days;
    }

    function getRemainingLockTime() public view returns (uint256) {
        if (lockTime[msg.sender] < block.timestamp) {
            return 0;
        }
        unchecked {
            return lockTime[msg.sender] - block.timestamp;
        }
    }

    function withdraw() public {
        require(balances[msg.sender] > 0);
        require(block.timestamp >= lockTime[msg.sender]);
        uint256 DEPOSIT_COEF = 7316017851829954; // 1.01^200
        uint256 DEPOSIT_DENOMINATOR = 1000000000000000; // 10^15
        uint256 transferValue = balances[msg.sender] * DEPOSIT_COEF / DEPOSIT_DENOMINATOR;
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(transferValue);
    }
}