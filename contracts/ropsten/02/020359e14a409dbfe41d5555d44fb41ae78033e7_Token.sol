/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 100 * 10 ** 18;
    string public name = "empe2";
    string public symbol = "Empe2";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    address admin;

    address charityWallet; //I put my wallets here but I deleted them for now
    address burnWallet;

    uint charityFee = 2;
    uint burnFee = 1;
    uint taxFee = 3;
    uint totalFee = 6;
    
    uint taxedCoins;

    constructor() {
        balances[msg.sender] = totalSupply;
        admin = msg.sender;
    }

    function balanceOf(address owner) public view returns(uint) {
        uint actualBalance = balances[owner] + ((balances[owner] * taxedCoins) / totalSupply);
        return actualBalance;
    }

/*
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
*/

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Balance is too low");

        balances[charityWallet] += (charityFee * value) / 100;
        balances[burnWallet] += (burnFee * value) / 100;

        taxedCoins += (taxFee * value) / 100;

        balances[to] += (value * (100 - totalFee)) / 100;
        if (value <= balances[msg.sender]) {
            balances[msg.sender] -= value;
        } else {
            uint leftoverCoins = value - balances[msg.sender];
            balances[msg.sender] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Balance is too low");
        require(allowance[from][msg.sender] >= value, "Allowance is too low");

        balances[charityWallet] += (charityFee * value) / 100;
        balances[burnWallet] += (burnFee * value) / 100;

        taxedCoins += (taxFee * value) / 100;

        balances[to] += (value * (100 - totalFee)) / 100;
        if (value <= balances[from]) {
            balances[from] -= value;
        } else {
            uint leftoverCoins = value - balances[from];
            balances[from] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getNumberOfTaxedCoins() public view returns(uint) {
        return taxedCoins;
    }

    function getTaxFee() public view returns(uint) {
        return taxFee;
    }

    function changeFees(uint charity, uint burn, uint tax) public {
        require(msg.sender == admin, "Only admin is allowed to change the fees");
        charityFee = charity;
        burnFee = burn;
        taxFee = tax;
        totalFee = charity + burn + tax;
    }

}