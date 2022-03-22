/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/** 

██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗     ██╗███╗   ██╗██╗   ██╗
██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    ██║████╗  ██║██║   ██║
███████║███████║██║     █████╔╝ █████╗  ██████╔╝    ██║██╔██╗ ██║██║   ██║
██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗    ██║██║╚██╗██║██║   ██║
██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║    ██║██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝ ╚═════╝   Token v2.0.0                

Telegram: https://t.me/HackerINUPortal
Twitter: https://twitter.com/hacker_inu
Website: https://hackerinu.io

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
}

interface IUniswapV2Factory {
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

contract HackerInu is Context, IERC20, Ownable {
    string private constant _name = "HACKER INU v2";
    string private constant _symbol = "HCKR";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _totalSupply = 10000000 * 10**9;

    //Buy Fee
    uint256 private _liquidityFeeOnBuy = 0;
    uint256 private _treasuryFeeOnBuy = 700;
    uint256 private _devFeeOnBuy = 300;

    //Sell Fee
    uint256 private _liquidityFeeOnSell = 0;
    uint256 private _treasuryFeeOnSell = 1300;
    uint256 private _devFeeOnSell = 600;

    //Original Fee
    uint256 private _taxFee =
        _liquidityFeeOnSell + _treasuryFeeOnSell + _devFeeOnSell;

    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public blacklist;

    address payable public _treasuryAddress =
        payable(0x04291298CE0050CFF34EA882D3dfE9a7Facaa2a6);
    address payable public _devAddress =
        payable(0x8cC5e6a4fD3Ab66F6c7781Be9482d6d7193E5891);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 private _tradingOpenDate;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount = 30000 * 10**9; // 0.3%
    uint256 public _maxWalletSize = 1000000 * 10**9; // 10%
    uint256 public _tokenSwapThreshold = 1000 * 10**9; //0.1%

    // Cooldown
    uint256 public cooldownTimeBound = 120 seconds;
    bool public cooldownEnabled = true;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_treasuryAddress] = true;
        _isExcludedFromFee[_devAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
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

    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previoustaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previoustaxFee;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    // Transfer functions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "TOKEN: Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(!cooldownEnabled || (cooldown[from] < block.timestamp && cooldown[to] < block.timestamp), "TOKEN: Cooldown is enabled. Try again in a few minutes.");
            require(
                _tradingOpenDate < block.timestamp,
                "TOKEN: This account cannot send or receive tokens until trading is enabled"
            );
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(
                !blacklist[from] && !blacklist[to],
                "TOKEN: Your account is blacklisted!"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
                cooldown[to] = block.timestamp + cooldownTimeBound;
            }

            if(from != uniswapV2Pair) {
                cooldown[from] = block.timestamp + cooldownTimeBound;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool shouldSwap = contractTokenBalance >= _tokenSwapThreshold;

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }

            if (shouldSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapAndLiquidy(contractTokenBalance);
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _liquidityFeeOnBuy + _treasuryFeeOnBuy + _devFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee =
                    _liquidityFeeOnSell +
                    _treasuryFeeOnSell +
                    _devFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 feeAmount = (amount * _taxFee) / 10000;
        uint256 remainingAmount = amount - feeAmount;
        _balances[sender] = _balances[sender] - amount;
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        _balances[recipient] = _balances[recipient] + remainingAmount;
        emit Transfer(sender, recipient, remainingAmount);
    }

    // Swap and send functions
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    // Add liquidity function
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquidy(uint256 amount) private {
        // Split the contract balance into halves
        uint256 denominator = (_liquidityFeeOnBuy +
            _liquidityFeeOnSell +
            _treasuryFeeOnBuy +
            _treasuryFeeOnSell +
            _devFeeOnBuy +
            _devFeeOnSell) * 2;
        uint256 tokensToAddLiquidityWith = (amount *
            (_liquidityFeeOnBuy + _liquidityFeeOnSell)) / denominator;
        uint256 toSwap = amount - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance /
            (denominator - (_liquidityFeeOnBuy + _liquidityFeeOnSell));
        uint256 ethToAddLiquidityWith = unitBalance *
            (_liquidityFeeOnBuy + _liquidityFeeOnSell);

        if (ethToAddLiquidityWith > 0) {
            // Add liquidity to uniswap
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        // Send remaining ETH
        uint256 treasuryAmt = unitBalance *
            2 *
            (_treasuryFeeOnBuy + _treasuryFeeOnSell);
        uint256 devAmt = unitBalance * 2 * (_devFeeOnBuy + _devFeeOnSell) >
            address(this).balance
            ? address(this).balance
            : unitBalance * 2 * (_devFeeOnBuy + _devFeeOnSell);

        if (treasuryAmt > 0) {
            (bool successtreasury, ) = _treasuryAddress.call{
                value: treasuryAmt
            }("");
            require(successtreasury, "Tx Failed");
        }

        if (devAmt > 0) {
            (bool successdev, ) = _devAddress.call{value: devAmt}("");
            require(successdev, "Tx Failed");
        }
    }

    function manualSwapAndLiquify() external {
        require(_msgSender() == _devAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapAndLiquidy(contractBalance);
    }

    function blacklistAddresses(address[] memory _blacklist) public onlyOwner {
        for (uint256 i = 0; i < _blacklist.length; i++) {
            blacklist[_blacklist[i]] = true;
        }
    }

    function whitelistAddress(address whitelist) external onlyOwner {
        blacklist[whitelist] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function setLaunchDate(uint32 delay) public onlyOwner {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        _tradingOpenDate = delay + blockTimestamp + (blockTimestamp % 60);
    }

    function setCooldownTimeBound(uint256 timeInSeconds) external onlyOwner {
        cooldownTimeBound = timeInSeconds;
    }

    function setEnableCooldown(bool enable) external onlyOwner {
        cooldownEnabled = enable;
    }

    function setTreasuryWalletAddress(address payable newAddress)
        external
        onlyOwner
    {
        _treasuryAddress = newAddress;
    }

    function setDevWalletAddress(address payable newAddress)
        external
        onlyOwner
    {
        _devAddress = newAddress;
    }

    function setFee(
        uint256 liquidityFeeOnBuy,
        uint256 liquidityFeeOnSell,
        uint256 treasuryFeeOnBuy,
        uint256 treasuryFeeOnSell,
        uint256 devFeeOnBuy,
        uint256 devFeeOnSell
    ) public onlyOwner {
        _liquidityFeeOnBuy = liquidityFeeOnBuy;
        _liquidityFeeOnSell = liquidityFeeOnSell;
        _treasuryFeeOnBuy = treasuryFeeOnBuy;
        _treasuryFeeOnSell = treasuryFeeOnSell;
        _devFeeOnBuy = devFeeOnBuy;
        _devFeeOnSell = devFeeOnSell;
    }

    function setMinSwapTokensThreshold(uint256 tokenSwapThreshold)
        public
        onlyOwner
    {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    // Enable the current contract to receive ETH
    receive() external payable {}
}