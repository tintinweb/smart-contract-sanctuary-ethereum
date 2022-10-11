// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseConvert } from "../BaseConvert.sol";
import { ICurveInt128 } from "../../interfaces/CurvePools/ICurveInt128.sol";
import { SafeMath } from "@openzeppelin/contracts-new/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts-new/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts-new/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract ConvertUSDCMainnet is BaseConvert {
  using SafeMath for *;
  using SafeERC20 for IERC20;
  uint256 constant _maxBurnGas = 10000;
  uint256 constant _maxLoanGas = 10000;
  uint256 constant _maxRepayGas = 10000;

  address constant renCrv = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  uint24 constant wethWbtcFee = 500;
  uint24 constant usdcWethFee = 500;
  ISwapRouter constant routerV3 = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  constructor(address asset) BaseConvert(asset) {}

  function initialize() public override {
    IERC20(asset).approve(address(renCrv), ~uint256(1) << 2);
    IERC20(wbtc).approve(address(routerV3), ~uint256(1) << 2);
  }

  function swap(ConvertLocals memory locals) internal override returns (uint256 amountOut) {
    uint256 wbtcAmountOut = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(ICurveInt128.exchange.selector, 0, 1, locals.amount, 1));
    require(success, "!curve wbtc");
    wbtcAmountOut = IERC20(wbtc).balanceOf(address(this)) - wbtcAmountOut;
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, usdcWethFee, usdc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: locals.borrower,
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountOut,
      amountOutMinimum: locals.minOut,
      path: path
    });
    amountOut = routerV3.exactInput(params);
  }

  function swapBack(ConvertLocals memory locals) internal override returns (uint256 amountOut) {
    //no-op
  }

  function transfer(address to, uint256 amount) internal override {
    //no-op
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { BaseModule } from "../erc4626/BaseModule.sol";

abstract contract BaseConvert is BaseModule {
  constructor(address asset) BaseModule(asset) {}

  function _receiveLoan(
    address borrower,
    uint256 amount,
    uint256 nonce,
    bytes calldata data
  ) internal override returns (uint256 collateralIssued) {
    ConvertLocals memory locals;
    locals.borrower = borrower;
    locals.amount = amount;
    if (data.length > 0) (locals.minOut) = abi.decode(data, (uint256));
    collateralIssued = swap(locals);
    transfer(borrower, collateralIssued);
  }

  function _repayLoan(
    address,
    uint256,
    uint256,
    bytes calldata
  ) internal override returns (uint256) {
    //no-op
    return 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveInt128 {
  function get_dy(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(int128) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import { FixedPointMathLib } from "./utils/FixedPointMathLib.sol";
import "./utils/ModuleStateCoder.sol";
import { ZeroBTCStorage } from "./storage/ZeroBTCStorage.sol";

/**
 * @notice Base contract that must be inherited by all modules.
 */
abstract contract BaseModule is ZeroBTCStorage {
  using ModuleStateCoder for ModuleState;
  using FixedPointMathLib for uint256;

  /// @notice Base asset of the vault which is calling the module.
  /// This value is private because it is read only to the module.
  address public immutable asset;

  /// @notice Isolated storage pointer for any data that the module must write
  /// Use like so:
  address internal immutable _moduleSlot;

  constructor(address _asset) {
    asset = _asset;
    _moduleSlot = address(this);
  }

  function initialize() external virtual {}

  function _getModuleState() internal returns (ModuleState moduleState) {
    moduleState = _moduleFees[_moduleSlot];
  }

  /**
   * @notice Repays a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToUnlock` should be equal to `repaidAmount` unless the vault
   * has less than 100% collateralization or the loan is underpaid.
   *
   * @param borrower Recipient of the loan
   * @param repaidAmount Amount of `asset` being repaid.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToUnlock Amount of collateral to unlock for the lender.
   */
  function repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToUnlock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToUnlock = _repayLoan(borrower, repaidAmount, loanId, data);
  }

  /**
   * @notice Take out a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToLock` should be equal to `borrowAmount` unless the vault
   * has less than 100% collateralization.
   *
   * @param borrower Recipient of the loan
   * @param borrowAmount Amount of `asset` being borrowed.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToLock Amount of collateral to lock for the lender.
   */
  function receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToLock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToLock = _receiveLoan(borrower, borrowAmount, loanId, data);
  }

  struct ConvertLocals {
    address borrower;
    uint256 minOut;
    uint256 amount;
    uint256 nonce;
  }

  /* ---- Override These In Child ---- */
  function swap(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function swapBack(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function transfer(address to, uint256 amount) internal virtual;

  function _receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToLock);

  function _repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToUnlock);

  /* ---- Leave Empty For Now ---- */

  /// @notice Return recent average gas price in wei per unit of gas
  function getGasPrice() internal view virtual returns (uint256) {
    return 1;
  }

  /// @notice Get current price of ETH in terms of `asset`
  function getEthPrice() internal view virtual returns (uint256) {
    return 1;
  }
}

contract ABC {
  function x(uint256 a) external pure {
    assembly {
      a := or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), shr(96, a))))))
    }
  }
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
  }

  /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // First, divide z - 1 by the denominator and add 1.
      // We allow z - 1 to underflow if z is 0, because we multiply the
      // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function divUp(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uint256 z)
  {
    assembly {
      // Equivalent to require(denominator != 0)
      if iszero(denominator) {
        revert(0, 0)
      }

      // First, divide numerator - 1 by the denominator and add 1.
      // We allow z - 1 to underflow if z is 0, because we multiply the
      // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(
        iszero(iszero(numerator)),
        add(div(sub(numerator, 1), denominator), 1)
      )
    }
  }

  function rpow(
    uint256 x,
    uint256 n,
    uint256 scalar
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          // 0 ** 0 = 1
          z := scalar
        }
        default {
          // 0 ** n = 0
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          // If n is even, store scalar in z for now.
          z := scalar
        }
        default {
          // If n is odd, store x in z for now.
          z := x
        }

        // Shifting right by 1 is like dividing by 2.
        let half := shr(1, scalar)

        for {
          // Shift n right by 1 before looping to halve it.
          n := shr(1, n)
        } n {
          // Shift n right by 1 each iteration to halve it.
          n := shr(1, n)
        } {
          // Revert immediately if x ** 2 would overflow.
          // Equivalent to iszero(eq(div(xx, x), x)) here.
          if shr(128, x) {
            revert(0, 0)
          }

          // Store x squared.
          let xx := mul(x, x)

          // Round to the nearest number.
          let xxRound := add(xx, half)

          // Revert if xx + half overflowed.
          if lt(xxRound, xx) {
            revert(0, 0)
          }

          // Set x to scaled xxRound.
          x := div(xxRound, scalar)

          // If n is even:
          if mod(n, 2) {
            // Compute z * x.
            let zx := mul(z, x)

            // If z * x overflowed:
            if iszero(eq(div(zx, x), z)) {
              // Revert if x is non-zero.
              if iszero(iszero(x)) {
                revert(0, 0)
              }
            }

            // Round to the nearest number.
            let zxRound := add(zx, half)

            // Revert if zx + half overflowed.
            if lt(zxRound, zx) {
              revert(0, 0)
            }

            // Return properly scaled zxRound.
            z := div(zxRound, scalar)
          }
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

  function sqrt(uint256 x) internal pure returns (uint256 z) {
    assembly {
      // Start off with z at 1.
      z := 1

      // Used below to help find a nearby power of 2.
      let y := x

      // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
        // Equivalent to 2 ** z.
        z := shl(1, z)
      }

      // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

      // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct ModuleState {
//   ModuleType moduleType;
//   uint8 loanGasE4;
//   uint8 repayGasE4;
//   uint64 ethRefundForLoanGas;
//   uint64 ethRefundForRepayGas;
//   uint24 btcFeeForLoanGas;
//   uint24 btcFeeForRepayGas;
//   uint32 lastUpdateTimestamp;
// }
type ModuleState is uint256;

ModuleState constant DefaultModuleState = ModuleState
  .wrap(0);

library ModuleStateCoder {
  /*//////////////////////////////////////////////////////////////
                           ModuleState
//////////////////////////////////////////////////////////////*/

  function decode(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    ModuleType moduleType,
    uint256 loanGasE4,
    uint256 repayGasE4,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState encoded) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        or(
          gt(repayGasE4, MaxUint8),
          or(
            gt(ethRefundForLoanGas, MaxUint64),
            or(
              gt(ethRefundForRepayGas, MaxUint64),
              or(
                gt(btcFeeForLoanGas, MaxUint24),
                or(
                  gt(
                    btcFeeForRepayGas,
                    MaxUint24
                  ),
                  gt(
                    lastUpdateTimestamp,
                    MaxUint32
                  )
                )
              )
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        ),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          or(
            shl(
              ModuleState_repayGasE4_bitsAfter,
              repayGasE4
            ),
            or(
              shl(
                ModuleState_ethRefundForLoanGas_bitsAfter,
                ethRefundForLoanGas
              ),
              or(
                shl(
                  ModuleState_ethRefundForRepayGas_bitsAfter,
                  ethRefundForRepayGas
                ),
                or(
                  shl(
                    ModuleState_btcFeeForLoanGas_bitsAfter,
                    btcFeeForLoanGas
                  ),
                  or(
                    shl(
                      ModuleState_btcFeeForRepayGas_bitsAfter,
                      btcFeeForRepayGas
                    ),
                    shl(
                      ModuleState_lastUpdateTimestamp_bitsAfter,
                      lastUpdateTimestamp
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState LoanParams coders
//////////////////////////////////////////////////////////////*/

  function getLoanParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForLoanGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                ModuleState BitcoinGasFees coders
//////////////////////////////////////////////////////////////*/

  function getBitcoinGasFees(ModuleState encoded)
    internal
    pure
    returns (
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState RepayParams coders
//////////////////////////////////////////////////////////////*/

  function setRepayParams(
    ModuleState old,
    ModuleType moduleType,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForRepayGas, MaxUint64),
        gt(btcFeeForRepayGas, MaxUint24)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_RepayParams_maskOut),
        or(
          shl(
            ModuleState_moduleType_bitsAfter,
            moduleType
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            shl(
              ModuleState_btcFeeForRepayGas_bitsAfter,
              btcFeeForRepayGas
            )
          )
        )
      )
    }
  }

  function getRepayParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    ModuleState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    ModuleState old,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForLoanGas, MaxUint64),
        or(
          gt(ethRefundForRepayGas, MaxUint64),
          or(
            gt(btcFeeForLoanGas, MaxUint24),
            or(
              gt(btcFeeForRepayGas, MaxUint24),
              gt(lastUpdateTimestamp, MaxUint32)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_Cached_maskOut),
        or(
          shl(
            ModuleState_ethRefundForLoanGas_bitsAfter,
            ethRefundForLoanGas
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            or(
              shl(
                ModuleState_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              or(
                shl(
                  ModuleState_btcFeeForRepayGas_bitsAfter,
                  btcFeeForRepayGas
                ),
                shl(
                  ModuleState_lastUpdateTimestamp_bitsAfter,
                  lastUpdateTimestamp
                )
              )
            )
          )
        )
      )
    }
  }

  function getCached(ModuleState encoded)
    internal
    pure
    returns (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState GasParams coders
//////////////////////////////////////////////////////////////*/

  function setGasParams(
    ModuleState old,
    uint256 loanGasE4,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        gt(repayGasE4, MaxUint8)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_GasParams_maskOut),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          shl(
            ModuleState_repayGasE4_bitsAfter,
            repayGasE4
          )
        )
      )
    }
  }

  function getGasParams(ModuleState encoded)
    internal
    pure
    returns (
      uint256 loanGasE4,
      uint256 repayGasE4
    )
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.moduleType coders
//////////////////////////////////////////////////////////////*/

  function getModuleType(ModuleState encoded)
    internal
    pure
    returns (ModuleType moduleType)
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
    }
  }

  function setModuleType(
    ModuleState old,
    ModuleType moduleType
  ) internal pure returns (ModuleState updated) {
    assembly {
      updated := or(
        and(old, ModuleState_moduleType_maskOut),
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.loanGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getLoanGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 loanGasE4)
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLoanGasE4(
    ModuleState old,
    uint256 loanGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(loanGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_loanGasE4_maskOut),
        shl(
          ModuleState_loanGasE4_bitsAfter,
          loanGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.repayGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getRepayGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 repayGasE4)
  {
    assembly {
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRepayGasE4(
    ModuleState old,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(repayGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_repayGasE4_maskOut),
        shl(
          ModuleState_repayGasE4_bitsAfter,
          repayGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForLoanGas)
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForLoanGas(
    ModuleState old,
    uint256 ethRefundForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForLoanGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForLoanGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          ethRefundForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForRepayGas)
  {
    assembly {
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForRepayGas(
    ModuleState old,
    uint256 ethRefundForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForRepayGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForRepayGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          ethRefundForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               ModuleState.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForLoanGas(
    ModuleState old,
    uint256 btcFeeForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForLoanGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForLoanGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          btcFeeForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              ModuleState.btcFeeForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForRepayGas)
  {
    assembly {
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForRepayGas(
    ModuleState old,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForRepayGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForRepayGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          btcFeeForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLastUpdateTimestamp(
    ModuleState old,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(lastUpdateTimestamp, MaxUint32) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_lastUpdateTimestamp_maskOut
        ),
        shl(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          lastUpdateTimestamp
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(ModuleState a, ModuleState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(ModuleState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultModuleState);
  }
}

enum ModuleType {
  Null,
  LoanOverride,
  LoanAndRepayOverride
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC4626Storage.sol";
import "./GovernableStorage.sol";
import "../utils/ModuleStateCoder.sol";
import "../utils/GlobalStateCoder.sol";
import "../utils/LoanRecordCoder.sol";

contract ZeroBTCStorage is ERC4626Storage, GovernableStorage {
  GlobalState internal _state;

  mapping(address => ModuleState) internal _moduleFees;

  // Maps loanId => LoanRecord
  mapping(uint256 => LoanRecord) internal _outstandingLoans;

  // maps wallets => whether they can call earn
  mapping(address => bool) internal _isHarvester;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

uint256 constant GlobalState_BorrowFees_maskOut = 0x000003ffe000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_Cached_maskOut = 0xffffffffffffffffffff80000000000000000001ffffffffffffffffffffffff;
uint256 constant GlobalState_Fees_maskOut = 0x000000000000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_LoanInfo_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_ParamsForModuleFees_maskOut = 0xffffffffffffffffffff800000000001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_UnburnedShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe00000000000001;
uint256 constant GlobalState_gweiPerGas_bitsAfter = 0x81;
uint256 constant GlobalState_gweiPerGas_maskOut = 0xfffffffffffffffffffffffffffe0001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_lastUpdateTimestamp_bitsAfter = 0x61;
uint256 constant GlobalState_lastUpdateTimestamp_maskOut = 0xfffffffffffffffffffffffffffffffe00000001ffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeBips_bitsAfter = 0xea;
uint256 constant GlobalState_renBorrowFeeBips_maskOut = 0xffe003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeStatic_bitsAfter = 0xaf;
uint256 constant GlobalState_renBorrowFeeStatic_maskOut = 0xffffffffffffffc000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_satoshiPerEth_bitsAfter = 0x91;
uint256 constant GlobalState_satoshiPerEth_maskOut = 0xffffffffffffffffffff80000001ffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_totalBitcoinBorrowed_bitsAfter = 0x39;
uint256 constant GlobalState_totalBitcoinBorrowed_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_unburnedGasReserveShares_bitsAfter = 0x1d;
uint256 constant GlobalState_unburnedGasReserveShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe0000001fffffff;
uint256 constant GlobalState_unburnedZeroFeeShares_bitsAfter = 0x01;
uint256 constant GlobalState_unburnedZeroFeeShares_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0000001;
uint256 constant GlobalState_zeroBorrowFeeBips_bitsAfter = 0xf5;
uint256 constant GlobalState_zeroBorrowFeeBips_maskOut = 0x001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroBorrowFeeStatic_bitsAfter = 0xc6;
uint256 constant GlobalState_zeroBorrowFeeStatic_maskOut = 0xffffffffe000003fffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroFeeShareBips_bitsAfter = 0xdd;
uint256 constant GlobalState_zeroFeeShareBips_maskOut = 0xfffffc001fffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_SharesAndDebt_maskOut = 0x000000000000ffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_actualBorrowAmount_bitsAfter = 0xa0;
uint256 constant LoanRecord_actualBorrowAmount_maskOut = 0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_btcFeeForLoanGas_bitsAfter = 0x40;
uint256 constant LoanRecord_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffff000000000000ffffffffffffffff;
uint256 constant LoanRecord_expiry_bitsAfter = 0x20;
uint256 constant LoanRecord_expiry_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;
uint256 constant LoanRecord_lenderDebt_bitsAfter = 0x70;
uint256 constant LoanRecord_lenderDebt_maskOut = 0xffffffffffffffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_sharesLocked_bitsAfter = 0xd0;
uint256 constant LoanRecord_sharesLocked_maskOut = 0x000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant MaxUint11 = 0x07ff;
uint256 constant MaxUint13 = 0x1fff;
uint256 constant MaxUint16 = 0xffff;
uint256 constant MaxUint2 = 0x03;
uint256 constant MaxUint23 = 0x7fffff;
uint256 constant MaxUint24 = 0xffffff;
uint256 constant MaxUint28 = 0x0fffffff;
uint256 constant MaxUint30 = 0x3fffffff;
uint256 constant MaxUint32 = 0xffffffff;
uint256 constant MaxUint40 = 0xffffffffff;
uint256 constant MaxUint48 = 0xffffffffffff;
uint256 constant MaxUint64 = 0xffffffffffffffff;
uint256 constant MaxUint8 = 0xff;
uint256 constant ModuleState_BitcoinGasFees_maskOut = 0xffffffffffffffffffffffffffffffffffffc000000000003fffffffffffffff;
uint256 constant ModuleState_Cached_maskOut = 0xffffc0000000000000000000000000000000000000000000000000003fffffff;
uint256 constant ModuleState_GasParams_maskOut = 0xc0003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_LoanParams_maskOut = 0x3fffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_RepayParams_maskOut = 0x3fffffffffffffffffffc0000000000000003fffffc000003fffffffffffffff;
uint256 constant ModuleState_btcFeeForLoanGas_bitsAfter = 0x56;
uint256 constant ModuleState_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffffc000003fffffffffffffffffffff;
uint256 constant ModuleState_btcFeeForRepayGas_bitsAfter = 0x3e;
uint256 constant ModuleState_btcFeeForRepayGas_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffc000003fffffffffffffff;
uint256 constant ModuleState_ethRefundForLoanGas_bitsAfter = 0xae;
uint256 constant ModuleState_ethRefundForLoanGas_maskOut = 0xffffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_ethRefundForRepayGas_bitsAfter = 0x6e;
uint256 constant ModuleState_ethRefundForRepayGas_maskOut = 0xffffffffffffffffffffc0000000000000003fffffffffffffffffffffffffff;
uint256 constant ModuleState_lastUpdateTimestamp_bitsAfter = 0x1e;
uint256 constant ModuleState_lastUpdateTimestamp_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffc00000003fffffff;
uint256 constant ModuleState_loanGasE4_bitsAfter = 0xf6;
uint256 constant ModuleState_loanGasE4_maskOut = 0xc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_moduleType_bitsAfter = 0xfe;
uint256 constant ModuleState_moduleType_maskOut = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_repayGasE4_bitsAfter = 0xee;
uint256 constant ModuleState_repayGasE4_maskOut = 0xffc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant Panic_arithmetic = 0x11;
uint256 constant Panic_error_length = 0x24;
uint256 constant Panic_error_offset = 0x04;
uint256 constant Panic_error_signature = 0x4e487b7100000000000000000000000000000000000000000000000000000000;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC2612Storage.sol";
import "./ReentrancyGuardStorage.sol";

contract ERC4626Storage is ERC2612Storage, ReentrancyGuardStorage {
  // maps user => authorized
  mapping(address => bool) internal _authorized;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract GovernableStorage {
  address internal _governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct GlobalState {
//   uint11 zeroBorrowFeeBips;
//   uint11 renBorrowFeeBips;
//   uint13 zeroFeeShareBips;
//   uint23 zeroBorrowFeeStatic;
//   uint23 renBorrowFeeStatic;
//   uint30 satoshiPerEth;
//   uint16 gweiPerGas;
//   uint32 lastUpdateTimestamp;
//   uint40 totalBitcoinBorrowed;
//   uint28 unburnedGasReserveShares;
//   uint28 unburnedZeroFeeShares;
// }
type GlobalState is uint256;

GlobalState constant DefaultGlobalState = GlobalState
  .wrap(0);

library GlobalStateCoder {
  /*//////////////////////////////////////////////////////////////
                           GlobalState
//////////////////////////////////////////////////////////////*/

  function decode(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroFeeShareBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp,
    uint256 totalBitcoinBorrowed,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState encoded) {
    assembly {
      if or(
        gt(zeroBorrowFeeStatic, MaxUint23),
        or(
          gt(renBorrowFeeStatic, MaxUint23),
          or(
            gt(satoshiPerEth, MaxUint30),
            or(
              gt(gweiPerGas, MaxUint16),
              or(
                gt(
                  lastUpdateTimestamp,
                  MaxUint32
                ),
                or(
                  gt(
                    totalBitcoinBorrowed,
                    MaxUint40
                  ),
                  or(
                    gt(
                      unburnedGasReserveShares,
                      MaxUint28
                    ),
                    gt(
                      unburnedZeroFeeShares,
                      MaxUint28
                    )
                  )
                )
              )
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        ),
        or(
          shl(
            GlobalState_renBorrowFeeBips_bitsAfter,
            renBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_zeroFeeShareBips_bitsAfter,
              zeroFeeShareBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                or(
                  shl(
                    GlobalState_satoshiPerEth_bitsAfter,
                    satoshiPerEth
                  ),
                  or(
                    shl(
                      GlobalState_gweiPerGas_bitsAfter,
                      gweiPerGas
                    ),
                    or(
                      shl(
                        GlobalState_lastUpdateTimestamp_bitsAfter,
                        lastUpdateTimestamp
                      ),
                      or(
                        shl(
                          GlobalState_totalBitcoinBorrowed_bitsAfter,
                          totalBitcoinBorrowed
                        ),
                        or(
                          shl(
                            GlobalState_unburnedGasReserveShares_bitsAfter,
                            unburnedGasReserveShares
                          ),
                          shl(
                            GlobalState_unburnedZeroFeeShares_bitsAfter,
                            unburnedZeroFeeShares
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                   GlobalState LoanInfo coders
//////////////////////////////////////////////////////////////*/

  function setLoanInfo(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_LoanInfo_maskOut),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  function getLoanInfo(GlobalState encoded)
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                     GlobalState Fees coders
//////////////////////////////////////////////////////////////*/

  function setFees(
    GlobalState old,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(zeroBorrowFeeBips, MaxUint11),
        or(
          gt(renBorrowFeeBips, MaxUint11),
          or(
            gt(zeroBorrowFeeStatic, MaxUint23),
            or(
              gt(renBorrowFeeStatic, MaxUint23),
              gt(zeroFeeShareBips, MaxUint13)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_Fees_maskOut),
        or(
          shl(
            GlobalState_zeroBorrowFeeBips_bitsAfter,
            zeroBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_renBorrowFeeBips_bitsAfter,
              renBorrowFeeBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                shl(
                  GlobalState_zeroFeeShareBips_bitsAfter,
                  zeroFeeShareBips
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState BorrowFees coders
//////////////////////////////////////////////////////////////*/

  function getBorrowFees(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    GlobalState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        or(
          gt(gweiPerGas, MaxUint16),
          gt(lastUpdateTimestamp, MaxUint32)
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_Cached_maskOut),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          or(
            shl(
              GlobalState_gweiPerGas_bitsAfter,
              gweiPerGas
            ),
            shl(
              GlobalState_lastUpdateTimestamp_bitsAfter,
              lastUpdateTimestamp
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState ParamsForModuleFees coders
//////////////////////////////////////////////////////////////*/

  function setParamsForModuleFees(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        gt(gweiPerGas, MaxUint16)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_ParamsForModuleFees_maskOut
        ),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          shl(
            GlobalState_gweiPerGas_bitsAfter,
            gweiPerGas
          )
        )
      )
    }
  }

  function getParamsForModuleFees(
    GlobalState encoded
  )
    internal
    pure
    returns (
      uint256 satoshiPerEth,
      uint256 gweiPerGas
    )
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState UnburnedShares coders
//////////////////////////////////////////////////////////////*/

  function setUnburnedShares(
    GlobalState old,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(unburnedGasReserveShares, MaxUint28),
        gt(unburnedZeroFeeShares, MaxUint28)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_UnburnedShares_maskOut
        ),
        or(
          shl(
            GlobalState_unburnedGasReserveShares_bitsAfter,
            unburnedGasReserveShares
          ),
          shl(
            GlobalState_unburnedZeroFeeShares_bitsAfter,
            unburnedZeroFeeShares
          )
        )
      )
    }
  }

  function getUnburnedShares(GlobalState encoded)
    internal
    pure
    returns (
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.zeroBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeBips)
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
    }
  }

  function setZeroBorrowFeeBips(
    GlobalState old,
    uint256 zeroBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.renBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeBips)
  {
    assembly {
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeBips(
    GlobalState old,
    uint256 renBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_renBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeBips_bitsAfter,
          renBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.zeroFeeShareBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroFeeShareBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroFeeShareBips)
  {
    assembly {
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroFeeShareBips(
    GlobalState old,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroFeeShareBips_maskOut
        ),
        shl(
          GlobalState_zeroFeeShareBips_bitsAfter,
          zeroFeeShareBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.zeroBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeStatic)
  {
    assembly {
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroBorrowFeeStatic(
    GlobalState old,
    uint256 zeroBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(zeroBorrowFeeStatic, MaxUint23) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_zeroBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          zeroBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.renBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeStatic)
  {
    assembly {
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeStatic(
    GlobalState old,
    uint256 renBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(renBorrowFeeStatic, MaxUint23) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_renBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          renBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState.satoshiPerEth coders
//////////////////////////////////////////////////////////////*/

  function getSatoshiPerEth(GlobalState encoded)
    internal
    pure
    returns (uint256 satoshiPerEth)
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState.gweiPerGas coders
//////////////////////////////////////////////////////////////*/

  function getGweiPerGas(GlobalState encoded)
    internal
    pure
    returns (uint256 gweiPerGas)
  {
    assembly {
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.totalBitcoinBorrowed coders
//////////////////////////////////////////////////////////////*/

  function getTotalBitcoinBorrowed(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  function setTotalBitcoinBorrowed(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_totalBitcoinBorrowed_maskOut
        ),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
           GlobalState.unburnedGasReserveShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedGasReserveShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedGasReserveShares)
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedGasReserveShares(
    GlobalState old,
    uint256 unburnedGasReserveShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedGasReserveShares, MaxUint28) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_unburnedGasReserveShares_maskOut
        ),
        shl(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          unburnedGasReserveShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
            GlobalState.unburnedZeroFeeShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedZeroFeeShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedZeroFeeShares)
  {
    assembly {
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedZeroFeeShares(
    GlobalState old,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedZeroFeeShares, MaxUint28) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_unburnedZeroFeeShares_maskOut
        ),
        shl(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          unburnedZeroFeeShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 GlobalState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(GlobalState a, GlobalState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(GlobalState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultGlobalState);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct LoanRecord {
//   uint48 sharesLocked;
//   uint48 actualBorrowAmount;
//   uint48 lenderDebt;
//   uint48 btcFeeForLoanGas;
//   uint32 expiry;
// }
type LoanRecord is uint256;

LoanRecord constant DefaultLoanRecord = LoanRecord
  .wrap(0);

library LoanRecordCoder {
  /*//////////////////////////////////////////////////////////////
                           LoanRecord
//////////////////////////////////////////////////////////////*/

  function decode(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas,
      uint256 expiry
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  function encode(
    uint256 sharesLocked,
    uint256 actualBorrowAmount,
    uint256 lenderDebt,
    uint256 btcFeeForLoanGas,
    uint256 expiry
  ) internal pure returns (LoanRecord encoded) {
    assembly {
      if or(
        gt(sharesLocked, MaxUint48),
        or(
          gt(actualBorrowAmount, MaxUint48),
          or(
            gt(lenderDebt, MaxUint48),
            or(
              gt(btcFeeForLoanGas, MaxUint48),
              gt(expiry, MaxUint32)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          LoanRecord_sharesLocked_bitsAfter,
          sharesLocked
        ),
        or(
          shl(
            LoanRecord_actualBorrowAmount_bitsAfter,
            actualBorrowAmount
          ),
          or(
            shl(
              LoanRecord_lenderDebt_bitsAfter,
              lenderDebt
            ),
            or(
              shl(
                LoanRecord_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              shl(
                LoanRecord_expiry_bitsAfter,
                expiry
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 LoanRecord SharesAndDebt coders
//////////////////////////////////////////////////////////////*/

  function getSharesAndDebt(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 lenderDebt
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              LoanRecord.actualBorrowAmount coders
//////////////////////////////////////////////////////////////*/

  function getActualBorrowAmount(
    LoanRecord encoded
  )
    internal
    pure
    returns (uint256 actualBorrowAmount)
  {
    assembly {
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               LoanRecord.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(LoanRecord encoded)
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    LoanRecord.expiry coders
//////////////////////////////////////////////////////////////*/

  function getExpiry(LoanRecord encoded)
    internal
    pure
    returns (uint256 expiry)
  {
    assembly {
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  LoanRecord comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(LoanRecord a, LoanRecord b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(LoanRecord a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultLoanRecord);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC20Storage.sol";

contract ERC2612Storage is ERC20Storage {
  mapping(address => uint256) internal _nonces;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract ReentrancyGuardStorage {
  uint256 internal locked;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract ERC20Storage {
  uint256 internal _totalSupply;

  mapping(address => uint256) internal _balanceOf;

  mapping(address => mapping(address => uint256)) internal _allowance;
}