/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDC {
    string public name = "Faux USDC"; // Le nom du token est "Faux USDC"
    string public symbol = "fUSDC"; // Le symbole du token est "fUSDC"
    uint256 public totalSupply; // Le montant total de tokens en circulation

    mapping(address => uint256) public balances; // Une carte associant les adresses des détenteurs de tokens à leurs soldes

    event Transfer(address indexed from, address indexed to, uint256 amount); // Un événement émis lors d'un transfert de tokens

    constructor() {
        totalSupply = 1000; // Définir le montant total initial des tokens
        balances[msg.sender] = totalSupply; // Le créateur du contrat reçoit l'intégralité des tokens créés
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Solde insuffisant"); // Vérifie que le solde du détenteur est suffisant pour effectuer le transfert

        balances[msg.sender] -= amount; // Déduit le montant transféré du solde du détenteur actuel
        balances[to] += amount; // Ajoute le montant transféré au solde du destinataire

        emit Transfer(msg.sender, to, amount); // Émet l'événement de transfert
    }

    function mint(uint256 amount) external {
        require(msg.sender == 0xF90aCf91BdAB539aAC3093E5C5b207b562354401, "Autorisation refusee"); // Vérifie que l'appelant est autorisé à créer de nouveaux tokens

        balances[msg.sender] += amount; // Ajoute le montant créé au solde de l'appelant
        totalSupply += amount; // Augmente le montant total de tokens en circulation

        emit Transfer(address(0), msg.sender, amount); // Émet l'événement de création de tokens
    }
}