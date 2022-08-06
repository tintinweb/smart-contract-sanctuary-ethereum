// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../utils/Governable.sol";
import "../interfaces/native/IFluxPriceFeed.sol";
import "../interfaces/native/IFluxMegaOracle.sol";


/**
 * @title FluxMegaOracle
 * @author solace.fi
 * @notice An oracle that consumes data from [Flux](https://fluxprotocol.org) and returns it in a useable format.
 *
 * [Governance](/docs/protocol/governance) can add or remove price feeds via [`addPriceFeeds()`](#addpricefeeds) and [`removePriceFeeds()`](#removepricefeeds). Users can view price feeds via [`priceFeedForToken(address token)`](#pricefeedfortoken). Users can use the price feeds via [`valueOfTokens()`](#valueoftokens).
 */
contract FluxMegaOracle is IFluxMegaOracle, Governable {

    mapping(address => PriceFeedData) internal _priceFeeds;

    /***************************************
    STATE VARIABLES
    ***************************************/

    /**
     * @notice Constructs the `FluxMegaOracle` contract.
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
     * @notice Given an amount of some token, calculates the value in `USD`.
     * @dev Returns zero if no known price feed for the token.
     * @param token The address of the token to price.
     * @param amount The amount of the token to price.
     * @return valueInUSD The value in `USD` with 18 decimals.
     */
    function valueOfTokens(address token, uint256 amount) external view override returns (uint256 valueInUSD) {
        PriceFeedData memory feed = _priceFeeds[token];
        if(feed.priceFeed == address(0x0)) return 0;
        int256 answer = IFluxPriceFeed(feed.priceFeed).latestAnswer();
        require(answer >= 0, "negative price");
        return (amount * uint256(answer) * 1 ether) / (10 ** (feed.tokenDecimals + feed.priceFeedDecimals));
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds price feeds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param feeds The list of price feeds to add.
     */
    function addPriceFeeds(PriceFeedData[] memory feeds) external override onlyGovernance {
        for(uint256 i = 0; i < feeds.length; i++) {
            PriceFeedData memory feed = feeds[i];
            address token = feed.token;
            _priceFeeds[token] = feed;
            emit PriceFeedAdded(token);
        }
    }

    /**
     * @notice Removes price feeds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of price feeds to remove.
     */
    function removePriceFeeds(address[] memory tokens) external override onlyGovernance {
        for(uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            delete _priceFeeds[token];
            emit PriceFeedRemoved(token);
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


/**
 * @title Flux first-party price feed oracle
 * @author fluxprotocol.org
 * @notice Simple data posting on chain of a scalar value, compatible with Chainlink V2 and V3 aggregator interface
 */
interface IFluxPriceFeed {

    /**
     * @notice answer from the most recent report
     */
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IPriceOracle.sol";

/**
 * @title IFluxMegaOracle
 * @author solace.fi
 * @notice An oracle that consumes data from [Flux](https://fluxprotocol.org) and returns it in a useable format.
 *
 * [Governance](/docs/protocol/governance) can add or remove price feeds via [`addPriceFeeds()`](#addpricefeeds) and [`removePriceFeeds()`](#removepricefeeds). Users can view price feeds via [`priceFeedForToken(address token)`](#pricefeedfortoken). Users can use the price feeds via [`valueOfTokens()`](#valueoftokens).
 */
interface IFluxMegaOracle is IPriceOracle {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a price feed is added.
    event PriceFeedAdded(address indexed token);
    /// @notice Emitted when a price feed is removed.
    event PriceFeedRemoved(address indexed token);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    struct PriceFeedData {
        address token;
        address priceFeed;
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

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds price feeds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param feeds The list of price feeds to add.
     */
    function addPriceFeeds(PriceFeedData[] memory feeds) external;

    /**
     * @notice Removes price feeds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of price feeds to remove.
     */
    function removePriceFeeds(address[] memory tokens) external;
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