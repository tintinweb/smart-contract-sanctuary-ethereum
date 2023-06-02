// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract UnofDexSwap {
    using SafeMath  for uint;
    
    IUnofDexSwapRouter private router;  
    address private wrappedToken; 

    constructor(address _router, address _wrappedToken) {
        router = IUnofDexSwapRouter(_router);
        wrappedToken = _wrappedToken;
    }  

    function getAllowance(address tokenAddress) public view returns(uint allowance) {
        IERC20 token = IERC20(tokenAddress);
        allowance = token.allowance(msg.sender, address(this));
    }

    function getQuote(address tokenInAddress, address tokenOutAddress, uint tokenInAmount) public view returns(uint tokenOutAmount) {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenInAddress;
        path[1] = tokenOutAddress;

        uint[] memory amount = router.getAmountsOut(tokenInAmount, path);
        tokenOutAmount = amount[1];
    }

    function getNativeQuote(address tokenOutAddress, uint tokenInAmount) external view returns(uint tokenOutAmount) {
        address[] memory path;
        path = new address[](2);
        path[0] = wrappedToken;
        path[1] = tokenOutAddress;

        uint[] memory amount = router.getAmountsOut(tokenInAmount, path);
        tokenOutAmount = amount[1];
    }

    function provideTokenAllowance(address sender, address tokenAddress, uint amount) private {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(sender, address(this), amount);
        token.approve(address(router), amount);
    }   

    function swapNonNativeToken(address tokenInAddress, address tokenOutAddress, uint tokenInAmount) external returns(uint swapAmount) {
        uint contractAllowance = getAllowance(tokenInAddress);
        require(contractAllowance > 0, "Allowance error");

        provideTokenAllowance(msg.sender, tokenInAddress, tokenInAmount);
        
        address[] memory path;
        path = new address[](2);
        path[0] = tokenInAddress;
        path[1] = tokenOutAddress;

        uint tokenOutAmount = router.getAmountsOut(tokenInAmount, path)[1];
        uint deadline = block.timestamp + 5 minutes;

        uint[] memory amounts = router.swapExactTokensForTokens(
            tokenInAmount, 
            tokenOutAmount,
            path, 
            msg.sender, 
            deadline
        );

        swapAmount = amounts[1]; 
    }

    function swapNativeToken(address tokenOutAddress) external payable returns(uint swapAmount) {
        address[] memory path;
        path = new address[](2);
        path[0] = wrappedToken;
        path[1] = tokenOutAddress;

        uint tokenOutAmount = router.getAmountsOut(msg.value, path)[1];
        uint deadline = block.timestamp + 5 minutes;

        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            tokenOutAmount, 
            path, 
            msg.sender, 
            deadline
        );

        swapAmount = amounts[1]; 
    }

    function addNonNativeTokenLiquidity(address token0Address, address token1Address, uint token0Amount, uint token1Amount, uint slippage) external returns(uint token0AmountAdded, uint token1AmountAdded, uint liquidity) {
        uint contractToken0Allowance = getAllowance(token0Address);
        require(contractToken0Allowance > 0, "Allowance error");
        uint contractToken1Allowance = getAllowance(token1Address);
        require(contractToken1Allowance > 0, "Allowance error");

        provideTokenAllowance(msg.sender, token0Address, token0Amount);
        provideTokenAllowance(msg.sender, token1Address, token1Amount);

        uint token0Slippage = token0Amount.mul(slippage).div(100); 
        uint token1Slippage = token1Amount.mul(slippage).div(100); 
        uint token0AmountMin = token0Amount.sub(token0Slippage);
        uint token1AmountMin = token1Amount.sub(token1Slippage);

        uint deadline = block.timestamp + 5 minutes;
    
        (token0AmountAdded, token1AmountAdded, liquidity) = router.addLiquidity(
            token0Address, 
            token1Address, 
            token0Amount, 
            token1Amount,
            token0AmountMin, 
            token1AmountMin, 
            msg.sender, 
            deadline
        );
    }

    function addNativeTokenLiquidity(address token1Address, uint token1Amount, uint slippage) external payable returns(uint nativeTokenAmountAdded, uint token1AmountAdded, uint liquidity) {
        uint contractAllowance = getAllowance(token1Address);
        require(contractAllowance > 0, "Allowance error");

        provideTokenAllowance(msg.sender, token1Address, token1Amount);

        uint nativeTokenAmount = msg.value; 

        uint nativeTokenSlippage = nativeTokenAmount.mul(slippage).div(100); 
        uint token1Slippage = token1Amount.mul(slippage).div(100); 

        uint nativeTokenMin = nativeTokenAmount.sub(nativeTokenSlippage);
        uint token1AmountMin = token1Amount.sub(token1Slippage);

        uint deadline = block.timestamp + 5 minutes;

        (nativeTokenAmountAdded, token1AmountAdded, liquidity) = router.addLiquidityETH{value: msg.value}(
            token1Address, 
            token1Amount,
            token1AmountMin, 
            nativeTokenMin, 
            msg.sender, 
            deadline
        );
    }

    fallback() external payable { }
    receive() external payable {}

}

interface IUnofDexSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}