/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// File: contracts/FastSellLimit.sol

pragma solidity ^0.8.7;

abstract contract FastSellLimit {
    mapping(address => uint256) public canSellTimes; // when accounts can sell tokens

    function updateCanSellTime(
        address account,
        uint256 balance,
        uint256 onePercent
    ) internal {
        canSellTimes[account] =
            block.timestamp +
            getTimeInterval(balance, onePercent);
    }

    function checkCanSellTime(address account) internal view {
        require(block.timestamp >= canSellTimes[account], "fast sell limit");
    }

    function getTimeInterval(uint256 balance, uint256 onePercent)
        private
        pure
        returns (uint256)
    {
        if (balance >= onePercent) return 24 hours; // if more 1% of total then fee 20%
        return (24 hours * balance) / onePercent;
    }

    function getLapsedCanSellTime(address account)
        external
        view
        returns (uint256)
    {
        uint256 canSellTime = canSellTimes[account];
        if (block.timestamp >= canSellTime) return 0;
        return canSellTime - block.timestamp;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/IUniswapV2Factory.sol

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// File: contracts/IUniswapV2Router02.sol

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

// File: contracts/IERC20.sol

pragma solidity ^0.8.7;

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
// File: contracts/ERC20.sol

pragma solidity ^0.8.7;


abstract contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 1e21;
    string _name;
    string _symbol;
    uint8 constant _decimals = 9;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal constant INFINITY_ALLOWANCE = 2**256 - 1;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external virtual override view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount);
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        if (currentAllowance == INFINITY_ALLOWANCE) return true;
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}

// File: contracts/MaxWalletDynamic.sol

pragma solidity ^0.8.7;


abstract contract MaxWalletDynamic {
    uint256 startMaxWallet;
    uint256 startTime; // last increment time
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 constant maxIncrements = 9; // maximum time incrementations
    uint256 maxBuyIncrementValue; // value for increment maxBuy

    function startMaxWalletDynamic(uint256 totalSupply) internal {
        startTime = block.timestamp;
        startMaxWallet = totalSupply / 1000;
        maxBuyIncrementValue = (totalSupply * maxBuyIncrementPercentil) / 1000;
    }

    function checkMaxWallet(uint256 walletSize) internal view {
        require(walletSize <= getMaxWallet(), "max wallet limit");
    }

    function getMaxWallet() public view returns (uint256) {
        uint256 incrementCount = (block.timestamp - startTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount >= maxIncrements) incrementCount = maxIncrements;        
        return startMaxWallet + maxBuyIncrementValue * incrementCount;
    }
}

// File: contracts/RewardableErc20.sol

pragma solidity ^0.8.7;



abstract contract RewardableErc20 is ERC20, MaxWalletDynamic {
    uint256 public constant rewardIntervalDays = 5; // reward interval time
    uint256 public rewardInterval; // current reward interwal
    uint256 public rewardIntervalStartRewards; // current reward interwal start rewards
    uint256 public rewardIntervalLapsedRewards; // current reward interwal lapsed rewards
    uint256 public rewardedTotal; // total rewarded
    uint256 rewardIntervalStartTime; // time, when current reward interval starts
    mapping(address => uint256) _lastClaimedReward; // reward interwals by account claims
    uint256 startRewardsAccountsBalance; // all accounts balance on change reward interval

    function tryNextRewardInterval() public {
        if (rewardIntervalLapsedTime() > 0) return;
        _nextRewardInterval();
    }

    function _startRewardIntervals() internal {
        _nextRewardInterval();
    }

    function _nextRewardInterval() internal {
        rewardIntervalStartRewards = _balances[address(this)];
        rewardIntervalLapsedRewards = rewardIntervalStartRewards;
        rewardIntervalStartTime = block.timestamp;
        startRewardsAccountsBalance = getAccountsBalance();
        ++rewardInterval;
    }

    function getRewardForBalanceThisRewardInterval(uint256 balance)
        external
        view
        returns (uint256)
    {
        return
            _getRewardForBalance(
                balance,
                rewardIntervalStartRewards,
                startRewardsAccountsBalance
            );
    }

    function getRewardForBalanceTotal(uint256 balance)
        external
        view
        returns (uint256)
    {
        return
            _getRewardForBalance(
                balance,
                _balances[address(this)],
                getAccountsBalance()
            );
    }

    function _getRewardForBalance(
        uint256 balance,
        uint256 startRewardsCount,
        uint256 startBalanceTotal
    ) public view returns (uint256) {
        // if has no rewards on pool
        if (startBalanceTotal == 0) return 0;
        // get reward
        uint256 reward = (startRewardsCount * balance) /
            startBalanceTotal;
        // max wallet limitation
        uint256 maxWallet = getMaxWallet();
        if (balance + reward > maxWallet) reward = maxWallet - balance;
        // return reward
        return reward;
    }

    /// @dev current available reward for account
    function getRewardCount(address account) external view returns (uint256) {
        if (rewardIntervalLapsedTime() == 0)
            return _getRewardForBalance(
                _balances[account],
                _balances[address(this)],
                getAccountsBalance()
            );
        if (_lastClaimedReward[account] == rewardInterval) return 0;
        return
            _getRewardForBalance(
                _balances[account],
                rewardIntervalStartRewards,
                startRewardsAccountsBalance
            );
    }

    function canClaimReward(address account) external view returns (bool) {
        return rewardIntervalLapsedTime() == 0 || _canClaimReward(account);
    }

    function _canClaimReward(address account) internal view returns (bool) {
        return
            _lastClaimedReward[account] < rewardInterval && rewardInterval != 1;
    }

    function _tryClaimReward(address account) internal {
        tryNextRewardInterval();
        if (!_canClaimReward(account)) return;
        _claimReward(account);
    }

    function claimReward(address account) external {
        tryNextRewardInterval();
        require(_canClaimReward(account), "can not claim reward now");
        _claimReward(account);
    }

    function _claimReward(address account) private {
        _lastClaimedReward[account] = rewardInterval;
        uint256 reward = _getRewardForBalance(
            _balances[account],
            rewardIntervalStartRewards,
            startRewardsAccountsBalance
        );
        uint256 balance = _balances[account];

        if (reward > rewardIntervalLapsedRewards) return;
        _balances[address(this)] -= reward;
        rewardIntervalLapsedRewards -= reward;
        _balances[account] = balance + reward;
        rewardedTotal += reward;
        emit Transfer(address(this), account, reward);
    }

    function rewardIntervalLapsedTime() public view returns (uint256) {
        uint256 nextIntervalTime = rewardIntervalStartTime +
            rewardIntervalDays *
            1 minutes;
        if (block.timestamp >= nextIntervalTime) return 0;
        return nextIntervalTime - block.timestamp;
    }

    function getAccountsBalance() public view virtual returns (uint256);
}

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;






abstract contract TradableErc20 is RewardableErc20, FastSellLimit, Ownable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable = false;
    mapping(address => bool) _isExcludedFromFee;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[BURN_ADDRESS] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[msg.sender] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        _startRewardIntervals();
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uint256 initialLiquidity = getSupplyForMakeLiquidity();
        _balances[address(this)] = initialLiquidity;
        emit Transfer(address(0), address(this), initialLiquidity);
        _allowances[address(this)][
            address(_uniswapV2Router)
        ] = INFINITY_ALLOWANCE;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            initialLiquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        startMaxWalletDynamic(initialLiquidity);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // claim rewards
        if (from != uniswapV2Pair && !_isExcludedFromFee[from])
            _tryClaimReward(from);
        if (to != uniswapV2Pair && !_isExcludedFromFee[to]) _tryClaimReward(to);

        require(_balances[from] >= amount, "not enough token for transfer");
        require(to != address(0), "incorrect address");

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable, "trading disabled");
            // get taxes
            amount = _getFeeBuy(from, amount);
            // check max wallet
            checkMaxWallet(_balances[to] + amount);
        }
        // sell
        else if (
            uniswapV2Pair != address(0) &&
            to == uniswapV2Pair &&
            !_isExcludedFromFee[from]
        ) {
            require(tradingEnable, "trading disabled");
            // can sell timer
            checkCanSellTime(from);
            updateCanSellTime(from, _balances[from], _totalSupply / 100);
            // fee
            amount = _getFeeSell(from, amount);
        }
        // transfer from wallet to wallet
        else {
            if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                // can sell timer
                checkCanSellTime(from);
                updateCanSellTime(from, _balances[from], _totalSupply / 100);
                // get taxes
                amount = _getFeeTransfer(from, amount);
                // check max wallet
                checkMaxWallet(_balances[to] + amount);
            }
        }

        // transfer
        super._transfer(from, to, amount);
        if (to == address(BURN_ADDRESS)) _totalSupply -= amount;
    }

    function getWalletSizeFee(uint256 walletSize, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 onePercent = _balances[uniswapV2Pair] / 100;
        if (walletSize >= onePercent) return amount / 10; // if more 1% of liquidity then fee 10%
        return (amount * walletSize) / (10 * onePercent);
    }

    function getTotalSupplyFee(uint256 amount) public view returns (uint256) {
        uint256 onePercent = _totalSupply / 100;
        if (amount >= onePercent) return amount / 5; // if more 1% of total then fee 20%
        return (amount * amount) / (5 * onePercent);
    }

    function getLiquidityImpactFee(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 count = (_balances[uniswapV2Pair]) / 12; // 8.33% i.e. 30% fee is for 5% liquidity
        if (amount >= count) return amount / 2; // if more 8.33% of liquidity then fee 50%
        return (amount * amount) / (2 * count);
    }

    function _getFeeBuy(address from, uint256 amount)
        private
        returns (uint256)
    {
        uint256 a = amount / 100;
        uint256 b = getTotalSupplyFee(amount);
        uint256 c = getWalletSizeFee(_balances[from] + amount, amount);
        uint256 fee = a + b + c;
        uint256 reward = fee / 2;
        uint256 burn = fee - reward;
        amount -= fee;
        _balances[from] -= fee;
        _balances[address(this)] += reward;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(from, address(this), reward);
        emit Transfer(from, BURN_ADDRESS, burn);
        return amount;
    }

    function _getFeeSell(address account, uint256 amount)
        private
        returns (uint256)
    {
        uint256 c = getWalletSizeFee(_balances[account], amount);
        uint256 i = getLiquidityImpactFee(amount);
        uint256 fee = c + i;
        uint256 reward = fee / 2;
        uint256 burn = fee - reward;
        amount -= fee;
        _balances[account] -= fee;
        _balances[address(this)] += reward;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(account, address(this), reward);
        emit Transfer(account, BURN_ADDRESS, burn);
        return amount;
    }

    function _getFeeTransfer(address from, uint256 amount)
        private
        returns (uint256)
    {
        uint256 fee = getWalletSizeFee(_balances[from] + amount, amount);
        uint256 reward = fee / 2;
        uint256 burn = fee - reward;
        amount -= fee;
        _balances[from] -= fee;
        _balances[address(this)] += reward;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(from, address(this), reward);
        emit Transfer(from, BURN_ADDRESS, burn);
        return amount;
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value) external onlyOwner {
        tradingEnable = value;
    }

    function getSupplyForMakeLiquidity() internal virtual returns (uint256);
}

// File: contracts/ETALON.sol

pragma solidity ^0.8.7;


contract ETALON is TradableErc20 {
    constructor() TradableErc20("Etalon", "ETA") {}

    function getSupplyForMakeLiquidity()
        internal
        view
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    function getAccountsBalance() public view override returns (uint256) {
        return
            _totalSupply - _balances[uniswapV2Pair] - _balances[address(this)];
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        if (_isExcludedFromFee[account] || !this.canClaimReward(account))
            return _balances[account];
        return _balances[account] + this.getRewardCount(account);
    }
}