/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// Kartazion - Scientific Research & Quantum Engineering 
// Native Kartazion $KZN Cryptoassets with Solana -> to -> this Wrapped Kartazion $WKZN on Ethereum blockchain.
// Solana contract address of native Kartazion cryptoassets EjSwAfwi4F6uYtoi2WuCSYSWPVUPJCdemmShZ9tdy65P

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @notice This contract serves as an intermediary between the Solana blockchain and the Ethereum one in the ERC20 token format. 
 * @notice Wormhole's Portal Bridge protocol allows Kartazion tokens to be exchanged between Solana's SPL tokens and ERC20 tokens.
 *
 * @author Kartazion
 */
 
contract WrapKZN {
	string public name = "Wrapped Kartazion";
	string public symbol = "WKZN";
	uint8  public decimals = 18;
	string public description = "Kartazion - Scientific Research & Quantum Engineering";
	string public totalTokens = "The total number of tokens minted on the Solana blockchain is less than 21 million. Part of Solana's SPL tokens are removed to this wrapped ERC20 token. The tolal supply can never exceed 21 million tokens by adding the two blockchains.";
	address owner = 0x875F0cc11e97d8d6E074D87948F305F5a7660239;

	event Deposit(address indexed account, uint256 amount);
	event Withdraw(address indexed account, uint256 amount);

function deposit() public payable {
	require(owner == msg.sender,"Only the owner can execute this transaction.");
	emit Deposit(msg.sender, msg.value); }

function withdraw(uint256 wei_amount) external {
	require(owner == msg.sender,"Only the owner can execute this transaction.");
	(bool success,) = payable(msg.sender).call{value: wei_amount}("");
	require(success, "Transfer Fail");
	emit Withdraw(msg.sender, wei_amount); }
}