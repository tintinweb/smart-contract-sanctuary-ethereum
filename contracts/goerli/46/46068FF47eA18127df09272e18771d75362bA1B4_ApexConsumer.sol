// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";

/// @title Consumer contract which stores all data from CL data feed (Link to docs:https://market.link/nodes/Apex146/integrations), also creates all sports markets based on that data
/// @author vladan
contract ApexConsumer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */

    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;

    uint public constant STATUS_CANCELLED = 0;
    uint public constant STATUS_RESOLVED = 1;

    uint public constant NUMBER_OF_POSITIONS = 2;
    uint public constant MIN_TAG_NUMBER = 9100;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct RaceCreate {
        string raceId;
        uint256 qualifyingStartTime;
        uint256 startTime;
        string eventId;
        string eventName;
        string betType;
    }

    struct GameCreate {
        bytes32 gameId;
        string raceId;
        uint256 startTime;
        uint256 homeOdds;
        uint256 awayOdds;
        uint256 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    }

    struct GameResults {
        bytes32 gameId;
        string result;
        string resultDetails;
    }

    struct GameOdds {
        bytes32 gameId;
        uint256 homeOdds;
        uint256 awayOdds;
        uint256 drawOdds;
    }

    /* ========== STATE VARIABLES ========== */

    // global params
    address public wrapperAddress;
    mapping(address => bool) public whitelistedAddresses;

    // Maps <GameId, Game>
    mapping(string => RaceCreate) public raceCreated;
    mapping(bytes32 => GameCreate) public gameCreated;
    mapping(bytes32 => GameResolve) public gameResolved;
    mapping(bytes32 => GameResults) public gameResults;
    mapping(bytes32 => GameOdds) public gameOdds;
    mapping(bytes32 => uint) public sportsIdPerGame;
    mapping(string => bool) public raceFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledResolved;
    mapping(string => string) public latestRaceIdPerSport;

    // sports props
    mapping(string => bool) public supportedSport;
    mapping(string => uint) public supportedSportId;

    // market props
    ISportPositionalMarketManager public sportsManager;
    mapping(bytes32 => address) public marketPerGameId;
    mapping(address => bytes32) public gameIdPerMarket;
    mapping(address => bool) public marketCreated;
    mapping(address => bool) public marketResolved;
    mapping(address => bool) public marketCanceled;

    // game
    mapping(address => bool) public invalidOdds;
    mapping(address => bool) public isPausedByCanceledStatus;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        string[] memory _supportedSports,
        address _sportsManager
    ) external initializer {
        setOwner(_owner);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        whitelistedAddresses[_owner] = true;
        for (uint i; i < _supportedSports.length; i++) {
            supportedSport[_supportedSports[i]] = true;
            supportedSportId[_supportedSports[i]] = i;
        }
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    /// @notice Fulfill all race metadata necessary to create sport markets
    /// @param _requestId unique request ID form CL
    /// @param _eventId event ID which is provided from CL
    /// @param _betType bet type for provided event ID
    /// @param _eventName event name which is provided from CL
    /// @param _qualifyingStartTime timestamp on which race qualifying is started
    /// @param _raceStartTime timestamp on which race is started
    /// @param _sport supported sport name which is provided from CL
    function fulfillMetaData(
        bytes32 _requestId,
        string memory _eventId,
        string memory _betType,
        string memory _eventName,
        uint256 _qualifyingStartTime,
        uint256 _raceStartTime,
        string memory _sport
    ) external onlyWrapper {
        //if (_qualifying_start_time > block.timestamp) {
        RaceCreate memory race;

        race.raceId = _eventId;
        race.eventId = _eventId;
        race.eventName = _eventName;
        race.betType = _betType;
        race.qualifyingStartTime = _qualifyingStartTime;
        race.startTime = _raceStartTime;

        latestRaceIdPerSport[_sport] = race.raceId;

        _createRaceFulfill(_requestId, race, supportedSportId[_sport]);
        //}
    }

    /// @notice Fulfill all matchup data necessary to create sport markets
    /// @param _requestId unique request ID form CL
    /// @param _betTypeDetail1 Team/Category/Rider A identifier, returned as string
    /// @param _betTypeDetail2 Team/Category/Rider B identifier, returned as string
    /// @param _probA: Probability for Team/Category/Rider A, returned as uint256
    /// @param _probB: Probability for Team/Category/Rider B, returned as uint256
    /// @param _gameId unique game identifier
    /// @param _sport supported sport name which is provided from CL
    function fulfillMatchup(
        bytes32 _requestId,
        string memory _betTypeDetail1,
        string memory _betTypeDetail2,
        uint256 _probA,
        uint256 _probB,
        bytes32 _gameId,
        string memory _sport,
        string memory _eventId
    ) external onlyWrapper {
        if (!gameFulfilledCreated[_gameId] && raceFulfilledCreated[_eventId]) {
            RaceCreate memory race = raceCreated[_eventId];

            //if (race.qualifyingStartTime > block.timestamp) {
            GameCreate memory game;

            game.gameId = _gameId;
            game.homeOdds = _probA;
            game.awayOdds = _probB;
            game.homeTeam = _betTypeDetail1;
            game.awayTeam = _betTypeDetail2;
            game.raceId = _eventId;
            game.startTime = race.qualifyingStartTime;

            _createGameFulfill(_requestId, game, supportedSportId[_sport]);
            //}
        }

        GameOdds memory newGameOdds;
        newGameOdds.gameId = _gameId;
        newGameOdds.homeOdds = _probA;
        newGameOdds.awayOdds = _probB;

        _oddsGameFulfill(_requestId, newGameOdds);
    }

    /// @notice Fulfill all data necessary to resolve sport markets
    /// @param _requestId unique request ID form CL
    /// @param _result win/loss for the matchup
    /// @param _resultDetails ranking/timing data to elaborate on win/loss
    /// @param _gameId unique game identifier
    /// @param _sport supported sport name which is provided from CL
    function fulfillResults(
        bytes32 _requestId,
        string memory _result,
        string memory _resultDetails,
        bytes32 _gameId,
        string memory _sport
    ) external onlyWrapper {
        GameResolve memory game;
        if (keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("win/lose"))) {
            game.gameId = _gameId;
            game.homeScore = 1;
            game.awayScore = 0;
            game.statusId = uint8(STATUS_RESOLVED);
            _resolveGameFulfill(_requestId, game, supportedSportId[_sport]);
        } else if (keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("lose/win"))) {
            game.gameId = _gameId;
            game.homeScore = 0;
            game.awayScore = 1;
            game.statusId = uint8(STATUS_RESOLVED);
            _resolveGameFulfill(_requestId, game, supportedSportId[_sport]);
        } else if (keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("null"))) {
            game.gameId = _gameId;
            game.homeScore = 0;
            game.awayScore = 0;
            game.statusId = uint8(STATUS_CANCELLED);
            _resolveGameFulfill(_requestId, game, supportedSportId[_sport]);
        }

        GameResults memory newGameResults;
        newGameResults.gameId = _gameId;
        newGameResults.result = _result;
        newGameResults.resultDetails = _resultDetails;

        _gameResultsFulfill(_requestId, newGameResults, supportedSportId[_sport]);
    }

    /// @notice Creates market for a given game ID
    /// @param _gameId unique game identifier
    function createMarketForGame(bytes32 _gameId) public isAddressWhitelisted {
        require(marketPerGameId[_gameId] == address(0), "Market for game already exists");
        require(gameFulfilledCreated[_gameId], "No such game fulfilled, created");
        _createMarket(_gameId);
    }

    /// @notice Resolve market for a given game ID
    /// @param _gameId unique game identifier
    function resolveMarketForGame(bytes32 _gameId) public isAddressWhitelisted {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(gameFulfilledResolved[_gameId], "No such game fulfilled, resolved");
        _resolveMarket(_gameId);
    }

    /// @notice Resolve market for a given game ID
    /// @param _gameId unique game identifier
    /// @param _outcome outcome of the game (1: home win, 2: away win, 0: cancel market)
    /// @param _homeScore score of home team
    /// @param _awayScore score of away team
    function resolveGameManually(
        bytes32 _gameId,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external isAddressWhitelisted canGameBeResolved(_gameId, _outcome, _homeScore, _awayScore) {
        _resolveMarketManually(marketPerGameId[_gameId], _outcome, _homeScore, _awayScore);
    }

    /// @notice Resolve market for a given market address
    /// @param _market market address
    /// @param _outcome outcome of a game (1: home win, 2: away win, 0: cancel market)
    /// @param _homeScore score of home team
    /// @param _awayScore score of away team
    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external isAddressWhitelisted canGameBeResolved(gameIdPerMarket[_market], _outcome, _homeScore, _awayScore) {
        _resolveMarketManually(_market, _outcome, _homeScore, _awayScore);
    }

    /// @notice Cancel market for a given market address
    /// @param _market market address
    function cancelMarketManually(address _market)
        external
        isAddressWhitelisted
        canGameBeCanceled(gameIdPerMarket[_market])
    {
        _cancelMarketManually(_market);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice View function which returns odds
    /// @param _gameId unique game identifier
    /// @return homeOdds moneyline odd in a two decimal places
    /// @return awayOdds moneyline odd in a two decimal places
    /// @return drawOdds moneyline odd in a two decimal places
    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (gameOdds[_gameId].homeOdds, gameOdds[_gameId].awayOdds, gameOdds[_gameId].drawOdds);
    }

    /// @notice View function which returns game created object based on ID of a game
    /// @param _gameId unique game identifier
    /// @return GameCreate game create object
    function getGameCreatedById(bytes32 _gameId) public view returns (GameCreate memory) {
        return gameCreated[_gameId];
    }

    /// @notice View function which returns game resolved object based on ID of a game
    /// @param _gameId unique game identifier
    /// @return GameResolve game resolve object
    function getGameResolvedById(bytes32 _gameId) public view returns (GameResolve memory) {
        return gameResolved[_gameId];
    }

    /// @notice View function which returns if game is resolved or canceled and ready for market to be resolved or canceled
    /// @param _gameId unique game identifier for which game is looking
    /// @return bool is it ready for resolve or cancel true/false
    function isGameResolvedOrCanceled(bytes32 _gameId) public view returns (bool) {
        return marketResolved[marketPerGameId[_gameId]] || marketCanceled[marketPerGameId[_gameId]];
    }

    /// @notice View function which returns if sport is supported or not
    /// @param _sport sport for which is looking
    /// @return bool is sport supported true/false
    function isSupportedSport(string memory _sport) external view returns (bool) {
        return supportedSport[_sport];
    }

    /// @notice View function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _gameId unique game identifier for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOdds(bytes32 _gameId) public view returns (uint[] memory) {
        uint[] memory normalizedOdds = new uint[](3);
        normalizedOdds[0] = gameOdds[_gameId].homeOdds;
        normalizedOdds[1] = gameOdds[_gameId].awayOdds;
        normalizedOdds[2] = gameOdds[_gameId].drawOdds;

        for (uint i = 0; i < normalizedOdds.length; i++) {
            normalizedOdds[i] = (1e18 * normalizedOdds[i]) / 1e4;
        }
        return normalizedOdds;
    }

    /// @notice Vew function which returns if game is resolved
    /// @param _gameId unique game identifier for which game is looking
    /// @return bool is game resolved true/false
    function isGameInResolvedStatus(bytes32 _gameId) public view returns (bool) {
        return _isGameStatusResolved(getGameResolvedById(_gameId));
    }

    /// @notice View function which returns outcome of a game based on ID
    /// @param _gameId unique game identifier for which result is looking
    /// @return _result returns 1: home win, 2: away win
    function getResult(bytes32 _gameId) external view returns (uint _result) {
        if (isGameInResolvedStatus(_gameId)) {
            return _calculateOutcome(getGameResolvedById(_gameId));
        }
    }

    /// @notice View function which returns if game is provided by Apex
    /// @param _gameId unique game identifier for which result is looking
    /// @return bool is game provided by Apex
    function isApexGame(bytes32 _gameId) public view returns (bool) {
        return gameFulfilledCreated[_gameId];
    }

    /* ========== INTERNALS ========== */

    function _createRaceFulfill(
        bytes32 _requestId,
        RaceCreate memory _race,
        uint _sportId
    ) internal {
        raceCreated[_race.raceId] = _race;
        raceFulfilledCreated[_race.raceId] = true;

        emit RaceCreated(_requestId, _sportId, _race.raceId, _race);
    }

    function _createGameFulfill(
        bytes32 _requestId,
        GameCreate memory _game,
        uint _sportId
    ) internal {
        gameCreated[_game.gameId] = _game;
        sportsIdPerGame[_game.gameId] = _sportId;
        gameFulfilledCreated[_game.gameId] = true;
        gameOdds[_game.gameId] = GameOdds(_game.gameId, _game.homeOdds, _game.awayOdds, _game.drawOdds);

        emit GameCreated(_requestId, _sportId, _game.gameId, _game, getNormalizedOdds(_game.gameId));
    }

    function _resolveGameFulfill(
        bytes32 _requestId,
        GameResolve memory _game,
        uint _sportId
    ) internal {
        GameCreate memory singleGameCreated = getGameCreatedById(_game.gameId);

        // if status is resolved OR (status is canceled AND start time has passed fulfill game to be resolved)
        if (
            _isGameStatusResolved(_game) || (_isGameStatusCancelled(_game) && singleGameCreated.startTime < block.timestamp)
        ) {
            gameResolved[_game.gameId] = _game;
            gameFulfilledResolved[_game.gameId] = true;

            emit GameResolved(_requestId, _sportId, _game.gameId, _game);
        }
        // if market for the game exists AND status is canceled AND start time has not passed only pause market
        else if (
            marketPerGameId[_game.gameId] != address(0) &&
            _isGameStatusCancelled(_game) &&
            singleGameCreated.startTime >= block.timestamp
        ) {
            isPausedByCanceledStatus[marketPerGameId[_game.gameId]] = true;
            _pauseOrUnpauseMarket(marketPerGameId[_game.gameId], true);
        }
    }

    function _gameResultsFulfill(
        bytes32 _requestId,
        GameResults memory _game,
        uint _sportId
    ) internal {
        gameResults[_game.gameId] = _game;

        emit GameResultsSet(_requestId, _sportId, _game.gameId, _game);
    }

    function _oddsGameFulfill(bytes32 requestId, GameOdds memory _game) internal {
        // if odds are valid store them if not pause market
        if (_areOddsValid(_game)) {
            gameOdds[_game.gameId] = _game;

            // if market created and was paused (paused by invalid odds or paused by canceled status) unpause
            if (marketPerGameId[_game.gameId] != address(0) && sportsManager.isMarketPaused(marketPerGameId[_game.gameId])) {
                if (invalidOdds[marketPerGameId[_game.gameId]] || isPausedByCanceledStatus[marketPerGameId[_game.gameId]]) {
                    invalidOdds[marketPerGameId[_game.gameId]] = false;
                    isPausedByCanceledStatus[marketPerGameId[_game.gameId]] = false;
                    _pauseOrUnpauseMarket(marketPerGameId[_game.gameId], false);
                }
            }

            emit GameOddsAdded(requestId, _game.gameId, _game, getNormalizedOdds(_game.gameId));
        } else {
            if (
                marketPerGameId[_game.gameId] != address(0) && !sportsManager.isMarketPaused(marketPerGameId[_game.gameId])
            ) {
                invalidOdds[marketPerGameId[_game.gameId]] = true;
                _pauseOrUnpauseMarket(marketPerGameId[_game.gameId], true);
            }

            emit InvalidOddsForMarket(requestId, marketPerGameId[_game.gameId], _game.gameId, _game);
        }
    }

    function _createMarket(bytes32 _gameId) internal {
        GameCreate memory game = getGameCreatedById(_gameId);
        uint sportId = sportsIdPerGame[_gameId];
        uint[] memory tags = _calculateTags(sportId);

        // create
        sportsManager.createMarket(
            _gameId,
            _append(game.homeTeam, game.awayTeam), // gameLabel
            block.timestamp + 600,
            //game.startTime, //maturity
            0, //initialMint
            NUMBER_OF_POSITIONS,
            tags //tags
        );

        address marketAddress = sportsManager.getActiveMarketAddress(sportsManager.numActiveMarkets() - 1);
        marketPerGameId[game.gameId] = marketAddress;
        gameIdPerMarket[marketAddress] = game.gameId;
        marketCreated[marketAddress] = true;

        emit CreateSportsMarket(marketAddress, game.gameId, game, tags, getNormalizedOdds(game.gameId));
    }

    function _resolveMarket(bytes32 _gameId) internal {
        GameResolve memory game = getGameResolvedById(_gameId);
        GameCreate memory singleGameCreated = getGameCreatedById(_gameId);

        if (_isGameStatusResolved(game)) {
            if (invalidOdds[marketPerGameId[game.gameId]]) {
                _pauseOrUnpauseMarket(marketPerGameId[game.gameId], false);
            }

            uint _outcome = _calculateOutcome(game);

            sportsManager.resolveMarket(marketPerGameId[game.gameId], _outcome);
            marketResolved[marketPerGameId[game.gameId]] = true;

            emit ResolveSportsMarket(marketPerGameId[game.gameId], game.gameId, _outcome);
            // if status is canceled and start time of a game passed cancel market
        } else if (_isGameStatusCancelled(game) && singleGameCreated.startTime < block.timestamp) {
            _cancelMarket(game.gameId);
        }
    }

    function _resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) internal {
        _pauseOrUnpauseMarket(_market, false);
        sportsManager.resolveMarket(_market, _outcome);
        marketResolved[_market] = true;
        gameResolved[gameIdPerMarket[_market]] = GameResolve(
            gameIdPerMarket[_market],
            _homeScore,
            _awayScore,
            uint8(STATUS_RESOLVED)
        );

        emit GameResolved(
            gameIdPerMarket[_market],
            sportsIdPerGame[gameIdPerMarket[_market]],
            gameIdPerMarket[_market],
            gameResolved[gameIdPerMarket[_market]]
        );
        emit ResolveSportsMarket(_market, gameIdPerMarket[_market], _outcome);
    }

    function _cancelMarketManually(address _market) internal {
        _pauseOrUnpauseMarket(_market, false);
        sportsManager.resolveMarket(_market, 0);
        marketCanceled[_market] = true;

        emit CancelSportsMarket(_market, gameIdPerMarket[_market]);
    }

    function _pauseOrUnpauseMarket(address _market, bool _pause) internal {
        if (sportsManager.isMarketPaused(_market) != _pause) {
            sportsManager.setMarketPaused(_market, _pause);
            emit PauseSportsMarket(_market, _pause);
        }
    }

    function _cancelMarket(bytes32 _gameId) internal {
        sportsManager.resolveMarket(marketPerGameId[_gameId], 0);
        marketCanceled[marketPerGameId[_gameId]] = true;

        emit CancelSportsMarket(marketPerGameId[_gameId], _gameId);
    }

    function _append(string memory teamA, string memory teamB) internal pure returns (string memory) {
        return string(abi.encodePacked(teamA, " vs ", teamB));
    }

    function _calculateTags(uint _sportsId) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](1);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        return result;
    }

    function _isGameReadyToBeResolved(GameResolve memory _game) internal pure returns (bool) {
        return _isGameStatusResolved(_game) || _isGameStatusCancelled(_game);
    }

    function _isGameStatusResolved(GameResolve memory _game) internal pure returns (bool) {
        return _game.statusId == STATUS_RESOLVED;
    }

    function _isGameStatusCancelled(GameResolve memory _game) internal pure returns (bool) {
        return _game.statusId == STATUS_CANCELLED;
    }

    function _calculateOutcome(GameResolve memory _game) internal pure returns (uint) {
        return _game.homeScore > _game.awayScore ? HOME_WIN : AWAY_WIN;
    }

    function _areOddsValid(GameOdds memory _game) internal pure returns (bool) {
        return _game.awayOdds != 0 && _game.homeOdds != 0;
    }

    function _isValidOutcomeForGame(uint _outcome) internal pure returns (bool) {
        return _outcome == HOME_WIN || _outcome == AWAY_WIN || _outcome == CANCELLED;
    }

    function _isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) internal pure returns (bool) {
        if (_outcome == CANCELLED) {
            return _awayScore == CANCELLED && _homeScore == CANCELLED;
        } else if (_outcome == HOME_WIN) {
            return _homeScore > _awayScore;
        } else if (_outcome == AWAY_WIN) {
            return _homeScore < _awayScore;
        } else {
            return _homeScore == _awayScore;
        }
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice Sets if sport is suported or not (delete from supported sport)
    /// @param sport sport which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSport(string memory sport, bool _isSupported) external onlyOwner {
        require(supportedSport[sport] != _isSupported, "Already set");
        supportedSport[sport] = _isSupported;
        emit SupportedSportsChanged(sport, _isSupported);
    }

    /// @notice Sets wrapper and manager addresses
    /// @param _wrapperAddress wrapper address
    /// @param _sportsManager sport manager address
    function setSportContracts(address _wrapperAddress, address _sportsManager) external onlyOwner {
        require(_wrapperAddress != address(0) || _sportsManager != address(0), "Invalid addreses");

        sportsManager = ISportPositionalMarketManager(_sportsManager);
        wrapperAddress = _wrapperAddress;

        emit NewSportContracts(_wrapperAddress, _sportsManager);
    }

    /// @notice Adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted or removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0), "Invalid address");
        require(whitelistedAddresses[_whitelistAddress] != _flag, "Already set to that flag");
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWrapper() {
        require(msg.sender == wrapperAddress, "Only wrapper can call this function");
        _;
    }

    modifier isAddressWhitelisted() {
        require(whitelistedAddresses[msg.sender], "Address not supported");
        _;
    }

    modifier canGameBeCanceled(bytes32 _gameId) {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(marketPerGameId[_gameId] != address(0), "No market created for game");
        _;
    }

    modifier canGameBeResolved(
        bytes32 _gameId,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(marketPerGameId[_gameId] != address(0), "No market created for game");
        require(
            _isValidOutcomeForGame(_outcome) && _isValidOutcomeWithResult(_outcome, _homeScore, _awayScore),
            "Bad result or outcome"
        );
        _;
    }

    modifier canGameBePaused(address _market, bool _pause) {
        require(_market != address(0), "No market address");
        require(gameFulfilledCreated[gameIdPerMarket[_market]], "Game not existing");
        require(gameIdPerMarket[_market] != 0, "Market not existing");
        require(!isGameResolvedOrCanceled(gameIdPerMarket[_market]), "Market resoved or canceled");
        require(sportsManager.isMarketPaused(_market) != _pause, "Already paused/unpaused");
        _;
    }

    /* ========== EVENTS ========== */

    event RaceCreated(bytes32 _requestId, uint _sportId, string _id, RaceCreate _race);
    event GameCreated(bytes32 _requestId, uint _sportId, bytes32 _id, GameCreate _game, uint[] _normalizedOdds);
    event GameResolved(bytes32 _requestId, uint _sportId, bytes32 _id, GameResolve _game);
    event GameResultsSet(bytes32 requestId, uint _sportId, bytes32 _id, GameResults _game);

    event GameOddsAdded(bytes32 _requestId, bytes32 _id, GameOdds _game, uint[] _normalizedOdds);
    event InvalidOddsForMarket(bytes32 _requestId, address _marketAddress, bytes32 _id, GameOdds _game);

    event CreateSportsMarket(address _marketAddress, bytes32 _id, GameCreate _game, uint[] _tags, uint[] _normalizedOdds);
    event ResolveSportsMarket(address _marketAddress, bytes32 _id, uint _outcome);

    event PauseSportsMarket(address _marketAddress, bool _pause);
    event CancelSportsMarket(address _marketAddress, bytes32 _id);
    event SupportedSportsChanged(string _sport, bool _isSupported);
    event NewSportContracts(address _wrapperAddress, address _sportsManager);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportPositionalMarket.sol";

interface ISportPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getActiveMarketAddress(uint _index) external view returns (address);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function isMarketPaused(address _market) external view returns (bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags
    ) external returns (ISportPositionalMarket);

    function setMarketPaused(address _market, bool _paused) external;

    function resolveMarket(address market, uint outcome) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {Trading, Maturity, Expiry}
    enum Side {Cancelled, Home, Away, Draw}

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {Trading, Maturity, Expiry}
    enum Side {Up, Down}

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}