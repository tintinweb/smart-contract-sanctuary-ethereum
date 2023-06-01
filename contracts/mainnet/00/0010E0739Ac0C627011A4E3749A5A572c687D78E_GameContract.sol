/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GameContract {
    // Define data structures to store user balances and accumulated fees
    mapping(address => uint256) private balances;
    uint256 private accumulatedFees;
    address private escrowWallet;
    address private botWallet;

    modifier onlyBot() {
        require(msg.sender == botWallet, "Only the bot can call this function");
        _;
    }

    // Set the escrow and bot wallet addresses on contract deployment
    constructor(address _escrowWallet, address _botWallet) {
        escrowWallet = _escrowWallet;
        botWallet = _botWallet;
    }

    // Allow users to deposit ETH into the contract
    function deposit() external payable {
        require(msg.sender == tx.origin, "Only the wallet owner can deposit");
        balances[msg.sender] += msg.value;
    }

    function updateBalances(address winner, address[] calldata losers, uint256[] calldata amounts) external onlyBot {
        // Check if the winner can cover the transaction fees
        uint256 gasCost = tx.gasprice * gasleft();
        require(balances[winner] >= gasCost, "Winner cannot cover transaction fees");

        // Reimburse the bot for the gas cost
        balances[winner] -= gasCost;
        payable(botWallet).transfer(gasCost);
        
        uint256 fee;
        uint256 netAmount;
        for (uint256 i = 0; i < losers.length; i++) {
            uint256 amount = amounts[i];
            uint256 gameFee = amount / 100;
            fee += gameFee;
            netAmount = amount - gameFee;
            balances[losers[i]] -= amount;
            balances[winner] += netAmount;
        }
        accumulatedFees += fee;

        if (accumulatedFees >= 0.1 ether && tx.gasprice <= 0.0025 ether) {
            payable(escrowWallet).transfer(accumulatedFees);
            accumulatedFees = 0;
        }
    }


    // Allow users to withdraw their ETH balance
    function withdraw(uint256 amount) external {
        require(msg.sender == tx.origin, "Only the wallet owner can withdraw");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Getter functions to check balances and accumulated fees
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }

    // Manually withdraw escrow balance
    function withdrawEscrowBalance() external onlyBot {
        uint256 escrowBalance = accumulatedFees;
        accumulatedFees = 0;
        payable(escrowWallet).transfer(escrowBalance);
    }

    // Check the escrow balance
    function getEscrowBalance() external view returns (uint256) {
        return accumulatedFees;
    }
}