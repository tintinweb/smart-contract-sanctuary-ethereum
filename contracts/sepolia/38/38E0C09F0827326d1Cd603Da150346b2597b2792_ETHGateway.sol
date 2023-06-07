// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { IWETH } from "../interfaces/IWETH.sol";
import { IMarket } from "./interfaces/IMarket.sol";

contract ETHGateway {
  using SafeERC20 for IERC20;

  /*************
   * Constants *
   *************/

  /// @notice The address of WETH.
  address public immutable weth;

  /// @notice The address of Fractional ETH.
  address public immutable fToken;

  /// @notice The address of Leveraged ETH.
  address public immutable xToken;

  /// @notice The address of Market.
  address public immutable market;

  /************
   * Modifier *
   ************/

  constructor(
    address _market,
    address _weth,
    address _fToken,
    address _xToken
  ) {
    market = _market;
    weth = _weth;
    fToken = _fToken;
    xToken = _xToken;

    IERC20(_weth).safeApprove(_market, uint256(-1));
    IERC20(_fToken).safeApprove(_market, uint256(-1));
    IERC20(_xToken).safeApprove(_market, uint256(-1));
  }

  receive() external payable {
    require(msg.sender == weth, "only WETH");
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint some fToken with some ETH.
  /// @param _minFTokenMinted The minimum amount of fToken should be received.
  /// @return _fTokenMinted The amount of fToken should be received.
  function mintFToken(uint256 _minFTokenMinted) external payable returns (uint256 _fTokenMinted) {
    IWETH(weth).deposit{ value: msg.value }();

    _fTokenMinted = IMarket(market).mintFToken(msg.value, msg.sender, _minFTokenMinted);

    _refund(weth, msg.sender);
  }

  /// @notice Mint some xToken with some ETH.
  /// @param _minXTokenMinted The minimum amount of xToken should be received.
  /// @return _xTokenMinted The amount of xToken should be received.
  function mintXToken(uint256 _minXTokenMinted) external payable returns (uint256 _xTokenMinted) {
    IWETH(weth).deposit{ value: msg.value }();

    _xTokenMinted = IMarket(market).mintXToken(msg.value, msg.sender, _minXTokenMinted);

    _refund(weth, msg.sender);
  }

  /// @notice Mint some xToken by add some ETH as collateral.
  /// @param _minXTokenMinted The minimum amount of xToken should be received.
  /// @return _xTokenMinted The amount of xToken should be received.
  function addBaseToken(uint256 _minXTokenMinted) external payable returns (uint256 _xTokenMinted) {
    IWETH(weth).deposit{ value: msg.value }();

    _xTokenMinted = IMarket(market).addBaseToken(msg.value, msg.sender, _minXTokenMinted);

    _refund(weth, msg.sender);
  }

  /// @notice Redeem ETH with fToken and xToken.
  /// @param _fTokenIn the amount of fToken to redeem.
  /// @param _xTokenIn the amount of xToken to redeem.
  /// @param _minBaseOut The minimum amount of base token should be received.
  /// @return _baseOut The amount of base token should be received.
  function redeem(
    uint256 _fTokenIn,
    uint256 _xTokenIn,
    uint256 _minBaseOut
  ) external returns (uint256 _baseOut) {
    if (_fTokenIn > 0) {
      _fTokenIn = _transferTokenIn(fToken, _fTokenIn);
      _xTokenIn = 0;
    } else {
      _xTokenIn = _transferTokenIn(xToken, _xTokenIn);
    }

    _baseOut = IMarket(market).redeem(_fTokenIn, _xTokenIn, address(this), _minBaseOut);

    if (_fTokenIn > 0) {
      _refund(fToken, msg.sender);
    }
    if (_xTokenIn > 0) {
      _refund(xToken, msg.sender);
    }
    _transferETH(_baseOut, msg.sender);
  }

  /// @notice Permissionless liquidate some fToken to increase the collateral ratio.
  /// @param _fTokenIn the amount of fToken to supply.
  /// @param _minBaseOut The minimum amount of base token should be received.
  /// @return _baseOut The amount of base token should be received.
  function liquidate(uint256 _fTokenIn, uint256 _minBaseOut) external returns (uint256 _baseOut) {
    _fTokenIn = _transferTokenIn(fToken, _fTokenIn);

    _baseOut = IMarket(market).liquidate(_fTokenIn, address(this), _minBaseOut);

    _refund(fToken, msg.sender);
    _transferETH(_baseOut, msg.sender);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to transfer token to this contract.
  /// @param _token The address of token to transfer.
  /// @param _amount The amount of token to transfer.
  /// @return uint256 The amount of token transfered.
  function _transferTokenIn(address _token, uint256 _amount) internal returns (uint256) {
    if (_amount == uint256(-1)) {
      _amount = IERC20(_token).balanceOf(msg.sender);
    }

    if (_amount > 0) {
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    return _amount;
  }

  /// @dev Internal function to refund extra token.
  /// @param _token The address of token to refund.
  /// @param _recipient The address of the token receiver.
  function _refund(address _token, address _recipient) internal {
    uint256 _balance = IERC20(_token).balanceOf(address(this));

    if (_balance > 0) {
      if (_token == weth) {
        _transferETH(_balance, _recipient);
      } else {
        IERC20(_token).safeTransfer(_recipient, _balance);
      }
    }
  }

  /// @dev Internal function to withdraw WETH and transfer ETH.
  /// @param _amount The amount of ETH to transfer.
  /// @param _recipient The address of the ETH receiver.
  function _transferETH(uint256 _amount, address _recipient) internal {
    IWETH(weth).withdraw(_amount);

    (bool _success, ) = _recipient.call{ value: _amount }("");
    require(_success, "transfer ETH failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMarket {
  /**********
   * Events *
   **********/

  /// @notice Emitted when fToken or xToken is minted.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param fTokenOut The amount of fToken minted.
  /// @param xTokenOut The amount of xToken minted.
  /// @param mintFee The amount of mint fee charged.
  event Mint(
    address indexed owner,
    address indexed recipient,
    uint256 baseTokenIn,
    uint256 fTokenOut,
    uint256 xTokenOut,
    uint256 mintFee
  );

  /// @notice Emitted when someone redeem base token with fToken or xToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param xTokenBurned The amount of xToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param redeemFee The amount of redeem fee charged.
  event Redeem(
    address indexed owner,
    address indexed recipient,
    uint256 fTokenBurned,
    uint256 xTokenBurned,
    uint256 baseTokenOut,
    uint256 redeemFee
  );

  /// @notice Emitted when someone add more base token.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param xTokenMinted The amount of xToken minted.
  event AddCollateral(address indexed owner, address indexed recipient, uint256 baseTokenIn, uint256 xTokenMinted);

  /// @notice Emitted when someone liquidate with fToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  event UserLiquidate(address indexed owner, address indexed recipient, uint256 fTokenBurned, uint256 baseTokenOut);

  /// @notice Emitted when self liquidate with fToken.
  /// @param caller The address of caller.
  /// @param baseSwapAmt The amount of base token used to swap.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param fTokenBurned The amount of fToken liquidated.
  event SelfLiquidate(address indexed caller, uint256 baseSwapAmt, uint256 baseTokenOut, uint256 fTokenBurned);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint both fToken and xToken with some base token.
  /// @param baseIn The amount of base token supplied.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mint(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted,
    uint256 minXTokenMinted
  ) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint some fToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for fToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  function mintFToken(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted
  ) external returns (uint256 fTokenMinted);

  /// @notice Mint some xToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mintXToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Mint some xToken by add some base token as collateral.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function addBaseToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Redeem base token with fToken and xToken.
  /// @param fTokenIn the amount of fToken to redeem, use `uint256(-1)` to redeem all fToken.
  /// @param xTokenIn the amount of xToken to redeem, use `uint256(-1)` to redeem all xToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Permissionless liquidate some fToken to increase the collateral ratio.
  /// @param fTokenIn the amount of fToken to supply, use `uint256(-1)` to liquidate all fToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function liquidate(
    uint256 fTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate some fToken to increase the collateral ratio.
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param minFTokenLiquidated The minimum amount of fToken should be liquidated.
  /// @param data The data used to swap base token to fToken.
  /// @return baseOut The amount of base token should be received.
  /// @return fTokenLiquidated the amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 minFTokenLiquidated,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fTokenLiquidated);

  /// @notice Callback to swap base token to fToken
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param data The data passed to market contract.
  /// @return fTokenAmt The amount of fToken received.
  function onSelfLiquidate(uint256 baseSwapAmt, bytes calldata data) external returns (uint256 fTokenAmt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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