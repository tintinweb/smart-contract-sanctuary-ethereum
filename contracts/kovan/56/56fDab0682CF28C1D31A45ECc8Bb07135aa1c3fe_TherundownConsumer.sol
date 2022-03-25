// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "./GamesQueue.sol";

// interface
import "../interfaces/IExoticPositionalMarketManager.sol";

/** 
    Link to docs: https://market.link/nodes/098c3c5e-811d-4b8a-b2e3-d1806909c7d7/integrations
 */

contract TherundownConsumer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== LIBRARIES ========== */

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== CONSTANTS =========== */

    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant RESULT_DRAW = 3;
    uint public constant MIN_TAG_NUMBER = 9000;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    }

    /* ========== STATE VARIABLES ========== */

    // Maps <RequestId, Result>
    mapping(bytes32 => bytes[]) public requestIdGamesCreated;
    mapping(bytes32 => bytes[]) public requestIdGamesResolved;

    // Maps <GameId, Game>
    mapping(bytes32 => GameCreate) public gameCreated;
    mapping(bytes32 => GameResolve) public gameResolved;
    mapping(bytes32 => uint) public sportsIdPerGame;
    mapping(bytes32 => bool) public gameFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledResolved;

    // sports props
    mapping(uint => bool) public supportedSport;
    mapping(uint => bool) public twoPositionSport;

    // market props
    IExoticPositionalMarketManager public exoticManager;
    mapping(bytes32 => address) public marketPerGameId;
    mapping(address => bool) public marketResolved;
    mapping(address => bool) public marketCanceled;
    uint public fixedTicketPrice;
    bool public withdrawalAllowed;

    // wrapper
    address public wrapperAddress;

    GamesQueue public queues;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        uint[] memory _supportedSportIds,
        address _exoticManager,
        uint[] memory _twoPositionSports,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        GamesQueue _queues
    ) public initializer {
        setOwner(_owner);
        _populateSports(_supportedSportIds);
        _populateTwoPositionSports(_twoPositionSports);
        exoticManager = IExoticPositionalMarketManager(_exoticManager);
        fixedTicketPrice = _fixedTicketPrice;
        withdrawalAllowed = _withdrawalAllowed;
        queues = _queues;
        //approve
        IERC20Upgradeable(exoticManager.paymentToken()).approve(
            exoticManager.thalesBonds(),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId
    ) external onlyWrapper {
        requestIdGamesCreated[_requestId] = _games;
        for (uint i = 0; i < _games.length; i++) {
            GameCreate memory game = abi.decode(_games[i], (GameCreate));
            if(!queues.existingGamesInCreatedQueue(game.gameId)){
                _createGameFulfill(_requestId, game, _sportId);
            }
        }
    }

    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId
    ) external onlyWrapper {
        requestIdGamesResolved[_requestId] = _games;
        for (uint i = 0; i < _games.length; i++) {
            _resolveGameFulfill(_requestId, abi.decode(_games[i], (GameResolve)), _sportId);
        }
    }

    function createMarketForGame(bytes32 _gameId) public {
        require(marketPerGameId[_gameId] == address(0), "Market for game already exists");
        require(gameFulfilledCreated[_gameId], "No such game fulfilled, created");
        require(queues.gamesCreateQueue(queues.firstCreated()) == _gameId, "Must be first in a queue");
        _createMarket(_gameId);
    }

    function resolveMarketForGame(bytes32 _gameId) public {
        require(!isGameResolvedOrCanceled(_gameId), "Market resoved or canceled");
        require(gameFulfilledResolved[_gameId], "No such game Fulfilled, resolved");
        _resolveMarket(_gameId);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getGameCreatedByRequestId(bytes32 _requestId, uint256 _idx) public view returns (GameCreate memory) {
        GameCreate memory game = abi.decode(requestIdGamesCreated[_requestId][_idx], (GameCreate));
        return game;
    }

    function getGameResolvedByRequestId(bytes32 _requestId, uint256 _idx) public view returns (GameResolve memory) {
        GameResolve memory game = abi.decode(requestIdGamesResolved[_requestId][_idx], (GameResolve));
        return game;
    }

    function getGameCreatedById(bytes32 _gameId) public view returns (GameCreate memory) {
        return gameCreated[_gameId];
    }

    function getGameTime(bytes32 _gameId) public view returns (uint256) {
        return gameCreated[_gameId].startTime;
    }

    function getGameResolvedById(bytes32 _gameId) public view returns (GameResolve memory) {
        return gameResolved[_gameId];
    }

    function isSupportedMarketType(string memory _market) external view returns (bool) {
        return
            keccak256(abi.encodePacked(_market)) == keccak256(abi.encodePacked("create")) ||
            keccak256(abi.encodePacked(_market)) == keccak256(abi.encodePacked("resolve"));
    }

    function isGameResolvedOrCanceled(bytes32 _gameId) public view returns (bool) {
        return marketResolved[marketPerGameId[_gameId]] || marketCanceled[marketPerGameId[_gameId]];
    }

    function isSupportedSport(uint _sportId) external view returns (bool) {
        return supportedSport[_sportId];
    }

    function isSportTwoPositionsSport(uint _sportsId) public view returns (bool) {
        return twoPositionSport[_sportsId];
    }

    function isGameInResolvedStatus(bytes32 _gameId) public view returns (bool) {
        return _isGameStatusResolved(getGameResolvedById(_gameId));
    }

    /* ========== INTERNALS ========== */

    function _createGameFulfill(
        bytes32 requestId,
        GameCreate memory _game,
        uint _sportId
    ) internal {
        gameCreated[_game.gameId] = _game;
        sportsIdPerGame[_game.gameId] = _sportId;
        queues.enqueueGamesCreated(_game.gameId);
        gameFulfilledCreated[_game.gameId] = true;

        emit GameCreted(requestId, _sportId, _game.gameId, _game, queues.lastCreated());
    }

    function _resolveGameFulfill(
        bytes32 requestId,
        GameResolve memory _game,
        uint _sportId
    ) internal {
        if(_isGameReadyToBeResolved(_game)){
            gameResolved[_game.gameId] = _game;
            queues.enqueueGamesResolved(_game.gameId);
            gameFulfilledResolved[_game.gameId] = true;
        }

        emit GameResolved(requestId, _sportId, _game.gameId, _game, queues.lastResolved());
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

    function _createMarket(bytes32 _gameId) internal {
        GameCreate memory game = getGameCreatedById(_gameId);
        uint sportId = sportsIdPerGame[_gameId];
        uint numberOfPositions = _calculateNumberOfPositionsBasedOnSport(sportId);

        // create
        exoticManager.createCLMarket(
            _append(game.homeTeam, game.awayTeam),
            "chainlink_sports_data",
            game.startTime,
            fixedTicketPrice,
            withdrawalAllowed,
            _calculateTags(sportId),
            numberOfPositions,
            _createPhrases(game.homeTeam, game.awayTeam, numberOfPositions)
        );

        address marketAddress = exoticManager.getActiveMarketAddress(exoticManager.numOfActiveMarkets() - 1);
        marketPerGameId[game.gameId] = marketAddress;

        queues.dequeueGamesCreated();

        emit CreateSportsMarket(marketAddress, game.gameId, game);
    }

    function _resolveMarket(bytes32 _gameId) internal {
        GameResolve memory game = getGameResolvedById(_gameId);

        if (_isGameStatusResolved(game)) {
            exoticManager.resolveMarket(marketPerGameId[game.gameId], _callulateOutcome(game));
            marketResolved[marketPerGameId[game.gameId]] = true;

            queues.dequeueGamesResolved();

            emit ResolveSportsMarket(marketPerGameId[game.gameId], game.gameId, game);
        } else if (_isGameStatusCanceled(game)) {
            exoticManager.cancelMarket(marketPerGameId[game.gameId]);
            marketCanceled[marketPerGameId[game.gameId]] = true;

            queues.dequeueGamesResolved();

            emit CancelSportsMarket(marketPerGameId[game.gameId], game.gameId, game);
        }
    }

    function _append(string memory teamA, string memory teamB) internal pure returns (string memory) {
        return string(abi.encodePacked(teamA, " vs ", teamB));
    }

    function _createPhrases(
        string memory teamA,
        string memory teamB,
        uint _numberOfPositions
    ) public pure returns (string[] memory) {
        string[] memory result = new string[](_numberOfPositions);

        result[0] = teamA;
        result[1] = teamB;
        if (_numberOfPositions > 2) {
            result[2] = "It will be a draw";
        }

        return result;
    }

    function _calculateNumberOfPositionsBasedOnSport(uint _sportsId) internal returns (uint) {
        return isSportTwoPositionsSport(_sportsId) ? 2 : 3;
    }

    function _calculateTags(uint _sportsId) internal returns (uint[] memory) {
        uint[] memory result = new uint[](1);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        return result;
    }

    function _isGameReadyToBeResolved(GameResolve memory _game) internal pure returns (bool) {
        return _isGameStatusResolved(_game) || _isGameStatusCanceled(_game);
    }

    function _isGameStatusResolved(GameResolve memory _game) internal pure returns (bool) {
        // TODO
        // 8 : STATUS_FINAL - NBA
        // 11 : STATUS_FULL_TIME - Champions league 90 min
        // penalties, extra time ???
        return _game.statusId == 8 || _game.statusId == 11;
    }

    function _isGameStatusCanceled(GameResolve memory _game) internal pure returns (bool) {
        // 1 : STATUS_CANCELED
        // 2 : STATUS_DELAYED
        return _game.statusId == 1 || _game.statusId == 2;
    }

    function _callulateOutcome(GameResolve memory _game) internal pure returns (uint) {
        if (_game.homeScore == _game.awayScore) {
            return RESULT_DRAW;
        }
        return _game.homeScore > _game.awayScore ? HOME_WIN : AWAY_WIN;
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    function setSupportedSport(uint _sportId, bool _isSuported) public onlyOwner {
        supportedSport[_sportId] = _isSuported;
        emit SupportedSportsChanged(_sportId, _isSuported);
    }

    function setwoPositionSport(uint _sportId, bool _isTwoPosition) public onlyOwner {
        twoPositionSport[_sportId] = _isTwoPosition;
        emit TwoPositionSportChanged(_sportId, _isTwoPosition);
    }

    function setExoticManager(address _exoticManager) public onlyOwner {
        exoticManager = IExoticPositionalMarketManager(_exoticManager);
        emit NewExoticPositionalMarketManager(_exoticManager);
    }

    function setFixedTicketPrice(uint _fixedTicketPrice) public onlyOwner {
        fixedTicketPrice = _fixedTicketPrice;
        emit NewFixedTicketPrice(_fixedTicketPrice);
    }

    function setWithdrawalAllowed(bool _withdrawalAllowed) public onlyOwner {
        withdrawalAllowed = _withdrawalAllowed;
        emit NewWithdrawalAllowed(_withdrawalAllowed);
    }

    function setWrapperAddress(address _wrapperAddress) public onlyOwner {
        require(_wrapperAddress != address(0), "Invalid address");
        wrapperAddress = _wrapperAddress;
        emit NewWrapperAddress(_wrapperAddress);
    }


    function setQueueAddress(GamesQueue _queues) public onlyOwner {
        queues = _queues;
        emit NewQueueAddress(_queues);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWrapper() {
        require(msg.sender == wrapperAddress, "Only wrapper can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event GameCreted(bytes32 _requestId, uint _sportId, bytes32 _id, GameCreate _game, uint _queueIndex);
    event GameResolved(bytes32 _requestId, uint _sportId, bytes32 _id, GameResolve _game, uint _queueIndex);
    event CreateSportsMarket(address _marketAddress, bytes32 _id, GameCreate _game);
    event ResolveSportsMarket(address _marketAddress, bytes32 _id, GameResolve _game);
    event CancelSportsMarket(address _marketAddress, bytes32 _id, GameResolve _game);
    event SupportedSportsChanged(uint _sportId, bool _isSupported);
    event TwoPositionSportChanged(uint _sportId, bool _isTwoPosition);
    event NewFixedTicketPrice(uint _fixedTicketPrice);
    event NewWithdrawalAllowed(bool _withdrawalAllowed);
    event NewExoticPositionalMarketManager(address _exoticManager);
    event NewWrapperAddress(address _wrapperAddress);
    event NewQueueAddress(GamesQueue _queues);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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

pragma solidity ^0.8.0;

contract GamesQueue {

    // create games queue
    mapping(uint => bytes32) public gamesCreateQueue;
    mapping(bytes32 => bool) public existingGamesInCreatedQueue;
    uint public firstCreated = 1;
    uint public lastCreated = 0;

    // resolve games queue
    mapping(uint => bytes32) public gamesResolvedQueue;
    uint public firstResolved = 1;
    uint public lastResolved = 0;

    function enqueueGamesCreated(bytes32 data) public {
        lastCreated += 1;
        gamesCreateQueue[lastCreated] = data;
        existingGamesInCreatedQueue[data] = true;
    }

    function dequeueGamesCreated() public returns (bytes32 data) {
        require(lastCreated >= firstCreated, "No more elements in a queue");

        data = gamesCreateQueue[firstCreated];

        delete gamesCreateQueue[firstCreated];
        firstCreated += 1;
    }

    function enqueueGamesResolved(bytes32 data) public {
        lastResolved += 1;
        gamesResolvedQueue[lastResolved] = data;
    }

    function dequeueGamesResolved() public returns (bytes32 data) {
        require(lastResolved >= firstResolved);  // non-empty queue

        data = gamesResolvedQueue[firstResolved];

        delete gamesResolvedQueue[firstResolved];
        firstResolved += 1;
    }
}

pragma solidity ^0.8.0;

interface IExoticPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */
    function getActiveMarketAddress(uint _index) external view returns(address);
    function getActiveMarketIndex(address _marketAddress) external view returns(uint);
    function isActiveMarket(address _marketAddress) external view returns(bool);
    function numOfActiveMarkets() external view returns(uint);
    function getMarketBondAmount(address _market) external view returns (uint);
    function maximumPositionsAllowed() external view returns(uint);
    function paymentToken() external view returns(address);
    function owner() external view returns(address);
    function thalesBonds() external view returns(address);
    function oracleCouncilAddress() external view returns(address);
    function safeBoxAddress() external view returns(address);
    function creatorAddress(address _market) external view returns(address);
    function resolverAddress(address _market) external view returns(address);
    function isPauserAddress(address _pauserAddress) external view returns(bool);
    function safeBoxPercentage() external view returns(uint);
    function creatorPercentage() external view returns(uint);
    function resolverPercentage() external view returns(uint);
    function withdrawalPercentage() external view returns(uint);
    function pDAOResolveTimePeriod() external view returns(uint);
    function claimTimeoutDefaultPeriod() external view returns(uint);
    function maxOracleCouncilMembers() external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);

    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function createCLMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function disputeMarket(address _marketAddress, address disputor) external;
    function resolveMarket(address _marketAddress, uint _outcomePosition) external;
    function resetMarket(address _marketAddress) external;
    function cancelMarket(address _market) external ;
    function closeDispute(address _market) external ;
    function setBackstopTimeout(address _market) external; 
    function sendMarketBondAmountTo(address _market, address _recepient, uint _amount) external;
    function addPauserAddress(address _pauserAddress) external;
    function removePauserAddress(address _pauserAddress) external;
    function sendRewardToDisputor(address _market, address _disputorAddress, uint amount) external;
    function issueBondsBackToCreatorAndResolver(address _marketAddress) external ;


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