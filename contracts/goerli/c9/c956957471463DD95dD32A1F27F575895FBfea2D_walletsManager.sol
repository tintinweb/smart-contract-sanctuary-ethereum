// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// wallet manager that has to be deployed once to store the addressess of the smart wallets deployed by every user
// current address: 0x3039542200BF803dd3a68Ae28Fb008492Db170c4


contract walletsManager {

struct _wallets{
address[] _addresses;}

// Maps EOA to its wallets 
    mapping (address => _wallets) internal EOAwallets;

function addWallet(address walletOwner, address newWallet) public{
    EOAwallets[walletOwner]._addresses.push(newWallet);
}

function checkWalletAddress(address walletOwner, uint8 index) public view returns(address){
return EOAwallets[walletOwner]._addresses[index];
}

function amountOfWallets(address walletOwner) public view returns(uint256) {
return EOAwallets[walletOwner]._addresses.length;
}
}