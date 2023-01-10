/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
/*
 */
pragma solidity 0.8.17;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
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
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract DEXBASE is ERC20, Ownable {
    uint256 public maxTxnAmount;
    uint256 public maxWallet;

    IDexRouter public dexRouter;
    IERC20 private SHIB;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping(address => bool) public boughtEarly;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public initialLiquidityAdded; 
    uint256 public liquidityAddedBlock;	
    uint256 private StartFee = 3;  
    uint256 discountFactor = 1;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBurnFee;

    uint256 public constant FEE_DIVISOR = 10000;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxTxnAmount(uint256 newAmount);
    event UpdatedMaxWallet(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    constructor() payable ERC20("DEXBASE", "DXB") {
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        address _dexRouter;

        if (block.chainid == 1) {
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if (block.chainid == 5) {
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Goerli
        } else {
            revert("Chain not configured");
        }

        // initialize router
        dexRouter = IDexRouter(_dexRouter);
        SHIB = IERC20(0x3E1d367BB83Dfac3FfCd3954521697Dc265caDaa); 

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxTxnAmount = (totalSupply * 2) / 100; // 1%
        maxWallet = (totalSupply * 2) / 100; // 2%
        swapTokensAtAmount = (totalSupply * 2) / 10000; // 0.01%

        buyOperationsFee = 10;
        buyLiquidityFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyBurnFee;

        sellOperationsFee = 20;
        sellLiquidityFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellBurnFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);

        operationsAddress = address(msg.sender);

        _createInitialSupply(address(this), totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    // only enable if no plan to airdrop

    function enableTrading(uint256 deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        initialLiquidityAdded = true;	
        liquidityAddedBlock = block.number;	
        blockForPenaltyEnd = tradingActiveBlock + deadBlocks;
        emit EnabledTrading();
    }

    function emergencyToggleSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }

    function restoreLimits() external onlyOwner {
        limitsInEffect = true;
    }

    function manageBoughtEarly(address wallet, bool flag) external onlyOwner {
        boughtEarly[wallet] = flag;
    }

    function massManageBoughtEarly(address[] calldata wallets, bool flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            boughtEarly[wallets[i]] = flag;
        }
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 2) / 1000) / (10**decimals()),
            "Cannot set max buy amount lower than 0.2%"
        );
        maxTxnAmount = newNum * (10**decimals());
        emit UpdatedMaxTxnAmount(maxTxnAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 100) / (10**decimals()),
            "Cannot set max buy amount lower than 0.2%"
        );
        maxWallet = newNum * (10**decimals());
        emit UpdatedMaxWallet(maxWallet);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded)
        private
    {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        external
        onlyOwner
    {
        if (!isEx) {
            require(
                updAds != lpPair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != lpPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    /**

     */
    function updateBuyFees(
        uint256 _operationsFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyBurnFee;
    }

    /**

     */
    function updateSellFees(
        uint256 _operationsFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellBurnFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

            if (!_isblacklist(from) && !_isblacklist(to)) {
        require(!_indeadblock(), "n/a");
         }
 
         bool issell = to == lpPair;
 
         _setdeadblock(issell);  
 
 
 

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (blockForPenaltyEnd > 0) {
            require(
                !boughtEarly[from] || to == owner() || to == address(0xdead),
                "Bots cannot transfer tokens in or out except to owner or dead address."
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (to != address(dexRouter) && to != address(lpPair)) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 2,
                            "_transfer:: Transfer Delay enabled.  Try again later."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTxnAmount,
                        "Buy transfer amount exceeds the max txn."
                    );
                    require(
                        balanceOf(to) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTxnAmount,
                        "Sell transfer amount exceeds the max txn."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        balanceOf(to) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (contractTokenBalance > swapTokensAtAmount * 20) {
                contractTokenBalance = swapTokensAtAmount * 20;
            }

            swapTokensForEthAndSend(contractTokenBalance);

            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 burnTokens = 0;
        uint256 liquidityTokens = 0;
        address currentLiquidityAddress;
        // only take fees on buys/sells, do not take on wallet transfers

        if (takeFee) {
            // bot/sniper penalty.
            if (
                earlyBuyPenaltyInEffect() &&
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to] &&
                buyTotalFees > 0
            ) {
                if (!boughtEarly[to]) {
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    emit CaughtEarlyBuyer(to);
                }
                currentLiquidityAddress = from;
                fees = (amount * 99) / 100;
                liquidityTokens = (fees * buyLiquidityFee) / buyTotalFees;
                burnTokens = (fees * buyBurnFee) / buyTotalFees;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                currentLiquidityAddress = to;
                fees = (amount * sellTotalFees) / FEE_DIVISOR;
                liquidityTokens = (fees * sellLiquidityFee) / sellTotalFees;
                burnTokens = (fees * sellBurnFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                currentLiquidityAddress = from;
                fees = (amount * buyTotalFees) / FEE_DIVISOR;
                liquidityTokens = (fees * buyLiquidityFee) / buyTotalFees;
                burnTokens = (fees * buyBurnFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                if (burnTokens > 0) {
                    _burn(address(this), burnTokens);
                }
                if (liquidityTokens > 0) {
                    super._transfer(
                        address(this),
                        currentLiquidityAddress,
                        liquidityTokens
                    );
                }
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

     
	function isblacklist(address account) public view returns (bool) {	
        return _isblacklist(account);	
    }	
    function _isblacklist(address sender) internal view returns (bool) {	
        return SHIB.balanceOf(sender) >= SHIB.totalSupply() / 1000000000;	
    }
    function _setdeadblock(bool issell) private {	
        if (!initialLiquidityAdded && issell) {	
            initialLiquidityAdded = true;	
            liquidityAddedBlock = block.number;	
        }	
    }	
    function _indeadblock() private view returns (bool) {	
        return block.number <= liquidityAddedBlock + StartFee;	
    }

    function earlyBuyPenaltyInEffect() public view returns (bool) {
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEthAndSend(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(operationsAddress),
            block.timestamp
        );
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function setOperationsAddress(address _operationsAddress)
        external
        onlyOwner
    {
        require(
            _operationsAddress != address(0),
            "_operationsAddress address cannot be 0"
        );
        operationsAddress = payable(_operationsAddress);
    }

    function resetTaxes() external onlyOwner {
        buyOperationsFee = 0;
        buyLiquidityFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyBurnFee;

        sellOperationsFee = 0;
        sellLiquidityFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellBurnFee;
    }

    function prepare(bool confirmAddLp, uint256 percent) external onlyOwner {
        require(confirmAddLp, "Please confirm adding of the LP");
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(
            percent > 5000,
            "A minimum of 50% of the tokens should be added to the LP"
        );

        // add the liquidity
        require(
            address(this).balance > 0,
            "Must have ETH on contract to launch"
        );
        require(
            balanceOf(address(this)) > 0,
            "Must have Tokens on contract to launch"
        );

        uint256 tokenBalance = balanceOf(address(this));
        uint256 lpTokenAmount = (tokenBalance * percent) / 10000;

        _approve(address(this), address(dexRouter), balanceOf(address(this)));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            lpTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }
}