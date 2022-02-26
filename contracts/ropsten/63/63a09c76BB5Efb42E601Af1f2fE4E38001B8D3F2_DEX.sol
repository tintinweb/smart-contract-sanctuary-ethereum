// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DEX {
    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract

    /* ========== VARIABLES ========== */
    uint256 public totalLiquidity; //BAL token total liquidity in this contract
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    event EthToTokenSwap(address sender, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(
        address sender,
        uint256 ethOutput,
        uint256 tokensInput
    );

    event LiquidityDeposited(
        address sender,
        uint256 ethInput,
        uint256 tokensInput
    );

    event LiquidityWithdrawn(
        address sender,
        uint256 ethOutput,
        uint256 tokensOutput
    );

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    /// @notice initialisation function to add starting liquidity to the pool
    function init(uint256 tokens) public payable {
        require(totalLiquidity == 0, "Pool already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(
            token.transferFrom(msg.sender, address(this), tokens),
            "init failed"
        );
    }

    /// @notice Pricing function that determines the amount of tokens outputY for a given amount of inputX.
    /// Based on the formula (amount of x in DEX ) * ( amount of y in DEX ) = k
    /// i.e. outputY / reserveY = inputX / reserveX
    ///      outputY = inputX / reserveX * reserveY
    /// @dev Additionally need to handle 0.3% fee by multiplying by 997 and dividing by 1000
    function price(
        uint256 inputX,
        uint256 reserveX,
        uint256 reserveY
    ) public pure returns (uint256 yOutput) {
        uint256 inputXAfterFees = inputX.mul(997);
        uint256 numerator = inputXAfterFees.mul(reserveY);
        uint256 denominator = (reserveX.mul(1000)).add(inputXAfterFees);
        return (numerator / denominator);
    }

    /// @notice Swap function to exchange ETH for tokens
    /// Set ethInput (inputX), ethReserve(reserveX) and tokenReserve(reserveY)
    /// Use them to calculate tokenOutput (outputY) with the price function
    function ethToToken() public payable {
        require(msg.value > 0, "No eth sent");

        uint256 ethInput = msg.value;
        uint256 ethReserve = address(this).balance.sub(ethInput);
        uint256 token_reserve = token.balanceOf(address(this));

        uint256 tokenOutput = price(ethInput, ethReserve, token_reserve);

        require(
            token.transfer(msg.sender, tokenOutput),
            "ethToToken token transfer failed"
        );
        emit EthToTokenSwap(msg.sender, tokenOutput, ethInput);
    }

    /// @notice Swap function to exchange tokens for ETH
    /// Set tokenInput (inputX), tokenReserve(reserveX) and ethReserve(reserveY)
    /// Use them to calculate ethOutput (outputY) with the price function
    function tokenToEth(uint256 tokenInput) public {
        require(tokenInput > 0, "No tokens sent");

        uint256 ethReserve = address(this).balance;
        uint256 token_reserve = token.balanceOf(address(this));

        uint256 ethOutput = price(tokenInput, token_reserve, ethReserve);

        require(
            token.transferFrom(msg.sender, address(this), tokenInput),
            "tokenToEth transfer tokens failed"
        );

        (bool sent, ) = msg.sender.call{value: ethOutput}("");
        require(sent, "tokenToEth tranfer eth failed");
        emit TokenToEthSwap(msg.sender, ethOutput, tokenInput);
    }

    /// @notice Deposit function to add liquidity to the pool
    /// @dev Eth and Tokens are added at the current ratio
    function deposit() public payable {
        require(msg.value > 0, "No eth sent");

        uint256 ethInput = msg.value;
        uint256 ethReserve = address(this).balance.sub(ethInput);
        uint256 tokenReserve = token.balanceOf(address(this));

        // Token input calculated by multiplying ethInput by the current token / eth ratio
        uint256 tokenInput = (ethInput.mul(tokenReserve) / ethReserve).add(1); // Add 1 is a tiny correction for small numbers

        // New liquiditiy calculated by multiplying totalLiquidity by the ethInput / ethReserve ratio
        // (i.e. the percentage increase * total liquidity)
        uint256 liquidityMinted = ethInput.mul(totalLiquidity) / ethReserve;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidityMinted);
        totalLiquidity = totalLiquidity.add(liquidityMinted);

        require(token.transferFrom(msg.sender, address(this), tokenInput));
        emit LiquidityDeposited(msg.sender, ethInput, tokenInput);
    }

    /// @notice Withdraw function to subtract liquidity from the pool
    function withdraw(uint256 amount) public {
        require(amount > 0, "Can't withdraw 0 tokens");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        // Amount of eth withdrawn is the ethReserve * amountOfLiquidity / totalLiquidity
        uint256 ethOutput = ethReserve.mul(amount) / totalLiquidity;

        // Amount of token withdrawn is the tokenReserve * amountOfLiquidity / totalLiquidity
        uint256 tokenOutput = tokenReserve.mul(amount) / totalLiquidity;

        liquidity[msg.sender] = liquidity[msg.sender].sub(ethOutput);
        totalLiquidity = totalLiquidity.sub(ethOutput);

        // Transfer token and eth to the withdrawer
        (bool sent, ) = msg.sender.call{value: ethOutput}("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenOutput));

        emit LiquidityWithdrawn(msg.sender, ethOutput, tokenOutput);
    }

    /* ========== READ-ONLY FUNCTIONS ========== */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    function getEthLiquidity(address lp) public view returns (uint256) {
        uint256 amount = liquidity[lp];
        uint256 ethReserve = address(this).balance;
        return ethReserve.mul(amount) / totalLiquidity;
    }

    function getTokenLiquidity(address lp) public view returns (uint256) {
        uint256 amount = liquidity[lp];
        uint256 tokenReserve = token.balanceOf(address(this));
        return tokenReserve.mul(amount) / totalLiquidity;
    }
}