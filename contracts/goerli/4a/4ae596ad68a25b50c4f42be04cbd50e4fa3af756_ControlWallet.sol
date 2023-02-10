/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

pragma solidity ^0.7.0;
contract ControlWallet {

// Define the structure of a user's wallet
struct Wallet {
uint balance;
bool approved;
}

// Create a mapping of addresses to wallets
mapping(address => Wallet) public wallets;

// Function to deposit funds into a user's wallet
function deposit(address _to, uint _value) public payable {
// Check if the address exists in the mapping
require(wallets[_to].balance >= 0, "Wallet does not exist");
// Add the funds to the user's wallet
wallets[_to].balance += _value;
}

// Function to approve a user's wallet for access
function approve(address _from) public {
wallets[_from].approved = true;
}

// Function to withdraw funds from a user's wallet
function withdraw(address _from, uint _value) public {
// Check if the address exists in the mapping
require(wallets[_from].balance >= 0, "Wallet does not exist");
// Check if the user's wallet is approved for access
require(wallets[_from].approved, "Wallet not approved for access");
// Check if the user has enough funds in their wallet
require(wallets[_from].balance >= _value, "Insufficient funds");
// Transfer the funds from the user's wallet to the address calling the function
address payable to = address(uint160(_from));
to.transfer(_value);
// Deduct the funds from the user's wallet
wallets[_from].balance -= _value;
}

// Function to transfer funds from one wallet to another
function transferFrom(address _from, address _to, uint _value) public {
// Check if the sender's wallet exists
require(wallets[_from].balance >= 0, "Sender's wallet does not exist");
// Check if the recipient's wallet exists
require(wallets[_to].balance >= 0, "Recipient's wallet does not exist");
// Check if the sender's wallet is approved for access
require(wallets[_from].approved, "Sender's wallet not approved for access");
// Check if the sender has enough funds in their wallet
require(wallets[_from].balance >= _value, "Insufficient funds");
    }
}