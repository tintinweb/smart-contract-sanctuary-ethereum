// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author The PlayEstates Developer Team
/// @title Game Enigne Contract
/// @notice Register a round, enter a round with entry fee, claim rewards
/// Admin can create a new round with the basic round info and set up the round environment.
/// Players deposit in the round with their entry fees required,
/// In the acivated period, they can claim their rewards, if they won the round under rankings
/// @dev An implemnetation contract for game engine, interacting with the admin and players

import "./GamePlayV2Storage.sol";

contract GamePlayV2 is GamePlayV2Storage {
    using SafeERC20 for IERC20;

    /// @notice Constructor
    /// @dev Store deployer's address as game engine factory's one
    constructor() {
        GAME_ENGINE_FACTORY = msg.sender;
    }

    /// @notice Initialize the game engine, called only once by the game engine factory
    /// @dev game engine needs to be secured and shouldn't be called by an attacker, called only by the deployer - game engine factory
    /// The entered and reward tokens has the same address in the game. The token would be named as OWND.
    /// Parent contract is initialized here.
    /// @param _enteredToken entered token address used in the game for game entry
    /// @param _rewardToken reward token address for the game which is the same as entry token
    /// @param _decimalsRewardToken decimals for reward token
    /// @param _admin contract admin address
    /// @param _treasury admin's treasury address
    /// @param _gameTreasury game treasury address
    /// @param _gameName game name
    /// @param _gameCompany game company name
    /// @param _gameMode game mode: 0- single, 1- multi, 2- complex
    function initialize(
        IERC20 _enteredToken,
        IERC20 _rewardToken,
        uint256 _decimalsRewardToken,
        address _admin,
        address _treasury,
        address _gameTreasury,
        string memory _gameName,
        string memory _gameCompany,
        uint256 _gameMode
    ) external initializer {
        require(_enteredToken == _rewardToken, "Tokens must be same");
        require(_decimalsRewardToken < 30, "Must be inferior to 30");
        enteredToken = _enteredToken;
        rewardToken = _rewardToken;

        gameInfo.walletAddress = _gameTreasury;
        gameInfo.gameName = _gameName;
        gameInfo.gameCompany = _gameCompany;
        gameInfo.gameMode = _gameMode;
        treasury = _treasury;
        PRECISION_FACTOR = uint256(10**(30 - _decimalsRewardToken));
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        require(msg.sender == GAME_ENGINE_FACTORY, "Not factory");
        roundId = 0;
    }
    
    function updateSystemTreasury(address _systemTreasury) external onlyOwner {
        require(_systemTreasury != address(0), "zero address");
        treasury = _systemTreasury;
    }

    function updateGameTreasury(address _gameTreasury) external onlyOwner {
        require(_gameTreasury != address(0), "zero address");
        gameInfo.walletAddress = _gameTreasury;
    }

    /// @notice Create a round in game and initialize it. It is performed by administrators
    /// @dev This function is only callable by admininstrator.
    /// @param _startTime starting time of the round in seconds based on UTC
    /// @param _entryPeriod the period time of entering the round in seconds with the entry fee specified below
    /// @param _minPlayers minimum number of players required
    /// @param _maxPlayers maximum number of players required
    /// @param _playPeriod the period time that a user can play the game in the round
    /// @param _finalPeriod the period time of being reviewed and evaluated by the platform
    /// @param _entryAmount entry fee for the round
    /// @param _adminFeeRate admin's fee percentage between 0 - 99
    /// @param _roundFeeRate game company's fee percentage between 0 - 99 to be sent to game company's treasury
    function createRound(
        uint256 _startTime,
        uint256 _entryPeriod,
        uint256 _minPlayers,
        uint256 _maxPlayers,
        uint256 _playPeriod,
        uint256 _finalPeriod,
        uint256 _entryAmount,
        uint256 _adminFeeRate,
        uint256 _roundFeeRate
    ) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "Round: can't start at prior time"
        );
        require(_entryAmount > 0, "Round: entryAmount is 0");
        require(_maxPlayers > 0, "Round: max players is 0");

        roundId++;

        rounds[roundId] = Round({
            startTime: _startTime,
            entryPeriod: _entryPeriod,
            minPlayers: _minPlayers,
            maxPlayers: _maxPlayers,
            playPeriod: _playPeriod,
            finalPeriod: _finalPeriod,
            entryAmount: _entryAmount,
            adminFeeRate: _adminFeeRate,
            roundFeeRate: _roundFeeRate,
            distributed: false,
            locked: false
        });
        uint256[] memory _rewardRates = new uint256[](4);
        _rewardRates[0] = 50;
        _rewardRates[1] = 25;
        _rewardRates[2] = 15;
        _rewardRates[3] = 10;
        setRewardRates(roundId, _rewardRates);
        emit CreateRound(roundId);
    }

    // define admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @dev throws if the caller is not default admin and not admin role
    modifier onlyOwner() {
        address account = msg.sender;
        require(
            hasRole(DEFAULT_ADMIN_ROLE, account) ||
                hasRole(ADMIN_ROLE, account),
            "Not admin"
        );
        _;
    }

    /// @dev throws if current is not setup period for the reward system configuration
    modifier setupPeriod(uint256 _roundId) {
        Round memory round = rounds[_roundId];
        require(
            block.timestamp < round.startTime + round.entryPeriod,
            "GamePlayV2: not setup period"
        );
        _;
    }
    /// @dev throws if current is not entry period for player deposit
    modifier entryPeriod(uint256 _roundId) {
        Round memory round = rounds[_roundId];
        require(
            round.startTime <= block.timestamp &&
                block.timestamp < round.startTime + round.entryPeriod,
            "GamePlayV2: not entry period"
        );
        _;
    }

    /// @dev throws if current is not active period
    modifier activePeriod(uint256 _roundId) {
        Round memory round = rounds[_roundId];
        require(
            round.startTime <= block.timestamp &&
                block.timestamp <
                round.startTime + round.entryPeriod + round.playPeriod,
            "GamePlayV2: not active period"
        );
        _;
    }

    /// @dev throws if current is not finalizing period
    modifier finalPeriod(uint256 _roundId) {
        Round memory round = rounds[_roundId];
        require(
            round.startTime + round.entryPeriod + round.playPeriod <=
                block.timestamp &&
                block.timestamp <
                round.startTime +
                    round.entryPeriod +
                    round.playPeriod +
                    round.finalPeriod,
            "GamePlayV2: not final period"
        );
        _;
    }

    /// @dev throws if the game is locked(=true)
    modifier notLocked(uint256 _roundId) {
        require(!rounds[_roundId].locked, "GamePlay2: round locked");
        _;
    }

    /// @notice Enter the round with token payment as a player
    /// @dev Not working on finialzing period or locked
    /// @param _roundId round id
    /// @param _amount amount for entry
    function enter(uint256 _roundId, uint256 _amount)
        external
        nonReentrant
        notLocked(_roundId)
        activePeriod(_roundId)
    {
        Round memory thisRound = rounds[_roundId];
        require(
            _amount >= thisRound.entryAmount,
            "GamePlayV2: insufficient deposit amount"
        );

        roundPlayers[_roundId].push(address(msg.sender));
        PlayerInfo storage player = roundPlayerInfo[_roundId][msg.sender];
        player.amount += _amount;

        enteredToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        enteredTokenSupplyMap[_roundId] += _amount;

        emit Enter(address(msg.sender), _amount, _roundId);
    }

    /// @notice Claim reward tokens as player
    /// @dev Works only in final period and unlocked status
    /// @param _roundId round id to be claimed (in rewardToken)
    function claim(uint256 _roundId)
        external
        nonReentrant
        notLocked(_roundId)
        finalPeriod(_roundId)
    {
        PlayerInfo storage player = roundPlayerInfo[_roundId][msg.sender];
        Round memory round = rounds[_roundId];

        uint256 rewards = player.rewards;
        bool claimed = player.claimed;

        require(round.distributed, "Round: not distributed yet");
        require(!claimed, "Round: player already claimed");
        require(rewards > 0, "no rewards");

        rewaredTokenSupplyMap[_roundId] += rewards;
        player.claimed = true;

        rewardToken.safeTransfer(address(msg.sender), rewards);

        emit Claim(msg.sender, rewards, _roundId);
    }

    /// @notice Withdraw entered tokens in the round as a player, without caring about rewards
    /// @dev Available only in the entry period with unlocked status.
    /// @param _roundId round id
    function emergencyWithdraw(uint256 _roundId)
        external
        notLocked(_roundId)
        nonReentrant
        entryPeriod(_roundId)
    {
        PlayerInfo storage player = roundPlayerInfo[_roundId][msg.sender];
        uint256 amountToTransfer = player.amount;
        player.amount = 0;

        enteredToken.safeTransfer(address(msg.sender), amountToTransfer);
        enteredTokenSupplyMap[_roundId] -= amountToTransfer;

        emit EmergencyWithdraw(_roundId, msg.sender, amountToTransfer);
    }

    /// @notice Emergency claim for rewards in the round as an admin
    /// @dev Works at any time as long as not locked and not claimed
    /// @param _roundId round id
    /// @param _player player's address
    /// @param _ranking ranking core
    function emergencyClaim(
        uint256 _roundId,
        address _player,
        uint256 _ranking
    ) external nonReentrant notLocked(_roundId) onlyOwner {
        _updateRankingRewards(_roundId, _player, _ranking);
        PlayerInfo storage player = roundPlayerInfo[_roundId][_player];
        bool claimed = player.claimed;
        require(!claimed, "Round: player already claimed");

        player.claimed = true;
        uint256 rewards = player.rewards;
        rewaredTokenSupplyMap[_roundId] += rewards;

        rewardToken.safeTransfer(_player, rewards);

        emit EmergencyClaim(_roundId, _player, _ranking);
    }

    /// @notice Withdraw system income to treasury
    /// @dev Withdrawal can be only done at once during the final period. the rate will be zero, once it is done
    /// Available only in the final period
    /// @param _roundId round id
    function withdrawToTreasury(uint256 _roundId)
        external
        finalPeriod(_roundId)
        nonReentrant
    {
        Round storage round = rounds[_roundId];
        require(round.adminFeeRate != 0, "admin rate is zero");
        uint256 totalIncome = enteredTokenSupplyMap[_roundId];
        uint256 adminIncome = (totalIncome * round.adminFeeRate) / 100;

        round.adminFeeRate = 0;
        enteredToken.safeTransfer(treasury, adminIncome);

        emit WithdrawToTreasury(_roundId, adminIncome);
    }

    /// @notice Withdraws the income share to game service treasury
    /// @dev Withdrawal can be only done at once during the final period. the rate will be zero, once it is done.
    /// Available only in the final period
    /// @param _roundId round id
    function withdrawToGameService(uint256 _roundId)
        external
        finalPeriod(_roundId)
        nonReentrant
    {
        Round storage round = rounds[_roundId];
        require(round.roundFeeRate != 0, "game service rate is zero");
        uint256 totalIncome = enteredTokenSupplyMap[_roundId];
        uint256 gameIncome = (totalIncome * round.roundFeeRate) / 100;

        round.roundFeeRate = 0;
        enteredToken.safeTransfer(gameInfo.walletAddress, gameIncome);
        emit WithdrawToGameService(_roundId, gameIncome);
    }

    /// @notice Getter remaining rewards
    /// @dev actual token amount is returned after deducting admin fee and game service fee
    /// @param _roundId round id
    /// @return remaining rewards for winners
    function remainingRewards(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return _remainingRewards(_roundId);
    }

    /// @notice Internal function to calculate remaining rewards
    /// @dev Deduct admin fee, round fee and rewared amount from totalIncome
    /// @param _roundId round id
    /// @return Remaining rewards for winners
    function _remainingRewards(uint256 _roundId)
        internal
        view
        returns (uint256)
    {
        Round memory round = rounds[_roundId];
        uint256 totalIncome = enteredTokenSupplyMap[_roundId];
        uint256 rewardedAmount = rewaredTokenSupplyMap[_roundId];
        uint256 adminRewardFee = (totalIncome * round.adminFeeRate) / 100;
        uint256 roundRewardFee = (totalIncome * round.roundFeeRate) / 100;
        return totalIncome - rewardedAmount - adminRewardFee - roundRewardFee;
    }

    /// @notice Distribute rewards in the round
    /// @dev the length of players should be same as one of rankings, it can be called by only owner.
    /// Able to do as long as not distributed.
    /// @param _roundId round id
    function distributeRewards(uint256 _roundId) external onlyOwner {
        require(
            !rounds[_roundId].distributed,
            "distribute: already distributed"
        );
        rounds[_roundId].distributed = true;
        emit DistributeRewards(_roundId);
    }

    /// @notice Update player's ranking and re-calculate the rewards
    /// @param _roundId round id
    /// @param _player player addresses
    /// @param _ranking player rankings
    function updateRankingRewards(
        uint256 _roundId,
        address _player,
        uint256 _ranking
    ) external onlyOwner {
        Round memory round = rounds[_roundId];
        require(round.startTime <= block.timestamp, "Round not started");
        _updateRankingRewards(_roundId, _player, _ranking);
    }

    /// @dev able to do only after the round is started.
    /// @param _roundId round id
    /// @param _players list of player addresses
    /// @param _ranks list of palyer player rankings
    function updateRankingRewardsBatch(uint256 _roundId, address[] calldata _players, uint256[] calldata _ranks) 
        external onlyOwner {
        Round memory round = rounds[_roundId];
        require(_players.length == _ranks.length, "not same length");
        require(!round.distributed, "distribute: already distributed");
        require(round.startTime <= block.timestamp, "Round not started");
        for(uint256 i = 0; i < _players.length; i++) {
            _updateRankingRewards(_roundId, _players[i], _ranks[i]);
        }
    }
    
    /// @notice Internal function to update player's ranking and the rewards
    /// @param _roundId round id
    /// @param _player player addresses
    /// @param _ranking player rankings
    function _updateRankingRewards(
        uint256 _roundId,
        address _player,
        uint256 _ranking
    ) internal {
        require(_ranking > 0, "ranking is zero");
        if(_isPlayerEntered(_roundId, _player)) {
            uint256 oldRanking = roundPlayerInfo[_roundId][_player].ranking;
            if (oldRanking != _ranking) {
                roundPlayerInfo[_roundId][_player].ranking = _ranking;
                numberOfRankingMap[_roundId][_ranking - 1]++;

                if (oldRanking != 0) {
                    numberOfRankingMap[_roundId][oldRanking - 1]--;
                }
                roundPlayerInfo[_roundId][_player].rewards = _calcRankingRewards(
                    _roundId,
                    _ranking
                );
            }
            emit UpdateRankingRewards(_roundId, _player, _ranking);
        }
    }

    /// @notice Internal function to check if the player already entered or not
    /// @dev Checking the amount of player's deposit
    /// @param _roundId round id
    /// @param _player player address
    /// @return true if valid player, else false 
    function _isPlayerEntered(uint256 _roundId, address _player)
        internal
        view
        returns (bool)
    {
        return roundPlayerInfo[_roundId][_player].amount > 0 ? true : false;
    }

    function isPlayerEntered(uint256 _roundId, address _player)
        external
        view
        returns (bool)
    {
        return _isPlayerEntered(_roundId, _player);
    }

    /// @notice Update player's score as an admin
    /// @dev Use internal update function, activated in the active period
    /// @param _roundId round id
    /// @param _player player address
    /// @param _score score update
    function updateScore(
        uint256 _roundId,
        address _player,
        uint256 _score
    ) external onlyOwner activePeriod(_roundId) {
        _updateScore(_roundId, _player, _score);
        emit UpdateScore(_roundId, _player, _score);
    }

    /// @notice Internal function to update player's score
    /// @dev Change the player score
    /// @param _roundId: round id
    /// @param _player: player address
    /// @param _score: score update

    function _updateScore(
        uint256 _roundId,
        address _player,
        uint256 _score
    ) internal {
        unchecked {
            roundPlayerInfo[_roundId][_player].score = _score;
        }
    }

    /// @notice Update the round specified by id as an admin
    /// @dev Don't update locked field, available only in the setup period,
    /// Only can be updated before the round is started
    /// @param _roundId round id
    /// @param _startTime starting time of the round in seconds based on UTC
    /// @param _minPlayers minimum number of players required
    /// @param _maxPlayers maximum number of players required
    /// @param _entryPeriod the period time of entering the round in seconds with the entry fee specified below
    /// @param _playPeriod the period time that a user can play the game in the round
    /// @param _finalPeriod the period time of being reviewed and evaluated by the platform
    /// @param _entryAmount entry fee for the round
    /// @param _adminFeeRate admin's fee percentage between 0 - 99
    /// @param _roundFeeRate game company's fee percentage between 0 - 99 to be sent to game company's treasury
    function updateRound(
        uint256 _roundId,
        uint256 _startTime,
        uint256 _minPlayers,
        uint256 _maxPlayers,
        uint256 _entryPeriod,
        uint256 _playPeriod,
        uint256 _finalPeriod,
        uint256 _entryAmount,
        uint256 _adminFeeRate,
        uint256 _roundFeeRate
    ) external onlyOwner setupPeriod(_roundId) {
        Round storage round = rounds[_roundId];
        require(block.timestamp < _startTime, "Invaild start time");
        require(block.timestamp < round.startTime, "Round has started");

        round.startTime = _startTime;
        round.minPlayers = _minPlayers;
        round.maxPlayers = _maxPlayers;
        round.entryPeriod = _entryPeriod;
        round.playPeriod = _playPeriod;
        round.finalPeriod = _finalPeriod;
        round.entryAmount = _entryAmount;
        round.adminFeeRate = _adminFeeRate;
        round.roundFeeRate = _roundFeeRate;

        emit UpdateRound(
            _roundId,
            _startTime,
            _minPlayers,
            _maxPlayers,
            _entryPeriod,
            _playPeriod,
            _finalPeriod,
            _entryAmount,
            _adminFeeRate,
            _roundFeeRate
        );
    }

    function updateStartTime(uint256 _roundId, uint256 _startTime) external onlyOwner setupPeriod(_roundId) {
        Round storage round = rounds[_roundId];
        require(block.timestamp < _startTime, "Invaild start time");
        round.startTime = _startTime;
    }

    function updateEntryFee(uint256 _roundId, uint256 _amount) external onlyOwner setupPeriod(_roundId) {
        require(_amount > 0, "Invalid entry amount");
        Round storage round = rounds[_roundId];
        round.entryAmount = _amount;
    }

    /// @notice Switch the round to locked/unclocked as an admin
    /// @param _roundId round id
    function toogleLockRound(uint256 _roundId) external onlyOwner {
        Round storage round = rounds[_roundId];
        round.locked = !round.locked;
        emit ToggleLockedRound(_roundId);
    }
    
    function getRoundLocked(uint256 _roundId) external view returns (bool) {
        return rounds[_roundId].locked;
    }

    function getRoundDistributed(uint256 _roundId) external view returns (bool) {
        return rounds[_roundId].distributed;
    }

    /// @notice View function to see pending reward on frontend.
    /// @dev Zero, if the user already claimed
    /// @param _roundId round id
    /// @param _player player address
    /// @return Pending reward for a given player
    function pendingRewards(uint256 _roundId, address _player)
        external
        view
        returns (uint256)
    {
        PlayerInfo storage player = roundPlayerInfo[_roundId][_player];
        if (player.claimed) {
            return 0;
        }

        uint256 rewards = _calcPlayerRewards(_roundId, _player);
        return rewards;
    }

    /// @notice Internal function to calculate rewards according to the ranking
    /// @dev Load array state variables on memory to save gas
    /// @param _roundId round id
    /// @param _ranking player ranking
    /// @return rewards for ranking
    function _calcRankingRewards(uint256 _roundId, uint256 _ranking)
        internal
        view
        returns (uint256)
    {
        if (_ranking == 0) return 0;
        uint256 totalRewardRate;
        uint256[] memory rewwardRates = rewardRatesMap[_roundId];
        uint256[] memory numberOfRanking = numberOfRankingMap[_roundId];
        for (uint256 rank = 0; rank < rewwardRates.length; rank++) {
            totalRewardRate += numberOfRanking[rank] * rewwardRates[rank];
        }
        return
            totalRewardRate > 0
                ? (rewwardRates[_ranking - 1] * _remainingRewards(_roundId)) /
                    totalRewardRate
                : 0;
    }

    /// @notice Internal function to calculate player rewards
    /// @dev Use _calcRankingRewards internally
    /// @param _roundId round id
    /// @param _player player address
    /// @return rewards for player
    function _calcPlayerRewards(uint256 _roundId, address _player)
        internal
        view
        returns (uint256)
    {
        PlayerInfo storage player = roundPlayerInfo[_roundId][_player];
        return _calcRankingRewards(_roundId, player.ranking);
    }

    /// @notice Set up rewards rate according to rankings as an admin.
    /// @dev Reward rates are entered as an array
    /// @param _roundId round id
    /// @param _rewardRates array of reward rates
    function setRewardRates(uint256 _roundId, uint256[] memory _rewardRates)
        public
        onlyOwner
        setupPeriod(_roundId)
    {
        require(_rewardRates.length > 0, "Round: reward rate list is empty");
        numberOfRankingMap[_roundId] = new uint256[](_rewardRates.length);
        rewardRatesMap[_roundId] = _rewardRates;
        emit SetRewardRates(_roundId, _rewardRates);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author The PlayEstates Developer Team
/// @title Storage contract to manage state variables and events
/// @notice Use this only for the game engine contract - GamePlayV2.
/// @dev An abstract contract which provides structs, state variables and events

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract GamePlayV2Storage is
    AccessControl,
    ReentrancyGuard,
    Initializable
{
    // entry token supply in the round
    mapping(uint256 => uint256) public enteredTokenSupplyMap;

    // reward token supply in the round
    mapping(uint256 => uint256) public rewaredTokenSupplyMap;

    // address of game engine factory
    address public GAME_ENGINE_FACTORY;

    // precision factor
    uint256 public PRECISION_FACTOR;

    //public round id
    uint256 public roundId;

    // reward token
    IERC20 public rewardToken;

    // entered token
    IERC20 public enteredToken;

    // address of the platform treasury
    address public treasury;

    // game info
    GameInfo public gameInfo;

    // round info corresponding to round id
    mapping(uint256 => Round) public rounds;

    // player info to the player address in the round
    mapping(uint256 => mapping(address => PlayerInfo)) public roundPlayerInfo;

    // player address list in the round
    mapping(uint256 => address[]) public roundPlayers;

    // reward rate list in the round. Index 0 means rank 1
    mapping(uint256 => uint256[]) public rewardRatesMap;

    // number of ranked players in the round. Index 0 means rank 1
    mapping(uint256 => uint256[]) public numberOfRankingMap;

    // Player Information Struct
    struct PlayerInfo {
        uint256 amount; // How many entered tokens the player has provided
        uint256 ranking; // Ranking of score
        uint256 score; // score earned from game round
        uint256 rewards; // Rewards
        bool claimed; // is claimed ?
    }

    // Game Information Structure
    struct GameInfo {
        address walletAddress;
        string gameName;
        string gameCompany;
        uint256 gameMode;
    }

    // Round Information Struct
    struct Round {
        uint256 startTime;
        uint256 entryPeriod;
        uint256 minPlayers;
        uint256 maxPlayers;
        uint256 playPeriod;
        uint256 finalPeriod;
        uint256 entryAmount;
        uint256 adminFeeRate;
        uint256 roundFeeRate;
        bool distributed;
        bool locked;
    }

    /// @dev emitted when a round is created
    event CreateRound(uint256 indexed roundId);

    /// @dev emitted when owner recovers the old tokens.
    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);

    /// @dev emitted when a player deposits entry amount of token
    event Enter(address indexed player, uint256 amount, uint256 round);

    /// @dev emitted when a player withdraws his deposit
    event EmergencyWithdraw(
        uint256 round,
        address indexed player,
        uint256 amount
    );

    /// @dev emitted when player's rewards are claimed by the admin in emergency
    event EmergencyClaim(
        uint256 indexed roundId,
        address indexed player,
        uint256 ranking
    );

    /// @dev emitted when a player claims the rewards
    event Claim(address indexed player, uint256 amount, uint256 round);

    /// @dev emitted when the owner updates the round
    event UpdateRound(
        uint256 indexed roundId,
        uint256 startTime,
        uint256 minPlayers,
        uint256 maxPlayers,
        uint256 entryPeriod,
        uint256 playPeriod,
        uint256 finalPeriod,
        uint256 entryAmount,
        uint256 adminFeeRate,
        uint256 roundFeeRate
    );

    /// @dev emitted when the owner call the function
    event DistributeRewards(uint256 indexed roundId);

    /// @dev emitted when the owner locks the round
    event ToggleLockedRound(uint256 indexed roundId);

    /// @dev emitted when the owner updates a player score
    event UpdateScore(uint256 indexed roundId, address indexed player, uint256 score);

    /// @dev emitted when the owner update a player ranking
    event UpdateRankingRewards(
        uint256 indexed roundId,
        address indexed player,
        uint256 score
    );

    /// @dev emitted when the withdrawal to system treasury occurs successfully
    event WithdrawToTreasury(uint256 indexed roundId, uint256 amount);

    /// @dev emitted when the withdrawal to game service treasury occurs successfully
    event WithdrawToGameService(uint256 indexed roundId, uint256 amount);

    /// @dev emitted when setting reward rates is triggered
    event SetRewardRates(uint256 indexed roundId, uint256[] rewardRates);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}