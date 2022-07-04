// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "./GamesQueue.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";

/// @title Consumer contract which stores all data from CL data feed (Link to docs: https://market.link/nodes/TheRundown/integrations), also creates all sports markets based on that data
/// @author gruja
contract TherundownConsumer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */

    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant RESULT_DRAW = 3;
    uint public constant MIN_TAG_NUMBER = 9000;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    }

    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
    }

    /* ========== STATE VARIABLES ========== */

    // global params
    address public wrapperAddress;
    mapping(address => bool) public whitelistedAddresses;

    // Maps <RequestId, Result>
    mapping(bytes32 => bytes[]) public requestIdGamesCreated;
    mapping(bytes32 => bytes[]) public requestIdGamesResolved;
    mapping(bytes32 => bytes[]) public requestIdGamesOdds;

    // Maps <GameId, Game>
    mapping(bytes32 => GameCreate) public gameCreated;
    mapping(bytes32 => GameResolve) public gameResolved;
    mapping(bytes32 => GameOdds) public gameOdds;
    mapping(bytes32 => uint) public sportsIdPerGame;
    mapping(bytes32 => bool) public gameFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledResolved;

    // sports props
    mapping(uint => bool) public supportedSport;
    mapping(uint => bool) public twoPositionSport;
    mapping(uint => bool) public supportResolveGameStatuses;
    mapping(uint => bool) public cancelGameStatuses;

    // market props
    ISportPositionalMarketManager public sportsManager;
    mapping(bytes32 => address) public marketPerGameId;
    mapping(address => bytes32) public gameIdPerMarket;
    mapping(address => bool) public marketResolved;
    mapping(address => bool) public marketCanceled;

    // game
    GamesQueue public queues;
    mapping(bytes32 => uint) public oddsLastPulledForGame;
    mapping(uint => bytes32[]) public gamesPerDate;
    mapping(uint => mapping(uint => bool)) public isSportOnADate;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        uint[] memory _supportedSportIds,
        address _sportsManager,
        uint[] memory _twoPositionSports,
        GamesQueue _queues,
        uint[] memory _resolvedStatuses,
        uint[] memory _cancelGameStatuses
    ) external initializer {
        setOwner(_owner);
        _populateSports(_supportedSportIds);
        _populateTwoPositionSports(_twoPositionSports);
        _populateSupportedStatuses(_resolvedStatuses);
        _populateCancelGameStatuses(_cancelGameStatuses);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        queues = _queues;
        whitelistedAddresses[_owner] = true;
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    /// @notice fulfill all data necessary to create sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be stored and transfered to markets
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    /// @param _date date on which game/games are played
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId,
        uint _date
    ) external onlyWrapper {
        requestIdGamesCreated[_requestId] = _games;

        if (_games.length > 0) {
            isSportOnADate[_date][_sportId] = true;
        }

        for (uint i = 0; i < _games.length; i++) {
            GameCreate memory game = abi.decode(_games[i], (GameCreate));
            if (
                !queues.existingGamesInCreatedQueue(game.gameId) &&
                !isSameTeamOrTBD(game.homeTeam, game.awayTeam) &&
                game.startTime > block.timestamp
            ) {
                gamesPerDate[_date].push(game.gameId);
                _createGameFulfill(_requestId, game, _sportId);
            }
        }
    }

    /// @notice fulfill all data necessary to resolve sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be resolved
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId
    ) external onlyWrapper {
        requestIdGamesResolved[_requestId] = _games;
        for (uint i = 0; i < _games.length; i++) {
            GameResolve memory game = abi.decode(_games[i], (GameResolve));
            // if game is not resolved already and there is market for that game
            if (!queues.existingGamesInResolvedQueue(game.gameId) && marketPerGameId[game.gameId] != address(0)) {
                _resolveGameFulfill(_requestId, game, _sportId);
            }
        }
    }

    /// @notice fulfill all data necessary to populate odds of a game
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to update the odds
    /// @param _date date on which game/games are played
    function fulfillGamesOdds(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _date
    ) external onlyWrapper {
        requestIdGamesOdds[_requestId] = _games;
        for (uint i = 0; i < _games.length; i++) {
            GameOdds memory game = abi.decode(_games[i], (GameOdds));
            // game needs to be fulfilled and market needed to be created 
            if(gameFulfilledCreated[game.gameId] && marketPerGameId[game.gameId] != address(0)){
                _oddsGameFulfill(_requestId, game);
            }
        }
    }

    /// @notice creates market for a given game id
    /// @param _gameId game id
    function createMarketForGame(bytes32 _gameId) external {
        require(marketPerGameId[_gameId] == address(0), "Market for game already exists");
        require(gameFulfilledCreated[_gameId], "No such game fulfilled, created");
        require(queues.gamesCreateQueue(queues.firstCreated()) == _gameId, "Must be first in a queue");
        _createMarket(_gameId);
    }

    /// @notice resolve market for a given game id
    /// @param _gameId game id
    function resolveMarketForGame(bytes32 _gameId) external {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(gameFulfilledResolved[_gameId], "No such game Fulfilled, resolved");
        _resolveMarket(_gameId);
    }

    /// @notice resolve market for a given game id
    /// @param _gameId game id
    /// @param _outcome outcome of a game (1: home win, 2: away win, 3: draw, 0: cancel market)
    function resolveGameManually(bytes32 _gameId, uint _outcome) external isAddressWhitelisted canGameBeResolved(_gameId, _outcome) {
        _resolveMarketManually(marketPerGameId[_gameId], _outcome);
    }

    /// @notice resolve market for a given market address
    /// @param _market market address
    /// @param _outcome outcome of a game (1: home win, 2: away win, 3: draw, 0: cancel market)
    function resolveMarketManually(address _market, uint _outcome) external isAddressWhitelisted canGameBeResolved(gameIdPerMarket[_market], _outcome) {
        _resolveMarketManually(_market, _outcome);
    }

    /// @notice cancel market for a given game id
    /// @param _gameId game id
    function cancelGameManually(bytes32 _gameId) external isAddressWhitelisted canGameBeCanceled(_gameId) {
        _cancelMarketManually(marketPerGameId[_gameId]);
    }

    /// @notice cancel market for a given market address
    /// @param _market market address
    function cancelMarketManually(address _market) external isAddressWhitelisted canGameBeCanceled(gameIdPerMarket[_market]){
        _cancelMarketManually(_market);
    }

    /// @notice pause/unpause market for a given game id
    /// @param _gameId game id
    /// @param _pause pause = true, unpause = false
    function pauseOrUnpauseGameManually(bytes32 _gameId, bool _pause) external isAddressWhitelisted canGameBePaused(marketPerGameId[_gameId], _pause) {
        _pauseOrUnpauseMarketManually(marketPerGameId[_gameId], _pause);
    }

    /// @notice pause/unpause market for a given market address
    /// @param _market market address
    /// @param _pause pause = true, unpause = false
    function pauseOrUnpauseMarketManually(address _market, bool _pause) external isAddressWhitelisted canGameBePaused(_market, _pause) {
        _pauseOrUnpauseMarketManually(_market, _pause);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice returns game created based on CL request id and index of a game in a array
    /// @param _requestId request id from CL
    /// @param _idx index in array
    /// @return GameCreate game create object
    function getGameCreatedByRequestId(bytes32 _requestId, uint256 _idx) public view returns (GameCreate memory) {
        GameCreate memory game = abi.decode(requestIdGamesCreated[_requestId][_idx], (GameCreate));
        return game;
    }

    /// @notice returns game resolved based on CL request id and index of a game in a array
    /// @param _requestId request id from CL
    /// @param _idx index in array
    /// @return GameResolve game resolved object
    function getGameResolvedByRequestId(bytes32 _requestId, uint256 _idx) public view returns (GameResolve memory) {
        GameResolve memory game = abi.decode(requestIdGamesResolved[_requestId][_idx], (GameResolve));
        return game;
    }

    /// @notice view function which returns game created object based on id of a game
    /// @param _gameId game id
    /// @return GameCreate game create object
    function getGameCreatedById(bytes32 _gameId) public view returns (GameCreate memory) {
        return gameCreated[_gameId];
    }

    /// @notice view function which returns game start time based on id of a game
    /// @param _gameId game id
    /// @return startTime game start time
    function getGameTime(bytes32 _gameId) public view returns (uint256) {
        return gameCreated[_gameId].startTime;
    }

    /// @notice view function which returns odds for home team based on id of a game
    /// @param _gameId game id
    /// @return homeOdds moneyline odd in a two decimal places
    function getOddsHomeTeam(bytes32 _gameId) public view returns (int24) {
        return gameOdds[_gameId].homeOdds;
    }

    /// @notice view function which returns odds for awway team based on id of a game
    /// @param _gameId game id
    /// @return awayOdds moneyline odd in a two decimal places
    function getOddsAwayTeam(bytes32 _gameId) public view returns (int24) {
        return gameOdds[_gameId].awayOdds;
    }

    /// @notice view function which returns odds for draw based on id of a game (if game can have draw result if not return is 0)
    /// @param _gameId game id
    /// @return drawOdds moneyline odd in a two decimal places
    function getOddsDraw(bytes32 _gameId) public view returns (int24) {
        return gameOdds[_gameId].drawOdds;
    }

    /// @notice view function which returns games on certan date
    /// @param _date date
    /// @return bytes32[] list of games
    function getGamesPerdate(uint _date) public view returns (bytes32[] memory) {
        return gamesPerDate[_date];
    }

    /// @notice view function which returns game resolved object based on id of a game
    /// @param _gameId game id
    /// @return GameResolve game resolve object
    function getGameResolvedById(bytes32 _gameId) public view returns (GameResolve memory) {
        return gameResolved[_gameId];
    }

    /// @notice view function which returns if market type is supported, checks are done in a wrapper contract
    /// @param _market type of market (create or resolve)
    /// @return bool supported or not
    function isSupportedMarketType(string memory _market) external view returns (bool) {
        return
            keccak256(abi.encodePacked(_market)) == keccak256(abi.encodePacked("create")) ||
            keccak256(abi.encodePacked(_market)) == keccak256(abi.encodePacked("resolve"));
    }

    /// @notice view function which returns if game is ready to be created and teams are defined or not
    /// @param _teamA team A in string (Example: Liverpool Liverpool)
    /// @param _teamB team B in string (Example: Arsenal Arsenal)
    /// @return bool is it ready for creation true/false
    function isSameTeamOrTBD(string memory _teamA, string memory _teamB) public view returns (bool) {
        return
            keccak256(abi.encodePacked(_teamA)) == keccak256(abi.encodePacked(_teamB)) ||
            keccak256(abi.encodePacked(_teamA)) == keccak256(abi.encodePacked("TBD TBD")) ||
            keccak256(abi.encodePacked(_teamB)) == keccak256(abi.encodePacked("TBD TBD"));
    }

    /// @notice view function which returns if game is resolved or canceled and ready for market to be resolved or canceled
    /// @param _gameId game id for which game is looking
    /// @return bool is it ready for resolve or cancel true/false
    function isGameResolvedOrCanceled(bytes32 _gameId) public view returns (bool) {
        return marketResolved[marketPerGameId[_gameId]] || marketCanceled[marketPerGameId[_gameId]];
    }

    /// @notice view function which returns if sport is supported or not
    /// @param _sportId sport id for which is looking
    /// @return bool is sport supported true/false
    function isSupportedSport(uint _sportId) external view returns (bool) {
        return supportedSport[_sportId];
    }

    /// @notice view function which returns if sport is two positional (no draw, example: NBA)
    /// @param _sportsId sport id for which is looking
    /// @return bool is sport two positional true/false
    function isSportTwoPositionsSport(uint _sportsId) public view returns (bool) {
        return twoPositionSport[_sportsId];
    }

    /// @notice view function which returns if game is resolved
    /// @param _gameId game id for which game is looking
    /// @return bool is game resolved true/false
    function isGameInResolvedStatus(bytes32 _gameId) public view returns (bool) {
        return _isGameStatusResolved(getGameResolvedById(_gameId));
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOdds(bytes32 _gameId) public view returns (uint[] memory) {
        int[] memory odds = new int[](3);
        odds[0] = gameOdds[_gameId].homeOdds;
        odds[1] = gameOdds[_gameId].awayOdds;
        odds[2] = gameOdds[_gameId].drawOdds;
        return _calculateAndNormalizeOdds(odds);
    }

    /// @notice view function which returns normalized odd based on moneyline odd (Example: -15000)
    /// @param _americanOdd moneyline odd (Example of a param: -15000, +35000, etc.), this param is with two decimal places (-15000 is -150 in moneyline world)
    /// @return uint odd normalized to a 100
    function calculateNormalizedOddFromAmerican(int _americanOdd) external pure returns (uint) {
        uint odd;
        if (_americanOdd == 0) {
            odd = 0;
        } else if (_americanOdd > 0) {
            odd = uint(_americanOdd);
            odd = ((10000 * 1e18) / (odd + 10000)) * 100;
        } else if (_americanOdd < 0) {
            odd = uint(-_americanOdd);
            odd = ((odd * 1e18) / (odd + 10000)) * 100;
        }
        return odd;
    }

    /// @notice view function which returns outcome of a game based on ID
    /// @param _gameId game id for which result is looking
    /// @return uint returns 1: home win, 2: away win, 3: draw, 0: cancel
    function getResult(bytes32 _gameId) external view returns (uint) {
        if (isGameInResolvedStatus(_gameId)) {
            return _calculateOutcome(getGameResolvedById(_gameId));
        } else {
            return 0;
        }
    }

    /* ========== INTERNALS ========== */

    function _createGameFulfill(
        bytes32 requestId,
        GameCreate memory _game,
        uint _sportId
    ) internal {
        gameCreated[_game.gameId] = _game;
        sportsIdPerGame[_game.gameId] = _sportId;
        queues.enqueueGamesCreated(_game.gameId, _game.startTime, _sportId);
        gameFulfilledCreated[_game.gameId] = true;
        gameOdds[_game.gameId] = GameOdds(_game.gameId, _game.homeOdds, _game.awayOdds, _game.drawOdds);
        oddsLastPulledForGame[_game.gameId] = block.timestamp;

        emit GameCreated(requestId, _sportId, _game.gameId, _game, queues.lastCreated(), getNormalizedOdds(_game.gameId));
    }

    function _resolveGameFulfill(
        bytes32 requestId,
        GameResolve memory _game,
        uint _sportId
    ) internal {
        if (_isGameReadyToBeResolved(_game)) {
            gameResolved[_game.gameId] = _game;
            queues.enqueueGamesResolved(_game.gameId);
            gameFulfilledResolved[_game.gameId] = true;

            emit GameResolved(requestId, _sportId, _game.gameId, _game, queues.lastResolved());
        }
    }

    function _oddsGameFulfill(bytes32 requestId, GameOdds memory _game) internal {
        // if odds are valid store them if not pause market
        if(_areOddsValid(_game)){

            gameOdds[_game.gameId] = _game;
            oddsLastPulledForGame[_game.gameId] = block.timestamp;

            if(sportsManager.isMarketPaused(marketPerGameId[_game.gameId])){
                sportsManager.setMarketPaused(marketPerGameId[_game.gameId], false);
            }

            emit GameOddsAdded(requestId, _game.gameId, _game, getNormalizedOdds(_game.gameId));
        }else{

            if(!sportsManager.isMarketPaused(marketPerGameId[_game.gameId])){
                sportsManager.setMarketPaused(marketPerGameId[_game.gameId], true);
            }

            emit InvalidOddsForMarket(requestId, marketPerGameId[_game.gameId], _game.gameId, _game);
        }
    }

    function _populateSports(uint[] memory _supportedSportIds) internal {
        for (uint i; i < _supportedSportIds.length; i++) {
            supportedSport[_supportedSportIds[i]] = true;
        }
    }

    function _populateTwoPositionSports(uint[] memory _twoPositionSports) internal {
        for (uint i; i < _twoPositionSports.length; i++) {
            twoPositionSport[_twoPositionSports[i]] = true;
        }
    }

    function _populateSupportedStatuses(uint[] memory _supportedStatuses) internal {
        for (uint i; i < _supportedStatuses.length; i++) {
            supportResolveGameStatuses[_supportedStatuses[i]] = true;
        }
    }

    function _populateCancelGameStatuses(uint[] memory _cancelStatuses) internal {
        for (uint i; i < _cancelStatuses.length; i++) {
            cancelGameStatuses[_cancelStatuses[i]] = true;
        }
    }

    function _createMarket(bytes32 _gameId) internal {
        GameCreate memory game = getGameCreatedById(_gameId);
        uint sportId = sportsIdPerGame[_gameId];
        uint numberOfPositions = _calculateNumberOfPositionsBasedOnSport(sportId);
        uint[] memory tags = _calculateTags(sportId);

        // create
        sportsManager.createMarket(
            _gameId,
            _append(game.homeTeam, game.awayTeam), // gameLabel
            game.startTime, //maturity
            0, //initialMint
            numberOfPositions,
            tags //tags
        );

        address marketAddress = sportsManager.getActiveMarketAddress(sportsManager.numActiveMarkets() - 1);
        marketPerGameId[game.gameId] = marketAddress;
        gameIdPerMarket[marketAddress] = game.gameId;

        queues.dequeueGamesCreated();

        emit CreateSportsMarket(marketAddress, game.gameId, game, tags, getNormalizedOdds(game.gameId));
    }

    function _resolveMarket(bytes32 _gameId) internal {
        GameResolve memory game = getGameResolvedById(_gameId);
        uint index = queues.unproccessedGamesIndex(_gameId);

        // it can return ZERO index, needs checking
        require(_gameId == queues.unproccessedGames(index), "Invalid Game ID");

        if (_isGameStatusResolved(game)) {
            uint _outcome = _calculateOutcome(game);

            sportsManager.resolveMarket(marketPerGameId[game.gameId], _outcome);
            marketResolved[marketPerGameId[game.gameId]] = true;

            _cleanStorageQueue(index);

            emit ResolveSportsMarket(marketPerGameId[game.gameId], game.gameId, _outcome);
        } else if (_isGameStatusCanceled(game)) {
            sportsManager.resolveMarket(marketPerGameId[game.gameId], 0);
            marketCanceled[marketPerGameId[game.gameId]] = true;

            _cleanStorageQueue(index);

            emit CancelSportsMarket(marketPerGameId[game.gameId], game.gameId);
        }
    }

    function _resolveMarketManually(address _market, uint _outcome) internal {
        uint index = queues.unproccessedGamesIndex(gameIdPerMarket[_market]);

        // it can return ZERO index, needs checking
        require(gameIdPerMarket[_market] == queues.unproccessedGames(index), "Invalid Game ID");

        sportsManager.resolveMarket(_market, _outcome);
        marketResolved[_market] = true;
        queues.removeItemUnproccessedGames(index);

        emit ResolveSportsMarket(_market, gameIdPerMarket[_market], _outcome);
    }

    function _cancelMarketManually(address _market) internal {
        uint index = queues.unproccessedGamesIndex(gameIdPerMarket[_market]);

        // it can return ZERO index, needs checking
        require(gameIdPerMarket[_market] == queues.unproccessedGames(index), "Invalid Game ID");

        sportsManager.resolveMarket(_market, 0);
        marketCanceled[_market] = true;
        queues.removeItemUnproccessedGames(index);

        emit CancelSportsMarket(_market, gameIdPerMarket[_market]);
    }

    function _pauseOrUnpauseMarketManually(address _market, bool _pause) internal {
        sportsManager.setMarketPaused(_market, _pause);
        emit PauseSportsMarket(_market, _pause);
    }

    function _cleanStorageQueue(uint index) internal {
        queues.dequeueGamesResolved();
        queues.removeItemUnproccessedGames(index);
    }

    function _append(string memory teamA, string memory teamB) internal pure returns (string memory) {
        return string(abi.encodePacked(teamA, " vs ", teamB));
    }

    function _calculateNumberOfPositionsBasedOnSport(uint _sportsId) internal returns (uint) {
        return isSportTwoPositionsSport(_sportsId) ? 2 : 3;
    }

    function _calculateTags(uint _sportsId) internal returns (uint[] memory) {
        uint[] memory result = new uint[](1);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        return result;
    }

    function _isGameReadyToBeResolved(GameResolve memory _game) internal view returns (bool) {
        return _isGameStatusResolved(_game) || _isGameStatusCanceled(_game);
    }

    function _isGameStatusResolved(GameResolve memory _game) internal view returns (bool) {
        return supportResolveGameStatuses[_game.statusId];
    }

    function _isGameStatusCanceled(GameResolve memory _game) internal view returns (bool) {
        return cancelGameStatuses[_game.statusId];
    }

    function _calculateOutcome(GameResolve memory _game) internal pure returns (uint) {
        if (_game.homeScore == _game.awayScore) {
            return RESULT_DRAW;
        }
        return _game.homeScore > _game.awayScore ? HOME_WIN : AWAY_WIN;
    }

    function _areOddsValid(GameOdds memory _game) internal view returns (bool) {
        if(isSportTwoPositionsSport(sportsIdPerGame[_game.gameId])){
            return _game.awayOdds != 0 && _game.homeOdds != 0;
        }else{
            return _game.awayOdds != 0 && _game.homeOdds != 0 && _game.drawOdds != 0;
        }
    }

    function _isValidOutcomeForGame(bytes32 _gameId, uint _outcome) internal view returns (bool) {
        if (isSportTwoPositionsSport(sportsIdPerGame[_gameId])) {
            return _outcome == HOME_WIN || _outcome == AWAY_WIN || _outcome == CANCELLED;
        } 
        return _outcome == HOME_WIN || _outcome == AWAY_WIN || _outcome == RESULT_DRAW || _outcome == CANCELLED;
    }

    function _calculateAndNormalizeOdds(int[] memory _americanOdds) internal pure returns (uint[] memory) {
        uint[] memory normalizedOdds = new uint[](_americanOdds.length);
        uint totalOdds;
        for (uint i = 0; i < _americanOdds.length; i++) {
            uint odd;
            if (_americanOdds[i] == 0) {
                normalizedOdds[i] = 0;
            } else if (_americanOdds[i] > 0) {
                odd = uint(_americanOdds[i]);
                normalizedOdds[i] = ((10000 * 1e18) / (odd + 10000)) * 100;
            } else if (_americanOdds[i] < 0) {
                odd = uint(-_americanOdds[i]);
                normalizedOdds[i] = ((odd * 1e18) / (odd + 10000)) * 100;
            }
            totalOdds += normalizedOdds[i];
        }
        for (uint i = 0; i < normalizedOdds.length; i++) {
            if (totalOdds == 0) {
                normalizedOdds[i] = 0;
            } else {
                normalizedOdds[i] = (1e18 * normalizedOdds[i]) / totalOdds;
            }
        }
        return normalizedOdds;
    }

    /* ========== GAMES MANAGEMENT ========== */

    /// @notice remove first game in a created queue if needed
    function removeFromCreatedQueue() external isAddressWhitelisted {
        queues.dequeueGamesCreated();
    }

    /// @notice remove first game in a resolved queue if needed
    function removeFromResolvedQueue() external isAddressWhitelisted {
        queues.dequeueGamesResolved();
    }

    /// @notice remove from unprocessed games array based on index
    /// @param _index index which needed to be removed
    function removeFromUnprocessedGamesArray(uint _index) external isAddressWhitelisted {
        queues.removeItemUnproccessedGames(_index);
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSuported true/false (supported or not)
    function setSupportedSport(uint _sportId, bool _isSuported) external onlyOwner {
        supportedSport[_sportId] = _isSuported;
        emit SupportedSportsChanged(_sportId, _isSuported);
    }

    /// @notice sets resolved status which is supported or not
    /// @param _status status ID which needs to be supported or not
    /// @param _isSuported true/false (supported or not)
    function setSupportedResolvedStatuses(uint _status, bool _isSuported) external onlyOwner {
        supportResolveGameStatuses[_status] = _isSuported;
        emit SupportedResolvedStatusChanged(_status, _isSuported);
    }

    /// @notice sets cancel status which is supported or not
    /// @param _status ststus ID which needs to be supported or not
    /// @param _isSuported true/false (supported or not)
    function setSupportedCancelStatuses(uint _status, bool _isSuported) external onlyOwner {
        cancelGameStatuses[_status] = _isSuported;
        emit SupportedCancelStatusChanged(_status, _isSuported);
    }

    /// @notice sets if sport is two positional (Example: NBA)
    /// @param _sportId sport ID which is two positional
    /// @param _isTwoPosition true/false (two positional sport or not)
    function setTwoPositionSport(uint _sportId, bool _isTwoPosition) external onlyOwner {
        twoPositionSport[_sportId] = _isTwoPosition;
        emit TwoPositionSportChanged(_sportId, _isTwoPosition);
    }

    /// @notice sets manager for market creation
    /// @param _sportsManager sport manager address
    function setSportsManager(address _sportsManager) external onlyOwner {
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        emit NewSportsMarketManager(_sportsManager);
    }

    /// @notice sets wrapper address
    /// @param _wrapperAddress wrapper address
    function setWrapperAddress(address _wrapperAddress) external onlyOwner {
        require(_wrapperAddress != address(0), "Invalid address");
        wrapperAddress = _wrapperAddress;
        emit NewWrapperAddress(_wrapperAddress);
    }

    /// @notice sets queue address
    /// @param _queues queue address
    function setQueueAddress(GamesQueue _queues) external onlyOwner {
        queues = _queues;
        emit NewQueueAddress(_queues);
    }

    /// @notice adding into whitelist address which can call market creation
    /// @param _whitelistAddress address that needed to be whitelisted
    function addToWhitelist(address _whitelistAddress) external onlyOwner {
        require(_whitelistAddress != address(0), "Invalid address");
        whitelistedAddresses[_whitelistAddress] = true;
        emit AddedIntoWhitelist(_whitelistAddress);
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

    modifier canGameBeResolved(bytes32 _gameId, uint _outcome) {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(marketPerGameId[_gameId] != address(0), "No market created for game");
        require(_isValidOutcomeForGame(_gameId, _outcome) , "Bad outcome.");
        _;
    } 

    modifier canGameBePaused(address _market, bool _pause) {
        require(_market != address(0), "No market address");
        require(gameFulfilledCreated[gameIdPerMarket[_market]], "Game not existing");
        require(gameIdPerMarket[_market] != 0 , "Market not existing");
        require(!isGameResolvedOrCanceled(gameIdPerMarket[_market]), "Market resoved or canceled");
        require(sportsManager.isMarketPaused(_market) != _pause, "Already paused/unpaused");
        _;
    } 
    /* ========== EVENTS ========== */

    event GameCreated(
        bytes32 _requestId,
        uint _sportId,
        bytes32 _id,
        GameCreate _game,
        uint _queueIndex,
        uint[] _normalizedOdds
    );
    event GameResolved(bytes32 _requestId, uint _sportId, bytes32 _id, GameResolve _game, uint _queueIndex);
    event GameOddsAdded(bytes32 _requestId, bytes32 _id, GameOdds _game, uint[] _normalizedOdds);
    event CreateSportsMarket(address _marketAddress, bytes32 _id, GameCreate _game, uint[] _tags, uint[] _normalizedOdds);
    event ResolveSportsMarket(address _marketAddress, bytes32 _id, uint _outcome);
    event PauseSportsMarket(address _marketAddress, bool _pause);
    event CancelSportsMarket(address _marketAddress, bytes32 _id);
    event InvalidOddsForMarket(bytes32 _requestId, address _marketAddress, bytes32 _id, GameOdds _game);
    event SupportedSportsChanged(uint _sportId, bool _isSupported);
    event SupportedResolvedStatusChanged(uint _status, bool _isSupported);
    event SupportedCancelStatusChanged(uint _status, bool _isSupported);
    event TwoPositionSportChanged(uint _sportId, bool _isTwoPosition);
    event NewSportsMarketManager(address _sportsManager);
    event NewWrapperAddress(address _wrapperAddress);
    event NewQueueAddress(GamesQueue _queues);
    event AddedIntoWhitelist(address _whitelistAddress);
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

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

/// @title Storage for games (created or resolved), calculation for order-making bot processing
/// @author gruja
contract GamesQueue is Initializable, ProxyOwned, ProxyPausable {
    // create games queue
    mapping(uint => bytes32) public gamesCreateQueue;
    mapping(bytes32 => bool) public existingGamesInCreatedQueue;
    uint public firstCreated;
    uint public lastCreated;
    mapping(bytes32 => uint) public gameStartPerGameId;
    mapping(bytes32 => uint) public sportPerGameId; // delete

    // resolve games queue
    bytes32[] public unproccessedGames;
    mapping(bytes32 => uint) public unproccessedGamesIndex;
    mapping(uint => bytes32) public gamesResolvedQueue;
    mapping(bytes32 => bool) public existingGamesInResolvedQueue;
    uint public firstResolved;
    uint public lastResolved;

    address public consumer;

    /// @notice public initialize proxy method
    /// @param _owner future owner of a contract
    function initialize(address _owner) public initializer {
        setOwner(_owner);
        firstCreated = 1;
        lastCreated = 0;
        firstResolved = 1;
        lastResolved = 0;
    }

    /// @notice putting game in a crated queue and fill up unprocessed games array
    /// @param data id of a game in byte32
    /// @param startTime game start time
    /// @param sportsId id of a sport (Example: NBA = 4 etc.)
    function enqueueGamesCreated(
        bytes32 data,
        uint startTime,
        uint sportsId
    ) public onlyConsumer {
        lastCreated += 1;
        gamesCreateQueue[lastCreated] = data;

        existingGamesInCreatedQueue[data] = true;
        unproccessedGames.push(data);
        unproccessedGamesIndex[data] = unproccessedGames.length - 1;
        gameStartPerGameId[data] = startTime;

        emit EnqueueGamesCreated(data, sportsId, lastCreated);
    }

    /// @notice removing first game in a queue from created queue
    /// @return data returns id of a game which is removed
    function dequeueGamesCreated() public onlyConsumer returns (bytes32 data) {
        require(lastCreated >= firstCreated, "No more elements in a queue");

        data = gamesCreateQueue[firstCreated];

        delete gamesCreateQueue[firstCreated];
        firstCreated += 1;

        emit DequeueGamesCreated(data, firstResolved - 1);
    }

    /// @notice putting game in a resolved queue
    /// @param data id of a game in byte32
    function enqueueGamesResolved(bytes32 data) public onlyConsumer {
        lastResolved += 1;
        gamesResolvedQueue[lastResolved] = data;
        existingGamesInResolvedQueue[data] = true;

        emit EnqueueGamesResolved(data, lastCreated);
    }

    /// @notice removing first game in a queue from resolved queue
    /// @return data returns id of a game which is removed
    function dequeueGamesResolved() public onlyConsumer returns (bytes32 data) {
        require(lastResolved >= firstResolved, "No more elements in a queue");

        data = gamesResolvedQueue[firstResolved];

        delete gamesResolvedQueue[firstResolved];
        firstResolved += 1;

        emit DequeueGamesResolved(data, firstResolved - 1);
    }

    /// @notice removing game from array of unprocessed games
    /// @param index index in array
    function removeItemUnproccessedGames(uint index) public onlyConsumer {
        require(index < unproccessedGames.length, "No such index in array");

        bytes32 dataProccessed = unproccessedGames[index];

        unproccessedGames[index] = unproccessedGames[unproccessedGames.length - 1];
        unproccessedGamesIndex[unproccessedGames[index]] = index;
        unproccessedGames.pop();

        emit GameProcessed(dataProccessed, index);
    }

    /// @notice public function which will return length of unprocessed array
    /// @return index index in array
    function getLengthUnproccessedGames() public view returns (uint) {
        return unproccessedGames.length;
    }

    /// @notice sets the consumer contract address, which only owner can execute
    /// @param _consumer address of a consumer contract
    function setConsumerAddress(address _consumer) external onlyOwner {
        require(_consumer != address(0), "Invalid address");
        consumer = _consumer;
        emit NewConsumerAddress(_consumer);
    }

    modifier onlyConsumer() {
        require(msg.sender == consumer, "Only consumer can call this function");
        _;
    }

    event EnqueueGamesCreated(bytes32 _gameId, uint _sportId, uint _index);
    event EnqueueGamesResolved(bytes32 _gameId, uint _index);
    event DequeueGamesCreated(bytes32 _gameId, uint _index);
    event DequeueGamesResolved(bytes32 _gameId, uint _index);
    event GameProcessed(bytes32 _gameId, uint _index);
    event NewConsumerAddress(address _consumer);
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

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        bool customMarket,
        address customOracle
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