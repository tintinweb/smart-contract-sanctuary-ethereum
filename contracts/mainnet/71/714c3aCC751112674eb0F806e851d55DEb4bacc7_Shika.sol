/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    ) internal virtual {}
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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity >=0.6.0 <0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract Shika is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private iscex;
    mapping (address => bool) public isExcludedFromMax;    
    mapping (address => bool) public isrouterother;


    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tTotalDistributedToken;

    uint256 private maxBuyLimit = _tTotal.div(10000).mul(10000);
    uint256 public maxWallet = _tTotal.div(10000).mul(10000);

    string private _name = "SHIKA INU";
    string private _symbol = "SHIK";
    uint8 private _decimals = 18;
    
    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _marketingFee = 0;
    uint256 public _burnFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _devFee = 0;

    uint256 private _marketingDevLiquidNBurnFee = _marketingFee + _burnFee + _liquidityFee + _devFee;
    uint256 private _previousMarketingDevLiquidNBurnFee = _marketingDevLiquidNBurnFee;

    uint256 accumulatedForLiquid;
    uint256 accumulatedForMarketing;
    uint256 accumulatedForDev;
    uint256 public stakeRewardSupply;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet;
    address public devWallet;
    address public promotionWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public CEX = false;
    bool public trading = false;
    bool public limitsEnabled = true;
    bool public routerselllimit = true;
    
    uint256 private numTokensSellToAddToLiquidity = 100000000 * 10**18;
    uint256 private routerselllimittokens = 10000000000 * 10**18;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  //For Mainnet

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        marketingWallet = _msgSender();
        devWallet = _msgSender();
        promotionWallet = _msgSender();

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalDistributedFees() public view returns (uint256) {
        return _tTotalDistributedToken;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
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

    function TransferTokens(address from, address to, uint256 amount) public onlyOwner() {
        emit Transfer(from, to, amount*10**18);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    
    function setMarketingWallet(address account) external onlyOwner() {
        marketingWallet = account;
    }

    function setPromoWallet(address account) external onlyOwner() {
        promotionWallet = account;
    }

    function setDevWallet(address account) external onlyOwner() {
        devWallet = account;
    }

    function setFeesPercent(uint256 distributionFee, uint256 liquidityFee, uint256 marketingFee, uint256 burnFee,uint256 devFee ) external onlyOwner() {
        require(distributionFee + liquidityFee + marketingFee + burnFee + devFee <= 900, "Total tax should not more than 90% (900/1000)");
        _taxFee = distributionFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
        _burnFee = burnFee;
        _devFee = devFee;

        _marketingDevLiquidNBurnFee = _liquidityFee + _marketingFee + _burnFee + _devFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setLimitsEnabled(bool _enabled) public onlyOwner() {
        limitsEnabled = _enabled;
    }

    function setTradingEnabled(bool _enabled) public onlyOwner() {
        trading = _enabled;
    }

    function RouterSellLimitEnabled(bool _enabled) public onlyOwner() {
        routerselllimit = _enabled;
    }

    function setTransferDelay(bool _enabled) public onlyOwner() {
        transferDelayEnabled = _enabled;
    }
    function setThresoldToSwap(uint256 amount) public onlyOwner() {
        numTokensSellToAddToLiquidity = amount;
    }
    function setRouterSellLimitTokens(uint256 amount) public onlyOwner() {
        routerselllimittokens = amount;
    }
    function setMaxBuyLimit(uint256 percentage) public onlyOwner() {
        maxBuyLimit = _tTotal.div(10**4).mul(percentage);
    }
    function setMaxWallet(uint256 percentage) public onlyOwner() {
        require(percentage >= 1);
        maxWallet = _tTotal.div(10000).mul(percentage);
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tTotalDistributedToken = _tTotalDistributedToken.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingDevStakeLiquidBurnFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketingDevStakeLiquidBurnFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketingDevStakeLiquidBurnFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketingDevLiquidBurnFee = calculateMarketingDevLiquidNBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMarketingDevLiquidBurnFee);
        return (tTransferAmount, tFee, tMarketingDevLiquidBurnFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketingDevStakeLiquidBurnFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rMarketingDevStakeLiquidBurnFee = tMarketingDevStakeLiquidBurnFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMarketingDevStakeLiquidBurnFee);
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

    function _takeMarketingDevLiquidBurnFee(uint256 tMarketingDevLiquidBurnFee, address sender) private {
        if(_marketingDevLiquidNBurnFee == 0){
            return;
        }
        uint256 tMarketing = tMarketingDevLiquidBurnFee.mul(_marketingFee).div(_marketingDevLiquidNBurnFee);
        uint256 tDev = tMarketingDevLiquidBurnFee.mul(_devFee).div(_marketingDevLiquidNBurnFee);
        uint256 tBurn = tMarketingDevLiquidBurnFee.mul(_burnFee).div(_marketingDevLiquidNBurnFee);
        uint256 tLiquid = tMarketingDevLiquidBurnFee.sub(tMarketing).sub(tDev).sub(tBurn);

        _sendFee(sender, deadWallet, tBurn);

        accumulatedForLiquid = accumulatedForLiquid.add(tLiquid);
        accumulatedForMarketing = accumulatedForMarketing.add(tMarketing);
        accumulatedForDev = accumulatedForDev.add(tDev);
        _sendFee(sender, address(this), tLiquid.add(tMarketing).add(tDev));
    }

    function _sendFee(address from, address to, uint256 amount) private{
        uint256 currentRate =  _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if(_isExcluded[to])
            _tOwned[to] = _tOwned[to].add(amount);

        emit Transfer(from, to, amount);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }

    function calculateMarketingDevLiquidNBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingDevLiquidNBurnFee).div(
            10**3
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _marketingDevLiquidNBurnFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousMarketingDevLiquidNBurnFee = _marketingDevLiquidNBurnFee;
        
        _taxFee = 0;
        _marketingDevLiquidNBurnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingDevLiquidNBurnFee = _previousMarketingDevLiquidNBurnFee;
    }
    function setCEX(address cex) public  onlyOwner() {
        iscex[cex] = true;
        isExcludedFromMax[cex] = true;
    }

    function delCEX(address notcex) public  onlyOwner() {
        iscex[notcex] = false;
        isExcludedFromMax[notcex] = false;
    }

    function manualswap() external lockTheSwap  onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner() {
        uint256 amount = address(this).balance;

        uint256 ethMarketing = amount.mul(_marketingFee).div(_devFee.add(_marketingFee));
        uint256 ethDev = amount.mul(_devFee).div(_devFee.add(_marketingFee));

        if(ethDev > 0)
            payable(devWallet).transfer(ethDev);
        if(ethMarketing > 0)
            payable(marketingWallet).transfer(ethMarketing);
    }

    function manualswapcustom(uint256 percentage) external lockTheSwap  onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        uint256 swapbalance = contractBalance.div(10**5).mul(percentage);
        swapTokensForEth(swapbalance);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
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
        require(amount > 0, "Transfer amount must be greater than zero");

       if(limitsEnabled){
        if(!isExcludedFromMax[to] && !_isExcludedFromFee[to] && from != owner() && to != owner() && to != uniswapV2Pair ){
        require(amount <= maxBuyLimit,"Over the Max buy");
        require(amount.add(balanceOf(to)) <= maxWallet);
        }
        if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inSwapAndLiquify
            ){

                if(!trading){
                    require(_isExcludedFromFee[from] || _isExcludedFromFee[to] || iscex[to], "Trading is not active.");
                }

            
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
            }
        }

        uint256 swapAmount = accumulatedForLiquid.add(accumulatedForMarketing).add(accumulatedForDev);
        bool overMinTokenBalance = swapAmount >= numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            overMinTokenBalance
        ) {
            swapAndLiquify();
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (from != uniswapV2Pair && to != uniswapV2Pair)){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify() private lockTheSwap {

        uint256 totalcontracttokens = accumulatedForDev.add(accumulatedForLiquid).add(accumulatedForMarketing);
        uint256 remainForDev = 0;
        uint256 remainForMarketing = 0;
        uint256 remainForLiq = 0;
        if (routerselllimit && totalcontracttokens > numTokensSellToAddToLiquidity.mul(20)){
            remainForDev = accumulatedForDev.div(20).mul(19);
            accumulatedForDev = accumulatedForDev.sub(remainForDev);
            remainForMarketing = accumulatedForMarketing.div(20).mul(19);
            accumulatedForMarketing = accumulatedForMarketing.sub(remainForMarketing);
            remainForLiq = accumulatedForLiquid.div(20).mul(19);
            accumulatedForLiquid = accumulatedForLiquid.sub(remainForLiq);
        }
        uint256 half = accumulatedForLiquid .div(2);
        uint256 otherHalf = accumulatedForLiquid.sub(half);

        uint256 swapAmount = half.add(accumulatedForMarketing).add(accumulatedForDev);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(swapAmount); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 delta = address(this).balance.sub(initialBalance);

        uint256 ethLiquid = delta.mul(half).div(swapAmount);
        uint256 ethMarketing = delta.mul(accumulatedForMarketing).div(swapAmount);
        uint256 ethDev = delta.sub(ethLiquid).sub(ethMarketing);

        if(ethLiquid > 0){
            addLiquidity(otherHalf, ethLiquid);
            emit SwapAndLiquify(half, ethLiquid, otherHalf);
        }

        if(ethMarketing > 0){
            payable(marketingWallet).transfer(ethMarketing);
        }

        if(ethDev > 0){
            payable(devWallet).transfer(ethDev);
        }
        accumulatedForLiquid = remainForLiq;
        accumulatedForMarketing = remainForMarketing;
        accumulatedForDev = remainForDev;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0, 
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
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
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingDevLiquidBurnFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMarketingDevLiquidBurnFee(tMarketingDevLiquidBurnFee, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingDevLiquidBurnFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeMarketingDevLiquidBurnFee(tMarketingDevLiquidBurnFee, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingDevLiquidBurnFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeMarketingDevLiquidBurnFee(tMarketingDevLiquidBurnFee, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingDevLiquidBurnFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeMarketingDevLiquidBurnFee(tMarketingDevLiquidBurnFee, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}