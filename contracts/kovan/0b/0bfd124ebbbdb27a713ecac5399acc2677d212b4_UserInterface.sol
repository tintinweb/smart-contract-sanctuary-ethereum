/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeCheckLibrary{
    function WalletCollectionContains(address[] memory wallets, address _addr) public view returns (bool isVerified){
       for (uint i=0; i<wallets.length; i++) {
           if(wallets[i] == _addr){
               return true;
           }
       }
    }
}

contract UserInterface{
    using SafeCheckLibrary for address[];

    address[] public wallets;
    mapping(address => uint256) public walletBalance;

    constructor() payable {}

    function depositEth(address _wallet) public payable{
        require(wallets.WalletCollectionContains(_wallet),"Invalid wallet");
        walletBalance[_wallet] += msg.value;
    }

    function addWallet(address _addr) public{
        require(!wallets.WalletCollectionContains(_addr),"Wallet already included");
        wallets.push(_addr);
    }

    //...
}