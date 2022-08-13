/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.1;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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


contract PEPESILVER is Context,IERC20,Ownable {
    using Address for address;
    using SafeMath for uint256;

    mapping (address => uint256) public _cooldown;
    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) public _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public _blacklisted;
    mapping (address => bool) public _lpPairs;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcluded;
    mapping (address => bool) public _maxWalletExempt;
    mapping (address => bool) public _preTrader;
    mapping (address => bool) public _lpHolder;
    uint8 public constant _decimals = 9;
    uint16 totalFee;
    uint16 taxFee;
    uint16 public constant taxDivisor = 10000;
    uint256 private constant MAX = ~uint256(0);
    uint256 public constant startingSupply = 10_000_000;
    uint256 public constant _tTotal = startingSupply * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "PEPESILVER";
    string private constant _symbol = "PEPES";

    bool public feesEnabled;
    struct IFees {
        uint16 taxFee;
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 totalFee;
    }
    struct ILaunch {
        uint256 launchedAt;
        uint256 launchBlock;
        uint256 antiBlocks;
        bool tradingOpen;
        bool launched;
        bool launchProtection;
    }
    struct ICooldown {
        bool buycooldownEnabled;
        bool sellcooldownEnabled;
        uint256 cooldownLimit;
        uint256 cooldownTime;
    }
    struct ILiquiditySettings {
        uint256 liquidityFeeAccumulator;
        uint256 numTokensToSwap;
        uint256 lastSwap;
        uint8 swapInterval;
        bool swapEnabled;
        bool marketing;
        bool inSwap;
    }
    struct ITransactionSettings {
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        bool txLimits;
    }
    IFees public MaxFees;
    IFees public BuyFees;
    IFees public SellFees;
    IFees public TransferFees;
    ICooldown public Cooldown;
    ILaunch public Launch;
    ILiquiditySettings public LiquiditySettings;
    ITransactionSettings public TransactionSettings;
    IUniswapV2Router02 public immutable router;
    address public lpPair;
    address payable public marketingWallet;
    address[] private _excluded;
    event areFeesEnabled(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 indexed minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 eth, uint256 tokensIntoLiquidity);
    event SwapToMarketing(uint256 eth);
    modifier lockTheSwap {
        LiquiditySettings.inSwap = true;
        _;
        LiquiditySettings.inSwap = false;
    }
  
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        marketingWallet = payable(owner());
        _lpHolder[owner()] = true;
        Cooldown.cooldownLimit = 60;
        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        lpPair = IUniswapV2Factory(_router.factory())
            .createPair(address(this), _router.WETH());

        // set the rest of the contract variables
        router = _router;
        _lpPairs[lpPair] = true;
        _approve(_msgSender(), address(_router), type(uint256).max);
        _approve(address(this), address(_router), type(uint256).max);      
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _preTrader[owner()] = true;
        _lpHolder[owner()] = true;        
        _maxWalletExempt[lpPair] = true;
        _maxWalletExempt[owner()] = true;
        _maxWalletExempt[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol()  public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) private {
        address sender = _msgSender();
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        if(_isExcluded[msg.sender])
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);

    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
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
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    // Exclude or Include from Fees
    function excludeFromFee(address account, bool FeeLess) public onlyOwner {
        _isExcludedFromFee[account] = FeeLess;
    }
    
    // Sets marketing wallet
    function setWallet(address payable m) external onlyOwner() {
        marketingWallet = m; 

    }
    
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFees) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tFees, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tFees);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = (tAmount * taxFee) / taxDivisor;
        uint256 tFees = (tAmount * totalFee) / taxDivisor;
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFees);
        return (tTransferAmount, tFee, tFees);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFees = tFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFees);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function getCirculatingSupply() external view returns(uint256){
        return _tTotal - balanceOf(address(0xDead));
    }

    function _takeFees(uint256 tFees) private {
        uint256 currentRate = _getRate();
        uint256 rFees = tFees.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFees);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tFees);
    }

    function _takeMarketing(uint256 marketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = marketing.mul(currentRate);
        _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketing);
        if(_isExcluded[marketingWallet])
            _tOwned[marketingWallet] = _tOwned[marketingWallet].add(marketing);
     
    }

    function limits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
            && !_lpHolder[from]
            && !_lpHolder[to]
            && to != address(0xdead)
            && to != address(0)
            && from != address(this);
    }

    // Transfer functions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool){
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");            
        require(!_blacklisted[from], "TOKEN: Your account is blacklisted!");
        require(!_blacklisted[to], "TOKEN: Your account is blacklisted!");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");
        if(LiquiditySettings.inSwap) return (_basicTransfer(from, to, amount));
        if(from != owner() && to != owner()){
            if(!Launch.tradingOpen){
                require(_preTrader[from] || _preTrader[to]);
            }
            if (limits(from, to)) {
                if(Launch.tradingOpen && Launch.launched && TransactionSettings.txLimits){
                    if(!_maxWalletExempt[to]){
                        require(amount <= TransactionSettings.maxTxAmount && balanceOf(to) + amount <= TransactionSettings.maxWalletAmount, "TOKEN: Amount exceeds Transaction size");
                    }
                    if (_lpPairs[from] && to != address(router) && !_isExcludedFromFee[to] && Cooldown.buycooldownEnabled) {
                        require(_cooldown[to] < block.timestamp);
                         _cooldown[to] = block.timestamp + (Cooldown.cooldownTime);
                    } else if (!_lpPairs[from] && !_isExcludedFromFee[from] && Cooldown.sellcooldownEnabled){
                        require(_cooldown[from] <= block.timestamp);
                        _cooldown[from] = block.timestamp + (Cooldown.cooldownTime);
                    }                     
                }
            }      
            if(LiquiditySettings.swapEnabled && !LiquiditySettings.inSwap && balanceOf(address(this)) >= LiquiditySettings.numTokensToSwap && _lpPairs[to]){
                if(LiquiditySettings.liquidityFeeAccumulator >= LiquiditySettings.numTokensToSwap && block.timestamp >= LiquiditySettings.lastSwap + LiquiditySettings.swapInterval){
                    swapAndLiquify();
                    LiquiditySettings.lastSwap = block.timestamp;
                } else {
                    if(block.timestamp >= LiquiditySettings.lastSwap + LiquiditySettings.swapInterval){
                        swapForMarketing();
                        LiquiditySettings.lastSwap = block.timestamp;
                    }
                }
            }
        }
        // transfer amount, it will set fees and auto blacklist snipers
        return (_tokenTransfer(from,to,amount));
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private returns (bool){
        if(Launch.launched){
            setFee(sender, recipient);
            if(Launch.launchProtection){
                if(Launch.launchBlock + Launch.antiBlocks <= block.number) {
                    turnOff();
                }
                if (_lpPairs[sender] && recipient != address(router) && !_isExcludedFromFee[recipient]) {
                    if (block.number  <= Launch.launchBlock + Launch.antiBlocks) {
                        if(!_lpPairs[recipient]){
                            _setSniperStatus(recipient, true);
                        }
                    }
                }
            }
        }

        // transfers and takes fees
        if(!Launch.tradingOpen){
            _basicTransfer(sender, recipient, amount);
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 tAmount) private returns (bool){
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if(!LiquiditySettings.marketing){
            _takeFees(tFees);
            uint16 taxCorrection = (BuyFees.taxFee + SellFees.taxFee + TransferFees.taxFee);
            LiquiditySettings.liquidityFeeAccumulator += (tFees * (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee)) / ((BuyFees.totalFee + SellFees.totalFee + TransferFees.totalFee) - taxCorrection) + (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee);
        } else {
            _takeMarketing(tFees);
        }      
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);      
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        if(!LiquiditySettings.marketing){
            _takeFees(tFees);
            uint16 taxCorrection = (BuyFees.taxFee + SellFees.taxFee + TransferFees.taxFee);
            LiquiditySettings.liquidityFeeAccumulator += (tFees * (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee)) / ((BuyFees.totalFee + SellFees.totalFee + TransferFees.totalFee) - taxCorrection) + (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee);
        } else {
            _takeMarketing(tFees);
        }        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        if(!LiquiditySettings.marketing){
            _takeFees(tFees);
            uint16 taxCorrection = (BuyFees.taxFee + SellFees.taxFee + TransferFees.taxFee);
            LiquiditySettings.liquidityFeeAccumulator += (tFees * (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee)) / ((BuyFees.totalFee + SellFees.totalFee + TransferFees.totalFee) - taxCorrection) + (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee);
        } else {
            _takeMarketing(tFees);
        }       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        if(!LiquiditySettings.marketing){
            _takeFees(tFees);
            uint16 taxCorrection = (BuyFees.taxFee + SellFees.taxFee + TransferFees.taxFee);
            LiquiditySettings.liquidityFeeAccumulator += (tFees * (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee)) / ((BuyFees.totalFee + SellFees.totalFee + TransferFees.totalFee) - taxCorrection) + (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee);
        } else {
            _takeMarketing(tFees);
        }        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Sets the  Fees
    function setFee(address sender, address recipient) internal {
        if(feesEnabled){
            if (_lpPairs[recipient]) {
                if(totalFee != SellFees.marketingFee + SellFees.liquidityFee){
                    totalFee = SellFees.marketingFee + SellFees.liquidityFee;            
                }
                if(taxFee != SellFees.taxFee){
                    taxFee = SellFees.taxFee;
                }
            } else if(_lpPairs[sender]){
                if(totalFee != BuyFees.marketingFee + BuyFees.liquidityFee){
                    totalFee = BuyFees.marketingFee + BuyFees.liquidityFee;            
                }
                if(taxFee != BuyFees.taxFee){
                    taxFee = BuyFees.taxFee;
                }
            } else {
                if(totalFee != TransferFees.marketingFee + TransferFees.liquidityFee){
                    totalFee = TransferFees.marketingFee + TransferFees.liquidityFee;            
                }
                if(taxFee != TransferFees.taxFee){
                    taxFee = TransferFees.taxFee;
                }
            }
            if(block.number <= Launch.launchBlock + Launch.antiBlocks){
                totalFee += 500; // Adds 5% tax onto original tax
            }
        }
        // removes fee if sender or recipient is fee excluded or if fees are disabled
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || !feesEnabled) {
            if(totalFee != 0 && taxFee != 0){
                totalFee = 0;
                taxFee = 0;
            }
        }
    }
    
    // set launch
    function setTradingOpen(bool _tradingOpen, uint8 sniperblocks) public onlyOwner {
        require(sniperblocks <= 5);
        require(!Launch.tradingOpen);
        Launch.tradingOpen = _tradingOpen;
        FeesEnabled(_tradingOpen);
        setCooldownEnabled(_tradingOpen, _tradingOpen, 30);
        setNumTokensToSwap(1,1000);
        setTxSettings(5,1000,1,100,_tradingOpen);
        toggleSwap(_tradingOpen, 10);
        if(!Launch.launched) {
            setMaxFee(500,500,500, _tradingOpen);
            Launch.launched = _tradingOpen;
            Launch.antiBlocks = sniperblocks;
            Launch.launchedAt = block.timestamp; 
            Launch.launchBlock = block.number; 
            Launch.launchProtection = _tradingOpen;
        }
    }

    // Swaps tokens and adds to Liquidity
    function swapAndLiquify() private lockTheSwap {
        uint256 liquidityTokens = LiquiditySettings.numTokensToSwap / 2;
        swapTokens(liquidityTokens);
        uint256 toLiquidity = address(this).balance;
        addLiquidity(liquidityTokens, toLiquidity);
        emit SwapAndLiquify(toLiquidity, liquidityTokens);
        LiquiditySettings.liquidityFeeAccumulator -= LiquiditySettings.numTokensToSwap;        
    }

    // Swaps tokens and send to Marketing
    function swapForMarketing() private lockTheSwap {
        swapTokens(LiquiditySettings.numTokensToSwap);
        uint256 toMarketing = address(this).balance;
        marketingWallet.transfer(toMarketing);
        emit SwapToMarketing(toMarketing);
    }

    // Swaps Token for Eth
    function swapTokens(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Eth
            path,
            address(this),
            block.timestamp
        );
    }

    // Adds eth and token to Liqudity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(owner()),
            block.timestamp
        );
    }

    // Transaction functions
    function setTxSettings(uint256 txp, uint256 txd, uint256 mwp, uint256 mwd, bool limit) public onlyOwner {
        require((_tTotal * txp) / txd >= _tTotal / 1000, "Max Transaction must be above 0.1% of total supply.");
        require((_tTotal * mwp) / mwd >= _tTotal / 1000, "Max Wallet must be above 0.1% of total supply.");
        uint256 newTxAmount = (_tTotal * txp) / txd;
        uint256 newMaxWalletAmount = (_tTotal * mwp) / mwd;
        TransactionSettings = ITransactionSettings ({
            maxTxAmount: newTxAmount,
            maxWalletAmount: newMaxWalletAmount,
            txLimits: limit
        });
    }

    function setWalletExempt(address account, bool enabled) public onlyOwner{
        _maxWalletExempt[account] = enabled;
    }
    // Cooldown Settings
    function setCooldownEnabled(bool onoff, bool offon, uint8 time) public onlyOwner {
        require(time <= Cooldown.cooldownLimit);
        Cooldown.cooldownTime = time;
        Cooldown.buycooldownEnabled = onoff;
        Cooldown.sellcooldownEnabled = offon;
    }

    // contract swap functions
    function toggleSwap(bool _swapEnabled, uint8 swapInterval) public onlyOwner {
        LiquiditySettings.swapEnabled = _swapEnabled;
        LiquiditySettings.swapInterval = swapInterval;
    }

    // Receive tokens instead of Eth
    function toggleMarketing(bool enabled) public onlyOwner {
        LiquiditySettings.marketing = enabled;
    }

    // AirDrop 
    function airDropTokens(address[] memory addresses, uint256[] memory amounts) external {
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(_msgSender()) >= amounts[i]);
            _tokenTransfer(_msgSender(), addresses[i], amounts[i]*10**_decimals);
        }
    }

    // Pretraders
    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(_preTrader[account] != allowed, "TOKEN: Already enabled.");
        _preTrader[account] = allowed;
    }

    // Clear Stuck Tokens 
    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage <= 100);
        uint256 amountETH = address(this).balance;
        payable(marketingWallet).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function clearStuckToken(address to) external onlyOwner {
        uint256 _balance = balanceOf(address(this));
        _transfer(address(this), to, _balance);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    // Blacklist
    function blockBots(address[] memory bots_, bool enabled) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            _blacklisted[bots_[i]] = enabled;
        }
    }

    function _setSniperStatus(address account, bool blacklisted) internal {
        if(_lpPairs[account] || account == address(this) || account == address(router) || _isExcludedFromFee[account]) {revert();}
        
        if (blacklisted == true) {
            _blacklisted[account] = true;
        } else {
            _blacklisted[account] = false;
        }    
    }

    function turnOff() internal {
        Launch.launchProtection = false;
    }
    // Set LP Holders
    function setLpHolder(address holder, bool enabled) external onlyOwner {
        _lpHolder[holder] = enabled;
    }
    // Setting new Lp Pairs
    function setLpPair(address pair, bool enabled) external onlyOwner {
        _lpPairs[pair] = enabled;
    }

    // Set minimum tokens required to swap.
    function setNumTokensToSwap(uint256 percent, uint256 divisor) public onlyOwner {
        LiquiditySettings.numTokensToSwap = (_tTotal * percent) / divisor;
    }

    // Fee Settings
    function FeesEnabled(bool _enabled) public onlyOwner {
        feesEnabled = _enabled;
        emit areFeesEnabled(_enabled);
    }

    function setBuyFees(uint16 _liquidityFee, uint16 _marketingFee, uint16 _taxFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        BuyFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            taxFee: _taxFee,
            totalFee: _liquidityFee + _marketingFee + _taxFee
        });
    }

    function setSellFees(uint16 _liquidityFee, uint16 _marketingFee, uint16 _taxFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        SellFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            taxFee: _taxFee,
            totalFee: _liquidityFee + _marketingFee +  _taxFee
        });
    }

    function setTransferFees(uint16 _liquidityFee, uint16 _marketingFee, uint16 _taxFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        TransferFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            taxFee: _taxFee,
            totalFee: _liquidityFee + _marketingFee + _taxFee
        });
    }
        

    function setMaxFee(uint16 _taxFee, uint16 _liquidityFee, uint16 _marketingFee, bool resetFees) public onlyOwner {
        if(!Launch.launched){
            MaxFees = IFees({
                taxFee: _taxFee,
                liquidityFee: _liquidityFee,
                marketingFee: _marketingFee,
                totalFee: _taxFee + _liquidityFee + _marketingFee
            });
            setBuyFees(_liquidityFee, _marketingFee, _taxFee);                
            setSellFees(_liquidityFee, _marketingFee, _taxFee);
            setTransferFees(_liquidityFee / (10), _marketingFee/ (10), _taxFee / (10));
        }else{
            require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee && _taxFee <= MaxFees.taxFee);
            MaxFees = IFees({
                taxFee: _taxFee,
                liquidityFee: _liquidityFee,
                marketingFee: _marketingFee,
                totalFee: _taxFee + _liquidityFee + _marketingFee
            });
            if(resetFees){
                setBuyFees(_liquidityFee, _marketingFee, _taxFee);                
                setSellFees(_liquidityFee, _marketingFee, _taxFee);
            }
        }
    }
}