// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title InterPool : InterPool Contract
/// @author Perrin GRANDNE
/// @notice Contract for InterPool Game, a prediction game for FIFA World Cup
/// @notice This contract is used to test and improve calculations, it will merge with Pool Contract after validation
/// @custom:experimental This is an experimental contract.

/// @notice Only ERC-20 functions we need
interface IERC20 {
    /// @notice Get the number of tickets (token) per player
    function balanceOf(address account) external view returns (uint);

    /// @notice Get the Total Supply of the token
    function totalSupply() external view returns (uint);
}

/// @notice Only EnetPulse functions we need
interface IEnet {
    /// @notice create a Market for Games, returns request id
    function requestSchedule(
        uint256 _market,
        uint256 _leagueId,
        uint256 _date
    ) external returns (bytes32);

    // @notice get result of a game (homeScore, awayScore) for a game id from a request
    function getScoresPerGameIdPerRequest(bytes32 _requestId, uint32 _gameId)
        external
        view
        returns (
            uint8,
            uint8,
            bool
        );

    /// @notice get a game id from a request id and an index
    function getGameIdPerRequestIndex(bytes32 _requestId, uint256 _idx)
        external
        view
        returns (uint32);

    /// @notice Get Number of Games per Request Id
    function getNumberOfGamesPerRequest(bytes32 _requestId)
        external
        view
        returns (uint256);

    function getWinningsPerPlayer(address _player)
        external
        view
        returns (uint256, uint256);
}

interface IPool {
    function depositOnAave(uint _amount, address _player) external;

    function claimFromPool(address _player) external;

    function withdrawFromPool(uint256 _nbTickets, address _player) external;

    function setWinnings(address _player, uint256 _winnings) external;

    function getGlobalPrizePool() external view returns (uint256);

    function getWinningsPerPlayer(address _player)
        external
        view
        returns (uint256, uint256);
}

/* ========== CONTRACT BEGINNING ========== */

contract InterpoolContract is Ownable, Pausable {
    struct GameResolve {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    /// @notice structure for id league and end of contest for each contest
    struct ContestInfo {
        uint256 leagueId;
        uint256 dateEnd;
    }

    /// @notice structure for data received from the front end, predictions from a player
    struct GamePredict {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
    }

    /// @notice Number of ticket of a player when he submits his predictions
    struct NbTicketsPerPlayer {
        address player;
        uint256 nbTickets;
    }

    /// @notice Number of points and tickets for player of a contest
    /// @notice Used for Points Table
    struct PlayerPointsAndTickets {
        address player;
        uint256 nbTickets;
        uint256 nbPoints;
    }

    /// @notice Scores for a Player in a Contest
    struct PlayerPoints {
        address player;
        uint256 nbPoints;
    }

    /// @notice Rank of player with ex-aequo
    /// @notice if 2 players have the same score, they have the same rank
    /// @notice and the next rank is + 2 instrad of +1
    struct Rank {
        address player;
        uint256 nbPoints;
        uint256 rankExAequo;
    }

    /// @notice struct of Gain per Player for Contest Result calculation
    struct Gain {
        address player;
        uint256 nbPoints;
        uint256 rankExAequo;
        uint256 rewardNoExAequo;
        uint256 cumulatedRewardsNoExAequo;
        uint256 cumulatedRewardsPerRank;
        uint256 rewardPerRankPerPlayer;
    }

    /// @notice struct for Contest Table
    struct ContestResult {
        address player;
        uint256 nbTickets;
        uint256 nbPoints;
        uint256 rankExAequo;
        uint256 rewardPerRankPerPlayer;
    }

    /// @notice association between contest info and contest
    mapping(uint256 => ContestInfo) internal infoContest;

    /// @notice list of all players who participate to the contest
    /// @notice and their number of ticket when they submitted their predictions
    /// @dev contest Id = Table with players and their number of tickets
    mapping(uint256 => NbTicketsPerPlayer[])
        public listPlayersWithNbTicketsPerContest;

    /// @notice Total Number of Tickets per Contest
    /// @dev contest id => number ot tickets
    mapping(uint256 => uint256) private nbTotalTicketsPerContest;

    /// @notice use struct Score for all game id predicted for a contest by a player
    /// @dev player => contest id => game id => score prediction
    mapping(address => mapping(uint32 => uint8[2]))
        internal predictionsPerPlayerPerGame;

    /// @notice association between array of requests and contest
    /// @dev contest id => array of request id
    mapping(uint256 => bytes32[]) private listCreatedRequestsPerContest;

    /// @notice association between array of requests and contest
    /// @dev contest id => array of request id
    mapping(uint256 => bytes32[]) private listResolvedRequestsPerContest;

    /// @notice Contest Table at the end of a contest
    /// @dev contest id => Table of results for the contest
    mapping(uint256 => ContestResult[]) private contestTable;

    /// @notice Check if a player submitted predictions during the current contest
    /// @notice If yes he cannot withdraw his tickets
    /// @dev contest id => player => Played or Not
    mapping(uint256 => mapping(address => bool))
        private verifPlayerPlayedPerContest;

    /// @notice current contest id
    uint256 internal currentContestId;

    /// @notice Percentage that each player will earn from the remaining winnings
    uint256 private gainPercentage;

    IERC20 private interpoolTicket;

    /// @notice interface for EnetPulse Contract
    IEnet private enetContract;

    /// @notice interface for Pool Contract
    IPool private poolContract;

    constructor() {
        interpoolTicket = IERC20(0x1E0a4b2e73779fd6a1Db504CD3668f23F42cE683);
        setEnetContract(0x49672EdD419e4795307CCC906Cab0E8Fc5d147f9);
        setPoolContract(0xd3bAbc11CCC23648a24c42D4812af2380C28626A);
        gainPercentage = 5;
        currentContestId = 0; // initialisation of current contest id
    }

    /* ========== INTERPOOL WRITE FUNCTIONS ========== */

    function setPoolContract(address _poolContract) public onlyOwner {
        poolContract = IPool(_poolContract);
    }

    /// @notice Change the contract used for Prediction (only for testnet)
    function setEnetContract(address _enetContract) public onlyOwner {
        enetContract = IEnet(_enetContract);
    }

    /// @notice Pausable functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Create a contest with a list of requests/games, league Id and end of predictions
     * @param _leagueId : 77: FIFA World Cup / 53: France Ligue / 42: UEFA Champion's League
     *  _dateEndContestPredictions: Date in timestamp for the end of predictions saving
     * @param _requestDates : Array of days in timestamp for matches of the contest
     */

    function createContest(
        uint256 _leagueId,
        uint256 _dateEndContestPredictions,
        uint256[] memory _requestDates
    ) external onlyOwner {
        currentContestId++;
        uint256 nbRequest = _requestDates.length;
        for (uint256 i = 0; i < nbRequest; i++) {
            listCreatedRequestsPerContest[currentContestId].push(
                enetContract.requestSchedule(0, _leagueId, _requestDates[i])
            );
        }
        infoContest[currentContestId] = ContestInfo({
            leagueId: _leagueId,
            dateEnd: _dateEndContestPredictions
        });
    }

    /**
     * @notice Resolve games, results are stored in a mapping
     * @param _leagueId : 77: FIFA World Cup / 53: France Ligue / 42: UEFA Champion's League
     * @param _requestDates : Array of days in timestamp for matches of the contest
     */

    function resolveGames(uint256 _leagueId, uint256[] memory _requestDates)
        external
        onlyOwner
    {
        uint256 nbRequest = _requestDates.length;
        for (uint256 i = 0; i < nbRequest; i++) {
            listResolvedRequestsPerContest[currentContestId].push(
                enetContract.requestSchedule(1, _leagueId, _requestDates[i])
            );
        }
    }

    /**
     * @notice Save predictions for a player for the current contest
     *  @param _gamePredictions: table of games with predicted scores received from the front end
     * Verify the contest is still open and the number of predictions is the expected number
     * Save scores of games in predictionsPerPlayerPerContest
     */
    function savePrediction(GamePredict[] memory _gamePredictions) external {
        require(
            interpoolTicket.balanceOf(msg.sender) > 0,
            "You need a ticket for saving predictions!"
        );
        require(
            block.timestamp < infoContest[currentContestId].dateEnd,
            "Prediction Period is closed!"
        );
        require(
            _gamePredictions.length ==
                getNumberOfGamesPerContest(currentContestId),
            "The number of predictions doesn't match!"
        );
        uint256 nbOfGames = getNumberOfGamesPerContest(currentContestId);
        uint256 nbTickets = interpoolTicket.balanceOf(msg.sender);
        /// Create/Update all predictions for a player
        for (uint256 i = 0; i < nbOfGames; i++) {
            predictionsPerPlayerPerGame[msg.sender][
                _gamePredictions[i].gameId
            ] = [_gamePredictions[i].homeScore, _gamePredictions[i].awayScore];
        }
        bool alreadyExist;
        /// Check if the player already played, if not add him in players contest list
        for (
            uint256 i = 0;
            i < listPlayersWithNbTicketsPerContest[currentContestId].length;
            i++
        ) {
            if (
                msg.sender ==
                listPlayersWithNbTicketsPerContest[currentContestId][i].player
            ) {
                listPlayersWithNbTicketsPerContest[currentContestId][i]
                    .nbTickets = nbTickets;
                alreadyExist = true;
            }
        }
        if (alreadyExist == false) {
            listPlayersWithNbTicketsPerContest[currentContestId].push(
                NbTicketsPerPlayer({player: msg.sender, nbTickets: nbTickets})
            );
            verifPlayerPlayedPerContest[currentContestId][msg.sender] = true;
        }
    }

    /// At the end of the contest, create the table with all infos of the contest
    function createContestTable(uint _contestId) external onlyOwner {
        nbTotalTicketsPerContest[_contestId] = interpoolTicket.totalSupply();
        PlayerPointsAndTickets[] memory pointsTable = getPointsTable(
            _contestId
        );
        Gain[] memory gainTable = calculateGain(_contestId, pointsTable);
        uint256 indexTable = 0;
        /// Inititate the table with the first row
        contestTable[_contestId].push(
            ContestResult({
                player: gainTable[0].player,
                nbTickets: 1,
                nbPoints: gainTable[0].nbPoints,
                rankExAequo: gainTable[0].rankExAequo,
                rewardPerRankPerPlayer: gainTable[0].rewardPerRankPerPlayer
            })
        );
        for (uint i = 1; i < nbTotalTicketsPerContest[_contestId]; i++) {
            /// Check if the player of the row is the same than the previous one, if yes update his info (nbTickets + rewards)
            if (gainTable[i].player == gainTable[i - 1].player) {
                contestTable[_contestId][indexTable].nbTickets++;
                contestTable[_contestId][indexTable]
                    .rewardPerRankPerPlayer += gainTable[i]
                    .rewardPerRankPerPlayer;
            } else {
                contestTable[_contestId].push(
                    ContestResult({
                        player: gainTable[i].player,
                        nbTickets: 1,
                        nbPoints: gainTable[i].nbPoints,
                        rankExAequo: gainTable[i].rankExAequo,
                        rewardPerRankPerPlayer: gainTable[i]
                            .rewardPerRankPerPlayer
                    })
                );
                indexTable++;
            }
        }
        /// Update pendings winnings based on results from the contest Table
        for (uint256 i = 0; i < contestTable[_contestId].length; i++) {
            address player = contestTable[_contestId][i].player;
            poolContract.setWinnings(
                player,
                contestTable[_contestId][i].rewardPerRankPerPlayer
            );
        }
    }

    function deposit(uint256 _amount) external {
        poolContract.depositOnAave(_amount, msg.sender);
    }

    /// @notice witdraw USDC and burn ticket if the contest is finished
    function withdraw(uint256 _nbTickets) external {
        require(
            verifPlayerPlayedPerContest[currentContestId][msg.sender] ==
                false ||
                block.timestamp > infoContest[currentContestId].dateEnd,
            "You cannot withdraw until the end of the contest!"
        );
        poolContract.withdrawFromPool(_nbTickets, msg.sender);
    }

    function claim() external {
        poolContract.claimFromPool(msg.sender);
    }

    /* ========== INTERPOOL READ FUNCTIONS ========== */

    /**
     * @notice Define the winner of the game
     * @notice 0 : Home Winner, 1 : Draw, 2 Away Winner
     * @param _homeScore score of the Home Team
     * @param _awayScore score of the Away Team
     */

    /// @notice calculate result of a game : 0 = homeTeam won / 1 = draw / 2 = awayTeam won
    function calculateMatchResult(uint8 _homeScore, uint8 _awayScore)
        public
        pure
        returns (uint256)
    {
        uint256 gameResult;
        if (_homeScore > _awayScore) {
            gameResult = 0;
        } else if (_awayScore > _homeScore) {
            gameResult = 2;
        } else {
            gameResult = 1;
        }
        return gameResult;
    }

    /// @notice calculate number of points for a player in a contest
    /// @notice good result : +1 / good scores for home and away team : +2
    function getPointsOfPlayerForContest(uint256 _contestId, address _player)
        public
        view
        returns (uint256)
    {
        uint256 gameResultPlayer;
        uint256 gameResultOracle;
        uint256 playerScoring = 0;
        uint32 gameId;
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint32[] memory listGamesIdPerContest = new uint32[](nbGames);
        listGamesIdPerContest = getIdGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesIdPerContest[i];
            (
                uint8 resolveHomeScore,
                uint8 resolveAwayScore
            ) = getScoresPerGameId(_contestId, gameId);
            (
                uint8 playerHomeScore,
                uint8 playerAwayScore
            ) = getPrevisionsPerPlayerPerGame(_player, gameId);
            gameResultPlayer = calculateMatchResult(
                playerHomeScore,
                playerAwayScore
            );
            gameResultOracle = calculateMatchResult(
                resolveHomeScore,
                resolveAwayScore
            );
            /// Check if the match happened, if homeScore = 255, the match doesn't exist or is not finished
            if (
                gameResultPlayer == gameResultOracle && resolveHomeScore != 255
            ) {
                playerScoring += 1;
                if (
                    playerHomeScore == resolveHomeScore &&
                    playerAwayScore == resolveAwayScore
                ) {
                    playerScoring += 2;
                }
            }
        }
        return playerScoring;
    }

    /// @notice get number of tickets and number of points for all the players of the contest
    function getPointsTable(uint256 _contestId)
        public
        view
        returns (PlayerPointsAndTickets[] memory)
    {
        uint256 nbPlayers = listPlayersWithNbTicketsPerContest[_contestId]
            .length;
        address player;
        uint256 nbTickets;
        uint256 nbPoints;
        PlayerPointsAndTickets[]
            memory pointsTable = new PlayerPointsAndTickets[](nbPlayers);
        for (uint256 i = 0; i < nbPlayers; i++) {
            player = listPlayersWithNbTicketsPerContest[_contestId][i].player;
            nbTickets = listPlayersWithNbTicketsPerContest[_contestId][i]
                .nbTickets;
            nbPoints = getPointsOfPlayerForContest(_contestId, player);
            pointsTable[i] = PlayerPointsAndTickets({
                player: player,
                nbTickets: nbTickets,
                nbPoints: nbPoints
            });
        }
        return pointsTable;
    }

    /// @notice calculate gain for a table of players with their points and tickets
    /// @param _pointsTable receive the table with points per player for the contest for gain calculation
    function calculateGain(
        uint _contestId,
        PlayerPointsAndTickets[] memory _pointsTable
    ) public view returns (Gain[] memory) {
        uint256 ranking;
        uint256 lastRanking;
        uint256 cumulatedRewardsNoExAequo = 0;
        uint256 nbExAequo;
        uint256 rewardNoExAequo;
        uint256 indexTable = 0;
        uint256 prizePool = poolContract.getGlobalPrizePool();
        uint256 nbTotalTickets = nbTotalTicketsPerContest[_contestId];
        PlayerPoints[] memory pointsTablePerTicket = new PlayerPoints[](
            nbTotalTickets
        );
        Rank[] memory rankTable = new Rank[](nbTotalTickets);
        Gain[] memory gainTable = new Gain[](nbTotalTickets);
        /// @notice create a table of points per unique ticket instead of per player
        /// @notice if a player has 2 tickets, 2 rows are create in the temp array tempPlayerPT (Player Points and Tickets)
        for (uint256 i = 0; i < _pointsTable.length; i++) {
            PlayerPointsAndTickets memory tempPlayerPT = _pointsTable[i];
            for (uint256 j = 0; j < tempPlayerPT.nbTickets; j++) {
                pointsTablePerTicket[indexTable] = PlayerPoints({
                    player: tempPlayerPT.player,
                    nbPoints: tempPlayerPT.nbPoints
                });
                indexTable++;
            }
        }
        /// @notice calculate the ranking per Ticket instead of per Player : To Be Improved : Not necessary
        for (uint256 i = 0; i < nbTotalTickets; i++) {
            ranking = 1;
            for (uint256 j = 0; j < nbTotalTickets; j++) {
                if (
                    pointsTablePerTicket[i].nbPoints <
                    pointsTablePerTicket[j].nbPoints
                ) {
                    ranking++;
                    if (ranking > lastRanking) {
                        lastRanking = ranking;
                    }
                }
            }
            rankTable[i] = Rank({
                player: pointsTablePerTicket[i].player,
                nbPoints: pointsTablePerTicket[i].nbPoints,
                rankExAequo: ranking
            });
        }

        /// @notice For each ticket, calculate the gain for each ticket
        indexTable = 0;
        for (uint256 i = 1; i <= lastRanking; i++) {
            /// @notice Initiate the table with empty rewards
            for (uint256 j = 0; j < nbTotalTickets; j++) {
                if (rankTable[j].rankExAequo == i) {
                    gainTable[indexTable] = (
                        Gain({
                            player: rankTable[j].player,
                            nbPoints: rankTable[j].nbPoints,
                            rankExAequo: rankTable[j].rankExAequo,
                            rewardNoExAequo: 0,
                            cumulatedRewardsNoExAequo: 0,
                            cumulatedRewardsPerRank: 0,
                            rewardPerRankPerPlayer: 0
                        })
                    );
                    indexTable++;
                }
            }
        }
        /// @notice Initiate the table with the first row
        rewardNoExAequo =
            ((prizePool - cumulatedRewardsNoExAequo) * gainPercentage) /
            100;
        cumulatedRewardsNoExAequo += rewardNoExAequo;
        gainTable[0].rewardNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsPerRank = rewardNoExAequo;
        gainTable[0].rewardPerRankPerPlayer = rewardNoExAequo;

        /// @notice calculate gain for each ticket, check if the rank is ex eaquo with the previous one
        /// @notice if it is the case, gains are summed and divided by the number of rows ex aequo
        for (uint256 m = 1; m < nbTotalTickets; m++) {
            rewardNoExAequo =
                ((prizePool - cumulatedRewardsNoExAequo) * gainPercentage) /
                100;
            gainTable[m].rewardNoExAequo = rewardNoExAequo;
            cumulatedRewardsNoExAequo += rewardNoExAequo;
            gainTable[m].cumulatedRewardsNoExAequo = cumulatedRewardsNoExAequo;
            if (m != (nbTotalTickets - 1)) {
                if (gainTable[m].rankExAequo == gainTable[m - 1].rankExAequo) {
                    gainTable[m].cumulatedRewardsPerRank =
                        gainTable[m - 1].cumulatedRewardsPerRank +
                        rewardNoExAequo;
                } else {
                    gainTable[m].cumulatedRewardsPerRank = rewardNoExAequo;
                    gainTable[m].rewardPerRankPerPlayer = rewardNoExAequo;
                    nbExAequo =
                        gainTable[m].rankExAequo -
                        gainTable[m - 1].rankExAequo;
                    for (uint n = 0; n < nbExAequo; n++) {
                        gainTable[m - (n + 1)]
                            .rewardPerRankPerPlayer = (gainTable[m - 1]
                            .cumulatedRewardsPerRank / nbExAequo);
                    }
                }
            } else {
                if (gainTable[m].rankExAequo == gainTable[m - 1].rankExAequo) {
                    gainTable[m].cumulatedRewardsPerRank =
                        gainTable[m - 1].cumulatedRewardsPerRank +
                        rewardNoExAequo;
                    nbExAequo = nbTotalTickets + 1 - gainTable[m].rankExAequo;
                    for (uint n = 0; n < nbExAequo; n++) {
                        gainTable[m - n].rewardPerRankPerPlayer = (gainTable[m]
                            .cumulatedRewardsPerRank / nbExAequo);
                    }
                } else {
                    gainTable[m].cumulatedRewardsPerRank = rewardNoExAequo;
                    gainTable[m].rewardPerRankPerPlayer = rewardNoExAequo;
                }
            }
        }
        return gainTable;
    }

    /// @notice Get the rank of a player  in a contest based on his number of points
    function getPlayerRank(uint _contestId, address _player)
        public
        view
        returns (uint256)
    {
        PlayerPointsAndTickets[] memory pointsTable = getPointsTable(
            _contestId
        );
        uint256 ranking;
        uint256 nbPlayers = pointsTable.length;
        uint256 playerRank = 0;
        Rank[] memory rankTable = new Rank[](nbPlayers);
        for (uint256 i = 0; i < nbPlayers; i++) {
            ranking = 1;
            for (uint256 j = 0; j < nbPlayers; j++) {
                if (pointsTable[i].nbPoints < pointsTable[j].nbPoints) {
                    ranking++;
                }
            }
            rankTable[i] = Rank({
                player: pointsTable[i].player,
                nbPoints: pointsTable[i].nbPoints,
                rankExAequo: ranking
            });
        }
        for (uint256 i = 0; i < nbPlayers; i++) {
            if (_player == rankTable[i].player) {
                playerRank = rankTable[i].rankExAequo;
                break;
            }
        }
        return playerRank;
    }

    /// @notice get the contest Table
    function getContestTable(uint256 _contestId)
        public
        view
        returns (ContestResult[] memory)
    {
        return contestTable[_contestId];
    }

    /// @notice get the list of request per contest, there are created and resolved requests
    /// @param _market : 0 for Created requests and 1 for Resolved requests
    function getListRequestIdPerContest(uint256 _contestId, uint256 _market)
        public
        view
        returns (bytes32[] memory)
    {
        if (_market == 0) {
            return listCreatedRequestsPerContest[_contestId];
        } else {
            return listResolvedRequestsPerContest[_contestId];
        }
    }

    /// @notice get number of Games for a contest
    function getNumberOfGamesPerContest(uint256 _contestId)
        public
        view
        returns (uint256)
    {
        uint256 nbGames = 0;
        uint256 nbRequest = listCreatedRequestsPerContest[_contestId].length;
        for (uint256 i = 0; i < nbRequest; i++) {
            bytes32 requestId = listCreatedRequestsPerContest[_contestId][i];
            nbGames += enetContract.getNumberOfGamesPerRequest(requestId);
        }
        return nbGames;
    }

    /// @notice get the list of Game Id for a contest
    function getIdGamesPerContest(uint256 _contestId)
        public
        view
        returns (uint32[] memory)
    {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint256 iGames;
        uint32[] memory listGamesIdPerContest = new uint32[](nbGames);
        for (
            uint256 i = 0;
            i < listCreatedRequestsPerContest[_contestId].length;
            i++
        ) {
            nbGames = enetContract.getNumberOfGamesPerRequest(
                listCreatedRequestsPerContest[_contestId][i]
            );
            for (uint256 j = 0; j < nbGames; j++) {
                listGamesIdPerContest[iGames] = enetContract
                    .getGameIdPerRequestIndex(
                        listCreatedRequestsPerContest[_contestId][i],
                        j
                    );
                iGames++;
            }
        }
        return listGamesIdPerContest;
    }

    /// @notice get result of a game (homeScore, awayScore) for a game id of a contest
    /// @notice if the game doesn't exist or is not finished the home score is 255 (to be excluded for nb points calculation)
    function getScoresPerGameId(uint256 _contestId, uint32 _gameId)
        public
        view
        returns (uint8, uint8)
    {
        uint256 nbRequests = listResolvedRequestsPerContest[_contestId].length;
        uint8 homeScore = 255;
        uint8 awayScore;
        bool existingGame;
        for (uint i = 0; i < nbRequests; i++) {
            bytes32 requestId = listResolvedRequestsPerContest[_contestId][i];
            (homeScore, awayScore, existingGame) = enetContract
                .getScoresPerGameIdPerRequest(requestId, _gameId);
            if (existingGame = true) {
                break;
            }
        }
        return (homeScore, awayScore);
    }

    /// @notice get the list of predictions per game id for a player in a contest
    function getPrevisionsPerPlayerPerContest(
        uint256 _contestId,
        address _player
    ) public view returns (GamePredict[] memory) {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint32 gameId;
        GamePredict[] memory listPredictionsPerContest = new GamePredict[](
            nbGames
        );
        uint32[] memory listGamesIdPerContest = new uint32[](nbGames);
        listGamesIdPerContest = getIdGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesIdPerContest[i];
            listPredictionsPerContest[i] = GamePredict({
                gameId: gameId,
                homeScore: predictionsPerPlayerPerGame[_player][gameId][0],
                awayScore: predictionsPerPlayerPerGame[_player][gameId][1]
            });
        }
        return listPredictionsPerContest;
    }

    /// @notice get predictions per player for a specific game
    function getPrevisionsPerPlayerPerGame(address _player, uint32 _gameId)
        public
        view
        returns (uint8, uint8)
    {
        uint8[2] memory score = predictionsPerPlayerPerGame[_player][_gameId];
        return (score[0], score[1]);
    }

    function getCurrentContestId() public view returns (uint256) {
        return currentContestId;
    }

    function getNumberOfPlayers(uint256 _contestId)
        public
        view
        returns (uint256)
    {
        return (listPlayersWithNbTicketsPerContest[_contestId].length);
    }

    function getContestPredictionEndDate() public view returns (uint256) {
        return infoContest[currentContestId].dateEnd;
    }

    function getGlobalPrizePool() external view returns (uint256) {
        return poolContract.getGlobalPrizePool();
    }

    function getWinningsPerPlayer(address _player)
        external
        view
        returns (uint256, uint256)
    {
        return poolContract.getWinningsPerPlayer(_player);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}