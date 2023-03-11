// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RockPaperScissors {
    event GameCreated(address creator, bytes32 hashGame);
    event Commited(address player, bytes32 hashGame);
    event Revealed(address player, bytes32 hashGame);

    enum Result {None, Rock, Paper, Scissors}

    struct Game {
        address[2] players;
        mapping(address => bytes32) commits;
        mapping(address => Result) results;
    }

    struct GameView {
        address[2] players;
        bool[2] commits;
        Result[2] results;
        address winner;
    }

    mapping(bytes32 => Game) games;

    bytes32[] hashGames;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function createGame() external {
        bytes32 hashGame = bytes32(uint256(block.timestamp) + uint256(uint160(msg.sender)));

        require(games[hashGame].players[0] == address(0), 'game already has been created');

        games[hashGame].players[0] = msg.sender;
        emit GameCreated(msg.sender, hashGame);
    }

    function commitResult(bytes32 _hashResult, bytes32 _hashGame) external {
        require(games[_hashGame].players[0] != address(0), 'game till not has been created');
        require(
            games[_hashGame].players[0] == msg.sender ||
            (games[_hashGame].players[0] != msg.sender && games[_hashGame].players[1] == address(0)),
            'game already has players'
        );
        require(games[_hashGame].commits[msg.sender] == bytes32(0), 'result has been saved');

        if (games[_hashGame].players[0] != msg.sender) {
            games[_hashGame].players[1] = msg.sender;
        }

        games[_hashGame].commits[msg.sender] = _hashResult;
        emit Commited(msg.sender, _hashGame);
    }

    function revealResult(Result _result, bytes32 _secret, bytes32 _hashGame) external {
        require(_result != Result.None, 'incorrect result');
        require(
            games[_hashGame].commits[games[_hashGame].players[0]] != bytes32(0) &&
            games[_hashGame].commits[games[_hashGame].players[1]] != bytes32(0),
        'waiting commits from players');

        bytes32 commit = keccak256(abi.encodePacked(_hashGame, _result, _secret, msg.sender));
        require(games[_hashGame].commits[msg.sender] == commit, 'error result');

        games[_hashGame].results[msg.sender] = _result;
        emit Revealed(msg.sender, _hashGame);
    }

    function getGame(bytes32 _hashGame) external view returns(GameView memory) {
        address[2] memory _players = [
            games[_hashGame].players[0], 
            games[_hashGame].players[1]
        ];

        bool[2] memory _commits = [
            games[_hashGame].commits[_players[0]] != 0x00,
            games[_hashGame].commits[_players[1]] != 0x00
        ];

        Result[2] memory _results = [
            games[_hashGame].results[_players[0]],
            games[_hashGame].results[_players[1]]
        ];

        address _winner = address(0);
        if (_results[0] != Result.None && _results[1] != Result.None && _results[0] != _results[1]) {
            if (
                (_results[0] == Result.Rock && _results[1] == Result.Scissors) || 
                (_results[0] == Result.Scissors && _results[1] == Result.Paper) || 
                (_results[0] == Result.Paper && _results[1] == Result.Rock)
            ) {
                _winner = _players[0];
            } else {
                _winner = _players[1];
            }
        }

        GameView memory _gameView = GameView(
            _players,
            _commits,
            _results,
            _winner
        );

        return _gameView;
    }

    function withdraw() external {
        require(msg.sender == owner, 'access is denied');
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}