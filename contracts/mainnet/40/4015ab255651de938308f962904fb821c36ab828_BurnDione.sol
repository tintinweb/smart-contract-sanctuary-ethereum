/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
 
abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

function name() external pure returns(string memory);
function symbol() external pure returns(string memory);
function decimals() external pure returns(uint8);
function totalSupply() external view returns(uint);
function balanceOf(address owner) external view returns(uint);
function allowance(address owner, address spender) external view returns(uint);

function approve(address spender, uint value) external returns(bool);
function transfer(address to, uint value) external returns(bool);
function transferFrom(address from, address to, uint value) external returns(bool);

function DOMAIN_SEPARATOR() external view returns(bytes32);
function PERMIT_TYPEHASH() external pure returns(bytes32);
function nonces(address owner) external view returns(uint);

function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;


function MINIMUM_LIQUIDITY() external pure returns(uint);
function factory() external view returns(address);
function token0() external view returns(address);
function token1() external view returns(address);
function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
function price0CumulativeLast() external view returns(uint);
function price1CumulativeLast() external view returns(uint);
function kLast() external view returns(uint);

function mint(address to) external returns(uint liquidity);
function burn(address to) external returns(uint amount0, uint amount1);
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
function skim(address to) external;
function sync() external;

function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

function feeTo() external view returns(address);
function feeToSetter() external view returns(address);

function getPair(address tokenA, address tokenB) external view returns(address pair);
function allPairs(uint) external view returns(address pair);
function allPairsLength() external view returns(uint);

function createPair(address tokenA, address tokenB) external returns(address pair);

function setFeeTo(address) external;
function setFeeToSetter(address) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

/**
 * @dev Returns the amount of tokens owned by `account`.
 */
function balanceOf(address account) external view returns(uint256);


function transfer(address recipient, uint256 amount) external returns(bool);

function allowance(address owner, address spender) external view returns(uint256);


function approve(address spender, uint256 amount) external returns(bool);


function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) external returns(bool);

 
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
  
    function name() external view returns(string memory);

    
    function symbol() external view returns(string memory);

    
    function decimals() external view returns(uint8);
}
 
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

        mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns(string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

  
    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual { }
}
 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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


    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

 
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
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
 
 
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns(int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns(int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns(uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
 
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns(int256) {
    int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns(address);
function WETH() external pure returns(address);

function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns(uint amountA, uint amountB, uint liquidity);
function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) external payable returns(uint amountToken, uint amountETH, uint liquidity);
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns(uint amountA, uint amountB);
function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) external returns(uint amountToken, uint amountETH);
function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external returns(uint amountA, uint amountB);
function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external returns(uint amountToken, uint amountETH);
function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns(uint[] memory amounts);
function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
) external returns(uint[] memory amounts);
function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
external
payable
returns(uint[] memory amounts);
function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
external
returns(uint[] memory amounts);
function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
external
returns(uint[] memory amounts);
function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
external
payable
returns(uint[] memory amounts);

function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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
 
contract BurnDione is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;


    // addresses
    address private burnWallet;

    // limits 
    uint256 private maxTransactionBuyAmount;
    uint256 private maxTransactionSellAmount;   
    uint256 private maxWallet;
 
    uint256 private swapTokensAtAmount;

    // status flags
    bool private tradingActive = false;
    bool public swapEnabled = false;
    bool public swapping;


    // Blacklist Map
    mapping(address => bool) private _blacklist;


    struct Fees {
        uint256 buyTotalFees;
        uint256 buyBurnFee;
        uint256 buyLiquidityFee;

        uint256 sellTotalFees;
        uint256 sellBurnFee;
        uint256 sellLiquidityFee;
    }  

    Fees public _fees = Fees({
        buyTotalFees: 0,
        buyBurnFee: 0,
        buyLiquidityFee: 0,

        sellTotalFees: 0,
        sellBurnFee: 0,
        sellLiquidityFee: 0
    });
    
    

    uint256 public tokensForBurn;
    uint256 public tokensForLiquidity;


    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
 
  
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );


    constructor() ERC20("Burn Dione", "BIONE") {
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        approve(address(_uniswapV2Router), type(uint256).max);
        uint256 totalSupply = 1 * 1e8 * 1e18;

        maxTransactionBuyAmount = (totalSupply * 2) / 100;
        maxTransactionSellAmount = (totalSupply * 2) / 100;
        maxWallet = totalSupply * 3 / 100; 
        swapTokensAtAmount = totalSupply * 1 / 10000; 

        _fees.buyBurnFee = 1;
        _fees.buyLiquidityFee = 1;
        _fees.buyTotalFees = _fees.buyBurnFee + _fees.buyLiquidityFee;

        _fees.sellBurnFee = 4;
        _fees.sellLiquidityFee = 1;
        _fees.sellTotalFees = _fees.sellBurnFee + _fees.sellLiquidityFee;


        burnWallet = address(0x8e157eA4bF81BaCc20F46EB8Fe76A83c49F57E56); // Dione Burn Wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);

        excludeFromWalletLimit(owner(), true);
        excludeFromWalletLimit(address(this), true);
        excludeFromWalletLimit(address(uniswapV2Pair), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {

    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }



    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns(bool){
        swapTokensAtAmount = newAmount;
        return true;
    }


    function updateMaxTxnAmount(uint256 newMaxBuyAmount, uint256 newMaxSellAmount) external onlyOwner {
        require(((totalSupply() * newMaxBuyAmount) / 1000) >= (totalSupply() / 5000), "Cannot set maxTransactionAmounts lower than 0.5%");
        require(((totalSupply() * newMaxSellAmount) / 1000) >= (totalSupply() / 5000), "Cannot set maxTransactionAmounts lower than 0.5%");
        maxTransactionBuyAmount = (totalSupply() * newMaxBuyAmount) / 1000;
        maxTransactionSellAmount = (totalSupply() * newMaxSellAmount) / 1000;
    }


    function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
        require(((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 5000), "Cannot set maxWallet lower than 0.5%");
        maxWallet = (totalSupply() * newPercentage) / 1000;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function updateBuyFees(uint256 _burnFee, uint256 _liquidityFee) external onlyOwner {
        _fees.buyBurnFee = _burnFee;
        _fees.buyLiquidityFee = _liquidityFee;
        _fees.buyTotalFees = _fees.buyBurnFee + _fees.buyLiquidityFee;
        require(_fees.buyTotalFees <= 7, "Never above 7");
    }

    function updateSellFees(uint256 _burnFee, uint256 _liquidityFee) external onlyOwner {
        _fees.sellBurnFee = _burnFee;
        _fees.sellLiquidityFee = _liquidityFee;
        _fees.sellTotalFees = _fees.sellBurnFee + _fees.sellLiquidityFee;
        require(_fees.sellTotalFees <= 7, "Never above 7");
    }

    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
    function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
        _isExcludedMaxWalletAmount[account] = excluded;
    }
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
    }


    function updateWallets(address newBurnWallet) external onlyOwner{
        burnWallet = newBurnWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0xdEaD), "ERC20: transfer from the dEaD address");
        require(to != address(0xdEaD), "ERC20: transfer to the dEaD address");
        require(!_blacklist[to] && !_blacklist[from], "You have been blacklisted from transfering tokens");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            !swapping
        ) {
            if (!tradingActive) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
            }

            //when buy
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionBuyAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            }

            //when sell
            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionSellAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            }
            if (!_isExcludedMaxWalletAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }
 
        
 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }
 
        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            
            // on sell
            if (automatedMarketMakerPairs[to] && _fees.sellTotalFees > 0) {
                fees = amount.mul(_fees.sellTotalFees).div(100);
                tokensForLiquidity += fees * _fees.sellLiquidityFee / _fees.sellTotalFees;
                tokensForBurn += fees * _fees.sellBurnFee / _fees.sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && _fees.buyTotalFees > 0) {
                fees = amount.mul(_fees.buyTotalFees).div(100);
                tokensForLiquidity += fees * _fees.buyLiquidityFee / _fees.buyTotalFees;
                tokensForBurn += fees * _fees.buyBurnFee / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;

        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{ value: ethAmount } (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForBurn ;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) { return; }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForBurn = ethBalance.mul(tokensForBurn).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForBurn;


        tokensForLiquidity = 0;
        tokensForBurn = 0;


        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }

        (success,) = address(burnWallet).call{ value: address(this).balance } ("");
    }

}