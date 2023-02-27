/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
/*

    Website:
    https://mevfree.com

    Telegram:
    https://t.me/mevfree

    Twitter:
    https://twitter.com/mevfree


 */
pragma solidity ^0.8.17;

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

        /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

        /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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

    function renounceOwnership(bool confirmRenounce)
        external
        virtual
        onlyOwner
    {
        require(confirmRenounce, "Please confirm renounce!");
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

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external
        returns (uint[] memory amounts);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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

contract MEVFree is ERC20, Ownable {

    uint256 public maxBuyTokenAmount;
    uint256 public maxSellTokenAmount;
    uint256 public maxWalletTokenAmount;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping = false;
    uint256 public swapTokensAtAmount;

    address public devWallet;
    address public marketingWallet;
    address public rewardsWallet;

    uint256 public launchBlock = 0; // 0 means trading is not active
    uint public BSL = 0; // blocks since launch
    uint256 public blockForLaunchPenaltyEnd;
    uint256 public penaltyBlocks = 0;
    uint256 public feesLastUpdated = 0;
    bool public launchPenaltyPeriod = false;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapBackEnabled = false;

    // launch buy fees
    uint[10] launchBuyDevFees =       [40, 40, 30, 25, 20, 15, 10, 5, 5, 5];
    uint[10] launchBuyMarketingFees = [20, 15, 15, 15, 10, 10, 5, 3, 3, 2];
    uint[10] launchBuyRewardsFees =   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint[10] launchBuyLiquidityFees = [20, 15, 15, 10, 10, 5, 5, 2, 2, 1];
    uint[10] launchBuyBurnFees =      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    // normal buy fees
    uint256 private normalBuyDevFee = 4;
    uint256 private normalBuyMarketingFee = 1;
    uint256 private normalBuyRewardsFee = 0;
    uint256 private normalBuyLiquidityFee = 1;
    uint256 private normalBuyBurnFee = 0;

    // buy fees
    uint256 public buyDevFee = 4;
    uint256 public buyMarketingFee = 1;
    uint256 public buyRewardsFee = 0;
    uint256 public buyLiquidityFee = 1;
    uint256 public buyBurnFee = 0;
    uint256 public buyTotalFees =  buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;

    // launch sell fees
    uint[10] launchSellDevFees =       [40, 40, 30, 25, 20, 15, 10, 5, 5, 5];
    uint[10] launchSellMarketingFees = [20, 15, 15, 15, 10, 10, 5, 3, 3, 2];
    uint[10] launchSellRewardsFees =   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint[10] launchSellLiquidityFees = [20, 15, 15, 10, 10, 5, 5, 2, 2, 1];
    uint[10] launchSellBurnFees =      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    // normal sell fees
    uint256 private normalSellDevFee = 4;
    uint256 private normalSellMarketingFee = 1;
    uint256 private normalSellRewardsFee = 0;
    uint256 private normalSellLiquidityFee = 1;
    uint256 private normalSellBurnFee = 0;

    // sell fees
    uint256 public sellDevFee = 4;
    uint256 public sellMarketingFee = 1;
    uint256 public sellRewardsFee = 0;
    uint256 public sellLiquidityFee = 1;
    uint256 public sellBurnFee = 0;
    uint256 public sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;

    // fee token counters
    uint256 public tokensForDev;
    uint256 public tokensForMarketing;
    uint256 public tokensForRewards;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBurn;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // Anti-MEV mappings and variables
    mapping(address => uint256) public blocksOfTrades; // to hold the next block that trading is allowed
    bool public antiMEVEnabled = true;
    bool public antiContractSellEnabled = true;
    uint256 public mevBlocks = 2; // blocks to block same account trades from

    // mapping to store mev bots or suspected mev bots
    // additional mapping to store whitelisted address exempt from antiMEV
    mapping (address => bool) public botsOfMEV;
    mapping (address => bool) public whitelistedMEV;

    // mappings to track those who bought during the higher penalty period
    // so that they always have the tax penalty on sell whilst they hold tokens
    mapping(address => bool) public launchPenaltyHolder;
    mapping(address => uint) public launchPenaltySellFee;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyTokenAmount(uint256 newAmount);

    event UpdatedMaxSellTokenAmount(uint256 newAmount);

    event UpdatedMaxWalletTokenAmount(uint256 newAmount);

    event UpdatedDevWallet(address indexed newWallet);

    event UpdatedMarketingWallet(address indexed newWallet);

    event UpdatedRewardsWallet(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBackAndBurn(uint256 timestamp);

    event OwnerForcedSwapOfTokens(uint256 timestamp);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    event Burn(address indexed user, uint256 amount);

    event TransferForeignToken(address token, uint256 amount);

    constructor() payable ERC20("MEVFree", "MEVFree") {
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        address _dexRouter;

        _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2 Router

        // initialize router
        dexRouter = IDexRouter(_dexRouter);

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );
        _setAutomatedMarketMakerPair(address(lpPair), true);

        _excludeFromMaxTransaction(lpPair, true);
        automatedMarketMakerPairs[lpPair] = true;

        uint256 totalSupply = 100 * 1e6 * 1e18; // 100 million

        maxBuyTokenAmount = (totalSupply * 1) / 100; // 1%
        maxSellTokenAmount = (totalSupply * 1) / 100; // 1%
        maxWalletTokenAmount = (totalSupply * 2) / 100; // 2%
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05 %

        // set wallets - assume deployer is the dev
        devWallet = address(0x18234cA263bfE40ACB395119ABFFC5c80f31153A);
        marketingWallet = address(0x4098BE3E6b13cAEF10373cB398200fdbd4F5f5a3);
        rewardsWallet = address(0x1A23560fb2946Ab8Fb4056a25834061D8594936C);

        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(newOwner), true);
        _excludeFromMaxTransaction(address(devWallet), true);
        _excludeFromMaxTransaction(address(marketingWallet), true);
        _excludeFromMaxTransaction(address(rewardsWallet), true);
        _excludeFromMaxTransaction(address(dexRouter), true);
        _excludeFromMaxTransaction(address(0xa4fD37C3916824a974df5FA6e136A8Fc7e58044E), true); // Team
        _excludeFromMaxTransaction(address(0x3C507DC5C57c31fB9C61BB75471B19B71bf16a95), true); // Presale

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(devWallet), true);
        excludeFromFees(address(marketingWallet), true);
        excludeFromFees(address(rewardsWallet), true);
        excludeFromFees(address(dexRouter), true);
        excludeFromFees(address(0xa4fD37C3916824a974df5FA6e136A8Fc7e58044E),true); // Team

        _createInitialSupply(address(this), (totalSupply * 20) / 100); // Tokens for liquidity
        _createInitialSupply(address(rewardsWallet),(totalSupply * 15) / 100); // Rewards
        _createInitialSupply(address(0xa4fD37C3916824a974df5FA6e136A8Fc7e58044E),(totalSupply * 10) / 100); // Team
        _createInitialSupply(address(0x3C507DC5C57c31fB9C61BB75471B19B71bf16a95),(totalSupply * 35) / 100); // Presale
        _createInitialSupply(address(newOwner),(totalSupply * 20) / 100); //Additional Liquidity etc

        transferOwnership(newOwner);
    }

    receive() external payable {}

    function emergencyUpdateRouter(address router) external onlyOwner {
        require(!tradingActive, "Cannot update after trading is active");
        dexRouter = IDexRouter(router);
    }

    function setAntiMEVMode(bool setting) external onlyOwner {
        antiMEVEnabled = setting;
    }

    function setAntiContractSellMode(bool setting) external onlyOwner {
        antiContractSellEnabled = setting;
    }

    function setMEVBlocks(uint256 _mevBlocks) external onlyOwner {
        require(_mevBlocks < 8,"Cannot make _mevBlocks more that 8");
        mevBlocks = _mevBlocks;
    }

    // clear state for individual bots
    function clearMEVBot(address bot) external onlyOwner {
        botsOfMEV[bot] = false;
    }
    
    // clear state for bulk bots
    function removeMEVBots(address[] calldata bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            botsOfMEV[bots_[i]] = false;
        }
    }

    // set state for whitelisted address to pass mev checks
    function setWhitelist(address addr, bool state) external onlyOwner {
		whitelistedMEV[addr] = state;
	}

        // clear state for individual bots
    function clearLaunchPenaltyState(address penaltyAddress) external onlyOwner {
        launchPenaltyHolder[penaltyAddress] = false;
        launchPenaltySellFee[penaltyAddress] = 0;
    }

    function updateMaxBuyTokenAmount(uint256 newMaxBuy) external onlyOwner {
        require(
            newMaxBuy >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max buy token amount lower than 0.5%"
        );
        require(
            newMaxBuy <= ((totalSupply() * 2) / 100) / 1e18,
            "Cannot set max buy token amount higher than 2%"
        );
        maxBuyTokenAmount = newMaxBuy * (10**18);
        emit UpdatedMaxBuyTokenAmount(maxBuyTokenAmount);
    }

    function updateMaxSellTokenAmount(uint256 newMaxSell) external onlyOwner {
        require(
            newMaxSell >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max sell token amount lower than 0.5%"
        );
        require(
            newMaxSell <= ((totalSupply() * 2) / 100) / 1e18,
            "Cannot set max sell token amount higher than 2%"
        );
        maxSellTokenAmount = newMaxSell * (10**18);
        emit UpdatedMaxSellTokenAmount(maxSellTokenAmount);
    }

    function updateMaxWalletTokenAmount(uint256 newMaxWallet) external onlyOwner {
        require(
            newMaxWallet >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max wallet token amount lower than 0.5%"
        );
        require(
            newMaxWallet <= ((totalSupply() * 5) / 100) / 1e18,
            "Cannot set max wallet token amount higher than 5%"
        );
        maxWalletTokenAmount = newMaxWallet * (10**18);
        emit UpdatedMaxWalletTokenAmount(maxWalletTokenAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newSwapAmount) external onlyOwner {
        require(
            newSwapAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newSwapAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newSwapAmount;
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

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
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

    function updateBuyFees(
        uint256 _devFee,
        uint256 _marketingFee,
        uint256 _rewardsFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyDevFee = _devFee;
        buyMarketingFee = _marketingFee;
        buyRewardsFee = _rewardsFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;
        require(buyTotalFees <= 15, "Must keep buy fees at 15% or less");
    }

    function updateSellFees(
        uint256 _devFee,
        uint256 _marketingFee,
        uint256 _rewardsFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellDevFee = _devFee;
        sellMarketingFee = _marketingFee;
        sellRewardsFee = _rewardsFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;
        require(sellTotalFees <= 25, "Must keep sell fees at 25% or less");
    }

    function taxToNormal() external onlyOwner {
        buyDevFee = normalBuyDevFee;
        buyMarketingFee = normalBuyMarketingFee;
        buyRewardsFee = normalBuyRewardsFee;
        buyLiquidityFee = normalBuyLiquidityFee;
        buyBurnFee = normalBuyBurnFee;
        buyTotalFees = buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;

        sellDevFee = normalSellDevFee;
        sellMarketingFee = normalSellMarketingFee;
        sellRewardsFee = normalSellRewardsFee;
        sellLiquidityFee = normalSellLiquidityFee;
        sellBurnFee = normalSellBurnFee;
        sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        bool _isBuying = automatedMarketMakerPairs[from] && to != address(dexRouter);
        bool _isSelling = automatedMarketMakerPairs[to] && from != address(this);
        bool _mevBot = false;

        // anti MEV mode blocks trades from the same sender more often than every x blocks
        // if a mev bot is detected then they are added to the botsOfMEV list and not able to sell
        // while unlikely, this can block multi block mev from happening, and trap the mev bot buy
        if (antiMEVEnabled) {
            if (_isBuying) {
                // flag next block allowed for trading
                blocksOfTrades[to] = block.number;
                //blocksOfTrades[msg.sender] = block.number;

            } else if (_isSelling && !whitelistedMEV[from]) {
                // check to see if seller has been flagged as a mev bot previously and block the sell :)
                // mev bot status can be manually removed by owner but not set for safety
                if ((block.number < (blocksOfTrades[from] + mevBlocks)) && (block.number < (blocksOfTrades[msg.sender] + mevBlocks))) {
                    if (!botsOfMEV[from] || !botsOfMEV[msg.sender]) {
                        botsOfMEV[from] = true;
                        botsOfMEV[msg.sender] = true;
                    }
                    _mevBot = true;
                }

                if (botsOfMEV[from] && botsOfMEV[msg.sender]) {
                    _mevBot = true;
                }

                if (from == msg.sender && antiContractSellEnabled) {
                    botsOfMEV[from] = true;
                    botsOfMEV[msg.sender] = true;
                    _mevBot = true;
                }
            }  
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                //when buy
                if (_isBuying && !_isExcludedMaxTransactionAmount[to]) 
                {
                    require(
                        amount <= maxBuyTokenAmount,
                        "Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletTokenAmount,
                        "Max Wallet Exceeded"
                    );
                }
                //when sell
                else if (_isSelling && !_isExcludedMaxTransactionAmount[from]) 
                {
                    require(
                        amount <= maxSellTokenAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } 
                // else simple transfer
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletTokenAmount,
                        "Max Wallet Exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool okToSwapBack = contractTokenBalance >= swapTokensAtAmount;

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee we do not take any fees
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            uint256 fees = 0;
            // early buying bot/sniper penalty.
            if (launchPenaltyPeriod) {
                if (feesLastUpdated < block.number) {
                    updateEarlyPenaltyFees();
                }
                if (_isBuying && !launchPenaltyHolder[to]) {
                    launchPenaltyHolder[to] = true;
                    launchPenaltySellFee[to] = sellTotalFees;
                }
            }

            // on sell
            if (_isSelling) {
                if (okToSwapBack && swapBackEnabled && !swapping) {
                    swapping = true;
                    swapBackAndBurn();
                    swapping = false;
                }
            // on sell if launch penalty holder then tax according to
            // the sell taxes at the time of the eoriginal buy
                if (launchPenaltyHolder[from]) {
                    uint _penaltySellFee = launchPenaltySellFee[from];
                    fees = (amount * _penaltySellFee) / 100;
                    tokensForDev += fees;
                }
                // on normal sell
                else if (sellTotalFees > 0) {
                    fees = (amount * sellTotalFees) / 100;
                    tokensForDev += (fees * sellDevFee) / sellTotalFees;
                    tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                    tokensForRewards += (fees * sellRewardsFee) / sellTotalFees;
                    tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                    tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
                }
            }
            // on buy
            else if (_isBuying && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForRewards += (fees * buyRewardsFee) / buyTotalFees;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
            } 
            // on Transfer
            else {
                // if from wallet has penalties then we also apply to the 
                // wallet being transferred to
                if (launchPenaltyHolder[from]) {
                    launchPenaltyHolder[to] = true;
                    launchPenaltySellFee[to] = launchPenaltySellFee[from];
                }
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;

        }

        if (!_mevBot || (_mevBot && _isBuying)) {
            super._transfer(from, to, amount);
        }
        
    }

    function updateEarlyPenaltyFees() private {
        if (block.number == launchBlock) {
            buyDevFee = launchBuyDevFees[0];
            buyMarketingFee = launchBuyMarketingFees[0];
            buyRewardsFee = launchBuyRewardsFees[0];
            buyLiquidityFee = launchBuyLiquidityFees[0];
            buyBurnFee = launchBuyBurnFees[0];
            buyTotalFees = buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;

            sellDevFee = launchSellDevFees[0];
            sellMarketingFee = launchSellMarketingFees[0];
            sellRewardsFee = launchSellRewardsFees[0];
            sellLiquidityFee = launchSellLiquidityFees[0];
            sellBurnFee = launchSellBurnFees[0];
            sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;
        } else if (block.number < blockForLaunchPenaltyEnd) {
            //BSL = (block.number - launchBlock); // BlocksSinchLaunch
            BSL = (block.number - launchBlock) <= 9 ? (block.number - launchBlock) : 9;

            buyDevFee = launchBuyDevFees[BSL] > normalBuyDevFee ? launchBuyDevFees[BSL] : normalBuyDevFee;
            buyMarketingFee = launchBuyMarketingFees[BSL] > normalBuyMarketingFee ? launchBuyMarketingFees[BSL] : normalBuyMarketingFee;
            buyRewardsFee = launchBuyRewardsFees[BSL] > normalBuyRewardsFee ? launchBuyRewardsFees[BSL] : normalBuyRewardsFee;
            buyLiquidityFee = launchBuyLiquidityFees[BSL] > normalBuyLiquidityFee ? launchBuyLiquidityFees[BSL] : normalBuyLiquidityFee;
            buyBurnFee = launchBuyBurnFees[BSL] > normalBuyBurnFee ? launchBuyBurnFees[BSL] : normalBuyBurnFee;
            buyTotalFees = buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;

            sellDevFee = launchSellDevFees[BSL] > normalSellDevFee ? launchSellDevFees[BSL] : normalSellDevFee;
            sellMarketingFee = launchSellMarketingFees[BSL] > normalSellMarketingFee ? launchSellMarketingFees[BSL] : normalSellMarketingFee;
            sellRewardsFee = launchSellRewardsFees[BSL] > normalSellRewardsFee ? launchSellRewardsFees[BSL] : normalSellRewardsFee;
            sellLiquidityFee = launchSellLiquidityFees[BSL] > normalSellLiquidityFee ? launchSellLiquidityFees[BSL] : normalSellLiquidityFee;
            sellBurnFee = launchSellBurnFees[BSL] > normalSellBurnFee ? launchSellBurnFees[BSL] : normalSellBurnFee;
            sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;
        } else if ((block.number >= blockForLaunchPenaltyEnd) && launchPenaltyPeriod) {
            buyDevFee = normalBuyDevFee;
            buyMarketingFee = normalBuyMarketingFee;
            buyRewardsFee = normalBuyRewardsFee;
            buyLiquidityFee = normalBuyLiquidityFee;
            buyBurnFee = normalBuyBurnFee;
            buyTotalFees = buyDevFee + buyMarketingFee + buyRewardsFee + buyLiquidityFee + buyBurnFee;

            sellDevFee = normalSellDevFee;
            sellMarketingFee = normalSellMarketingFee;
            sellRewardsFee = normalSellRewardsFee;
            sellLiquidityFee = normalSellLiquidityFee;
            sellBurnFee = normalSellBurnFee;
            sellTotalFees = sellDevFee + sellMarketingFee + sellRewardsFee + sellLiquidityFee + sellBurnFee;
            launchPenaltyPeriod = false;

        }
        feesLastUpdated = block.number;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityAndBurn(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapBackAndBurn() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (tokensForBurn > 0) {
            if (tokensForBurn > contractBalance) {
                tokensForBurn = contractBalance;
            }
            _burnWithEvent(address(this), tokensForBurn);
            contractBalance = balanceOf(address(this));
        }

        uint256 totalTokensToSwap = tokensForDev +
            tokensForMarketing + 
            tokensForRewards +
            tokensForLiquidity;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // limit max number of tokens to swap this 
        // occurs if no sells have happened in a while
        // limiting it this low ensure that no slippage
        //  issues or "router clogs" happen
        if (contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForDev = (ethBalance * tokensForDev) / totalTokensToSwap;
        uint256 ethForMarketing = (ethBalance * tokensForMarketing) / totalTokensToSwap;
        uint256 ethForRewards = (ethBalance * tokensForRewards) / totalTokensToSwap;

        uint256 ethForLiquidity = ethBalance - ethForDev - ethForMarketing - ethForRewards;

        tokensForDev = 0;
        tokensForMarketing = 0;
        tokensForRewards = 0;
        tokensForLiquidity = 0;
        tokensForBurn = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidityAndBurn(liquidityTokens, ethForLiquidity);
        }

        
        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");
        (success, ) = address(rewardsWallet).call{value: ethForRewards}("");
        (success, ) = address(devWallet).call{value: address(this).balance}("");

    }

    function burn(uint256 _amount) external {
        _burnWithEvent(msg.sender, _amount);
    }

    function _burnWithEvent(address _user, uint256 _amount) internal {
        _burn(_user, _amount);
        emit Burn(_user, _amount);
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(
            _token != address(this) || !tradingActive,
            "Can't withdraw native tokens while trading is active"
        );
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function setDevWallet(address _devWallet) external onlyOwner
    {
        require(_devWallet != address(0),"_devWallet address cannot be 0");
        devWallet = payable(_devWallet);
        emit UpdatedDevWallet(_devWallet);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != address(0),"_marketingWallet address cannot be 0");
        marketingWallet = payable(_marketingWallet);
        emit UpdatedMarketingWallet(_marketingWallet);
    }

    function setRewardsWallet(address _rewardsWallet) external onlyOwner {
        require(_rewardsWallet != address(0),"_rewardsWallet address cannot be 0");
        rewardsWallet = payable(_rewardsWallet);
        emit UpdatedRewardsWallet(_rewardsWallet);
    }

    // force Swap back and burn if slippage issues.
    function forceSwapBackAndBurn() external onlyOwner {
        require(
            balanceOf(address(this)) >= swapTokensAtAmount,
            "Can only swap when token amount is at or higher than swapTokensAtAmount"
        );
        swapping = true;
        swapBackAndBurn();
        swapping = false;
        emit OwnerForcedSwapBackAndBurn(block.timestamp);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapBackEnabled(bool enabled) external onlyOwner {
        swapBackEnabled = enabled;
    }

    // remove trading limits
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function restoreLimits() external onlyOwner {
        limitsInEffect = true;
    }

    // combined function to autmatically add and create the initial LP and enable trading
    function addLPEnableTradingWithLaunchPenalty(uint256 blocksForPenalty, bool confirmLaunch) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty <= 10,"Cannot make penalty blocks more than 10");
        require(confirmLaunch, "Please confirm go time!");

        // add the liquidity
        require(address(this).balance > 0,"Must have ETH on contract to launch");
        require(balanceOf(address(this)) > 0,"Must have Tokens on contract to launch");

        //standard enable trading action
        tradingActive = true;
        swapBackEnabled = true;
        launchBlock = block.number;
        blockForLaunchPenaltyEnd = blocksForPenalty > 0 ? launchBlock + blocksForPenalty : launchBlock;
        penaltyBlocks = blocksForPenalty > 0 ? blocksForPenalty : 0;
        launchPenaltyPeriod = blocksForPenalty > 0 ? true : false;
        emit EnabledTrading();

        _approve(address(this), address(dexRouter), balanceOf(address(this)));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    // add and create initial LP
    function addLP(bool _addLP) external onlyOwner {
        require(_addLP, "Please confirm add LP");

        // add the liquidity
        require(address(this).balance > 0,"Must have ETH on contract to launch");
        require(balanceOf(address(this)) > 0,"Must have Tokens on contract to launch");

        _approve(address(this), address(dexRouter), balanceOf(address(this)));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    // classic enable trading with no launch penalty period:
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");

        //standard enable trading action
        tradingActive = true;
        swapBackEnabled = true;
        launchBlock = block.number;
        penaltyBlocks = 0;
        blockForLaunchPenaltyEnd = launchBlock;
        launchPenaltyPeriod = false;
        emit EnabledTrading();
    }

}