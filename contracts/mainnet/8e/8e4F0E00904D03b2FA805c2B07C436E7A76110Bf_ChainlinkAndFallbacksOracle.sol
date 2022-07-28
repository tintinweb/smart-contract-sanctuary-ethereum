// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Context, Initializable {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal initializer {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Deviation check feature, useful when checking prices from different providers for the same asset
 */
abstract contract UsingMaxDeviation is Governable {
    /**
     * @notice The max acceptable deviation
     * @dev 18-decimals scale (e.g 1e17 = 10%)
     */
    uint256 public maxDeviation;

    /// @notice Emitted when max deviation is updated
    event MaxDeviationUpdated(uint256 oldMaxDeviation, uint256 newMaxDeviation);

    constructor(uint256 maxDeviation_) {
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Update max deviation
     */
    function updateMaxDeviation(uint256 maxDeviation_) external onlyGovernor {
        emit MaxDeviationUpdated(maxDeviation, maxDeviation_);
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Check if two numbers deviation is acceptable
     */
    function _isDeviationOK(uint256 a_, uint256 b_) internal view returns (bool) {
        uint256 _deviation = a_ > b_ ? ((a_ - b_) * 1e18) / a_ : ((b_ - a_) * 1e18) / b_;
        return _deviation <= maxDeviation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";
import "../interfaces/core/IPriceProvidersAggregator.sol";

/**
 * @title Providers Aggregators usage feature, useful for periphery oracles that need get prices from many providers
 */
abstract contract UsingProvidersAggregator is Governable {
    /// @notice The PriceProvidersAggregator contract
    IPriceProvidersAggregator public providersAggregator;

    /// @notice Emitted when providers aggregator is updated
    event ProvidersAggregatorUpdated(
        IPriceProvidersAggregator oldProvidersAggregator,
        IPriceProvidersAggregator newProvidersAggregator
    );

    constructor(IPriceProvidersAggregator providersAggregator_) {
        require(address(providersAggregator_) != address(0), "aggregator-is-null");
        providersAggregator = providersAggregator_;
    }

    /**
     * @notice Update PriceProvidersAggregator contract
     */
    function updateProvidersAggregator(IPriceProvidersAggregator providersAggregator_) external onlyGovernor {
        require(address(providersAggregator_) != address(0), "address-is-null");
        emit ProvidersAggregatorUpdated(providersAggregator, providersAggregator_);
        providersAggregator = providersAggregator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Stale price check feature, useful when checking if prices are fresh enough
 */
abstract contract UsingStalePeriod is Governable {
    /// @notice The stale period. It's used to determine if a price is invalid (i.e. outdated)
    uint256 public stalePeriod;

    /// @notice Emitted when stale period is updated
    event StalePeriodUpdated(uint256 oldStalePeriod, uint256 newStalePeriod);

    constructor(uint256 stalePeriod_) {
        stalePeriod = stalePeriod_;
    }

    /**
     * @notice Update stale period
     */
    function updateStalePeriod(uint256 stalePeriod_) external onlyGovernor {
        emit StalePeriodUpdated(stalePeriod, stalePeriod_);
        stalePeriod = stalePeriod_;
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @dev Uses default stale period
     * @param timeOfLastUpdate_ The price timestamp
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(uint256 timeOfLastUpdate_) internal view returns (bool) {
        return _priceIsStale(timeOfLastUpdate_, stalePeriod);
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @param timeOfLastUpdate_ The price timestamp
     * @param stalePeriod_ The maximum acceptable outdated period
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(uint256 timeOfLastUpdate_, uint256 stalePeriod_) internal view returns (bool) {
        return block.timestamp - timeOfLastUpdate_ > stalePeriod_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceProvider {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_)
        external
        view
        returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(address token_, uint256 amountIn_)
        external
        view
        returns (uint256 _amountOut, uint256 _lastUpdatedAt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../libraries/DataTypes.sol";
import "./IPriceProvider.sol";

/**
 * @notice PriceProvidersAggregator interface
 * @dev Worth noting that the `_lastUpdatedAt` logic depends on the underlying price provider. In summary:
 * ChainLink: returns the last updated date from the aggregator
 * UniswapV2: returns the date of the latest pair oracle update
 * UniswapV3: assumes that the price is always updated (returns block.timestamp)
 * Flux: returns the last updated date from the aggregator
 * Umbrella (FCD): returns the last updated date returned from their oracle contract
 * Umbrella (Passport): returns the date of the latest pallet submission
 * Anytime that a quote performs more than one query, it uses the oldest date as the `_lastUpdatedAt`.
 * See more: https://github.com/bloqpriv/one-oracle/issues/64
 */
interface IPriceProvidersAggregator {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param provider_ The price provider to get quote from
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(DataTypes.Provider provider_, address token_)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Provider Providers' mapping
     */
    function priceProviders(DataTypes.Provider provider_) external view returns (IPriceProvider _priceProvider);

    /**
     * @notice Get quote
     * @param provider_ The price provider to get quote from
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @dev If providers aren't the same, uses native token as "bridge"
     * @param providerIn_ The price provider to get quote for the tokenIn
     * @param tokenIn_ The address of assetIn
     * @param providerOut_ The price provider to get quote for the tokenOut
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quote(
        DataTypes.Provider providerIn_,
        address tokenIn_,
        DataTypes.Provider providerOut_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param provider_ The price provider to get quote from
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param provider_ The price provider to get quote from
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Set a price provider
     * @dev Administrative function
     * @param provider_ The provider (from enum)
     * @param priceProvider_ The price provider contract
     */
    function setPriceProvider(DataTypes.Provider provider_, IPriceProvider priceProvider_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     */
    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library DataTypes {
    /**
     * @notice Price providers enumeration
     */
    enum Provider {
        NONE,
        CHAINLINK,
        UNISWAP_V3,
        UNISWAP_V2,
        SUSHISWAP,
        TRADERJOE,
        PANGOLIN,
        QUICKSWAP,
        UMBRELLA_FIRST_CLASS,
        UMBRELLA_PASSPORT,
        FLUX
    }

    enum ExchangeType {
        UNISWAP_V2,
        SUSHISWAP,
        TRADERJOE,
        PANGOLIN,
        QUICKSWAP,
        UNISWAP_V3
    }

    enum SwapType {
        EXACT_INPUT,
        EXACT_OUTPUT
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/core/IPriceProvidersAggregator.sol";
import "../interfaces/periphery/IOracle.sol";
import "../features/UsingProvidersAggregator.sol";
import "../features/UsingMaxDeviation.sol";
import "../features/UsingStalePeriod.sol";

/**
 * @title Chainlink and Fallbacks oracle
 * @dev Uses chainlink as primary oracle, if it doesn't support the asset(s), get price from fallback providers
 */
contract ChainlinkAndFallbacksOracle is IOracle, UsingProvidersAggregator, UsingMaxDeviation, UsingStalePeriod {
    /// @notice The fallback provider A. It's used when Chainlink isn't available
    DataTypes.Provider public fallbackProviderA;

    /// @notice The fallback provider B. It's used when Chainlink isn't available
    /// @dev This is optional
    DataTypes.Provider public fallbackProviderB;

    /// @notice Emitted when fallback providers are updated
    event FallbackProvidersUpdated(
        DataTypes.Provider oldFallbackProviderA,
        DataTypes.Provider newFallbackProviderA,
        DataTypes.Provider oldFallbackProviderB,
        DataTypes.Provider newFallbackProviderB
    );

    constructor(
        IPriceProvidersAggregator providersAggregator_,
        uint256 maxDeviation_,
        uint256 stalePeriod_,
        DataTypes.Provider fallbackProviderA_,
        DataTypes.Provider fallbackProviderB_
    ) UsingProvidersAggregator(providersAggregator_) UsingMaxDeviation(maxDeviation_) UsingStalePeriod(stalePeriod_) {
        require(fallbackProviderA_ != DataTypes.Provider.NONE, "fallback-provider-not-set");
        fallbackProviderA = fallbackProviderA_;
        fallbackProviderB = fallbackProviderB_;
    }

    /// @inheritdoc IOracle
    function getPriceInUsd(address _asset) public view virtual returns (uint256 _priceInUsd) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_priceInUsd, _lastUpdatedAt) = _getPriceInUsd(DataTypes.Provider.CHAINLINK, _asset);

        // 2. If price from chainlink is OK return it
        if (_priceInUsd > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _priceInUsd;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _getPriceInUsd(fallbackProviderA, _asset);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _getPriceInUsd(fallbackProviderB, _asset);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quote(DataTypes.Provider.CHAINLINK, tokenIn_, tokenOut_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quote(fallbackProviderA, tokenIn_, tokenOut_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quote(fallbackProviderB, tokenIn_, tokenOut_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quoteTokenToUsd(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quoteTokenToUsd(DataTypes.Provider.CHAINLINK, token_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quoteTokenToUsd(fallbackProviderA, token_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quoteTokenToUsd(fallbackProviderB, token_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quoteUsdToToken(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quoteUsdToToken(DataTypes.Provider.CHAINLINK, token_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quoteUsdToToken(fallbackProviderA, token_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quoteUsdToToken(fallbackProviderB, token_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /**
     * @notice Wrapped `getPriceInUsd` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _getPriceInUsd(DataTypes.Provider provider_, address token_)
        private
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        try providersAggregator.getPriceInUsd(provider_, token_) returns (
            uint256 __priceInUsd,
            uint256 __lastUpdatedAt
        ) {
            _priceInUsd = __priceInUsd;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quote` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quote(provider_, tokenIn_, tokenOut_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quoteTokenToUsd` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quoteTokenToUsd(provider_, token_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quoteUsdToToken` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quoteUsdToToken(provider_, token_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Update fallback providers
     * @dev The fallback provider B is optional
     */
    function updateFallbackProviders(DataTypes.Provider fallbackProviderA_, DataTypes.Provider fallbackProviderB_)
        external
        onlyGovernor
    {
        require(fallbackProviderA_ != DataTypes.Provider.NONE, "fallback-a-is-null");
        emit FallbackProvidersUpdated(fallbackProviderA, fallbackProviderA_, fallbackProviderB, fallbackProviderB_);
        fallbackProviderA = fallbackProviderA_;
        fallbackProviderB = fallbackProviderB_;
    }
}