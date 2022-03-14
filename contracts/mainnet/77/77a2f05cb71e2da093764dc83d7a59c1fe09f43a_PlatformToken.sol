/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _ownermint;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _ownermint = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function ownermint() external view returns (address) {
        return _ownermint;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwnerMint() {
        require(
            _ownermint == _msgSender(),
            "Ownable: caller is not the ownermint"
        );
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renounceOwnershipMint() external virtual onlyOwner {
        emit OwnershipTransferred(_ownermint, _owner);
        _ownermint = _owner;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnershipMint(address newOwner)
        external
        virtual
        onlyOwnerMint
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_ownermint, newOwner);
        _ownermint = newOwner;
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
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
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
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
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

/** DividendPayingToken simplified explanation:
 *
 * When the holder reaching minimumTokenBalanceForDividends, non-transferable Divident Paying tokens will be minted.
 * Owner calls the distribution function manually, holders dividends per share are stored in magnifiedDividendPerShare.
 *
 * Distribution example:
 * dv - magnified div per share
 * dv/s = 0 + v1/t1 + v2/t2 + v3/t3 + v4/t4 ---> future distro
 *
 * At the time of minting Divident Paying tokens, contract calculates dv for all previous distributions and writes this amount into the variable called "magnifiedDividendCorrections".
 * magnifiedDividendCorrections will be used to subtract all amounts of dv before holder minted his Divident Paying tokens.
 */

contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant MAGNITUDE = 2**128;
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

    /**
     * @dev function requires sending ethereum
     * @dev Magnified divident per share will be 0 on the time of deployement
     */

    function distributeDividends() public payable override {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(MAGNITUDE) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    function withdrawDividend() external virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            emit DividendWithdrawn(user, _withdrawableDividend);
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
            } else {
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
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
        external
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
                .toUint256Safe() / MAGNITUDE;
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

contract PlatformToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    VCDividendTracker public dividendTracker;

    address public uniswapV2Pair;
    uint256 internal constant ONE = 10**18;
    address internal constant ZERO_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // store automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public automatedMarketMakerRouters;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public vestedAddress;
    mapping(address => uint256) public initialVest;
    mapping(address => uint256) private _lastTX;
    mapping(address => uint256) private _lastTransfer;
    mapping(address => uint256) private _lastDailyTransferedAmount;

    uint256 public nativeRewardsFee;
    uint256 public projectFee;
    uint256 public liquidityFee;
    uint256 private maxTXAmount;
    uint256 public swapTokensAtAmount;
    uint256 public totalFees;
    uint256 public firstLiveBlock;
    uint256 public firstLiveBlockNumber;
    uint256 public maxHoldings;
    uint256 public vestedSellLimit;
    uint256 public totalSellFees;
    uint256 public maximumDailyAmountToSell;

    bool public swapEnabled;
    bool public sendDividendsEnabled;
    bool public paused;
    bool public maxTXEnabled;
    bool public maxHoldingsEnabled;
    bool public antiSnipeBot;
    bool public cooldown;
    bool public buySellOnly;
    bool public takeFees;
    bool public dailyCoolDown;
    bool public enableMaxDailySell;
    bool private swapping;

    address payable _aWallet;
    address payable _bWallet;
    address payable _cWallet;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SendDividends(uint256 amount);
    event MaxDailyAmountToSellChanged(uint256 oldAmount, uint256 newAmount);
    event MaxHoldingsChanged(
        uint256 oldHoldings,
        uint256 newHoldings,
        bool maxHoldingsEnabled
    );
    event VestedSellLimitChanged(uint256 oldLimit, uint256 newLimit);
    event FeesChanged(
        uint256 nativeRewardsFee,
        uint256 liquidityFee,
        uint256 projectFee,
        uint256 totalFees
    );
    event MaxTXAmountChanged(uint256 oldMaxTXAmount, uint256 maxTXAmount);
    event SwapTokensAtAmountChanged(
        uint256 oldSwapTokensAtAmount,
        uint256 swapTokensAtAmount
    );

    constructor() ERC20("Viral Crypto", "VC") {
        dividendTracker = new VCDividendTracker();
        updateUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), false);
        dividendTracker.excludeFromDividends(address(this), false);
        dividendTracker.excludeFromDividends(owner(), false);
        dividendTracker.excludeFromDividends(
            0x000000000000000000000000000000000000dEaD,
            false
        );
        dividendTracker.excludeFromDividends(ZERO_ADDRESS, false);
        dividendTracker.excludeFromDividends(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            false
        );

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_aWallet, true);
        excludeFromFees(address(this), true);

        _mint(owner(), 27020401250 * (ONE));

        nativeRewardsFee = 5;
        projectFee = 5;
        liquidityFee = 2;
        maxTXAmount = 75000000 * (ONE);
        maxHoldings = 150000000 * (ONE);
        maximumDailyAmountToSell = 5 * maxTXAmount;
        swapTokensAtAmount = 2000000 * (ONE);
        totalFees = nativeRewardsFee.add(projectFee).add(liquidityFee);
        totalSellFees = totalFees;
        swapEnabled = true;
        sendDividendsEnabled = true;
        maxHoldingsEnabled = true;
        maxTXEnabled = true;
        antiSnipeBot = true;
        cooldown = true;
        paused = true;
        buySellOnly = true;
        takeFees = true;
    }

    receive() external payable {}

    function mint(address _to, uint256 _amount) external onlyOwnerMint {
        _mint(_to, _amount);
    }

    function setWETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function updateDividendTracker(address newAddress) external onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "The dividend tracker already has that address"
        );
        VCDividendTracker newDividendTracker = VCDividendTracker(
            payable(newAddress)
        );
        require(
            newDividendTracker.checkOwnership(address(this)),
            "The new dividend tracker must be owned by token contract"
        );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            false
        );
        newDividendTracker.excludeFromDividends(address(this), false);
        newDividendTracker.excludeFromDividends(owner(), false);
        newDividendTracker.excludeFromDividends(
            address(uniswapV2Router),
            false
        );
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "The router already has that address"
        );
        require(
            newAddress != address(0),
            "New router should not be address zero"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        automatedMarketMakerRouters[address(uniswapV2Router)] = false;
        automatedMarketMakerPairs[uniswapV2Pair] = false;
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), WETH);
        if (_uniswapV2Pair == ZERO_ADDRESS) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), WETH);
        }
        automatedMarketMakerRouters[newAddress] = true;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    /**
     * @dev sets inital vest amount and bool for a vested address and transfers tokens to address so they collect dividends
     */
    function airdrop(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "Array sizes must be equal"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i].mul(ONE);
            _transfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }

    /**
     * @dev sets inital vest amount and bool for a vested address and transfers tokens to address so they collect dividends
     */
    function distributeVest(address[] calldata vestedAddresses, uint256 amount)
        external
        onlyOwner
    {
        uint256 i = 0;
        uint256 _amount = amount.mul(ONE);
        while (i < vestedAddresses.length) {
            address vestAddress = vestedAddresses[i];
            _transfer(msg.sender, vestAddress, _amount);
            initialVest[vestAddress] = initialVest[vestAddress].add(_amount);
            vestedAddress[vestAddress] = true;

            i += 1;
        }
    }

    /**
     * @dev Creating pair with uni factory, pairs on other DEXes should be created manually
     */
    function createPair() external onlyOwner {
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), WETH);
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account already 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setTakeFees(bool _takeFees) external onlyOwner {
        require(takeFees != _takeFees, "Updating to current value, takeFees");
        takeFees = _takeFees;
    }

    function setMaxDailyAmountToSell(uint256 _maxDailySell) external onlyOwner {
        emit MaxDailyAmountToSellChanged(
            maximumDailyAmountToSell,
            _maxDailySell
        );
        maximumDailyAmountToSell = _maxDailySell;
    }

    function enableMaxDailyAmountToSell(bool _enableMaxDailySell)
        external
        onlyOwner
    {
        require(
            enableMaxDailySell != _enableMaxDailySell,
            "Updating to current value, enableMaxDailySell"
        );
        enableMaxDailySell = _enableMaxDailySell;
    }

    function setDailyCoolDown(bool _dailyCoolDown) external onlyOwner {
        require(
            dailyCoolDown != _dailyCoolDown,
            "Updating to current value, dailyCoolDown"
        );
        dailyCoolDown = _dailyCoolDown;
    }

    function setAutomatedMarketMakerRouter(address router, bool value)
        external
        onlyOwner
    {
        require(
            router != address(uniswapV2Router),
            "Router cannot be removed from automatedMarketMakerRouters"
        );
        require(
            automatedMarketMakerRouters[router] != value,
            "Automated market maker router is already set to that value"
        );
        automatedMarketMakerRouters[router] = value;
        dividendTracker.excludeFromDividends(router, false);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, false);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        if (value) {
            require(!isBlacklisted[account], "Already blacklisted");
            dividendTracker.excludeFromDividends(account, true);
        }
        isBlacklisted[account] = value;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateMinimumToken(uint256 minimumToken) external onlyOwner {
        dividendTracker.updateMinimumToken(minimumToken);
    }

    function getMinHoldForDividends() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account, bool reduceHolderCount)
        external
        onlyOwner
    {
        require(
            !(dividendTracker.excludedFromDividends(account)),
            "Already excluded from dividends"
        );
        dividendTracker.excludeFromDividends(account, reduceHolderCount);
    }

    function getAccountDividendsInfo(address _account)
        external
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        return dividendTracker.getAccount(_account);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "A wallet should not be address zero");
        _aWallet = payable(newWallet);
    }

    function setBWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "B wallet should not be address zero");

        _bWallet = payable(newWallet);
    }

    function setCWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "C wallet should not be address zero");

        _cWallet = payable(newWallet);
    }

    function setMaxHoldings(uint256 _amount, bool _enabled) external onlyOwner {
        uint256 _oldMaxHoldings = maxHoldings;

        maxHoldings = _amount.mul(ONE);
        maxHoldingsEnabled = _enabled;

        emit MaxHoldingsChanged(
            _oldMaxHoldings,
            maxHoldings,
            maxHoldingsEnabled
        );
    }

    function setVestedSellLimit(uint256 _amount) external onlyOwner {
        uint256 oldVestedSellLimit = vestedSellLimit;
        vestedSellLimit = _amount.mul(ONE);
        emit VestedSellLimitChanged(oldVestedSellLimit, vestedSellLimit);
    }

    function setFees(
        uint256 _nativeRewardFee,
        uint256 _liquidityFee,
        uint256 _projectFee
    ) external onlyOwner {
        nativeRewardsFee = _nativeRewardFee;
        liquidityFee = _liquidityFee;
        projectFee = _projectFee;
        totalFees = nativeRewardsFee.add(liquidityFee).add(projectFee);

        emit FeesChanged(nativeRewardsFee, liquidityFee, projectFee, totalFees);
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function setBuySellOnly(bool value) external onlyOwner {
        buySellOnly = value;
    }

    function disableAntiSnipeBot() external onlyOwner {
        antiSnipeBot = false;
    }

    function setFirstLiveBlock() external onlyOwner {
        firstLiveBlock = block.timestamp;
        firstLiveBlockNumber = block.number;
        paused = false;
    }

    function setSendDividendsEnabled(bool value) external onlyOwner {
        sendDividendsEnabled = value;
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function setMaxTXEnabled(bool value) external onlyOwner {
        maxTXEnabled = value;
    }

    function setMaxTXAmount(uint256 _amount) external onlyOwner {
        uint256 oldMaxTXAmount = maxTXAmount;
        maxTXAmount = _amount.mul(ONE);
        emit MaxTXAmountChanged(oldMaxTXAmount, maxTXAmount);
    }

    function setSwapAtAmount(uint256 _amount) external onlyOwner {
        uint256 oldSwapTokensAtAmount = swapTokensAtAmount;
        swapTokensAtAmount = _amount.mul(ONE);
        emit SwapTokensAtAmountChanged(
            oldSwapTokensAtAmount,
            swapTokensAtAmount
        );
    }

    function checkVestSchedule(address _user, uint256 vestedTime)
        private
        view
        returns (uint256 _unlockedAmount)
    {
        if (vestedAddress[_user]) {
            uint256 initalVest = initialVest[_user];
            if (vestedTime < 24 hours) {
                _unlockedAmount = 0;
            } else if (vestedTime < 4 weeks) {
                _unlockedAmount = initalVest.mul(2).div(10);
            } else if (vestedTime < 8 weeks) {
                _unlockedAmount = initalVest.mul(25).div(100);
            } else if (vestedTime < 12 weeks) {
                _unlockedAmount = initalVest.mul(30).div(100);
            } else if (vestedTime < 16 weeks) {
                _unlockedAmount = initalVest.mul(35).div(100);
            } else if (vestedTime < 20 weeks) {
                _unlockedAmount = initalVest.mul(24).div(100);
            } else if (vestedTime < 24 weeks) {
                _unlockedAmount = initalVest.mul(45).div(100);
            } else if (vestedTime < 28 weeks) {
                _unlockedAmount = initalVest.div(2);
            } else if (vestedTime < 32 weeks) {
                _unlockedAmount = initalVest.mul(56).div(100);
            } else if (vestedTime < 36 weeks) {
                _unlockedAmount = initalVest.mul(62).div(100);
            } else if (vestedTime < 40 weeks) {
                _unlockedAmount = initalVest.mul(68).div(100);
            } else if (vestedTime < 44 weeks) {
                _unlockedAmount = initalVest.mul(76).div(100);
            } else if (vestedTime < 48 weeks) {
                _unlockedAmount = initalVest.mul(84).div(100);
            } else if (vestedTime < 52 weeks) {
                _unlockedAmount = initalVest.mul(92).div(100);
            } else if (vestedTime > 52 weeks) {
                _unlockedAmount = initalVest;
            }
        }
    }

    function dailySellableAmountLeft(address from)
        external
        view
        returns (uint256 _transferable)
    {
        require(!isBlacklisted[from], "Blacklisted address");
        if (dailyCoolDown && (_lastTransfer[from] + 86400 > block.timestamp)) {
            return 0;
        }

        _transferable = balanceOf(from);

        uint256 vestedTime = block.timestamp.sub(firstLiveBlock);

        if (!(vestedTime > 52 weeks || !vestedAddress[from])) {
            uint256 unlocked = checkVestSchedule(from, vestedTime);

            unlocked = unlocked > vestedSellLimit ? vestedSellLimit : unlocked;

            if (balanceOf(from) > initialVest[from].sub(unlocked)) {
                _transferable = balanceOf(from).sub(
                    initialVest[from].sub(unlocked)
                );
            } else {
                return 0;
            }
        }

        if (
            enableMaxDailySell && _lastTransfer[from] + 86400 > block.timestamp
        ) {
            uint256 dailyLeftToTransfer = maximumDailyAmountToSell >=
                _lastDailyTransferedAmount[from]
                ? maximumDailyAmountToSell.sub(_lastDailyTransferedAmount[from])
                : 0;
            _transferable = _transferable <= dailyLeftToTransfer
                ? _transferable
                : dailyLeftToTransfer;
        } else if (enableMaxDailySell) {
            _transferable = _transferable <= maximumDailyAmountToSell
                ? _transferable
                : maximumDailyAmountToSell;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !isBlacklisted[from] &&
                !isBlacklisted[to] &&
                !isBlacklisted[tx.origin],
            "Blacklisted address"
        );
        if (from != owner()) {
            require(!paused, "trading paused");
        }

        if (from != owner() && to != owner()) {
            checkTransactionParameters(from, to, amount);
        }

        if (isBlacklisted[tx.origin]) {
            return;
        }

        uint256 balance = balanceOf(from);
        uint256 vestedTime = block.timestamp.sub(firstLiveBlock);

        if (vestedTime > 52 weeks) {
            if (vestedAddress[from]) {
                vestedAddress[from] = false;
            }
        } else {
            uint256 unlockedVest = checkVestSchedule(from, vestedTime);
            if (
                automatedMarketMakerPairs[to] || automatedMarketMakerRouters[to]
            ) {
                unlockedVest = unlockedVest > vestedSellLimit
                    ? vestedSellLimit
                    : unlockedVest;
            }

            require(
                balance.sub(amount) >= initialVest[from].sub(unlockedVest),
                "Can't bypass vest and can't bypass vestedSellLimit"
            );
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            swapTokensAtAmount;
        if (
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            overMinimumTokenBalance
        ) {
            swapping = true;
            swapAndDistribute(contractTokenBalance);
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || !takeFees) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
            if (
                from != owner() &&
                from != address(this) &&
                !(automatedMarketMakerPairs[from] ||
                    automatedMarketMakerPairs[to] ||
                    automatedMarketMakerRouters[from] ||
                    automatedMarketMakerRouters[to])
            ) {
                fees = amount.mul(totalSellFees).div(100);
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        //check if bots were blacklisted on first block before setting dividends
        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    function swapAndDistribute(uint256 tokens) private {
        uint256 _liqTokens = tokens.mul(liquidityFee).div(totalFees);
        uint256 tokensToSave = _liqTokens.div(2);
        uint256 tokensToSwap = tokens.sub(tokensToSave);
        uint256 preBalance = address(this).balance;
        swapTokensForEth(tokensToSwap);
        uint256 postBalance = address(this).balance.sub(preBalance);
        uint256 ethForLiq = (
            postBalance.mul(liquidityFee).div(totalFees).div(2)
        );
        uint256 ethForProject = (
            postBalance.mul(projectFee).div(totalFees).div(3)
        );
        _aWallet.transfer(ethForProject);
        _bWallet.transfer(ethForProject);
        _cWallet.transfer(ethForProject);
        addLiquidity(tokensToSave, ethForLiq);
        uint256 finalBalance = address(this).balance;
        if (sendDividendsEnabled) {
            sendDividends(finalBalance);
        }
    }

    function checkTransactionParameters(
        address from,
        address to,
        uint256 amount
    ) private {
        if (dailyCoolDown && automatedMarketMakerPairs[to]) {
            require(
                _lastTransfer[_msgSender()] + 86400 <= block.timestamp,
                "One sell per day is allowed"
            );
        }

        if (automatedMarketMakerPairs[to]) {
            if (_lastTransfer[_msgSender()] + 86400 >= block.timestamp) {
                _lastDailyTransferedAmount[_msgSender()] += amount;
            } else {
                _lastDailyTransferedAmount[_msgSender()] = amount;
            }

            _lastTransfer[_msgSender()] = block.timestamp;
        }

        if (enableMaxDailySell) {
            require(
                _lastDailyTransferedAmount[_msgSender()] <=
                    maximumDailyAmountToSell,
                "Max daily sell amount was reached"
            );
        }

        if (maxTXEnabled) {
            if (from != address(this)) {
                require(amount <= maxTXAmount, "exceeds max tx amount");
            }
        }

        if (cooldown) {
            if (
                from != address(this) &&
                to != address(this) &&
                !automatedMarketMakerRouters[to] &&
                !automatedMarketMakerPairs[to]
            ) {
                require(
                    block.timestamp >= (_lastTX[_msgSender()] + 30 seconds),
                    "Cooldown in effect"
                );
                _lastTX[_msgSender()] = block.timestamp;
            }
        }

        if (antiSnipeBot) {
            if (
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerRouters[to] &&
                to != address(this) &&
                from != address(this)
            ) {
                require(tx.origin == to);
            }
            if (block.number <= firstLiveBlockNumber + 4) {
                isBlacklisted[tx.origin] = true;
                if (tx.origin != from && tx.origin != to) {
                    dividendTracker.excludeFromDividends(tx.origin, true);
                }
                if (
                    !automatedMarketMakerPairs[from] &&
                    !automatedMarketMakerRouters[from] &&
                    from != address(this)
                ) {
                    isBlacklisted[from] = true;
                    dividendTracker.excludeFromDividends(from, true);
                }

                if (
                    !automatedMarketMakerPairs[to] &&
                    !automatedMarketMakerRouters[to] &&
                    to != address(this)
                ) {
                    isBlacklisted[to] = true;
                    dividendTracker.excludeFromDividends(to, true);
                }
            }
        }

        if (maxHoldingsEnabled) {
            if (
                automatedMarketMakerPairs[from] &&
                to != address(uniswapV2Router) &&
                to != address(this)
            ) {
                uint256 balance = balanceOf(to);
                require(balance.add(amount) <= maxHoldings);
            }
        }

        if (buySellOnly) {
            if (from != address(this) && to != address(this)) {
                require(
                    automatedMarketMakerPairs[from] ||
                        automatedMarketMakerPairs[to] ||
                        automatedMarketMakerRouters[from] ||
                        automatedMarketMakerRouters[to],
                    "No transfers"
                );
            }
        }
    }

    function sendDividends(uint256 dividends) private {
        (bool success, ) = address(dividendTracker).call{value: dividends}("");
        if (success) {
            emit SendDividends(dividends);
        }
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

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}

contract VCDividendTracker is Context, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping(address => bool) isDividendHolder;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    mapping(address => bool) private isOwner;

    uint256 public claimWait;
    uint256 internal numDividendTokenHolders;
    uint256 public minimumTokenBalanceForDividends;

    modifier onlyOwners() {
        require(isOwner[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event minimumTokenBalanceUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    event OwnershipSet(address indexed account, bool indexed vaule);

    constructor()
        DividendPayingToken("VC_Dividend_Tracker", "VC_Dividend_Tracker")
    {
        isOwner[_msgSender()] = true;
        isOwner[tx.origin] = true;
        emit OwnershipSet(_msgSender(), true);
        emit OwnershipSet(tx.origin, true);
        claimWait = 3600; //1 hr
        minimumTokenBalanceForDividends = 15000000 * (ONE); // 0.0555%
    }

    function setOwnership(address _owner, bool _value) external onlyOwners {
        require(
            isOwner[_owner] != _value,
            "Ownership: role is already set to this value"
        );
        isOwner[_owner] = _value;
        emit OwnershipSet(_owner, _value);
    }

    function checkOwnership(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        require(
            false,
            "Viral_Dividend_Tracker: Token is not transferable, no need to approve"
        );
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Viral_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() external pure override {
        require(
            false,
            "Viral_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main VIRAL contract."
        );
    }

    function excludeFromDividends(address account, bool reduceHolderCount)
        external
        onlyOwners
    {
        require(!excludedFromDividends[account], "Account already excluded");
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        if (reduceHolderCount) {
            if (isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwners {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "Viral_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "Viral_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumToken(uint256 newMinimumToken) external onlyOwners {
        require(
            newMinimumToken >= 1,
            "Viral_Dividend_Tracker: newMinimumToken more 1 token"
        );

        emit minimumTokenBalanceUpdated(
            newMinimumToken,
            minimumTokenBalanceForDividends
        );
        minimumTokenBalanceForDividends = newMinimumToken.mul(ONE);
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return numDividendTokenHolders;
    }

    function getAccount(address _account)
        external
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0
            ? lastClaimTime.add(claimWait)
            : block.timestamp;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwners
    {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            if (!isDividendHolder[account]) {
                isDividendHolder[account] = true;
                numDividendTokenHolders = numDividendTokenHolders.add(1);
            }
        } else {
            _setBalance(account, 0);
            if (isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
    }

    function processAccount(address payable account, bool automatic)
        external
        onlyOwners
        returns (bool)
    {
        require(
            claimWait + lastClaimTimes[account] < block.timestamp,
            "Viral_Dividend_Tracker: please wait for another claim"
        );
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }
}