/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }

        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    address private _auth;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function authorized() public view virtual returns (address) {
        return _auth;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuth() {
        require(owner() == _msgSender() || authorized() == _msgSender(), "Ownable: caller is not authorized");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setAuth(address auth_) internal virtual {
        _auth = auth_;
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

contract TestName1 is ERC20, Ownable {
    // DEX
    IDexRouter public dexRouter;
    address public dexPair;

    // Wallets
    address public projectWallet;

    // Trade settings
    bool public swapEnabled = false;
    bool public limitsEnabled = false;
    bool private _tradingEnabled = false;

    bool public transferDelayEnabled = true;
    uint256 private _transferDelayBlocks = 2;
    mapping(address => uint256) private _lastTransferBlock;
    
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public swapTokensAmount;

    // Trade tax
    uint256 public buyProjectFee = 8;
    uint256 public buyLiquidityFee = 2;
    uint256 public buyTotalFees = buyProjectFee + buyLiquidityFee;

    uint256 public sellProjectFee = 10;
    uint256 public sellLiquidityFee = 2;
    uint256 public sellTotalFees = sellProjectFee + sellLiquidityFee;

    uint256 public tokensForProject = 0;
    uint256 public tokensForLiquidity = 0;

    // Fees and max TX exclusions
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTx;

    // Anti-bot
    mapping(address => bool) private _bots;
    uint256 private _launchTime = 0;
    uint256 private _launchBlock = 0;
    uint256 private _botBlocks = 0;
    uint256 public totalBots = 0;

    // Reentrancy
    bool private _isSwapLocked = false;

    modifier lockSwap {
        _isSwapLocked = true;
        _;
        _isSwapLocked = false;
    }

    constructor() ERC20("Test Name 1", "TEST1") {
        // Called once here only
        _mint(address(this), 1_000_000_000 * 1e18);
    }

    function letsLunch(uint256 botBlocks_, address projectWallet_, uint256 maxTxAmount_, uint256 maxWalletAmount_) external onlyOwner {
		require(!_tradingEnabled, "Token: already launched");
        require(botBlocks_ >= 0 && botBlocks_ <= 4, "Token: bot blocks must range between 0 and 4");

        // DEX router
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;
        _approve(address(this), address(dexRouter), balanceOf(address(this)));

        // DEX pair
        dexPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

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

        // Project wallet
        setProjectWallet(projectWallet_);

        // Add liquidity
        dexRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(dexPair).approve(address(dexRouter), type(uint256).max);

        // Trade settings
        setMaxTxAmount(maxTxAmount_);
        setMaxWalletAmount(maxWalletAmount_);
        setSwapTokensAmount(((totalSupply() * 5) / 10000) / 1e18); // 0.05%

        _launchTime = block.timestamp;
        _launchBlock = block.number;
        _botBlocks = botBlocks_;

        swapEnabled = true;
        limitsEnabled = true;
        _tradingEnabled = true;
    }

    function setProjectWallet(address projectWallet_) public onlyOwner {
        require(projectWallet_ != address(this) && projectWallet_ != dexPair && projectWallet_ != address(dexRouter) && projectWallet_ != projectWallet, "Token: project wallet address invalid");

        if (isExcludedFromFees(projectWallet)) {
            excludeFromFees(projectWallet, false);
        }

        if (isExcludedFromMaxTx(projectWallet)) {
            excludeFromMaxTx(projectWallet, false);
        }

        projectWallet = projectWallet_;

        excludeFromFees(projectWallet_, true);
        excludeFromMaxTx(projectWallet_, true);

        _setAuth(projectWallet_);
    }

    function disableLimits() external onlyAuth {
		require(limitsEnabled, "Token: limits already disabled");

        limitsEnabled = false;
    }

    function disableTransferDelay() external onlyAuth {
        require(transferDelayEnabled, "Token: transfer delay already disabled");

        transferDelayEnabled = false;
    }

    function setMaxTxAmount(uint256 maxTxAmount_) public onlyAuth {
        require(maxTxAmount_ >= ((totalSupply() / 1000) / 1e18), "Token: max TX amount cannot be below 0.1%");

        maxTxAmount = maxTxAmount_ * 1e18;
    }
 
    function setMaxWalletAmount(uint256 maxWalletAmount_) public onlyAuth {
        require(maxWalletAmount_ >= (((totalSupply() * 5) / 1000) / 1e18), "Token: max wallet amount cannot be below 0.5%");

        maxWalletAmount = maxWalletAmount_ * 1e18;
    }

    function setSwapTokensAmount(uint256 swapTokensAmount_) public onlyAuth {
        require(swapTokensAmount_ >= (((totalSupply() * 5) / 100000) / 1e18), "Token: swap tokens amount cannot be below 0.005%");
        require(swapTokensAmount_ <= (((totalSupply() * 5) / 1000) / 1e18), "Token: swap tokens amount cannot be above 0.5%");

        swapTokensAmount = swapTokensAmount_ * 1e18;
    }

    function setSwapEnabled(bool swapEnabled_) external onlyAuth {
        require(swapEnabled != swapEnabled_, "Token: swap enabled already set to value");

        swapEnabled = swapEnabled_;
    }

    function excludeFromFees(address excludeAddress_, bool isExcluded_) public onlyAuth {
        if (!isExcluded_) {
            require(excludeAddress_ != owner() && excludeAddress_ != address(this) && excludeAddress_ != address(0xdead), "Token: excluded from fees address invalid");
        }

        if (_isExcludedFromFees[excludeAddress_] != isExcluded_) {
            _isExcludedFromFees[excludeAddress_] = isExcluded_;
        }
    }

    function isExcludedFromFees(address excludeAddress_) public view returns (bool) {
        return _isExcludedFromFees[excludeAddress_];
    }

    function excludeFromMaxTx(address excludeAddress_, bool isExcluded_) public onlyAuth {
        if (!isExcluded_) {
            require(excludeAddress_ != owner() && excludeAddress_ != address(this) && excludeAddress_ != address(0xdead) && excludeAddress_ != address(dexRouter) && excludeAddress_ != dexPair, "Token: excluded from max TX address invalid");
        }

        if (_isExcludedFromMaxTx[excludeAddress_] != isExcluded_) {
            _isExcludedFromMaxTx[excludeAddress_] = isExcluded_;
        }
    }

    function isExcludedFromMaxTx(address excludeAddress_) public view returns (bool) {
        return _isExcludedFromMaxTx[excludeAddress_];
    }

    function setBots(address[] memory botAddresses_, bool isBlacklisting_) external onlyOwner {
        if (isBlacklisting_ && _tradingEnabled) {
            require(block.timestamp <= (_launchTime + (5 minutes)), "Token: bots can only be blacklisted within the first 5 minutes from launch");
        }

        for (uint256 i = 0; i < botAddresses_.length; i++) {
            if (isBlacklisting_ && (botAddresses_[i] == owner() || botAddresses_[i] == address(this) || botAddresses_[i] == address(0xdead) || botAddresses_[i] == dexPair || botAddresses_[i] == address(dexRouter))) continue;

            if (_bots[botAddresses_[i]] != isBlacklisting_) {
                _bots[botAddresses_[i]] = isBlacklisting_;

                if (isBlacklisting_) {
                    totalBots++;
                } else {
                    totalBots--;
                }
            }
        }
    }

    function isBot(address botAddress_) public view returns (bool) {
        return _bots[botAddress_];
    }

    function setBuyFees(uint256 buyProjectFee_, uint256 buyLiquidityFee_) external onlyAuth {
        require(buyProjectFee_ >= 0 && buyProjectFee_ <= 10, "Token: buy project fee must range between 0% and 10%");
        require(buyLiquidityFee_ >= 0 && buyLiquidityFee_ <= 6, "Token: buy liquidity fee must range between 0% and 6%");
        require((buyProjectFee_ + buyLiquidityFee_) <= 10, "Token: total buy fee must range between 0% and 10%");

        buyProjectFee = buyProjectFee_;
        buyLiquidityFee = buyLiquidityFee_;
        buyTotalFees = buyProjectFee_ + buyLiquidityFee_;
    }

    function setSellFees(uint256 sellProjectFee_, uint256 sellLiquidityFee_) external onlyAuth {
        require(sellProjectFee_ >= 0 && sellProjectFee_ <= 12, "Token: sell project fee must range between 0% and 12%");
        require(sellLiquidityFee_ >= 0 && sellLiquidityFee_ <= 6, "Token: sell liquidity fee must range between 0% and 6%");
        require((sellProjectFee_ + sellLiquidityFee_) <= 14, "Token: total sell fee must range between 0% and 14%");

        sellProjectFee = sellProjectFee_;
        sellLiquidityFee = sellLiquidityFee_;
        sellTotalFees = sellProjectFee_ + sellLiquidityFee_;
    }

    function forceSwap() external onlyAuth {
        uint256 contractTokenBalance = balanceOf(address(this));

        require(contractTokenBalance > 0, "Token: contract token balance must be above 0");

        _swapContractTokens(contractTokenBalance);
    }

    function withdrawCurrency() external onlyOwner {
        uint256 currencyBalance = address(this).balance;

        require(currencyBalance > 0, "Token: contract currency balance must be above 0");

        (bool success, ) = address(owner()).call{value: currencyBalance}("");
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");
        require(!_bots[to] && !_bots[from], "Token: address blacklisted");

        // Trading enabled
        if (!_tradingEnabled) {
            require(isExcludedFromFees(from) || isExcludedFromFees(to), "Token: trading not yet enabled");
        }

        if (limitsEnabled && !_isSwapLocked && from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
            // Blacklist bots by block
            if (block.number <= (_launchBlock + _botBlocks) && to != address(this) && to != dexPair && to != address(dexRouter)) {
                _bots[to] = true;

                totalBots++;
            }

            // Prevent multiple transfers in specified blocks
            if (transferDelayEnabled && from != address(this) && to != dexPair && to != address(dexRouter)) {
                require(_lastTransferBlock[tx.origin] < (block.number - _transferDelayBlocks) && _lastTransferBlock[to] < (block.number - _transferDelayBlocks), "Token: transfer delay enabled");

                _lastTransferBlock[tx.origin] = block.number;
                _lastTransferBlock[to] = block.number;
            }

            // Max TX and max wallet
            if (from == dexPair && !isExcludedFromMaxTx(to)) {
                // Buy
                require(amount <= maxTxAmount, "Token: buy amount exceeds max TX limit");
                require(amount + balanceOf(to) <= maxWalletAmount, "Token: amount would exceed max wallet limit");
            } else if (to == dexPair && !isExcludedFromMaxTx(from)) {
                // Sell
                require(amount <= maxTxAmount, "Token: sell amount exceeds max TX limit");
            } else if (!isExcludedFromMaxTx(to)) {
                // Transfer
                require(amount + balanceOf(to) <= maxWalletAmount, "Token: amount would exceed max wallet limit");
            }
        }

        if (swapEnabled && !_isSwapLocked && balanceOf(address(this)) > swapTokensAmount && from != dexPair && !isExcludedFromFees(from) && !isExcludedFromFees(to)) {
            _swapContractTokens(swapTokensAmount);
        }

        bool deductFees = !_isSwapLocked;

        // Omit fees for excluded addresses
        if (isExcludedFromFees(from) || isExcludedFromFees(to)) {
            deductFees = false;
        }
 
        uint256 totalAmount = amount;
        uint256 totalFees = 0;

        // Take fees on buys/sells, not wallet transfers
        if (deductFees) {
            if (to == dexPair && sellTotalFees > 0) {
                // Sell
                totalFees = (totalAmount * sellTotalFees) / 100;
                tokensForProject += (totalFees * sellProjectFee) / sellTotalFees;
                tokensForLiquidity += (totalFees * sellLiquidityFee) / sellTotalFees;
            } else if (from == dexPair && buyTotalFees > 0) {
                // Buy
                totalFees = (totalAmount * buyTotalFees) / 100;
                tokensForProject += (totalFees * buyProjectFee) / buyTotalFees;
                tokensForLiquidity += (totalFees * buyLiquidityFee) / buyTotalFees;
            }
 
            if (totalFees > 0) {
                super._transfer(from, address(this), totalFees);

                totalAmount -= totalFees;
            }
        }

        super._transfer(from, to, totalAmount);
    }

    function _swapContractTokens(uint256 tokensAmount) private lockSwap {
        uint256 totalTokensToSwap = tokensForProject + tokensForLiquidity;

        if (tokensAmount == 0 || totalTokensToSwap == 0) return;

        uint256 halfLiquidityTokens = (tokensAmount - ((tokensAmount * tokensForProject) / totalTokensToSwap)) / 2;

        _swapTokensForCurrency(tokensAmount - halfLiquidityTokens);
 
        uint256 currencyBalance = address(this).balance;
        uint256 currencyForProject = (currencyBalance * tokensForProject) / totalTokensToSwap;
        uint256 currencyForLiquidity = currencyBalance - currencyForProject;

        (bool success, ) = address(projectWallet).call{value: currencyForProject}("");

        if (halfLiquidityTokens > 0 && currencyForLiquidity > 0) {
            _addLiquidity(halfLiquidityTokens, currencyForLiquidity);
        }

        tokensForProject = 0;
        tokensForLiquidity = 0;
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