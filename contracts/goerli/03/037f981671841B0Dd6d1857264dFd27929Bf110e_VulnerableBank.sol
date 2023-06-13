// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

// Контракт банку, що вразливий до атаки з повторним входом
contract VulnerableBank {
    // Словник з адресами користувачів та їх балансами
    mapping(address => uint256) public balances;

    // Функція депозиту
    function deposit() external payable {
        // Оновлення балансу
        balances[msg.sender] += msg.value;
    }

    // Функція виводу коштів
    function withdraw() external {
        // Перевірка, чи є кошти на балансі
        require(balances[msg.sender] != 0);

        // Відправка коштів
        (bool success,) = msg.sender.call{value: balances[msg.sender]}("");
        require(success);

        // Оновлення балансу
        balances[msg.sender] = 0;
    }
}