/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

/*
An experienced team brings you Bulldozer $DOZER - the most bullish memecoin of 2022.
http://www.bulldozertoken.com
https://t.me/bulldozertoken
https://twitter.com/bulldozertoken
*/



// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    constructor(address withdrawAddress) {
        _withdrawAddress = withdrawAddress;
    }

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/TimedFee.sol

pragma solidity ^0.8.7;

abstract contract TimedFee {
    uint256 MIN_TIMER = 1 minutes;
    uint256 MAX_TIMER = 6 hours;
    uint256 _nonce = 1;
    mapping(address => uint256) public timers; // when accounts timers are ends

    function setTimer(address account) internal {
        timers[account] = block.timestamp + getTimeInterval();
    }

    function getTimeInterval() private returns (uint256) {
        return MIN_TIMER + (_random() % (MAX_TIMER - MIN_TIMER));
    }

    function getFeeLapsedTime(address account) public view returns (uint256) {
        uint256 timer = timers[account];
        if (block.timestamp >= timer) return 0;
        return timer - block.timestamp;
    }

    function getTimedFee(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (getFeeLapsedTime(account) == 0) return 0;
        return amount / 5; // 20%
    }

    function _random() private returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(msg.sender, _nonce++, block.timestamp)
                )
            );
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

// File: contracts/DoubleSwapped.sol

pragma solidity ^0.8.7;


contract DoubleSwapped {
    bool internal _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        IUniswapV2Router02 _uniswapV2Router
    ) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function _swapTokensForEthOnTransfer(
        uint256 transferAmount,
        uint256 swapCount,
        IUniswapV2Router02 _uniswapV2Router
    ) internal {
        if (swapCount == 0) return;
        uint256 maxSwapCount = 2 * transferAmount;
        if (swapCount > maxSwapCount) swapCount = maxSwapCount;
        _swapTokensForEth(swapCount, _uniswapV2Router);
    }
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
    uint256 internal _totalSupply = 1e13;
    string _name;
    string _symbol;
    uint8 constant _decimals = 0;
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
    uint256 constant startMaxBuyPercentil = 2; // maximum buy on start 1000=100%
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 constant maxIncrements = 998; // maximum time incrementations
    uint256 maxBuyIncrementValue; // value for increment maxBuy

    function startMaxWalletDynamic(uint256 totalSupply) internal {
        startTime = block.timestamp;
        startMaxWallet = (totalSupply * startMaxBuyPercentil) / 1000;
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

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;








abstract contract TradableErc20 is
    ERC20,
    TimedFee,
    DoubleSwapped,
    Ownable,
    MaxWalletDynamic
{
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
        require(_balances[from] >= amount, "not enough token for transfer");
        require(to != address(0), "incorrect address");

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable, "trading disabled");
            // get taxes
            amount = _getFeeBuy(from, to, amount);
            // check max wallet
            checkMaxWallet(_balances[to] + amount);
            // timer
            setTimer(to);
        }
        // sell
        else if (
            !_inSwap &&
            uniswapV2Pair != address(0) &&
            to == uniswapV2Pair &&
            !_isExcludedFromFee[from]
        ) {
            require(tradingEnable, "trading disabled");
            // fee
            amount = _getFeeSell(from, amount);
        }
        // transfer from wallet to wallet
        else {
            if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                // get taxes
                amount = _getFeeTransfer(from, amount);
                // check max wallet
                checkMaxWallet(_balances[to] + amount);
                // swap tokens
                _swapTokensForEthOnTransfer(
                    amount,
                    _balances[address(this)],
                    _uniswapV2Router
                );
                // timer
                setTimer(to);
            }
        }

        // transfer
        super._transfer(from, to, amount);
        if (to == address(BURN_ADDRESS)) _totalSupply -= amount;
    }

    function getBFee(uint256 amount) private view returns (uint256) {
        uint256 onePercent = _totalSupply / 100;
        if (amount >= onePercent) return amount / 5; // if more 1% of total then fee 20%
        return (amount * amount) / (5 * onePercent);
    }

    function getCFee(uint256 walletSize, uint256 amount)
        private
        view
        returns (uint256)
    {
        uint256 onePercent = _totalSupply / 100;
        if (walletSize >= onePercent) return amount / 20; // if more 1% of liquidity then fee 5%
        return (amount * walletSize) / (20 * onePercent);
    }

    function getIFee(uint256 amount) private view returns (uint256) {
        uint256 count = (_balances[uniswapV2Pair]) / 12; // 8.33% i.e. 30% fee is for 5% liquidity
        if (amount >= count) return amount / 2; // if more 8.33% of liquidity then fee 50%
        return (amount * amount) / (2 * count);
    }

    function getFeeBuy(address account, uint256 amount)
        private
        view
        returns (uint256)
    {
        uint256 a = amount / 20; // 5%
        uint256 b = getBFee(amount);
        uint256 c = getCFee(_balances[account] + amount, amount);
        return a + b + c;
    }

    function getFeeSell(address account, uint256 amount)
        private
        view
        returns (uint256)
    {
        uint256 a = amount / 20; // 5%
        uint256 c = getCFee(_balances[account], amount);
        return a + c + getTimedFee(account, amount);
    }

    function getFeeTransfer(address account, uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (amount * 3) / 20; // 15%
    }

    function _getFeeBuy(
        address pair,
        address to,
        uint256 amount
    ) private returns (uint256) {
        return _arrangeFee(pair, amount, getFeeBuy(to, amount));
    }

    function _getFeeSell(address from, uint256 amount)
        private
        returns (uint256)
    {
        return _arrangeFee(from, amount, getFeeSell(from, amount));
    }

    function _getFeeTransfer(address from, uint256 amount)
        private
        returns (uint256)
    {
        return _arrangeFee(from, amount, getFeeTransfer(from, amount));
    }

    function _arrangeFee(
        address from,
        uint256 amount,
        uint256 fee
    ) private returns (uint256) {
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

// File: contracts/Bulldozer.sol

pragma solidity ^0.8.7;



contract Bulldozer is TradableErc20, Withdrawable {
    constructor()
        TradableErc20("BULLDOZER", "DOZER")
        Withdrawable(0xe86B3f35eEAcd09b5D1518b5F02cDA24BF3CBe9F)
    {}

    function getSupplyForMakeLiquidity()
        internal
        view
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function withdrawByOwner() external onlyOwner {
        _withdraw();
    }
}