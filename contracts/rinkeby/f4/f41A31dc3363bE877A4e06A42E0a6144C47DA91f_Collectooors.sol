// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum MoveDirection {
    Up,
    Down,
    Left,
    Right
}

struct Position {
    uint8 x;
    uint8 y;
}

interface IGame {
    function setRegistry(address _registry) external;
    function register() external;
    function move(MoveDirection direction) external;
    function collectTokens() external;
    function collectHealth() external;
    function update(address myNewContract) external;
    function currentPosition() external view returns(Position memory);
    function positionOf(address player) external view returns(Position memory);
}

contract Collectooors {

    IGame constant g = IGame(0x219B220123896B7F79E584497826d0b9EEb7Dd44);
    constructor() {
        g.register();
    }

    function up(uint8 x) external {
        for (uint8 i=0;i<x;i++) {
            g.move(MoveDirection(0));
        }
    }

    function down(uint8 x) external {
        for (uint8 i=0;i<x;i++) {
            g.move(MoveDirection(1));
        }
    }

    function left(uint8 x) external {

        for (uint8 i=0;i<x;i++) {
            g.move(MoveDirection(2));
        }
    }

    function right(uint8 x) external {

        for (uint8 i=0;i<x;i++) {
            g.move(MoveDirection(3));
        }
    }

    function collectHealth() external {
        g.collectHealth();
    }

    function collectTokens() external {
        g.collectTokens();
    }

}