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
    enum Winner {
        NONE,
        TEAM_1,
        TEAM_2,
        DRAW
    }
    enum GameState {
        LISTED,
        OPEN_FOR_BID,
        WAITING_FOR_RESULT,
        CLOSED,
        ON_HOLD
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
        Winner winner;
        mapping(address => TeamNumber) playerTeamMapping;
        mapping(address => uint256) playerAmountMapping;
        address[] players;
    }
    event BetSuccessful(
        uint256 indexed activeGameId,
        address indexed from,
        uint256 amount,
        TeamNumber teamNumber,
        string teamName
    );
    event Withdraw(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender;
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

    function openBidding(uint256 _gameIndex) public onlyOwner {
        require(!anyGameActive, "There is one game active already.");
        games[_gameIndex].state = GameState.OPEN_FOR_BID;
        activeGameId = _gameIndex;
        anyGameActive = true;
    }

    function closeBidding() public onlyOwner {
        require(anyGameActive, "There is no game active.");
        games[activeGameId].state = GameState.WAITING_FOR_RESULT;
    }

    function closeGame(uint256 _gameIndex) public onlyOwner {
        games[_gameIndex].state = GameState.LISTED;
        activeGameId = 0;
        anyGameActive = false;
    }

    function bet(TeamNumber _teamNumber) public payable {
        require(anyGameActive, "There is no game active currently!");
        Game storage game = games[activeGameId];
        require(
            game.state == GameState.OPEN_FOR_BID,
            "Game is not open for bids."
        );
        require(
            game.playerAmountMapping[msg.sender] == 0,
            "You already placed a bet."
        ); //TODO allow to add more bet in same team

        string memory teamName;
        if (_teamNumber == TeamNumber.TEAM_1) {
            game.team1.totalBetAmount += msg.value;
            game.team1.bids.push(Bids(msg.sender, msg.value));
            game.playerTeamMapping[msg.sender] = TeamNumber.TEAM_1;
            teamName = game.team1.name;
        } else {
            game.team2.totalBetAmount += msg.value;
            game.team2.bids.push(Bids(msg.sender, msg.value));
            game.playerTeamMapping[msg.sender] = TeamNumber.TEAM_2;
            teamName = game.team2.name;
        }
        game.playerAmountMapping[msg.sender] += msg.value;
        betBalances[msg.sender] += msg.value;
        totalBetMoney += msg.value;
        game.players.push(msg.sender);
        emit BetSuccessful(
            activeGameId,
            msg.sender,
            msg.value,
            _teamNumber,
            teamName
        );
    }

    function declareResult(uint256 gameIndex, Winner winner) public onlyOwner {
        Game storage game = games[gameIndex];
        require(
            game.winner == Winner.NONE,
            "Result already declared for the game."
        );
        require(winner != Winner.NONE, "invalid team");

        if (winner == Winner.DRAW) {
            address[] memory players = game.players;
            for (uint256 i = 0; i < players.length; i++) {
                address player = players[i];
                uint256 amountToTransfer = game.playerAmountMapping[player];
                walletBalances[player] += amountToTransfer;
                betBalances[player] -= amountToTransfer;
                contractBalance -= amountToTransfer;
            }
            game.winner = Winner.DRAW;
        } else {
            Team memory winnerTeam;
            Team memory looserTeam;
            uint256 poolPrize;

            if (winner == Winner.TEAM_1) {
                winnerTeam = game.team1;
                looserTeam = game.team2;
                poolPrize = game.team2.totalBetAmount;
                game.winner = Winner.TEAM_1;
            } else {
                winnerTeam = game.team2;
                looserTeam = game.team1;
                poolPrize = game.team1.totalBetAmount;
                game.winner = Winner.TEAM_2;
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
        }

        game.state = GameState.CLOSED;
        anyGameActive = false;
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

    struct GameBets {
        address player;
        uint256 amount;
        TeamNumber teamNumber;
        string teamName;
    }

    function getGameBets(uint256 gameIndex)
        public
        view
        returns (GameBets[] memory)
    {
        Game storage game = games[gameIndex];
        address[] memory players = game.players;

        GameBets[] memory gameBets = new GameBets[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            uint256 amount = game.playerAmountMapping[player];
            TeamNumber team = game.playerTeamMapping[player];
            string memory teamName;
            if (team == TeamNumber.TEAM_1) {
                teamName = game.team1.name;
            } else {
                teamName = game.team2.name;
            }
            gameBets[i] = GameBets(player, amount, team, teamName);
        }
        return gameBets;
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

    function withdrawFromWallet() public {
        require(walletBalances[msg.sender] > 0, "You do not have any balance.");
        uint256 amountToTransfer = walletBalances[msg.sender];
        walletBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amountToTransfer);
        emit Withdraw(msg.sender, amountToTransfer);
    }

    function withdrawAdmin() public onlyOwner {
        require(contractBalance > 0, "You do not have any balance.");
        uint256 amountToTransfer = contractBalance;
        contractBalance = 0;
        payable(owner).transfer(amountToTransfer);
    }
}