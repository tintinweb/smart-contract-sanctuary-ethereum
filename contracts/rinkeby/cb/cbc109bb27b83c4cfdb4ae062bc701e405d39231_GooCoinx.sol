/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
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

    function mint(address to) external returns (uint256 liquidity);

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

interface IBEP20 {
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

interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
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
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
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

contract Ownable is Context {
    address private _owner;

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract DividendPayingToken is
    BEP20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
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
        BEP20(_name, _symbol)
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

    function _withdrawDividendOfUser(address payable user)
        internal
        virtual
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract GooCoinx is BEP20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address private _pancakePairAddress;
    address public trapedToken;    
    address public uniswapV2Pair;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private swapping;
    bool public tradingEnabled = false;

    uint256 public sellAmount = 0;
    uint256 public buyAmount = 0;

    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    GooCoinxDividendTracker public dividendTracker;

    address payable public marketingWallet;

    // Max tx, dividend threshold and tax variables
    uint256 public swapTokensAtAmount;
    uint256 public sellDevFees;
    uint256 public sellCharityFees;
    uint256 public sellLiquidityFees;
    uint256 public buyDevFees;
    uint256 public buyMarketingFees;
    uint256 public buyLiquidityFees;
    uint256 public feedivisor;

    bool public swapAndLiquifyEnabled = true;

    // gas for processing auto claim dividends 
    uint256 public gasForProcessing = 300000;

    // exlcude from fees 
    mapping(address => bool) private _isExcludedFromFees;
    

    /* store addresses of automated market maker pairs. Any transfer to these addresses
    could be subject to a maximum transfer amount */
    mapping(address => bool) public automatedMarketMakerPairs;

    //lock variables
    mapping(address => uint256) public lockBonus;
    mapping(address => uint256) public tokensLocked;
    mapping(address => bool) private _isLocked;
    uint256 public bonusforlock;

    //for allowing specific address to trade while trading has not been enabled yet 
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    // Limit variables for bot protection
    bool public limitsInEffect = true; //boolean used to turn limits on and off
    uint256 private gasPriceLimit = 20 * 1 gwei; 
    mapping(address => uint256) private _holderLastTransferBlock; // for 1 tx per block
    mapping(address => uint256) private _holderLastTransferTimestamp; // for sell cooldown timer
    uint256 public launchblock;    
    uint256 public cooldowntimer = 60; //default cooldown 60s

    // LAUNCH Implement access control modifiers

    event EnableSwapAndLiquify(bool enabled);
    
    event updateMarketingWallet(address wallet);

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event TradingEnabled();

    event UpdateFees(
        uint256 sellDevFees,
        uint256 sellCharityFees,
        uint256 sellLiquidityFees,
        uint256 buyDevFees,
        uint256 buyMarketingFees,
        uint256 buyLiquidityFees
        
    );

    event Airdrop(address holder, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 amount, uint256 opAmount, bool success);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdatePayoutToken(address token);

    constructor() BEP20("GooCoinx", "GOX") {
        marketingWallet = payable(0x2BaEfec1814eef5f4f6757a870109C29179840e2); 
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


        buyDevFees = 100;
        sellDevFees = 100;
        buyMarketingFees = 100;
        sellCharityFees = 100;
        buyLiquidityFees = 100;
        sellLiquidityFees = 200;
        

        totalBuyFees = buyLiquidityFees
            .add(buyMarketingFees).add(buyDevFees);
        totalSellFees = sellLiquidityFees
            .add(sellCharityFees).add(sellDevFees);

        dividendTracker = new GooCoinxDividendTracker(
            payable(this),
            router,
            0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
            "GooCoinxTRACKER",
            "GooTRACKER"
        );

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
        _isExcludedFromFees[msg.sender] = true;

        uint256 totalTokenSupply = (1_000_000_000) * (10**18);
        _mint(owner(), totalTokenSupply); // only time internal mint function is ever called is to create supply
        swapTokensAtAmount = totalTokenSupply / 2000; // 0.005%;
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    // writeable function to enable trading, can only enable, trading can never be disabled
    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        launchblock = block.number;        
        emit TradingEnabled();
    }
    

    // change marketing wallet, just in case something goes wrong with the multi sig wallet
    function setMarketingWallet(address wallet) external onlyOwner {
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);
        marketingWallet = payable(wallet);
        emit updateMarketingWallet(wallet);
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
        dividendTracker.setBalance(account, getLockBalance(account));
    }

    //allow a wallet to trade before trading enabled
    function setCanTransferBefore(address wallet, bool enable)
        external
        onlyOwner
    {
        canTransferBeforeTradingIsEnabled[wallet] = enable;
    }

    // turn limits on and off
    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    // set cooldown timer, can only be between 0 and 300 seconds (5 mins max)
    function setcooldowntimer(uint256 value) external onlyOwner {
        require(value <= 300, "cooldown timer cannot exceed 5 minutes");
        cooldowntimer = value;
    }

    function PermaLockForAdditionalRewards(address wallet, uint256 amount) public onlyOwner {
        amount = amount * (10**18);
        tokensLocked[wallet] = amount;
        _isLocked[wallet] = true;
        lockBonus[wallet] = bonusforlock;
        dividendTracker.setBalance(wallet, getLockBalance(wallet));
    }

    function setLockBonus(uint256 bonus) public onlyOwner {
        require (bonus <= 100, "lock bonus cannot exceed 100%");
        bonusforlock = bonus;
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

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
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

    // only for recovering stranded tokens in the contract, in times of miscalculation or user error.
    function ownerWithdrawStrandedToken(address strandedToken) public onlyOwner {
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this)&&strandedToken!=address(trapedToken));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }       
    
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 1000000);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function transferAdmin(address newOwner) public onlyOwner {
        dividendTracker.excludeFromDividends(newOwner);
        _isExcludedFromFees[newOwner] = true;
        canTransferBeforeTradingIsEnabled[newOwner] = true;
        transferOwnership(newOwner);
    }

    function updateFees(
        uint256 devBuy,
        uint256 devSell,
        uint256 marketingBuy,
        uint256 charitySell,
        uint256 liquidityBuy,
        uint256 liquiditySell
    ) public onlyOwner {
        buyDevFees = devBuy;
        buyMarketingFees = marketingBuy;
        buyLiquidityFees = liquidityBuy;
        sellDevFees = devSell;
        sellCharityFees = charitySell;
        sellLiquidityFees = liquiditySell;


        totalSellFees = sellLiquidityFees
            .add(sellCharityFees).add(sellDevFees);
        totalBuyFees = buyLiquidityFees
            .add(buyMarketingFees).add(buyDevFees);

        emit UpdateFees(
            sellDevFees,
            sellCharityFees,
            sellLiquidityFees,
            buyDevFees,
            buyMarketingFees,
            buyLiquidityFees
        );
    }

    function getLockInfo(address account) external view returns (uint256) {
        return tokensLocked[account];
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
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

    function isExcludedFromAutoClaim(address account)
        external
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }

    function isReinvest(address account) external view returns (bool) {
        return dividendTracker.isReinvest(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        uint256 chairtyFees;
        uint256 devFees;
        uint256 marketingFees;
        uint256 liquidityFees;
        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");
            
        }
        if (_isLocked[from]) {
            require(balanceOf(from).sub(amount) >= tokensLocked[from], "Tokens are locked for extra rewards");
        }
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if (
            !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]
        ) {
            bool isSelling = automatedMarketMakerPairs[to];
            

            if (isSelling) {
                devFees = sellDevFees;
                chairtyFees = sellCharityFees;
                liquidityFees = sellLiquidityFees;

                if (limitsInEffect) {
                require(
                    block.timestamp >= _holderLastTransferTimestamp[tx.origin] + cooldowntimer,
                    "cooldown period active"
                );
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                }
            } else {
                devFees = buyDevFees;
                marketingFees = buyMarketingFees;
                liquidityFees = buyLiquidityFees;

                if (limitsInEffect) {
                require(
                    block.number > launchblock + 2,
                    "you shall not pass"
                );                                
                require(
                    tx.gasprice <= gasPriceLimit,
                    "Gas price exceeds limit."
                );
                require(
                    _holderLastTransferBlock[tx.origin] != block.number,
                    "Too many TX in block"
                );
                
                _holderLastTransferBlock[tx.origin] = block.number;
            }
            
            }

            uint256 totalFees = chairtyFees
                .add(liquidityFees)
                .add(marketingFees).add(devFees);

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap && !automatedMarketMakerPairs[from]) {
                swapping = true;

                if (swapAndLiquifyEnabled) {
                    uint256 totalBuySell = buyAmount.add(sellAmount);
                    uint256 swapAmountBought = contractTokenBalance
                        .mul(buyAmount)
                        .div(totalBuySell);
                    uint256 swapAmountSold = contractTokenBalance
                        .mul(sellAmount)
                        .div(totalBuySell);

                    uint256 swapBuyTokens = swapAmountBought
                        .mul(liquidityFees)
                        .div(totalBuyFees);

                    uint256 swapSellTokens = swapAmountSold
                        .mul(liquidityFees)
                        .div(totalSellFees);

                    uint256 swapTokens = swapSellTokens.add(swapBuyTokens);

                    swapAndLiquify(swapTokens);
                }

                uint256 remainingBalance = swapTokensAtAmount;
                swapAndSendDividends(remainingBalance);
                buyAmount = 0;
                sellAmount = 0;
                swapping = false;
            }

            uint256 fees = amount.mul(totalFees).div(10000);
            

            amount = amount.sub(fees);

            if (isSelling) {
                sellAmount = sellAmount.add(fees);
            } else {
                buyAmount = buyAmount.add(fees);
            }

            super._transfer(from, address(this), fees);
            

            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }

        super._transfer(from, to, amount);
        dividendTracker.setBalance(from, getLockBalance(from));
        dividendTracker.setBalance(to, getLockBalance(to));
    }

    function getLockBalance(address account) private view returns (uint256) {
        uint256 unlockedBalance = balanceOf(account).sub(tokensLocked[account]);
        uint256 lockBalance = unlockedBalance.add(tokensLocked[account].mul(lockBonus[account].add(100)).div(100));
        return
                lockBalance;
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

    function setMinimumTokenBalanceForAutoDividends(uint256 value)
        public
        onlyOwner
    {
        dividendTracker.setMinimumTokenBalanceForAutoDividends(value);
    }

    function setMinimumTokenBalanceForDividends(uint256 value)
        public
        onlyOwner
    {
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
            owner(),
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

        uint256 dividendsFromBuy = address(this)
            .balance
            .mul(buyAmount)
            .div(totalAmount)
            .add(buyMarketingFees);

        uint256 dividendsFromSell = address(this)
            .balance
            .mul(sellAmount)
            .div(totalAmount)
            .add(sellCharityFees);

        uint256 dividends = dividendsFromBuy.add(dividendsFromSell);
        bool success = true;
        bool successOp1 = true;

        if (dividends > 0) {
            (success, ) = address(dividendTracker).call{value: dividends}("");
        }
        uint256 _marketTotal = sellCharityFees.add(buyMarketingFees);

        uint256 feePortions;
        if (_marketTotal > 0) {
            feePortions = address(this).balance.div(_marketTotal);
        }

        uint256 marketingPayout = buyMarketingFees.add(sellCharityFees) * feePortions;

        if (marketingPayout > 0) {
            (successOp1, ) = address(marketingWallet).call{value: marketingPayout}("");
        }

        emit SendDividends(
            dividends,
            marketingPayout,
            success && successOp1
        );
    }

    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(airdropWallets.length == amount.length, "Arrays must be the same length");
        require(airdropWallets.length <= 200, "Wallets list length must be <= 200");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**18);
            super._transfer(msg.sender, wallet, airdropAmount);
            dividendTracker.setBalance(payable(wallet), getLockBalance(wallet));
        }
    }
}

contract GooCoinxDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => bool) public excludedFromAutoClaim;
    mapping(address => bool) public autoReinvest;
    address public defaultToken; // BUSD
    bool public allowCustomTokens;
    bool public allowAutoReinvest;
    bool public dividendsPaused = false;

    string private trackerName;
    string private trackerTicker;

    IUniswapV2Router02 public uniswapV2Router;

    GooCoinx public GooCoinxContract;

    mapping(address => uint256) public lastClaimTimes;

    uint256 private minimumTokenBalanceForAutoDividends;
    uint256 private minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(
        address indexed acount,
        uint256 value,
        bool indexed automatic
    );
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event SetAllowAutoReinvest(bool allow);

    constructor(
        address payable mainContract,
        address router,
        address token,
        string memory _name,
        string memory _ticker
    ) DividendPayingToken(_name, _ticker) {
        trackerName = _name;
        trackerTicker = _ticker;
        defaultToken = token;
        GooCoinxContract = GooCoinx(mainContract);
        minimumTokenBalanceForAutoDividends = 100_000_000000000000000000; // 100,000, 0,01% of supply
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

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "GooCoinx_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "GooCoinx_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main GooCoinx contract."
        );
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return excludedFromAutoClaim[account];
    }

    function isReinvest(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
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

    function setMinimumTokenBalanceForAutoDividends(uint256 value)
        external
        onlyOwner
    {
        minimumTokenBalanceForAutoDividends = value * (10**18);
    }

    function setMinimumTokenBalanceForDividends(uint256 value)
        external
        onlyOwner
    {
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

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
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
        } else {
            tokenHoldersMap.remove(account);
        }
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
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

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
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
            } else {
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

    function _reinvestDividendOfUser(address account)
        private
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            bool success;

            withdrawnDividends[account] = withdrawnDividends[account].add(
                _withdrawableDividend
            );

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(GooCoinxContract);

            uint256 prevBalance = GooCoinxContract.balanceOf(address(this));

            // make the swap
            try
                uniswapV2Router
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _withdrawableDividend
                }(
                    0, // accept any amount of Tokens
                    path,
                    address(this),
                    block.timestamp
                )
            {
                uint256 received = GooCoinxContract
                    .balanceOf(address(this))
                    .sub(prevBalance);
                if (received > 0) {
                    success = true;
                    GooCoinxContract.transfer(account, received);
                } else {
                    success = false;
                }
            } catch {
                success = false;
            }

            if (!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        override
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );

            address tokenAddress = defaultToken;
            bool success;

            if (tokenAddress == address(0)) {
                (success, ) = user.call{
                    value: _withdrawableDividend,
                    gas: 3000
                }("");
            } else {
                address[] memory path = new address[](2);
                path[0] = uniswapV2Router.WETH();
                path[1] = tokenAddress;
                try
                    uniswapV2Router
                        .swapExactETHForTokensSupportingFeeOnTransferTokens{
                        value: _withdrawableDividend
                    }(
                        0, // accept any amount of Tokens
                        path,
                        user,
                        block.timestamp
                    )
                {
                    success = true;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            } else {
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

    function getIndexOfKey(Map storage map, address key)
        internal
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
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