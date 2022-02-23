/*

███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗███████╗██╗  ██╗ ██████╗ ████████╗
████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██╔════╝██║  ██║██╔═══██╗╚══██╔══╝
██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║███████╗███████║██║   ██║   ██║   
██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚════██║██╔══██║██║   ██║   ██║   
██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║███████║██║  ██║╚██████╔╝   ██║   
╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝  v2

Moonshot is a deflationary, frictionless yield and liquidity protocol.

For every transaction, a fee of max. 10% is decucted and shared between holders, the liqduity pool and the dev/marketing wallet.
As the burn address participates as a holder, the supply is forever decreasing.

Started out at DEFI meme token, moonshot features MoonBoxes and MoonSea.

This contract features:
 - blacklisting for enhanced security
 - router and pair address are dynamic
 - rescue BNB sent by mistake
 - higher precision fees
 - fee can be setup per address

*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract Moonshot is Context, IERC20, Ownable {
    using SafeMath for uint256;
  
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _specialFees;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromReward;
    mapping( address => bool) private _isBlackListed;
    mapping( address => bool) private _hasSpecialFee;

    address[] private _excludedFromReward;

    address payable public moonshotFundAddress = payable(0x000000000000000000000000000000000000dEaD);

    uint256 public numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private constant _name = "MoonSoon";
    string private constant _symbol = "MSOON";
    uint8 private constant _decimals = 9;
    
    uint256 public _taxFee = 400;
    uint256 private _prevTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 400;
    uint256 private _prevLiquidityFee = _liquidityFee;

    uint256 public _projectFee = 200;
    uint256 private _prevProjectFee = _projectFee;

    uint256 public _buyBackFee = 0;
    uint256 private _prevBuyBackFee = _buyBackFee;

    uint256 public _totalLiqFee = 0;
    uint256 private _prevTotalLiqFee = _totalLiqFee;

    uint256 private _tFeeTotal;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private inSwapAndLiquify;
    
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyMaxAmountEnabled = true;

    uint256 public _buyBackMinAmount = 0;
    uint256 public _buyBackMaxAmount = 0;

    uint256 private timeLock = 0;
        
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyMaxAmountEnabled(bool enabled, uint256 maxTokenIntoLiquidity);
    event SwapAndFundProject(uint256 amount);
    event SwapAndBurnTokens(uint256 amount);
    event SetPancakeRouterAddress(address newRouter, address pair);
    event SetPancakePairAddress(address newPair);
    event SetMoonshotFundAddress(address newAddress);
    event SetFees(uint256 newRewardFee, uint256 newLiquidityFee, uint256 newProjectFee, uint256 newBuyBackFee);
    event ExcludeFromReward(address account);
    event IncludeInReward(address account);
    event SetFee(address account, uint256 newFee, bool enabled);
    event AddToBlackList(address account);
    event RemoveFromBlackList(address account);
    event SetNumTokensSellToAddToLiquidity(uint256 amount);
    event RescueBNB(uint256 amount);
    event TimeLock(uint256 timestamp);
    event SetBuyBackMaxAmount(uint256 maxAmount);
    event SetBuyBackMinAmount(uint256 minAmount);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        
        // BSC MainNet, Pancakeswap Router
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Ropsten, Uniswap Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // BSC TestNet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
       
        //exclude owner and this contract from fee
        _hasSpecialFee[ owner() ] = true;
        _hasSpecialFee[ address(this) ] = true;

        //exclude pair from receiving rewards
        _isExcludedFromReward[ uniswapV2Pair ] = true;
     
        _totalLiqFee = _liquidityFee.add(_projectFee).add(_buyBackFee);
        _prevTotalLiqFee = _totalLiqFee;

        timeLock = block.timestamp;

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
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf( 0x000000000000000000000000000000000000dEaD ));
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function isFeeForAddressEnabled(address account) external view returns (bool) {
        return _hasSpecialFee[ account ];
    }

    function getFeeForAddress(address account) external view returns (uint256) {
        return  _specialFees[ account ];
    }

    function setPancakeRouterAddress(address routerAddress) external onlyOwner() {
        require( address(uniswapV2Router) != routerAddress, "Already using given router");
        IUniswapV2Router02 newRouter = IUniswapV2Router02( routerAddress );
        // test if pair exists and create if it does not exist
        address pair = IUniswapV2Factory(newRouter.factory()).getPair(address(this), newRouter.WETH());
        if (pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(newRouter.factory()).createPair(address(this), newRouter.WETH());
        }
        else {
            uniswapV2Pair = pair;
        }

        // approve new router to spend contract tokens
        _approve( address(this), routerAddress, MAX );

        // reset approval of old router
        _approve( address(this), address(uniswapV2Router), 0);

        // update state
        uniswapV2Router = IUniswapV2Router02(newRouter);

        emit SetPancakeRouterAddress(routerAddress, uniswapV2Pair);
    }

    function setPancakePairAddress(address newPair) external onlyOwner() {
        uniswapV2Pair = newPair;

        emit SetPancakePairAddress(uniswapV2Pair);
    }

    function setMoonshotFundAddress(address newAddress) external onlyOwner() {
        moonshotFundAddress = payable(newAddress);

        emit SetMoonshotFundAddress(moonshotFundAddress);
    }

   function setFees(uint256 newRewardFee, uint256 newLiquidityFee, uint256 newProjectFee, uint256 buyBackFee) external onlyOwner() {
        require( (newRewardFee + newLiquidityFee + newProjectFee) <= 1000, "Total fees must be <= 1000" );
        
        _taxFee = newRewardFee;
        _liquidityFee = newLiquidityFee;
        _projectFee = newProjectFee;
        _buyBackFee = buyBackFee;
        _totalLiqFee = _liquidityFee.add(_projectFee);
        
        emit SetFees(newRewardFee, newLiquidityFee, newProjectFee, buyBackFee);
    }

    function setFee(address account, uint256 newFee, bool enabled) external onlyOwner {
        require( newFee <= 1000, "Total fee must be <= 1000" );

        _specialFees[ account ] = newFee;
        _hasSpecialFee[ account ] = enabled;
        emit SetFee(account, newFee, enabled);
    }

    function setBuyBackMinAmount(uint256 amountMin) external onlyOwner() {
        require( amountMin >= 0, "Amount must be greater than 0");
        require( amountMin <= _buyBackMaxAmount, "Amount cannot be greater than buyBackMaxAmount");

        _buyBackMinAmount = amountMin;
        
        emit SetBuyBackMinAmount(amountMin);
    }

    function setBuyBackMaxAmount(uint256 amountMax) external onlyOwner() {
        _buyBackMaxAmount = amountMax;
        
        emit SetBuyBackMaxAmount(amountMax);
    }


    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        require(_excludedFromReward.length < 100, "Excluded list is too long");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);

        emit ExcludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        require(_excludedFromReward.length < 100, "Excluded list is too long");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                uint256 currentRate = _getRate();
                _rOwned[account] = _tOwned[account].mul(currentRate);
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }

        emit IncludeInReward(account);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function addToBlackList(address account) external onlyOwner {
        _isBlackListed[ account ] = true;

        emit AddToBlackList(account);
    }

    function removeFromBlackList(address account) external onlyOwner {
        _isBlackListed[ account ] = false;

        emit RemoveFromBlackList(account);
    }

    function isBlackListed(address account) external view returns(bool) {
        return _isBlackListed[ account ];
    }

    function setSwapAndLiquifyMaxAmountEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyMaxAmountEnabled = _enabled;

        emit SwapAndLiquifyMaxAmountEnabled(_enabled, numTokensSellToAddToLiquidity);
    }

    function setSwapAndLiquifyMaxAmount(uint256 amount) external onlyOwner {
        require( amount > 0, "Amount must be higher than 0");
        numTokensSellToAddToLiquidity = amount;

        emit SetNumTokensSellToAddToLiquidity(amount);
    }

    // contract gains BNB over time
    function rescueBNB(uint256 amount) external onlyOwner {
        payable( msg.sender ).transfer(amount);

        emit RescueBNB(amount);
    }
 
    // remove at most 10% of the liquidity and put a time lock of 4 weeks
    function removeLiquidity(uint256 percentage) external onlyOwner {

        require(timeLock <= block.timestamp, "Remove Liquidity is time locked.");
        require(percentage <= 1000, "Can only remove up to 10% of LP tokens");
        
        uint256 liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        require( liquidity > 0, "LP token balance is 0");

        uint256 amount = liquidity.mul(percentage).div(10**4); // at most 10% 
        
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), amount);
        uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(address(this), amount, 0, 0, msg.sender, block.timestamp.add(60) );

        // set a new timed lock
        timeLock = block.timestamp + (4 weeks);

        emit TimeLock(timeLock);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalLiqFee).div(
            10**4
        );
    }

    function saveAllFees() private {
        _prevTaxFee = _taxFee;
        _prevTotalLiqFee = _totalLiqFee;
        _prevProjectFee = _projectFee;
        _prevLiquidityFee = _liquidityFee;
        _prevBuyBackFee = _buyBackFee;
    }
  
    function setSpecialFee(address from, address to) private returns (bool) {
        
        uint256 totalFee = _taxFee.add(_liquidityFee).add(_projectFee).add(_buyBackFee);
        if( totalFee == 0 ) {
            return false; // don't take fee
        }

        // either one or both have a special fee, take the lowest
        address lowestFeeAccount = from;
        if( _hasSpecialFee[from] && _hasSpecialFee[to]) {
            lowestFeeAccount = ( _specialFees[from] > _specialFees[to] ? to : from );
        } else if ( _hasSpecialFee[to] ) {
            lowestFeeAccount = to;
        }

        // get the fee
        uint256 fee = _specialFees[ lowestFeeAccount ];
        
        // set fees
        _taxFee = fee.mul(_taxFee).div( totalFee );
        _liquidityFee = fee.mul(_liquidityFee).div( totalFee );
        _projectFee = fee.mul(_projectFee).div( totalFee );
        _buyBackFee = fee.mul(_buyBackFee).div( totalFee );

        _totalLiqFee = _liquidityFee.add(_projectFee).add(_buyBackFee);

        return ( _taxFee.add(_liquidityFee).add(_buyBackFee) ) > 0;
    }

    function restoreAllFees() private {
        _taxFee = _prevTaxFee;
        _totalLiqFee = _prevTotalLiqFee;
        _projectFee = _prevProjectFee;
        _liquidityFee = _prevLiquidityFee;
        _buyBackFee = _prevBuyBackFee;
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(from), "Transfer amount exceeds allowance");
        require(amount >= 0, "Transfer amount must be >= 0");
        require(!_isBlackListed[from], "From address is blacklisted");
        require(!_isBlackListed[to], "To address is blacklisted");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance > numTokensSellToAddToLiquidity;
        bool takeFee = true;
        
        // save all the fees
        saveAllFees();

        // if the address has a special fee, use it
        if( _hasSpecialFee[from] || _hasSpecialFee[to] ) {
            takeFee = setSpecialFee(from,to);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            if( swapAndLiquifyMaxAmountEnabled ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
            }
            
            swapAndLiquify(contractTokenBalance);
        }
        
        //transfer amount, it will deduct fee and reflect tokens
        _tokenTransfer(from,to,amount);

        // restore all the fees
        restoreAllFees();
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 forLiquidity = tAmount.div(_totalLiqFee).mul(_liquidityFee);
        uint256 forBuyBack = tAmount.div(_totalLiqFee).mul(_buyBackFee);
        uint256 forWallets = tAmount.sub(forLiquidity).sub(forBuyBack);
        
        if(forLiquidity > 0 && _liquidityFee > 0)
        {
            // sell half the tokens for BNB and add liquidity
            uint256 half = forLiquidity.div(2);
            uint256 otherHalf = forLiquidity.sub(half);
    
            uint256 initialBalance = address(this).balance;
            swapTokensForBNB(half);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
                
        if(forWallets > 0 && _projectFee > 0) 
        {
            // sell tokens for BNB and send to project fund
            uint256 initialBalance = address(this).balance;
            swapTokensForBNB(forWallets);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            transferToAddressBNB(moonshotFundAddress, newBalance);

            emit SwapAndFundProject(newBalance);
        }

        if(forBuyBack >0 && _buyBackFee > 0) {
            // if there is a max set on amount to buy back, cap the buy order
            if( _buyBackMaxAmount != 0 && forBuyBack > _buyBackMaxAmount ) {
                forBuyBack = _buyBackMaxAmount;
            }

            // if there is a minimum set, buy when we exceed threshold
            if( forBuyBack > _buyBackMinAmount) {
                swapBNBForTokens(forBuyBack);
            
                emit SwapAndBurnTokens(forBuyBack);
            }
        }

    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if( _allowances[ address(this)][address(uniswapV2Router)] < tokenAmount )
            _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp
        );
    }

    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {        
        if( _allowances[ address(this)][address(uniswapV2Router)] < tokenAmount )
            _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
   
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

     //to receive BNB from pancakeV2Router when swapping
    receive() external payable {}

}