// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Betting {
    address public owner;
    uint256 public gameCounter;
    uint256 public totalBetMoney;
    Game[] public games;
    mapping(address => uint256) public betBalances;
    mapping(address => uint256) public walletBalances;
    uint256 private contractBalance;
    uint256[] activeGameIds;

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
        UPCOMING,
        STARTED,
        ENDED,
        ON_HOLD,
        CANCELLED
    }
    enum BetState {
        NONE,
        BIDDING_STARTED,
        BIDDING_CLOSED,
        WAITING_FOR_RESULT,
        RESULT_DECLARED,
        WAITING_FOR_REFUND,
        REFUNDED
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
    struct Time {
        uint256 betting_start_time;
        uint256 match_start_time;
    }
    struct Game {
        uint256 id;
        string name;
        GameState gameState;
        BetState betState;
        Time time;
        Team team1;
        Team team2;
        Winner winner;
        mapping(address => TeamNumber) playerTeamMapping;
        mapping(address => uint256) playerAmountMapping;
        address[] players;
    }

    event GameAdded(uint256 indexed gameIndex);
    event BiddingOpen(
        uint256 indexed gameIndex,
        GameState gameState,
        BetState betState
    );
    event BiddingClose(
        uint256 indexed gameIndex,
        GameState gameState,
        BetState betState
    );
    event ResultDeclared(
        uint256 indexed gameIndex,
        Winner indexed winner,
        GameState gameState,
        BetState betState
    );
    event BetSuccessful(
        uint256 indexed gameIndex,
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
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function addGame(
        string memory _name,
        string memory _team1,
        string memory _team2,
        uint256 _betting_start_time,
        uint256 _match_start_time
    ) public onlyOwner {
        Game storage game = games.push();
        game.id = gameCounter;
        game.name = _name;
        game.gameState = GameState.UPCOMING;
        game.betState = BetState.NONE;
        game.time.betting_start_time = _betting_start_time;
        game.time.match_start_time = _match_start_time;
        game.team1.name = _team1;
        game.team2.name = _team2;
        gameCounter = gameCounter + 1;
        emit GameAdded(game.id);
    }

    function openBidding(uint256 _gameIndex) public onlyOwner {
        Game storage game = games[_gameIndex];
        require(
            game.betState != BetState.BIDDING_STARTED,
            "Betting Already Started"
        );
        game.betState = BetState.BIDDING_STARTED;
        activeGameIds.push(_gameIndex);
        emit BiddingOpen(_gameIndex, game.gameState, game.betState);
    }

    function closeBidding(uint256 _gameIndex) public onlyOwner {
        Game storage game = games[_gameIndex];
        require(
            game.betState != BetState.BIDDING_CLOSED,
            "Betting Already Closed"
        );
        game.gameState = GameState.STARTED;
        game.betState = BetState.BIDDING_CLOSED;
        emit BiddingClose(_gameIndex, game.gameState, game.betState);
    }

    struct ActiveGame {
        uint256 id;
        string name;
        GameState gameState;
        BetState betState;
        Time time;
        Team team1;
        Team team2;
        Winner winner;
    }

    function getActiveGames() public view returns (ActiveGame[] memory) {
        ActiveGame[] memory active_gems = new ActiveGame[](
            activeGameIds.length
        );
        for (uint256 i = 0; i < activeGameIds.length; i++) {
            Game storage game = games[activeGameIds[i]];
            active_gems[i].id = game.id;
            active_gems[i].name = game.name;
            active_gems[i].gameState = game.gameState;
            active_gems[i].time = game.time;
            active_gems[i].team1 = game.team1;
            active_gems[i].team2 = game.team2;
            active_gems[i].winner = game.winner;
        }
        return active_gems;
    }

    // function closeGame(uint256 _gameIndex) public onlyOwner {
    //     games[_gameIndex].gameState = GameState.LISTED;
    //     activeGameId = 0;
    //     anyGameActive = false;
    // }

    function bet(uint256 gameIndex, TeamNumber _teamNumber) public payable {
        Game storage game = games[gameIndex];
        require(
            game.betState == BetState.BIDDING_STARTED,
            "Game is not open for bids."
        );
        require(
            game.playerAmountMapping[msg.sender] <= 0,
            "You already placed a bet."
        ); //TODO allow to add more bet in same team
        require(_teamNumber != TeamNumber.NONE, "Incorrect team.");
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
            gameIndex,
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

            // rewards after contracts commission
            uint256 rewards = poolPrize - poolPrize / 10;
            uint256 spentRewards;

            Bids[] memory winnerBids = winnerTeam.bids;
            for (uint256 i = 0; i < winnerBids.length; i++) {
                Bids memory bid = winnerBids[i];
                uint256 playerReward = (rewards * bid.amount) /
                    winnerTeam.totalBetAmount;
                walletBalances[bid.player] += playerReward + bid.amount;
                betBalances[bid.player] -= bid.amount;
                spentRewards += playerReward;
            }

            Bids[] memory looserBids = looserTeam.bids;
            for (uint256 i = 0; i < looserBids.length; i++) {
                Bids memory bid = looserBids[i];
                betBalances[bid.player] -= bid.amount;
            }
            // add leftover rewards to the contract
            contractBalance += poolPrize - spentRewards;
        }

        game.gameState = GameState.ENDED;
        game.betState = BetState.RESULT_DECLARED;
        removeGameFromActiveList(gameIndex);
        emit ResultDeclared(gameIndex, winner, game.gameState, game.betState);
    }

    struct PlayerBetInfo {
        TeamNumber teamNumber;
        string teamName;
        uint256 amountBetted;
        uint256 team1Bets;
        uint256 team2Bets;
    }

    function getPlayerBetInfo(uint256 gameIndex,address playerAddress)
        public
        view
        returns (PlayerBetInfo memory)
    {
        Game storage game = games[gameIndex];
        string memory team;
        TeamNumber teamNumber = game.playerTeamMapping[playerAddress];
        uint256 amountBetted = game.playerAmountMapping[playerAddress];
        if (teamNumber == TeamNumber.TEAM_1) team = game.team1.name;
        else if (teamNumber == TeamNumber.TEAM_2) team = game.team2.name;
        return
            PlayerBetInfo(
                teamNumber,
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

    function removeGameFromActiveList(uint256 index) internal {
        for (uint256 i = 0; i < activeGameIds.length; i++) {
            if (index == activeGameIds[i]) {
                activeGameIds[i] = activeGameIds[activeGameIds.length - 1];
                activeGameIds.pop();
                break;
            }
        }
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