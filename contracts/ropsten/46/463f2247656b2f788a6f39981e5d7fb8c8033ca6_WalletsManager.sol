/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract WalletsManager {

  struct Wallet {
    address owner;
    bool isWallet;
    uint balance;
  }

  mapping(address => Wallet) public wallets;

  modifier userOwnWallet(){
    require(wallets[msg.sender].isWallet, "You need to create a wallet");
    require(wallets[msg.sender].owner == msg.sender, "You don't own this wallet");
    _;
  }

  function createWallet() external {
    wallets[msg.sender].owner = msg.sender;
    wallets[msg.sender].isWallet = true;
    wallets[msg.sender].balance = 0;
  }

  function getWalletBalance() external view userOwnWallet returns (uint) {
    return wallets[msg.sender].balance;
  }



  function hasWallet() external view returns (bool) {
    return wallets[msg.sender].isWallet;
  }

  receive() external payable userOwnWallet {
    wallets[msg.sender].balance += msg.value;
  }

  function withdrawMoney(uint amount) external  userOwnWallet {
    require(amount <= wallets[msg.sender].balance, "Not enough funds on you wallet");
    wallets[msg.sender].balance -= amount;
    payable(wallets[msg.sender].owner).transfer(amount);
  }

  function removeWallet() external userOwnWallet {
    wallets[msg.sender].isWallet = false;
    uint walletBalance = wallets[msg.sender].balance;
    wallets[msg.sender].balance = 0;
    payable(wallets[msg.sender].owner).transfer(walletBalance);
  }
}