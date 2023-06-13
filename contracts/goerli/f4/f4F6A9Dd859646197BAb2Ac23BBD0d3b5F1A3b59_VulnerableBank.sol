// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Контракт банку, що вразливий до атаки з повторним входом
contract VulnerableBank {
    // Словник з адресами користувачів та їх балансами
    mapping(address => uint256) balances;

    // Функція депозиту
    function deposit() external payable {
        // Оновлення балансу
        balances[msg.sender] += msg.value;
    }

    // Функція виводу коштів
    function withdraw() external {
        // Відправка коштів
        (bool success,) = msg.sender.call{value: balances[msg.sender]}("");
        require(success);

        // Оновлення балансу
        balances[msg.sender] = 0;
    }
}