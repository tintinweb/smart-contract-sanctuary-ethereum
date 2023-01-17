// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//This is an exercise to put into practice a basic Dex based on Uniswap's V1 protocol,
//as a pair that exchanges native ETH with the ERC20 token address we introduce on contract deployment.
contract DexV1 {
    using SafeMath for uint256;
    IERC20 token;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProvided;
    uint256 public ethRes;
    uint256 public tokenRes;
    uint256 public msgVal;
    uint256 public tokenAmount;

    constructor(address yeahTokenAddress) public {
        token = IERC20(yeahTokenAddress);
    }

    //getters
    function getLiquidity() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidity;
    }

    function getTokenReserves() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getLiquidityProvided(address liquidityProvider) public view returns (uint256) {
        require(
            liquidityProvided[liquidityProvider] > 0,
            "address has not provided liquidity to this pool"
        );
        return liquidityProvided[liquidityProvider];
    }

    //to init, the contract must be approved to perform the transfer
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "dex has already been initialized");
        //if someone send eth before calling the init function, the liquidity provided will be captured by
        //the user that calls init.
        totalLiquidity = address(this).balance;
        liquidityProvided[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens)); //transfer call for the amount we set as an input to this func
        return totalLiquidity;
    }

    function price(uint256 a, uint256 x, uint256 y) private pure returns (uint256) {
        //the constant k remains the same
        //x * y = k
        // x * y = x' * y'

        //the amount of tokens we recieve depends on the multiplication of x and y to mantain the constant
        // x' * y' = k
        //a is the token amount we input in the exchange
        // x + a = x'
        //b is the token amount we recieve
        // y - b = y'

        //(x + a)(y - b) = k

        //solving to b we deduce:
        //b = (y * a) / (x + a)

        //with the 0,3% trading fee:
        //b = (y * a * 0,997) / (x + a * 0,997)

        uint256 input_with_fee = a.mul(997);
        uint256 numerator = y.mul(input_with_fee);
        uint256 denominator = x.mul(1000).add(input_with_fee);
        return numerator / denominator;
    }

    function ethToToken() public payable returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //ETH is X, tokens are Y
        //y - b = y'
        //how many tokens are we getting?
        uint256 tokensBought = price(msg.value, address(this).balance.sub(msg.value), tokenReserve); // a , x=x'- a, y
        require(token.transfer(msg.sender, tokensBought), "failed to transfer ETH");
        return tokensBought;
    }

    function ethToTokenView(uint256 msgValue) public view returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //ETH is X, tokens are Y
        //y - b = y'
        //how many tokens are we getting?
        uint256 tokensBought = price(msgValue, address(this).balance, tokenReserve); // a , x=x'- a, y

        return tokensBought;
    }

    function tokenToEth(uint256 tokens) public payable returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //in this case, tokens is X, Y is eth
        //y - b = y'
        //how many ETH are we getting?
        uint256 ethBought = price(tokens, tokenReserve, address(this).balance); // a , x, y
        require(token.transferFrom(msg.sender, address(this), tokens), "failed to transfer tokens");
        (bool sent, ) = msg.sender.call{value: ethBought}("");
        require(sent, "failed to send ETH");
        return ethBought;
    }

    function tokenToEthView(uint256 tokens) public view returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        //in this case, tokens is X, Y is eth
        //y - b = y'
        //how many ETH are we getting?
        uint256 ethBought = price(tokens, tokenReserve, address(this).balance); // a , x, y
        return ethBought;
    }

    function deposit() public payable returns (uint256) {
        //checks the original ETH reserve, subtracting what we have sent
        uint256 eth_reserve = address(this).balance.sub(msg.value);
        ethRes = eth_reserve;
        //Token reserve
        uint256 token_reserve = token.balanceOf(address(this));
        tokenRes = token_reserve;
        //token amount example with a pool with reserves of 4 eth and 8000 Dai
        // we send 1 eth, 1 * 8000 / 4 = 2000, therefore it will input the balance of 1 2000, which is correct.
        uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
        msgVal = msg.value;
        tokenAmount = token_amount;

        //((eth sent * total liquidity shares ) / eth reserves ) + 1
        // the previous formula with 18 decimals makes it so that the LP tokens minted to the user is
        //equal to the eth send, since the total liquidity shares in V1 is always going to be equal to the eth reserves.
        uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;
        //liquidity tokens added to user balance
        liquidityProvided[msg.sender] = liquidityProvided[msg.sender].add(liquidity_minted);
        //update total liquidity for future liquidity operations
        totalLiquidity = totalLiquidity.add(liquidity_minted);
        //call transferFrom with the approved tokens to this contract to finish adding liquidity
        require(token.transferFrom(msg.sender, address(this), token_amount));
        return liquidity_minted;

        //on V2 the process is transferFunction agnostic, there is no approval, instead, the tokens must be sent to the contract,
        //the contract itself will keep track of the token balance after each interaction, and will calculate how many tokens you have sent,
        //based on the difference between the balanceOf its own address in the ERC20 contract, with its own balance data structure.
    }

    function withdraw(uint256 amount) public returns (uint256, uint256) {
        //ERC20 token call to know what is the balance of this contract
        uint256 token_reserve = token.balanceOf(address(this));
        //on the same pool mentioned before, with 5 eth and 10000 DAI the user inputs 1 as amount
        //1 * 5 / 5 = 1
        uint256 eth_amount = amount.mul(address(this).balance) / totalLiquidity;
        //1 * 10000 / 5 = 2000
        uint256 token_amount = amount.mul(token_reserve) / totalLiquidity;
        //liquidity subtracted from the users liquidity balance -1 = 0
        liquidityProvided[msg.sender] = liquidityProvided[msg.sender].sub(eth_amount);

        totalLiquidity = totalLiquidity.sub(eth_amount);
        //transfer eth to user natively
        payable(msg.sender).transfer(eth_amount);
        //transfer 2000 dai to user
        require(token.transfer(msg.sender, token_amount));
        return (eth_amount, token_amount);
    }
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