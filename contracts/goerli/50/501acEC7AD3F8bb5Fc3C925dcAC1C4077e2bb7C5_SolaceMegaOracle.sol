// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../utils/Governable.sol";
import "../interfaces/native/ISolaceMegaOracle.sol";


/**
 * @title SolaceMegaOracle
 * @author solace.fi
 * @notice An oracle that consumes data from Solace updaters and returns it in a useable format.
 *
 * [Governance](/docs/protocol/governance) can add or remove updater bots via [`setUpdaterStatuses()`](#setupdaterstatuses). Users can view updater status via [`isUpdater()`](#isupdater).
 */
contract SolaceMegaOracle is ISolaceMegaOracle, Governable {

    /***************************************
    STATE VARIABLES
    ***************************************/

    // token => data
    mapping(address => PriceFeedData) internal _priceFeeds;
    // index => token
    mapping(uint256 => address) internal _indexToToken;
    // token => index+1
    mapping(address => uint256) internal _tokenToIndex;
    // number of tokens known
    uint256 internal _tokensLength;

    // updater => status
    mapping(address => bool) internal _isUpdater;

    /**
     * @notice Constructs the `SolaceMegaOracle` contract.
     * @param governance_ The address of the governor.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor (address governance_) Governable(governance_) { }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns information about the price feed for a token.
     * @dev Returns a zero struct if no known price feed.
     * @param token The token to query price feed data of.
     * @return data Information about te price feed.
     */
    function priceFeedForToken(address token) external view override returns (PriceFeedData memory data) {
        return _priceFeeds[token];
    }

    /**
     * @notice Lists the tokens in the oracle.
     * @dev Enumerable `[0,tokensLength]`
     * @param index The index to query.
     * @return token The address of the token at that index.
     */
    function tokenByIndex(uint256 index) external view override returns (address token) {
        require(index < _tokensLength, "index out of bounds");
        return _indexToToken[index];
    }

    /**
     * @notice The number of tokens with feeds in this oracle.
     * @return len The number of tokens.
     */
    function tokensLength() external view override returns (uint256 len) {
        return _tokensLength;
    }

    /**
     * @notice Given an amount of some token, calculates the value in `USD`.
     * @dev Returns zero if no known price feed for the token.
     * @param token The address of the token to price.
     * @param amount The amount of the token to price.
     * @return valueInUSD The value in `USD` with 18 decimals.
     */
    function valueOfTokens(address token, uint256 amount) external view override returns (uint256 valueInUSD) {
        PriceFeedData memory feed = _priceFeeds[token];
        return (amount * feed.latestPrice * 1 ether) / (10 ** (feed.tokenDecimals + feed.priceFeedDecimals));
    }

    /**
     * @notice Returns the status of an updater.
     * @param updater The account to query.
     * @return status True if the account has the updater role, false otherwise.
     */
    function isUpdater(address updater) external view override returns (bool status) {
        return _isUpdater[updater];
    }

    /***************************************
    UPDATER FUNCTIONS
    ***************************************/

    /**
     * @notice Sets metadata for each token and adds it to the token enumeration.
     * Can only be called by an `updater`.
     * @param feeds The list of feeds to set.
     */
    function addPriceFeeds(PriceFeedData[] memory feeds) external override {
        require(_isUpdater[msg.sender], "!updater");
        uint256 stLen = _tokensLength;
        uint256 stLen0 = stLen;
        for(uint256 i = 0; i < feeds.length; i++) {
            // add to feed mapping
            PriceFeedData memory feed = feeds[i];
            address token = feed.token;
            _priceFeeds[token] = feed;
            // add to token enumeration
            if(_tokenToIndex[token] == 0) {
                uint256 index = stLen++; // autoincrement from 0
                _indexToToken[index] = token;
                _tokenToIndex[token] = index + 1;
            }
            emit PriceFeedAdded(token);
        }
        if(stLen != stLen0) _tokensLength = stLen;
    }

    /**
     * @notice Sets latest price for each token.
     * Can only be called by an `updater`.
     * @param tokens The list of token addresses to set prices for.
     * @param prices The list of prices for each token.
     */
    function transmit(address[] memory tokens, uint256[] memory prices) external override {
        require(_isUpdater[msg.sender], "!updater");
        uint256 len = tokens.length;
        require(len == prices.length, "length mismatch");
        for(uint256 i = 0; i < len; i++) {
            _priceFeeds[tokens[i]].latestPrice = prices[i];
            emit PriceTransmitted(tokens[i], prices[i]);
        }
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds or removes updaters.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updaters The list of updater addresses to add or remove.
     * @param statuses A list of true to set as updater false otherwise.
     */
    function setUpdaterStatuses(address[] memory updaters, bool[] memory statuses) external override onlyGovernance {
        uint256 len = updaters.length;
        require(len == statuses.length, "length mismatch");
        for(uint256 i = 0; i < len; i++) {
            _isUpdater[updaters[i]] = statuses[i];
            emit UpdaterSet(updaters[i], statuses[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IPriceOracle.sol";

/**
 * @title ISolaceMegaOracle
 * @author solace.fi
 * @notice An oracle that consumes data from Solace updaters and returns it in a useable format.
 *
 * [Governance](/docs/protocol/governance) can add or remove updater bots via [`setUpdaterStatuses()`](#setupdaterstatuses). Users can view updater status via [`isUpdater()`](#isupdater). Updaters can update prices via [`transmit()`](#transmit).
 *
 * price feeds via [`priceFeedForToken(address token)`](#pricefeedfortoken). Users can use the price feeds via [`valueOfTokens()`](#valueoftokens). Users can list price feeds via [`tokensLength()`](#tokenslength) and [`tokenByIndex()`](#tokenbyindex).
 */
interface ISolaceMegaOracle is IPriceOracle {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a price feed metadata is set.
    event PriceFeedAdded(address indexed token);
    /// @notice Emitted when a price is transmitted.
    event PriceTransmitted(address indexed token, uint256 price);
    /// @notice Emitted when an updater is added or removed.
    event UpdaterSet(address indexed updater, bool status);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    struct PriceFeedData {
        uint256 latestPrice;
        address token;
        uint8 tokenDecimals;
        uint8 priceFeedDecimals;
    }

    /**
     * @notice Returns information about the price feed for a token.
     * @dev Returns a zero struct if no known price feed.
     * @param token The token to query price feed data of.
     * @return data Information about te price feed.
     */
    function priceFeedForToken(address token) external view returns (PriceFeedData memory data);

    /**
     * @notice Lists the tokens in the oracle.
     * @dev Enumerable `[0,tokensLength]`
     * @param index The index to query.
     * @return token The address of the token at that index.
     */
    function tokenByIndex(uint256 index) external view returns (address token);

    /**
     * @notice The number of tokens with feeds in this oracle.
     * @return len The number of tokens.
     */
    function tokensLength() external view returns (uint256 len);

    /**
     * @notice Returns the status of an updater.
     * @param updater The account to query.
     * @return status True if the account has the updater role, false otherwise.
     */
    function isUpdater(address updater) external view returns (bool status);

    /***************************************
    UPDATER FUNCTIONS
    ***************************************/

    /**
     * @notice Sets metadata for each token and adds it to the token enumeration.
     * Can only be called by an `updater`.
     * @param feeds The list of feeds to set.
     */
    function addPriceFeeds(PriceFeedData[] memory feeds) external;

    /**
     * @notice Sets latest price for each token.
     * Can only be called by an `updater`.
     * @param tokens The list of token addresses to set prices for.
     * @param prices The list of prices for each token.
     */
    function transmit(address[] memory tokens, uint256[] memory prices) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds or removes updaters.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updaters The list of updater addresses to add or remove.
     * @param statuses A list of true to set as updater false otherwise.
     */
    function setUpdaterStatuses(address[] memory updaters, bool[] memory statuses) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IPriceOracle
 * @author solace.fi
 * @notice Generic interface for an oracle that determines the price of tokens.
 */
interface IPriceOracle {

    /**
     * @notice Given an amount of some token, calculates the value in `USD`.
     * @param token The address of the token to price.
     * @param amount The amount of the token to price.
     * @return valueInUSD The value in `USD` with 18 decimals.
     */
    function valueOfTokens(address token, uint256 amount) external view returns (uint256 valueInUSD);
}