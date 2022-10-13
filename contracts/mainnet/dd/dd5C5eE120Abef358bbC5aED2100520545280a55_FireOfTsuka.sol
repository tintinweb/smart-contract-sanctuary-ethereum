/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
/*

ʻʻTHEIR WINGS WILL SHADOW THE SUN. 
THEIR BREATH WILL THE SCORCH EARTH. 
AND THEIR FIRE WILL CONSUME THE WEAK.ʻʻ

In a world full of fake dragons and warrios that lost the way,
Kasui is on a mission to provide an endless amount of fire to 
the project with the greatest vision, Dejitaru Tsuka.
2% of every KASUI transaction is gifted to push TSUKA's mission,
the KASUI code uses the accumulated funds to automatically 
buy TSUKA from the open market and then it sends the tokens 
gathered directly to the 0x..dead address effectively removing
them from circulation, increasing TSUKA price and scarcity.

Website: https://www.fireoftsuka.io/
Telegram: https://twitter.com/fireoftsuka
Twitter: https://twitter.com/fireoftsuka

*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Tokens/FIREOFTSUKA/FireOfTsukav2.sol


pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    
}

contract FireOfTsuka is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    string private constant _name = "Fire Of Tsuka";
    string private constant _symbol = "KASUI";
    uint8 private constant _decimals = 18;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _tTotal; //Total Supply

    uint256 public _maxTxAmount;
    uint256 public _maxWalletAmount;
    uint256 public swapAmount;
    uint256 public _buybackThreshold;

    //Buy Fees
    uint256 private bLPFee; 
    uint256 private bMarketingFee; 
    uint256 private bBuybackFee; 

    //Sell Fee
    uint256 private sLPFee; 
    uint256 private sMarketingFee; 
    uint256 private sBuybackFee; 

    //Early Max Sell Fee (Decay)
    uint256 private sEarlySellFee;
    
    //Previous Fee 
    uint256 private pLPFee = rLPFee;
    uint256 private pMarketingFee = rMarketingFee;
    uint256 private pBuybackFee = rBuybackFee;
    uint256 private pEarlySellFee = rEarlySellFee;

    //Real Fee
    uint256 private rLPFee;
    uint256 private rMarketingFee;
    uint256 private rBuybackFee;
    uint256 private rEarlySellFee;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tMarket;
        uint256 tBuyback;
        uint256 tEarlySell;
        uint256 tAmount;
    }

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public preTrader;
    mapping(address => bool) public bots;

    address payable private _taxWallet1;
    address payable private _taxWallet2;

    address private _buybackTokenReceiver;
    address private _lpTokensReceiver;
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapEnabled;
    bool private swapping;

    //Decaying Tax Logic
    uint256 private decayTaxExpiration;
    mapping(address => uint256) private buyTracker;
    mapping(address => uint256) private lastBuyTimestamp;
    mapping(address => uint256) private sellTracker;

    bool private tradingOpen;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {

        //Initialize numbers for token
        _tTotal = 1000000000 * 10**18; //Total Supply
        _maxTxAmount = _tTotal.mul(200).div(10000); //2%
        _maxWalletAmount = _tTotal.mul(200).div(10000); //2%
        swapAmount = _tTotal.mul(1).div(10000); //0.01%
        _buybackThreshold = 10; //10 wei

        //Buy Fees
        bLPFee = 100; 
        bMarketingFee = 300; 
        bBuybackFee = 200; 

        //Sell Fee
        sLPFee = 100; 
        sMarketingFee = 300; 
        sBuybackFee = 200; 
        sEarlySellFee = 600;
            
        _taxWallet1 = payable(0xCB9802Cd6D02ccE4827e14fadee5dD7A9C905370);
        _taxWallet2 = payable(0xCB9802Cd6D02ccE4827e14fadee5dD7A9C905370);
        _buybackTokenReceiver = 0x000000000000000000000000000000000000dEaD;
        _lpTokensReceiver = 0xCB9802Cd6D02ccE4827e14fadee5dD7A9C905370;

        swapEnabled = true;
        tradingOpen = false;
        swapping = false;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_taxWallet1] = true;
        _isExcludedFromFee[_taxWallet2] = true;
        _isExcludedFromFee[_buybackTokenReceiver] = true;
        _isExcludedFromFee[_lpTokensReceiver] = true;
        _isExcludedFromFee[address(this)] = true;
        preTrader[owner()] = true;

        //initialie decay tax
        decayTaxExpiration = 1 days;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeAllFee() private {
        if (rLPFee == 0 && rMarketingFee == 0 && rBuybackFee == 0 && rEarlySellFee == 0) return;
        
        pLPFee = rLPFee;
        pMarketingFee = rMarketingFee;
        pBuybackFee = rBuybackFee;
        pEarlySellFee = rEarlySellFee;

        rLPFee = 0;
        rMarketingFee = 0;
        rBuybackFee = 0;
        rEarlySellFee = 0;
    }
    
    function restoreAllFee() private {
        rLPFee = pLPFee;
        rMarketingFee = pMarketingFee;
        rBuybackFee = pBuybackFee;
        rEarlySellFee = pEarlySellFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[from] && !bots[to], "You are blacklisted");

        bool takeFee = true;

        if (from != owner() && to != owner() && !preTrader[from] && !preTrader[to] && from != address(this) && to != address(this)) {

            //Trade start check
            if (!tradingOpen) {
                require(preTrader[from], "TOKEN: This account cannot send tokens until trading is enabled");
            }

            //Max wallet Limit
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(balanceOf(to).add(amount) < _maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }
            
            //Max txn amount limit
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");

            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                rLPFee = bLPFee;
                rMarketingFee = bMarketingFee;
                rBuybackFee = bBuybackFee;
                rEarlySellFee = 0;
            }
                
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                rLPFee = sLPFee;
                rMarketingFee = sMarketingFee;
                rBuybackFee = sBuybackFee;
                rEarlySellFee = sEarlySellFee;
            }
           
            if(!swapping && swapEnabled && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if(contractTokenBalance >= _maxTxAmount) {
                    contractTokenBalance = _maxTxAmount;
                }
                
                if (contractTokenBalance > swapAmount) {
                    processDistributions(contractTokenBalance);
                }

            }
            
        }

        //No tax on Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        
        if(!takeFee) {
            removeAllFee();
        }

        //Define Fee amounts
        FeeBreakdown memory fees;
        fees.tLiq = amount.mul(rLPFee).div(10000);
        fees.tMarket = amount.mul(rMarketingFee).div(10000);
        fees.tBuyback = amount.mul(rBuybackFee).div(10000);

        fees.tEarlySell = 0;
        if(rEarlySellFee > 0) {
            uint256 finalEarlySellFee = getUserEarlySellTax(sender, amount, rEarlySellFee);
            fees.tEarlySell = amount.mul(finalEarlySellFee).div(10000);
        }

        //Calculate total fee amount
        uint256 totalFeeAmount = fees.tLiq.add(fees.tBuyback).add(fees.tMarket).add(fees.tEarlySell);
        fees.tAmount = amount.sub(totalFeeAmount);

        //Update balances
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(totalFeeAmount);
        
        emit Transfer(sender, recipient, fees.tAmount);
        if(totalFeeAmount > 0) {
            emit Transfer(sender, address(this), totalFeeAmount);
        }
        restoreAllFee();

        //Update decay tax for user
        //Set for Buys
        if(sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {
            buyTracker[recipient] += amount;
            lastBuyTimestamp[recipient] = block.timestamp;
        }
            
        //Set for Sells
        if (recipient == uniswapV2Pair && sender != address(uniswapV2Router)) {
            sellTracker[sender] += amount;
        }

        // if the sell tracker equals or exceeds the amount of tokens bought,
        // reset all variables here which resets the time-decaying sell tax logic.
        if(sellTracker[sender] >= buyTracker[sender]) {
            resetBuySellDecayTax(sender);
        }
        
        // handles transferring to a fresh wallet or wallet that hasn't bought tokens before
        if(lastBuyTimestamp[recipient] == 0) {
            resetBuySellDecayTax(recipient);
        }

    }
    
    /// @notice Get user decayed tax
    function getUserEarlySellTax(address _seller, uint256 _sellAmount, uint256 _earlySellFee) public view returns (uint256) {
        uint256 _tax = _earlySellFee;

        if(lastBuyTimestamp[_seller] == 0) {
            return _tax;
        }

        if(sellTracker[_seller] + _sellAmount > buyTracker[_seller]) {
            return _tax;
        }

        if(block.timestamp > getSellEarlyExpiration(_seller)) {
            return 0;
        }

        uint256 _secondsAfterBuy = block.timestamp - lastBuyTimestamp[_seller];
        return (_tax * (decayTaxExpiration - _secondsAfterBuy)) / decayTaxExpiration;
    }

    function getSellEarlyExpiration(address _seller) private  view returns (uint256) {
        return lastBuyTimestamp[_seller] == 0 ? 0 : lastBuyTimestamp[_seller] + decayTaxExpiration;
    }

    function resetBuySellDecayTax(address _user) private {
        buyTracker[_user] = balanceOf(_user);
        lastBuyTimestamp[_user] = block.timestamp;
        sellTracker[_user] = 0;
    }

    //Buyback Module
    function buyBackTokens() private lockSwap {
        if(address(this).balance > 0) {
    	    swapETHForTokens(address(this).balance);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        address[] memory path = new address[](3);
        path[0] = uniswapV2Router.WETH();
        path[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC Address
        path[2] = 0xc5fB36dd2fb59d3B98dEfF88425a3F425Ee469eD; //TSUKA Address
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _buybackTokenReceiver, //Send bought tokens to this address
            block.timestamp.add(300)
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _lpTokensReceiver,
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet1.transfer(amount.div(2));
        _taxWallet2.transfer(amount.div(2));
    }

    function processDistributions(uint256 tokens) private {

        uint256 totalTokensFee = sMarketingFee.add(sLPFee).add(sBuybackFee);
        uint256 halfLPFee = sLPFee.div(2);

        //Get tokens to swap for eth. excluding tokens to add to LP
        uint256 tokensToSwapToETH = tokens.mul(totalTokensFee.sub(halfLPFee)).div(totalTokensFee);

        //Swap for eth
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokensToSwapToETH);
        uint256 newETHBalance = address(this).balance.sub(initialETHBalance);

        uint256 liquidityTokens = tokens.mul(halfLPFee).div(totalTokensFee);

        uint256 ethMarketingShare = newETHBalance.mul(sMarketingFee).div(totalTokensFee.sub(halfLPFee));
        uint256 ethLPShare = newETHBalance.mul(halfLPFee).div(totalTokensFee.sub(halfLPFee));

        //Send eth share to distribute to tax wallets        
        sendETHToFee(ethMarketingShare);
        //Send lp share along with tokens to add LP
        addLiquidity(liquidityTokens, ethLPShare);
        //Leave the remaining eth in contract itself for buybacking

        //Process buyback
        if(address(this).balance >= _buybackThreshold) {
            buyBackTokens();
        }
    }
    
    /// @notice Manually convert tokens in contract to Eth
    function manualswap() external {
        require(_msgSender() == _taxWallet1 || _msgSender() == _taxWallet2 || _msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    /// @notice Manually send ETH in contract to marketing wallets
    function manualsend() external {
        require(_msgSender() == _taxWallet1 || _msgSender() == _taxWallet2 || _msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    /// @notice Manually execute buyback with Eth availabe in contract
    function manualBuyBack() external {
        require(_msgSender() == _taxWallet1 || _msgSender() == _taxWallet2 || _msgSender() == owner());
        require(address(0).balance > 0, "No ETH in contract to buyback");
        buyBackTokens();
    }

    receive() external payable {}

    /// @notice Add an address to a pre trader
    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }

    /// @notice Add multiple address to exclude/include fee
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    /// @notice Enable disable trading
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    /// @notice Enable/Disable contract fee distribution
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    //Settings: Limits
    /// @notice Set maximum wallet limit
    function setMaxWalletAmount(uint256 maxWalletAmount) public onlyOwner() {
        require(maxWalletAmount > _tTotal.div(1000), "Amount must be greater than 0.1% of supply");
        _maxWalletAmount = maxWalletAmount;
    }

    /// @notice Set max amount a user can buy/sell/transfer
    function setMaxTxnAmount(uint256 maxTxnAmount) public onlyOwner() {
        require(_maxTxAmount > _tTotal.div(1000), "Amount must be greater than 0.1% of supply");
        _maxTxAmount = maxTxnAmount;
    }

    /// @notice Set Contract swap amount threshold
    function setSwapAmount(uint256 _swapAmount) public onlyOwner() {
        swapAmount = _swapAmount;
    }

    /// @notice Set buyback threshold
    function setBuyBackThreshold(uint256 amount) public onlyOwner {
        _buybackThreshold = amount;
    }

    /// @notice Set wallets
    function setWallets(address taxWallet1, address taxWallet2, address lpTokensReceiver, address buybackTokenReceiver) public onlyOwner {
        _taxWallet1 = payable(taxWallet1);
        _taxWallet2 = payable(taxWallet2);
        _lpTokensReceiver = lpTokensReceiver;
        _buybackTokenReceiver = buybackTokenReceiver;
    }

    /// @notice Setup fee in rate of 100 (If 1%, then set 100)
    function setBuyFee(uint256 _bMarketingFee, uint256 _bLPFee, uint256 _bBuybackFee) public onlyOwner {
        
        //Hard cap check to prevent honeypot
        require(_bMarketingFee <= 500, "Hard cap 20%");
        require(_bLPFee <= 500, "Hard cap 20%");
        require(_bBuybackFee <= 500, "Hard cap 20%");
        
        bMarketingFee = _bMarketingFee;
        bLPFee = _bLPFee;
        bBuybackFee = _bBuybackFee;
    
    }

    /// @notice Setup fee in rate of 100 (If 1%, then set 100)
    function setSellFee(uint256 _sMarketingFee, uint256 _sLPFee, uint256 _sBuybackFee, uint256 _sEarlySellFee) public onlyOwner {
        
        //Hard cap check to prevent honeypot
        require(_sMarketingFee <= 500, "Hard cap 20%");
        require(_sLPFee <= 500, "Hard cap 20%");
        require(_sBuybackFee <= 500, "Hard cap 20%");
        require(_sEarlySellFee <= 500, "Hard cap 20%");
        
        sMarketingFee = _sMarketingFee;
        sLPFee = _sLPFee;
        sBuybackFee = _sBuybackFee;
        sEarlySellFee = _sEarlySellFee;
    
    }

    function readFees() external view returns (uint _totalBuyFee, uint _totalSellFee, uint _marketingFeeBuy, uint _marketingFeeSell, uint _liquidityFeeBuy, uint _liquidityFeeSell, uint _buybackFeeBuy, uint _buybackFeeSell, uint maxEarlySellFee) {

        return (
            bMarketingFee+bLPFee+bBuybackFee,
            sMarketingFee+sLPFee+sBuybackFee+sEarlySellFee,
            bMarketingFee,
            sMarketingFee,
            bLPFee,
            sLPFee,
            bBuybackFee,
            sBuybackFee,
            sEarlySellFee
        );
    }

    /// @notice Airdropper inbuilt
    function multiSend(address[] calldata addresses, uint256[] calldata amounts, bool overrideTracker, uint256 trackerTimestamp) external {
        require(addresses.length == amounts.length, "Must be the same length");
        for(uint256 i = 0; i < addresses.length; i++){
            _transfer(_msgSender(), addresses[i], amounts[i] * 10**_decimals);

            //Suppose to airdrop holders who bought long back and don't want to reset their decaytax
            if(overrideTracker) {
                //Override buytracker
                buyTracker[addresses[i]] += amounts[i];
                lastBuyTimestamp[addresses[i]] = trackerTimestamp;
            }
        }
    }
    
}