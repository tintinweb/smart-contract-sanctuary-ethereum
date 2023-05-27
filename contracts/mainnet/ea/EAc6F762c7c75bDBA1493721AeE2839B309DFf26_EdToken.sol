/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/**
  * 🌐 Website - edtoken.io
  * 🐦 Twitter - twitter.com/EdEthereum
  * ✈️ Telegram Group - t.me/EdEthereum
  * 🐙 GitHub - github.com/EdEthereumm
  * 📔 Whitepaper - docs.edtoken.io
  */

//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
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
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,
        uint amountOutMin, address[] calldata path, address to, uint deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,
        address[] calldata path, address to, uint deadline) external payable;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin,
        uint256 amountETHMin, address to, uint256 deadline) external payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract EdToken is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public swapTokensAtAmount;

    struct Set { uint256 dev; uint256 operations; uint256 burn; uint256 liquidity; }
    Set public tokensFor;

    uint256 public tradingActiveBlock = 0;
    uint256 public deadBlocks = 1;
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    uint256 public botsCaught;

    bool private swapping;
    bool public limitsInEffect  = true;
    bool public tradingActive   = false;
    bool public swapEnabled     = false;
    bool public transferDelayEnabled = true;

    mapping (address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) public _isExcludedMaxTx;
    mapping (address => bool) public automatedMarketMakerPairs;

    event EnabledTrading();
    event ExcludedFromMaxTx(address _address, bool excluded);
    event UpdatedMaxTxAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event OwnerForcedSwapBack(uint256 timestamp);
    event CaughtEarlyBuyer(address bot);
    event RemovedLimits();

    constructor () ERC20 ("Ethereum Jawbreaker", "ED") {
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        excludeFromMaxTxAmount(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 123690000000000 * 1e9;
        maxTxAmount         = totalSupply * 20 / 1e3; // 2.0%
        maxWalletAmount     = totalSupply * 20 / 1e3; // 2.0%
        swapTokensAtAmount  = totalSupply * 5 / 1e4; // 0.05%

        excludeFromMaxTxAmount(msg.sender, true);
        excludeFromMaxTxAmount(address(this), true);
        excludeFromMaxTxAmount(address(0xdead), true);
        
         _createInitialSupply(msg.sender, totalSupply);
    }

    receive() external payable { }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading.");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        if (_deadBlocks == 0) deadBlocks = 1;
        else deadBlocks = _deadBlocks;
        blockForPenaltyEnd = tradingActiveBlock + deadBlocks;
        emit EnabledTrading();
    }

    function excludeFromMaxTxAmount(address updAds, bool excluded) public onlyOwner {
        if (excluded == false) { require(updAds != lpPair, "Cannot include Uniswap pair from maxTxAmount restriction."); }
        _isExcludedMaxTx[updAds] = excluded;
        emit ExcludedFromMaxTx(updAds, excluded);
    }

    function updateMaxTx(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 2 / 1e3) / 1e18, "Cannot set maxTxAmount lower than 0.2%");
        maxTxAmount = newAmount * 1e18;
        emit UpdatedMaxTxAmount(maxTxAmount);
    }

    function updateMaxWallet(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 3 / 1e3) / 1e18, "Cannot set maxWalletAmount lower than 0.3%");
        maxWalletAmount = newAmount * 1e18;
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokens(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 1e5, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1e4, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs.");

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction.");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }

    ////

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        require(tradingActive, "Trading is not active.");

        if (blockForPenaltyEnd > 0) {
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
                if (transferDelayEnabled) {
                    if (to != address(dexRouter) && to != address(lpPair)) {
                        require(_holderLastTransferTimestamp[tx.origin] < block.number - 2 && _holderLastTransferTimestamp[to] < block.number - 2, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }
    
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTx[to]) { // Buy
                    require(amount <= maxTxAmount, "Cannot exceed the maxTxAmount.");
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot exceed the maxWalletAmount.");
                }
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTx[from]) { // Sell
                    require(amount <= maxTxAmount, "Cannot exceed the maxTxAmount.");
                }
                else if (!_isExcludedMaxTx[to]) {
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot exceed the maxWalletAmount.");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 fees = 0;
        if (earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]) { // botPenalty
            if (!boughtEarly[to]) {
                boughtEarly[to] = true;
                botsCaught += 1;
                emit CaughtEarlyBuyer(to);
            }

            fees = amount * 99 / 100;
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }

        amount -= fees;

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool) {
        return block.number < blockForPenaltyEnd;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        excludeFromMaxTxAmount(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {
        if (tokensFor.burn > 0 && balanceOf(address(this)) >= tokensFor.burn) {
            _burn(address(this), tokensFor.burn);
        }
        tokensFor.burn = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensFor.dev + tokensFor.operations + tokensFor.liquidity;

        if (contractBalance == 0 || totalTokensToSwap == 0) { return; }

        if (contractBalance > swapTokensAtAmount * 60) {
            contractBalance = swapTokensAtAmount * 60;
        }

        uint256 liquidityTokens = contractBalance * tokensFor.liquidity / totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensFor.operations / (totalTokensToSwap - (tokensFor.liquidity / 2));
        uint256 ethForDev = ethBalance * tokensFor.dev / (totalTokensToSwap - (tokensFor.liquidity / 2));

        ethForLiquidity -= ethForOperations + ethForDev;

        tokensFor.dev = 0;
        tokensFor.operations = 0;
        tokensFor.liquidity = 0;
        tokensFor.burn = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }
    }
}