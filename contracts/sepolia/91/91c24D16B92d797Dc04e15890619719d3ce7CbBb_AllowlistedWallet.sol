/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AllowlistedWallet {
    mapping(address => uint256) private balances;
    mapping(address => bool) private allowlist;

    // Event emitted when a deposit is made
    event Deposit(address indexed account, uint256 amount);

    // Event emitted when a withdrawal is made
    event Withdrawal(address indexed account, uint256 amount);

    // Event emitted when an address is added to the allowlist
    event AllowlistAdded(address indexed account);

    // Modifier to restrict access to addresses in the allowlist
    modifier onlyAllowlisted() {
        require(allowlist[msg.sender], "Only allowlisted addresses can call this function.");
        _;
    }

    // Internal function to handle the deposit logic
    function _deposit(address account, uint256 amount) internal {
        balances[account] += amount;
        emit Deposit(account, amount);
    }

    // Deposit ETH into the contract
    function depositFunds() external payable {
        _deposit(msg.sender, msg.value);
    }

    // Get the balance of an address
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    // Withdraw ETH from the contract
    function withdraw(uint256 amount) external onlyAllowlisted {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // Add an address to the allowlist
    function addAllowlist(address account) external onlyAllowlisted {
        allowlist[account] = true;
        emit AllowlistAdded(account);
    }

    // Check if an address is in the allowlist
    function isAllowlisted(address account) external view returns (bool) {
        return allowlist[account];
    }

    // Fallback function to receive ETH deposits
    receive() external payable {
        _deposit(msg.sender, msg.value);
    }
}