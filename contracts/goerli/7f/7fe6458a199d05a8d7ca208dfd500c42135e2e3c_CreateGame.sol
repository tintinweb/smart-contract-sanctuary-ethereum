/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract CreateGame {
    struct Game {
        int256 id;
        string home;
        string away;
        string date;
    }

    struct GameResult {
        int256 id;
        int homeScore;
        int awayScore;
    }

    Game[] games;

    mapping(int => GameResult) public gameScore;

    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function getGame() public view returns(Game[] memory)  {
        return  games;
    }

    function setGame(Game[] memory _games) public {
        require(msg.sender == owner, "You can't");
        delete games;
        for (uint256 i = 0; i < _games.length; i++) {
            games.push(_games[i]);
        }
    }

    function getGameScore(int _gameId) public view returns(GameResult memory) {
        return gameScore[_gameId];
    }

    function updateGameScore(int _id, int _homeScore, int _awayScore) public {
        require(msg.sender == owner, "You can't");
        gameScore[_id].homeScore = _homeScore;
        gameScore[_id].awayScore = _awayScore;
    }
}