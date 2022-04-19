//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

enum MoveDirection {
    Up,
    Down,
    Left,
    Right
}

interface Game {
    function setRegistry(address _registry) external;
    function register() external;
    function move(MoveDirection direction) external;
    function collectTokens() external;
    function collectHealth() external;
    function update(address myNewContract) external;
}

contract YourContract  {
    Game public gameContract;

    constructor() {
        gameContract = Game(0x3f27D7790cA7B7193c6CdE7bE223E4dc61751601);
        //transferOwnership();
    }

    function setRegistry(address _registry) public {
        gameContract = Game(_registry);
    }

    function register() public {
        gameContract.register();
    }

    function move(MoveDirection direction) public {
        gameContract.move(direction);
    }

    function collectTokens() public {
        gameContract.collectTokens();
    }

    function collectHealth() public {
        gameContract.collectHealth();
    }

    function update(address myNewContract) public {
        gameContract.update(myNewContract);
    }
}