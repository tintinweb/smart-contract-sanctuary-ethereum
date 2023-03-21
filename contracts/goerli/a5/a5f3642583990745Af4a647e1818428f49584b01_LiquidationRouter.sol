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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./libraries/LiquidatorLib.sol";
import "./libraries/FixedMathLib.sol";
import "./interfaces/ILiquidationSource.sol";

contract LiquidationPair {
    /* ============ Variables ============ */
    ILiquidationSource public immutable source; // Where to get tokenIn from
    address public immutable tokenIn; // Token being sent into the Liquidator Pair by the user(ex. POOL)
    address public immutable tokenOut; // Token being sent out of the Liquidation Pair to the user(ex. USDC, WETH, etc.)
    UFixed32x9 public immutable swapMultiplier; // 9 decimals
    UFixed32x9 public immutable liquidityFraction; // 9 decimals

    uint128 public virtualReserveIn;
    uint128 public virtualReserveOut;

    /* ============ Events ============ */
    event Swapped(address indexed account, uint256 amountIn, uint256 amountOut);

    /* ============ Constructor ============ */

    constructor(
        ILiquidationSource _source,
        address _tokenIn,
        address _tokenOut,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction,
        uint128 _virtualReserveIn,
        uint128 _virtualReserveOut
    ) {
        require(UFixed32x9.unwrap(_liquidityFraction) > 0, "LiquidationPair/liquidity-fraction-greater-than-zero");
        require(UFixed32x9.unwrap(_swapMultiplier) <= 1e9, "LiquidationPair/swap-multiplier-less-than-one");
        require(UFixed32x9.unwrap(_liquidityFraction) <= 1e9, "LiquidationPair/liquidity-fraction-less-than-one");
        source = _source;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        swapMultiplier = _swapMultiplier;
        liquidityFraction = _liquidityFraction;
        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;
    }

    /* ============ External Function ============ */

    function maxAmountOut() external returns (uint256) {
        return _availableReserveOut();
    }

    function _availableReserveOut() internal returns (uint256) {
        return source.availableBalanceOf(tokenOut);
    }

    function nextLiquidationState() external returns (uint128, uint128) {
        return LiquidatorLib.virtualBuyback(virtualReserveIn, virtualReserveOut, _availableReserveOut());
    }

    function computeExactAmountIn(uint256 _amountOut) external returns (uint256) {
        return
            LiquidatorLib.computeExactAmountIn(virtualReserveIn, virtualReserveOut, _availableReserveOut(), _amountOut);
    }

    function computeExactAmountOut(uint256 _amountIn) external returns (uint256) {
        return
            LiquidatorLib.computeExactAmountOut(virtualReserveIn, virtualReserveOut, _availableReserveOut(), _amountIn);
    }

    function swapExactAmountIn(address _account, uint256 _amountIn, uint256 _amountOutMin) external returns (uint256) {
        uint256 availableBalance = _availableReserveOut();
        (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountOut) = LiquidatorLib.swapExactAmountIn(
            virtualReserveIn, virtualReserveOut, availableBalance, _amountIn, swapMultiplier, liquidityFraction
        );

        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;

        require(amountOut >= _amountOutMin, "LiquidationPair/min-not-guaranteed");
        _swap(_account, amountOut, _amountIn);

        emit Swapped(_account, _amountIn, amountOut);

        return amountOut;
    }

    function swapExactAmountOut(address _account, uint256 _amountOut, uint256 _amountInMax) external returns (uint256) {
        uint256 availableBalance = _availableReserveOut();
        (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountIn) = LiquidatorLib.swapExactAmountOut(
            virtualReserveIn, virtualReserveOut, availableBalance, _amountOut, swapMultiplier, liquidityFraction
        );
        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;
        require(amountIn <= _amountInMax, "LiquidationPair/max-not-guaranteed");
        _swap(_account, _amountOut, amountIn);

        emit Swapped(_account, amountIn, _amountOut);

        return amountIn;
    }

    /**
     * @notice Get the address that will receive `tokenIn`.
     * @return address Address of the target
     */
    function target() external returns(address) {
        return source.targetOf(tokenIn);
    }

    /* ============ Internal Functions ============ */

    // Note: Uniswap has restrictions on _account, but we don't
    // Note: Uniswap requires _amountOut to be > 0, but we don't
    function _swap(address _account, uint256 _amountOut, uint256 _amountIn) internal {
        source.liquidate(_account, tokenIn, _amountIn, tokenOut, _amountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./LiquidationPair.sol";

contract LiquidationPairFactory {

    /* ============ Events ============ */
    event PairCreated(
        LiquidationPair indexed liquidator,
        ILiquidationSource indexed source,
        address indexed tokenIn,
        address tokenOut,
        UFixed32x9 swapMultiplier,
        UFixed32x9 liquidityFraction,
        uint128 virtualReserveIn,
        uint128 virtualReserveOut
    );

    /* ============ Variables ============ */
    LiquidationPair[] public allPairs;

    /* ============ Mappings ============ */

    /**
     * @notice Mapping to verify if a LiquidationPair has been deployed via this factory.
     * @dev LiquidationPair address => boolean
     */
    mapping(LiquidationPair => bool) public deployedPairs;

    /* ============ External Functions ============ */
    function createPair(
        ILiquidationSource _source,
        address _tokenIn,
        address _tokenOut,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction,
        uint128 _virtualReserveIn,
        uint128 _virtualReserveOut
    ) external returns (LiquidationPair) {
        LiquidationPair _liquidationPair = new LiquidationPair(
            _source,
            _tokenIn,
            _tokenOut,
            _swapMultiplier,
            _liquidityFraction,
            _virtualReserveIn,
            _virtualReserveOut
        );

        allPairs.push(_liquidationPair);
        deployedPairs[_liquidationPair] = true;

        emit PairCreated(
            _liquidationPair,
            _source,
            _tokenIn,
            _tokenOut,
            _swapMultiplier,
            _liquidityFraction,
            _virtualReserveIn,
            _virtualReserveOut
            );

        return _liquidationPair;
    }

    /**
     * @notice Total number of LiquidationPair deployed by this factory.
     * @return Number of LiquidationPair deployed by this factory.
     */
    function totalPairs() external view returns (uint256) {
        return allPairs.length;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { LiquidationPair } from "./LiquidationPair.sol";
import { LiquidationPairFactory } from "./LiquidationPairFactory.sol";

contract LiquidationRouter {
  using SafeERC20 for IERC20;

  /* ============ Events ============ */
  event LiquidationRouterCreated(
    LiquidationPairFactory indexed liquidationPairFactory
  );

  /* ============ Variables ============ */
  LiquidationPairFactory internal immutable _liquidationPairFactory;

  /* ============ Constructor ============ */
  constructor(
    LiquidationPairFactory liquidationPairFactory_
  ) {
    require(address(liquidationPairFactory_) != address(0), "LR/LPF-not-address-zero");
    _liquidationPairFactory = liquidationPairFactory_;

    emit LiquidationRouterCreated(liquidationPairFactory_);
  }

  function swapExactAmountIn(
    LiquidationPair _liquidationPair,
    address _account,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) external returns (uint256) {
    IERC20(_liquidationPair.tokenIn()).safeTransferFrom(_account, _liquidationPair.target(), _amountIn);

    return _liquidationPair.swapExactAmountIn(_account, _amountIn, _amountOutMin);
  }

  function swapExactAmountOut(
    LiquidationPair _liquidationPair,
    address _account,
    uint256 _amountOut,
    uint256 _amountInMax
  ) external returns (uint256) {
    IERC20(_liquidationPair.tokenIn()).safeTransferFrom(
      _account,
      _liquidationPair.target(),
      _liquidationPair.computeExactAmountIn(_amountOut)
    );

    return _liquidationPair.swapExactAmountOut(_account, _amountOut, _amountInMax);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface ILiquidationSource {
    /**
     * @notice Get the available amount of tokens that can be swapped.
     * @param tokenOut Address of the token to get available balance for
     * @return uint256 Available amount of `token`
     */
    function availableBalanceOf(address tokenOut) external returns (uint256);

    /**
     * @notice Liquidate `amountIn` of `tokenIn` for `amountOut` of `tokenOut` and transfer to `account`.
     * @param account Address of the account that will receive `tokenOut`
     * @param tokenIn Address of the token being sold
     * @param amountIn Amount of token being sold
     * @param tokenOut Address of the token being bought
     * @param amountOut Amount of token being bought
     * @return bool Return true once the liquidation has been completed
     */
    function liquidate(
        address account,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    ) external returns (bool);

    /**
     * @notice Get the address that will receive `tokenIn`.
     * @param tokenIn Address of the token to get the target address for
     * @return address Address of the target
     */
    function targetOf(address tokenIn) external returns(address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

type UFixed32x9 is uint32;

/// A minimal library to do fixed point operations on UFixed32x9.
library FixedMathLib {
    uint256 constant multiplier = 1e9;

    function mul(uint256 a, UFixed32x9 b) internal pure returns (uint256) {
        require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
        return a * UFixed32x9.unwrap(b) / multiplier;
    }

    function div(uint256 a, UFixed32x9 b) internal pure returns (uint256) {
        require(UFixed32x9.unwrap(b) > 0, "FixedMathLib/b-greater-than-zero");
        require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
        return a * multiplier / UFixed32x9.unwrap(b);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./FixedMathLib.sol";

/**
 * @title PoolTogether Liquidator Library
 * @author PoolTogether Inc. Team
 * @notice
 */
library LiquidatorLib {
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn1, uint128 reserve1, uint128 reserve0)
        internal
        pure
        returns (uint256 amountOut0)
    {
        require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity");
        uint256 numerator = amountIn1 * reserve0;
        uint256 denominator = amountIn1 + reserve1;
        amountOut0 = numerator / denominator;
        require(amountOut0 < reserve0, "LiquidatorLib/insufficient-reserve-liquidity");
        // require(amountOut0 > 0, "LiquidatorLib/insufficient-amount-out");
        return amountOut0;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut0, uint128 reserve1, uint128 reserve0)
        internal
        pure
        returns (uint256 amountIn1)
    {
        // require(amountOut0 > 0, "LiquidatorLib/insufficient-amount-out");
        require(amountOut0 < reserve0, "LiquidatorLib/insufficient-reserve-liquidity");
        require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity");
        uint256 numerator = amountOut0 * reserve1;
        uint256 denominator = uint256(reserve0) - amountOut0;
        amountIn1 = (numerator / denominator);
    }

    function virtualBuyback(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1)
        internal
        pure
        returns (uint128 reserve0, uint128 reserve1)
    {
        // swap back yield
        uint256 amountOut0 = getAmountOut(_amountIn1, _reserve1, _reserve0);
        reserve0 = _reserve0 - uint128(amountOut0); // Note: Safe: amountOut0 < reserve0
        reserve1 = _reserve1 + uint128(_amountIn1); // Note: Potential overflow
    }

    function computeExactAmountIn(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1, uint256 _amountOut1)
        internal
        pure
        returns (uint256)
    {
        require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        (uint128 reserve0, uint128 reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);
        return getAmountIn(_amountOut1, reserve0, reserve1);
    }

    function computeExactAmountOut(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1, uint256 _amountIn0)
        internal
        pure
        returns (uint256)
    {
        (uint128 reserve0, uint128 reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);

        uint256 amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
        require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        return amountOut1;
    }

    function swapExactAmountIn(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountIn0,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountOut1) {
        (reserve0, reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);

        // do swap
        amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
        require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        reserve0 = reserve0 + uint128(_amountIn0); // Note: Potential overflow
        reserve1 = reserve1 - uint128(amountOut1); // Note: Safe: amountOut1 < reserve1

        (reserve0, reserve1) =
            _virtualSwap(reserve0, reserve1, _amountIn1, amountOut1, _swapMultiplier, _liquidityFraction);
    }

    function swapExactAmountOut(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountOut1,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountIn0) {

        require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        (reserve0, reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);


        // do swap
        amountIn0 = getAmountIn(_amountOut1, reserve0, reserve1);
        reserve0 = reserve0 + uint128(amountIn0); // Note: Potential overflow
        reserve1 = reserve1 - uint128(_amountOut1); // Note: Safe: _amountOut1 < reserve1

        (reserve0, reserve1) =
            _virtualSwap(reserve0, reserve1, _amountIn1, _amountOut1, _swapMultiplier, _liquidityFraction);
    }

    function _virtualSwap(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountOut1,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1) {
        uint256 virtualAmountOut1 = FixedMathLib.mul(_amountOut1, _swapMultiplier);
        // NEED THIS TO BE GREATER THAN 0 for getAmountIn!
        // Effectively a minimum of 1e9 going out to the user?

        uint256 virtualAmountIn0 = getAmountIn(virtualAmountOut1, _reserve0, _reserve1);

        reserve0 = _reserve0 + uint128(virtualAmountIn0); // Note: Potential overflow
        reserve1 = _reserve1 - uint128(virtualAmountOut1); // Note: Potential underflow after sub


        // now, we want to ensure that the accrued yield is always a small fraction of virtual LP position.\
        uint256 reserveFraction = (_amountIn1 * 1e9) / reserve1;
        uint256 multiplier = FixedMathLib.div(reserveFraction, _liquidityFraction);
        reserve0 = uint128((uint256(reserve0) * multiplier) / 1e9); // Note: Safe cast
        reserve1 = uint128((uint256(reserve1) * multiplier) / 1e9); // Note: Safe cast
    }
}

// reserve1 of 2381976568565668072671905656
// rf of 2857142857
// multiplier of 142857142850