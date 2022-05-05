/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * SHIBELLA RISES
 *
 * SHIB's lil' sister escaped, and she's fiery!
 *
 * Tax: 3% Swap Burn; 2% Liquidity & Burn; 3% Operations.
 *
 * Telegram: https://t.me/ShibellaPortal
 *
 * Twitter: https://twitter.com/ShibellaToken
 *
 * Website: https://shibella.io/
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);

        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        _approve(owner, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ShibellaInu is Context, ERC20, Ownable {
    // DEX
    IDexRouter public dexRouter;
    address public dexPair;

    // Wallets
    address public operationsWallet;

    // Trade settings
    bool public swapEnabled = false;
    bool public limitsEnabled = false;
    bool private _tradingEnabled = false;

    bool public transferDelayEnabled = true;
    uint256 private _transferDelayBlocks = 2;
    mapping(address => uint256) private _lastTransferBlock;
    
    uint256 private _maxTxAmount;
    uint256 private _maxWalletAmount;
    uint256 public swapTokensAmount;

    // Trade tax
    uint256 public buyBurnFee = 3;
    uint256 public buyLiquidityFee = 2;
    uint256 public buyOperationsFee = 3;
    uint256 public buyTotalFees = buyBurnFee + buyLiquidityFee + buyOperationsFee;

    uint256 public sellBurnFee = 3;
    uint256 public sellLiquidityFee = 2;
    uint256 public sellOperationsFee = 3;
    uint256 public sellTotalFees = sellBurnFee + sellLiquidityFee + sellOperationsFee;

    uint256 private _tokensForBurn = 0;
    uint256 private _tokensForOperations = 0;
    uint256 private _tokensForLiquidity = 0;

    // Fees and max TX exclusions
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTx;

    // Anti-bot
    bool public antiBotEnabled = true;
    mapping(address => bool) private _bots;
    uint256 private _launchTime = 0;
    uint256 private _launchBlock = 0;
    uint256 private _botBlocks = 1;
    uint256 private _botSeconds = 10;
    uint256 public totalBots = 0;

    // Reentrancy
    bool private _isSwapLocked = false;

    modifier lockSwap {
        _isSwapLocked = true;
        _;
        _isSwapLocked = false;
    }

    constructor(address operationsWallet_) payable ERC20("Shibella Inu", "SHIBELLA") {
        require(address(this).balance > 0, "Token: contract currency balance must be above 0");

        // DEX router
        if (block.chainid == 56) {
            dexRouter = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        } else if (block.chainid == 1 || block.chainid == 4) {
            dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert();
        }

        _approve(address(this), address(dexRouter), type(uint256).max);

        // Wallets
        operationsWallet = operationsWallet_;

        // Mint total supply - only called here
        _mint(address(this), 1_425_000 * 1e18);
        _mint(operationsWallet_, 75_000 * 1e18);
    }

    function lightTheFire(uint256 botBlocks_, uint256 botSeconds_, uint256 maxTxAmount_, uint256 maxWalletAmount_, address[] memory botAddresses_) external onlyOwner {
        require(!_tradingEnabled, "Token: trading already enabled");
        require(botBlocks_ >= 0 && botBlocks_ <= 3, "Token: bot blocks must range between 0 and 3");
        require(botSeconds_ >= 10 && botSeconds_ <= 120, "Token: bot seconds must range between 10 and 120");
        require(botAddresses_.length > 0 && botAddresses_.length <= 200, "Token: number of bot addresses cannot be above 200");

        // DEX pair
        dexPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        // Exclude from fees
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
 
        // Exclude from max TX
        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(0xdead), true);
        excludeFromMaxTx(address(dexRouter), true);
        excludeFromMaxTx(dexPair, true);

        // Add liquidity
        dexRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(dexPair).approve(address(dexRouter), type(uint256).max);

        // Anti-bot
        setBots(botAddresses_, true);

        // Trade settings
        setMaxTxAmount(maxTxAmount_);
        setMaxWalletAmount(maxWalletAmount_);
        setSwapTokensAmount(((totalSupply() * 5) / 10000) / 1e18); // 0.05%

        // Launch settings
        _launchTime = block.timestamp;
        _launchBlock = block.number;
        _botBlocks = botBlocks_;
        _botSeconds = botSeconds_;

        swapEnabled = true;
        limitsEnabled = true;
        _tradingEnabled = true;
    }

    function setOperationsWallet(address operationsWallet_) public onlyOwner {
        require(operationsWallet_ != address(0), "Token: operations wallet address invalid");

        if (isExcludedFromFees(operationsWallet)) {
            excludeFromFees(operationsWallet, false);
        }

        if (isExcludedFromMaxTx(operationsWallet)) {
            excludeFromMaxTx(operationsWallet, false);
        }

        operationsWallet = operationsWallet_;

        excludeFromFees(operationsWallet_, true);
        excludeFromMaxTx(operationsWallet_, true);
    }

    function disableLimits() external onlyOwner {
    		require(limitsEnabled, "Token: limits already disabled");

        limitsEnabled = false;
    }

    function disableTransferDelay() external onlyOwner {
        require(transferDelayEnabled, "Token: transfer delay already disabled");

        transferDelayEnabled = false;
    }

    function setMaxTxAmount(uint256 maxTxAmount_) public onlyOwner {
        require(maxTxAmount_ >= (((totalSupply() * 75) / 10000) / 1e18), "Token: max TX amount cannot be below 0.75%");

        _maxTxAmount = maxTxAmount_ * 1e18;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount_) public onlyOwner {
        require(maxWalletAmount_ >= ((totalSupply() / 100) / 1e18), "Token: max wallet amount cannot be below 1%");

        _maxWalletAmount = maxWalletAmount_ * 1e18;
    }

    function setSwapTokensAmount(uint256 swapTokensAmount_) public {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");
        require(swapTokensAmount_ >= (((totalSupply() * 5) / 100000) / 1e18), "Token: swap tokens amount cannot be below 0.005%");
        require(swapTokensAmount_ <= ((totalSupply() / 1000) / 1e18), "Token: swap tokens amount cannot be above 0.1%");

        swapTokensAmount = swapTokensAmount_ * 1e18;
    }

    function excludeFromFees(address excludeAddress_, bool isExcluded_) public onlyOwner {
        if (isExcluded_) {
            require(excludeAddress_ != address(dexRouter) && excludeAddress_ != dexPair, "Token: excluded from fees address invalid");
        } else {
            require(excludeAddress_ != owner() && excludeAddress_ != address(this) && excludeAddress_ != address(0xdead), "Token: excluded from fees address invalid");
        }

        _isExcludedFromFees[excludeAddress_] = isExcluded_;
    }

    function isExcludedFromFees(address excludeAddress_) public view returns (bool) {
        return _isExcludedFromFees[excludeAddress_];
    }

    function excludeFromMaxTx(address excludeAddress_, bool isExcluded_) public onlyOwner {
        if (!isExcluded_) {
            require(excludeAddress_ != owner() && excludeAddress_ != address(this) && excludeAddress_ != address(0xdead) && excludeAddress_ != address(dexRouter) && excludeAddress_ != dexPair, "Token: excluded from max TX address invalid");
        }

        _isExcludedFromMaxTx[excludeAddress_] = isExcluded_;
    }

    function isExcludedFromMaxTx(address excludeAddress_) public view returns (bool) {
        return _isExcludedFromMaxTx[excludeAddress_];
    }

    function setAntiBotEnabled(bool antiBotEnabled_) external {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");

        antiBotEnabled = antiBotEnabled_;
    }

    function setBots(address[] memory botAddresses_, bool isBlacklisting_) public {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");
        require(botAddresses_.length > 0 && botAddresses_.length <= 200, "Token: number of bot addresses cannot be above 200");

        if (isBlacklisting_ && _tradingEnabled) {
            require(block.timestamp <= (_launchTime + (10 minutes)), "Token: bots can only be blacklisted within the first 10 minutes from launch");
        }

        for (uint256 i = 0; i < botAddresses_.length; i++) {
            if (isBlacklisting_ && (botAddresses_[i] == owner() || botAddresses_[i] == address(this) || botAddresses_[i] == address(0xdead) || botAddresses_[i] == dexPair || botAddresses_[i] == address(dexRouter))) continue;

            if (_bots[botAddresses_[i]] == isBlacklisting_) continue;

            _bots[botAddresses_[i]] = isBlacklisting_;

            if (isBlacklisting_) {
                totalBots++;
            } else {
                totalBots--;
            }
        }
    }

    function isBot(address botAddress_) public view returns (bool) {
        return _bots[botAddress_];
    }

    function setBuyFees(uint256 buyBurnFee_, uint256 buyLiquidityFee_, uint256 buyOperationsFee_) external {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");
        require(buyBurnFee_ >= 0 && buyBurnFee_ <= 6, "Token: buy burn fee must range between 0% and 6%");
        require(buyLiquidityFee_ >= 0 && buyLiquidityFee_ <= 6, "Token: buy liquidity fee must range between 0% and 6%");
        require(buyOperationsFee_ >= 0 && buyOperationsFee_ <= 6, "Token: buy operations fee must range between 0% and 6%");
        require((buyBurnFee_ + buyLiquidityFee_ + buyOperationsFee_) <= 10, "Token: total buy fee must range between 0% and 10%");

        buyBurnFee = buyBurnFee_;
        buyLiquidityFee = buyLiquidityFee_;
        buyOperationsFee = buyOperationsFee_;
        buyTotalFees = buyBurnFee_ + buyLiquidityFee_ + buyOperationsFee_;
    }

    function setSellFees(uint256 sellBurnFee_, uint256 sellLiquidityFee_, uint256 sellOperationsFee_) external {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");
        require(sellBurnFee_ >= 0 && sellBurnFee_ <= 6, "Token: sell burn fee must range between 0% and 6%");
        require(sellLiquidityFee_ >= 0 && sellLiquidityFee_ <= 6, "Token: sell liquidity fee must range between 0% and 6%");
        require(sellOperationsFee_ >= 0 && sellOperationsFee_ <= 6, "Token: sell operations fee must range between 0% and 6%");
        require((sellBurnFee_ + sellLiquidityFee_ + sellOperationsFee_) <= 10, "Token: total sell fee must range between 0% and 10%");

        sellBurnFee = sellBurnFee_;
        sellLiquidityFee = sellLiquidityFee_;
        sellOperationsFee = sellOperationsFee_;
        sellTotalFees = sellBurnFee_ + sellLiquidityFee_ + sellOperationsFee_;
    }

    function forceSwap(uint256 tokensAmount_) external {
        require(_msgSender() == owner() || _msgSender() == operationsWallet, "Token: caller is not authorised");

        uint256 contractTokenBalance = balanceOf(address(this));

        require(contractTokenBalance > 0, "Token: contract token balance must be above zero");
        require(tokensAmount_ <= contractTokenBalance, "Token: swap amount exceeds contract balance");

        _swapTokens(tokensAmount_);
    }

    function withdrawCurrency() external onlyOwner {
        uint256 currencyBalance = address(this).balance;

        require(currencyBalance > 0, "Token: contract currency balance must be above 0");

        (bool success, ) = _msgSender().call{value: currencyBalance}("");
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");

        // Anti-bot
        if (antiBotEnabled) {
            require(!_bots[to] && !_bots[from], "Token: address blacklisted");
        }

        // Trading enabled
        if (!_tradingEnabled) {
            require(isExcludedFromFees(from) || isExcludedFromFees(to), "Token: trading not yet enabled");
        }

        if (limitsEnabled && !_isSwapLocked && from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
            // Blacklist bots
            if ((block.timestamp <= (_launchTime + _botSeconds) || block.number <= (_launchBlock + _botBlocks)) && to != address(this) && to != dexPair && to != address(dexRouter)) {
                _bots[to] = true;

                totalBots++;
            }

            // Block transfer restrictions
            if (transferDelayEnabled && from != address(this) && to != dexPair && to != address(dexRouter)) {
                require(_lastTransferBlock[tx.origin] < (block.number - _transferDelayBlocks) && _lastTransferBlock[to] < (block.number - _transferDelayBlocks), "Token: transfer delay enabled");

                _lastTransferBlock[tx.origin] = block.number;
                _lastTransferBlock[to] = block.number;
            }

            // Max TX and max wallet
            if (from == dexPair && !isExcludedFromMaxTx(to)) {
                // Buy
                require(amount <= _maxTxAmount, "Token: buy amount exceeds max TX limit");
                require(amount + balanceOf(to) <= _maxWalletAmount, "Token: amount would exceed max wallet limit");
            } else if (to == dexPair && !isExcludedFromMaxTx(from)) {
                // Sell
                require(amount <= _maxTxAmount, "Token: sell amount exceeds max TX limit");
            } else if (!isExcludedFromMaxTx(to)) {
                // Transfer
                require(amount + balanceOf(to) <= _maxWalletAmount, "Token: amount would exceed max wallet limit");
            }
        }

        if (swapEnabled && !_isSwapLocked && balanceOf(address(this)) > swapTokensAmount && from != dexPair && !isExcludedFromFees(from) && !isExcludedFromFees(to)) {
            _swapTokens(swapTokensAmount);
        }

        bool takeFees = !_isSwapLocked;

        // Skip fees for excluded
        if (isExcludedFromFees(from) || isExcludedFromFees(to) || to == address(dexRouter)) {
            takeFees = false;
        }
 
        uint256 totalAmount = amount;
        uint256 totalFees = 0;

        // Take fees
        if (takeFees) {
            if (to == dexPair && sellTotalFees > 0) {
                // Sell
                totalFees = (totalAmount * sellTotalFees) / 100;
                _tokensForBurn += (totalFees * sellBurnFee) / sellTotalFees;
                _tokensForLiquidity += (totalFees * sellLiquidityFee) / sellTotalFees;
                _tokensForOperations += (totalFees * sellOperationsFee) / sellTotalFees;
            } else if (from == dexPair && buyTotalFees > 0) {
                // Buy
                totalFees = (totalAmount * buyTotalFees) / 100;
                _tokensForBurn += (totalFees * buyBurnFee) / buyTotalFees;
                _tokensForLiquidity += (totalFees * buyLiquidityFee) / buyTotalFees;
                _tokensForOperations += (totalFees * buyOperationsFee) / buyTotalFees;
            }
 
            if (totalFees > 0) {
                super._transfer(from, address(this), totalFees);

                totalAmount -= totalFees;
            }
        }

        super._transfer(from, to, totalAmount);
    }

    function _swapTokens(uint256 tokensAmount) private lockSwap {
        uint256 totalTokensToSwap = _tokensForBurn + _tokensForLiquidity + _tokensForOperations;

        if (tokensAmount == 0 || totalTokensToSwap == 0) return;

        uint256 burnTokens = (tokensAmount * _tokensForBurn) / totalTokensToSwap;
        uint256 operationsTokens = (tokensAmount * _tokensForOperations) / totalTokensToSwap;
        uint256 halfLiquidityTokens = ((tokensAmount - burnTokens) - operationsTokens) / 2;

        _swapTokensForCurrency((tokensAmount - burnTokens) - halfLiquidityTokens);
 
        uint256 currencyBalance = address(this).balance;
        uint256 currencyForOperations = (currencyBalance * _tokensForOperations) / totalTokensToSwap;
        uint256 currencyForLiquidity = currencyBalance - currencyForOperations;

        if (halfLiquidityTokens > 0 && currencyForLiquidity > 0) {
            _addLiquidity(halfLiquidityTokens, currencyForLiquidity);
        }

        (bool success, ) = address(operationsWallet).call{value: address(this).balance}("");

        if (burnTokens > 0) {
            super._transfer(address(this), address(0xdead), burnTokens);
        }

        _tokensForBurn = 0;
        _tokensForLiquidity = 0;
        _tokensForOperations = 0;
    }

    function _swapTokensForCurrency(uint256 tokensAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
 
        _approve(address(this), address(dexRouter), tokensAmount);
 
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensAmount, 0, path, address(this), block.timestamp);
    }

    function _addLiquidity(uint256 tokensAmount, uint256 currencyAmount) private {
        _approve(address(this), address(dexRouter), tokensAmount);

        dexRouter.addLiquidityETH{value: currencyAmount}(address(this), tokensAmount, 0, 0, address(0xdead), block.timestamp);
    }

    receive() external payable {}
}