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

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part 
 of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves 
 of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone 
 to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also 
 return variable names that may need to be specified exactly may be referenced (if you are 
 confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract
    // why should we track *proportion* instead of value of liquidity? <https://youtu.be/QNPyFs8Wybk?t=752>
    /* S Kaunov, [7/14/22 9:21 PM]
next "magical" part of math for me here
is we measure _ratio_ of liquidity change, but at the same time we _sum up_ this changes to get total value
either I did a mistake, either need to wrap my head around this

S Kaunov, [7/14/22 9:38 PM]
hmmm....
_total liquidity_ is sqrt(k), so in totalLiquidity state variable we store not the information about liquidity itself, but about _liquidity providers_ contributions: how did they moved the curve higher or lower
...

S Kaunov, [7/14/22 10:45 PM]
could you help me to understand what is share mathematically

when we init DEX we raise liquidity from zero to the amount (thanks to 1:1), does it generates shares?

if I correctly went through formulas, then ratio of new shares to totalShares is equal xAmo to xRes (as well as yAmo to yRes)

soooo, is share a _geometric mean_ of values added to the constant product?

S Kaunov, [7/14/22 10:51 PM]
if it is,
what why is it possible to sum them?

S Kaunov, [7/14/22 10:54 PM]
for each user we track geometric mean of his contribution
to return him amounts of tokens which constitutes the same geometric mean but in new proportion
...

S Kaunov, [7/14/22 11:05 PM]
so... summing up their contributions in form of geometric means is equal to total liquidity indeed
with no respect to ratio of one reserve to another

if these speculations (instead of solid math) of mine are correct
than the sense of this is much clearer */

    /* We can use different functions of _k_ for metrics to track `liquidity`. But `sqrt(k)` is a marvelous finding that dramatically simplify calculations in conjuction with tracking of 
    individual contribution as *ratio* of `liquidity` change. */
    uint public totalLiquidity;
    mapping (address => uint) public liquidity;

    /* ========== EVENTS ========== */
    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address indexed swapper, uint trade, uint eth, uint token_am);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address indexed swapper, uint trade, uint eth, uint token_am);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(
        address indexed swapper, 
        uint addedLiquidity, 
        uint eth, 
        uint token_am
    );

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(address indexed swapper, uint removedLiquidity, uint eth, uint token_am);

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX 
     itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). 
     Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made 
     to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) 
     as equal to eth balance of contract.
     */
     // can we avoid `init` for adding liquidity `function`?
     //  ifeasible, since it would defeat `nonZeroTrading` `modifier` on `deposit`
     // we should set here `totalLiquidity` to sqrt(tokens*amount) == amount (they're equal)
    function init(uint256 tokens) public payable returns (uint256) {
        // should we check `balance` or `value`?
        require(msg.value > 0, "zero init isn't allowed");
        require(msg.value == tokens, "for 1:1 liquidity send precisely eth as tokens");
        require(token.transferFrom(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            address(this),
            msg.value));

        totalLiquidity = msg.value;
        liquidity[msg.sender] = msg.value;
        emit LiquidityProvided(msg.sender, msg.value, msg.value, msg.value);
        return tokens;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model 
     and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {
        // k == xReserves * yReserves
        // (xReserves + deduceFee(xInput)) * (yReserves - yOutput) == k
        // (xReserves + deduceFee(xInput)) * (yReserves - yOutput) == xReserves * yReserves
        // (yReserves - yOutput) == xReserves * yReserves / (xReserves + deduceFee(xInput))
        // yOutput = yReserves - xReserves * yReserves / (xReserves + /* deduceFee( */xInput/* ) */);
        // == yReserves * (1 - xReserves / (xReserves + deduceFee(xInput)))
        // == yReserves * ((xReserves + deduceFee(xInput)) - xReserves / (xReserves + deduceFee(xInput)))
        // == yReserves * deduceFee(xInput) / (xReserves + deduceFee(xInput))
        yOutput = yReserves * xInput / (xReserves + xInput);
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    // try ~~two versions~~ for `assert`ion
    /* S Kaunov, [7/16/22 5:22 PM]
console
✓ Should send less tokens after the first trade (ethToToken called)
        tokenToEth
25000000000000000008000000000000000000
25000000000000000009935606060606060607

S Kaunov, [7/16/22 5:22 PM]
the numbers are k

S Kaunov, [7/16/22 5:22 PM]
I wonder if the difference comes from rounding of division.

S Kaunov, [7/16/22 5:23 PM]
console
✓ Should send 1 $BAL to DEX in exchange for _ $ETH
25000000000000000009935606060606060607
25000000000000000014878048780487804880

25000000000000000014878048780487804880
25000000000000000017581632653061224492

S Kaunov, [7/16/22 5:24 PM]
[In reply to S Kaunov]
Not when k is calculated to assert, but when pricing number are got.

S Kaunov, [7/16/22 5:25 PM]
disappointing that k is growing
diminishingly ofc
and the number of transactions only three
but would be nicer to see it shifting both ways

S Kaunov, [7/16/22 5:26 PM]
What acceptable k deviation would you set, if you wanted to assert that it's *constant*?

S Kaunov, [7/16/22 5:35 PM]
If someone knows an explanation on how much can k change in different circumstances — pls, share with me. Would be interesting to see. */
    modifier assertK(uint msgValue) {
        uint balance_initial = address(this).balance - msgValue;
        uint k = balance_initial * token.balanceOf(address(this));
        _;
        assert(address(this).balance * token.balanceOf(address(this)) == k); 
    }

    //  try to *set* _k_ to protect from `selfdestruct` or `transfer`
    /* It's not feasible to _set_ `k`. 1) It fluctuates due to rounding in `price()`. (?) 2) It will "ruin" math for liquidity
    tracking. It's marvelously modelled to work without `sqrt` function, and it's not obvious how to make everything work together
    relying on fixed `k`.abi
    
    It seems like receiving values can't bring much of damage. */
    // enum k_bal_type {init, current}
    function getK_initial(/* k_bal_type bal_type */) internal view returns (uint) {
        // if (bal_type == k_bal_type.init) {
            return (address(this).balance - msg.value) * token.balanceOf(address(this));
        // }
        // if (bal_type == k_bal_type.current) {
        //     return address(this).balance * token.balanceOf(address(this));
        // }
    }
    
    modifier nonZeroTrading(uint amountToCheck) {
        require(amountToCheck > 0 && address(this).balance > 0 && token.balanceOf(address(this)) > 0, "we don't trade zeros");
        _;
    }

    function deduceFee(uint amount) pure internal returns (uint) {
        return amount * 997 / 1000;
    }
    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable /* assertK(msg.value) */ nonZeroTrading(msg.value) returns (uint256 tokenOutput) {
        // uint balance_fee = address(this).balance - msg.value + /* deduceFee( */msg.value/* ) */;
        // tokenOutput = token.balanceOf(address(this)) - getK_initial(/* k_bal_type.init */) / balance_fee;
        tokenOutput = price(msg.value, address(this).balance - msg.value, token.balanceOf(address(this)));
        require(token.transfer(msg.sender, tokenOutput), "transfer failed");
        emit EthToTokenSwap(msg.sender, 0, msg.value, tokenOutput);
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public /* assertK(0) */ nonZeroTrading(tokenInput) returns (uint256 ethOutput) {
        // require(tokenInput > 0, "we don't trade zeros");
        // ethOutput = address(this).balance - getK_initial(/* k_bal_type.init */) / (token.balanceOf(address(this)) + /* deduceFee( */tokenInput/* ) */);
        ethOutput = price(tokenInput, token.balanceOf(address(this)), address(this).balance);

        takeTokens(tokenInput);

        (bool success, /* data */) = payable(msg.sender).call{value: ethOutput}("");
        require(success, "failed to send eth");
        emit TokenToEthSwap(msg.sender, 0, ethOutput, tokenInput);
    }

    // TODO redo fees on `deposit` instead of swapping
    
    // function compInitialLiquidity(uint tokenBalance) view internal returns (uint) {
    //     // return sqrt((address(this).balance - msg.value)^2 + tokenBalance^2);
    //     return compLiquidity(
    //         address(this).balance - msg.value,
    //         tokenBalance
    //     );
    // }

    //  understand if sqrt(balance * balance) is arbitrary or deducible

    function takeTokens(uint amount) internal {
        require(token.allowance(msg.sender, address(this)) >= amount, "allowance is too low");
        require(token.transferFrom(msg.sender, address(this), amount), "trFrom failed");
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount 
     of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve 
     function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined 
     by the AMM.
     */
    function deposit() public payable nonZeroTrading(msg.value) returns (uint256 tokensDeposited) {
        // k == address(this).balance * token.balanceOf(address(this))
        // (msg.value + address(this).balance) * (token.balanceOf(address(this)) + tokensDeposited) == k
        // (token.balanceOf(address(this)) + tokensDeposited) == k / (msg.value + address(this).balance)
        
        // tokensDeposited = (getK_initial(/* k_bal_type.init */) / address(this).balance - token.balanceOf(address(this)));
        tokensDeposited = msg.value * token.balanceOf(address(this)) / (address(this).balance - msg.value);
        tokensDeposited += tokensDeposited * 3 / 1000; // add fee

        takeTokens(tokensDeposited);

        // mint
        // uint liquidity_delta = compLiquidity(address(this).balance, token.balanceOf(address(this)) - tokensDeposited + deduceFee(tokensDeposited)) 
        //     - compInitialLiquidity(token.balanceOf(address(this)) - tokensDeposited);
        uint liquidity_delta = totalLiquidity * msg.value / (address(this).balance - msg.value);
        liquidity[msg.sender] += liquidity_delta;
        totalLiquidity += liquidity_delta;
        emit LiquidityProvided(msg.sender, liquidity_delta, msg.value, tokensDeposited);
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the `msg.sender` could end up getting very little back if the liquidity 
     is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public nonZeroTrading(amount) returns (uint256 eth_amount, uint256 token_amount) {
        uint balance_initial_eth = address(this).balance;
        uint balance_initial_tok = token.balanceOf(address(this));

        // k == address(this).balance * token.balanceOf(address(this))
        // (msgValue + address(this).balance) * (token.balanceOf(address(this)) + amount) == k
        // (msgValue + address(this).balance) == k / (token.balanceOf(address(this)) + amount)
        
        // eth_amount = getK_initial(/* k_bal_type.init */) / (token.balanceOf(address(this)) + amount) - address(this).balance;
        
        // eth_bal_old * tok_bal_old == (eth_bal_old - eth_amount) * (tok_bal_old - token_amount)
        // (eth_bal_old * tok_bal_old) / (eth_bal_old - eth_amount) == tok_bal_old - token_amount
        // token_amount == tok_bal_old - (eth_bal_old * tok_bal_old) / (eth_bal_old - eth_amount) == tok_bal_old * (1 - eth_bal_old / (eth_bal_old - eth_amount)) == tok_bal_old * (eth_bal_old + eth_amount - eth_bal_old) / (eth_bal_old - eth_amount) == tok_bal_old * eth_amount / (eth_bal_old - eth_amount)
        // token_amount == tok_bal_old * eth_amount / (eth_bal_old - eth_amount)

        // (totalLiquidity - amount) / totalLiquidity == (eth_bal - eth_amount) / eth_bal = (tok_bal - token_amount) / tok_bal
        // eth_bal - eth_amount = (totalLiquidity - amount) * eth_bal / totalLiquidity
        // eth_amount = eth_bal - (totalLiquidity - amount) * eth_bal / totalLiquidity = eth_bal * (1 - totalLiquidity + amount) / totalLiquidity = eth_bal * (amount + 1)/totalLiquidity - eth_bal/totalLiquidity

        require(amount <= liquidity[msg.sender], "your deposits aren't enough");
        eth_amount = amount * address(this).balance / totalLiquidity;
        token_amount = amount * token.balanceOf(address(this)) / totalLiquidity;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        // _________________________________

        // uint liquidity_target = compLiquidity(address(this).balance - eth_amount, token.balanceOf(address(this)) - token_amount);
        // uint liquidity_delta = compLiquidity(address(this).balance, token.balanceOf(address(this))) - liquidity_target;
        // require(liquidity[msg.sender] >= liquidity_delta, "#outdated you didn't `deposit`ed enough");

        require(token.transfer(msg.sender, token_amount), "failed tok transfer");

        (bool success, /* data */) = payable(msg.sender).call{value: eth_amount}("");
        require(success, "eth tr failed");
        // check balance after ext call
        assert(
            address(this).balance == balance_initial_eth - eth_amount
            && token.balanceOf(address(this)) == balance_initial_tok - token_amount
        );
        emit LiquidityRemoved(msg.sender, amount, eth_amount, token_amount);
    }
}