/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/misc/deposit_repay/interfaces/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File contracts/lib/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 is IERC20Upgradeable{
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


// File contracts/lib/interfaces/MarketTokenInterface.sol


pragma solidity ^0.8.0;

interface MarketTokenInterface {
    function isMarketToken() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function underlying() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockTimestamp() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function accountTokens(address account) external view returns (uint256);
    function accountBorrows(address account) external view returns (uint256,uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function comptroller() external view returns (address);
    function interestRateModel() external view returns (address);

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerSecond() external view returns (uint);
    function supplyRatePerSecond() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function _setComptroller(address newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external  returns (uint);
    function _reduceReserves(uint reduceAmount) external  returns (uint);
    function _setInterestRateModel(address newInterestRateModel) external  returns (uint);



    
}

interface MarketTokenEtherInterface is MarketTokenInterface{

    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address marketTokenCollateral) external payable;

    function _addReserves() external payable returns (uint);

}

interface MarketTokenERC20Interface is MarketTokenInterface{

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address marketTokenCollateral) external returns (uint);
    function sweepToken(address token) external ;

    function _addReserves(uint addAmount) external returns (uint);

}


// File contracts/lib/interfaces/ComptrollerInterface.sol


pragma solidity ^0.8.0;

interface ComptrollerInterface {

    function isComptroller() external view returns(bool);
    function oracle() external view returns(address);
    function distributioner() external view returns(address);
    function closeFactorMantissa() external view returns(uint);
    function liquidationIncentiveMantissa() external view returns(uint);
    function maxAssets() external view returns(uint);
    function accountAssets(address account,uint index) external view returns(address);
    function markets(address market) external view returns(bool,uint);

    function pauseGuardian() external view returns(address);
    function paused() external view returns(bool);
    function marketMintPaused(address market) external view returns(bool);
    function marketRedeemPaused(address market) external view returns(bool);
    function marketBorrowPaused(address market) external view returns(bool);
    function marketRepayBorrowPaused(address market) external view returns(bool);
    function marketTransferPaused(address market) external view returns(bool);
    function marketSeizePaused(address market) external view returns(bool);
    function borrowCaps(address market) external view returns(uint);
    function supplyCaps(address market) external view returns(uint);
    function liquidateWhiteAddresses(uint index) external view returns(address);

    function enterMarkets(address[] calldata marketTokens) external returns (uint[] memory);
    function exitMarket(address marketToken) external returns (uint);

    function mintAllowed(address marketToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address marketToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address marketToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address marketToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address marketToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address marketToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address marketToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address marketToken, address src, address dst, uint transferTokens) external;

    function liquidateCalculateSeizeTokens(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        uint repayAmount) external view returns (uint, uint);

    function getHypotheticalAccountLiquidity(
        address account,
        address marketTokenModify,
        uint redeemTokens,
        uint borrowAmount) external view returns (uint, uint, uint);

    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address marketToken) external view returns (bool) ;
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;
    function getAllMarkets() external view returns (address[] memory);
    function isDeprecated(address marketToken) external view returns (bool);
    function isMarketListed(address marketToken) external view returns (bool);

    
}


// File contracts/lib/interfaces/PriceOracle.sol


pragma solidity ^0.8.0;

interface PriceOracle {
    /**
      * @notice Get the underlying price of a marketToken asset
      * @param marketToken The marketToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e(36-decimals)).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MarketTokenInterface marketToken) external view returns (uint);
}


interface PriceSource {
    /**
     * @notice Get the price of an token asset.
     * @param token The token asset to get the price of.
     * @return The token asset price in USD as a mantissa (scaled by 1e8).
    */
    function getPrice(address token) external view returns (uint);
}


// File contracts/misc/deposit_repay/interfaces/uniswapv2.sol


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

interface IUniswapV2Router02 {

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


// File contracts/misc/deposit_repay/swap/SwapHandlerInterface.sol


pragma solidity ^0.8.0;

interface SwapHandlerInterface {

    function router() external returns(address);

    function estimateBestOut(address tokenIn, address tokenOut, uint256 amountIn, address ignorePair) external view returns (uint256, address[] memory);


    function estimateBestIn(address tokenIn, address tokenOut, uint256 amountOut, address ignorePair) external view returns (uint256, address[] memory);

    function swapBestOut(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountIn, 
        uint256 amountOutMin, 
        uint256 deadline,
        address ignorePair
    ) external returns (uint256);


    function swapBestIn(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountInMax, 
        uint256 amountOut, 
        uint256 deadline,
        address ignorePair
    ) external returns (uint256);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address recipient,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address recipient,
        uint deadline
    ) external returns (uint[] memory amounts);

}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/misc/deposit_repay/DepositToRepayV1.sol


pragma solidity ^0.8.0;








contract DepositToRepayV1 {

    using SafeMathUpgradeable for uint;
    using SafeERC20Upgradeable for IERC20;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public owner;
    address payable public feeManager;
    ComptrollerInterface public comptroller;
    IWETH public WETH;
    SwapHandlerInterface public swapHandler;

    constructor(ComptrollerInterface _comptroller, IWETH _WETH, SwapHandlerInterface _swapHandler, address payable _feeManager){
        owner = msg.sender;
        feeManager = _feeManager;
        comptroller = _comptroller;
        WETH = _WETH;
        swapHandler = _swapHandler;
    }

    function estimateInternal(
        address account, 
        MarketTokenInterface collateralMarket, 
        MarketTokenInterface borrowMarket, 
        uint depositAmount, 
        uint repayAmount,
        uint slippage
    ) internal returns(bytes memory) {

        require(depositAmount == 0 || repayAmount == 0);
        address collateralUnderlying = isEtherMarket(collateralMarket) ? address(WETH) : collateralMarket.underlying();
        address borrowUnderlying = isEtherMarket(borrowMarket) ? address(WETH) : borrowMarket.underlying();

        uint amountInMax;
        uint amountOutMin;
        address[] memory path;
        if(depositAmount > 0) { 

            if(collateralUnderlying == borrowUnderlying){
                amountInMax = depositAmount;
                amountOutMin = depositAmount;
                repayAmount = depositAmount;
            }else{
                (uint _amountOutMin, address[] memory _path) = swapHandler.estimateBestOut(collateralUnderlying, borrowUnderlying, depositAmount, address(0));
                amountInMax = depositAmount;
                amountOutMin = _amountOutMin.mul(uint(1e18).sub(slippage)).div(1e18);
                repayAmount = amountOutMin;
                path = _path;
            }

            // Check repayAmount, make sure repayAmount less than or equal to accountBorrowAmount.
            uint accountBorrowAmount = borrowMarket.borrowBalanceCurrent(account);
            repayAmount = accountBorrowAmount >= repayAmount ? repayAmount : accountBorrowAmount;

        }else if(repayAmount > 0) { 

            if(collateralUnderlying == borrowUnderlying){
                repayAmount = (repayAmount == type(uint).max) ? borrowMarket.borrowBalanceCurrent(account) : repayAmount; //the max repay
                amountOutMin = repayAmount;
                amountInMax = repayAmount;
                depositAmount = repayAmount;
            }else{
                repayAmount = (repayAmount == type(uint).max) ? borrowMarket.borrowBalanceCurrent(account) : repayAmount; //the max repay
                (uint _amountInMax, address[] memory _path) = swapHandler.estimateBestIn(collateralUnderlying, borrowUnderlying, repayAmount, address(0));
                amountOutMin = repayAmount;
                amountInMax = _amountInMax.mul(uint(1e18).add(slippage)).div(1e18);
                depositAmount = amountInMax;
                path = _path;
            }

            // Check depositAmount, make sure depositAmount less than or equal to accountSupplyAmount.
            uint accountSupplyAmount = collateralMarket.balanceOfUnderlying(account);
            depositAmount = accountSupplyAmount >= depositAmount ? depositAmount : accountSupplyAmount;

        }

        return abi.encode(depositAmount,repayAmount,amountOutMin,amountInMax,path);

    }

    /**
    * @notice Using the collateral market to repay the borrow market
    * @param account The user
    * @param collateralMarket The collateral market
    * @param borrowMarket The borrow market
    * @param depositAmount The collateral amount or 0. If 0, the repayAmount must bigger than 0
    * @param repayAmount The repay amount or 0. If 0, the depositAmount must bigger than 0
    * @param slippage The slippage for swap
    * @return (depositAmount,repayAmount,amountOutMin,amountInMax,path)
    */
    function estimate(
        address account, 
        MarketTokenInterface collateralMarket, 
        MarketTokenInterface borrowMarket, 
        uint depositAmount, 
        uint repayAmount,
        uint slippage
    ) public returns(uint, uint, uint, uint, address[] memory) {

        return abi.decode(estimateInternal(account, collateralMarket, borrowMarket, depositAmount, repayAmount, slippage), (uint, uint, uint, uint, address[]));
    }


    /**
    * @notice Using the collateral market to repay the borrow market
    * @param account The user
    * @param collateralMarket The collateral market
    * @param borrowMarket The borrow market
    * @param depositAmount The collateral amount or 0. If 0, the repayAmount must bigger than 0
    * @param repayAmount The repay amount or 0. If 0, the depositAmount must bigger than 0
    * @param slippage The slippage for swap
    */
    function depositRepay(
        address account, 
        MarketTokenInterface collateralMarket, 
        MarketTokenInterface borrowMarket, 
        uint depositAmount, 
        uint repayAmount,
        uint slippage
    ) external {
        require(msg.sender == account,"Error account");
        uint liquidity = getLiquidity();
        address collateralUnderlying = isEtherMarket(collateralMarket) ? address(WETH) : collateralMarket.underlying();
        address borrowUnderlying = isEtherMarket(borrowMarket) ? address(WETH) : borrowMarket.underlying();
       
       bool forRepayAmount = repayAmount > 0 ? true : false;

        address[] memory path;
        {
            (uint _depositAmount, uint _repayAmount,,,address[] memory _path) = estimate(account, collateralMarket, borrowMarket, depositAmount, repayAmount,slippage);
            depositAmount = _depositAmount;
            repayAmount = _repayAmount;
            path = _path;
        }
        
        require(depositAmount <= getTokenMaxAmount(collateralMarket),"DepositToRepay: Insufficient liquidity"); // Check liquidity

        //  Borrowing collateralUnderlying from WePiggy
        if(isEtherMarket(collateralMarket)){
           MarketTokenEtherInterface(address(collateralMarket)).borrow(depositAmount);
           WETH.deposit{value:depositAmount}();
        }else{
           MarketTokenERC20Interface(address(collateralMarket)).borrow(depositAmount);
        }

        //  Calculate the repayAmount and get it by swapping
        if(collateralUnderlying != borrowUnderlying){
            transferInternal(path[0], payable(address(swapHandler)), depositAmount);
            if(forRepayAmount){            
                swapHandler.swapTokensForExactTokens(repayAmount, depositAmount, path, address(this), block.timestamp); 
            }else{
                swapHandler.swapExactTokensForTokens(depositAmount, repayAmount, path, address(this), block.timestamp); 
            }
        }

        // RepayBorrowBehalf
        if(isEtherMarket(borrowMarket)){
            WETH.withdraw(repayAmount);
            MarketTokenEtherInterface(address(borrowMarket)).repayBorrowBehalf{value:repayAmount}(account);
        }else{
            approveInternal(borrowUnderlying,address(borrowMarket),repayAmount);
            MarketTokenERC20Interface(address(borrowMarket)).repayBorrowBehalf(account,repayAmount);
        }

        //  Get the account's pToken and redeem it.
        // collateralTokenAmount = (depositAmount * 1e18 / exchangeRateStored) + 1
        uint collateralTokenAmount = depositAmount.mul(1e18).div(collateralMarket.exchangeRateStored()).add(1);
        collateralMarket.transferFrom(account, address(this), collateralTokenAmount);
        if(isEtherMarket(collateralMarket)){
            MarketTokenEtherInterface(address(collateralMarket)).redeem(collateralTokenAmount);
        }else{
            MarketTokenERC20Interface(address(collateralMarket)).redeem(collateralTokenAmount);
        }

        //  Repay the collateralUnderlying to WePiggy
        uint256 borrowBalance = collateralMarket.borrowBalanceCurrent(address(this));
        if(isEtherMarket(collateralMarket)){
            MarketTokenEtherInterface(address(collateralMarket)).repayBorrow{value:borrowBalance}();
        }else{
            approveInternal(collateralUnderlying, address(collateralMarket), borrowBalance);
            MarketTokenERC20Interface(address(collateralMarket)).repayBorrow(borrowBalance);
        }

        require(liquidity <= getLiquidity(),"DepositToRepay: liquidity decreased");

        transferInternal(collateralUnderlying, payable(account), balanceOf(collateralUnderlying));
        transferInternal(borrowUnderlying, payable(account), balanceOf(borrowUnderlying));

    }

    function approveInternal(address token,address spender,uint amount) internal {
        IERC20 erc20 = IERC20(token);
        uint allowance = erc20.allowance(address(this), spender);
        if (allowance < amount) {
            erc20.safeApprove(spender, type(uint256).max);
        }
    }

    function transferInternal(address asset, address payable to, uint amount) internal{
        if(amount == 0){
            return;
        }

        if (asset == ETH) {
            (bool success,) = to.call{value : amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(asset).safeTransfer(to, amount);
    }

    function getLiquidity() public view returns(uint256){
        (uint err, uint256 liquidity, uint shortfall) = comptroller.getAccountLiquidity(address(this));
        if (err != 0 || shortfall != 0) {
            return 0;
        }
        return liquidity;
    }

    function getTokenMaxAmount(MarketTokenInterface marketToken) public view returns(uint256){
        (bool isListed,) = comptroller.markets(address(marketToken));
        require(isListed,"DepositToRepay: marketToken is not surpported");

        PriceOracle oracle = PriceOracle(comptroller.oracle());
        uint price = oracle.getUnderlyingPrice(marketToken); 
        uint liquidity = getLiquidity();

        return liquidity.mul(1e18).div(price);
    }

    function isEtherMarket(MarketTokenInterface marketToken) public view returns(bool){
        return marketToken.underlying() == ETH;
    }
    

    function balanceOf(address asset) public view returns(uint){
        if (asset == ETH) {
            return address(this).balance;
        }
        return IERC20(asset).balanceOf(address(this));
    }


    function _enterMarket(address marketToken) external {
        require(msg.sender == owner,"caller is not the owner");
        if(comptroller.checkMembership(address(this), marketToken)){
            return;
        }
        address[] memory markets = new address[](1);
        markets[0] = marketToken;
        uint[] memory errs = comptroller.enterMarkets(markets);
        require(errs[0] == 0, "DepositToRepay: enter market error");
    } 

    function _exitMarket(address marketToken) external {
        require(msg.sender == owner,"caller is not the owner");
        if(comptroller.checkMembership(address(this), marketToken)){
            return;
        }
        uint err = comptroller.exitMarket(marketToken);
        require(err == 0, "DepositToRepay: exit market error");
    }

    function _approve(address token,address spender,uint amount) external{
        require(msg.sender == owner,"caller is not the owner");
        approveInternal(token, spender, amount);
    }

    function _withdraw(address asset, address payable to, uint amount) external{
        require(msg.sender == owner,"caller is not the owner");

        uint balance = balanceOf(asset);
        if(balance < amount){
            amount = balance;
        }
        transferInternal(asset, to, amount);
    }

    function _setOwner(address _owner) external{
        require(msg.sender == owner,"caller is not the owner");
        require(_owner != address(0), "new owner is the zero address");

        owner = _owner;
    }

    function _setFeeManager(address payable _feeManager) external{
        require(msg.sender == owner,"caller is not the owner");
        require(_feeManager != address(0), "new feeManager is the zero address");
        
        feeManager = _feeManager;
    }

    function _setSwapHandler(address _swapHandler) external{
        require(msg.sender == owner,"caller is not the owner");
        require(_swapHandler != address(0), "new swapHandler is the zero address");

        swapHandler = SwapHandlerInterface(_swapHandler);
    }

    receive() external payable {
    }


}