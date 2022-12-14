/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Game {
    uint256 private _gameCount;

    enum Options {
        ROCK,
        PAPER,
        SCISSORS
    }

    struct GameInfo {
        address playerA;
        Options playerASelection;
        address playerB;
        Options playerBSelection;
        address Winner;
        bool concluded;
    }

    event AnnounceWinner(uint256 gameNumber, address winner);
    event PlayerSelections(
        uint256 gameNumber,
        string player,
        address account,
        Options selection,
        string selection_string
    );

    mapping(uint256 => GameInfo) allGames;

    function startGame() internal returns (string memory) {
        require(
            allGames[_gameCount].playerA != address(0x0),
            "The first player has not selected their play choice yet."
        );
        require(
            allGames[_gameCount].playerB != address(0x0),
            "The second player has not selected their play choice yet."
        );

        allGames[_gameCount].concluded = true;
        string memory result = determineWinner(allGames[_gameCount]);

        emit AnnounceWinner(_gameCount, allGames[_gameCount].Winner);
        _gameCount += 1;
        return result;
    }

    function playWithComputer(Options selected) public returns (string memory) {
        require(
            allGames[_gameCount].playerA == address(0x0) &&
                allGames[_gameCount].playerB == address(0x0),
            "Please finish the existing game before starting a game with the computer."
        );

        uint256 rand = random(2);
        Options computerSelected = mapSelectionToEnum(rand);
        GameInfo memory gameWithComputer;
        gameWithComputer.playerA = msg.sender;
        gameWithComputer.playerASelection = selected;

        gameWithComputer.playerB = address(this);
        gameWithComputer.playerBSelection = computerSelected;

        allGames[_gameCount] = gameWithComputer;
        emit PlayerSelections(
            _gameCount,
            "PlayerA",
            msg.sender,
            selected,
            mapSelectionToString(selected)
        );
        emit PlayerSelections(
            _gameCount,
            "PlayerB: Computer",
            address(this),
            computerSelected,
            mapSelectionToString(selected)
        );

        string memory result = startGame();

        return
            string.concat(
                "PlayerA (You) selected: ",
                mapSelectionToString(selected),
                ". ",
                "PlayerB (Computer) selected: ",
                mapSelectionToString(computerSelected),
                ". ",
                result
            );
    }

    function playWithAPlayer(Options selected) public returns (string memory) {
        if (allGames[_gameCount].playerA == address(0x0)) {
            allGames[_gameCount].playerA = msg.sender;
            allGames[_gameCount].playerASelection = selected;
            emit PlayerSelections(
                _gameCount,
                "PlayerA",
                msg.sender,
                selected,
                mapSelectionToString(selected)
            );
            return
                string.concat(
                    "PlayerA selected: ",
                    mapSelectionToString(selected)
                );
        } else {
            require(
                allGames[_gameCount].playerA != msg.sender,
                "PlayerB cannot be the same player as playerA, please select option with a different account."
            );
            allGames[_gameCount].playerB = msg.sender;
            allGames[_gameCount].playerBSelection = selected;
            emit PlayerSelections(
                _gameCount,
                "PlayerB",
                msg.sender,
                selected,
                mapSelectionToString(selected)
            );
            string memory result = startGame();
            return
                string.concat(
                    "PlayerB selected: ",
                    mapSelectionToString(selected),
                    ". ",
                    result
                );
        }
    }

    function mapSelectionToString(Options selected)
        internal
        pure
        returns (string memory)
    {
        if (selected == Options.ROCK) {
            return "Rock";
        } else if (selected == Options.PAPER) {
            return "Paper";
        } else {
            return "Scissors";
        }
    }

    function mapSelectionToEnum(uint256 selected)
        private
        pure
        returns (Options)
    {
        if (selected == 0) {
            return Options.ROCK;
        } else if (selected == 1) {
            return Options.PAPER;
        } else {
            return Options.SCISSORS;
        }
    }

    function determineWinner(GameInfo memory game)
        internal
        returns (string memory result)
    {
        if (game.playerASelection == game.playerBSelection) {
            allGames[_gameCount].Winner = game.playerA;
            return
                string.concat(
                    "Both players selected: ",
                    mapSelectionToString(game.playerASelection),
                    ". It's a tie!"
                );
        } else if (game.playerASelection == Options.ROCK) {
            if (game.playerBSelection == Options.SCISSORS) {
                allGames[_gameCount].Winner = game.playerA;
                return "Rock smashes scissors! PlayerA win!";
            } else {
                allGames[_gameCount].Winner = game.playerB;
                return "Paper covers rock! PlayerB wins.";
            }
        } else if (game.playerASelection == Options.PAPER) {
            if (game.playerBSelection == Options.ROCK) {
                allGames[_gameCount].Winner = game.playerA;
                return "Paper covers rock! PlayerA win!";
            } else {
                allGames[_gameCount].Winner = game.playerB;
                return "Scissors cuts paper! PlayerB wins.";
            }
        } else if (game.playerASelection == Options.SCISSORS) {
            if (game.playerBSelection == Options.PAPER) {
                allGames[_gameCount].Winner = game.playerA;
                return "Scissors cuts paper! PlayerA wins!";
            } else {
                allGames[_gameCount].Winner = game.playerB;
                return "Rock smashes scissors! PlayerB wins.";
            }
        }
    }

    function random(uint256 num) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % num;
    }
}