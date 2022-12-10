/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

/**
Venom SmartContract 
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v,
                    bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out,
               uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1,
                                                  uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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
        return 18;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,
                "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,
                "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount,"ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns (uint256);
    function withdrawnDividendOf(address _owner) external view returns (uint256);
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired,
                          uint256 amountAMin, uint256 amountBMin, address to, 
                          uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin,
                             uint256 amountETHMin, address to, uint256 deadline) external payable
                             returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin,
                             uint256 amountBMin, address to, uint256 deadline) external 
                             returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin,
                                uint256 amountETHMin, address to, uint256 deadline) external 
                                returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin,
                                       uint256 amountBMin, address to, uint256 deadline, bool approveMax,
                                       uint8 v, bytes32 r, bytes32 s) external 
                                       returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin,
                                          uint256 amountETHMin, address to, uint256 deadline, bool approveMax,
                                          uint8 v, bytes32 r, bytes32 s) external 
                                          returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
                                      address to, uint256 deadline) external 
                                      returns (uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path,
                                      address to, uint256 deadline) external 
                                      returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, 
                                   uint256 deadline) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path,
                                   address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
                                   address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to,
                                   uint256 deadline) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin,
                                                             uint256 amountETHMin, address to, uint256 deadline) 
                                                             external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin,
                                                                       uint256 amountETHMin, address to, uint256 deadline,
                                                                       bool approveMax, uint8 v, bytes32 r, bytes32 s) 
                                                                       external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin,
                                                                   address[] calldata path, address to, uint256 deadline) 
                                                                   external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path,
                                                                address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
                                                                address to, uint256 deadline) external;
}

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal virtual returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{value: _withdrawableDividend, gas: 3000}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        return
            magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
            .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } 
        else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract Venom is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private swapping;
    bool public tradingEnabled = false;

    uint256 public sellAmount = 1;
    uint256 public buyAmount = 1;

    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    VenomDividendTracker public dividendTracker;

    address payable public marketingWallet;

    // Max tx, dividend threshold and tax variables
    uint256 public maxWallet;
    uint256 public maxTX;
    uint256 public swapTokensAtAmount;
    uint256 public sellRewardsFee;
    uint256 public sellDeadFees;
    uint256 public sellMarketingFees;
    uint256 public sellLiquidityFee;
    uint256 public buyDeadFees;
    uint256 public buyMarketingFees;
    uint256 public buyLiquidityFee;
    uint256 public buyRewardsFee;
    uint256 public transferFee;

    bool public swapAndLiquifyEnabled = true;

    uint256 public gasForProcessing = 500000;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;
    mapping(address => uint256) private tokensVesting;
    mapping(address => bool) private _isVesting;
    mapping(address => uint256) private _vestingTimestamp;
    mapping(address => bool) private _diamondHands;
    mapping(address => bool) private _multiplier;
    mapping(address => uint256) private _holderBuy1Timestamp;
    mapping(address => uint256) private _holderBuy2Timestamp;
    uint256 private minimumForDiamondHands;

    // Limit variables for bot protection
    bool public limitsInEffect = true; //boolean used to turn limits on and off
    uint256 private gasPriceLimit; 
    mapping(address => uint256) private _holderLastTransferBlock; // for 1 tx per block
    mapping(address => uint256) private _holderLastTransferTimestamp; // for sell cooldown timer
    mapping(address => uint256) private _holderFirstBuyTimestamp;
    
   
    
    uint256 public launchblock;
    uint256 public launchtimestamp;
    
    uint256 public delay;
    uint256 public cooldowntimer = 60; //default cooldown 60s

    event EnableSwapAndLiquify(bool enabled);
    event SetPreSaleWallet(address wallet);
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event TradingEnabled();
    event UpdateFees(uint256 sellDeadFees, uint256 sellMarketingFees, uint256 sellLiquidityFee, uint256 sellRewardsFee,
                     uint256 buyDeadFees, uint256 buyMarketingFees, uint256 buyLiquidityFee, uint256 buyRewardsFee);

    event UpdateTransferFee(uint256 transferFee);
    event Airdrop(address holder, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 amount, uint256 opAmount, bool success);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex,
                                   bool indexed automatic, uint256 gas);

    event UpdatePayoutToken(address token);

    constructor() ERC20("Venom", "VNM") {
        marketingWallet = payable(0xB4ba72b728248Ba8caC7f1A8f560324340a6c239);
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        buyDeadFees = 2;
        sellDeadFees = 2;
        buyMarketingFees = 2;
        sellMarketingFees = 2;
        buyLiquidityFee = 0;
        sellLiquidityFee = 0;
        buyRewardsFee = 2;
        sellRewardsFee = 2;
        transferFee = 1;

        totalBuyFees = buyRewardsFee.add(buyLiquidityFee).add(buyMarketingFees);
        totalSellFees = sellRewardsFee.add(sellLiquidityFee).add(sellMarketingFees);

        dividendTracker = new VenomDividendTracker(payable(this), router, address(this),
                                                   "VenomTRACKER", "VNMTRACKER");

        uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludedFromDividends(address(0));
        dividendTracker.excludeFromDividends(router);
        dividendTracker.excludeFromDividends(marketingWallet);
        dividendTracker.excludeFromDividends(owner());

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;
        _isExcludedFromFees[address(marketingWallet)] = true;
        _isExcludedFromFees[msg.sender] = true;

        uint256 totalTokenSupply = (100_000_000_000) * (10**18);
        _mint(owner(), totalTokenSupply); // only time internal mint function is ever called is to create supply
        swapTokensAtAmount = totalTokenSupply / 2000; // 0.05%
        minimumForDiamondHands = totalTokenSupply / 2000; // 0.05%
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    // writeable function to enable trading, can only enable, trading can never be disabled
    function enableTrading(uint256 initialMaxGwei, uint256 initialMaxWallet, uint256 initialMaxTX,
                           uint256 setDelay) external onlyOwner {
        initialMaxWallet = initialMaxWallet * (10**18);
        initialMaxTX = initialMaxTX * (10**18);
        require(!tradingEnabled);
        require(initialMaxWallet >= _totalSupply / 1000,"cannot set below 0.1%");
        require(initialMaxTX >= _totalSupply / 1000,"cannot set below 0.1%");
        maxWallet = initialMaxWallet;
        maxTX = initialMaxTX;
        gasPriceLimit = initialMaxGwei * 1 gwei;
        tradingEnabled = true;
        launchblock = block.number;
        launchtimestamp = block.timestamp;
        delay = setDelay;
        emit TradingEnabled();
    }
    // use for pre sale wallet, adds all exclusions to it
    function setPresaleWallet(address wallet) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = true;
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);
        emit SetPreSaleWallet(wallet);
    }
    
    // exclude a wallet from fees 
    function setExcludeFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // exclude from dividends (rewards)
    function setExcludeDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // include in dividends 
    function setIncludeDividends(address account) public onlyOwner {
        dividendTracker.includeFromDividends(account);
        dividendTracker.setBalance(account, getMultiplier(account));
    }

    //allow a wallet to trade before trading enabled
    function setCanTransferBefore(address wallet, bool enable) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = enable;
    }

    // turn limits on and off
    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    // set max GWEI
    function setGasPriceLimit(uint256 GWEI) external onlyOwner {
        require(GWEI >= 50, "can never be set lower than 50");
        gasPriceLimit = GWEI * 1 gwei;
    }

    // set cooldown timer, can only be between 0 and 300 seconds (5 mins max)
    function setcooldowntimer(uint256 value) external onlyOwner {
        require(value <= 300, "cooldown timer cannot exceed 5 minutes");
        cooldowntimer = value;
    }

    // set max wallet, can not be lower than 0.1% of supply
    function setmaxWallet(uint256 value) external onlyOwner {
        value = value * (10**18);
        require(value >= _totalSupply / 1000, "max wallet cannot be set to less than 0.1%");
        maxWallet = value;
    }

    // in case any ETH gets stuck in the contract
    function Sweep() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH);
    }

    // set max tx, can not be lower than 0.1% of supply
    function setmaxTX(uint256 value) external onlyOwner {
        value = value * (10**18);
        require(value >= _totalSupply / 1000, "max tx cannot be set to less than 0.1%");
        maxTX = value;
    }

    function setMinimumForDiamondHands (uint256 value) external onlyOwner {
        value = value * (10**18);
        require(value <= _totalSupply / 2000, "cannot be set to more than 0.05%");
        minimumForDiamondHands = value;
    }

    // rewards threshold
    function setSwapTriggerAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * (10**18);
    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;
        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setAllowCustomTokens(bool allow) public onlyOwner {
        dividendTracker.setAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) public onlyOwner {
        dividendTracker.setAllowAutoReinvest(allow);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 5000000);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function transferAdmin(address newOwner) public onlyOwner {
        dividendTracker.excludeFromDividends(newOwner);
        _isExcludedFromFees[newOwner] = true;
        transferOwnership(newOwner);
    }

    function updateTransferFee(uint256 newTransferFee) public onlyOwner {
        require (newTransferFee <= 5, "transfer fee cannot exceed 5%");
        transferFee = newTransferFee;
        emit UpdateTransferFee(transferFee);
    }

    function updateRewardsMultiplier() external {
        if (!_multiplier[msg.sender]) {
                    _multiplier[msg.sender] = true;
                }
        dividendTracker.setBalance(msg.sender, getMultiplier(msg.sender));
    }

    function updateFees(uint256 deadBuy, uint256 deadSell, uint256 marketingBuy, uint256 marketingSell,
                        uint256 liquidityBuy, uint256 liquiditySell, uint256 RewardsBuy,
                        uint256 RewardsSell) public onlyOwner {
        
        buyDeadFees = deadBuy;
        buyMarketingFees = marketingBuy;
        buyLiquidityFee = liquidityBuy;
        buyRewardsFee = RewardsBuy;
        sellDeadFees = deadSell;
        sellMarketingFees = marketingSell;
        sellLiquidityFee = liquiditySell;
        sellRewardsFee = RewardsSell;

        totalSellFees = sellRewardsFee.add(sellLiquidityFee).add(sellMarketingFees);

        totalBuyFees = buyRewardsFee.add(buyLiquidityFee).add(buyMarketingFees);
        require(deadBuy <= 3 && deadSell <= 3, "burn fees cannot exceed 3%");
        require(totalSellFees <= 10 && totalBuyFees <= 10, "total fees cannot exceed 10%");

        emit UpdateFees(sellDeadFees, sellMarketingFees, sellLiquidityFee, sellRewardsFee, buyDeadFees,
                        buyMarketingFees, buyLiquidityFee, buyRewardsFee);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256,
                                                                             uint256, uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256,
                                                                                  uint256, uint256, uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAutoClaim(bool value) external {
        dividendTracker.setAutoClaim(msg.sender, value);
    }

    function setReinvest(bool value) external {
        dividendTracker.setReinvest(msg.sender, value);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        dividendTracker.setDividendsPaused(value);
    }

    function isExcludedFromAutoClaim(address account) external view returns (bool) {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }

    function isReinvest(address account) external view returns (bool) {
        return dividendTracker.isReinvest(account);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 RewardsFee;
        uint256 deadFees;
        uint256 marketingFees;
        uint256 liquidityFee;

        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");
        }
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } 

        if (_isVesting[from]) {
            if (block.timestamp < _vestingTimestamp[from] + 5 minutes) {
                require(balanceOf(from) - amount >= tokensVesting[from], "cant sell vested tokens");
            }
            else {
                tokensVesting[from] = 0;
                _isVesting[from] = false;
            }
        }

        
        else if (!swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            bool isSelling = automatedMarketMakerPairs[to];
            bool isBuying = automatedMarketMakerPairs[from];

            if (!isBuying && !isSelling) {
                if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                    uint256 tFees = amount.mul(transferFee).div(100);
                    amount = amount.sub(tFees);
                    super._transfer(from, address(this), tFees);
                    super._transfer(from, to, amount);
                    dividendTracker.setBalance(from, getMultiplier(from));
                    dividendTracker.setBalance(to, getMultiplier(to));
                    _diamondHands[from] = false;
                    _multiplier[from] = false;
                    _holderFirstBuyTimestamp[from] = block.timestamp;
                    return;
                }
                else {
                    super._transfer(from, to, amount);
                    dividendTracker.setBalance(from, getMultiplier(from));
                    dividendTracker.setBalance(to, getMultiplier(to));
                    _diamondHands[from] = false;
                    _multiplier[from] = false;
                    _holderFirstBuyTimestamp[from] = block.timestamp;
                    return;
                }
            }

            else if (isSelling) {
                if (amount >= minimumForDiamondHands) {
                    RewardsFee = 8;
                }
                else {
                    RewardsFee = sellRewardsFee;
                }
                deadFees = sellDeadFees;
                marketingFees = sellMarketingFees;
                liquidityFee = sellLiquidityFee;

                if (limitsInEffect) {
                require(block.timestamp >= _holderLastTransferTimestamp[from] + cooldowntimer,
                        "cooldown period active");
                require(amount <= maxTX,"above max transaction limit");
                _holderLastTransferTimestamp[from] = block.timestamp;

                }
                _diamondHands[from] = false;
                _multiplier[from] = false;
                _holderFirstBuyTimestamp[from] = block.timestamp;


            } else if (isBuying) {

                if (_diamondHands[to]) {
                    if (block.timestamp >= _holderBuy1Timestamp[to] + 1 days && balanceOf(to) >= minimumForDiamondHands) {
                        super._transfer(from, to, amount);
                        dividendTracker.setBalance(from, getMultiplier(from));
                        dividendTracker.setBalance(to, getMultiplier(to));
                        return;
                    }
                }

                if (!_multiplier[to]) {
                    _multiplier[to] = true;
                    _holderFirstBuyTimestamp[to] = block.timestamp;
                }

                if (!_diamondHands[to]) {
                    _diamondHands[to] = true;
                    _holderBuy1Timestamp[to] = block.timestamp;
                }

                RewardsFee = buyRewardsFee;
                deadFees = buyDeadFees;
                marketingFees = buyMarketingFees;
                liquidityFee = buyLiquidityFee;

                if (limitsInEffect) {
                require(block.timestamp > launchtimestamp + delay,"you shall not pass");
                require(tx.gasprice <= gasPriceLimit,"Gas price exceeds limit.");
                require(_holderLastTransferBlock[to] != block.number,"Too many TX in block");
                require(amount <= maxTX,"above max transaction limit");
                _holderLastTransferBlock[to] = block.number;
                }

                uint256 contractBalanceRecipient = balanceOf(to);
                require(contractBalanceRecipient + amount <= maxWallet,"Exceeds maximum wallet token amount." );
            }

            uint256 totalFees = RewardsFee.add(liquidityFee + marketingFees);

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap && isSelling) {
                swapping = true;

                if (swapAndLiquifyEnabled && liquidityFee > 0 && totalBuyFees > 0) {
                    uint256 totalBuySell = buyAmount.add(sellAmount);
                    uint256 swapAmountBought = contractTokenBalance.mul(buyAmount).div(totalBuySell);
                    uint256 swapAmountSold = contractTokenBalance.mul(sellAmount).div(totalBuySell);
                    uint256 swapBuyTokens = swapAmountBought.mul(liquidityFee).div(totalBuyFees);
                    uint256 swapSellTokens = swapAmountSold.mul(liquidityFee).div(totalSellFees);
                    uint256 swapTokens = swapSellTokens.add(swapBuyTokens);

                    swapAndLiquify(swapTokens);
                }

                uint256 remainingBalance = balanceOf(address(this));
                swapAndSendDividends(remainingBalance);
                buyAmount = 1;
                sellAmount = 1;
                swapping = false;
            }

            uint256 fees = amount.mul(totalFees).div(100);
            uint256 burntokens;

            if (deadFees > 0) {
            burntokens = amount.mul(deadFees) / 100;
            super._transfer(from, DEAD, burntokens);
            _totalSupply = _totalSupply.sub(burntokens);

            }

            amount = amount.sub(fees + burntokens);

            if (isSelling) {
                sellAmount = sellAmount.add(fees);
            } 
            else {
                buyAmount = buyAmount.add(fees);
            }

            super._transfer(from, address(this), fees);

            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas);
            } catch {}
        }

        super._transfer(from, to, amount);
        dividendTracker.setBalance(from, getMultiplier(from));
        dividendTracker.setBalance(to, getMultiplier(to));
    }

    function getMultiplier(address account) private view returns (uint256) {
        uint256 multiplier;
        if (_multiplier[account] && block.timestamp > _holderFirstBuyTimestamp[account] + 1 weeks && 
            block.timestamp < _holderFirstBuyTimestamp[account] + 2 weeks) {
            multiplier = balanceOf(account).mul(3);
        }
        else if (_multiplier[account] && block.timestamp > _holderFirstBuyTimestamp[account] + 2 weeks && 
                 block.timestamp < _holderFirstBuyTimestamp[account] + 3 weeks) {
                     multiplier = balanceOf(account).mul(5);
        }
        else if (_multiplier[account] && block.timestamp > _holderFirstBuyTimestamp[account] + 3 weeks) {
                     multiplier = balanceOf(account).mul(7);
        }
        else {
            multiplier = balanceOf(account);
        }
        
        return
                multiplier;
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function updatePayoutToken(address token) public onlyOwner {
        dividendTracker.updatePayoutToken(token);
        emit UpdatePayoutToken(token);
    }

    function getPayoutToken() public view returns (address) {
        return dividendTracker.getPayoutToken();
    }

    function setMinimumTokenBalanceForAutoDividends(uint256 value) public onlyOwner {
        dividendTracker.setMinimumTokenBalanceForAutoDividends(value);
    }

    function setMinimumTokenBalanceForDividends(uint256 value) public onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(value);
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
            address(0),
            block.timestamp
        );
    }

    function forceSwapAndSendDividends(uint256 tokens) public onlyOwner {
        tokens = tokens * (10**18);
        uint256 totalAmount = buyAmount.add(sellAmount);
        uint256 fromBuy = tokens.mul(buyAmount).div(totalAmount);
        uint256 fromSell = tokens.mul(sellAmount).div(totalAmount);

        swapAndSendDividends(tokens);

        buyAmount = buyAmount.sub(fromBuy);
        sellAmount = sellAmount.sub(fromSell);
    }

    function swapAndSendDividends(uint256 tokens) private {
        if (tokens == 0) {
            return;
        }
        swapTokensForEth(tokens);
        uint256 totalAmount = buyAmount.add(sellAmount);

        bool success = true;
        bool successOp1 = true;

        uint256 dividends;
        uint256 dividendsFromBuy;
        uint256 dividendsFromSell;

        if (buyRewardsFee > 0) {
            dividendsFromBuy = address(this).balance.mul(buyAmount).div(totalAmount)
            .mul(buyRewardsFee).div(buyRewardsFee + buyMarketingFees);
        }
        if (sellRewardsFee > 0) {
            dividendsFromSell = address(this).balance.mul(sellAmount).div(totalAmount)
            .mul(sellRewardsFee).div(sellRewardsFee + sellMarketingFees);
        }
        dividends = dividendsFromBuy.add(dividendsFromSell);

        if (dividends > 0) {
            (success, ) = address(dividendTracker).call{value: dividends}("");
        }
        
        uint256 _completeFees = sellMarketingFees + buyMarketingFees;

        uint256 feePortions;
        if (_completeFees > 0) {
            feePortions = address(this).balance.div(_completeFees);
        }
        uint256 marketingPayout = buyMarketingFees.add(sellMarketingFees).mul(feePortions);

        if (marketingPayout > 0) {
            (successOp1, ) = address(marketingWallet).call{value: marketingPayout}("");
        }

        emit SendDividends(dividends, marketingPayout, success && successOp1);
    }

    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(airdropWallets.length == amount.length,"Arrays must be the same length");
        require(airdropWallets.length <= 200, "Wallets list length must be <= 200");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**18);
            super._transfer(msg.sender, wallet, airdropAmount);
            dividendTracker.setBalance(payable(wallet), getMultiplier(wallet));
        }
    }

    function airdropToWalletsAndVest(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(airdropWallets.length == amount.length, "Arrays must be the same length");
        require(airdropWallets.length <= 200, "Wallets list length must be <= 200");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**18);
            super._transfer(msg.sender, wallet, airdropAmount);
            dividendTracker.setBalance(payable(wallet), getMultiplier(wallet));
            tokensVesting[wallet] = airdropAmount;
            _isVesting[wallet] = true;
            _vestingTimestamp[wallet] = block.timestamp;
        }
    }
}

contract VenomDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => bool) public excludedFromAutoClaim;
    mapping(address => bool) public autoReinvest;
    address public defaultToken;
    bool public allowCustomTokens;
    bool public allowAutoReinvest;
    bool public dividendsPaused = false;

    string private trackerName;
    string private trackerTicker;

    IUniswapV2Router02 public uniswapV2Router;

    Venom public VenomContract;

    mapping(address => uint256) public lastClaimTimes;

    uint256 private minimumTokenBalanceForAutoDividends;
    uint256 private minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(address indexed acount, uint256 value, bool indexed automatic);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event SetAllowAutoReinvest(bool allow);

    constructor(address payable mainContract, address router, address token, string memory _name,
                string memory _ticker) DividendPayingToken(_name, _ticker) {
        
        trackerName = _name;
        trackerTicker = _ticker;
        defaultToken = token;
        VenomContract = Venom(mainContract);
        minimumTokenBalanceForAutoDividends = 1_000000000000000000; // 1 token
        minimumTokenBalanceForDividends = minimumTokenBalanceForAutoDividends;

        uniswapV2Router = IUniswapV2Router02(router);
        allowCustomTokens = true;
        allowAutoReinvest = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return trackerName;
    }

    function symbol() public view virtual override returns (string memory) {
        return trackerTicker;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "withdrawDividend disabled. Use the 'claim' function on the main Venom contract.");
    }

    function isExcludedFromAutoClaim(address account) external view onlyOwner returns (bool) {
        return excludedFromAutoClaim[account];
    }

    function isReinvest(address account) external view onlyOwner returns (bool) {
        return autoReinvest[account];
    }

    function setAllowCustomTokens(bool allow) external onlyOwner {
        require(allowCustomTokens != allow);
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) external onlyOwner {
        require(allowAutoReinvest != allow);
        allowAutoReinvest = allow;
        emit SetAllowAutoReinvest(allow);
    }

    function excludeFromDividends(address account) external onlyOwner {
        //require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = false;
    }

    function setAutoClaim(address account, bool value) external onlyOwner {
        excludedFromAutoClaim[account] = value;
    }

    function setReinvest(address account, bool value) external onlyOwner {
        autoReinvest[account] = value;
    }

    function setMinimumTokenBalanceForAutoDividends(uint256 value) external onlyOwner {
        minimumTokenBalanceForAutoDividends = value * (10**18);
    }

    function setMinimumTokenBalanceForDividends(uint256 value) external onlyOwner {
        minimumTokenBalanceForDividends = value * (10**18);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        require(dividendsPaused != value);
        dividendsPaused = value;
        emit DividendsPaused(value);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account) public view returns (address account, int256 index, int256 iterationsUntilProcessed,
                                                               uint256 withdrawableDividends, uint256 totalDividends,
                                                               uint256 lastClaimTime) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            } 
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256,
                                                                   uint256, uint256) {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance < minimumTokenBalanceForDividends) {
            tokenHoldersMap.remove(account);
            _setBalance(account, 0);

            return;
        }

        _setBalance(account, newBalance);

        if (newBalance >= minimumTokenBalanceForAutoDividends) {
            tokenHoldersMap.set(account, newBalance);
        } 
        else {
            tokenHoldersMap.remove(account);
        }
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256)
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0 || dividendsPaused) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= numberOfTokenHolders) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (!excludedFromAutoClaim[account]) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner
        returns (bool)
    {
        if (dividendsPaused) {
            return false;
        }

        bool reinvest = autoReinvest[account];

        if (automatic && reinvest && !allowAutoReinvest) {
            return false;
        }

        uint256 amount = reinvest
            ? _reinvestDividendOfUser(account)
            : _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            if (reinvest) {
                emit DividendReinvested(account, amount, automatic);
            } 
            else {
                emit Claim(account, amount, automatic);
            }
            return true;
        }

        return false;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updatePayoutToken(address token) public onlyOwner {
        defaultToken = token;
    }

    function getPayoutToken() public view returns (address) {
        return defaultToken;
    }

    function _reinvestDividendOfUser(address account) private returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            bool success;

            withdrawnDividends[account] = withdrawnDividends[account].add(_withdrawableDividend);

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(VenomContract);

            uint256 prevBalance = VenomContract.balanceOf(address(this));

            // make the swap
            try
                uniswapV2Router
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{value: _withdrawableDividend}
                    (0, path, address(this), block.timestamp)
            {
                uint256 received = VenomContract.balanceOf(address(this)).sub(prevBalance);
                if (received > 0) {
                    success = true;
                    VenomContract.transfer(account, received);
                } 
                else {
                    success = false;
                }
            } catch {
                success = false;
            }

            if (!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _withdrawDividendOfUser(address payable user) internal override returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

            address tokenAddress = defaultToken;
            bool success;

            if (tokenAddress == address(0)) {
                (success, ) = user.call{value: _withdrawableDividend, gas: 3000}("");
            } 
            else {
                address[] memory path = new address[](2);
                path[0] = uniswapV2Router.WETH();
                path[1] = tokenAddress;
                try
                    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _withdrawableDividend}(0, path, user, block.timestamp)
                {
                    success = true;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            } 
            else {
                emit DividendWithdrawn(user, _withdrawableDividend);
            }
            return _withdrawableDividend;
        }
        return 0;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint256 val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}