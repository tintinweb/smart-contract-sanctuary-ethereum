// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract TestLand {
    uint256 public constant X = 9;
    uint256 public constant Y = 9;

    struct LandTile {
        address owner;
        uint8 resourceA;
        uint8 resourceB;
        uint8 resourceC;
    }

    LandTile[X][Y] public gameState;
    mapping(address => uint256) staminaLevels;

    constructor() {
        for (uint256 i = 0; i < X; i++) {
            for (uint256 j = 0; j < Y; j++) {
                LandTile storage tile = gameState[i][j];
                tile.resourceA =
                    uint8(uint256(keccak256(abi.encodePacked(i + 33)))) %
                    10;
                tile.resourceB =
                    uint8(uint256(keccak256(abi.encodePacked(j + 2)))) %
                    10;
                tile.resourceB =
                    uint8(uint256(keccak256(abi.encodePacked(j + i)))) %
                    10;
            }
        }
    }

    function getGameState() external view returns (LandTile[X][Y] memory) {
        return gameState;
    }

    function changeOwner(
        uint256 newX,
        uint256 newY,
        address owner
    ) external {
        LandTile storage newLandTile = gameState[newX][newY];
        newLandTile.owner = owner;
    }

    function changeResource(
        uint256 newX,
        uint256 newY,
        uint256 resource,
        uint8 newResource
    ) external {
        LandTile storage newLandTile = gameState[newX][newY];
        if (resource == 0) {
            newLandTile.resourceA = newResource;
        } else if (resource == 1) {
            newLandTile.resourceB = newResource;
        } else if (resource == 1) {
            newLandTile.resourceC = newResource;
        }
    }
}