/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// Mai && Luke: The most powerful couple
contract RDVCoin {
    
    address public minter;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    
    event Sent(address from, address to, uint256 amount);

    constructor() {
        minter = msg.sender;
        totalBalance = 0;
    }

    function getTotalBalance() view public returns (uint) {
        return totalBalance;
    }

    function getBalanceFor(address account) view public returns(uint256) {
        return balances[account];
    }

    // Sends an amount of newly created coins to an address Can only be called by the contract creator
    function mint(address receiver, uint256 amount) public {
        require(msg.sender == minter, 'Only the owner can mint coins');
        totalBalance += amount;
        balances[receiver] += amount;
    }

    // Errors allow you to provide information about why an operation failed. They are returned to the caller of the function.
    error InsufficientBalance(uint256 requested, uint256 available);

    // Sends an amount of existing coins from any caller to an address
    function send(address receiver, uint256 amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}