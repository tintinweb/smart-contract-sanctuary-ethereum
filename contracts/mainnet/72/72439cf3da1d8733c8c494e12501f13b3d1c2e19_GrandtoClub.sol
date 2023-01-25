// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract GrandtoClub is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "GrandtoClub";
    string private _symbol = "GTC";
    uint8 private _decimals = 18;

    uint256 private _totalSupply = 1000000 * 10**_decimals; // total supply

    address public developerAddress =
        0xb280eB22334f4c3b0cC2fE6C5665FE11B15AE5e3; // Developer Address

    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /**
     * @dev Set the maximum transaction amount allowed in a transfer.
     */
    uint256 public maxTransactionAmount = _totalSupply / 400; // 0.25% of the total supply

    /**
     * @dev Set the maximum allowed balance in a wallet.
     *
     * IMPORTANT: This value MUST be greater than `numberOfTokensToSwapToLiquidity` set below,
     * otherwise the liquidity swap will never be executed
     */
    uint256 public maxWalletBalance = _totalSupply / 100; // 1% of the total supply

    /**
     * @dev Set the number of tokens to swap and add to liquidity.
     */
    uint256 public numberOfTokensToSwapToLiquidity = _totalSupply / 1000; // 0.1% of the total supply

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint8 public _liquidityFee = 4;
    uint8 private _previousLiquidityFee = _liquidityFee;

    uint8 public _developerFee = 3;
    uint8 private _previousMarketingFee = _developerFee;

    mapping(address => bool) private liqPairs;
    address public uniswapV2Pair;

    bool private _takeFeeOnBuy = true;
    bool private _takeFeeOnSell = true;
    bool private _takeFeeOnTransfer = false;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event LiquidityAdded(
        uint256 tokenAmountSent,
        uint256 ethAmountSent,
        uint256 liquidity
    );

    struct AntiBot {
        bool lockCheater;
        mapping(address => uint256) _walletFirstBuyAttempt;
        mapping(address => uint256) _walletLastBuyAttempt;
        mapping(address => bool) _bannedWallets;
    }
    AntiBot antiBot;

    uint256 public launchingTime;
    bool public tradeStarted;

    /*
 
    * Steps to launch:
    *   0. 
    *   1. deploy contract.
    *   2. add Liq
    *   3. set _takeFeeOnTransfer to true (optional)
    *
    */
    constructor() {
        _tOwned[_msgSender()] = _totalSupply; //mint all to deployer
        emit Transfer(address(0), _msgSender(), _totalSupply);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[developerAddress] = true;
        antiBot.lockCheater = true;
        initLiqPair(uniswapV2Router);
    }

    function initLiqPair(address _dexRouter) internal {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_dexRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        liqPairs[uniswapV2Pair] = true;
        uniswapV2Router = _dexRouter;
        _isExcludedFromFee[_dexRouter] = true; //no fees for liqPool
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    // once enabled, can never be turned off
    function OpenTrading() external onlyOwner {
        tradeStarted = true;
        launchingTime = block.number;
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(tradeStarted, "Trading has not started");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !antiBot._bannedWallets[to] && !antiBot._bannedWallets[from],
            "401: Forbidden"
        );
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);

        if (
            amount > maxTransactionAmount &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            revert("Transfer amount exceeds the maxTxAmount.");
        }
        /**
         * The pair needs to excluded from the max wallet balance check;
         * selling tokens is sending them back to the pair (without this
         * check, selling tokens would not work if the pair's balance
         * was over the allowed max)
         */
        if (
            maxWalletBalance > 0 &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to] &&
            !liqPairs[to]
        ) {
            uint256 recipientBalance = balanceOf(to);
            require(
                recipientBalance + amount <= maxWalletBalance,
                "New balance would exceed the maxWalletBalance"
            );
        }

        // lockCheater anti bot . ONLY 1 TX / BLOCK ALLOWED.
       if (antiBot.lockCheater == true) {
            if (
                to != owner() &&
                to != address(_uniswapV2Router) &&
                !liqPairs[to]
            ) {
                require( 
                    antiBot._walletLastBuyAttempt[tx.origin] < block.number,
                    "401: Only one tx per block allowed."
                );
                antiBot._walletLastBuyAttempt[tx.origin] = block.number;
            }
        }
        // AUTOBAN SNIPER anti bot . BAN WALLET IF ATTEMPT TO TRADE AT LAUNCH TIME + 2 BLOCKS.

        if (
            block.number <= (launchingTime + 2) &&
            to != address(_uniswapV2Router) &&
            !liqPairs[to]
        ) {
            antiBot._bannedWallets[to] = true;
        }

        bool takeFee = _takeFeeOnTransfer;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            if (liqPairs[from]) {
                takeFee = _takeFeeOnBuy;
            } else if (liqPairs[to]) {
                takeFee = _takeFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _beforeTokenTransfer(address sender) internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        liquify(contractTokenBalance, sender);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            _beforeTokenTransfer(sender);

            _transferStandard(sender, recipient, amount);
        } else {
            _beforeTokenTransfer(sender);

            _transferWithFee(sender, recipient, amount);
        }
    }

    function _transferWithFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 fromBalance = _tOwned[sender];
        require(
            fromBalance >= tAmount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 devFee = (tAmount * _developerFee) / 100;
        uint256 liqFee = (tAmount * _liquidityFee) / 100;

        uint256 tTransferAmount = tAmount - devFee - liqFee;

        unchecked {
            _tOwned[sender] = fromBalance - tTransferAmount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _tOwned[recipient] += tTransferAmount;
            _tOwned[address(this)] += liqFee;
            _tOwned[developerAddress] += devFee;
        }

        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, developerAddress, devFee);
        emit Transfer(sender, address(this), liqFee);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 fromBalance = _tOwned[sender];
        require(
            fromBalance >= tAmount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _tOwned[sender] = fromBalance - tAmount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _tOwned[recipient] += tAmount;
        }

        emit Transfer(sender, recipient, tAmount);
    }

    function _getCurrentSupply() private view returns (uint256) {
        uint256 tSupply = _totalSupply;
        return tSupply;
    }

    function removeAllFee() private {
        if (_liquidityFee == 0 && _developerFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _developerFee;

        _liquidityFee = 0;
        _developerFee = 0;
    }

    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
        _developerFee = _previousMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        developerAddress = _marketingAddress;
    }

    function setTakeFees(
        bool newTakeFeeOnBuy,
        bool newTakeFeeOnsell,
        bool newTakeFeeOnTransfer
    ) external onlyOwner {
        _takeFeeOnBuy = newTakeFeeOnBuy;
        _takeFeeOnSell = newTakeFeeOnsell;
        _takeFeeOnTransfer = newTakeFeeOnTransfer;
    }

    function getTakeFees() public view onlyOwner returns (bool[] memory) {
        bool[] memory result = new bool[](3);
        result[0] = _takeFeeOnBuy;
        result[1] = _takeFeeOnSell;
        result[2] = _takeFeeOnTransfer;
        return result;
    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(uint256 contractTokenBalance, address sender) internal {
        if (contractTokenBalance >= maxTransactionAmount)
            contractTokenBalance = maxTransactionAmount;

        bool isOverRequiredTokenBalance = (contractTokenBalance >=
            numberOfTokensToSwapToLiquidity);

        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if (
            isOverRequiredTokenBalance &&
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            (!liqPairs[sender]) // stops swap and liquify for all "buy" transactions
        ) {
            _swapAndLiquify(contractTokenBalance);
        }
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _uniswapV2Router
            .addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            // Bounds the extent to which the WETH/token price can go up before the transaction reverts.
            // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
            0,
            // Bounds the extent to which the token/WETH price can go up before the transaction reverts.
            // 0 = accept any amount (slippage is inevitable)
            0,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }


    function blackListWallets(address _wallet, bool isBanned) public onlyOwner {
        antiBot._bannedWallets[_wallet] = isBanned; // true or false
    }

    // change the minimum amount of tokens to sell for ETH, swap add liquidity
    function setAmountTriggerSwapToETH(uint256 _triggerAmount)
        external
        onlyOwner
        returns (bool)
    {
        numberOfTokensToSwapToLiquidity = _triggerAmount;
        return true;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTransactionAmount = _amount * (10**18);
    }

    function updateMaxWalletAmount(uint256 _newMaxAmount) external onlyOwner {
        maxWalletBalance = _newMaxAmount * (10**18);
    }

    // disable Transfer lockCheater ANTI BOT - cannot be reenabled
    function disableDelayAntiBot() external onlyOwner returns (bool) {
        antiBot.lockCheater = false;
        return true;
    }

    receive() external payable {}

}