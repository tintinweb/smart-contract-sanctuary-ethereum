/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

/***
 
Locker safer than Team.finance locker.

TG: https://t.me/Unilocketh
 
****/
// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.17;    

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
 
interface IUSDCReceiver {
    function initialize(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
}
 
contract USDCReceiver is IUSDCReceiver, Ownable {
    address public usdc;
    address public token;
 
    constructor() Ownable() {
        token = msg.sender;
    }
 
    function initialize(address _usdc) public onlyOwner {
        require(usdc == address(0x0), "Already initialized");
        usdc = _usdc;
    }
 
    function withdraw() public {
        require(msg.sender == token, "Caller is not token");
        IERC20(usdc).transfer(token, IERC20(usdc).balanceOf(address(this)));
    }
 
    function withdrawUnsupportedAsset(address _token, uint256 _amount) public onlyOwner {
        if(_token == address(0x0))
            payable(owner()).transfer(_amount);
        else
            IERC20(_token).transfer(owner(), _amount);
    }
}
 
contract Unilock is Context, IERC20, Ownable {         
    using SafeMath for uint256;         
 
    IUniswapV2Router02 private _uniswapV2Router;
 
    USDCReceiver private _receiver;         
 
    mapping (address => uint) private _antiMEV;         
 
    mapping (address => uint256) private _balances;         
 
    mapping (address => mapping (address => uint256)) private _allowances;         
 
    mapping (address => bool) private _isExcludedFromFees;         
    mapping (address => bool) private _isExcludedMaxTransactionAmount;         
 
    bool public tradingOpen;         
    bool private _swapping;         
    bool public swapEnabled;         
    bool public antiMEVEnabled;         
 
    string private constant _name = "Unilock";         
    string private constant _symbol = "ULock";         
 
    uint8 private constant _decimals = 18;         
 
    uint256 private constant _totalSupply = 10_101_101_101_101 * (10**_decimals);         
 
    uint256 public buyThreshold = _totalSupply.mul(15).div(1000);         
    uint256 public sellThreshold = _totalSupply.mul(15).div(1000);         
    uint256 public walletThreshold = _totalSupply.mul(15).div(1000);         
 
    uint256 public fee = 50; // 5%         
    uint256 private _previousFee = fee;         
 
    uint256 private _tokensForFee;         
    uint256 private _swapTokensAtAmount = _totalSupply.mul(7).div(10000);                  
 
    address payable private feeCollector;         
    address private _uniswapV2Pair;         
    address private DEAD = 0x000000000000000000000000000000000000dEaD;         
    address private ZERO = 0x0000000000000000000000000000000000000000;         
    address private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
 
    constructor () {         
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);         
        _approve(address(this), address(_uniswapV2Router), _totalSupply);         
        IERC20(USDC).approve(address(_uniswapV2Router), IERC20(USDC).balanceOf(address(this)));         
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);         
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);         
 
        _receiver = new USDCReceiver();
        _receiver.initialize(USDC);
        _receiver.transferOwnership(msg.sender);
 
        feeCollector = payable(_msgSender());         
        _balances[_msgSender()] = _totalSupply;         
 
        _isExcludedFromFees[owner()] = true;         
        _isExcludedFromFees[address(this)] = true;         
        _isExcludedFromFees[address(_receiver)] = true;         
        _isExcludedFromFees[DEAD] = true;         
 
        _isExcludedMaxTransactionAmount[owner()] = true;         
        _isExcludedMaxTransactionAmount[address(this)] = true;         
        _isExcludedMaxTransactionAmount[address(_receiver)] = true;         
        _isExcludedMaxTransactionAmount[DEAD] = true;         
 
        emit Transfer(ZERO, _msgSender(), _totalSupply);         
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
 
    function totalSupply() public pure override returns (uint256) {         
        return _totalSupply;         
    }         
 
    function balanceOf(address account) public view override returns (uint256) {         
        return _balances[account];         
    }         
 
    function transfer(address to, uint256 amount) public override returns (bool) {         
        _transfer(_msgSender(), to, amount);         
        return true;         
    }         
 
    function allowance(address owner, address spender) public view override returns (uint256) {         
        return _allowances[owner][spender];         
    }         
 
    function approve(address spender, uint256 amount) public override returns (bool) {         
        address owner = _msgSender();         
        _approve(owner, spender, amount);         
        return true;         
    }         
 
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {         
        address spender = _msgSender();         
        _spendAllowance(from, spender, amount);         
        _transfer(from, to, amount);         
        return true;         
    }         
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {         
        address owner = _msgSender();         
        _approve(owner, spender, allowance(owner, spender) + addedValue);         
        return true;         
    }         
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {         
        address owner = _msgSender();         
        uint256 currentAllowance = allowance(owner, spender);         
        require(currentAllowance >= subtractedValue, "Safu: decreased allowance below zero");         
        unchecked {         
            _approve(owner, spender, currentAllowance - subtractedValue);         
        }         
 
        return true;         
    }         
 
    function _transfer(address from, address to, uint256 amount) internal {         
        require(from != ZERO, "Safu: transfer from the zero address");         
        require(to != ZERO, "Safu: transfer to the zero address");         
        require(amount > 0, "Safu: Transfer amount must be greater than zero");         
 
        bool takeFee = true;         
        bool shouldSwap = false;         
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {         
            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Safu: Trading is not allowed yet.");         
 
            if (antiMEVEnabled) {         
                if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)) {         
                    require(_antiMEV[tx.origin] < block.number - 1 && _antiMEV[to] < block.number - 1, "Safu: Transfer delay enabled. Try again later.");         
                    _antiMEV[tx.origin] = block.number;         
                    _antiMEV[to] = block.number;         
                }         
            }         
 
            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {         
                require(amount <= buyThreshold, "Safu: Transfer amount exceeds the buyThreshold.");         
                require(balanceOf(to) + amount <= walletThreshold, "Safu: Exceeds maximum wallet token amount.");         
            }         
 
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {         
                require(amount <= sellThreshold, "Safu: Transfer amount exceeds the sellThreshold.");         
 
                shouldSwap = true;         
            }         
        }         
 
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;         
 
        uint256 contractBalance = balanceOf(address(this));         
        bool canSwap = (contractBalance > _swapTokensAtAmount) && shouldSwap;         
 
        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {         
            _swapping = true;         
            _swapBack(contractBalance);         
            _swapping = false;         
        }         
 
        _tokenTransfer(from, to, amount, takeFee);         
    }         
 
    function _approve(address owner, address spender, uint256 amount) internal {         
        require(owner != ZERO, "Safu: approve from the zero address");         
        require(spender != ZERO, "Safu: approve to the zero address");         
 
        _allowances[owner][spender] = amount;         
        emit Approval(owner, spender, amount);         
    }         
 
    function _spendAllowance(address owner, address spender, uint256 amount) internal {         
        uint256 currentAllowance = allowance(owner, spender);         
        if (currentAllowance != type(uint256).max) {         
            require(currentAllowance >= amount, "Safu: insufficient allowance");         
            unchecked {         
                _approve(owner, spender, currentAllowance - amount);         
            }         
        }         
    }         
 
    function _swapBack(uint256 contractBalance) internal {         
        if (contractBalance == 0 || _tokensForFee == 0) return;         
 
        if (contractBalance > _swapTokensAtAmount * 5) contractBalance = _swapTokensAtAmount * 5;         
 
        _swapTokensForTokens(contractBalance);          
 
        _receiver.withdraw();
 
        _tokensForFee = 0;         
 
        IERC20(USDC).transfer(feeCollector, IERC20(USDC).balanceOf(address(this)));
    }         
 
    function _swapTokensForTokens(uint256 tokenAmount) internal {         
        address[] memory path = new address[](2);         
        path[0] = address(this);         
        path[1] = USDC;         
        _approve(address(this), address(_uniswapV2Router), tokenAmount);         
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_receiver),
            block.timestamp
        );         
    }         
 
    function _removeFee() internal {         
        if (fee == 0) return;         
        _previousFee = fee;         
        fee = 0;         
    }         
 
    function _restoreFee() internal {         
        fee = _previousFee;         
    }         
 
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal {         
        if (!takeFee) _removeFee();         
        else amount = _takeFees(sender, amount);         
 
        _transferStandard(sender, recipient, amount);         
 
        if (!takeFee) _restoreFee();         
    }         
 
    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {         
        _balances[sender] = _balances[sender].sub(tAmount);         
        _balances[recipient] = _balances[recipient].add(tAmount);         
        emit Transfer(sender, recipient, tAmount);         
    }         
 
    function _takeFees(address sender, uint256 amount) internal returns (uint256) {         
        if (fee > 0) {         
            uint256 fees = amount.mul(fee).div(1000);         
            _tokensForFee += fees * fee / fee;         
 
            if (fees > 0) _transferStandard(sender, address(this), fees);         
 
            amount -= fees;         
        }         
 
        return amount;         
    }         
 
    function usdcReceiverAddress() external view returns (address) {
        return address(_receiver);
    }
 
    function openTrading() public onlyOwner {         
        require(!tradingOpen,"Safu: Trading is already open");         
        IERC20(USDC).approve(address(_uniswapV2Router), IERC20(USDC).balanceOf(address(this)));         
        _uniswapV2Router.addLiquidity(address(this), USDC, balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), 0, 0, owner(), block.timestamp);         
        swapEnabled = true;               
        antiMEVEnabled = true;               
        tradingOpen = true;         
    }         
 
    function setBuyThreshold(uint256 _buyTreshold) public onlyOwner {         
        require(_buyTreshold >= (totalSupply().mul(1).div(1000)), "Safu: Max buy amount cannot be lower than 0.1% total supply.");         
        buyThreshold = _buyTreshold;         
    }         
 
    function setSellThreshold(uint256 _sellThreshold) public onlyOwner {         
        require(_sellThreshold >= (totalSupply().mul(1).div(1000)), "Safu: Max sell amount cannot be lower than 0.1% total supply.");         
        sellThreshold = _sellThreshold;         
    }         
 
    function setWalletThreshold(uint256 _walletThreshold) public onlyOwner {         
        require(_walletThreshold >= (totalSupply().mul(1).div(100)), "Safu: Max wallet amount cannot be lower than 1% total supply.");         
        walletThreshold = _walletThreshold;         
    }         
 
    function setSwapTokensAtAmount(uint256 _swapAmountThreshold) public onlyOwner {         
        require(_swapAmountThreshold >= (totalSupply().mul(1).div(100000)), "Safu: Swap amount cannot be lower than 0.001% total supply.");         
        require(_swapAmountThreshold <= (totalSupply().mul(5).div(1000)), "Safu: Swap amount cannot be higher than 0.5% total supply.");         
        _swapTokensAtAmount = _swapAmountThreshold;         
    }         
 
    function setSwapEnabled(bool onoff) public onlyOwner {         
        swapEnabled = onoff;         
    }         
 
    function setAntiMEVEnabled(bool onoff) public onlyOwner {         
        antiMEVEnabled = onoff;         
    }         
 
    function setFeeCollector(address feeCollectorAddy) public onlyOwner {         
        require(feeCollectorAddy != ZERO, "Safu: feeCollector address cannot be 0");         
        feeCollector = payable(feeCollectorAddy);         
        _isExcludedFromFees[feeCollectorAddy] = true;         
        _isExcludedMaxTransactionAmount[feeCollectorAddy] = true;         
    }         
 
    function excludeFromFees(address[] memory accounts, bool isEx) public onlyOwner {         
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;         
    }         
 
    function excludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {         
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;         
    }         
 
    function rescueETH() public onlyOwner {         
        bool success;         
        (success,) = address(msg.sender).call{value: address(this).balance}("");         
    }         
 
    function rescueTokens(address tokenAddy) public onlyOwner {         
        require(tokenAddy != address(this), "Cannot withdraw this token");         
        require(IERC20(tokenAddy).balanceOf(address(this)) > 0, "No tokens");         
        uint amount = IERC20(tokenAddy).balanceOf(address(this));         
        IERC20(tokenAddy).transfer(msg.sender, amount);         
    }         
 
    function removeThresholds() public onlyOwner {         
        buyThreshold = _totalSupply;         
        sellThreshold = _totalSupply;         
        walletThreshold = _totalSupply;         
    }         
 
    receive() external payable {
    }         
    fallback() external payable {
    }         
 
}