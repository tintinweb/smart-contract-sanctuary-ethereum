// SPDX-License-Identifier: N1KURA
// Created by N1KURA
// GitHUB: https://github.com/N1KURA
// Twitter: https://twitter.com/0xN1KURA
// Telegram: https://t.me/N1KURA
// BTC: bc1qqa4p9jjkkhawed4mkv0xmncmhtrft0d6gp8tw9

pragma solidity ^0.8.0;

contract N1KURA_Tamagotchi {
    uint256 public energyLevel;
    uint256 public happinessLevel;
    bool public isAsleep;
    bool public isAlive;

    uint256 private lastInteractionTime;
    uint256 private constant interactionInterval = 1 minutes; // Интервал времени для автоматического расхода

    constructor() {
        energyLevel = 100;
        happinessLevel = 100;
        isAsleep = false;
        isAlive = true;
        lastInteractionTime = block.timestamp;
    }

    function feed(uint256 amount) public {
        require(isAlive, "The Tamagotchi is not alive.");
        energyLevel += amount;
        resetLastInteractionTime();
    }

    function play(uint256 amount) public {
        require(isAlive, "The Tamagotchi is not alive.");
        require(amount <= energyLevel, "Not enough energy to play.");

        energyLevel -= amount;
        happinessLevel += amount;
        resetLastInteractionTime();
    }

    function sleep() public {
        require(isAlive, "The Tamagotchi is not alive.");
        isAsleep = true;
        resetLastInteractionTime();
    }

    function wakeUp() public {
        require(isAlive, "The Tamagotchi is not alive.");
        require(isAsleep, "The Tamagotchi is not asleep.");
        isAsleep = false;
        happinessLevel -= 5; // Уровень счастья уменьшается на 5 при пробуждении
        resetLastInteractionTime();
    }

    function checkLifeStatus() public {
        if (energyLevel == 0 || happinessLevel == 0) {
            isAlive = false;
        }
    }

    function resetLastInteractionTime() private {
        lastInteractionTime = block.timestamp;
    }

    function autoDecay() public {
        require(isAlive, "The Tamagotchi is not alive.");
        uint256 currentTime = block.timestamp;

        // Проверяем, прошла ли достаточная минута с момента последнего взаимодействия
        if (currentTime >= lastInteractionTime + interactionInterval) {
            uint256 timeSinceLastInteraction = (currentTime - lastInteractionTime) / interactionInterval;
            energyLevel -= timeSinceLastInteraction;
            if (!isAsleep) {
                happinessLevel -= (timeSinceLastInteraction * 11) / 10; // Уровень счастья уменьшается на 1.1 единицы за каждый период времени, если не спит
            }

            checkLifeStatus();
            lastInteractionTime += timeSinceLastInteraction * interactionInterval; // Обновляем последнее время взаимодействия
        }
    }
}