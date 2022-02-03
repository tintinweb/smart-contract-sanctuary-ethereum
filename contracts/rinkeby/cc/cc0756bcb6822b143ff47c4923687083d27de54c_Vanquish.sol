/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

interface IVanquish {
    error AlreadySpawnError();
    error AlreadyClaimedError();
    error NotSpawnLandError();
    error CooldownNotFinishedError();
    error InvalidClaimProof();
    error WrongDistanceError();
    error NotEnoughResources();
    error WrongOwnerError();
    error NotEnoughUnitsError();
    error PlayerVanquishedError();

    event Spawn(
        address indexed player,
        int256 x,
        int256 y
    );

    event Claim(
        address indexed player,
        int256 x,
        int256 y        
    );

    event Buy(
        address indexed player,
        uint256 quantity
    );

    event Move(
        address indexed player,
        int256 fromX,        
        int256 fromY,        
        int256 toX,        
        int256 toY,
        uint256 quantity
    );

    event Attack(
        address indexed attacker,
        address indexed defenser,
        bool hasWon,
        bool hasVanquished,
        int256 fromX,        
        int256 fromY,        
        int256 toX,        
        int256 toY,
        uint256 quantity        
    );
}

contract Vanquish is IVanquish {
    struct Player {
        bool hasSpawned;
        int256 spawnX;
        int256 spawnY;
        uint256 spawnedAt;
        uint256 lastMoveAt;
        uint256 availableResources;
        bool isVanquished;
    }

    mapping(address => Player) public statsOf;

    struct Land {
        address owner;
        uint256 units;
    }

    mapping(int256 => mapping(int256 => Land)) public map;

    uint256 constant public COOLDOWN = 30;

    modifier canPlay() {
        if (statsOf[msg.sender].lastMoveAt + COOLDOWN < block.timestamp) revert CooldownNotFinishedError();
        if (statsOf[msg.sender].isVanquished) revert PlayerVanquishedError();
        _;
        statsOf[msg.sender].lastMoveAt = block.timestamp;
    }

    function spawn(int256 x, int256 y) external {
        if (statsOf[msg.sender].hasSpawned) revert AlreadySpawnError();
        if (map[x][y].owner != address(0)) revert AlreadyClaimedError();
        if (_getLand(x, y) != 0) revert NotSpawnLandError();

        map[x][y].owner = msg.sender;
        statsOf[msg.sender].hasSpawned = true;
        statsOf[msg.sender].spawnedAt = block.timestamp;
        statsOf[msg.sender].lastMoveAt = block.timestamp;

        emit Spawn(msg.sender, x, y);
    }

    function claim(
        int256 x,
        int256 y,
        int256 proofX,
        int256 proofY
    ) external canPlay() {
        if (map[x][y].owner != address(0)) revert AlreadyClaimedError();
        if (map[proofX][proofY].owner != msg.sender) revert InvalidClaimProof();
        if (_getDistance(x, y, proofY, proofY) > 1) revert WrongDistanceError();

        statsOf[msg.sender].availableResources += _getLand(x, y);
        map[x][y].owner = msg.sender;

        emit Claim(msg.sender, x, y);
    }

    function buy(
        uint256 quantity
    ) external canPlay() {
        if (statsOf[msg.sender].availableResources < quantity) revert NotEnoughResources();

        statsOf[msg.sender].availableResources -= quantity;
        map[statsOf[msg.sender].spawnX][statsOf[msg.sender].spawnY].units += quantity;

        emit Buy(msg.sender, quantity);
    }

    function move(
        int256 fromX,
        int256 fromY,
        int256 toX,
        int256 toY,
        uint256 quantity
    ) external canPlay() {
        if (map[fromX][fromY].owner != msg.sender) revert WrongOwnerError();
        if (map[toX][toY].owner != msg.sender) revert WrongOwnerError();
        if (_getDistance(fromX, fromY, toX, toY) > 1) revert WrongDistanceError();

        map[fromX][fromY].units -= quantity;
        map[toX][toY].units += quantity;

        emit Move(msg.sender, fromX, fromX, toX, toY, quantity);
    }

    function attack(
        int256 fromX,
        int256 fromY,
        int256 toX,
        int256 toY,
        uint256 quantity
    ) external canPlay() {
        if (map[fromX][fromY].owner != msg.sender) revert WrongOwnerError();
        if (quantity > map[fromX][fromY].units) revert NotEnoughUnitsError();
        if (_getDistance(fromX, fromY, toX, toY) > 1) revert WrongDistanceError();
        if (
            map[toX][toY].owner == msg.sender
            || map[toX][toY].owner == address(0)
        ) revert WrongOwnerError();

        address defenser = map[toX][toY].owner;
        bool hasWon;
        bool hasVanquished;

        if (quantity >= map[toX][toY].units) {
            map[toX][toY].units = quantity - map[toX][toY].units;
            map[toX][toY].owner = msg.sender;
            hasWon = true;

            if (
                statsOf[msg.sender].spawnX == toX
                && statsOf[msg.sender].spawnY == toY
            ) {
                statsOf[msg.sender].isVanquished = true;
                hasVanquished = true;
            }
        } else {
            map[toX][toY].units -= quantity;
        }

        map[fromX][fromY].units -= quantity;

        emit Attack(
            msg.sender,
            defenser,
            hasWon,
            hasVanquished,
            fromX,
            fromY,
            toX,
            toY,
            quantity
        );
    }

    function _getDistance(
        int256 x,
        int256 y,
        int256 proofX,
        int256 proofY
    ) private pure returns (int256) {
        int256 d = _sqrt(
            (x - proofX) * (x - proofX)
            + (y - proofY) * (y - proofY)
        );

        return d;
    }

    function _getLand(int256 x, int256 y) private pure returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(x, y))) % 99;

        if (random == 99) return 4;
        if (random >= 94) return 3;
        if (random >= 80) return 2;
        if (random >= 50) return 2;
        
        return 0;
    }

    /// @dev Calculates the square root of {y}
    /// @return z Square root of {y}
    function _sqrt(int256 y) private pure returns (int256 z) {
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;

            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }    
}