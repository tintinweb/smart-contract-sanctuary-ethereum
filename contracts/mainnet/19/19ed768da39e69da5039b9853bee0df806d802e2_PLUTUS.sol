// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./DividendTracker.sol";

contract PLUTUS is Ownable, IERC20 {
    address UNISWAPROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string private _name = "PLUTUS CAPITAL HOLDINGS";
    string private _symbol = "PCH";

    // Allocations
    uint256 public _tokenomicsTokenAllocation;
    uint256 public _liquidityTokenAllocation;
    uint256 public _dividendsTokenAllocation;

    // Fess
    uint256 public tokenomicsFeeBuyBPS = 600;
    uint256 public liquidityFeeBuyBPS = 100;
    uint256 public dividendFeeBuyBPS = 300;
    uint256 public tokenomicsFeeSellBPS = 1900;
    uint256 public liquidityFeeSellBPS = 100;
    uint256 public dividendFeeSellBPS = 0;
    uint256 public totalFeeBPS =
        tokenomicsFeeBuyBPS +
            liquidityFeeBuyBPS +
            dividendFeeBuyBPS;

    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool public compoundingEnabled = true;

    uint256 private _totalSupply = 1000000000 * (10**18);
    bool private swapping;

    address payable public tokenomicsWallet =
        payable(0x20308B8986D45A1EB50757e03f4DdDD15b22FB0F);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) isBlacklisted;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    event SwapAndAddLiquidity(
        uint256 tokensSwapped,
        uint256 nativeReceived,
        uint256 tokensIntoLiquidity
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event CompoundingEnabled(bool enabled);
    event BlacklistEnabled(bool enabled);

    DividendTracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    uint256 public maxTxBPS = 50;
    uint256 public maxWalletBPS = 200;

    uint256 tradingOpenDate = 1649279774;

    constructor() {
        dividendTracker = new DividendTracker(address(this), UNISWAPROUTER);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _balances[_msgSender()] += _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "PLUTUS: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "PLUTUS: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function setParametersToLaunch() external onlyOwner {
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(uniswapV2Router), true);
        dividendTracker.excludeFromDividends(address(DEAD), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);
    }

    function setTradingOpenDate(uint256 timestamp) external onlyOwner {
        tradingOpenDate = timestamp;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            tradingOpenDate < block.timestamp ||
                sender == owner() ||
                recipient == owner() ||
                _whiteList[sender] ||
                _whiteList[recipient],
            "PLUTUS: Token isn't tradable yet"
        );

        require(!isBlacklisted[sender], "PLUTUS: Sender is blacklisted");
        require(!isBlacklisted[recipient], "PLUTUS: Recipient is blacklisted");

        require(sender != address(0), "PLUTUS: transfer from the zero address");
        require(
            recipient != address(0),
            "PLUTUS: transfer to the zero address"
        );

        uint256 _maxTxAmount = (totalSupply() * maxTxBPS) / 10000;
        uint256 _maxWallet = (totalSupply() * maxWalletBPS) / 10000;
        require(
            amount <= _maxTxAmount || _isExcludedFromMaxTx[sender],
            "TX Limit Exceeded"
        );

        if (
            sender != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(recipient);
            require(
                _isExcludedFromMaxWallet[recipient] ||
                    (currentBalance + amount <= _maxWallet)
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "PLUTUS: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled &&
            canSwap &&
            !swapping &&
            sender != address(uniswapV2Router) &&
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (!swapAllToken && contractTokenBalance > swapTokensAtAmount) {
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance, contractNativeBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee = false;

        if (
            (sender == address(uniswapV2Pair) &&
                recipient != address(uniswapV2Router)) ||
            (recipient == address(uniswapV2Pair) &&
                sender != address(uniswapV2Router))
        ) {
            takeFee = true;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (swapping || !taxEnabled) {
            takeFee = false;
        }

        if (takeFee) {
            //Set Fee for Buys
            if (sender == uniswapV2Pair) {
                totalFeeBPS =
                    tokenomicsFeeBuyBPS +
                    liquidityFeeBuyBPS +
                    dividendFeeBuyBPS;

                _tokenomicsTokenAllocation =
                    (amount * tokenomicsFeeBuyBPS) /
                    totalFeeBPS;
                _liquidityTokenAllocation =
                    (amount * liquidityFeeBuyBPS) /
                    totalFeeBPS;
                _dividendsTokenAllocation =
                    (amount * dividendFeeBuyBPS) /
                    totalFeeBPS;
            }

            //Set Fee for Sells
            if (recipient == uniswapV2Pair) {
                totalFeeBPS =
                    tokenomicsFeeSellBPS +
                    liquidityFeeSellBPS +
                    dividendFeeSellBPS;

                _tokenomicsTokenAllocation =
                    (amount * tokenomicsFeeSellBPS) /
                    totalFeeBPS;
                _liquidityTokenAllocation =
                    (amount * liquidityFeeSellBPS) /
                    totalFeeBPS;
                _dividendsTokenAllocation =
                    (amount * dividendFeeSellBPS) /
                    totalFeeBPS;
            }

            uint256 fees = (amount * totalFeeBPS) / 10000;
            amount -= fees;
            _executeTransfer(sender, address(this), fees);
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(payable(sender), balanceOf(sender));
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function _executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "PLUTUS: transfer from the zero address");
        require(
            recipient != address(0),
            "PLUTUS: transfer to the zero address"
        );
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "PLUTUS: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "PLUTUS: approve from the zero address");
        require(spender != address(0), "PLUTUS: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 native) private {
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            address(this),
            block.timestamp
        );
    }

    function includeToWhiteList(address[] memory _users) public onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function _executeSwap(uint256 tokens, uint256 native) private {
        if (tokens <= 0) {
            return;
        }

        uint256 totalAllocation = _tokenomicsTokenAllocation +
            _liquidityTokenAllocation +
            _dividendsTokenAllocation;

        // Calculations below might seem redundant, but we need them in case tokens < contract token balance
        uint256 tokensForTokenomics;
        if (address(tokenomicsWallet) != address(0)) {
            tokensForTokenomics =
                (tokens * _tokenomicsTokenAllocation) /
                totalAllocation;
        }

        uint256 tokensForDividends;
        if (dividendTracker.totalSupply() > 0) {
            tokensForDividends =
                (tokens * _dividendsTokenAllocation) /
                totalAllocation;
        }

        uint256 tokensForLiquidity = tokens -
            tokensForTokenomics-
            tokensForDividends;
        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = tokensForTokenomics +
            tokensForDividends +
            swapTokensLiquidity;

        uint256 initNativeBal = address(this).balance;
        swapTokensForNative(swapTokensTotal);
        uint256 nativeSwapped = (address(this).balance - initNativeBal) +
            native;

        uint256 nativeTokenomics = (nativeSwapped * tokensForTokenomics) /
            swapTokensTotal;
        uint256 nativeDividends = (nativeSwapped * tokensForDividends) /
            swapTokensTotal;
        uint256 nativeLiquidity = nativeSwapped -
            nativeTokenomics -
            nativeDividends;

        // Send tokens to treasury
        if (nativeTokenomics > 0) {
            (bool success, ) = tokenomicsWallet.call{value: nativeTokenomics}("");
            require(success, "PLUTUS: Tx failed.");
        }

        // Add liquidity
        addLiquidity(addTokensLiquidity, nativeLiquidity);
        emit SwapAndAddLiquidity(
            swapTokensLiquidity,
            nativeLiquidity,
            addTokensLiquidity
        );

        // Send redis to dividend tracker
        if (nativeDividends > 0) {
            (bool success, ) = address(dividendTracker).call{
                value: nativeDividends
            }("");
            if (success) {
                emit SendDividends(tokensForDividends, nativeDividends);
            }
        }

        _tokenomicsTokenAllocation = 0;
        _liquidityTokenAllocation = 0;
        _dividendsTokenAllocation = 0;
    }

    function manualSwapAndSend() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        if (!swapAllToken && contractTokenBalance > swapTokensAtAmount) {
            contractTokenBalance = swapTokensAtAmount;
        }
        _executeSwap(contractTokenBalance, contractNativeBalance);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "PLUTUS: account is already set to requested state"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function manualSendDividend(uint256 amount, address holder)
        external
        onlyOwner
    {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function excludeFromDividends(address account, bool excluded)
        public
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setWallets(
        address payable _tokenomicsWallet
    ) external onlyOwner {
        tokenomicsWallet = _tokenomicsWallet;
    }

    function setFee(
        uint256 _tokenomicsFeeBuy,
        uint256 _liquidityFeeBuy,
        uint256 _dividendFeeBuy,
        uint256 _tokenomicsFeeSell,
        uint256 _liquidityFeeSell,
        uint256 _dividendFeeSell
    ) external onlyOwner {
        tokenomicsFeeBuyBPS = _tokenomicsFeeBuy;
        liquidityFeeBuyBPS = _liquidityFeeBuy;
        dividendFeeBuyBPS = _dividendFeeBuy;
        tokenomicsFeeSellBPS = _tokenomicsFeeSell;
        liquidityFeeSellBPS = _liquidityFeeSell;
        dividendFeeSellBPS = _dividendFeeSell;

        totalFeeBPS =
            _tokenomicsFeeBuy +
            _liquidityFeeBuy +
            _dividendFeeBuy;
    }

    function claim() public {
        dividendTracker.processAccount(payable(_msgSender()));
    }

    function compound() public {
        require(compoundingEnabled, "PLUTUS: compounding is not enabled");
        dividendTracker.compoundAccount(payable(_msgSender()));
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function withdrawnDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawnDividendOf(account);
    }

    function accumulativeDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function getAccountInfo(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountInfo(account);
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setCompoundingEnabled(bool _enabled) external onlyOwner {
        compoundingEnabled = _enabled;
        emit CompoundingEnabled(_enabled);
    }

    function updateDividendSettings(
        bool _swapEnabled,
        uint256 _swapTokensAtAmount,
        bool _swapAllToken
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner {
        maxTxBPS = bps;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner {
        maxWalletBPS = bps;
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function blackList(address _user, bool blacklist) public onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = blacklist;
    }

    function blackListMany(address[] memory _users) public onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
        }
    }

    receive() external payable {}
}