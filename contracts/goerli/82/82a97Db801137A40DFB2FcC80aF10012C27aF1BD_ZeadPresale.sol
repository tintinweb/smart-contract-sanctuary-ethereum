pragma solidity ^0.8.0;

import { SafeMath } from "SafeMath.sol";

import { IERC20 } from "IERC20.sol";

import { PresaleAccessControl } from "PresaleAccessControl.sol";

import { UniswapV2Quoter } from "UniswapV2Quoter.sol";

// Presale contract for the Zead token
contract ZeadPresale is PresaleAccessControl {
    using SafeMath for uint256;

    // Constants for the presale
    uint256 public constant INITIAL_USDT_PRICE =  0.000001 * 1e18; // 0.001 USDT (18 decimals)
    uint256 public constant STAGE_INCREMENT = 0.0000005 * 1e18; // 0.0005 USDT (18 decimals)
    uint256 public constant TOKENS_PER_STAGE = 2e9; // 2 billion tokens
    uint256 public constant TOTAL_TOKENS = 1e10; // 10 billion tokens
    uint8 public constant NUM_STAGES = 4; // 5 Stages, Start at 0

    // Mapping from stage number to token price
    mapping (uint8 => uint256) public stagePrices;

    // Current stage of the presale
    uint8 public currentStage = 0;

    // Total number of tokens sold
    uint256 public tokensSold;

    // Total number of tokens sold in the current stage
    uint256 public tokensSoldInStage;

    // Total sales in USDT
    uint256 public totalSalesInUSDT;

    // UniswapV2Quoter
    UniswapV2Quoter private _uniswapV2Quoter;

    // Zead token contract address
    IERC20 public ZEADContractInterface;

    // USDT token contract address
    IERC20 public USDTContractInterface;

    // WETH token contract address
    IERC20 public WETHContractInterface;

    mapping(address => uint256) private _userDeposits;
    mapping(address => bool) private _hasClaimed;

    // Constructor to initialize the stage prices and token contract address
    constructor(address _uniswapV2QuoterAddress, address _ZEADContract) PresaleAccessControl() {
        _uniswapV2Quoter = UniswapV2Quoter(_uniswapV2QuoterAddress);

        // Set the initial stage price to the USDT price
        stagePrices[0] = INITIAL_USDT_PRICE;

        // Set the stage prices for the remaining stages
        for (uint8 i = 1; i <= NUM_STAGES; i++) {
            stagePrices[i] = stagePrices[i - 1].add(STAGE_INCREMENT);
        }

        // Set the token contract address
        ZEADContractInterface = IERC20(_ZEADContract);
        // Set the usdt contract address
        USDTContractInterface = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // Set the weth contract address
        WETHContractInterface = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    // Function to return the current Stage Price
    function getCurrentStagePrice() public view returns (uint256) {
        return stagePrices[currentStage];
    }

    // Function to return the total remaining tokens
    function getTotalRemainingTokens() public view returns (uint256) {
        return TOTAL_TOKENS.sub(tokensSold);
    }

    // Function to return the remaining tokens of the stage
    function getRemainingTokensInStage() public view returns (uint256) {
        return TOKENS_PER_STAGE.sub(tokensSoldInStage);
    }

    // Function to return the remaining tokens of the stage
    function getClaimableTokens() public view returns (uint256) {
        return _userDeposits[_msgSender()];
    }

    // Function to calculate the cost for the specified token amount in USDT
    function calculateCostInUSDT(uint256 amount) public returns (uint256) {
        // Calculate the cost in USDT
        uint256 costInUSDT = amount.mul(getCurrentStagePrice());
        return costInUSDT / 1e12; // USDT has 6 Decimals
    }

    // Function to calculate the cost for the specified token amount in WETH
    function calculateCostInWETH(uint256 amount) public returns (uint256) {
        // Calculate the cost in USDT
        uint256 costInUSDT = calculateCostInUSDT(amount);

        // Quote the Cost as WETH
        return _uniswapV2Quoter.quotePrice(costInUSDT, address(USDTContractInterface), address(WETHContractInterface));
    }

    // Function to buy tokens with USDT during the presale
    function buyWithUSDT(uint256 amount) public payable hasPresaleStarted {
        // First check if the amount exceeds the remaining tokens in stage
        uint remainingTokensInStage = getRemainingTokensInStage();
        if (amount > remainingTokensInStage) {
            // If true then sell the remaining tokens in stage
            amount = remainingTokensInStage;
        }

        require(amount > 0, "All Tokens sold!");

        // Calculate the cost in USDT
        uint costInUSDT = calculateCostInUSDT(amount);

        // Check allowance of USDT
        uint256 usdtAllowance = USDTContractInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(costInUSDT <= usdtAllowance, "Not enough allowance to pull the required USDT.");

        // Pay the Cost in USDT
        (bool success, ) = address(USDTContractInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                costInUSDT
            )
        );
        require(success, "USDT Payment failed.");

        // Deposit the bought token amount
        _userDeposits[_msgSender()] += amount;

        // Increase the total number of tokens sold
        tokensSold = tokensSold.add(amount);

        // Increase the total number of tokens sold in stage
        tokensSoldInStage = tokensSoldInStage.add(amount);

        // Increase the total sales in USDT
        totalSalesInUSDT += costInUSDT;

        // Check if the maximum number of tokens for the current stage has been reached
        if (tokensSoldInStage == TOKENS_PER_STAGE) {
            // Advance to the next stage
            _advanceStage();
        }
    }


    // Function to buy tokens with ETH during the presale
    function buyWithETH(uint256 amount) public payable hasPresaleStarted {
        // First check if the amount exceeds the remaining tokens in stage
        uint remainingTokensInStage = getRemainingTokensInStage();
        if (amount > remainingTokensInStage) {
            // If true then sell the remaining tokens in stage
            amount = remainingTokensInStage;
        }

        require(amount > 0, "All Tokens sold!");

        // Calculate the cost in USDT
        uint256 costInUSDT = calculateCostInUSDT(amount);

        // Quote the Cost as WETH
        uint costInWeth = _uniswapV2Quoter.quotePrice(costInUSDT, address(USDTContractInterface), address(WETHContractInterface));

        //Pay the Cost in ETH
        (bool success, ) = payable(owner()).call{value: costInWeth}("");
        require(success, "ETH Payment failed.");

        // Deposit the bought token amount
        _userDeposits[_msgSender()] += amount;

        // Increase the total number of tokens sold
        tokensSold = tokensSold.add(amount);

        // Increase the total number of tokens sold in stage
        tokensSoldInStage = tokensSoldInStage.add(amount);

        // Increase the total sales in USDT
        totalSalesInUSDT += costInUSDT;

        // Check if the maximum number of tokens for the current stage has been reached
        if (tokensSoldInStage == TOKENS_PER_STAGE) {
            // Advance to the next stage
            _advanceStage();
        }
    }



    // Function to claim tokens for the user
    function claimTokens() external virtual hasClaimingStarted returns (bool success) {
        // First check if the sender has allready claimed his tokens
        require(!_hasClaimed[_msgSender()], "Sender has already claimed his tokens!");
        _hasClaimed[_msgSender()] = true;

        // Get the deposited token amount of the sender
        uint256 amount = getClaimableTokens();
        require(amount > 0, "Sender has no tokens to claim!");

        // Send the deposited tokens to the sender
        (success, ) = address(ZEADContractInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                owner(),
                _msgSender(),
                amount * 1e18
            )
        );
        require(success, "Claiming failed.");

    }

    // Function to advance to the next stage of the presale
    function _advanceStage() private {
        // Increase the current stage if it's less than the total number of stages
        if (currentStage < NUM_STAGES) {
            // Reset the total number of tokens sold
            tokensSoldInStage = 0;

            // Increment the current stage
            currentStage++;
        }
    }
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

pragma solidity >=0.7.0 <0.9.0;

import { Ownable } from "Ownable.sol";

contract PresaleAccessControl is Ownable {
    bool public presaleStarted = false;
    bool public claimingStarted = false;

    constructor() Ownable() {
    }

    modifier hasPresaleStarted() {
        require(presaleStarted == true);
        _;
    }

    modifier hasClaimingStarted() {
        require(claimingStarted == true);
        _;
    }

    function startPresale() external onlyOwner {
        presaleStarted = true;
    }

    function startClaiming() external onlyOwner {
        claimingStarted = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import { UniswapV2Library } from "UniswapV2Library.sol";
import { IUniswapV2Router02 } from "IUniswapV2Router02.sol";


contract UniswapV2Quoter {

    IUniswapV2Router02 _router;
    address _factory;

    constructor(address uniswapV2Router) {
        _router = IUniswapV2Router02(uniswapV2Router);
        _factory = _router.factory();
    }

    function pairFor(address tokenA, address tokenB) public virtual returns (address pair) {
        return UniswapV2Library.pairFor(_factory, tokenA, tokenB);
    }

    function getReserves(address tokenA, address tokenB) public virtual returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB) = UniswapV2Library.getReserves(_factory, tokenA, tokenB);
        return (reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) public virtual returns (uint amountOut) {
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(_factory, tokenIn, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        return amountOut;
    }

    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) public virtual returns (uint amountIn) {
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(_factory, tokenIn, tokenOut);
        amountIn = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
        return amountIn;
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public virtual returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function quotePrice(uint amountA, address tokenA, address tokenB) public virtual returns (uint amountB) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(_factory, tokenA, tokenB);
        amountB = UniswapV2Library.quote(amountA, reserveA, reserveB);
    }


}

pragma solidity >=0.5.0;

import "IUniswapV2Pair.sol";

import "SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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

pragma solidity >=0.6.2;

import "IUniswapV2Router01.sol";

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