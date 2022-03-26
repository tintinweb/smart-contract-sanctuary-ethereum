/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract Ownable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

library SignedSafeMath {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount,
        address received
    );
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

abstract contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
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
        _withdrawDividendOfUser(payable(msg.sender), payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user, address payable to)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success, ) = to.call{value: _withdrawableDividend}("");

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
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
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

    function getAccount(address _account)
        public
        view
        returns (uint256 _withdrawableDividends, uint256 _withdrawnDividends)
    {
        _withdrawableDividends = withdrawableDividendOf(_account);
        _withdrawnDividends = withdrawnDividends[_account];
    }
}

contract DiamondDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenHoldersCount;
    mapping(address => bool) private tokenHoldersMap;

    mapping(address => bool) public excludedFromDividends;

    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);

    constructor()
        DividendPayingToken(
            "Diamond_Dividend_Tracker",
            "Diamond_Dividend_Tracker"
        )
    {
        minimumTokenBalanceForDividends = 10000 * 10**18;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Diamond_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Diamond_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "Diamond_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Diamond contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);

        if (tokenHoldersMap[account] == true) {
            tokenHoldersMap[account] = false;
            tokenHoldersCount.decrement();
        }

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account, uint256 balance)
        external
        onlyOwner
    {
        excludedFromDividends[account] = false;

        if (balance >= minimumTokenBalanceForDividends) {
            _setBalance(account, balance);

            if (tokenHoldersMap[account] == false) {
                tokenHoldersMap[account] = true;
                tokenHoldersCount.increment();
            }
        }

        emit ExcludeFromDividends(account);
    }

    function isExcludeFromDividends(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return excludedFromDividends[account];
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersCount.current();
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);

            if (tokenHoldersMap[account] == false) {
                tokenHoldersMap[account] = true;
                tokenHoldersCount.increment();
            }
        } else {
            _setBalance(account, 0);

            if (tokenHoldersMap[account] == true) {
                tokenHoldersMap[account] = false;
                tokenHoldersCount.decrement();
            }
        }
    }

    function processAccount(address account, address toAccount)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 amount = _withdrawDividendOfUser(
            payable(account),
            payable(toAccount)
        );
        return amount;
    }
}

contract Diamond is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant _name = "Diamond";
    string private constant _symbol = "DIAMONDS";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool private tradingOpen = false;
    uint256 private launchBlock = 0;
    address private uniswapV2Pair;

    IERC20 private MyBagsInstance;
    uint256 private minimumMyBagsToken = 1e8 * 10**18;
    uint256 private privateSaleTimestamp;
    uint256 private publicSaleTimestamp;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) public isBot;

    uint256 private walletLimitPercentage = 50;
    mapping(address => bool) public isExludeFromWalletLimit;

    uint256 private baseBuyTax = 10;
    uint256 public baseSellTax = 5;
    uint256 public sellPercentageOfHolding = 20;
    uint256 public minutesIntervalPerSell = 7200 minutes;
    mapping(address => uint256) public initialSellTimestamp;

    uint256 private autoLP = 27;
    uint256 private devFee = 40;
    uint256 private marketingFee = 33;

    uint256 public minContractTokensToSwap = 2e9 * 10**18;
    bool public swapAll = false;

    struct MinutesRangeTax {
        uint256 from;
        uint256 to;
        uint256 tax;
    }

    mapping(address => uint256) public initialBuyTimestamp;
    mapping(uint8 => MinutesRangeTax) public minutesRangeTaxes;
    uint8 public maxIndexMinutesRange;

    address private devWalletAddress;
    address private marketingWalletAddress;

    DiamondDividendTracker public dividendTracker;
    uint256 minimumTokenBalanceForDividends = 10000 * 10**18;
    mapping(address => uint256) public lastTransfer;

    uint256 public pendingTokensForReward;
    uint256 public minRewardTokensToSwap = 10000 * 10**18;

    uint256 public pendingEthReward;

    struct ClaimedEth {
        uint256 ethAmount;
        uint256 tokenAmount;
        uint256 timestamp;
    }

    Counters.Counter private claimedHistoryIds;

    mapping(uint256 => ClaimedEth) private claimedEthMap;
    mapping(address => uint256[]) private userClaimedIds;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 devEth, uint256 remarketingEth);
    event AddRewardPool(uint256 _ethAmount);

    event SendDividends(uint256 amount);

    event DividendClaimed(
        uint256 ethAmount,
        uint256 tokenAmount,
        address account
    );

    constructor(
        address _devWalletAddress,
        address _marketingWalletAddress,
        address _myBagsTokenAddress
    ) ERC20(_name, _symbol) {
        devWalletAddress = _devWalletAddress;
        marketingWalletAddress = _marketingWalletAddress;

        MyBagsInstance = IERC20(_myBagsTokenAddress);

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExludeFromWalletLimit[owner()] = true;
        isExludeFromWalletLimit[address(this)] = true;
        isExludeFromWalletLimit[address(uniswapV2Router)] = true;

        dividendTracker = new DiamondDividendTracker();
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
        minutesRangeTaxes[1].from = 0 minutes;
        minutesRangeTaxes[1].to = 7200 minutes;
        minutesRangeTaxes[1].tax = 30;
        minutesRangeTaxes[2].from = 7200 minutes;
        minutesRangeTaxes[2].to = 14400 minutes;
        minutesRangeTaxes[2].tax = 25;
        minutesRangeTaxes[3].from = 14400 minutes;
        minutesRangeTaxes[3].to = 21600 minutes;
        minutesRangeTaxes[3].tax = 20;
        minutesRangeTaxes[4].from = 21600 minutes;
        minutesRangeTaxes[4].to = 28800 minutes;
        minutesRangeTaxes[4].tax = 15;

        maxIndexMinutesRange = 4;

        _mint(owner(), _tTotal);
    }

    function openTrading(uint256 _launchTime, uint256 _minutesForPrivateSale)
        external
        onlyOwner
    {
        require(!tradingOpen, "Diamond: Trading is already open");
        require(_launchTime > block.timestamp, "Diamond: Invalid timestamp");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        dividendTracker.excludeFromDividends(uniswapV2Pair);

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        privateSaleTimestamp = _launchTime;
        publicSaleTimestamp = _launchTime.add(
            _minutesForPrivateSale.mul(1 minutes)
        );
        launchBlock = block.number;
    }

    function manualSwap() external onlyOwner {
        uint256 totalTokens = balanceOf(address(this)).sub(
            pendingTokensForReward
        );

        swapTokensForEth(totalTokens);
    }

    function manualSend() external onlyOwner {
        uint256 totalEth = address(this).balance.sub(pendingEthReward);

        uint256 devFeesToSend = totalEth.mul(devFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 remainingEthForFees = totalEth.sub(devFeesToSend).sub(
            marketingFeesToSend
        );
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, marketingFeesToSend);
    }

    function getTax(address _ad) public view returns (uint256) {
        uint256 tax = baseSellTax;

        for (uint8 x = 1; x <= maxIndexMinutesRange; x++) {
            if (
                (initialBuyTimestamp[_ad] + minutesRangeTaxes[x].from <=
                    block.timestamp &&
                    initialBuyTimestamp[_ad] + minutesRangeTaxes[x].to >=
                    block.timestamp)
            ) {
                tax = minutesRangeTaxes[x].tax;
                return tax;
            }
        }

        return tax;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address _account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(_account);
    }

    function dividendTokenBalanceOf(address _account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(_account);
    }

    function claim() external {
        _claim(payable(msg.sender), false);
    }

    function reinvest() external {
        _claim(payable(msg.sender), true);
    }

    function _claim(address payable _account, bool _reinvest) private {
        uint256 withdrawableAmount = dividendTracker.withdrawableDividendOf(
            _account
        );
        require(
            withdrawableAmount > 0,
            "Diamond: Claimer has no withdrawable dividend"
        );
        uint256 ethAmount;
        uint256 tokenAmount;

        if (!_reinvest) {
            ethAmount = dividendTracker.processAccount(_account, _account);
        } else {
            ethAmount = dividendTracker.processAccount(_account, address(this));
            if (ethAmount > 0) {
                tokenAmount = swapEthForTokens(ethAmount, _account);
            }
        }
        if (ethAmount > 0) {
            claimedHistoryIds.increment();
            uint256 hId = claimedHistoryIds.current();
            claimedEthMap[hId].ethAmount = ethAmount;
            claimedEthMap[hId].tokenAmount = tokenAmount;
            claimedEthMap[hId].timestamp = block.timestamp;

            userClaimedIds[_account].push(hId);

            emit DividendClaimed(ethAmount, tokenAmount, _account);
        }
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getAccount(address _account)
        public
        view
        returns (
            uint256 withdrawableDividends,
            uint256 withdrawnDividends,
            uint256 balance
        )
    {
        (withdrawableDividends, withdrawnDividends) = dividendTracker
            .getAccount(_account);
        return (withdrawableDividends, withdrawnDividends, balanceOf(_account));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);

        uint256 transferAmount = _amount;
        uint256 prevWalletLimit = walletLimitPercentage;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
            require(
                privateSaleTimestamp <= block.timestamp,
                "Diamond: Private and public sale is not open"
            );
            if (
                privateSaleTimestamp <= block.timestamp &&
                publicSaleTimestamp > block.timestamp
            ) {
                walletLimitPercentage = 10;
                require(
                    MyBagsInstance.balanceOf(_to) >= minimumMyBagsToken,
                    "Diamond: Not enough $MyBagsToken"
                );
            }
            transferAmount = takeFees(_from, _to, _amount);
        }
        if (initialBuyTimestamp[_to] == 0) {
            initialBuyTimestamp[_to] = block.timestamp;
        }
        if (!automatedMarketMakerPairs[_to] && !isExludeFromWalletLimit[_to]) {
            uint256 addressBalance = balanceOf(_to).add(transferAmount);
            require(
                addressBalance <=
                    totalSupply().mul(walletLimitPercentage).div(10000),
                "Diamond: Wallet balance limit reached"
            );
        }

        super._transfer(_from, _to, transferAmount);
        walletLimitPercentage = prevWalletLimit;
        if (!dividendTracker.isExcludeFromDividends(_from)) {
            try
                dividendTracker.setBalance(payable(_from), balanceOf(_from))
            {} catch {}
        }
        if (!dividendTracker.isExcludeFromDividends(_to)) {
            try
                dividendTracker.setBalance(payable(_to), balanceOf(_to))
            {} catch {}
        }
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "Diamond: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            dividendTracker.excludeFromDividends(_pair);
        }
    }

    function setMinimumMyBagsToken(uint256 _minimumMyBagsToken)
        external
        onlyOwner
    {
        minimumMyBagsToken = _minimumMyBagsToken;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external
        onlyOwner
    {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExludeFromDividends(
        address _address,
        bool _isExludeFromDividends
    ) external onlyOwner {
        if (_isExludeFromDividends) {
            dividendTracker.excludeFromDividends(_address);
        } else {
            dividendTracker.includeFromDividends(_address, balanceOf(_address));
        }
    }

    function setExludeFromWalletLimit(
        address _address,
        bool _isExludeFromWalletLimit
    ) external onlyOwner {
        isExludeFromWalletLimit[_address] = _isExludeFromWalletLimit;
    }

    function setWalletLimitPercentage(uint256 _percentage) external onlyOwner {
        walletLimitPercentage = _percentage;
    }

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _baseSellTax,
        uint256 _autoLP,
        uint256 _devFee,
        uint256 _marketingFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && baseSellTax <= 5);

        baseBuyTax = _baseBuyTax;
        baseSellTax = _baseSellTax;
        autoLP = _autoLP;
        devFee = _devFee;
        marketingFee = _marketingFee;
    }

    function setMinContractTokensToSwap(uint256 _numToken) public onlyOwner {
        minContractTokensToSwap = _numToken;
    }

    function setMinRewardTokensToSwap(uint256 _numToken) public onlyOwner {
        minRewardTokensToSwap = _numToken;
    }

    function setSwapAll(bool _isWapAll) public onlyOwner {
        swapAll = _isWapAll;
    }

    function setMinutesRangeTax(
        uint8 _index,
        uint256 _from,
        uint256 _to,
        uint256 _tax
    ) external onlyOwner {
        minutesRangeTaxes[_index].from = _from.mul(1 minutes);
        minutesRangeTaxes[_index].to = _to.mul(1 minutes);
        minutesRangeTaxes[_index].tax = _tax;
    }

    function setMaxIndexMinutesRange(uint8 _maxIndex) external onlyOwner {
        maxIndexMinutesRange = _maxIndex;
    }

    function setPercentageOfHolding(
        uint256 _sellPercentageOfHolding,
        uint256 _minutesIntervalPerSell
    ) external onlyOwner {
        sellPercentageOfHolding = _sellPercentageOfHolding;
        minutesIntervalPerSell = _minutesIntervalPerSell.mul(1 minutes);
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _devWallet, address _marketingWallet)
        external
        onlyOwner
    {
        devWalletAddress = _devWallet;
        marketingWalletAddress = _marketingWallet;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "Diamond: No market makers found"
        );

        if (automatedMarketMakerPairs[_from]) {
            fees = _amount.mul(baseBuyTax).div(100);
            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            emit BuyFees(_from, address(this), fees);
        } else {
            uint256 totalSellTax;
            if (isExcludeByInitialSell(_from, _amount)) {
                totalSellTax = baseSellTax;
            } else {
                totalSellTax = getTax(_from);
            }

            fees = _amount.mul(totalSellTax).div(100);
            uint256 rewardTokens = _amount
                .mul(totalSellTax.sub(baseSellTax))
                .div(100);
            pendingTokensForReward = pendingTokensForReward.add(rewardTokens);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            uint256 tokensToSwap = balanceOf(address(this)).sub(
                pendingTokensForReward
            );

            if (tokensToSwap > minContractTokensToSwap) {
                if (!swapAll) {
                    tokensToSwap = minContractTokensToSwap;
                }

                distributeTokensEth(tokensToSwap);
            }
            if (pendingTokensForReward > minRewardTokensToSwap) {
                swapAndSendDividends(pendingTokensForReward);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 devFeesToSend = totalEth.mul(devFee).div(100);
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(devFeesToSend)
            .sub(marketingFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, marketingFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _devFees, uint256 _marketingFees)
        private
    {
        if (_devFees > 0) {
            payable(devWalletAddress).transfer(_devFees);
        }
        if (_marketingFees > 0) {
            payable(marketingWalletAddress).transfer(_marketingFees);
        }
        emit DistributeFees(_devFees, _marketingFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to)
        private
        returns (uint256)
    {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function swapAndSendDividends(uint256 _tokenAmount) private {
        uint256 dividends = swapTokensForEth(_tokenAmount);

        pendingTokensForReward = pendingTokensForReward.sub(_tokenAmount);
        uint256 totalEthToSend = dividends.add(pendingEthReward);

        (bool success, ) = address(dividendTracker).call{value: totalEthToSend}(
            ""
        );

        if (success) {
            emit SendDividends(dividends);
        } else {
            pendingEthReward = pendingEthReward.add(dividends);
        }
    }

    function isExcludeByInitialSell(address _ad, uint256 _tokenAmount)
        private
        returns (bool)
    {
        if (
            initialSellTimestamp[_ad] + minutesIntervalPerSell <=
            block.timestamp
        ) {
            initialSellTimestamp[_ad] = block.timestamp;
            if (
                _tokenAmount <=
                balanceOf(_ad).mul(sellPercentageOfHolding).div(100)
            ) {
                return true;
            }
        }

        return false;
    }

    function availableContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this)).sub(pendingTokensForReward);
    }

    function getHistory(
        address _account,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (ClaimedEth[] memory) {
        require(_limit > 0 && _pageNumber > 0, "Diamond: Invalid arguments");
        uint256 userClaimedCount = userClaimedIds[_account].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < userClaimedCount, "Diamond: Out of range");
        uint256 limit = _limit;
        if (end > userClaimedCount) {
            end = userClaimedCount;
            limit = userClaimedCount % _limit;
        }

        ClaimedEth[] memory myClaimedEth = new ClaimedEth[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 hId = userClaimedIds[_account][i];
            myClaimedEth[currentIndex] = claimedEthMap[hId];
            currentIndex += 1;
        }
        return myClaimedEth;
    }

    function getHistoryCount(address _account) external view returns (uint256) {
        return userClaimedIds[_account].length;
    }

    receive() external payable {}
}