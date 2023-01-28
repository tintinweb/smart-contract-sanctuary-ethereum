// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../storage/GameStorage.sol";

contract Game {
    using GameStorage for GameStorage.Player;

    event PlayerBalanceChange(address indexed player, uint256 balance);

    function join() public {
        GameStorage.Player storage player = GameStorage.getPlayer(tx.origin);
        require(player._address == address(0), "Player already joined");
        player._address = tx.origin;
        player.balance = 100;
        emit PlayerBalanceChange(tx.origin, player.balance);
    }

    function addBalance(uint256 count) public {
        GameStorage.Player storage player = GameStorage.getPlayer(tx.origin);
        player.balance += count;
        emit PlayerBalanceChange(tx.origin, player.balance);
    }

    function subBalance(uint256 count) public {
        GameStorage.Player storage player = GameStorage.getPlayer(tx.origin);
        player.balance -= count;
        emit PlayerBalanceChange(tx.origin, player.balance);
    }

    function getBalance(address _address) public view returns (uint256) {
        GameStorage.Player storage player = GameStorage.getPlayer(_address);
        return player.balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library GameStorage {
    bytes32 internal constant GAME_STORAGE_POSITION =
        keccak256("game.storage.position");
    bytes32 internal constant GAME_STORAGE_PLAYER_POSITION =
        keccak256("game.storage.player.position");
    struct Player {
        address _address;
        uint256 balance;
    }

    function getPlayer(address _playerAddress)
        internal
        pure
        returns (GameStorage.Player storage player)
    {
        bytes32 position = keccak256(
            abi.encodePacked(GAME_STORAGE_PLAYER_POSITION, _playerAddress)
        );
        assembly {
            player.slot := position
        }
    }
}