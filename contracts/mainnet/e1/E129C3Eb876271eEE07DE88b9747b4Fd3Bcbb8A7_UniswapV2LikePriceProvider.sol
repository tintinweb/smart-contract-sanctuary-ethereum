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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
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
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/core/IPriceProvider.sol";

/**
 * @title Price providers' super class that implements common functions
 */
abstract contract PriceProvider is IPriceProvider {
    uint256 public constant USD_DECIMALS = 18;

    /// @inheritdoc IPriceProvider
    function getPriceInUsd(address token_) public view virtual returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /// @inheritdoc IPriceProvider
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view virtual override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        (uint256 _amountInUsd, uint256 _lastUpdatedAt0) = quoteTokenToUsd(tokenIn_, amountIn_);
        (_amountOut, _lastUpdatedAt) = quoteUsdToToken(tokenOut_, _amountInUsd);
        _lastUpdatedAt = Math.min(_lastUpdatedAt0, _lastUpdatedAt);
    }

    /// @inheritdoc IPriceProvider
    function quoteTokenToUsd(address token_, uint256 amountIn_)
        public
        view
        override
        returns (uint256 _amountOut, uint256 _lastUpdatedAt)
    {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_);
        _amountOut = (amountIn_ * _price) / 10**IERC20Metadata(token_).decimals();
    }

    /// @inheritdoc IPriceProvider
    function quoteUsdToToken(address token_, uint256 amountIn_)
        public
        view
        override
        returns (uint256 _amountOut, uint256 _lastUpdatedAt)
    {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_);
        _amountOut = (amountIn_ * 10**IERC20Metadata(token_).decimals()) / _price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../access/Governable.sol";
import "../interfaces/core/IUniswapV2LikePriceProvider.sol";
import "./PriceProvider.sol";

/**
 * @title UniswapV2 (and forks) TWAP Oracle implementation
 * Based on https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
 */
contract UniswapV2LikePriceProvider is IUniswapV2LikePriceProvider, Governable, PriceProvider {
    using FixedPoint for *;

    /**
     * @notice The UniswapV2-like factory's address
     */
    address public immutable factory;

    /**
     * @notice The native wrapped token (e.g. WETH, WAVAX, WMATIC, etc)
     */
    address public immutable nativeToken;

    /// @inheritdoc IUniswapV2LikePriceProvider
    uint256 public override defaultTwapPeriod;

    struct Oracle {
        address token0;
        address token1;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    /**
     * @notice Oracles'
     * @dev pair => twapPeriod => oracle
     */
    mapping(IUniswapV2Pair => mapping(uint256 => Oracle)) public oracles;

    /// @notice Emitted when default TWAP period is updated
    event DefaultTwapPeriodUpdated(uint256 oldTwapPeriod, uint256 newTwapPeriod);

    constructor(
        address factory_,
        uint256 defaultTwapPeriod_,
        address nativeToken_
    ) {
        require(factory_ != address(0), "factory-is-null");
        defaultTwapPeriod = defaultTwapPeriod_;
        factory = factory_;
        nativeToken = nativeToken_;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function hasOracle(IUniswapV2Pair pair_) external view override returns (bool) {
        return hasOracle(pair_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function hasOracle(IUniswapV2Pair pair_, uint256 twapPeriod_) public view override returns (bool) {
        return oracles[pair_][twapPeriod_].blockTimestampLast > 0;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function pairFor(address token0_, address token1_) public view override returns (IUniswapV2Pair _pair) {
        _pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(token0_, token1_));
    }

    /// @inheritdoc IPriceProvider
    function getPriceInUsd(address token_)
        public
        view
        override(IPriceProvider, PriceProvider)
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        return getPriceInUsd(token_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function getPriceInUsd(address token_, uint256 twapPeriod_)
        public
        view
        override
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        IStableCoinProvider _stableCoinProvider = addressProvider.stableCoinProvider();
        require(address(_stableCoinProvider) != address(0), "stable-coin-not-supported");

        uint256 _stableCoinAmount;
        (_stableCoinAmount, _lastUpdatedAt) = quote(
            token_,
            _stableCoinProvider.getStableCoinIfPegged(),
            twapPeriod_,
            10**IERC20Metadata(token_).decimals() // ONE
        );
        _priceInUsd = _stableCoinProvider.toUsdRepresentation(_stableCoinAmount);
    }

    /// @inheritdoc IPriceProvider
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view override(IPriceProvider, PriceProvider) returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        return quote(tokenIn_, tokenOut_, defaultTwapPeriod, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        if (tokenIn_ == tokenOut_) {
            return (amountIn_, block.timestamp);
        }

        if (hasOracle(pairFor(tokenIn_, tokenOut_), twapPeriod_)) {
            (_amountOut, _lastUpdatedAt) = _getAmountOut(tokenIn_, tokenOut_, twapPeriod_, amountIn_);
        } else {
            (_amountOut, _lastUpdatedAt) = _getAmountOut(tokenIn_, nativeToken, twapPeriod_, amountIn_);
            uint256 __lastUpdatedAt;
            (_amountOut, __lastUpdatedAt) = _getAmountOut(nativeToken, tokenOut_, twapPeriod_, _amountOut);
            _lastUpdatedAt = Math.min(__lastUpdatedAt, _lastUpdatedAt);
        }
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quoteTokenToUsd(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_, twapPeriod_);
        _amountOut = (amountIn_ * _price) / 10**IERC20Metadata(token_).decimals();
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quoteUsdToToken(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_, twapPeriod_);
        _amountOut = (amountIn_ * 10**IERC20Metadata(token_).decimals()) / _price;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        return updateAndQuote(tokenIn_, tokenOut_, defaultTwapPeriod, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) public override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        updateOrAdd(tokenIn_, tokenOut_, twapPeriod_);
        return quote(tokenIn_, tokenOut_, twapPeriod_, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateOrAdd(address tokenIn_, address tokenOut_) external override {
        updateOrAdd(tokenIn_, tokenOut_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateOrAdd(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_
    ) public override {
        IUniswapV2Pair _pair = pairFor(tokenIn_, tokenOut_);
        if (!hasOracle(_pair, twapPeriod_)) {
            _addOracleFor(_pair, twapPeriod_);
        }
        _updateIfNeeded(_pair, twapPeriod_);
    }

    /**
     * @notice Create new oracle
     * @param pair_ The pair to get prices from
     * @param twapPeriod_ The TWAP period
     */
    function _addOracleFor(IUniswapV2Pair pair_, uint256 twapPeriod_) private {
        require(address(pair_) != address(0), "invalid-pair");

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pair_.getReserves();

        require(_reserve0 != 0 && _reserve1 != 0, "no-reserves");

        oracles[pair_][twapPeriod_] = Oracle({
            token0: pair_.token0(),
            token1: pair_.token1(),
            price0CumulativeLast: pair_.price0CumulativeLast(),
            price1CumulativeLast: pair_.price1CumulativeLast(),
            blockTimestampLast: _blockTimestampLast,
            price0Average: uint112(0).encode(),
            price1Average: uint112(0).encode()
        });
    }

    /**
     * @notice Get the output amount for a given oracle
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function _getAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        Oracle memory _oracle = oracles[pairFor(tokenIn_, tokenOut_)][twapPeriod_];
        if (tokenIn_ == _oracle.token0) {
            _amountOut = _oracle.price0Average.mul(amountIn_).decode144();
        } else {
            _amountOut = _oracle.price1Average.mul(amountIn_).decode144();
        }
        _lastUpdatedAt = _oracle.blockTimestampLast;
    }

    /**
     * @notice Update an oracle
     * @param pair_ The pair to update
     * @param twapPeriod_ The TWAP period
     * @return True if updated was performed
     */
    function _updateIfNeeded(IUniswapV2Pair pair_, uint256 twapPeriod_) private returns (bool) {
        Oracle storage _oracle = oracles[pair_][twapPeriod_];

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary
            .currentCumulativePrices(address(pair_));
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - _oracle.blockTimestampLast; // overflow is desired
        }
        // ensure that at least one full period has passed since the last update
        if (timeElapsed < twapPeriod_) return false;

        uint256 price0new;
        uint256 price1new;

        unchecked {
            price0new = price0Cumulative - _oracle.price0CumulativeLast;
            price1new = price1Cumulative - _oracle.price1CumulativeLast;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        _oracle.price0Average = FixedPoint.uq112x112(uint224(price0new / timeElapsed));
        _oracle.price1Average = FixedPoint.uq112x112(uint224(price1new / timeElapsed));
        _oracle.price0CumulativeLast = price0Cumulative;
        _oracle.price1CumulativeLast = price1Cumulative;
        _oracle.blockTimestampLast = blockTimestamp;
        return true;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateDefaultTwapPeriod(uint256 newDefaultTwapPeriod_) external override onlyGovernor {
        emit DefaultTwapPeriodUpdated(defaultTwapPeriod, newDefaultTwapPeriod_);
        defaultTwapPeriod = newDefaultTwapPeriod_;
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

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IPriceProvider.sol";

interface IUniswapV2LikePriceProvider is IPriceProvider {
    /**
     * @notice The default time-weighted average price (TWAP) period
     * Used when a period isn't specified
     * @dev See more: https://docs.uniswap.org/protocol/concepts/V3-overview/oracle
     */
    function defaultTwapPeriod() external view returns (uint256);

    /**
     * @notice Check if there is an oracle for the PAIR-TWAP key
     * @param pair_ The pair
     * @param twapPeriod_ The TWAP period
     * @return True if exists
     */
    function hasOracle(IUniswapV2Pair pair_, uint256 twapPeriod_) external view returns (bool);

    /**
     * @notice Check if there is an oracle for the PAIR-TWAP key
     * @dev Uses `defaultTwapPeriod`
     * @param pair_ The pair
     * @return True if exists
     */
    function hasOracle(IUniswapV2Pair pair_) external view returns (bool);

    /**
     * @notice Returns the pair's contract
     */
    function pairFor(address token0_, address token1_) external view returns (IUniswapV2Pair _pair);

    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of assetIn
     * @param twapPeriod_ The TWAP period
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(address token_, uint256 twapPeriod_)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @param twapPeriod_ The TWAP period
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) external view returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetIn
     * @param amountIn_ Input amount in USD
     * @param twapPeriod_ The TWAP period
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @dev Will update the oracle if needed before getting quote
     * @dev Uses `defaultTwapPeriod`
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @dev Will update the oracle if needed before getting quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Update the default TWAP period
     * @dev Administrative function
     * @param newDefaultTwapPeriod_ The new default period
     */
    function updateDefaultTwapPeriod(uint256 newDefaultTwapPeriod_) external;

    /**
     * @notice Update cumulative and average price of pair
     * @dev Will create the pair if it doesn't exist
     * @dev Uses `defaultTwapPeriod`
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     */
    function updateOrAdd(address tokenIn_, address tokenOut_) external;

    /**
     * @notice Update cumulative and average price of pair
     * @dev Will create the pair if it doesn't exist
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     */
    function updateOrAdd(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_
    ) external;
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