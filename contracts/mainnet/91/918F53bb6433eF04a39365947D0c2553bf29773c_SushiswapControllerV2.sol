// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/IAddressRegistry.sol";
import "../../interfaces/ISushiLPtoCurveLPMigration.sol";

contract SushiLPtoCurveLPMigration is ISushiLPtoCurveLPMigration {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	IAddressRegistry public immutable addressRegistry;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Pair public immutable SUSHI_PAIR;
	// solhint-disable-next-line var-name-mixedcase
	ICryptoSwapPool public immutable CURVE_POOL;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable CURVE_LP_TOKEN;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable TOKE;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable WETH;

	constructor(
		IUniswapV2Router02 _sushiRouter,
		IUniswapV2Pair _sushiPair,
		IERC20 _toke,
		IERC20 _weth,
		address _curvePool,
		address _curveLpToken,
		address _addressRegistry
	) public {
		require(address(_sushiRouter) != address(0), "INVALID_ROUTER");
		require(address(_sushiPair) != address(0), "INVALID_SUSHI_PAIR");
		require(address(_toke) != address(0), "INVALID_TOKE");
		require(address(_weth) != address(0), "INVALID_WETH");
		require(_curvePool != address(0), "INVALID_CURVEPOOL");
		require(_curveLpToken != address(0), "INVALID_CURVELPTOKEN");
		require(_addressRegistry != address(0), "INVALID_REGISTRY_ADDRESS");

		require(ICryptoSwapPool(_curvePool).coins(0) == address(_weth), "INVALID_CURVE_POOL_WETH");
		require(ICryptoSwapPool(_curvePool).coins(1) == address(_toke), "INVALID_CURVE_POOL_TOKE");
		require(IUniswapV2Pair(_sushiPair).token0() == address(_toke), "INVALID_SUSHI_POOL_TOKE");
		require(IUniswapV2Pair(_sushiPair).token1() == address(_weth), "INVALID_SUSHI_POOL_WETH");

		addressRegistry = IAddressRegistry(_addressRegistry);

		SUSHI_PAIR = _sushiPair;
		TOKE = _toke;
		WETH = _weth;

		CURVE_POOL = ICryptoSwapPool(_curvePool);
		CURVE_LP_TOKEN = IERC20(_curveLpToken);

		SUSHISWAP_ROUTER = _sushiRouter;
	}

	function migrate(
		SushiWithdrawalInfo calldata withdrawalInfo,
		uint256 amountCurveLpMin,
		address to
	) external override {
		(uint256 amountTokeReceived, uint256 amountWethReceived) = _withdrawFromSushi(
			withdrawalInfo.amountLp,
			withdrawalInfo.amountTokeMin,
			withdrawalInfo.amountWethMin,
			address(this),
			withdrawalInfo.deadline
		);

		uint256 amountLpMinted = _deploytoCurve(amountTokeReceived, amountWethReceived, amountCurveLpMin);

		CURVE_LP_TOKEN.safeTransfer(to, amountLpMinted);

		emit SushiLPtoCurveLPMigrationEvent(
			withdrawalInfo.amountLp,
			amountLpMinted,
			amountTokeReceived,
			amountWethReceived
		);
	}

	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @param amountLp Amount of liquidity tokens to remove from pool
	/// @param amountTokeMin Minimum amount of TOKE to receive
	/// @param amountWethMin Minimum amount of WETH to receive
	/// @param to Address to send received tokens to
	/// @param deadline Unix timestamp denoting time tx must execute by
	function _withdrawFromSushi(
		uint256 amountLp,
		uint256 amountTokeMin,
		uint256 amountWethMin,
		address to,
		uint256 deadline
	) internal returns (uint256 amountTokeReceived, uint256 amountWethReceived) {
		require(SUSHI_PAIR.balanceOf(address(this)) >= amountLp, "INSUFFICIENT_LIQUIDITY");
		_approve(address(SUSHISWAP_ROUTER), IERC20(address(SUSHI_PAIR)), amountLp);

		uint256 tokeBalanceBeforeLiquidityRemoval = TOKE.balanceOf(address(this));
		uint256 wethBalanceBeforeLiquidityRemoval = WETH.balanceOf(address(this));

		SUSHISWAP_ROUTER.removeLiquidity(
			address(TOKE),
			address(WETH),
			amountLp,
			amountTokeMin,
			amountWethMin,
			to,
			deadline
		);

		uint256 tokeBalanceAfterLiquidityRemoval = TOKE.balanceOf(address(this));
		uint256 wethBalanceAfterLiquidityRemoval = WETH.balanceOf(address(this));

		amountTokeReceived = tokeBalanceAfterLiquidityRemoval.sub(tokeBalanceBeforeLiquidityRemoval);
		amountWethReceived = wethBalanceAfterLiquidityRemoval.sub(wethBalanceBeforeLiquidityRemoval);

		require(amountTokeReceived >= amountTokeMin, "MUST_BE_GREATER_THAN_MIN_TOKE");
		require(amountWethReceived >= amountWethMin, "MUST_BE_GREATER_THAN_MIN_WETH");
	}

	/// @notice Deploy liquidity to Curve pool
	/// @param amountToke Amount of TOKE to deposit
	/// @param amountWeth Amount of WETH to deposit
	/// @param amountLpMin Minimum amount of LP token to receive
	/// @return amountLpMinted amount of LP token received
	function _deploytoCurve(
		uint256 amountToke,
		uint256 amountWeth,
		uint256 amountLpMin
	) internal returns (uint256 amountLpMinted) {
		uint256 wethBalance = WETH.balanceOf(address(this));
		uint256 tokeBalance = TOKE.balanceOf(address(this));

		require(wethBalance >= amountWeth, "INSUFFICIENT_BALANCE");
		require(tokeBalance >= amountToke, "INSUFFICIENT_BALANCE");
		
		_approve(address(CURVE_POOL), WETH, amountWeth);
		_approve(address(CURVE_POOL), TOKE, amountToke);

		uint256 lpTokenBalanceBefore = CURVE_LP_TOKEN.balanceOf(address(this));
		CURVE_POOL.add_liquidity([amountWeth, amountToke], amountLpMin);
		uint256 lpTokenBalanceAfter = CURVE_LP_TOKEN.balanceOf(address(this));

		amountLpMinted = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(amountLpMinted >= amountLpMin, "LP_AMT_TOO_LOW");
	}

	function _approve(
		address spender,
		IERC20 token,
		uint256 amount
	) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface ICryptoSwapPool {
	/* solhint-disable func-name-mixedcase, var-name-mixedcase */

	function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

	function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

	function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[3] memory min_amounts) external;

	function remove_liquidity(uint256 amount, uint256[4] memory min_amounts) external;

	function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external;

	function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external returns (uint256);

	function coins(uint256 i) external returns (address);

	function balanceOf(address account) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

/**
 *   @title Track addresses to be used in liquidity deployment
 *   Any controller used, asset deployed, or pool tracked within the
 *   system should be registered here
 */
interface IAddressRegistry {
	enum AddressTypes {
		Token,
		Controller,
		Pool
	}

	event RegisteredAddressAdded(address added);
	event RegisteredAddressRemoved(address removed);
	event AddedToRegistry(address[] addresses, AddressTypes);
	event RemovedFromRegistry(address[] addresses, AddressTypes);

	/// @notice Allows address with REGISTERED_ROLE to add a registered address
	/// @param _addr address to be added
	function addRegistrar(address _addr) external;

	/// @notice Allows address with REGISTERED_ROLE to remove a registered address
	/// @param _addr address to be removed
	function removeRegistrar(address _addr) external;

	/// @notice Allows array of addresses to be added to registry for certain index
	/// @param _addresses calldata array of addresses to be added to registry
	/// @param _index AddressTypes enum of index to add addresses to
	function addToRegistry(address[] calldata _addresses, AddressTypes _index) external;

	/// @notice Allows array of addresses to be removed from registry for certain index
	/// @param _addresses calldata array of addresses to be removed from registry
	/// @param _index AddressTypes enum of index to remove addresses from
	function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external;

	/// @notice Allows array of all addresses for certain index to be returned
	/// @param _index AddressTypes enum of index to be returned
	/// @return address[] memory of addresses from index
	function getAddressForType(AddressTypes _index) external view returns (address[] memory);

	/// @notice Allows checking that one address exists in certain index
	/// @param _addr address to be checked
	/// @param _index AddressTypes index to check address against
	/// @return bool tells whether address exists or not
	function checkAddress(address _addr, uint256 _index) external view returns (bool);

	/// @notice Returns weth address
	/// @return address weth address
	function weth() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

interface ISushiLPtoCurveLPMigration {
	struct SushiWithdrawalInfo {
		uint256 amountLp;
		uint256 amountTokeMin;
		uint256 amountWethMin;
		uint256 deadline;
	}

	event SushiLPtoCurveLPMigrationEvent(
		uint256 amountSushiLpBurned,
		uint256 amountCurveLpMinted,
		uint256 amountTokeWithdrawnFromSushi,
		uint256 amountWethWithdrawnFromSushi
	);

	/// @notice Withdraw amount of SUSHI LP token and deposit returned TOKE and WETH to CURVE pool.
	/// @notice Send CURVE LP back to the user.
	/// @param withdrawalInfo sushi pool withdrawal infos
	/// @param amountCurveLpMin minimum amount of Curve LP token to receive
	function migrate(
		SushiWithdrawalInfo calldata withdrawalInfo,
		uint256 amountCurveLpMin,
		address to
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// SushiToken with Governance.
contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SUSHI::delegateBySig: invalid nonce");
        require(now <= expiry, "SUSHI::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "SUSHI::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SushiToken.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }
    // The SUSHI TOKEN!
    SushiToken public sushi;
    // Dev address.
    address public devaddr;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        SushiToken _sushi,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        sushi = _sushi;
        devaddr = _devaddr;
        sushiPerBlock = _sushiPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        sushi.mint(devaddr, sushiReward.div(10));
        sushi.mint(address(this), sushiReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeSushiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (_amount > sushiBal) {
            sushi.transfer(_to, sushiBal);
        } else {
            sushi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./INativeOrdersEvents.sol";


/// @dev Feature for interacting with limit orders.
interface INativeOrdersFeature is
    INativeOrdersEvents
{

    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds)
        external;

    /// @dev Fill a limit order. The taker and sender will be the caller.
    /// @param order The limit order. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        payable
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for up to `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        payable
        returns (uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    )
        external
        returns (uint128 makerTokenFilledAmount);

    /// @dev Fill a limit order. Internal variant. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      `msg.sender` (not `sender`).
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param sender The order sender.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        address sender
    )
        external
        payable
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order. Internal variant.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker
    )
        external
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder calldata order)
        external;

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder calldata order)
        external;

    /// @dev Mark what tx.origin addresses are allowed to fill an order that
    ///      specifies the message sender as its txOrigin.
    /// @param origins An array of origin addresses to update.
    /// @param allowed True to register, false to unregister.
    function registerAllowedRfqOrigins(address[] memory origins, bool allowed)
        external;

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] calldata orders)
        external;

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] calldata orders)
        external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    )
        external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    )
        external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    )
        external;

    /// @dev Get the order info for a limit order.
    /// @param order The limit order.
    /// @return orderInfo Info about the order.
    function getLimitOrderInfo(LibNativeOrder.LimitOrder calldata order)
        external
        view
        returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the order info for an RFQ order.
    /// @param order The RFQ order.
    /// @return orderInfo Info about the order.
    function getRfqOrderInfo(LibNativeOrder.RfqOrder calldata order)
        external
        view
        returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the canonical hash of a limit order.
    /// @param order The limit order.
    /// @return orderHash The order hash.
    function getLimitOrderHash(LibNativeOrder.LimitOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the canonical hash of an RFQ order.
    /// @param order The RFQ order.
    /// @return orderHash The order hash.
    function getRfqOrderHash(LibNativeOrder.RfqOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier()
        external
        view
        returns (uint32 multiplier);

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Get order info, fillable amount, and signature validity for an RFQ order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getRfqOrderRelevantState(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Batch version of `getLimitOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getLimitOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The limit orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetLimitOrderRelevantStates(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Batch version of `getRfqOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getRfqOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The RFQ orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetRfqOrderRelevantStates(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Register a signer who can sign on behalf of msg.sender
    ///      This allows one to sign on behalf of a contract that calls this function
    /// @param signer The address from which you plan to generate signatures
    /// @param allowed True to register, false to unregister.
    function registerAllowedOrderSigner(
        address signer,
        bool allowed
    )
        external;

    /// @dev checks if a given address is registered to sign on behalf of a maker address
    /// @param maker The maker address encoded in an order (can be a contract)
    /// @param signer The address that is providing a signature
    function isValidOrderSigner(
        address maker,
        address signer
    )
        external
        view
        returns (bool isAllowed);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IERC20TokenV06 {
    // solhint-disable no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibSignatureRichErrors.sol";


/// @dev A library for validating signatures.
library LibSignature {
    using LibRichErrorsV06 for bytes;

    // '\x19Ethereum Signed Message:\n32\x00\x00\x00\x00' in a word.
    uint256 private constant ETH_SIGN_HASH_PREFIX =
        0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;
    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    /// @dev Retrieve the signer of a signature.
    ///      Throws if the signature can't be validated.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    /// @return recovered The recovered signer address.
    function getSignerOfHash(
        bytes32 hash,
        Signature memory signature
    )
        internal
        pure
        returns (address recovered)
    {
        // Ensure this is a signature type that can be validated against a hash.
        _validateHashCompatibleSignature(hash, signature);

        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            recovered = ecrecover(
                hash,
                signature.v,
                signature.r,
                signature.s
            );
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            // Signed using `eth_sign`
            // Need to hash `hash` with "\x19Ethereum Signed Message:\n32" prefix
            // in packed encoding.
            bytes32 ethSignHash;
            assembly {
                // Use scratch space
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            recovered = ecrecover(
                ethSignHash,
                signature.v,
                signature.r,
                signature.s
            );
        }
        // `recovered` can be null if the signature values are out of range.
        if (recovered == address(0)) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA,
                hash
            ).rrevert();
        }
    }

    /// @dev Validates that a signature is compatible with a hash signee.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    function _validateHashCompatibleSignature(
        bytes32 hash,
        Signature memory signature
    )
        private
        pure
    {
        // Ensure the r and s are within malleability limits.
        if (uint256(signature.r) >= ECDSA_SIGNATURE_R_LIMIT ||
            uint256(signature.s) >= ECDSA_SIGNATURE_S_LIMIT)
        {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA,
                hash
            ).rrevert();
        }

        // Always illegal signature.
        if (signature.signatureType == SignatureType.ILLEGAL) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL,
                hash
            ).rrevert();
        }

        // Always invalid.
        if (signature.signatureType == SignatureType.INVALID) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID,
                hash
            ).rrevert();
        }

        // Solidity should check that the signature type is within enum range for us
        // when abi-decoding.
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";


/// @dev A library for common native order operations.
library LibNativeOrder {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    enum OrderStatus {
        INVALID,
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    /// @dev A standard OTC or OO limit order.
    struct LimitOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        uint128 takerTokenFeeAmount;
        address maker;
        address taker;
        address sender;
        address feeRecipient;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An RFQ limit order.
    struct RfqOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An OTC limit order.
    struct OtcOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        uint256 expiryAndNonce; // [uint64 expiry, uint64 nonceBucket, uint128 nonce]
    }

    /// @dev Info on a limit or RFQ order.
    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        uint128 takerTokenFilledAmount;
    }

    /// @dev Info on an OTC order.
    struct OtcOrderInfo {
        bytes32 orderHash;
        OrderStatus status;
    }

    uint256 private constant UINT_128_MASK = (1 << 128) - 1;
    uint256 private constant UINT_64_MASK = (1 << 64) - 1;
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // The type hash for limit orders, which is:
    // keccak256(abi.encodePacked(
    //     "LimitOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "uint128 takerTokenFeeAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address sender,",
    //       "address feeRecipient,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _LIMIT_ORDER_TYPEHASH =
        0xce918627cb55462ddbb85e73de69a8b322f2bc88f4507c52fcad6d4c33c29d49;

    // The type hash for RFQ orders, which is:
    // keccak256(abi.encodePacked(
    //     "RfqOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _RFQ_ORDER_TYPEHASH =
        0xe593d3fdfa8b60e5e17a1b2204662ecbe15c23f2084b9ad5bae40359540a7da9;

    // The type hash for OTC orders, which is:
    // keccak256(abi.encodePacked(
    //     "OtcOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "uint256 expiryAndNonce"
    //     ")"
    // ))
    uint256 private constant _OTC_ORDER_TYPEHASH =
        0x2f754524de756ae72459efbe1ec88c19a745639821de528ac3fb88f9e65e35c8;

    /// @dev Get the struct hash of a limit order.
    /// @param order The limit order.
    /// @return structHash The struct hash of the order.
    function getLimitOrderStructHash(LimitOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.takerTokenFeeAmount,
        //   order.maker,
        //   order.taker,
        //   order.sender,
        //   order.feeRecipient,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _LIMIT_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.takerTokenFeeAmount;
            mstore(add(mem, 0xA0), and(UINT_128_MASK, mload(add(order, 0x80))))
            // order.maker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.taker;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.sender;
            mstore(add(mem, 0x100), and(ADDRESS_MASK, mload(add(order, 0xE0))))
            // order.feeRecipient;
            mstore(add(mem, 0x120), and(ADDRESS_MASK, mload(add(order, 0x100))))
            // order.pool;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            // order.expiry;
            mstore(add(mem, 0x160), and(UINT_64_MASK, mload(add(order, 0x140))))
            // order.salt;
            mstore(add(mem, 0x180), mload(add(order, 0x160)))
            structHash := keccak256(mem, 0x1A0)
        }
    }

    /// @dev Get the struct hash of a RFQ order.
    /// @param order The RFQ order.
    /// @return structHash The struct hash of the order.
    function getRfqOrderStructHash(RfqOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _RFQ_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.pool;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            // order.expiry;
            mstore(add(mem, 0x120), and(UINT_64_MASK, mload(add(order, 0x100))))
            // order.salt;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            structHash := keccak256(mem, 0x160)
        }
    }

    /// @dev Get the struct hash of an OTC order.
    /// @param order The OTC order.
    /// @return structHash The struct hash of the order.
    function getOtcOrderStructHash(OtcOrder memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.expiryAndNonce,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _OTC_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.expiryAndNonce;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            structHash := keccak256(mem, 0x120)
        }
    }

    /// @dev Refund any leftover protocol fees in `msg.value` to `msg.sender`.
    /// @param ethProtocolFeePaid How much ETH was paid in protocol fees.
    function refundExcessProtocolFeeToSender(uint256 ethProtocolFeePaid)
        internal
    {
        if (msg.value > ethProtocolFeePaid && msg.sender != address(this)) {
            uint256 refundAmount = msg.value.safeSub(ethProtocolFeePaid);
            (bool success,) = msg
                .sender
                .call{value: refundAmount}("");
            if (!success) {
                LibNativeOrdersRichErrors.ProtocolFeeRefundFailed(
                    msg.sender,
                    refundAmount
                ).rrevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";


/// @dev Events emitted by NativeOrdersFeature.
interface INativeOrdersEvents {

    /// @dev Emitted whenever a `LimitOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param feeRecipient Fee recipient of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param protocolFeePaid How much protocol fee was paid.
    /// @param pool The fee pool associated with this order.
    event LimitOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address feeRecipient,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFeeFilledAmount,
        uint256 protocolFeePaid,
        bytes32 pool
    );

    /// @dev Emitted whenever an `RfqOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param pool The fee pool associated with this order.
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    /// @dev Emitted whenever a limit or RFQ order is cancelled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The order maker.
    event OrderCancelled(
        bytes32 orderHash,
        address maker
    );

    /// @dev Emitted whenever Limit orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledLimitOrders(
        address maker,
        address makerToken,
        address takerToken,
        uint256 minValidSalt
    );

    /// @dev Emitted whenever RFQ orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledRfqOrders(
        address maker,
        address makerToken,
        address takerToken,
        uint256 minValidSalt
    );

    /// @dev Emitted when new addresses are allowed or disallowed to fill
    ///      orders with a given txOrigin.
    /// @param origin The address doing the allowing.
    /// @param addrs The address being allowed/disallowed.
    /// @param allowed Indicates whether the address should be allowed.
    event RfqOrderOriginsAllowed(
        address origin,
        address[] addrs,
        bool allowed
    );

    /// @dev Emitted when new order signers are registered
    /// @param maker The maker address that is registering a designated signer.
    /// @param signer The address that will sign on behalf of maker.
    /// @param allowed Indicates whether the address should be allowed.
    event OrderSignerRegistered(
        address maker,
        address signer,
        bool allowed
    );
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibSignatureRichErrors {

    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    // solhint-disable func-name-mixedcase

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
            code,
            hash,
            signerAddress,
            signature
        );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32)")),
            code,
            hash
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";

library LibSafeMathV06 {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256DowncastError(
                    LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                    a
                )
            );
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibNativeOrdersRichErrors {

    // solhint-disable func-name-mixedcase

    function ProtocolFeeRefundFailed(
        address receiver,
        uint256 refundAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ProtocolFeeRefundFailed(address,uint256)")),
            receiver,
            refundAmount
        );
    }

    function OrderNotFillableByOriginError(
        bytes32 orderHash,
        address txOrigin,
        address orderTxOrigin
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByOriginError(bytes32,address,address)")),
            orderHash,
            txOrigin,
            orderTxOrigin
        );
    }

    function OrderNotFillableError(
        bytes32 orderHash,
        uint8 orderStatus
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableError(bytes32,uint8)")),
            orderHash,
            orderStatus
        );
    }

    function OrderNotSignedByMakerError(
        bytes32 orderHash,
        address signer,
        address maker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotSignedByMakerError(bytes32,address,address)")),
            orderHash,
            signer,
            maker
        );
    }

    function OrderNotSignedByTakerError(
        bytes32 orderHash,
        address signer,
        address taker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotSignedByTakerError(bytes32,address,address)")),
            orderHash,
            signer,
            taker
        );
    }

    function InvalidSignerError(
        address maker,
        address signer
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidSignerError(address,address)")),
            maker,
            signer
        );
    }

    function OrderNotFillableBySenderError(
        bytes32 orderHash,
        address sender,
        address orderSender
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableBySenderError(bytes32,address,address)")),
            orderHash,
            sender,
            orderSender
        );
    }

    function OrderNotFillableByTakerError(
        bytes32 orderHash,
        address taker,
        address orderTaker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByTakerError(bytes32,address,address)")),
            orderHash,
            taker,
            orderTaker
        );
    }

    function CancelSaltTooLowError(
        uint256 minValidSalt,
        uint256 oldMinValidSalt
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("CancelSaltTooLowError(uint256,uint256)")),
            minValidSalt,
            oldMinValidSalt
        );
    }

    function FillOrKillFailedError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("FillOrKillFailedError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }

    function OnlyOrderMakerAllowed(
        bytes32 orderHash,
        address sender,
        address maker
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOrderMakerAllowed(bytes32,address,address)")),
            orderHash,
            sender,
            maker
        );
    }

    function BatchFillIncompleteError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BatchFillIncompleteError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibSafeMathRichErrorsV06 {
    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR = 0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR = 0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_BINOP_ERROR_SELECTOR, errorCode, a, b);
    }

    function Uint256DowncastError(DowncastErrorCodes errorCode, uint256 a) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_DOWNCAST_ERROR_SELECTOR, errorCode, a);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//solhint-disable var-name-mixedcase
contract BaseController {
	address public immutable manager;
	address public immutable accessControl;
	IAddressRegistry public immutable addressRegistry;

	bytes32 public immutable ADD_LIQUIDITY_ROLE = keccak256("ADD_LIQUIDITY_ROLE");
	bytes32 public immutable REMOVE_LIQUIDITY_ROLE = keccak256("REMOVE_LIQUIDITY_ROLE");
	bytes32 public immutable MISC_OPERATION_ROLE = keccak256("MISC_OPERATION_ROLE");

	event RewardClaimed(address indexed token, uint256 amount);

	constructor(address _manager, address _accessControl, address _addressRegistry) public {
		require(_manager != address(0), "INVALID_ADDRESS");
		require(_accessControl != address(0), "INVALID_ADDRESS");
		require(_addressRegistry != address(0), "INVALID_ADDRESS");

		manager = _manager;
		accessControl = _accessControl;
		addressRegistry = IAddressRegistry(_addressRegistry);
	}

	modifier onlyManager() {
		require(address(this) == manager, "NOT_MANAGER_ADDRESS");
		_;
	}

	modifier onlyAddLiquidity() {
		require(AccessControl(accessControl).hasRole(ADD_LIQUIDITY_ROLE, msg.sender), "NOT_ADD_LIQUIDITY_ROLE");
		_;
	}

	modifier onlyRemoveLiquidity() {
		require(AccessControl(accessControl).hasRole(REMOVE_LIQUIDITY_ROLE, msg.sender), "NOT_REMOVE_LIQUIDITY_ROLE");
		_;
	}

	modifier onlyMiscOperation() {
		require(AccessControl(accessControl).hasRole(MISC_OPERATION_ROLE, msg.sender), "NOT_MISC_OPERATION_ROLE");
		_;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/MasterChef.sol";
import "./BaseController.sol";

contract SushiswapControllerV1 is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Factory public immutable SUSHISWAP_FACTORY;
	// solhint-disable-next-line var-name-mixedcase
	MasterChef public immutable MASTERCHEF;
	// solhint-disable-next-line var-name-mixedcase
	address public immutable TREASURY;

	constructor(
		IUniswapV2Router02 router,
		IUniswapV2Factory factory,
		MasterChef masterchef,
		address manager,
		address accessControl,
		address addressRegistry,
		address treasury
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(router) != address(0), "INVALID_ROUTER");
		require(address(factory) != address(0), "INVALID_FACTORY");
		require(address(masterchef) != address(0), "INVALID_MASTERCHEF");
		require(treasury != address(0), "INVALID_TREASURY");
		SUSHISWAP_ROUTER = router;
		SUSHISWAP_FACTORY = factory;
		MASTERCHEF = masterchef;
		TREASURY = treasury;
	}

	/// @notice deploy liquidity to Sushiswap pool
	/// @dev Calls to external contract
	/// @param tokenA Address of one token in pair to be deposited as liquidity
	/// @param tokenB Address of other token in pair to be deposited as liquidity
	/// @param amountADesired Desired amount of tokenA to add as liquidity
	/// @param amountBDesired Desired amount of tokenB to add as liquidity
	/// @param amountAMin Minimum amount of tokenA to add as liquidity
	/// @param amountBMin Minimum amount of tokenB to add as liquidity
	/// @param to Recipient of liquidity tokens
	/// @param deadline Unix timestamp after which tx will revert
	/// @param poolId Id of pool for Masterchef lp deposits
	/// @param toDeposit Bool to deposit lp tokens into Masterchef contract or not
	function deploy(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toDeposit,
		bool toDepositAll
	) external onlyManager onlyAddLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenA), amountADesired);
		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenB), amountBDesired);

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISTENT_PAIR");
		uint256 balanceBefore = pair.balanceOf(address(this));

		(, , uint256 liquidity) = SUSHISWAP_ROUTER.addLiquidity(
			tokenA,
			tokenB,
			amountADesired,
			amountBDesired,
			amountAMin,
			amountBMin,
			to,
			deadline
		);

		uint256 balanceAfter = pair.balanceOf(address(this));
		require(balanceAfter > balanceBefore, "MUST_INCREASE");

		if (toDeposit) {
			if (toDepositAll) {
				liquidity = pair.balanceOf(address(this));
			}
			_approve(address(MASTERCHEF), pair, liquidity);
			uint256 reward = checkRewards(poolId);
			depositLPTokensToMasterChef(poolId, liquidity);
			if (reward > 0) {
				IERC20 sushi = MASTERCHEF.sushi();
				sushi.safeTransfer(TREASURY, reward);
				emit RewardClaimed(address(sushi), reward);
			}
		}
	}

	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @dev Calls an external contract
	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @dev Calls an external contract
	/// @param tokenA Address of one token in pair to be withdraw from pool
	/// @param tokenB Address of other token in pair to be withdrawn from pool
	/// @param liquidity Amount of liquidity tokens to remove from pool
	/// @param amountAMin Minimum amount of tokenA to receive
	/// @param amountBMin Minimum amount of tokenB to receive
	/// @param to Address to send received tokens to
	/// @param deadline Unix timestamp denoting time tx must execute by
	/// @param poolId Id of pool for withdrawal of LP tokens from Masterchef
	/// @param toWithdraw Bool to withdraw lp tokens from masterchef
	function withdraw(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toWithdraw
	) external onlyManager onlyRemoveLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISENT_PAIR");

		if (toWithdraw) {
			uint256 reward = checkRewards(poolId);
			bool withdrawalHappened = withdrawLPTokensFromMasterChef(poolId, pair.balanceOf(address(this)), liquidity);
			if (reward > 0 && withdrawalHappened) {
				IERC20 sushi = MASTERCHEF.sushi();
				sushi.safeTransfer(TREASURY, reward);
				emit RewardClaimed(address(sushi), reward);
			}
		}

		require(pair.balanceOf(address(this)) >= liquidity, "INSUFFICIENT_LIQUIDITY");
		_approve(address(SUSHISWAP_ROUTER), pair, liquidity);

		IERC20 tokenAInterface = IERC20(tokenA);
		IERC20 tokenBInterface = IERC20(tokenB);
		uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

		SUSHISWAP_ROUTER.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

		uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
		require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
		require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
	}

	/// @dev Automatically withdraws any accumulated Sushi rewards from Masterchef contract
	function depositLPTokensToMasterChef(uint256 poolId, uint256 amount) private {
		MASTERCHEF.deposit(poolId, amount);
	}

	/// @dev Automatically withdraws Sushi rewards from Masterchef contract
	function withdrawLPTokensFromMasterChef(
		uint256 poolId,
		uint256 currentBalance,
		uint256 withdrawalAmount
	) private returns (bool) {
		if (currentBalance > 0) {
			if (currentBalance >= withdrawalAmount) {
				// Don't need to withdraw in this case
				return false;
			}
			withdrawalAmount = withdrawalAmount.sub(currentBalance);
		}

		(uint256 contractAmount, ) = MASTERCHEF.userInfo(poolId, address(this));
		require(contractAmount >= withdrawalAmount, "INVALID_AMOUNT");
		MASTERCHEF.withdraw(poolId, withdrawalAmount);
		return true;
	}

	function checkRewards(uint256 poolId) private returns (uint256) {
		return MASTERCHEF.pendingSushi(poolId, address(this));
	}

	function _approve(address spender, IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "../interfaces/sushiswap/IMasterChefV2.sol";
import "../interfaces/sushiswap/IComplexRewarder.sol";
import "./BaseController.sol";

contract SushiswapControllerV2 is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Factory public immutable SUSHISWAP_FACTORY;
	// solhint-disable-next-line var-name-mixedcase
	IMasterChefV2 public immutable MASTERCHEF;
	// solhint-disable-next-line var-name-mixedcase
	address public immutable TREASURY;

	constructor(
		IUniswapV2Router02 router,
		IUniswapV2Factory factory,
		IMasterChefV2 masterchef,
		address manager,
		address accessControl,
		address addressRegistry,
		address treasury
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(router) != address(0), "INVALID_ROUTER");
		require(address(factory) != address(0), "INVALID_FACTORY");
		require(address(masterchef) != address(0), "INVALID_MASTERCHEF");
		require(treasury != address(0), "INVALID_TREASURY");
		SUSHISWAP_ROUTER = router;
		SUSHISWAP_FACTORY = factory;
		MASTERCHEF = masterchef;
		TREASURY = treasury;
	}

	/// @notice deploy liquidity to Sushiswap pool
	/// @dev Calls to external contract
	/// @param tokenA Address of one token in pair to be deposited as liquidity
	/// @param tokenB Address of other token in pair to be deposited as liquidity
	/// @param amountADesired Desired amount of tokenA to add as liquidity
	/// @param amountBDesired Desired amount of tokenB to add as liquidity
	/// @param amountAMin Minimum amount of tokenA to add as liquidity
	/// @param amountBMin Minimum amount of tokenB to add as liquidity
	/// @param to Recipient of liquidity tokens
	/// @param deadline Unix timestamp after which tx will revert
	/// @param poolId Id of pool for Masterchef lp deposits
	/// @param toDeposit Bool to deposit lp tokens into Masterchef contract or not
	/// @param toDepositAll Bool to deposit extraneous lp tokens
	function deploy(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toDeposit,
		bool toDepositAll
	) external onlyManager onlyAddLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenA), amountADesired);
		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenB), amountBDesired);

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISTENT_PAIR");
		uint256 balanceBefore = pair.balanceOf(address(this));

		(, , uint256 liquidity) = SUSHISWAP_ROUTER.addLiquidity(
			tokenA,
			tokenB,
			amountADesired,
			amountBDesired,
			amountAMin,
			amountBMin,
			to,
			deadline
		);

		uint256 balanceAfter = pair.balanceOf(address(this));
		require(balanceAfter > balanceBefore, "MUST_INCREASE");

		if (toDeposit) {
			(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
			if (toDepositAll) {
				liquidity = pair.balanceOf(address(this));
			}
			_approve(address(MASTERCHEF), pair, liquidity);
			_depositLPTokensToMasterChef(poolId, liquidity);
			_transferMasterchefRewards(rewardTokens, rewards);
		}
	}

	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @dev Calls an external contract
	/// @param tokenA Address of one token in pair to be withdraw from pool
	/// @param tokenB Address of other token in pair to be withdrawn from pool
	/// @param liquidity Amount of liquidity tokens to remove from pool
	/// @param amountAMin Minimum amount of tokenA to receive
	/// @param amountBMin Minimum amount of tokenB to receive
	/// @param to Address to send received tokens to
	/// @param deadline Unix timestamp denoting time tx must execute by
	/// @param poolId Id of pool for withdrawal of LP tokens from Masterchef
	/// @param toWithdraw Bool to withdraw lp tokens from masterchef
	function withdraw(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toWithdraw
	) external onlyManager onlyRemoveLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		IERC20 tokenAInterface = IERC20(tokenA);
		IERC20 tokenBInterface = IERC20(tokenB);

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISTENT_PAIR");

		if (toWithdraw) {
			(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
			bool withdrawalHappened = _withdrawLPTokensFromMasterChef(poolId, pair.balanceOf(address(this)), liquidity);
			if (withdrawalHappened) {
				_transferMasterchefRewards(rewardTokens, rewards);
			}
		}

		require(pair.balanceOf(address(this)) >= liquidity, "INSUFFICIENT_LIQUIDITY");
		_approve(address(SUSHISWAP_ROUTER), pair, liquidity);

		uint256 tokenABalanceBeforeLiquidityRemoval = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceBeforeLiquidityRemoval = tokenBInterface.balanceOf(address(this));

		SUSHISWAP_ROUTER.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

		uint256 tokenABalanceAfterLiquidityRemoval = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceAfterLiquidityRemoval = tokenBInterface.balanceOf(address(this));
		require(tokenABalanceAfterLiquidityRemoval > tokenABalanceBeforeLiquidityRemoval, "MUST_INCREASE");
		require(tokenBBalanceAfterLiquidityRemoval > tokenBBalanceBeforeLiquidityRemoval, "MUST_INCREASE");
	}

	/// @notice claims Sushi rewards from Masterchef contract
	/// @dev reverts if no sushi claimable
	function claimSushi(uint256 poolId) external onlyManager onlyMiscOperation {
		uint256 pendingSushi = MASTERCHEF.pendingSushi(poolId, address(this));
		require(pendingSushi > 0, "NO_CLAIMABLE");

		(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
		MASTERCHEF.harvest(poolId, TREASURY);
		_transferMasterchefRewards(rewardTokens, rewards);

		emit RewardClaimed(address(MASTERCHEF.SUSHI()), pendingSushi);
	}

	/// @dev Will claim any non-sushi assets for specific poolId
	function _depositLPTokensToMasterChef(uint256 poolId, uint256 amount) private {
		MASTERCHEF.deposit(poolId, amount, address(this));
	}

	/// @dev Will claim any non-sushi assets for specific poolId
	function _withdrawLPTokensFromMasterChef(
		uint256 poolId,
		uint256 currentBalance,
		uint256 withdrawalAmount
	) private returns (bool) {
		if (currentBalance > 0) {
			if (currentBalance >= withdrawalAmount) {
				// Don't need to withdraw in this case
				return false;
			}
			withdrawalAmount = withdrawalAmount.sub(currentBalance);
		}

		(uint256 contractAmount, ) = MASTERCHEF.userInfo(poolId, address(this));
		require(contractAmount >= withdrawalAmount, "INVALID_AMOUNT");
		MASTERCHEF.withdraw(poolId, withdrawalAmount, address(this));
		return true;
	}

	/// @dev pendingTokens() returns arrays but will always only return one value
	/// @dev see https://github.com/sushiswap/sushiswap/blob/56cedd0e06a6cf665083b3a662f9f77b80303ebe/contracts/mocks/ComplexRewarder.sol#L97
	function _checkRewards(uint256 poolId) private returns (IERC20[] memory, uint256[] memory) {
		IComplexRewarder rewarder = MASTERCHEF.rewarder(poolId);
		if (address(rewarder) != address(0)) {
			return rewarder.pendingTokens(poolId, address(this), 0);
		}
		return (new IERC20[](0), new uint256[](0));
	}

	function _transferMasterchefRewards(IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) private {
		uint256 rewardAmountsLength = rewardAmounts.length;
		for (uint256 i = 0; i < rewardAmountsLength; ++i) {
			uint256 currentReward = rewardAmounts[i];
			if (currentReward > 0) {
				IERC20 token = rewardTokens[i];
				token.safeTransfer(TREASURY, currentReward);
				emit RewardClaimed(address(token), currentReward);
			}
		}
	}

	function _approve(address spender, IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComplexRewarder.sol";

struct UserInfo {
	uint256 amount;
	int256 rewardDebt;
}

struct PoolInfo {
	uint128 accSushiPerShare;
	uint64 lastRewardBlock;
	uint64 allocPoint;
}

/// @title Interface for the SushiSwap MasterChef V2 contract
interface IMasterChefV2 {
	function deposit(uint256 pid, uint256 amount, address to) external;

	function withdraw(uint256 pid, uint256 amount, address to) external;

	function userInfo(uint256 pid, address user) external returns (uint256, uint256);

	function harvest(uint256 pid, address to) external;

	// solhint-disable-next-line func-name-mixedcase
	function SUSHI() external returns (IERC20);

	function rewarder(uint256 pid) external returns (IComplexRewarder);

	function lpToken(uint256 pid) external returns (IERC20);

	function pendingSushi(uint256 pid, address user) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComplexRewarder {
	function pendingTokens(uint256 pid, address user, uint256) external returns (IERC20[] memory, uint256[] memory);
}

/*
    forked from balancer monorepo (had to be adjusted due to mismatch in needed compiler version):
    https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol
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

pragma solidity >=0.6.11 <=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library WeightedPoolUserData {
	enum JoinKind {
		INIT,
		EXACT_TOKENS_IN_FOR_BPT_OUT,
		TOKEN_IN_FOR_EXACT_BPT_OUT,
		ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
		ADD_TOKEN
	}
	enum ExitKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		EXACT_BPT_IN_FOR_TOKENS_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT,
		REMOVE_TOKEN
	}
}

/* forked from balancer monorepo / had to be adjusted due to mismatch in needed compiler version */
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

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/IERC20.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/helpers/ISignaturesValidator.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/helpers/ITemporarilyPausable.sol";
// import "@balancer-labs/v2-solidity-utils/contracts/misc/IWETH.sol";

import "./IAsset.sol";
// import "./IAuthorizer.sol";
// import "./IFlashLoanRecipient.sol";
// import "./IProtocolFeesCollector.sol";

pragma solidity >=0.6.11 <=0.6.12;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
	// is ISignaturesValidator, ITemporarilyPausable {
	// Generalities about the Vault:
	//
	// - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
	// transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
	// `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
	// calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
	// a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
	//
	// - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
	// while execution control is transferred to a token contract during a swap) will result in a revert. View
	// functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
	// Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
	//
	// - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

	// Authorizer
	//
	// Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
	// outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
	// can perform a given action.

	/**
	 * @dev Returns the Vault's Authorizer.
	 */
	// function getAuthorizer() external view returns (IAuthorizer);

	/**
	 * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
	 *
	 * Emits an `AuthorizerChanged` event.
	 */
	// function setAuthorizer(IAuthorizer newAuthorizer) external;

	/**
	 * @dev Emitted when a new authorizer is set by `setAuthorizer`.
	 */
	// event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

	// Relayers
	//
	// Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
	// Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
	// and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
	// this power, two things must occur:
	//  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
	//    means that Balancer governance must approve each individual contract to act as a relayer for the intended
	//    functions.
	//  - Each user must approve the relayer to act on their behalf.
	// This double protection means users cannot be tricked into approving malicious relayers (because they will not
	// have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
	// Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

	/**
	 * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
	 */
	// function hasApprovedRelayer(address user, address relayer) external view returns (bool);

	/**
	 * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
	 *
	 * Emits a `RelayerApprovalChanged` event.
	 */
	// function setRelayerApproval(
	//     address sender,
	//     address relayer,
	//     bool approved
	// ) external;

	/**
	 * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
	 */
	// event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

	// Internal Balance
	//
	// Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
	// transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
	// when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
	// gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
	//
	// Internal Balance management features batching, which means a single contract call can be used to perform multiple
	// operations of different kinds, with different senders and recipients, at once.

	/**
	 * @dev Returns `user`'s Internal Balance for a set of tokens.
	 */
	// function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

	/**
	 * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
	 * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
	 * it lets integrators reuse a user's Vault allowance.
	 *
	 * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
	 */
	// function manageUserBalance(UserBalanceOp[] memory ops) external payable;

	/**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
	// struct UserBalanceOp {
	//     UserBalanceOpKind kind;
	//     IAsset asset;
	//     uint256 amount;
	//     address sender;
	//     address payable recipient;
	// }

	// There are four possible operations in `manageUserBalance`:
	//
	// - DEPOSIT_INTERNAL
	// Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
	// `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
	// and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
	// relevant for relayers).
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - WITHDRAW_INTERNAL
	// Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
	// it to the recipient as ETH.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_INTERNAL
	// Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_EXTERNAL
	// Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
	// relayers, as it lets them reuse a user's Vault allowance.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `ExternalBalanceTransfer` event.

	// enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

	/**
	 * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
	 * interacting with Pools using Internal Balance.
	 *
	 * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
	 * address.
	 */
	// event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

	/**
	 * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
	 */
	// event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

	// Pools
	//
	// There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
	// functionality:
	//
	//  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
	// balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
	// which increase with the number of registered tokens.
	//
	//  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
	// balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
	// constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
	// independent of the number of registered tokens.
	//
	//  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
	// minimal swap info Pools, these are called via IMinimalSwapInfoPool.

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	/**
	 * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
	 * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
	 * changed.
	 *
	 * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
	 * depending on the chosen specialization setting. This contract is known as the Pool's contract.
	 *
	 * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
	 * multiple Pools may share the same contract.
	 *
	 * Emits a `PoolRegistered` event.
	 */
	// function registerPool(PoolSpecialization specialization) external returns (bytes32);

	/**
	 * @dev Emitted when a Pool is registered by calling `registerPool`.
	 */
	// event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

	/**
	 * @dev Returns a Pool's contract address and specialization setting.
	 */
	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	/**
	 * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
	 * exit by receiving registered tokens, and can only swap registered tokens.
	 *
	 * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
	 * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
	 * ascending order.
	 *
	 * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
	 * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
	 * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
	 * expected to be highly secured smart contracts with sound design principles, and the decision to register an
	 * Asset Manager should not be made lightly.
	 *
	 * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
	 * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
	 * different Asset Manager.
	 *
	 * Emits a `TokensRegistered` event.
	 */
	// function registerTokens(
	//     bytes32 poolId,
	//     IERC20[] memory tokens,
	//     address[] memory assetManagers
	// ) external;

	/**
	 * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
	 */
	// event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

	/**
	 * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
	 * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
	 * must be deregistered in the same `deregisterTokens` call.
	 *
	 * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
	 *
	 * Emits a `TokensDeregistered` event.
	 */
	// function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

	/**
	 * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
	 */
	// event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

	/**
	 * @dev Returns detailed information for a Pool's registered token.
	 *
	 * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
	 * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
	 * equals the sum of `cash` and `managed`.
	 *
	 * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
	 * `managed` or `total` balance to be greater than 2^112 - 1.
	 *
	 * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
	 * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
	 * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
	 * change for this purpose, and will update `lastChangeBlock`.
	 *
	 * `assetManager` is the Pool's token Asset Manager.
	 */
	// function getPoolTokenInfo(bytes32 poolId, IERC20 token)
	//     external
	//     view
	//     returns (
	//         uint256 cash,
	//         uint256 managed,
	//         uint256 lastChangeBlock,
	//         address assetManager
	//     );

	/**
	 * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
	 * the tokens' `balances` changed.
	 *
	 * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
	 * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
	 *
	 * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
	 * order as passed to `registerTokens`.
	 *
	 * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
	 * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
	 * instead.
	 */
	function getPoolTokens(
		bytes32 poolId
	) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

	/**
	 * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
	 * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
	 * Pool shares.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
	 * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
	 * these maximums.
	 *
	 * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
	 * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
	 * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
	 * back to the caller (not the sender, which is important for relayers).
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
	 * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
	 * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
	 *
	 * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
	 * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
	 * withdrawn from Internal Balance: attempting to do so will trigger a revert.
	 *
	 * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
	 * directly to the Pool's contract, as is `recipient`.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	struct JoinPoolRequest {
		IAsset[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	/**
	 * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
	 * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
	 * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
	 * `getPoolTokenInfo`).
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
	 * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
	 * it just enforces these minimums.
	 *
	 * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
	 * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
	 * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
	 * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
	 * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
	 *
	 * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
	 * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
	 * do so will trigger a revert.
	 *
	 * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
	 * `tokens` array. This array must match the Pool's registered tokens.
	 *
	 * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
	 * passed directly to the Pool's contract.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}

	/**
	 * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
	 */
	// event PoolBalanceChanged(
	//     bytes32 indexed poolId,
	//     address indexed liquidityProvider,
	//     IERC20[] tokens,
	//     int256[] deltas,
	//     uint256[] protocolFeeAmounts
	// );

	// enum PoolBalanceChangeKind { JOIN, EXIT }

	// Swaps
	//
	// Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
	// they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
	// aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
	//
	// The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
	// In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
	// and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
	// More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
	// individual swaps.
	//
	// There are two swap kinds:
	//  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
	// `onSwap` hook) the amount of tokens out (to send to the recipient).
	//  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
	// (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
	//
	// Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
	// the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
	// tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
	// swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
	// the final intended token.
	//
	// In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
	// Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
	// certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
	// much less gas than they would otherwise.
	//
	// It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
	// Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
	// updating the Pool's internal accounting).
	//
	// To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
	// involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
	// minimum amount of tokens to receive (by passing a negative value) is specified.
	//
	// Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
	// this point in time (e.g. if the transaction failed to be included in a block promptly).
	//
	// If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
	// the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
	// passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
	// same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
	//
	// Finally, Internal Balance can be used when either sending or receiving tokens.

	// enum SwapKind { GIVEN_IN, GIVEN_OUT }

	/**
	 * @dev Performs a swap with a single Pool.
	 *
	 * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
	 * taken from the Pool, which must be greater than or equal to `limit`.
	 *
	 * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
	 * sent to the Pool, which must be less than or equal to `limit`.
	 *
	 * Internal Balance usage and the recipient are determined by the `funds` struct.
	 *
	 * Emits a `Swap` event.
	 */
	// function swap(
	//     SingleSwap memory singleSwap,
	//     FundManagement memory funds,
	//     uint256 limit,
	//     uint256 deadline
	// ) external payable returns (uint256);

	/**
	 * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
	 * the `kind` value.
	 *
	 * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
	 * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	// struct SingleSwap {
	//     bytes32 poolId;
	//     SwapKind kind;
	//     IAsset assetIn;
	//     IAsset assetOut;
	//     uint256 amount;
	//     bytes userData;
	// }

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	// function batchSwap(
	//     SwapKind kind,
	//     BatchSwapStep[] memory swaps,
	//     IAsset[] memory assets,
	//     FundManagement memory funds,
	//     int256[] memory limits,
	//     uint256 deadline
	// ) external payable returns (int256[] memory);

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
	 */
	event Swap(
		bytes32 indexed poolId,
		IERC20 indexed tokenIn,
		IERC20 indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut
	);

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	// struct FundManagement {
	//     address sender;
	//     bool fromInternalBalance;
	//     address payable recipient;
	//     bool toInternalBalance;
	// }

	/**
	 * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
	 * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
	 *
	 * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
	 * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
	 * receives are the same that an equivalent `batchSwap` call would receive.
	 *
	 * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
	 * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
	 * approve them for the Vault, or even know a user's address.
	 *
	 * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
	 * eth_call instead of eth_sendTransaction.
	 */
	// function queryBatchSwap(
	//     SwapKind kind,
	//     BatchSwapStep[] memory swaps,
	//     IAsset[] memory assets,
	//     FundManagement memory funds
	// ) external returns (int256[] memory assetDeltas);

	// Flash Loans

	/**
	 * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
	 * and then reverting unless the tokens plus a proportional protocol fee have been returned.
	 *
	 * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
	 * for each token contract. `tokens` must be sorted in ascending order.
	 *
	 * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
	 * `receiveFlashLoan` call.
	 *
	 * Emits `FlashLoan` events.
	 */
	// function flashLoan(
	//     IFlashLoanRecipient recipient,
	//     IERC20[] memory tokens,
	//     uint256[] memory amounts,
	//     bytes memory userData
	// ) external;

	/**
	 * @dev Emitted for each individual flash loan performed by `flashLoan`.
	 */
	// event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

	// Asset Management
	//
	// Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
	// tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
	// `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
	// controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
	// prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
	// not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
	//
	// However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
	// for example by lending unused tokens out for interest, or using them to participate in voting protocols.
	//
	// This concept is unrelated to the IAsset interface.

	/**
	 * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
	 *
	 * Pool Balance management features batching, which means a single contract call can be used to perform multiple
	 * operations of different kinds, with different Pools and tokens, at once.
	 *
	 * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
	 */
	// function managePoolBalance(PoolBalanceOp[] memory ops) external;

	// struct PoolBalanceOp {
	//     PoolBalanceOpKind kind;
	//     bytes32 poolId;
	//     IERC20 token;
	//     uint256 amount;
	// }

	/**
	 * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
	 *
	 * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
	 *
	 * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
	 * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
	 */
	// enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

	/**
	 * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
	 */
	// event PoolBalanceManaged(
	//     bytes32 indexed poolId,
	//     address indexed assetManager,
	//     IERC20 indexed token,
	//     int256 cashDelta,
	//     int256 managedDelta
	// );

	// Protocol Fees
	//
	// Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
	// permissioned accounts.
	//
	// There are two kinds of protocol fees:
	//
	//  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
	//
	//  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
	// swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
	// Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
	// Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
	// exiting a Pool in debt without first paying their share.

	/**
	 * @dev Returns the current protocol fee module.
	 */
	// function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

	/**
	 * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
	 * error in some part of the system.
	 *
	 * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
	 *
	 * While the contract is paused, the following features are disabled:
	 * - depositing and transferring internal balance
	 * - transferring external balance (using the Vault's allowance)
	 * - swaps
	 * - joining Pools
	 * - Asset Manager interactions
	 *
	 * Internal Balance can still be withdrawn, and Pools exited.
	 */
	// function setPaused(bool paused) external;

	/**
	 * @dev Returns the Vault's WETH instance.
	 */
	// function WETH() external view returns (IWETH);
	// solhint-disable-previous-line func-name-mixedcase
}

/* forked from balancer monorepo / had to be adjusted due to mismatch in needed compiler version */
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

pragma solidity >=0.6.11 <=0.6.12;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
	// solhint-disable-previous-line no-empty-blocks
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 *
 *  FOR TESTING PURPOSES ONLY
 *
 */

contract WETH9 is ERC20 {
	event Deposit(address sender, uint256 value);
	event Withdrawal(address withdrawer, uint256 value);

	// solhint-disable-next-line no-empty-blocks
	constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

	receive() external payable {
		deposit();
	}

	function deposit() public payable {
		_mint(msg.sender, msg.value);
		emit Deposit(msg.sender, msg.value);
	}

	function withdraw(uint wad) public {
		_burn(msg.sender, wad);
		msg.sender.transfer(wad);
		emit Withdrawal(msg.sender, wad);
	}

	function mint(address account, uint256 amount) external {
		_mint(account, amount);
	}
}

pragma solidity ^0.6.0;

interface MockInterface {
	/**
	 * @dev After calling this method, the mock will return `response` when it is called
	 * with any calldata that is not mocked more specifically below
	 * (e.g. using givenMethodReturn).
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called regardless of arguments. If the methodId and arguments
	 * are mocked more specifically (using `givenMethodAndArguments`) the latter
	 * will take precedence.
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called with matching arguments. These exact calldataMocks will take
	 * precedence over all other calldataMocks.
	 * @param call ABI encoded calldata (methodId and arguments)
	 * @param response ABI encoded response that will be returned if contract is invoked with calldata
	 */
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	/**
	 * @dev Returns the number of times anything has been called on this mock since last reset
	 */
	function invocationCount() external returns (uint);

	/**
	 * @dev Returns the number of times the given method has been called on this mock since last reset
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 */
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	/**
	 * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
	 * @param call ABI encoded calldata (methodId and arguments)
	 */
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	/**
	 * @dev Resets all mocked methods and invocation counts.
	 */
	 function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }
	
	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";
	bytes public constant DEFAULT_FALLBACK_VALUE = abi.encode(false);

	// A linked list allows easy iteration and inclusion checks
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation = DEFAULT_FALLBACK_VALUE;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() public {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) override external {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) override external {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) override external {
		_givenAnyReturn(uintToBytes(response));	
	}

	function givenAnyReturnAddress(address response) override external {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() override external {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) override external  {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) override external {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) override external {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);		
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) override external {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) override external {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) override external {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);		
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);		
	}

	function givenCalldataRunOutOfGas(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);	
	}

	function invocationCount() override external returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) override external returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) override external returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() override external {
		// Reset all exact calldataMocks
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		// We cannot compary bytes
		while(mockHash != MOCKS_LIST_END_HASH) {
			// Reset all mock maps
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			// Set next mock to remove
			nextMock = calldataMocks[mockHash];
			// Remove from linked list
			calldataMocks[mockHash] = "";
			// Update mock hash
			mockHash = keccak256(nextMock);
		}
		// Clear list
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		// Reset all any calldataMocks
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			// Remove from linked list
			methodIdMocks[currentAnyMock] = 0x0;
		}
		// Clear list
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = DEFAULT_FALLBACK_VALUE;
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				//expensive call to EC multiply contract
				s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	fallback () payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		// First, check exact matching overrides
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		// Then check method Id overrides
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		// Last, use the fallback override
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		// Record invocation as separate call so we don't rollback in case we are called with STATICCALL
		(, bytes memory r) = address(this).call{gas: 100000}(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);
		
		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}