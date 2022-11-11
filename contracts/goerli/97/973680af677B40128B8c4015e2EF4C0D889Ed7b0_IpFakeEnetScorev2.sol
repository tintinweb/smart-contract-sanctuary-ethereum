// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
 * @title A consumer contract for Enetscores.
 * @author Perrin GRANDNE from Irruption Lab.
 * @notice Interact with the daily events API.
 * @dev Uses @chainlink/contracts 0.4.2.
 */
contract IpFakeEnetScorev2 {
    // @notice structure for the creation of a game to predict
    struct GameCreate {
        uint32 gameId;
        uint40 startTime;
        string homeTeam;
        string awayTeam;
    }

    // @notice structure for the Oracle resolution of predicted game
    struct GameResolve {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    struct Scores {
        uint8 homeScore;
        uint8 awayScore;
    }

    // @notice association between request id and data
    mapping(string => GameCreate[]) public requestIdGames;

    mapping(uint32 => bool) public gamePlayed;

    // @notice use struct Score for a game id
    mapping(uint32 => Scores) private scoresPerGameId;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    function getGamePlayed(uint32 _gameId) external view returns (bool) {
        return gamePlayed[_gameId];
    }

    function getRequestIdGames(string memory _requestId, uint256 _index)
        external
        view
        returns (
            uint32,
            uint40,
            string memory,
            string memory
        )
    {
        return (
            requestIdGames[_requestId][_index].gameId,
            requestIdGames[_requestId][_index].startTime,
            requestIdGames[_requestId][_index].homeTeam,
            requestIdGames[_requestId][_index].awayTeam
        );
    }

    function getScoresPerGameId(uint32 _gameId)
        external
        view
        returns (uint8, uint8)
    {
        return (
            scoresPerGameId[_gameId].homeScore,
            scoresPerGameId[_gameId].awayScore
        );
    }

    function getNumberOfGamesPerRequest(string memory _requestId)
        external
        view
        returns (uint)
    {
        return requestIdGames[_requestId].length;
    }

    function getGameCreate(string memory _requestId, uint256 _idx)
        external
        view
        returns (GameCreate memory)
    {
        return requestIdGames[_requestId][_idx];
    }

    /* ========== INTERPOOL WRITE FUNCTIONS ========== */

    function fakeGameCreate(
        string memory _requestId,
        GameCreate[] memory _fakeGameCreate
    ) external {
        for (uint256 i = 0; i < _fakeGameCreate.length; i++) {
            requestIdGames[_requestId].push(
                GameCreate({
                    gameId: _fakeGameCreate[i].gameId,
                    startTime: _fakeGameCreate[i].startTime,
                    homeTeam: _fakeGameCreate[i].homeTeam,
                    awayTeam: _fakeGameCreate[i].awayTeam
                })
            );
        }
    }

    function getGameResolve(GameResolve[] memory _fakeGameResolve) external {
        for (uint256 i = 0; i < _fakeGameResolve.length; i++) {
            scoresPerGameId[_fakeGameResolve[i].gameId] = Scores({
                homeScore: _fakeGameResolve[i].homeScore,
                awayScore: _fakeGameResolve[i].awayScore
            });
            gamePlayed[_fakeGameResolve[i].gameId] = true;
        }
    }
}