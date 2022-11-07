// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// Deposit Not Currently Available due to existing Deposit.
/// @param current_block The current block.
error DepositUnavailable(uint current_block);

/// Withdraw Not Currently Available due to TimeLock not being met.
/// @param current_block The Block Number This is being executed in.
/// @param available_at The Block Number This Withdraw can work on or after.
error WithdrawUnavailable(uint current_block, uint available_at);

contract TimeLock {
    mapping(address => uint) public locks;
    mapping(address => uint) public balances;
    uint256 public transactionValue;

    event Deposit(address from, uint current_block, uint until_block, uint value);
    event Withdraw(address to, uint current_block, uint value);

    function deposit(uint64 timelock) external payable {
        if (balances[msg.sender] > 0 && locks[msg.sender] > 0)
            revert DepositUnavailable({current_block: block.number});
        balances[msg.sender] += msg.value;
        locks[msg.sender] = (block.number + timelock);
        emit Deposit(msg.sender, block.number, locks[msg.sender], balances[msg.sender]);
    }

    function withdraw() external {
        if (block.number < locks[msg.sender])
            revert WithdrawUnavailable({current_block: block.number, available_at: locks[msg.sender]});
        transactionValue = balances[msg.sender];
        balances[msg.sender] = 0;
        locks[msg.sender] = 0;
        (bool sent,bytes memory data) = msg.sender.call{value: transactionValue}("");
        require(sent, "Failure During Withdraw");
        emit Withdraw(msg.sender, block.number, transactionValue);
    }
}