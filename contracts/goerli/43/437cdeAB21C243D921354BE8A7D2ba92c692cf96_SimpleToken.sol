/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

/*

    This smart contract alloctes a specific number of tokens that cannot be changed. 
    These tokens can be distributed among some owners that can  be added with transactions by the admin (the creator of the smart contract).
    The owners can exchange tokens among them.
    The admin cannot update the balances of the owners once he created it. The only way that the owners can increase or decrease their balance is 
    by doing transfers among them.
    The creation of new owners can be done only by the admin.
    The admin is the creator of the smart contract and it cannot be changed.
*/

pragma solidity >=0.7.0 <0.9.0;

contract SimpleToken {

    address admin;
    mapping(address => bool) owners;
    mapping(address => uint256) balances;

    uint256 totalTokens;

    constructor(uint256 total) {
        totalTokens = total;
        admin = msg.sender;
    }

    modifier isAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier isOwner() {
        require(owners[msg.sender] == true);
        _;
    }

    function availability() public view returns (uint256) {
        return totalTokens;
    }

    function balance(address owner) public view returns (uint) {
        return balances[owner];
    }

    function addOwner(address newOwner, uint256 tokens) isAdmin public {

        // Check if the owner doesn't already exist
        require(owners[newOwner] != true);

        // Cannot add a new owner that has the address of the admin
        require(newOwner != admin);

        //Check the availability of the tokens
        require(totalTokens - tokens >= 0);

        owners[newOwner] = true;
        balances[newOwner] = tokens;
        totalTokens -= tokens;
    }

    function transfer(address fromAddress, address toAddress, uint256 tokens) isOwner public {

        // Check if the sender of the transfer is the one that is creatring the transaction
        require(msg.sender == fromAddress);

        // Check if the fromAddress is equal to the toAddress
        require(fromAddress != toAddress);

        // Check if fromAddress and toAddress are registered owners
        require(owners[fromAddress] == true);
        require(owners[toAddress] == true);

        // Check if the sender has enough balance
        require(balances[fromAddress] - tokens >= 0);

        balances[fromAddress] -= tokens;
        balances[toAddress] += tokens;
    }
}