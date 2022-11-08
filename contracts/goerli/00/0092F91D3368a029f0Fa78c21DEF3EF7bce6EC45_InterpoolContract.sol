// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IpFakeEnetScore} from "./IpFakeEnetScore.sol";
import {IpPool} from "./IpPool.sol";

/*
 * @title A consumer contract for Enetscores.
 * @author Perrin GRANDNE from Irruption Lab.
 * @notice Interact with the daily events API.
 * @dev Uses @chainlink/contracts 0.4.2.
 */

contract InterpoolContract is IpFakeEnetScore, IpPool {
    struct Gain {
        address player;
        uint256 score;
        uint256 rankExAequo;
        uint256 rewardNoExAequo;
        uint256 cumulatedRewardsNoExAequo;
        uint256 cumulatedRewardsPerRank;
        uint256 rewardPerRankPerPlayer;
    }

    struct Rank {
        address player;
        uint256 score;
        uint256 rankExAequo;
    }

    struct PlayerScoreTicket {
        address player;
        uint256 nbTickets;
        uint256 score;
    }

    struct PlayerScore {
        address player;
        uint256 score;
    }

    struct ContestResult {
        address player;
        uint256 nbTickets;
        uint256 score;
        uint256 rankExAequo;
        uint256 rewardPerRankPerPlayer;
    }

    uint256 prizePool;
    uint256 gainPercentage;
    mapping(uint256 => ContestResult[]) public contestTable;

    mapping(uint256 => uint256) nbTotalTicketsPerContest;

    constructor() {
        prizePool = 1758;
        gainPercentage = 5;
        nbTotalTicketsPerContest[1] = 25;
    }

    function getScoreTable(uint256 _contestId)
        public
        view
        returns (PlayerScoreTicket[] memory)
    {
        uint256 nbPlayers = IpFakeEnetScore
            .listPlayersPerContest[_contestId]
            .length;
        address player;
        uint256 nbTickets;
        PlayerScoreTicket[] memory scoreTable = new PlayerScoreTicket[](
            nbPlayers
        );
        uint256 scorePlayer;
        for (uint256 i = 0; i < nbPlayers; i++) {
            player = listPlayersPerContest[_contestId][i];
            nbTickets = interPoolTicket.balanceOf(player);
            scorePlayer = IpFakeEnetScore.checkResult(_contestId, player);
            scoreTable[i] = PlayerScoreTicket({
                player: player,
                nbTickets: nbTickets,
                score: scorePlayer
            });
        }
        return scoreTable;
    }

    function calculateGain(
        uint _contestId,
        PlayerScoreTicket[] memory _scoreTable
    ) public view returns (Gain[] memory) {
        uint256 ranking;
        uint256 lastRanking;
        uint256 cumulatedRewardsNoExAequo = 0;
        uint256 nbExAequo;
        uint256 rewardNoExAequo;
        uint256 indexTable = 0;
        uint256 nbTotalTickets = nbTotalTicketsPerContest[_contestId];
        PlayerScore[] memory scoreTablePerTicket = new PlayerScore[](
            nbTotalTickets
        );
        Rank[] memory rankTable = new Rank[](nbTotalTickets);
        Gain[] memory gainTable = new Gain[](nbTotalTickets);
        for (uint256 i = 0; i < _scoreTable.length; i++) {
            PlayerScoreTicket memory tempPlayerScore = _scoreTable[i];
            for (uint256 j = 0; j < tempPlayerScore.nbTickets; j++) {
                scoreTablePerTicket[indexTable] = PlayerScore({
                    player: tempPlayerScore.player,
                    score: tempPlayerScore.score
                });
                indexTable++;
            }
        }
        for (uint256 i = 0; i < nbTotalTickets; i++) {
            ranking = 1;
            for (uint256 j = 0; j < nbTotalTickets; j++) {
                if (
                    scoreTablePerTicket[i].score < scoreTablePerTicket[j].score
                ) {
                    ranking++;
                    if (ranking > lastRanking) {
                        lastRanking = ranking;
                    }
                }
            }
            rankTable[i] = Rank({
                player: scoreTablePerTicket[i].player,
                score: scoreTablePerTicket[i].score,
                rankExAequo: ranking
            });
        }
        indexTable = 0;
        for (uint256 i = 1; i <= lastRanking; i++) {
            for (uint256 j = 0; j < nbTotalTickets; j++) {
                if (rankTable[j].rankExAequo == i) {
                    gainTable[indexTable] = (
                        Gain({
                            player: rankTable[j].player,
                            score: rankTable[j].score,
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
        /// Inititate the table with the first row
        rewardNoExAequo =
            ((prizePool - cumulatedRewardsNoExAequo) * gainPercentage) /
            100;
        cumulatedRewardsNoExAequo += rewardNoExAequo;
        gainTable[0].rewardNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsPerRank = rewardNoExAequo;
        gainTable[0].rewardPerRankPerPlayer = rewardNoExAequo;
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

    function updateContestTable(uint _contestId) public {
        PlayerScoreTicket[] memory scoreTable = getScoreTable(_contestId);
        Gain[] memory gainTable = calculateGain(_contestId, scoreTable);
        uint256 indexTable = 0;
        /// Inititate the table with the first row
        contestTable[_contestId].push(
            ContestResult({
                player: gainTable[0].player,
                nbTickets: 1,
                score: gainTable[0].score,
                rankExAequo: gainTable[0].rankExAequo,
                rewardPerRankPerPlayer: gainTable[0].rewardPerRankPerPlayer
            })
        );
        for (uint i = 1; i < nbTotalTicketsPerContest[_contestId]; i++) {
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
                        score: gainTable[i].score,
                        rankExAequo: gainTable[i].rankExAequo,
                        rewardPerRankPerPlayer: gainTable[i]
                            .rewardPerRankPerPlayer
                    })
                );
                indexTable++;
            }
        }
    }

    function getPlayerRank(uint _contestId, address _player)
        public
        view
        returns (uint256)
    {
        PlayerScoreTicket[] memory scoreTable = getScoreTable(_contestId);
        uint256 ranking;
        uint256 nbPlayers = scoreTable.length;
        uint256 playerRank = 0;
        Rank[] memory rankTable = new Rank[](nbPlayers);
        for (uint256 i = 0; i < nbPlayers; i++) {
            ranking = 1;
            for (uint256 j = 0; j < nbPlayers; j++) {
                if (scoreTable[i].score < scoreTable[j].score) {
                    ranking++;
                }
            }
            rankTable[i] = Rank({
                player: scoreTable[i].player,
                score: scoreTable[i].score,
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

    function getContestTable(uint256 _contestId)
        public
        view
        returns (ContestResult[] memory)
    {
        return contestTable[_contestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
 * @title A consumer contract for Enetscores.
 * @author Perrin GRANDNE from Irruption Lab.
 * @notice Interact with the daily events API.
 * @dev Uses @chainlink/contracts 0.4.2.
 */
contract IpFakeEnetScore {
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

    // @notice structure for scores from a game
    struct Scores {
        uint8 homeScore;
        uint8 awayScore;
    }

    // @notice structure for data received from the front end, predictions from a player
    struct GamePredict {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
    }

    // @notice structure for id league and end of contest for each contest
    struct ContestInfo {
        uint256 leagueId;
        uint256 dateEnd;
    }

    // @notice association between request id and data
    mapping(string => GameCreate[]) private requestIdGames;

    //@notice association between array of requests and contest
    mapping(uint256 => string[]) private listRequestsPerContest;

    // @notice assocation between contest info and contest
    mapping(uint256 => ContestInfo) private infoContest;

    // @notice use struct Score for a game id
    mapping(uint32 => Scores) private scoresPerGameId;

    // @notice use struct Score for all game id predicted for a contest by a player
    mapping(address => mapping(uint256 => mapping(uint32 => Scores)))
        private predictionsPerPlayerPerContest;

    // @notice list of all playesr who participate to the contest
    mapping(uint256 => address[]) internal listPlayersPerContest;

    // @notice specId = jobId from https://market.link/nodes/Enetscores/integrations
    bytes32 private specId;
    // @notice amount of Link for Oracle
    uint256 private payment;
    uint256 private currentContestId;

    mapping(uint32 => bool) gamePlayed;

    constructor() {
        currentContestId = 0; // initialisation of current contest id
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /*
     * @notice Requests the tournament games either to be created or to be resolved on a specific date.
     * @dev Requests the 'schedule' endpoint. Result is an array of GameCreate or GameResolve encoded (see structs).
     * specId the jobID.
     * payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _market the number associated with the type of market (see Data Conversions).
     * @param _leagueId the tournament ID.
     * @param _date the starting time of the event as a UNIX timestamp in seconds.
     */

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

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
    ) public {
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

    /*
     * @notice Creation of a Contest : 1667315919 ; 1669907919
     * @param _leagueId: 53 for Ligue 1, 42 Champion's League, 77 World Cup
     * @param _listDates: Array of dates with games for request id*
     * @param _dateEndContest: Timtestamp of the end for saving predictions
     * create a new contest => increment the current contest id
     * schedule all request associated to date and league and save it in listRequestsPerContest
     * add information about the contest in infoContest
     */
    function createContest(
        uint256 _leagueId,
        string[] memory _listRequestId,
        uint256 _dateEndContest
    ) public {
        currentContestId++;
        for (uint256 i = 0; i < _listRequestId.length; i++) {
            listRequestsPerContest[currentContestId].push(_listRequestId[i]);
        }
        infoContest[currentContestId] = ContestInfo({
            leagueId: _leagueId,
            dateEnd: _dateEndContest
        });
    }

    /*
     * @notice Get scores of games when they are finished
     * @param _leagueId: 53 for Ligue 1, 42 Champion's League, 77 World Cup
     * @param _date : date of request to resolve
     * resolve a request => get results of games for a league and a date
     * and save scores in scoresPerGameId
     */
    function saveRequestResults(GameResolve[] memory _fakeGameResolve) public {
        for (uint256 i = 0; i < _fakeGameResolve.length; i++) {
            scoresPerGameId[_fakeGameResolve[i].gameId] = Scores({
                homeScore: _fakeGameResolve[i].homeScore,
                awayScore: _fakeGameResolve[i].awayScore
            });
            gamePlayed[_fakeGameResolve[i].gameId] = true;
        }
    }

    /**
     * @notice Save predictions for a player for the current contest
     * @param _gamePredictions: table of games with predicted scores received from the front end
     * Verify the contest is still open and the number of predictions is the expected number
     * Save scores of games in predictionsPerPlayerPerContest
     */
    function savePrediction(GamePredict[] memory _gamePredictions) public {
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
        for (uint256 i = 0; i < nbOfGames; i++) {
            predictionsPerPlayerPerContest[msg.sender][currentContestId][
                _gamePredictions[i].gameId
            ] = Scores({
                homeScore: _gamePredictions[i].homeScore,
                awayScore: _gamePredictions[i].awayScore
            });
        }
        listPlayersPerContest[currentContestId].push(msg.sender);
    }

    /* ========== INTERPOOL VIEW FUNCTIONS ========== */

    /**
     * @notice Get the number of games for a request id
     * @param _requestId: the id of request to ask
     */
    function getNumberOfGamesPerRequest(string memory _requestId)
        public
        view
        returns (uint)
    {
        return requestIdGames[_requestId].length;
    }

    /**
     * @notice Get the list of requests id for a contest
     * @param _contestId: the id of contest to ask
     */
    function getRequestIdPerContest(uint256 _contestId)
        external
        view
        returns (string[] memory)
    {
        return listRequestsPerContest[_contestId];
    }

    /**
     * @notice Get the number of games for a contest
     * @param _contestId: the id of contest to ask
     */
    function getNumberOfGamesPerContest(uint256 _contestId)
        public
        view
        returns (uint256)
    {
        uint256 nbGames = 0;
        for (
            uint256 i = 0;
            i < listRequestsPerContest[_contestId].length;
            i++
        ) {
            nbGames += requestIdGames[listRequestsPerContest[_contestId][i]]
                .length;
        }
        return nbGames;
    }

    function getScorePerGameId(uint32 _gameId)
        public
        view
        returns (Scores memory)
    {
        return scoresPerGameId[_gameId];
    }

    /**
     * @notice Get the list of games for a contest
     * @param _contestId: the id of contest to ask
     * nbGames is used to agregate all games of all requests from the contest
     * GameCreate[] is used to store all games of all requests with info
     * iGames is used to increment the array GameCreate[]
     */
    function getListGamesPerContest(uint256 _contestId)
        public
        view
        returns (GameCreate[] memory)
    {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint256 iGames;
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        for (
            uint256 i = 0;
            i < listRequestsPerContest[_contestId].length;
            i++
        ) {
            nbGames = requestIdGames[listRequestsPerContest[_contestId][i]]
                .length;
            for (uint256 j = 0; j < nbGames; j++) {
                listGamesPerContest[iGames] = requestIdGames[
                    listRequestsPerContest[_contestId][i]
                ][j];
                iGames++;
            }
        }
        return listGamesPerContest;
    }

    /**
     * @notice Get the previsions per Player per Contest
     * @param _contestId: the id of contest to ask
     * @param _player: address of the player
     * Get the number of expected games for the contest,
     * Get the list of all Games for the contest
     * Associate each game id with home score and array score from the player
     */
    function getPrevisionsPerPlayerPerContest(
        uint256 _contestId,
        address _player
    ) public view returns (GamePredict[] memory) {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint32 gameId;
        GamePredict[] memory listPredictionsPerContest = new GamePredict[](
            nbGames
        );
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        listGamesPerContest = getListGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesPerContest[i].gameId;
            listPredictionsPerContest[i] = GamePredict({
                gameId: gameId,
                homeScore: predictionsPerPlayerPerContest[_player][_contestId][
                    gameId
                ].homeScore,
                awayScore: predictionsPerPlayerPerContest[_player][_contestId][
                    gameId
                ].awayScore
            });
        }
        return listPredictionsPerContest;
    }

    /**
     * @notice Transform scores of home and away to a result of game : 0 = home win, 1 = draw, 2 = away win
     * @param _homeScore: Score from the team A
     * @param _awayScore: Score from the team B
     */
    function calculateMatchResult(uint8 _homeScore, uint8 _awayScore)
        private
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

    /**
     * @notice Compare the predictions of a player with results from Oracle for a contest
     * @param _contestId: Contest id for the comparison
     * @param _player: Player which compare his predictions with Oracle results
     */
    function checkResult(uint256 _contestId, address _player)
        public
        view
        returns (uint256)
    {
        uint256 gameResultPlayer; // 0 home win, 1 draw, 2 away win
        uint256 gameResultOracle; // 0 home win, 1 draw, 2 away win
        uint256 playerScoring = 0;
        uint32 gameId;
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        listGamesPerContest = getListGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesPerContest[i].gameId;
            gameResultPlayer = calculateMatchResult(
                predictionsPerPlayerPerContest[_player][_contestId][gameId]
                    .homeScore,
                predictionsPerPlayerPerContest[_player][_contestId][gameId]
                    .awayScore
            );
            gameResultOracle = calculateMatchResult(
                scoresPerGameId[gameId].homeScore,
                scoresPerGameId[gameId].awayScore
            );
            if (
                gameResultPlayer == gameResultOracle &&
                gamePlayed[gameId] == true
            ) {
                playerScoring += 1;
                if (
                    predictionsPerPlayerPerContest[_player][_contestId][gameId]
                        .homeScore ==
                    scoresPerGameId[gameId].homeScore &&
                    predictionsPerPlayerPerContest[_player][_contestId][gameId]
                        .awayScore ==
                    scoresPerGameId[gameId].awayScore
                ) {
                    playerScoring += 2;
                }
            }
        }
        return playerScoring;
    }

    function getCurrentContestId() public view returns (uint256) {
        return currentContestId;
    }

    function getNumberOfPlayers(uint256 _contestId)
        public
        view
        returns (uint256)
    {
        return (listPlayersPerContest[_contestId].length);
    }

    function getContestPredictionEndDate() public view returns (uint256) {
        return infoContest[currentContestId].dateEnd;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InterPool : Pool Contract
/// @author Perrin GRANDNE
/// @notice Contract for Deposit and Withdraw on the Pool
/// @custom:experimental This is an experimental contract.

/// @notice Only the ERC-20 functions we need
interface IERC20 {
    /// @notice Get the balance of aUSDC in No Pool No Game
    /// @notice and balance of USDC from the Player
    function balanceOf(address account) external view returns (uint);

    /// @notice Approve the deposit of USDC from No Pool No Game to Aave
    function approve(address spender, uint amount) external returns (bool);

    /// @notice Confirm the allowed amount before deposit
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    /// @notice Withdraw USDC from No Pool No Game
    function transfer(address recipient, uint amount) external returns (bool);

    /// @notice Transfer USDC from User to No Pool No Game
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    /// @notice Mint NPNGaUSDC when user deposits on the pool
    function mint(address sender, uint amount) external;

    /// @notice Burn NPNGaUSDC when user withdraws from the pool
    function burn(address sender, uint amount) external;

    /// @notice Get the Total Supply of the token
    function totalSupply() external view returns (uint);
}

/// @notice Only the PoolAave functions we need
interface PoolAave {
    /// @notice Deposit USDC to Aave Pool
    function supply(
        address asset,
        uint amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// @notice Withdraw USDC from Aave Pool
    function withdraw(
        address asset,
        uint amount,
        address to
    ) external;
}

/// BEGINNING OF THE CONTRACT
contract IpPool is Ownable, Pausable {
    mapping(uint => uint) private remainedUnclaimedRewardsPerContest;

    /// @notice balance of total claimed rewards per player
    mapping(address => uint) private balanceOfClaimedRewards;

    IERC20 private usdcToken;
    IERC20 private aUsdcToken;
    IERC20 internal interPoolTicket;
    PoolAave private poolAave;

    constructor() {
        usdcToken = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
        poolAave = PoolAave(0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6);
        aUsdcToken = IERC20(0x1Ee669290939f8a8864497Af3BC83728715265FF);
        interPoolTicket = IERC20(0x514CD1D6FaB71307cdb51304638Edae51a402dA4);
    }

    /* ========== INTERPOOL WRITE FUNCTIONS ========== */

    /// Pausable functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Deposit USDC on Pool which will be deposited on Aave and get the same amount ofNPNGaUSCD
    function depositOnAave(uint _amount) public {
        require(_amount % 50 == 0, "The amount must be a multiple of 50");
        require(
            _amount <= usdcToken.balanceOf(msg.sender),
            "Insufficent amount of USDC"
        );
        require(
            _amount <= usdcToken.allowance(msg.sender, address(this)),
            "Insufficient allowed USDC"
        );
        uint256 nbTickets = _amount / 50;
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(poolAave), _amount);
        poolAave.supply(address(usdcToken), _amount, address(this), 0);
        interPoolTicket.mint(msg.sender, nbTickets);
    }

    /// READ FUNCTIONS

    /// @notice get the Prize Pool of the current contest
    function getGlobalPrizePool() public view returns (uint) {
        uint256 aavePoolValue = aUsdcToken.balanceOf(address(this));
        uint256 ipPoolValue = interPoolTicket.totalSupply();
        return aavePoolValue - ipPoolValue;
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