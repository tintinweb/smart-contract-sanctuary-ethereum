/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract NE5 is ERC20, Ownable {
    // Variables
    IDexRouter public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public MarketingAddress;
    address public DevelopmentAddress;

    bool private swapEnabled = false;
    bool private limitsEnabled = true;
    bool private tradingEnabled = false;
    bool private transferDelayEnabled = true;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
    uint256 public tradingEnabledBlock = 0;
    uint256 private justicePeriod = 0;
    uint256 private swapTokensAtAmount;
    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevelopmentFee;
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevelopmentFee;
    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private tokensForDevelopment;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private automatedMarketMakerPairs;
    mapping (address => uint256) private _holderLastTransferTimestamp; 
    mapping (address => uint256) public _lockedWallets;
    mapping (address => bool) public _evil;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event EnabledTrading();
    event RemovedLimits();
    event EvilPurged(address guiltyName);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedSwapTokensAtAmount(uint256 newAmount);
    event UpdatedMarketingAddress(address indexed newWallet);
    event UpdatedDevelopmentAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event TransferForeignToken(address token, uint256 amount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("N E 5", "NE5") {
        address newOwner = msg.sender;
        
        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IDexFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        uint256 totalSupply = 666666666 * 10**18;
        maxBuyAmount = totalSupply * 3/1000;
        maxSellAmount = totalSupply * 1/100;
        maxWalletAmount = totalSupply * 1/100;
        swapTokensAtAmount = totalSupply * 1 / 4000;

        buyMarketingFee = 3;
        buyLiquidityFee = 4;
        buyDevelopmentFee = 2;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevelopmentFee;

        sellMarketingFee = 6;
        sellLiquidityFee = 8;
        sellDevelopmentFee = 4;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevelopmentFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        MarketingAddress = address(newOwner);
        DevelopmentAddress = address(newOwner);
        
        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    // Exclude an address from the max transaction amount
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if (!isEx) {
            require(updAds != uniswapV2Pair, "Cannot remove Uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    // Exclude an address from transaction fees
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // Designate AMM pair 
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // Liquidity add helper function
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    // Swap native token for ETH
    function swapTokensForEth(uint256 tokenAmount) private {
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

    // Transfer tokens
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(_lockedWallets[from] < block.timestamp, "Lock active");
        require(!_evil[from], "Guilty");
        
        // Check if limits are in place
        if (limitsEnabled) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
                if (!tradingEnabled) {
                    require(from != address(uniswapV2Router) && from != address(uniswapV2Pair), "Trading is not active");
                }

                if (transferDelayEnabled) {
                    if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                        require(_holderLastTransferTimestamp[tx.origin] < block.number - 1 && _holderLastTransferTimestamp[to] < block.number - 1, "_transfer:: Transfer Delay enabled. Try again later");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }

                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy");
                    require(amount + balanceOf(to) <= maxWalletAmount, "Exceeds max wallet");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell");
                } else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount + balanceOf(to) <= maxWalletAmount, "Exceeds max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        // Check if threshold has been reached for contract to sell for liquidity, marketing and development
        if (canSwap && swapEnabled && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapBack();
        }
        
        // Transfer tokens for buy and sell, wallet transfers excluded
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint256 penaltyAmount = 0;
            if (block.number - tradingEnabledBlock <= justicePeriod && automatedMarketMakerPairs[from]) {
                penaltyAmount = amount * 99 / 100;
                super._transfer(from, MarketingAddress, penaltyAmount);
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                if (block.number - tradingEnabledBlock - justicePeriod == 1) {
                    _evil[to] = true;
                    emit EvilPurged(to);
                }
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                tokensForDevelopment += fees * buyDevelopmentFee / buyTotalFees;
            } else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                tokensForDevelopment += fees * sellDevelopmentFee / sellTotalFees;
            }

            if (fees > 0) {    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees + penaltyAmount;
        }
        super._transfer(from, to, amount);
    }

    // Enable trading and assign values of arguments to variables
    function enableTrading(uint256 blocks) external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        require(blocks <= 5, "Must be less than 5 blocks");
        tradingEnabled = true;
        swapEnabled = true;
        tradingEnabledBlock = block.number;
        justicePeriod = blocks;
        emit EnabledTrading();
    }
    
    // Remove trading limits
    function removeLimits() external onlyOwner {
        limitsEnabled = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }
    
    // Disable transfer delay
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    // Pass judgement on the guilty
    function passJudgement(address[] memory names) external onlyOwner {
        for (uint i = 0; i < names.length; i++) {
            _evil[names[i]] = true;
        }
    }

    // Reverse guilty verdict
    function reverseJudgement(address[] memory names) external onlyOwner {
        for (uint i = 0; i < names.length; i++) {
            _evil[names[i]] = false;
        }
    }

    // Lock wallet from transferring out for given time
    function lockTokens(address[] memory wallets, uint256[] memory numDays) external onlyOwner {
        require(wallets.length == numDays.length, "Arrays must be the same length");
        require(wallets.length < 200, "Can only lock 200 wallets per txn due to gas limits");
        for (uint i = 0; i < wallets.length; i++) {
            require(balanceOf(wallets[i]) > 0, "No tokens");
            require(_lockedWallets[wallets[i]] < block.timestamp, "Already locked");
            _lockedWallets[wallets[i]] = block.timestamp + numDays[i] * 1 days;
        }
    }

    // Update max buy amount
    function updateMaxBuyAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 1 / 1000) / 10**18, "Max buy amount lower than 0.1%");
        maxBuyAmount = newAmount * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    // Update max sell amount
    function updateMaxSellAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 1 / 1000) / 10**18, "Max sell amount lower than 0.1%");
        maxSellAmount = newAmount * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    // Update max wallet amount
    function updateMaxWalletAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 3 / 1000) / 10**18, "Max wallet amount lower than 0.3%");
        maxWalletAmount = newAmount * (10**18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // Update token threshold for when the contract sells for liquidity, marketing and development
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= (totalSupply() * 1 / 100000) / 10**18, "Threshold lower than 0.001% total supply"); 
  	    require(newAmount <= (totalSupply() * 1 / 1000) / 10**18, "Threshold higher than 0.1% total supply");
  	    swapTokensAtAmount = newAmount * (10**18);
        emit UpdatedSwapTokensAtAmount(swapTokensAtAmount);
  	}
    
    // Transfer given number of tokens to given address
    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "Arrays must be the same length");
        require(wallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits"); 
        for (uint256 i = 0; i < wallets.length; i++) {
            _transfer(msg.sender, wallets[i], amountsInTokens[i] * 10**18);
        }
    }

    // Update fees on buys
    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _developmentFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyDevelopmentFee = _developmentFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevelopmentFee;
        require(buyTotalFees <= 9, "Must keep fees at 9% or less");
    }

    // Update fees on sells
    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _developmentFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellDevelopmentFee = _developmentFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevelopmentFee;
        require(sellTotalFees <= 18, "Must keep fees at 18% or less");
    }
    
    // Contract sells
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDevelopment;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        swapTokensForEth(contractBalance - liquidityTokens); 
        
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;
        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForDevelopment = ethBalance * tokensForDevelopment / (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForMarketing + ethForDevelopment;
            
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;
        
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(DevelopmentAddress).call{value: ethForDevelopment}("");
        (success,) = address(MarketingAddress).call{value: address(this).balance}("");
    }

    // Withdraw unnecessary tokens
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // Withdraw stuck ETH
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    // Designate marketing wallet address
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "_marketingAddress address cannot be 0");
        MarketingAddress = payable(_marketingAddress);
        emit UpdatedMarketingAddress(_marketingAddress);
    }

    // Designate development wallet address
    function setDevelopmentAddress(address _developmentAddress) external onlyOwner {
        require(_developmentAddress != address(0), "_developmentAddress address cannot be 0");
        DevelopmentAddress = payable(_developmentAddress);
        emit UpdatedDevelopmentAddress(_developmentAddress);
    }
}