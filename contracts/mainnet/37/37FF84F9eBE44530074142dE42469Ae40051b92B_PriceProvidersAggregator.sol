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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../core/AddressProvider.sol";

/**
 * @notice Contract module which provides access control mechanism, where
 * the governor account is granted with exclusive access to specific functions.
 * @dev Uses the AddressProvider to get the governor
 */
abstract contract Governable {
    IAddressProvider public constant addressProvider = IAddressProvider(0xfbA0816A81bcAbBf3829bED28618177a2bf0e82A);

    /// @dev Throws if called by any account other than the governor.
    modifier onlyGovernor() {
        require(msg.sender == addressProvider.governor(), "not-governor");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/core/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Initializable {
    /// @notice The governor account
    address public governor;

    /// @notice The proposed governor account. Becomes the new governor after acceptance
    address public proposedGovernor;

    /// @notice The PriceProvidersAggregator contract
    IPriceProvidersAggregator public override providersAggregator;

    /// @notice The StableCoinProvider contract
    IStableCoinProvider public override stableCoinProvider;

    /// @notice Emitted when providers aggregator is updated
    event ProvidersAggregatorUpdated(
        IPriceProvidersAggregator oldProvidersAggregator,
        IPriceProvidersAggregator newProvidersAggregator
    );

    /// @notice Emitted when stable coin provider is updated
    event StableCoinProviderUpdated(
        IStableCoinProvider oldStableCoinProvider,
        IStableCoinProvider newStableCoinProvider
    );

    /// @notice Emitted when governor is updated
    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == msg.sender, "not-governor");
        _;
    }

    function initialize(address governor_) external initializer {
        governor = governor_;
        emit UpdatedGovernor(address(0), governor_);
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(msg.sender == proposedGovernor, "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
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
     * @notice Update PriceProvidersAggregator contract
     */
    function updateProvidersAggregator(IPriceProvidersAggregator providersAggregator_) external onlyGovernor {
        require(address(providersAggregator_) != address(0), "address-is-null");
        emit ProvidersAggregatorUpdated(providersAggregator, providersAggregator_);
        providersAggregator = providersAggregator_;
    }

    /**
     * @notice Update StableCoinProvider contract
     */
    function updateStableCoinProvider(IStableCoinProvider stableCoinProvider_) external onlyGovernor {
        emit StableCoinProviderUpdated(stableCoinProvider, stableCoinProvider_);
        stableCoinProvider = stableCoinProvider_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/core/IPriceProvidersAggregator.sol";
import "../access/Governable.sol";

/**
 * @title Price Providers Aggregator
 */
contract PriceProvidersAggregator is IPriceProvidersAggregator, Governable {
    /**
     * The native token (usually the most liquid asset in the chain)
     * @dev Is used when getting quote from two price providers
     */
    address public immutable nativeToken;

    /**
     * @notice Price providers map
     */
    mapping(DataTypes.Provider => IPriceProvider) public override priceProviders;

    /// Emitted when an price provider is updated
    event PriceProviderUpdated(
        DataTypes.Provider provider,
        IPriceProvider oldPriceProvider,
        IPriceProvider newPriceProvider
    );

    constructor(address nativeToken_) {
        require(nativeToken_ != address(0), "native-token-is-null");
        nativeToken = nativeToken_;
    }

    /// @inheritdoc IPriceProvidersAggregator
    function getPriceInUsd(DataTypes.Provider provider_, address token_)
        external
        view
        override
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.getPriceInUsd(token_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        override
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        )
    {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quote(tokenIn_, tokenOut_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quote(
        DataTypes.Provider providerIn_,
        address tokenIn_,
        DataTypes.Provider providerOut_,
        address tokenOut_,
        uint256 amountIn_
    )
        public
        view
        override
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _nativeTokenLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        )
    {
        IPriceProvider _providerIn = priceProviders[providerIn_];
        require(address(_providerIn) != address(0), "provider-in-not-set");

        if (providerIn_ == providerOut_) {
            (_amountOut, _tokenInLastUpdatedAt, _tokenOutLastUpdatedAt) = _providerIn.quote(
                tokenIn_,
                tokenOut_,
                amountIn_
            );
            _nativeTokenLastUpdatedAt = block.timestamp;
            return (_amountOut, _tokenInLastUpdatedAt, _nativeTokenLastUpdatedAt, _tokenOutLastUpdatedAt);
        }

        IPriceProvider _providerOut = priceProviders[providerOut_];
        require(address(_providerOut) != address(0), "provider-out-not-set");

        uint256 _nativeTokenLastUpdatedAt0;
        uint256 _nativeTokenLastUpdatedAt1;
        (_amountOut, _tokenInLastUpdatedAt, _nativeTokenLastUpdatedAt0) = _providerIn.quote(
            tokenIn_,
            nativeToken,
            amountIn_
        );
        (_amountOut, _nativeTokenLastUpdatedAt1, _tokenOutLastUpdatedAt) = _providerOut.quote(
            nativeToken,
            tokenOut_,
            _amountOut
        );
        _nativeTokenLastUpdatedAt = Math.min(_nativeTokenLastUpdatedAt0, _nativeTokenLastUpdatedAt1);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view override returns (uint256 amountOut_, uint256 _lastUpdatedAt) {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quoteTokenToUsd(token_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quoteUsdToToken(token_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function setPriceProvider(DataTypes.Provider provider_, IPriceProvider priceProvider_)
        external
        override
        onlyGovernor
    {
        require(provider_ != DataTypes.Provider.NONE, "invalid-provider");
        IPriceProvider _current = priceProviders[provider_];
        require(priceProvider_ != _current, "same-as-current");

        emit PriceProviderUpdated(provider_, _current, priceProvider_);

        priceProviders[provider_] = priceProvider_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IStableCoinProvider.sol";
import "./IPriceProvidersAggregator.sol";

interface IAddressProvider {
    function governor() external view returns (address);

    function providersAggregator() external view returns (IPriceProvidersAggregator);

    function stableCoinProvider() external view returns (IStableCoinProvider);
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
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

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
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

    /**
     * @notice Get quote
     * @dev If providers aren't the same, uses native token as "bridge"
     * @param providerIn_ The price provider to get quote for the tokenIn
     * @param tokenIn_ The address of assetIn
     * @param providerOut_ The price provider to get quote for the tokenOut
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _nativeTokenLastUpdatedAt Last updated timestamp of native token (i.e. WETH) used when providers aren't the same
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        DataTypes.Provider providerIn_,
        address tokenIn_,
        DataTypes.Provider providerOut_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _nativeTokenLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

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

interface IStableCoinProvider {
    /**
     * @notice Return the stable coin if pegged
     * @dev Check price relation between both stable coins and revert if peg is too loose
     * @return _stableCoin The primary stable coin if pass all checks
     */
    function getStableCoinIfPegged() external view returns (address _stableCoin);

    /**
     * @notice Convert given amount of stable coin to USD representation (18 decimals)
     */
    function toUsdRepresentation(uint256 stableCoinAmount_) external view returns (uint256 _usdAmount);
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
        UNISWAP_V3,
        PANCAKE_SWAP
    }

    enum SwapType {
        EXACT_INPUT,
        EXACT_OUTPUT
    }
}