/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

/* 

Welcome to Bull season

https://linktr.ee/musclebullofficial

Bulls thrive when they run in packs!

    
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract Bull is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public _marketingAddress;
        
    address payable public _devAddress;
        
    address payable public liquidityAddress;

    address public _liquidityLocker;

    address public dead;
        
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Anti-bot and anti-whale mappings and variables
    bool public limitsInEffect = true;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10 * 1e9 * 1e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Muscle Bull Official";
    string private constant _symbol = "$BULL";
    uint8 private constant _decimals = 9;

    // these values are pretty much arbitrary since they get overwritten for every txn, but the placeholders make it easier to work with current contract.
    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _marketingFee;
    
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    uint256 public _buyTaxFee = 0;
    uint256 public _buyLiquidityFee = 6;
    uint256 public _buyMarketingFee = 4;

    uint256 public _sellTaxFee = 0;
    uint256 public _sellLiquidityFee = 6;
    uint256 public _sellMarketingFee = 4;
    
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 private _tradingTime = block.timestamp;
    mapping (address => bool) private _isSniper; 
    bool private sniperProtection = true;  
    uint256 private snipeBlockAmt;
    uint256 public snipersCaught = 0; 
    
    uint256 public _liquidityTokensToSwap;
    uint256 public _marketingTokensToSwap;
    uint256 private _divisor = 100; //set for token split
    
    uint256 public MaxTransactionAmount;
    uint256 public maxWalletAmount;
    bool public maxWalletActive;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public _isExcludedFromWalletLimit;
    
    bool private gasLimitActive = true;
    uint256 private gasPriceLimit;
    bool private sameBlockActive = true;   
    bool private _cooldownEnabled = true;
    mapping (address => User) private cooldown;
    mapping (address => uint256) private lastTrade;
    uint256 private buyLimitEnd;
    uint256 private _launchTime;
    uint256 public _launchNumber;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap;

        struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);
    
    event SetAutomatedMarketMakerPair(address pair, bool value);
    
    event ExcludeFromReward(address excludedAddress);
    
    event IncludeInReward(address includedAddress);
    
    event ExcludeFromFee(address excludedAddress);
    
    event IncludeInFee(address includedAddress);
    
    event SetBuyFee(uint256 marketingFee, uint256 liquidityFee, uint256 reflectFee);
    
    event SetSellFee(uint256 marketingFee, uint256 liquidityFee, uint256 reflectFee);
    
    event TransferForeignToken(address token, uint256 amount);
    
    event UpdatedMarketingAddress(address _marketing);

    event UpdatedDevAddress(address _devAddress);
    
    event UpdatedLiquidityAddress(address liquidity);
    
    event OwnerForcedSwapBack(uint256 timestamp);
    
    event SniperCaught(address indexed sniperAddress);
    
    event RemovedSniper(address indexed notsnipersupposedly);

    event CooldownEnabledUpdated(bool _cooldown);

    event ExemptProjectWallet(address exempt);

    event UpdatedMaxTransacationAmount(uint maxTx);

    event UpdatedMaxWalletAmount(uint maxWallet);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(uint256 _snipeBlockAmt, uint256 _gasPriceLimit, address payable marketingAddress, address payable devAddress, address liquidityLocker)  {
        _rOwned[_msgSender()] = _rTotal;
        
        MaxTransactionAmount =  10000001  * 10**9; // .01% MaxTransactionAmount at launch
        maxWalletAmount =  50000001  * 10**9; // .5% maxWalletAmount, will update after launch
        minimumTokensBeforeSwap = 5000000 * 10**9; // 0.05% swap tokens amount
        
        snipeBlockAmt = _snipeBlockAmt;
        gasPriceLimit = _gasPriceLimit * 1 gwei;
        
        _marketingAddress = marketingAddress;
        _devAddress = devAddress;
        liquidityAddress = payable(owner());
        _liquidityLocker = liquidityLocker;
        dead = 0x000000000000000000000000000000000000dEaD;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[devAddress] = true;
        _isExcludedFromFee[liquidityAddress] = true;
        _isExcludedFromFee[liquidityLocker] = true; 
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(dead), true);
        excludeFromMaxTransaction(address(marketingAddress), true);
        excludeFromMaxTransaction(address(devAddress), true);
        excludeFromMaxTransaction(address(liquidityLocker), true); 

        excludeFromWalletLimit(owner(), true); 
        excludeFromWalletLimit(address(this), true);
        excludeFromWalletLimit(address(dead), true);
        excludeFromWalletLimit(address(marketingAddress), true);
        excludeFromWalletLimit(address(devAddress), true);
        excludeFromWalletLimit(address(liquidityLocker), true); 
        
        
        emit Transfer(address(0), address(this), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
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
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    // remove limits after token is stable - 30-60 minutes
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        gasLimitActive = false;
        _cooldownEnabled = false;
        sameBlockActive = false;
        return true;
    }
    
    // disable Transfer cooldown
    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }
    
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromWalletLimit(address updAds, bool isEx) public onlyOwner {
        _isExcludedFromWalletLimit[updAds] = isEx;
    }
    
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        tradingActiveBlock = block.number;
        buyLimitEnd = block.timestamp + (300 seconds);
        maxWalletActive = false;
    }

    function enableMaxWallet (bool onoff) external onlyOwner {
        maxWalletActive = onoff;
    }
    
    // send tokens and ETH for liquidity to contract directly, then call this (not required, can still use Uniswap to add liquidity manually, but this ensures everything is excluded properly and makes for a great stealth launch)
    function addPair() external onlyOwner returns (bool){
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromWalletLimit(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        IUniswapV2Pair(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _launchTime = block.timestamp;
        _launchNumber = block.number;
        return true;
    }
    
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _isExcludedMaxTransactionAmount[pair] = value;
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
    }
    
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gasLimitActive = true);
        require(gas >= 100);
        gasPriceLimit = gas * 1 gwei;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length + 1 <= 50, "Cannot exclude more than 50 accounts.  Include a previously excluded address.");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                // updating _rOwned to make sure the balances stay the same
                if (_tOwned[account] > 0)
                {
                    uint256 newrOwned = _tOwned[account].mul(_getRate());
                    _rTotal = _rTotal.sub(_rOwned[account]-newrOwned);
                    _tFeeTotal = _tFeeTotal.add(_rOwned[account]-newrOwned);
                    _rOwned[account] = newrOwned;
                }
                else
                {
                    _rOwned[account] = 0;
                }

                _tOwned[account] = 0;
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
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
        
        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to] && !_isExcludedMaxTransactionAmount[to] && !_isExcludedFromWalletLimit[to], "Trading is not active yet.");
        }

        if (!_isExcludedMaxTransactionAmount[from] ) {
                        require(amount <= MaxTransactionAmount, "Buy transfer amount exceeds the MaxTransactionAmount.");
        }

        if(maxWalletActive){
            if(!_isExcludedFromWalletLimit[to]) {
                        require(balanceOf(to) + amount <= maxWalletAmount, "Max wallet exceeded");
                } 
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(dead) &&
                !inSwapAndLiquify
            ){
                
             if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }
                
                // only use to prevent sniper buys in the first few blocks.
                if (gasLimitActive && automatedMarketMakerPairs[from]) {
                    require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                }
                
                // at launch if the cooldown is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                    if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                          require(amount <= MaxTransactionAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[to].buy = block.timestamp + (15 seconds);
                        }
                    }
                }
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= MaxTransactionAmount, "Buy transfer amount exceeds the MaxTransactionAmount.");
                         if (gasLimitActive) {
                            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                        }

                        if (sameBlockActive) {
                            if (from == uniswapV2Pair){
                        require(lastTrade[to] != block.number);
                        lastTrade[to] = block.number;
                        }  else {
                            require(lastTrade[from] != block.number);
                            lastTrade[from] = block.number;
                            }
                        }
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= MaxTransactionAmount, "Sell transfer amount exceeds the MaxTransactionAmount.");
                }
                
                if (!_isExcludedFromWalletLimit[to]) {
                        require(balanceOf(to) + amount <= maxWalletAmount, "Max wallet exceeded");
                } 
            }
        }
        
        
        
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_marketingTokensToSwap);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // swap and liquify
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(uniswapV2Pair) > 0 &&
            totalTokensToSwap > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            automatedMarketMakerPairs[to] &&
            overMinimumTokenBalance
        ) {
            swapBack();
        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            buyOrSellSwitch = TRANSFER; // TRANSFERs do not pay a tax.
        } else {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                removeAllFee();
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyMarketingFee;
                buyOrSellSwitch = BUY;
            } 
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                removeAllFee();
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee + _sellMarketingFee;
                buyOrSellSwitch = SELL;
            }
                        
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        
    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap + _marketingTokensToSwap;
        
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForMarketing = ethBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing);

        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        
        //Send to Marketing addresses
        transferToAddressETH(ethForMarketing);

    }
    
    // force Swap back if slippage above 49% for launch.
    function forceSwapBack() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= _tTotal / 100, "Can only swap back if more than 1% of tokens stuck on contract");
        swapBack();
        emit OwnerForcedSwapBack(block.timestamp);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
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
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        
        if (sniperProtection){	
            // If sender is a sniper address, reject the sell.	
            if (isSniper(sender)) {	
                revert("Sniper rejected.");	
            }

            if (block.number - tradingActiveBlock < snipeBlockAmt) {
                        _isSniper[recipient] = true;
                        snipersCaught ++;
                        emit SniperCaught(recipient);
                    }
            if (block.number - _launchNumber < snipeBlockAmt) {
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
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
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

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
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

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
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

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
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

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
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
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _buyMarketingFee / _liquidityFee;
        } else if(buyOrSellSwitch == SELL){
            _liquidityTokensToSwap += tLiquidity * _sellLiquidityFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _sellMarketingFee / _liquidityFee;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function isSniper(address account) public view returns (bool) {	
        return _isSniper[account];	
    }	

    function removeSniper(address account) external onlyOwner() {	
        require(_isSniper[account], "Account is not a recorded sniper.");	
        _isSniper[account] = false;	
        emit RemovedSniper(account);
    }

    function disableSniper(bool antiSnipe) external onlyOwner() {
        sniperProtection = antiSnipe;
    }

        function setdivisorpercentage (uint256 divisor) external onlyOwner() {
        _divisor = divisor;
    }

    //Exempt project wallet
    function exemptProjectWallet(address account) external onlyOwner()  {
        _isExcludedFromFee[account] = true;
        _isExcludedFromWalletLimit[account] = true;
        _isExcludedMaxTransactionAmount[account] = true;
        emit ExemptProjectWallet(account);
    }

    //Non-exempt previous exempt wallets
    function includeInFee(address account) external onlyOwner()  {
        _isExcludedFromFee[account] = false;
        _isExcludedFromWalletLimit[account] = false;
        _isExcludedMaxTransactionAmount[account] = false;
        emit IncludeInFee(account);
    }

    function setBuyFee(uint256 buyTaxFee, uint256 buyLiquidityFee, uint256 buyMarketingFee)
        external
        onlyOwner
    {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyMarketingFee = buyMarketingFee;
        require(_buyTaxFee + _buyLiquidityFee + _buyMarketingFee <= 10, "Must keep buy taxes below 10%");
        emit SetBuyFee(buyMarketingFee, buyLiquidityFee, buyTaxFee);
    }

    function setSellFee(uint256 sellTaxFee, uint256 sellLiquidityFee, uint256 sellMarketingFee)
        external
        onlyOwner
    {
        _sellTaxFee = sellTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        require(_sellTaxFee + _sellLiquidityFee + _sellMarketingFee <= 15, "Must keep sell taxes below 15%");
        emit SetSellFee(sellMarketingFee, sellLiquidityFee, sellTaxFee);
    }


    function setMarketingAddress(address payable marketingAddress) external onlyOwner {
        require(marketingAddress != address(0), "_marketingAddress address cannot be 0");
        _marketingAddress = marketingAddress;
        _isExcludedFromFee[marketingAddress] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }

        function setDevAddress(address payable devAddress) external onlyOwner {
        require(devAddress != address(0), "devAddress address cannot be 0");
        _devAddress = devAddress;
        _isExcludedFromFee[devAddress] = true;
        emit UpdatedDevAddress(_devAddress);
    }
    
    function setLiquidityAddress(address _liquidityAddress) public onlyOwner {
        require(_liquidityAddress != address(0), "_liquidityAddress address cannot be 0");
        liquidityAddress = payable(_liquidityAddress);
        _isExcludedFromFee[liquidityAddress] = true;
        emit UpdatedLiquidityAddress(_liquidityAddress);
    }

    function setMaxTransacationAmount(uint256 maxTx) external onlyOwner {
        require(maxTx >= 10000001 , "Cannot set MaxTransacationAmount lower than .01%");
        MaxTransactionAmount = maxTx * 10**9;
        emit UpdatedMaxTransacationAmount(maxTx);
    }

    function setMaxWalletAmount(uint256 maxWallet) external onlyOwner {
        require(maxWallet >= 100000000 , "Cannot set MaxTransacationAmount lower than 1%");
        maxWalletAmount = maxWallet * 10**9;
        emit UpdatedMaxWalletAmount(maxWallet);
    }


    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    //transfer stuck ETH
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        _marketingAddress.transfer(contractETHBalance);
    }

    
    function setSwapAndLiquifyEnabled(uint256 _numTokensMin) public onlyOwner {
        swapAndLiquifyEnabled = true;
        minimumTokensBeforeSwap = _numTokensMin;
        emit SwapAndLiquifyEnabledUpdated(true);
    }
    
    function transferToAddressETH(uint256 amount) private {
    uint amt0 = amount / 100 * (_divisor);
    _marketingAddress.transfer(amt0);
    _devAddress.transfer(amount - amt0);
    }



    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
    
    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!tradingActive, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }
    

}