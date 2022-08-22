/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint public totalSupply_ = 100000 * 10 ** 18;
    string public name = "Au Coin du Bloc";
    string public symbol = "ACB";
    uint public decimals = 18;

    // Événements
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    // Constructeur avec initialisation de la balance du contrat
    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    // Récupérer la quantité totale de jetons disponibles
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    // Récupérer la balance d'un utilisateur
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    // Transférer les jetons en tant que détenteur
    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) >= amount, 'balance too low');
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Transférer les jetons en tant que tiers (approbation préalable)
    function transferFrom(address from, address to, uint amount) public returns(bool) {
        require(balanceOf(from) >= amount, 'balance too low');
        require(allowed[from][msg.sender] >= amount, 'allowance too low');

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;

        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Approbation pour permettre à un tiers de transmettre des jetons
    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Récupérer la valeur accessible au délégataire
    function allowance(address owner, address delegate) public view returns(uint) {
        return allowed[owner][delegate];
    }
}