// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Betting {
    address public owner;
    uint256 public activeGameId;
    bool public anyGameActive;
    uint256 public gameCounter;
    uint256 public totalBetMoney;
    Game[] public games;
    mapping(address => uint256) public betBalances;
    mapping(address => uint256) public walletBalances;
    uint256 private contractBalance;

    enum TeamNumber {
        NONE,
        TEAM_1,
        TEAM_2
    }

    enum GameState {
        LISTED,
        OPEN,
        CLOSED
    }

    struct Bids {
        address player;
        uint256 amount;
    }

    struct Team {
        string name;
        uint256 totalBetAmount;
        Bids[] bids;
    }

    struct Game {
        uint256 id;
        string name;
        GameState state;
        Team team1;
        Team team2;
        TeamNumber winner;
        mapping(address => TeamNumber) playerTeamMapping;
        mapping(address => uint256) playerAmountMapping;
    }

    constructor() {
        owner = msg.sender;
        // Game storage game = games.push();
        // game.id = gameCounter;
        // game.name = "Game #1";
        // game.state = GameState.OPEN;
        // game.team1.name = "T1";
        // game.team2.name = "T2";
        // gameCounter = gameCounter + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addGame(
        string memory _name,
        string memory _team1,
        string memory _team2
    ) public onlyOwner {
        Game storage game = games.push();
        game.id = gameCounter;
        game.name = _name;
        game.state = GameState.LISTED;
        game.team1.name = _team1;
        game.team2.name = _team2;
        gameCounter = gameCounter + 1;
    }

    function openGame(uint256 _gameIndex) public onlyOwner {
        require(!anyGameActive, "There is one game active already.");
        games[_gameIndex].state = GameState.OPEN;
        activeGameId = _gameIndex;
        anyGameActive = true;
    }

    function closeGame(uint256 _gameIndex) public onlyOwner {
        games[_gameIndex].state = GameState.LISTED;
        activeGameId = 0;
        anyGameActive = false;
    }

    function bet(string memory teamName) public payable {
        require(anyGameActive, "There is no game active currently!");
        Game storage game = games[activeGameId];
        require(
            game.playerAmountMapping[msg.sender] == 0,
            "You already placed a bet."
        ); //TODO allow to add more bet in same team

        if (
            keccak256(abi.encodePacked(teamName)) ==
            keccak256(abi.encodePacked(game.team1.name))
        ) {
            game.team1.totalBetAmount += msg.value;
            game.team1.bids.push(Bids(msg.sender, msg.value));
            game.playerTeamMapping[msg.sender] = TeamNumber.TEAM_1;
        } else {
            game.team2.totalBetAmount += msg.value;
            game.team2.bids.push(Bids(msg.sender, msg.value));
            game.playerTeamMapping[msg.sender] = TeamNumber.TEAM_2;
        }
        game.playerAmountMapping[msg.sender] += msg.value;
        betBalances[msg.sender] += msg.value;
        totalBetMoney += msg.value;
    }

    function declareResult(uint256 gameIndex, TeamNumber teamNumber)
        public
        payable
        onlyOwner
    {
        Game storage game = games[gameIndex];
        require(
            game.winner == TeamNumber.NONE,
            "Result already declared for the game."
        );
        require(teamNumber != TeamNumber.NONE, "invalid team");
        Team memory winnerTeam;
        Team memory looserTeam;
        uint256 poolPrize;
        if (teamNumber == TeamNumber.TEAM_1) {
            winnerTeam = game.team1;
            looserTeam = game.team2;
            poolPrize = game.team2.totalBetAmount;
        } else {
            winnerTeam = game.team2;
            looserTeam = game.team1;
            poolPrize = game.team1.totalBetAmount;
        }

        uint256 rewards;
        if (poolPrize > 0) {
            uint256 fees = poolPrize / 10;
            rewards = poolPrize - fees;
            contractBalance += fees;
        }

        Bids[] memory bids = winnerTeam.bids;
        uint256 arrayLength = bids.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            Bids memory bid = bids[i];
            // bid.player
            uint256 playerReward = (rewards * bid.amount) /
                winnerTeam.totalBetAmount;
            walletBalances[bid.player] += playerReward + bid.amount;
            betBalances[bid.player] -= bid.amount;
        }

        Bids[] memory looser_bids = looserTeam.bids;
        uint256 looserArrayLength = looser_bids.length;
        for (uint256 i = 0; i < looserArrayLength; i++) {
            Bids memory bid = looser_bids[i];
            betBalances[bid.player] -= bid.amount;
        }
        game.state = GameState.CLOSED;
    }

    function getPlayerBetInfo(uint256 gameIndex)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        Game storage game = games[gameIndex];
        string memory team;
        TeamNumber teamNumber = game.playerTeamMapping[msg.sender];
        uint256 amountBetted = game.playerAmountMapping[msg.sender];
        if (teamNumber == TeamNumber.TEAM_1) team = game.team1.name;
        else if (teamNumber == TeamNumber.TEAM_2) team = game.team2.name;
        return (
            team,
            amountBetted,
            game.team1.totalBetAmount,
            game.team2.totalBetAmount
        );
    }

    function getWalletBalance(address _address) public view returns (uint256) {
        return walletBalances[_address];
    }

    function getBetBalance(address _address) public view returns (uint256) {
        return betBalances[_address];
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return contractBalance;
    }
}