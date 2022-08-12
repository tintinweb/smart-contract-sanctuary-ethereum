// SPDX-License-Identifier: MIT

/**
Safu contract.
We are the number 23 lovers.
Join us, chill, we have a surprise for ya ;)

https://twitter.com/Number23_real
https://number23.network/
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract Number23 is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    //Transfer Type
    uint8 constant FEE_EXEMPT = 0;
    uint8 constant TRANSFER = 1;
    uint8 constant BUY = 2;
    uint8 constant SELL = 3;

    //Basic info
    string private constant NAME = "Number23";
    string private constant SYMBOL = "23";
    uint8 private constant DECIMALS = 18;

    uint256 private constant _totalSupply = 23 * 10 ** DECIMALS;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    //Fees
    uint256 public _marketingBuyFee;
    uint256 public _rewardBuyFee;
    uint256 public _liquidityBuyFee;
    uint256 public _marketingSellFee;
    uint256 public _rewardSellFee;
    uint256 public _liquiditySellFee;
    uint256 public constant _maxFeePercentage = 10;
    address public _marketingWallet;
    address public _liquidityWallet;
    uint256 private _marketingBalance;
    uint256 private _rewardBalance;
    uint256 private _liquidityBalance;
    mapping(address => bool) private _feeExclusions;

    //Sixty nine
    uint256 public _rewardCounter;
    uint256 public _rewardMinBuy = 1 * 10 ** (DECIMALS) / 10; //0.1 eth
    address public _lastWinner;
    uint256 private constant TWENTY_THREE = 23;
    uint256 private constant ROUTER_FEE_PCT = 25; //uniswap take 0.25%
    uint256 private constant MAX_PCT = 10000;

    //Limit transaction
    uint256 public _transactionUpperLimit = _totalSupply;
    uint256 private constant MIN_TRANS_UPPER_LIMIT = _totalSupply / 1000;
    mapping(address => bool) private _limitExclusions;

    //Router & pair
    IUniswapV2Router02 private _swapRouter;
    address public _swapPair;
    bool private _inSwap;

    //event
    event UpdateRewardCounter(
        uint256 currentCounter
    );

    event Reward(
        address winner,
        uint256 tokenAmount
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    //// constructor
    constructor(address routerAddress) {
        _balances[_msgSender()] = totalSupply();

        _feeExclusions[address(this)] = true;
        _feeExclusions[_msgSender()] = true;

        _marketingWallet = _msgSender();
        _liquidityWallet = _msgSender();

        setFees(3, 2, 1, 5, 3, 1);
        setTransactionUpperLimit(_totalSupply / 50);
        if (routerAddress != address(0)) {
            setSwapRouter(routerAddress);
        }

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    //// modifier
    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    //// receive
    receive() external payable {}
    //// fallback
    //// external
    function setFeeWallets(
        address marketingWallet,
        address liquidityWallet
    )
    external
    onlyOwner
    {
        _marketingWallet = marketingWallet;
        _liquidityWallet = liquidityWallet;
    }

    function setExcludedFromFees(address addr, bool value) external onlyOwner {
        _feeExclusions[addr] = value;
    }

    function setRewardMinBuy(uint256 rewardMinBuy) external onlyOwner {
        _rewardMinBuy = _rewardMinBuy;
    }

    //// public
    function setFees(
        uint256 marketingBuyFee,
        uint256 rewardBuyFee,
        uint256 liquidityBuyFee,
        uint256 marketingSellFee,
        uint256 rewardSellFee,
        uint256 liquiditySellFee
    )
    public
    onlyOwner
    {
        require(_maxFeePercentage >= marketingBuyFee + rewardBuyFee + liquidityBuyFee);
        require(_maxFeePercentage >= marketingSellFee + rewardSellFee + liquiditySellFee);
        _marketingBuyFee = marketingBuyFee;
        _rewardBuyFee = rewardBuyFee;
        _liquidityBuyFee = liquidityBuyFee;
        _marketingSellFee = marketingSellFee;
        _rewardSellFee = rewardSellFee;
        _liquiditySellFee = liquiditySellFee;
    }

    function isExcludedFromFees(address addr)
    public
    view
    returns (bool)
    {
        return _feeExclusions[addr];
    }


    function setTransactionUpperLimit(uint256 limit) public onlyOwner {
        require(limit > MIN_TRANS_UPPER_LIMIT);
        _transactionUpperLimit = limit;
    }

    function setLimitExclusions(address addr, bool value) public onlyOwner {
        _limitExclusions[addr] = value;
    }

    function isExcludedFromLimit(address addr)
    public
    view
    returns (bool)
    {
        return _limitExclusions[addr];
    }

    function setSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Invalid router address");

        _swapRouter = IUniswapV2Router02(routerAddress);
        _approve(address(this), routerAddress, type(uint256).max);

        _swapPair = IUniswapV2Factory(_swapRouter.factory()).getPair(address(this), _swapRouter.WETH());
        if (_swapPair == address(0)) {// pair doesn't exist beforehand
            _swapPair = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        }
    }

    //// internal
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transferring amount");

        if (!isExcludedFromLimit(sender) && !isExcludedFromLimit(recipient)) {
            require(amount <= _transactionUpperLimit, "Transferring amount exceeds the maximum allowed");
        }

        if (_inSwap) {
            basicTransfer(sender, recipient, amount);
            return;
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        uint8 transferType = transferType(sender, recipient);
        uint256 afterFeeAmount = takeFees(amount, transferType);
        _balances[recipient] = _balances[recipient].add(afterFeeAmount);


        if (transferType == BUY || transferType == SELL) {
            _rewardCounter++;
            if (shouldReward(amount, transferType)) {
                //Only reward on BUY transaction => Then we send the reward for recipient (buyer)
                reward(recipient);
            }
            emit UpdateRewardCounter(_rewardCounter);
        }

        emit Transfer(sender, recipient, afterFeeAmount);
    }

    function transferType(address from, address to) internal view returns (uint8) {
        if (isExcludedFromFees(from) || isExcludedFromFees(to)) return FEE_EXEMPT;
        if (from == _swapPair) return BUY;
        if (to == _swapPair) return SELL;
        return TRANSFER;
    }

    function basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function takeFees(uint256 amount, uint8 transferType) private returns (uint256) {
        if (transferType != BUY && transferType != SELL) {
            return amount;
        }
        uint256 marketingPercentage = transferType == BUY ? _marketingBuyFee : _marketingSellFee;
        uint256 rewardPercentage = transferType == BUY ? _rewardBuyFee : _rewardSellFee;
        uint256 liquidityPercentage = transferType == BUY ? _liquidityBuyFee : _liquiditySellFee;

        uint256 marketingFee = amount.mul(marketingPercentage).div(100);
        uint256 rewardFee = amount.mul(rewardPercentage).div(100);
        uint256 liquidityFee = amount.mul(liquidityPercentage).div(100);

        _marketingBalance += marketingFee;
        _rewardBalance += rewardFee;
        _liquidityBalance += liquidityFee;

        uint256 totalFee = marketingFee.add(rewardFee).add(liquidityFee);
        _balances[address(this)] = _balances[address(this)].add(totalFee);
        uint256 afterFeeAmount = amount.sub(totalFee, "Insufficient amount");

        if (shouldSwapFees(transferType)) {
            swapFees();
            swapAndLiquify();
        }

        return afterFeeAmount;
    }

    function shouldSwapFees(uint8 transferType) private returns (bool) {
        return transferType == SELL && balanceOf(address(this)) > 0;
    }

    function swapFees() private swapping {
        uint256 ethToMarketing = swapTokensForEth(_marketingBalance);
        (bool successSentMarketing,) = _marketingWallet.call{value : ethToMarketing}("");
        _marketingBalance = 0;
    }

    function swapAndLiquify() private swapping {
        uint256 half = _liquidityBalance.div(2);
        uint256 otherHalf = _liquidityBalance.sub(half);
        uint256 ethToLiquidity = swapTokensForEth(half);
        _swapRouter.addLiquidityETH{value : ethToLiquidity}(
            address(this),
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
        _liquidityBalance = 0;

        emit SwapAndLiquify(half, ethToLiquidity, otherHalf);
    }

    function swapTokensForEth(uint256 amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        // Swap
        _swapRouter.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp + 360);

        // Return the amount received
        return address(this).balance;
    }

    function shouldReward(uint256 amount, uint8 transferType) private returns (bool){
        if (transferType != BUY) {
            return false;
        }
        if (_rewardCounter < TWENTY_THREE) {
            return false;
        }
        if (_rewardMinBuy == 0) {
            return true;
        }
        address[] memory path = new address[](2);
        path[0] = _swapRouter.WETH();
        path[1] = address(this);

        // We don't subtract the buy fee since the amount is pre-tax
        uint256 tokensOut = _swapRouter.getAmountsOut(_rewardMinBuy, path)[1].mul(MAX_PCT.sub(ROUTER_FEE_PCT)).div(MAX_PCT);
        return amount >= tokensOut;
    }

    function reward(address winner) private {
        uint256 rewardAmount = _rewardBalance;
        _lastWinner = winner;
        _rewardCounter = 0;
        _rewardBalance = 0;
        basicTransfer(address(this), winner, rewardAmount);

        emit Reward(winner, rewardAmount);
    }

    //// private
    //// view / pure
    function totalFee()
    external
    view
    returns (uint256)
    {
        return _marketingBuyFee.add(_rewardBuyFee).add(_liquidityBuyFee);
    }

    //region IERC20
    function totalSupply()
    public
    override
    pure
    returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account)
    public
    view
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    public
    override
    returns (bool)
    {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount, "Insufficient allowance");
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    //region IERC20Metadata
    function name()
    public
    override
    pure
    returns (string memory)
    {
        return NAME;
    }

    function symbol()
    public
    override
    pure
    returns (string memory)
    {
        return SYMBOL;
    }

    function decimals()
    public
    override
    pure
    returns (uint8)
    {
        return DECIMALS;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.5.0;

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