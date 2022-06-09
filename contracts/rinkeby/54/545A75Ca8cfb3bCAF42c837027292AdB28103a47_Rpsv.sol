// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// * Each choice follows the 'Commit-Reveal' pattern
// * The commit phase during which a value is chosen and specified -> hash the choice
// * The reveal phase during which the value is revealed and checked -> players will reveal the choice

contract Rpsv {
    enum State {CREATED, JOINED, COMMITED, REVEALED}
    struct Game {
        uint256 id;
        uint256 bet; // value of the bet per participant
        address payable[2] players;
        State state;
    }
    struct Choice {
        bytes32 hash;
        uint256 value;
    }
    mapping(uint256 => Game) public games;
    mapping(uint256 => mapping(address => Choice)) public choices; // game id -> player addr -> choice
    mapping(uint256 => uint256) public winningChoices;
    uint256 public gameId;

    constructor() {
        // 1. Rock
        // 2. Paper
        // 3. Scissors
        winningChoices[1] = 3;
        winningChoices[2] = 1;
        winningChoices[3] = 2;
    }

    function createGame(address payable participant) external payable {
        require(msg.value > 0, "need to send some ether");
        address payable[2] memory players;
        //address payable[] memory players = new address payable[](2);
        players[0] = payable(msg.sender);
        players[1] = participant;
        games[gameId] = Game(gameId, msg.value, players, State.CREATED);
        gameId++;
    }

    function joinGame(uint256 _gameId) external payable {
        Game storage game = games[_gameId];
        require(msg.sender == game.players[1], "sender must be second player");
        require(msg.value >= game.bet, "not enough ether send");
        require(game.state == State.CREATED, "must be in CREATED state");
        if (msg.value > game.bet) {
            payable(msg.sender).transfer(msg.value - game.bet);
        }
        game.state = State.JOINED;
    }

    function commitChoice(
        uint256 _gameId,
        uint256 choiceId,
        uint256 salt
    ) external isCommited(_gameId) {
        Game storage game = games[_gameId];
        require(game.state == State.JOINED, "game must be in JOINED state");
        // if no choice yet, it will default to 0
        require(choices[_gameId][msg.sender].hash == 0, "choice already made");
        require(
            choiceId == 1 || choiceId == 2 || choiceId == 3,
            "choice must be either 1, 2 or 3"
        );
        choices[_gameId][msg.sender] = Choice(
            keccak256(abi.encodePacked(choiceId, salt)),
            0 //choiceId
        );
        if (
            choices[_gameId][game.players[0]].hash != 0 &&
            choices[_gameId][game.players[1]].hash != 0
        ) {
            game.state = State.COMMITED;
        }
    }

    function revealChoice(
        uint256 _gameId,
        uint256 choiceId,
        uint256 salt
    ) external isCommited(_gameId) {
        Game storage game = games[_gameId];
        Choice storage choice1 = choices[_gameId][game.players[0]];
        Choice storage choice2 = choices[_gameId][game.players[1]];
        // We need to know which player launched the tx
        Choice storage choiceSender = choices[_gameId][msg.sender];
        require(game.state == State.COMMITED, "game must be in COMMITED state");
        require(
            choiceSender.hash == keccak256(abi.encodePacked(choiceId, salt)),
            "choiceId does not match commitment"
        );
        choiceSender.value = choiceId;
        if (choice1.value != 0 && choice2.value != 0) {
            if (choice1.value == choice2.value) {
                game.players[0].transfer(game.bet);
                game.players[1].transfer(game.bet);
                game.state = State.REVEALED;
                return;
            }
            address payable winner;
            winner = (winningChoices[choice1.value] == choice2.value)
                ? game.players[0]
                : game.players[1];
            winner.transfer(2 * game.bet);
            game.state = State.REVEALED;
        }
    }

    modifier isCommited(uint256 _gameId) {
        require(
            games[_gameId].players[0] == msg.sender ||
                games[_gameId].players[1] == msg.sender,
            "can only be called by 1 of the players"
        );
        _;
    }
}