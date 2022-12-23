/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @mimic-fi/v2-registry/contracts/implementations/[email protected]


pragma solidity >=0.8.0;

// solhint-disable func-name-mixedcase

/**
 * @title IImplementation
 * @dev Implementation interface that must be followed for implementations to be registered in the Mimic Registry
 */
interface IImplementation {
    /**
     * @dev Tells the namespace under which the implementation is registered in the Mimic Registry
     */
    function NAMESPACE() external view returns (bytes32);

    /**
     * @dev Tells the address of the Mimic Registry
     */
    function registry() external view returns (address);
}


// File @mimic-fi/v2-swap-connector/contracts/[email protected]


pragma solidity >=0.8.0;

/**
 * @title ISwapConnector
 * @dev Swap Connector interface to perform token swaps. It must follow the IImplementation interface.
 */
interface ISwapConnector is IImplementation {
    /**
     * @dev Enum identifying the sources proposed: Uniswap V2, Uniswap V3, Balancer V2, Paraswap V5, and 1inch V5.
     */
    enum Source {
        UniswapV2,
        UniswapV3,
        BalancerV2,
        ParaswapV5,
        OneInchV5
    }

    /**
     * @dev Swaps two tokens
     * @param source Source to execute the requested swap
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Encoded data to specify different swap parameters depending on the source picked
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data
    ) external returns (uint256 amountOut);
}


// File @mimic-fi/v2-helpers/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Denominations
 * @dev Provides a list of ground denominations for those tokens that cannot be represented by an ERC20.
 * For now, the only needed is the native token that could be ETH, MATIC, or other depending on the layer being operated.
 */
library Denominations {
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function isNativeToken(address token) internal pure returns (bool) {
        return token == NATIVE_TOKEN;
    }
}


// File @mimic-fi/v2-helpers/contracts/math/[email protected]


pragma solidity ^0.8.0;

/**
 * @title FixedPoint
 * @dev Math library to operate with fixed point values with 18 decimals
 */
library FixedPoint {
    // 1 in fixed point value: 18 decimal places
    uint256 internal constant ONE = 1e18;

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return ((aInflated - 1) / b) + 1;
        }
    }
}


// File @mimic-fi/v2-helpers/contracts/auth/[email protected]


pragma solidity >=0.8.0;

/**
 * @title IAuthorizer
 */
interface IAuthorizer {
    /**
     * @dev Emitted when an account is authorized to call a function
     */
    event Authorized(address indexed who, bytes4 what);

    /**
     * @dev Emitted when an account is unauthorized to call a function
     */
    event Unauthorized(address indexed who, bytes4 what);

    /**
     * @dev Authorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function authorize(address who, bytes4 what) external;

    /**
     * @dev Unauthorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, bytes4 what) external;

    /**
     * @dev Tells whether someone is allowed to call a function or not. It returns true if it's allowed to anyone.
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function isAuthorized(address who, bytes4 what) external view returns (bool);
}


// File @mimic-fi/v2-price-oracle/contracts/feeds/[email protected]


pragma solidity >=0.8.0;

/**
 * @title IPriceFeedProvider
 * @dev Contract providing price feed references for (base, quote) token pairs
 */
interface IPriceFeedProvider {
    /**
     * @dev Emitted every time a price feed is set for (base, quote) pair
     */
    event PriceFeedSet(address indexed base, address indexed quote, address feed);

    /**
     * @dev Tells the price feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getPriceFeed(address base, address quote) external view returns (address);

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed) external;

    /**
     * @dev Sets a list of price feeds
     * @param bases List of token bases to be set
     * @param quotes List of token quotes to be set
     * @param feeds List of price feeds to be set
     */
    function setPriceFeeds(address[] memory bases, address[] memory quotes, address[] memory feeds) external;
}


// File @mimic-fi/v2-smart-vault/contracts/[email protected]


pragma solidity ^0.8.0;



/**
 * @title ISmartVault
 * @dev Mimic Smart Vault interface to manage assets. It must support also `IImplementation` and `IAuthorizer`
 */
interface ISmartVault is IPriceFeedProvider, IImplementation, IAuthorizer {
    enum SwapLimit {
        Slippage,
        MinAmountOut
    }

    /**
     * @dev Emitted every time a new strategy is set for the Smart Vault
     */
    event StrategySet(address indexed strategy, bool allowed);

    /**
     * @dev Emitted every time a new price oracle is set for the Smart Vault
     */
    event PriceOracleSet(address indexed priceOracle);

    /**
     * @dev Emitted every time a new swap connector is set for the Smart Vault
     */
    event SwapConnectorSet(address indexed swapConnector);

    /**
     * @dev Emitted every time a new fee collector is set
     */
    event FeeCollectorSet(address indexed feeCollector);

    /**
     * @dev Emitted every time the withdraw fee percentage is set
     */
    event WithdrawFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time the performance fee percentage is set
     */
    event PerformanceFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time the swap fee percentage is set
     */
    event SwapFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time `call` is called
     */
    event Call(address indexed target, bytes callData, uint256 value, bytes result, bytes data);

    /**
     * @dev Emitted every time `collect` is called
     */
    event Collect(address indexed token, address indexed from, uint256 collected, bytes data);

    /**
     * @dev Emitted every time `withdraw` is called
     */
    event Withdraw(address indexed token, address indexed recipient, uint256 withdrawn, uint256 fee, bytes data);

    /**
     * @dev Emitted every time `wrap` is called
     */
    event Wrap(uint256 amount, uint256 wrapped, bytes data);

    /**
     * @dev Emitted every time `unwrap` is called
     */
    event Unwrap(uint256 amount, uint256 unwrapped, bytes data);

    /**
     * @dev Emitted every time `claim` is called
     */
    event Claim(address indexed strategy, address[] tokens, uint256[] amounts, bytes data);

    /**
     * @dev Emitted every time `join` is called
     */
    event Join(
        address indexed strategy,
        address[] tokensIn,
        uint256[] amountsIn,
        address[] tokensOut,
        uint256[] amountsOut,
        uint256 value,
        uint256 slippage,
        bytes data
    );

    /**
     * @dev Emitted every time `exit` is called
     */
    event Exit(
        address indexed strategy,
        address[] tokensIn,
        uint256[] amountsIn,
        address[] tokensOut,
        uint256[] amountsOut,
        uint256 value,
        uint256[] fees,
        uint256 slippage,
        bytes data
    );

    /**
     * @dev Emitted every time `swap` is called
     */
    event Swap(
        uint8 indexed source,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 minAmountOut,
        uint256 fee,
        bytes data
    );

    /**
     * @dev Tells a strategy is allowed or not
     * @param strategy Address of the strategy being queried
     */
    function isStrategyAllowed(address strategy) external view returns (bool);

    /**
     * @dev Tells the invested value for a strategy
     * @param strategy Address of the strategy querying the invested value of
     */
    function investedValue(address strategy) external view returns (uint256);

    /**
     * @dev Tells the last value accrued for a strategy. Note this value can be outdated.
     * @param strategy Address of the strategy querying the last value of
     */
    function lastValue(address strategy) external view returns (uint256);

    /**
     * @dev Tells the price oracle associated to a Smart Vault
     */
    function priceOracle() external view returns (address);

    /**
     * @dev Tells the swap connector associated to a Smart Vault
     */
    function swapConnector() external view returns (address);

    /**
     * @dev Tells the address where fees will be deposited
     */
    function feeCollector() external view returns (address);

    /**
     * @dev Tells the withdraw fee configuration
     */
    function withdrawFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the performance fee configuration
     */
    function performanceFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the swap fee configuration
     */
    function swapFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the address of the wrapped native token
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Sets a new strategy as allowed or not for a Smart Vault
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function setStrategy(address strategy, bool allowed) external;

    /**
     * @dev Sets a new price oracle to a Smart Vault
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @dev Sets a new swap connector to a Smart Vault
     * @param newSwapConnector Address of the new swap connector to be set
     */
    function setSwapConnector(address newSwapConnector) external;

    /**
     * @dev Sets a new fee collector
     * @param newFeeCollector Address of the new fee collector to be set
     */
    function setFeeCollector(address newFeeCollector) external;

    /**
     * @dev Sets a new withdraw fee configuration
     * @param pct Withdraw fee percentage to be set
     * @param cap New maximum amount of withdraw fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the withdraw fee
     */
    function setWithdrawFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Sets a new performance fee configuration
     * @param pct Performance fee percentage to be set
     * @param cap New maximum amount of performance fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the performance fee
     */
    function setPerformanceFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Sets a new swap fee configuration
     * @param pct Swap fee percentage to be set
     * @param cap New maximum amount of swap fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the swap fee
     */
    function setSwapFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Tells the price of a token (base) in a given quote
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) external view returns (uint256);

    /**
     * @dev Execute an arbitrary call from a Smart Vault
     * @param target Address where the call will be sent
     * @param callData Calldata to be used for the call
     * @param value Value in wei that will be attached to the call
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory callData, uint256 value, bytes memory data)
        external
        returns (bytes memory result);

    /**
     * @dev Collect tokens from a sender to a Smart Vault
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transfer from
     * @param amount Amount of tokens to be transferred
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return collected Amount of tokens assigned to the Smart Vault
     */
    function collect(address token, address from, uint256 amount, bytes memory data)
        external
        returns (uint256 collected);

    /**
     * @dev Withdraw tokens to an external account
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to withdraw
     * @param recipient Address where the tokens will be transferred to
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return withdrawn Amount of tokens transferred to the recipient address
     */
    function withdraw(address token, uint256 amount, address recipient, bytes memory data)
        external
        returns (uint256 withdrawn);

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it
     * @param amount Amount of native tokens to be wrapped
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return wrapped Amount of tokens wrapped
     */
    function wrap(uint256 amount, bytes memory data) external returns (uint256 wrapped);

    /**
     * @dev Unwrap an amount of wrapped native tokens
     * @param amount Amount of wrapped native tokens to unwrapped
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return unwrapped Amount of tokens unwrapped
     */
    function unwrap(uint256 amount, bytes memory data) external returns (uint256 unwrapped);

    /**
     * @dev Claim strategy rewards
     * @param strategy Address of the strategy to claim rewards
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokens Addresses of the tokens received as rewards
     * @return amounts Amounts of the tokens received as rewards
     */
    function claim(address strategy, bytes memory data)
        external
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @dev Join a strategy with an amount of tokens
     * @param strategy Address of the strategy to join
     * @param tokensIn List of token addresses to join with
     * @param amountsIn List of token amounts to join with
     * @param slippage Slippage that will be used to compute the join
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokensOut List of token addresses received after the join
     * @return amountsOut List of token amounts received after the join
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external returns (address[] memory tokensOut, uint256[] memory amountsOut);

    /**
     * @dev Exit a strategy
     * @param strategy Address of the strategy to exit
     * @param tokensIn List of token addresses to exit with
     * @param amountsIn List of token amounts to exit with
     * @param slippage Slippage that will be used to compute the exit
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokensOut List of token addresses received after the exit
     * @return amountsOut List of token amounts received after the exit
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external returns (address[] memory tokensOut, uint256[] memory amountsOut);

    /**
     * @dev Swaps two tokens
     * @param source Source to request the swap. It depends on the Swap Connector attached to a Smart Vault.
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param limitType Swap limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return amountOut Received amount of tokens out
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapLimit limitType,
        uint256 limitAmount,
        bytes memory data
    ) external returns (uint256 amountOut);
}


// File @mimic-fi/v2-helpers/contracts/auth/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Authorizer
 * @dev Authorization module to be used by contracts that need to implement permissions for their methods.
 * It provides a permissions model to list who is allowed to call what function in a contract. And only accounts
 * authorized to manage those permissions are the ones that are allowed to authorize or unauthorize accounts.
 */
contract Authorizer is IAuthorizer {
    // Constant used to denote that a permission is open to anyone
    address public constant ANY_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Internal mapping to tell who is allowed to do what indexed by (account, function selector)
    mapping (address => mapping (bytes4 => bool)) private authorized;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Tells whether someone is allowed to call a function or not. It returns true if it's allowed to anyone.
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function isAuthorized(address who, bytes4 what) public view override returns (bool) {
        return authorized[ANY_ADDRESS][what] || authorized[who][what];
    }

    /**
     * @dev Authorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function authorize(address who, bytes4 what) external override auth {
        _authorize(who, what);
    }

    /**
     * @dev Unauthorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, bytes4 what) external override auth {
        _unauthorize(who, what);
    }

    /**
     * @dev Internal function to authenticate someone over a function.
     * It reverts if the given account is not authorized to call the requested function.
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        require(isAuthorized(who, what), 'AUTH_SENDER_NOT_ALLOWED');
    }

    /**
     * @dev Internal function to authorize someone to call a function
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function _authorize(address who, bytes4 what) internal {
        authorized[who][what] = true;
        emit Authorized(who, what);
    }

    /**
     * @dev Internal function to unauthorize someone to call a function
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function _unauthorize(address who, bytes4 what) internal {
        authorized[who][what] = false;
        emit Unauthorized(who, what);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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


// File @mimic-fi/v2-registry/contracts/registry/[email protected]


pragma solidity >=0.8.0;

/**
 * @title IRegistry
 * @dev Registry interface, it must follow the IAuthorizer interface.
 */
interface IRegistry is IAuthorizer {
    /**
     * @dev Emitted every time a new implementation is registered
     */
    event Registered(bytes32 indexed namespace, address indexed implementation, bool stateless);

    /**
     * @dev Emitted every time an implementation is deprecated
     */
    event Deprecated(bytes32 indexed namespace, address indexed implementation);

    /**
     * @dev Emitted every time an implementation is cloned
     */
    event Cloned(bytes32 indexed namespace, address indexed implementation, address instance, bytes initResult);

    /**
     * @dev Tells the implementation associated to a contract instance
     * @param instance Address of the instance to request it's implementation
     */
    function implementationOf(address instance) external view returns (address);

    /**
     * @dev Tells the data of an implementation:
     * @param implementation Address of the implementation to request it's data
     */
    function implementationData(address implementation)
        external
        view
        returns (bool stateless, bool deprecated, bytes32 namespace);

    /**
     * @dev Tells if a specific implementation is registered under a certain namespace and it's not deprecated
     * @param namespace Namespace asking for
     * @param implementation Address of the implementation to be checked
     */
    function isActive(bytes32 namespace, address implementation) external view returns (bool);

    /**
     * @dev Registers a new implementation for a given namespace
     * @param namespace Namespace to be used for the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the implementation is stateless or not
     */
    function register(bytes32 namespace, address implementation, bool stateless) external;

    /**
     * @dev Deprecates a registered implementation
     * @param implementation Address of the implementation to be deprecated
     */
    function deprecate(address implementation) external;

    /**
     * @dev Clones a registered implementation
     * @param implementation Address of the implementation to be cloned
     * @param initializeData Arbitrary data to be sent after deployment
     * @return instance Address of the new instance created
     */
    function clone(address implementation, bytes memory initializeData) external returns (address);
}


// File @mimic-fi/v2-registry/contracts/implementations/[email protected]


pragma solidity ^0.8.0;


/**
 * @title BaseImplementation
 * @dev This implementation contract comes with an immutable reference to an implementations registry where it should
 * be registered as well (checked during initialization). It allows requesting new instances of other registered
 * implementations to as another safety check to make sure valid instances are referenced in case it's needed.
 */
abstract contract BaseImplementation is IImplementation {
    // Immutable implementations registry reference
    address public immutable override registry;

    /**
     * @dev Creates a new BaseImplementation
     * @param _registry Address of the Mimic Registry where dependencies will be validated against
     */
    constructor(address _registry) {
        registry = _registry;
    }

    /**
     * @dev Internal function to validate a new dependency that must be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and stateless.
     * @param dependency New stateless dependency to be set
     */
    function _validateStatelessDependency(address dependency) internal view {
        require(_validateDependency(dependency), 'DEPENDENCY_NOT_STATELESS');
    }

    /**
     * @dev Internal function to validate a new dependency that cannot be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and not stateful.
     * @param dependency New stateful dependency to be set
     */
    function _validateStatefulDependency(address dependency) internal view {
        require(!_validateDependency(dependency), 'DEPENDENCY_NOT_STATEFUL');
    }

    /**
     * @dev Internal function to validate a new dependency. It checks the dependency is registered and not deprecated.
     * @param dependency New dependency to be set
     * @return Whether the dependency is stateless or not
     */
    function _validateDependency(address dependency) private view returns (bool) {
        // If there is an implementation registered for the dependency, check the dependency as an instance.
        // Otherwise, treat the dependency as an implementation.
        address dependencyImplementation = IRegistry(registry).implementationOf(dependency);
        address implementation = dependencyImplementation != address(0) ? dependencyImplementation : dependency;

        (bool stateless, bool deprecated, bytes32 namespace) = IRegistry(registry).implementationData(implementation);
        require(namespace != bytes32(0), 'DEPENDENCY_NOT_REGISTERED');
        require(!deprecated, 'DEPENDENCY_DEPRECATED');
        return stateless;
    }
}


// File @mimic-fi/v2-registry/contracts/implementations/[email protected]


pragma solidity ^0.8.0;

/**
 * @title BaseAuthorizedImplementation
 * @dev BaseImplementation using the Authorizer mixin. Base implementations that want to use the Authorizer
 * permissions mechanism should inherit from this contract instead.
 */
abstract contract BaseAuthorizedImplementation is BaseImplementation, Authorizer {
    /**
     * @dev Creates a new BaseAuthorizedImplementation
     * @param admin Address to be granted authorize and unauthorize permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseImplementation(registry) {
        _authorize(admin, Authorizer.authorize.selector);
        _authorize(admin, Authorizer.unauthorize.selector);
    }
}


// File @mimic-fi/v2-smart-vaults-base/contracts/actions/[email protected]


pragma solidity >=0.8.0;


/**
 * @title IAction
 * @dev Action interface it must follow the IAuthorizer interface
 */
interface IAction is IAuthorizer {
    /**
     * @dev Emitted every time an action is executed
     */
    event Executed();

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (ISmartVault);
}


// File @mimic-fi/v2-smart-vaults-base/contracts/actions/[email protected]


pragma solidity ^0.8.0;




/**
 * @title BaseAction
 * @dev Simple action implementation with a Smart Vault reference and using the Authorizer mixin
 */
contract BaseAction is IAction, BaseAuthorizedImplementation {
    bytes32 public constant override NAMESPACE = keccak256('ACTION');

    // Smart Vault reference
    ISmartVault public override smartVault;

    /**
     * @dev Emitted every time a new smart vault is set
     */
    event SmartVaultSet(address indexed smartVault);

    /**
     * @dev Creates a new BaseAction
     * @param admin Address to be granted authorize and unauthorize permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseAuthorizedImplementation(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets the Smart Vault tied to the Action. Sender must be authorized. It can be set only once.
     * @param newSmartVault Address of the smart vault to be set
     */
    function setSmartVault(address newSmartVault) external auth {
        require(address(smartVault) == address(0), 'SMART_VAULT_ALREADY_SET');
        _validateStatefulDependency(newSmartVault);
        smartVault = ISmartVault(newSmartVault);
        emit SmartVaultSet(newSmartVault);
    }

    function _balanceOf(address token) internal view returns (uint256) {
        bool isNative = Denominations.isNativeToken(token);
        return isNative ? address(smartVault).balance : IERC20(token).balanceOf(address(smartVault));
    }

    function _isWrappedOrNativeToken(address token) internal view returns (bool) {
        return Denominations.isNativeToken(token) || token == smartVault.wrappedNativeToken();
    }
}


// File @mimic-fi/v2-smart-vaults-base/contracts/actions/[email protected]


pragma solidity ^0.8.0;

/**
 * @title TokenThresholdAction
 * @dev Action that offers a token threshold limit. It can be used for minimum swap amounts, or minimum withdrawal
 * amounts, etc. This type of action does not require any specific permission on the Smart Vault.
 */
abstract contract TokenThresholdAction is BaseAction {
    using FixedPoint for uint256;

    address public thresholdToken;
    uint256 public thresholdAmount;

    event ThresholdSet(address indexed token, uint256 amount);

    /**
     * @dev Sets a new threshold configuration. Sender must be authorized.
     * @param token New token threshold to be set
     * @param amount New amount threshold to be set
     */
    function setThreshold(address token, uint256 amount) external auth {
        thresholdToken = token;
        thresholdAmount = amount;
        emit ThresholdSet(token, amount);
    }

    /**
     * @dev Internal function to check the set threshold
     * @param token Token address of the given amount to evaluate the threshold
     * @param amount Amount of tokens to validate the threshold
     */
    function _passesThreshold(address token, uint256 amount) internal view returns (bool) {
        uint256 price = smartVault.getPrice(token, thresholdToken);
        // Result balance is rounded down to make sure we always match at least the threshold
        return amount.mulDown(price) >= thresholdAmount;
    }

    /**
     * @dev Internal function to validate the set threshold
     * @param token Token address of the given amount to evaluate the threshold
     * @param amount Amount of tokens to validate the threshold
     */
    function _validateThreshold(address token, uint256 amount) internal view {
        require(_passesThreshold(token, amount), 'MIN_THRESHOLD_NOT_MET');
    }
}


// File @mimic-fi/v2-smart-vaults-base/contracts/actions/[email protected]


pragma solidity ^0.8.0;


/**
 * @title RelayedAction
 * @dev Action that offers a relayed mechanism to allow reimbursing tx costs after execution in any ERC20 token.
 * This type of action at least require having withdraw permissions from the Smart Vault tied to it.
 */
abstract contract RelayedAction is BaseAction {
    using FixedPoint for uint256;

    // Base gas amount charged to cover default amounts
    // solhint-disable-next-line func-name-mixedcase
    function BASE_GAS() external view virtual returns (uint256);

    // Note to be used to mark tx cost payments
    bytes private constant REDEEM_GAS_NOTE = bytes('RELAYER');

    // Internal variable used to allow a better developer experience to reimburse tx gas cost
    uint256 internal _initialGas;

    // Allows relaying transactions even if there is not enough balance in the Smart Vault to pay for the tx gas cost
    bool public isPermissiveModeActive;

    // Gas price limit, if surpassed it wont relay the transaction
    uint256 public gasPriceLimit;

    // Total cost limit expressed in `payingGasToken`, if surpassed it wont relay the transaction
    uint256 public totalCostLimit;

    // Address of the ERC20 token that will be used to pay the total tx cost
    address public payingGasToken;

    // List of allowed relayers indexed by address
    mapping (address => bool) public isRelayer;

    /**
     * @dev Emitted every time the permissive mode is changed
     */
    event PermissiveModeSet(bool active);

    /**
     * @dev Emitted every time the relayers list is changed
     */
    event RelayerSet(address indexed relayer, bool allowed);

    /**
     * @dev Emitted every time the relayer limits are set
     */
    event LimitsSet(uint256 gasPriceLimit, uint256 totalCostLimit, address payingGasToken);

    /**
     * @dev Modifier that can be used to reimburse the gas cost of the tagged function
     */
    modifier redeemGas() {
        _beforeCall();
        _;
        _afterCall();
    }

    /**
     * @dev Sets the relayed action permissive mode. If active,  relayer address. Sender must be authorized.
     * @param active Whether the permissive mode should be active or not
     */
    function setPermissiveMode(bool active) external auth {
        isPermissiveModeActive = active;
        emit PermissiveModeSet(active);
    }

    /**
     * @dev Sets a relayer address. Sender must be authorized.
     * @param relayer Address of the relayer to be set
     * @param allowed Whether it should be allowed or not
     */
    function setRelayer(address relayer, bool allowed) external auth {
        isRelayer[relayer] = allowed;
        emit RelayerSet(relayer, allowed);
    }

    /**
     * @dev Sets the relayer limits. Sender must be authorized.
     * @param _gasPriceLimit New gas price limit to be set
     * @param _totalCostLimit New total cost limit to be set
     * @param _payingGasToken New paying gas token to be set
     */
    function setLimits(uint256 _gasPriceLimit, uint256 _totalCostLimit, address _payingGasToken) external auth {
        require(_payingGasToken != address(0), 'PAYING_GAS_TOKEN_ZERO');
        gasPriceLimit = _gasPriceLimit;
        totalCostLimit = _totalCostLimit;
        payingGasToken = _payingGasToken;
        emit LimitsSet(_gasPriceLimit, _totalCostLimit, _payingGasToken);
    }

    /**
     * @dev Internal before call hook where limit validations are checked
     */
    function _beforeCall() internal {
        _initialGas = gasleft();
        require(isRelayer[msg.sender], 'SENDER_NOT_RELAYER');
        uint256 limit = gasPriceLimit;
        require(limit == 0 || tx.gasprice <= limit, 'GAS_PRICE_ABOVE_LIMIT');
    }

    /**
     * @dev Internal after call hook where tx cost is reimburse
     */
    function _afterCall() internal {
        uint256 totalGas = _initialGas - gasleft();
        uint256 totalCostNative = (totalGas + RelayedAction(this).BASE_GAS()) * tx.gasprice;

        uint256 limit = totalCostLimit;
        address payingToken = payingGasToken;
        // Total cost is rounded down to make sure we always match at least the threshold
        uint256 totalCostToken = totalCostNative.mulDown(_getPayingGasTokenPrice(payingToken));
        require(limit == 0 || totalCostToken <= limit, 'TX_COST_ABOVE_LIMIT');

        if (_shouldTryRedeemFromSmartVault(payingToken, totalCostToken)) {
            smartVault.withdraw(payingToken, totalCostToken, smartVault.feeCollector(), REDEEM_GAS_NOTE);
        }

        delete _initialGas;
    }

    /**
     * @dev Internal function to fetch the paying gas token rate from the Smart Vault's price oracle
     */
    function _getPayingGasTokenPrice(address token) private view returns (uint256) {
        bool isUsingNativeToken = _isWrappedOrNativeToken(token);
        return isUsingNativeToken ? FixedPoint.ONE : smartVault.getPrice(smartVault.wrappedNativeToken(), token);
    }

    /**
     * @dev Internal function to tell if the relayed action should try to redeem the gas cost from the Smart Vault
     * @param token Address of the token to pay the relayed gas cost
     * @param amount Amount of tokens to pay for the relayed gas cost
     */
    function _shouldTryRedeemFromSmartVault(address token, uint256 amount) private view returns (bool) {
        if (!isPermissiveModeActive) return true;
        return _balanceOf(token) >= amount;
    }
}


// File contracts/actions/BaseSwapper.sol


pragma solidity ^0.8.0;





abstract contract BaseSwapper is BaseAction, TokenThresholdAction, RelayedAction {
    address public tokenIn;
    address public tokenOut;
    uint256 public maxSlippage;

    event TokenInSet(address indexed tokenIn);
    event TokenOutSet(address indexed tokenOut);
    event MaxSlippageSet(uint256 maxSlippage);

    function setTokenIn(address token) external auth {
        require(token == address(0) || token != tokenOut, 'SWAPPER_TOKEN_IN_EQ_OUT');
        tokenIn = token;
        emit TokenInSet(token);
    }

    function setTokenOut(address token) external auth {
        require(token == address(0) || token != tokenIn, 'SWAPPER_TOKEN_OUT_EQ_IN');
        tokenOut = token;
        emit TokenOutSet(token);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'SWAPPER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }
}


// File @mimic-fi/v2-helpers/contracts/math/[email protected]


pragma solidity ^0.8.0;

/**
 * @title UncheckedMath
 * @dev Math library to perform unchecked operations
 */
library UncheckedMath {
    /**
     * @dev Unsafely adds two unsigned integers
     */
    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    /**
     * @dev Unsafely subtracts two unsigned integers
     */
    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    /**
     * @dev Unsafely multiplies two unsigned integers
     */
    function uncheckedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a * b;
        }
    }

    /**
     * @dev Unsafely multiplies two signed integers
     */
    function uncheckedMul(int256 a, int256 b) internal pure returns (int256) {
        unchecked {
            return a * b;
        }
    }

    /**
     * @dev Unsafely divides two unsigned integers
     */
    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a / b;
        }
    }
}


// File contracts/actions/OTCSwapper.sol


pragma solidity ^0.8.0;


contract OTCSwapper is BaseSwapper {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 60e3;

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getAmountOut(uint256 amountIn) external view returns (uint256) {
        return _calcAmountOut(amountIn);
    }

    function canExecute(uint256 amountIn, uint256 minAmountOut) external view returns (bool) {
        uint256 amountOut = _calcAmountOut(amountIn);
        return
            tokenIn != address(0) &&
            tokenOut != address(0) &&
            amountOut >= minAmountOut &&
            _passesThreshold(tokenOut, amountOut);
    }

    function call(uint256 amountIn, uint256 minAmountOut) external auth {
        (isRelayer[msg.sender] ? _relayedCall : _call)(amountIn, minAmountOut);
    }

    function _relayedCall(uint256 amountIn, uint256 minAmountOut) internal redeemGas {
        _call(amountIn, minAmountOut);
    }

    function _call(uint256 amountIn, uint256 minAmountOut) internal {
        require(tokenIn != address(0), 'SWAPPER_TOKEN_IN_NOT_SET');
        require(tokenOut != address(0), 'SWAPPER_TOKEN_OUT_NOT_SET');

        uint256 amountOut = _calcAmountOut(amountIn);
        require(amountOut >= minAmountOut, 'SWAPPER_MIN_AMOUNT_OUT');
        _validateThreshold(tokenOut, amountOut);

        smartVault.collect(tokenIn, msg.sender, amountIn, new bytes(0));
        smartVault.withdraw(tokenOut, amountOut, msg.sender, new bytes(0));
        emit Executed();
    }

    function _calcAmountOut(uint256 amountIn) internal view returns (uint256) {
        uint256 price = smartVault.getPrice(tokenIn, tokenOut);
        uint256 amountOut = amountIn.mulDown(price);
        return amountOut.mulDown(FixedPoint.ONE.uncheckedAdd(maxSlippage));
    }
}