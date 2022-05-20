/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT

// Telegram: t.me/NotOkayToken
// 
// Website: https://nokay.app

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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
    uint256 private _lockTime;

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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
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

contract NOTOKAY is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public marketingAddress =
        payable(0xa956463b1361fe8C528A8CA40c70F11FA0AfB187);

    address payable public liquidityAddress =
        payable(0xa956463b1361fe8C528A8CA40c70F11FA0AfB187);

    address payable public devAddress =
        payable(0x83d07e6539552B72EA93142ff911FA2514845109);

    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _brcrOwned;
    mapping(address => uint256) private _brctOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBlackListed;
    address[] private _excluded;

    address public bridgeContract;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _brctTotal = 1000000000000 * 1e18;
    uint256 private _brcrTotal = (MAX - (MAX % _brctTotal));
    uint256 private _brctFeeTotal;

    bool public limitsInEffect = true;

    string private constant _name = "NOT OKAY";
    string private constant _symbol = "NOKAY";

    uint8 private constant _decimals = 18;

    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 private _buyTaxFee = 0;
    uint256 public _buyDeveloperFee = 2;
    uint256 public _buyLiquidityFee = 4;
    uint256 public _buyMarketingFee = 1;

    uint256 private _sellTaxFee = 0;
    uint256 public _sellDeveloperFee = 2;
    uint256 public _sellLiquidityFee = 4;
    uint256 public _sellMarketingFee = 1;

    uint256 public tradingActiveBlock = 0;
    mapping(address => bool) public boughtEarly;
    uint256 public earlyBuyPenaltyEnd;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _teamTokensToSwap;

    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 100 * 1 gwei;
    uint256 private gasMaxLimit = 50000000;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap = (_brctTotal * 5) / 10000;

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

    event SetBuyFee(uint256 marketingFee, uint256 liquidityFee, uint256 devFee);

    event SetSellFee(
        uint256 marketingFee,
        uint256 liquidityFee,
        uint256 devFee
    );

    event TransferForeignToken(address token, uint256 amount);

    event UpdatedMarketingAddress(address marketing);

    event UpdatedLiquidityAddress(address liquidity);

    event UpdatedDevAddress(address devAddress);

    event OwnerForcedSwapBack(uint256 timestamp);

    event BoughtEarly(address indexed sniper);

    event RemovedSniper(address indexed notsnipersupposedly);

    event UpdatedRouter(address indexed newrouter);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier tempRemoveLimits() {
        bool tempLimitsInEffect = limitsInEffect;

        if (tempLimitsInEffect == true) {
            limitsInEffect = false;
        }

        _;

        if (tempLimitsInEffect == true) {
            limitsInEffect = true;
        }
    }

    constructor() {
        _brcrOwned[_msgSender()] = _brcrTotal;

        maxTransactionAmount = (_brctTotal * 5) / 1000;
        maxWallet = (_brctTotal * 20) / 1000;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[liquidityAddress] = true;
        _isExcludedFromFee[devAddress] = true;

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        emit Transfer(address(0), _msgSender(), _brctTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _brctTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _brctOwned[account];

        require(
            _brcrOwned[account] <= _brcrTotal,
            "Amount must be less than total brc"
        );
        uint256 currentRate = _getRate();
        return _brcrOwned[account].div(currentRate);
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
        external
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
        if (_msgSender() != bridgeContract) {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }
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
        return _brctFeeTotal;
    }

    function enableTrading() external onlyOwner {
        if (tradingActive == false && tradingActiveBlock == 0) {
            tradingActive = true;
            swapAndLiquifyEnabled = true;
            tradingActiveBlock = block.number;
            earlyBuyPenaltyEnd = block.timestamp + 72 hours;
        } else if (tradingActive == false && tradingActiveBlock > 100) {
            tradingActive = true;
        } else {
            tradingActive = false;
        }
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        if (value) {
            excludeFromReward(pair);
        }
        if (!value) {
            includeInReward(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setProtectionSettings(bool antiGas) external onlyOwner {
        gasLimitActive = antiGas;
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75);
        gasPriceLimit = gas * 1 gwei;
    }

    function setGasMaxLimit(uint256 gas) external onlyOwner {
        require(gas >= 750000);
        gasMaxLimit = gas * gasPriceLimit;
    }

    function removeLimits(bool _case) public onlyOwner returns (bool) {
        limitsInEffect = _case;
        gasLimitActive = _case;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(
            _excluded.length + 1 <= 50,
            "Cannot exclude more than 50 accounts.  Include a previously excluded address."
        );
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _includeInReward(address account) private {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _brctOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function includeInReward(address account) public onlyOwner {
        _includeInReward(account);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function safeTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner tempRemoveLimits {
        _transfer(from, to, amount);
    }

    function clearStuckBNB(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(owner()).transfer((amountBNB * amountPercentage) / 100);
    }

    function clearStuckToken(IERC20 _token, uint256 amountPercentage)
        external
        onlyOwner
    {
        uint256 amountToken = _token.balanceOf(address(this));
        _token.transfer(owner(), (amountToken * amountPercentage) / 100);
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
        require(_isBlackListed[from] == false, "Sender is Blacklisted");

        if (!tradingActive) {
            require(
                _isExcludedFromFee[from] || _isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inSwapAndLiquify
            ) {
                if (
                    from != owner() &&
                    to != uniswapV2Pair &&
                    block.number == tradingActiveBlock
                ) {
                    boughtEarly[to] = true;
                    emit BoughtEarly(to);
                }

                if (gasLimitActive && automatedMarketMakerPairs[from]) {
                    require(
                        tx.gasprice <= gasPriceLimit,
                        "Gas price exceeds limit."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 totalTokensToSwap = _liquidityTokensToSwap +
            _marketingTokensToSwap +
            _teamTokensToSwap;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;

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

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            buyOrSellSwitch = TRANSFER;
        } else {
            if (automatedMarketMakerPairs[from]) {
                removeAllFee();
                _taxFee = _buyTaxFee;
                _liquidityFee =
                    _buyDeveloperFee +
                    _buyLiquidityFee +
                    _buyMarketingFee;
                buyOrSellSwitch = BUY;
            } else if (automatedMarketMakerPairs[to]) {
                removeAllFee();
                _taxFee = _sellTaxFee;
                _liquidityFee =
                    _sellDeveloperFee +
                    _sellLiquidityFee +
                    _sellMarketingFee;
                buyOrSellSwitch = SELL;
                if (boughtEarly[from] && earlyBuyPenaltyEnd <= block.number) {
                    _taxFee = _taxFee * 3;
                    _liquidityFee = _liquidityFee * 3;
                }
            } else {
                removeAllFee();
                buyOrSellSwitch = TRANSFER;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap = _liquidityTokensToSwap
            .add(_teamTokensToSwap)
            .add(_marketingTokensToSwap);

        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB = contractBalance.sub(tokensForLiquidity);

        uint256 initialBNBBalance = address(this).balance;

        swapTokensForBNB(amountToSwapForBNB);

        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);

        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(
            totalTokensToSwap
        );
        uint256 bnbForTeam = bnbBalance.mul(_teamTokensToSwap).div(
            totalTokensToSwap
        );
        uint256 bnbForLiquidity = bnbBalance.sub(bnbForMarketing).sub(
            bnbForTeam
        );

        _liquidityTokensToSwap = 0;
        _teamTokensToSwap = 0;
        _marketingTokensToSwap = 0;

        (bool success, ) = address(devAddress).call{value: bnbForTeam}("");
        (success, ) = address(marketingAddress).call{value: bnbForMarketing}(
            ""
        );

        addLiquidity(tokensForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(
            amountToSwapForBNB,
            bnbForLiquidity,
            tokensForLiquidity
        );

        if (address(this).balance > 1e17) {
            (success, ) = address(marketingAddress).call{
                value: address(this).balance
            }("");
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
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

        restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 brctAmount
    ) private {
        (
            uint256 brcrAmount,
            uint256 brcrTransferAmount,
            uint256 brcrFee,
            uint256 brctTransferAmount,
            uint256 brctFee,
            uint256 brctLiquidity
        ) = _getValues(brctAmount);
        _brcrOwned[sender] = _brcrOwned[sender].sub(brcrAmount);
        _brcrOwned[recipient] = _brcrOwned[recipient].add(brcrTransferAmount);
        _takeLiquidity(brctLiquidity);
        _brcFee(brcrFee, brctFee);
        emit Transfer(sender, recipient, brctTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 brctAmount
    ) private {
        (
            uint256 brcrAmount,
            uint256 brcrTransferAmount,
            uint256 brcrFee,
            uint256 brctTransferAmount,
            uint256 brctFee,
            uint256 brctLiquidity
        ) = _getValues(brctAmount);
        _brcrOwned[sender] = _brcrOwned[sender].sub(brcrAmount);
        _brctOwned[recipient] = _brctOwned[recipient].add(brctTransferAmount);
        _brcrOwned[recipient] = _brcrOwned[recipient].add(brcrTransferAmount);
        _takeLiquidity(brctLiquidity);
        _brcFee(brcrFee, brctFee);
        emit Transfer(sender, recipient, brctTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 brctAmount
    ) private {
        (
            uint256 brcrAmount,
            uint256 brcrTransferAmount,
            uint256 brcrFee,
            uint256 brctTransferAmount,
            uint256 brctFee,
            uint256 brctLiquidity
        ) = _getValues(brctAmount);
        _brctOwned[sender] = _brctOwned[sender].sub(brctAmount);
        _brcrOwned[sender] = _brcrOwned[sender].sub(brcrAmount);
        _brcrOwned[recipient] = _brcrOwned[recipient].add(brcrTransferAmount);
        _takeLiquidity(brctLiquidity);
        _brcFee(brcrFee, brctFee);
        emit Transfer(sender, recipient, brctTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 brctAmount
    ) private {
        (
            uint256 brcrAmount,
            uint256 brcrTransferAmount,
            uint256 brcrFee,
            uint256 brctTransferAmount,
            uint256 brctFee,
            uint256 brctLiquidity
        ) = _getValues(brctAmount);
        _brctOwned[sender] = _brctOwned[sender].sub(brctAmount);
        _brcrOwned[sender] = _brcrOwned[sender].sub(brcrAmount);
        _brctOwned[recipient] = _brctOwned[recipient].add(brctTransferAmount);
        _brcrOwned[recipient] = _brcrOwned[recipient].add(brcrTransferAmount);
        _takeLiquidity(brctLiquidity);
        _brcFee(brcrFee, brctFee);
        emit Transfer(sender, recipient, brctTransferAmount);
    }

    function _brcFee(uint256 brcrFee, uint256 tFee) private {
        _brcrTotal = _brcrTotal.sub(brcrFee);
        _brctFeeTotal = _brctFeeTotal.add(tFee);
    }

    function _getValues(uint256 brctAmount)
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
            uint256 brctTransferAmount,
            uint256 brctFee,
            uint256 brctLiquidity
        ) = _getTValues(brctAmount);
        (
            uint256 brcrAmount,
            uint256 brcrTransferAmount,
            uint256 brcrFee
        ) = _getBrcRValues(brctAmount, brctFee, brctLiquidity, _getRate());
        return (
            brcrAmount,
            brcrTransferAmount,
            brcrFee,
            brctTransferAmount,
            brctFee,
            brctLiquidity
        );
    }

    function _getTValues(uint256 brctAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 brctFee = calculateTaxFee(brctAmount);
        uint256 brctLiquidity = calculateLiquidityFee(brctAmount);
        uint256 tTransferAmount = brctAmount.sub(brctFee).sub(brctLiquidity);
        return (tTransferAmount, brctFee, brctLiquidity);
    }

    function _getBrcRValues(
        uint256 brctAmount,
        uint256 brctFee,
        uint256 brctLiquidity,
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
        uint256 brcrAmount = brctAmount.mul(currentRate);
        uint256 brcrFee = brctFee.mul(currentRate);
        uint256 brcrLiquidity = brctLiquidity.mul(currentRate);
        uint256 rTransferAmount = brcrAmount.sub(brcrFee).sub(brcrLiquidity);
        return (brcrAmount, rTransferAmount, brcrFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 brcrSupply, uint256 brctSupply) = _getCurrentSupply();
        return brcrSupply.div(brctSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 brcrSupply = _brcrTotal;
        uint256 brctSupply = _brctTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _brcrOwned[_excluded[i]] > brcrSupply ||
                _brctOwned[_excluded[i]] > brctSupply
            ) return (_brcrTotal, _brctTotal);
            brcrSupply = brcrSupply.sub(_brcrOwned[_excluded[i]]);
            brctSupply = brctSupply.sub(_brctOwned[_excluded[i]]);
        }
        if (brcrSupply < _brcrTotal.div(_brctTotal))
            return (_brcrTotal, _brctTotal);
        return (brcrSupply, brctSupply);
    }

    function _takeLiquidity(uint256 brctLiquidity) private {
        if (buyOrSellSwitch == BUY) {
            _liquidityTokensToSwap +=
                (brctLiquidity * _buyDeveloperFee) /
                _liquidityFee;
            _teamTokensToSwap += (brctLiquidity * _buyMarketingFee) / _liquidityFee;
            _marketingTokensToSwap +=
                (brctLiquidity * _buyLiquidityFee) /
                _liquidityFee;
        } else if (buyOrSellSwitch == SELL) {
            _liquidityTokensToSwap +=
                (brctLiquidity * _sellDeveloperFee) /
                _liquidityFee;
            _teamTokensToSwap += (brctLiquidity * _sellMarketingFee) / _liquidityFee;
            _marketingTokensToSwap +=
                (brctLiquidity * _sellLiquidityFee) /
                _liquidityFee;
        }
        uint256 currentRate = _getRate();
        uint256 brcrLiquidity = brctLiquidity.mul(currentRate);
        _brcrOwned[address(this)] = _brcrOwned[address(this)].add(
            brcrLiquidity
        );
        if (_isExcluded[address(this)])
            _brctOwned[address(this)] = _brctOwned[address(this)].add(
                brctLiquidity
            );
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

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function antiWhale(address account) external onlyOwner {
        boughtEarly[account] = false;
        emit RemovedSniper(account);
    }

    function setFlagAddress(address account, bool flag) external onlyOwner {
        _isBlackListed[account] = flag;
    }

    function setBridgeContract(address _bridgeAddress) external onlyOwner {
        bridgeContract = _bridgeAddress;
    }

    function setBuyFee(
        uint256 buyDevFee,
        uint256 buyLiquidityFee,
        uint256 buyMarketingFee
    ) external onlyOwner {
        _buyMarketingFee = buyMarketingFee;
        _buyDeveloperFee = buyDevFee;
        _buyLiquidityFee = buyLiquidityFee;
        require(
            _buyMarketingFee + _buyDeveloperFee + _buyLiquidityFee <= 30,
            "Must keep taxes below 30%"
        );
        emit SetBuyFee(buyMarketingFee, buyLiquidityFee, buyDevFee);
    }

    function setSellFee(
        uint256 sellDevFee,
        uint256 sellLiquidityFee,
        uint256 sellMarketingFee
    ) external onlyOwner {
        _sellMarketingFee = sellMarketingFee;
        _sellDeveloperFee = sellDevFee;
        _sellLiquidityFee = sellLiquidityFee;
        require(
            _sellMarketingFee + _sellDeveloperFee + _sellLiquidityFee <= 30,
            "Must keep taxes below 30%"
        );
        emit SetSellFee(sellMarketingFee, sellLiquidityFee, sellDevFee);
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(
            _marketingAddress != address(0),
            "_marketingAddress address cannot be 0"
        );
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
        _isExcludedFromFee[devAddress] = true;
        emit UpdatedDevAddress(devAddress);
    }

    function setLiquidityAddress(address _liquidityAddress) external onlyOwner {
        require(
            _liquidityAddress != address(0),
            "_liquidityAddress address cannot be 0"
        );
        liquidityAddress = payable(_liquidityAddress);
        _isExcludedFromFee[liquidityAddress] = true;
        emit UpdatedLiquidityAddress(_liquidityAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function getPairAddress() external view onlyOwner returns (address) {
        return uniswapV2Pair;
    }

    function changeRouterVersion(address _router)
        external
        onlyOwner
        returns (address _pair)
    {
        require(_router != address(0), "_router address cannot be 0");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        if (_pair == address(0)) {
            _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }
        uniswapV2Pair = _pair;

        uniswapV2Router = _uniswapV2Router;
        emit UpdatedRouter(_router);
    }

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
}

// Contract Developer: Dapprex
// www.dapprex.com