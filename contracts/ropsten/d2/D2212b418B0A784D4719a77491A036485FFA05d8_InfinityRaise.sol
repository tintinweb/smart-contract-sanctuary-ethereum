// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./token/ERC20.sol";
import "./token/ERC1363/ERC1363.sol";
import "./token/ERC2612/ERC2612.sol";
import "./token/extensions/ERC20Burnable.sol";
import "./token/extensions/ERC20TokenRecover.sol";
import "./interfaces/IDEXRouter.sol";
import "./interfaces/IDEXFactory.sol"; 
import "./interfaces/IDEXPair.sol"; 
import "./IInfinityRaise.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IInfinityRaiseDividendTracker.sol";


contract InfinityRaise is ERC20, ERC1363, ERC2612, ERC20Burnable, ERC20TokenRecover, IInfinityRaise {
    
    mapping(address => bool) public override dexRouters;
    // store addresses that are automatic market maker (dex) pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public override automatedMarketMakerPairs;

    IDEXRouter public override defaultDexRouter;
    address public override defaultPair;
    

    address public override dividendToken; 
    // to accommodate lock or unlock balance by bridge
    address public bridgeVault;
    address public bridge;
    address public override marketingWallet; 
    address public override vault;
    address public override liquidityWallet;
    address public busd;
    IInfinityRaiseDividendTracker public override dividendTracker;
    IInfinityRaiseDividendTracker public  oldDividendTracker;

    bool public override transfersEnabled = false;
    bool private isSwappingFees;
    bool public dexTradesEnabled = false;

    // Supply and amounts
    // 100 millions (this will also be the total supply as there is not public mint function)
    uint256 private _startSupply = 100000000 * (10**18);
    uint256 public override swapTokensAtAmount = 10 * (10**18);
    uint256 public override maxWalletToken =  2000000 * (10**18); // 2% of total supply

    // fees (from a total of 10000)
    uint256 public override buyFeesCollected = 0;
    uint256 public override buyDividendFee = 100;
    uint256 public override buyLiquidityFee = 100;
    uint256 public override buyMarketingFee = 500;
    uint256 public override buyVaultFee = 200;
    uint256 public override buyTotalFees = buyDividendFee + buyLiquidityFee + buyMarketingFee + buyVaultFee;

    uint256 public override sellFeesCollected = 0;
    uint256 public override sellDividendFee = 100;
    uint256 public override sellLiquidityFee = 100;
    uint256 public override sellMarketingFee = 500;
    uint256 public override sellVaultFee = 200;
    uint256 public override sellTotalFees = sellDividendFee + sellLiquidityFee + sellMarketingFee + sellVaultFee;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public override gasForProcessing = 300000;

    // white listed adresses (excluded from fees and dividends)
    // these addresses can also make transfers before presale is over
    mapping(address => bool) public override whitelistedAddresses;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    bool private nameChanged = false;

    event LogSetBridge(address indexed setter, address bridge);
    event LogLockByBridge(address indexed account, uint256 tAmount);
    event LogUnlockByBridge(address indexed account, uint256 tAmount);
    event LogUpdateDividendToken(address newToken);
    event LogMarketingWalletUpdated(address _marketingWallet);
    event LogVaultUpdated(address _vault);

    constructor(
        address _routerAddress,
        address _dividendToken,
        address _marketingWallet,
        address _vault,
        address _bridgeVault,
        address _busd
    ) ERC2612("InfinityRaise", "IRAISE") {
        IDEXRouter _dexRouter = IDEXRouter(_routerAddress);
        dividendToken = _dividendToken;
        marketingWallet = _marketingWallet;
        liquidityWallet = owner();
        vault = _vault;
        bridgeVault = _bridgeVault;
        busd = _busd;

        defaultDexRouter = _dexRouter;
        dexRouters[_routerAddress] = true;
        defaultPair = IDEXFactory(_dexRouter.factory()).createPair(address(this), busd);
        
        _setAutomatedMarketMakerPair(defaultPair, true);
        //_mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again
        _mint(owner(), _startSupply);
    }

    function initializeDividendTracker(IInfinityRaiseDividendTracker _dividendTracker) public override onlyOwner {
        require(address(dividendTracker) == address(0), "InfinityRaise: Dividend tracker already initialized");
        dividendTracker = _dividendTracker;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(defaultPair));
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(defaultDexRouter));
        dividendTracker.excludeFromDividends(address(bridgeVault));

        // whitlist wallets f.e. owner wallet to send tokens before presales are over
        setWhitelistAddress(address(this), true);
        setWhitelistAddress(owner(), true);
        setWhitelistAddress(marketingWallet, true);
    }

    receive() external payable {}

    //== BEP20 owner function ==
    function getOwner() public view override returns (address) {
        return owner();
    }

    function updateDividendToken(address newToken, address newDividendTracker) external onlyOwner{
        require(dividendToken != newToken, "Alreday set to this address");
        require(newToken != address(0), "InvalidAddress");
        require(newDividendTracker != address(0), "InvalidAddress");
        oldDividendTracker = dividendTracker;
        dividendToken = newToken;
        updateDividendTracker(newDividendTracker);
        emit LogUpdateDividendToken(newToken);
    }

    function updateNameAndSymbol(string memory name_, string memory symbol_) external onlyOwner {
        require(!nameChanged, "InfinityRaise: Name already changed");
        _name = name_;
        _symbol = symbol_;
        nameChanged = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1363, ERC2612) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        override(ERC20TokenRecover, IERC20TokenRecover)
        onlyOwner
    {
        require(tokenAddress != address(this), "Cannot retrieve InfinityRaises");
        super.recoverERC20(tokenAddress, tokenAmount);
    }

    function setWhitelistAddress(address _whitelistAddress, bool whitelisted) public override onlyOwner {
        whitelistedAddresses[_whitelistAddress] = whitelisted;
        excludeFromFees(_whitelistAddress, whitelisted);
        if (whitelisted) {
            dividendTracker.excludeFromDividends(_whitelistAddress);
        } else {
            dividendTracker.includeInDividends(_whitelistAddress);
        }
    }

    function updateDividendTracker(address newAddress) public override onlyOwner {
        require(newAddress != address(0), "InfinityRaise: Dividend tracker not yet initialized");
        require(newAddress != address(dividendTracker), "InfinityRaise: The dividend tracker already has that address");

        IInfinityRaiseDividendTracker newDividendTracker = IInfinityRaiseDividendTracker(payable(newAddress));
        require(
            newDividendTracker.getOwner() == address(this),
            "InfinityRaise: The new dividend tracker must be owned by the InfinityRaise token contract"
        );

        dividendTracker = newDividendTracker;
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(defaultPair));
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(defaultDexRouter));
        dividendTracker.excludeFromDividends(address(bridgeVault));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));
    }

    function addNewRouter(address _router, bool makeDefault) external override onlyOwner {
        dexRouters[_router] = true;
        dividendTracker.excludeFromDividends(_router);

        if (makeDefault) {
            emit UpdateDefaultDexRouter(_router, address(defaultDexRouter));
            defaultDexRouter = IDEXRouter(_router);
            defaultPair = IDEXFactory(defaultDexRouter.factory()).createPair(address(this), defaultDexRouter.WETH());
            _setAutomatedMarketMakerPair(defaultPair, true);
        }
    }

    function excludeFromFees(address account, bool excluded) public override onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "InfinityRaise: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludeFromFees(accounts[i], excluded);
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external override onlyOwner {
        require(
            value || pair != defaultPair,
            "InfinityRaise: The default pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "InfinityRaise: Automated market maker pair is already set to that value"
        );

        automatedMarketMakerPairs[pair] = value;
        if (value && address(dividendTracker) != address(0)) dividendTracker.excludeFromDividends(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMinTokenBalance(uint256 minTokens) external override onlyOwner {
        dividendTracker.updateMinTokenBalance(minTokens);
    }

    function updateMarketingWallet(address newMarketingWallet) external override onlyOwner {
        require(newMarketingWallet != marketingWallet, "InfinityRaise: The Marketing wallet is already this address");
        setWhitelistAddress(newMarketingWallet, true);
        marketingWallet = newMarketingWallet;
        emit LogMarketingWalletUpdated(newMarketingWallet);
    }

    function updateVault(address newVault) external override onlyOwner {
        require(newVault != vault, "InfinityRaise: The Vault wallet is already this address");
        setWhitelistAddress(newVault, true);
        vault = newVault;
        emit LogVaultUpdated(newVault);
    }

    function updateLiquidityWallet(address newLiquidityWallet) external override onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "InfinityRaise: The liquidity wallet is already this address");
        setWhitelistAddress(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) external override onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "InfinityRaise: gasForProcessing must be between 200,000 and 500,000"
        );
        require(newValue != gasForProcessing, "InfinityRaise: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external override onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view override returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view override returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view override returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) external view override returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) external view override returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        override
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        override
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external override {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external override {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view override returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view override returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    /**
     * Enable or disable transfers, used before presale and on critical problems in or with the token contract
     */
    function setTransfersEnabled(bool enabled) external override onlyOwner {
        require(transfersEnabled != enabled, "Already set to this value");
        transfersEnabled = enabled;
    }

    function setDexTradesEnabled(bool enabled) external onlyOwner {
        require(dexTradesEnabled != enabled, "Already set to this value");
        dexTradesEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _vaultFee
    ) external override onlyOwner {
        buyDividendFee = _dividendFee;
        buyLiquidityFee = _liquidityFee;
        buyMarketingFee = _marketingFee;
        buyVaultFee = _vaultFee;
        buyTotalFees = buyDividendFee + buyLiquidityFee + buyMarketingFee + buyVaultFee;
        require(buyTotalFees <= 5000, "Max fee  is 50%");
    }

    function updateSellFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _vaultFee
    ) external override onlyOwner {
        sellDividendFee = _dividendFee;
        sellLiquidityFee = _liquidityFee;
        sellMarketingFee = _marketingFee;
        sellVaultFee = _vaultFee;
        sellTotalFees = sellDividendFee + sellLiquidityFee + sellMarketingFee + sellVaultFee;
        require(sellTotalFees <= 5000, "Max fee is 50%");
    }

    function updateSwapTokensAtAmount(uint256 _swapTokensAtAmount) external override onlyOwner {
        require(_swapTokensAtAmount > 0, "InfinityRaise: Amount should be higher then 0");
        require(_swapTokensAtAmount <= 10 * (10**6) * (10**18), "InfinityRaise: Max should be at 10%");
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // when NOT from or to owner, to dex pair
        // check if target wallet exeeds the maxWalletPAirs
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != 0x000000000000000000000000000000000000dEaD &&
            !automatedMarketMakerPairs[to]
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "InfinityRaise: Exceeds maximum wallet token amount."
            );
        }

        if(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]){
            require(dexTradesEnabled = true, "Dex trades disabled");
        }

        // only whitelisted addresses can make transfers when transfers are disabled
        if (!transfersEnabled) {
            require(whitelistedAddresses[from], "InfinityRaise: Transfering is disabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        // take fee
        amount = collectFees(from, to, amount);

        if (address(dividendTracker) != address(0)) {
            try dividendTracker.setBalance(payable(from), balanceOf(from) - amount) {} catch {}
            try dividendTracker.setBalance(payable(to), balanceOf(to) + amount) {} catch {}
        }

        // swap fees before transfer has happened and after dividend balances are done
        swapFeesIfAmountIsReached(from, to);

        super._transfer(from, to, amount);

        if (address(dividendTracker) != address(0) && !isSwappingFees) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {}
        }
    }

    function collectFees(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        if (!isSwappingFees && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 fees;
            if (automatedMarketMakerPairs[from]) {
                fees = (amount * buyTotalFees) / 10000;
                buyFeesCollected += fees;
            } else if (automatedMarketMakerPairs[to]) {
                fees = (amount * sellTotalFees) / 10000;
                sellFeesCollected += fees;
            }

            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }
        return amount;
    }

    function swapFeesIfAmountIsReached(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (
            contractTokenBalance >= swapTokensAtAmount &&
            !isSwappingFees &&
            !automatedMarketMakerPairs[from] && // do not swap fees on buys
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            isSwappingFees = true;

            buyFeesCollected = (contractTokenBalance / (buyFeesCollected + sellFeesCollected)) * buyFeesCollected;
            sellFeesCollected = contractTokenBalance - buyFeesCollected;

            uint256 marketingTokens = (buyFeesCollected * buyMarketingFee) / buyTotalFees;
            marketingTokens += (sellFeesCollected * sellMarketingFee) / sellTotalFees;
            if (marketingTokens > 0) swapAndSendToFeeMarketing(marketingTokens);

            uint256 vaultTokens = (buyFeesCollected * buyVaultFee) / buyTotalFees;
            vaultTokens += (sellFeesCollected * sellVaultFee) / sellTotalFees;
            if (vaultTokens > 0) swapAndSendToFeeVault(vaultTokens);


            uint256 swapTokens = (buyFeesCollected * buyLiquidityFee) / buyTotalFees;
            swapTokens = (sellFeesCollected * sellLiquidityFee) / sellTotalFees;
            if (swapTokens > 0) swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            if (sellTokens > 0) swapAndSendDividends(sellTokens);

            buyFeesCollected = 0;
            sellFeesCollected = 0;

            isSwappingFees = false;
        }
    }

    function swapAndSendToFeeMarketing(uint256 tokens) private {
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBUSD(tokens);
        uint256 newBNBBalance = address(this).balance - initialBNBBalance;
        payable(marketingWallet).transfer(newBNBBalance);
    }

    function swapAndSendToFeeVault(uint256 tokens) private {
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBUSD(tokens);
        uint256 newBNBBalance = address(this).balance - initialBNBBalance;
        payable(vault).transfer(newBNBBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForBUSD(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBUSD(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = busd;

        _approve(address(this), address(defaultDexRouter), tokenAmount);

        // make the swap
        defaultDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(defaultDexRouter), tokenAmount);

        // add the liquidity
        defaultDexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IERC20(dividendToken).balanceOf(address(this));
        bool success = IERC20(dividendToken).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of weth -> Dividend token
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = defaultDexRouter.WETH();
        path[2] = dividendToken;

        _approve(address(this), address(defaultDexRouter), tokenAmount);

        // make the swap
        defaultDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of dividendToken
            path,
            recipient,
            block.timestamp
        );
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "Only bridge can perform this action");
        _;
    }

    function setBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Zero Address");
        require(bridge != _bridge, "Same Bridge!");
        bridge = _bridge;

        emit LogSetBridge(msg.sender, bridge);
    }

    /**
     * @dev need approval from account
     */
    function lock(address account, uint256 amount) external onlyBridge {
        require(account != address(0), "Zero address");
        require(amount > 0, "Lock amount must be greater than zero");
        //require(amount <= balanceOf(account), "Insufficient funds");
        require(super.allowance(account, _msgSender()) >= amount, "ERC20: transfer amount exceeds allowance");

        
        super.transferFrom(account, bridgeVault, amount);
       

        emit LogLockByBridge(account, amount);
    }

    /**
     * @dev no need approval, because bridgeVault balance is controlled by EMPIRE
     */
    function unlock(address account, uint256 amount) external onlyBridge {
        require(account != address(0), "Zero address");
        require(amount > 0, "Unlock amount must be greater than zero");
        require(amount <= balanceOf(bridgeVault), "Insufficient funds");

        super.transferFrom(bridgeVault, account, amount);
        
        emit LogUnlockByBridge(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC1363.sol";
import "./IERC1363Receiver.sol";
import "./IERC1363Spender.sol";

/**
 * @title ERC1363
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of an ERC1363 interface
 */
abstract contract ERC1363 is ERC165, ERC20, IERC1363 {
    using Address for address;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1363).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on recipient.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(address recipient, uint256 amount) public virtual override returns (bool) {
        return transferAndCall(recipient, amount, "");
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on recipient.
     * @param recipient The address to transfer to
     * @param amount The amount to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        transfer(recipient, amount);
        require(_checkAndCallTransfer(_msgSender(), recipient, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on recipient.
     * @param sender The address which you want to send tokens from
     * @param recipient The address which you want to transfer to
     * @param amount The amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return transferFromAndCall(sender, recipient, amount, "");
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on recipient.
     * @param sender The address which you want to send tokens from
     * @param recipient The address which you want to transfer to
     * @param amount The amount of tokens to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        transferFrom(sender, recipient, amount);
        require(_checkAndCallTransfer(sender, recipient, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on recipient.
     * @param spender The address allowed to transfer to
     * @param amount The amount allowed to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint256 amount) public virtual override returns (bool) {
        return approveAndCall(spender, amount, "");
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on recipient.
     * @param spender The address allowed to transfer to.
     * @param amount The amount allowed to be transferred.
     * @param data Additional data with no specified format.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        approve(spender, amount);
        require(_checkAndCallApprove(spender, amount, data), "ERC1363: _checkAndCallApprove reverts");
        return true;
    }

    /**
     * @dev Internal function to invoke `onTransferReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param sender address Representing the previous owner of the given token value
     * @param recipient address Target address that will receive the tokens
     * @param amount uint256 The amount mount of tokens to be transferred
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!recipient.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data);
        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);
    }

    /**
     * @dev Internal function to invoke `onApprovalReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallApprove(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data);
        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../ERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2612.sol';

/**
 * Implementation adapted from
 * https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
 */
abstract contract ERC2612 is ERC165, ERC20, IERC2612 {
    mapping(address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 public immutable TRANSFER_TYPEHASH =
        keccak256('Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 public override DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name_)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC2612).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Setting the version as a function so that it can be overriden
     */
    function version() public pure virtual returns (string memory) {
        return '1';
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        verifyPermit(PERMIT_TYPEHASH, owner, spender, value, deadline, v, r, s);
        _approve(owner, spender, value);
    }

    function transferWithPermit(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        verifyPermit(TRANSFER_TYPEHASH, owner, to, value, deadline, v, r, s);
        _transfer(owner, to, value);
        return true;
    }

    function verifyPermit(
        bytes32 typehash,
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, 'ERC20Permit: Expired permit');

        bytes32 hashStruct = keccak256(abi.encode(typehash, owner, to, value, nonces[owner]++, deadline));

        require(
            verifyEIP712(owner, hashStruct, v, r, s) || verifyPersonalSign(owner, hashStruct, v, r, s),
            'ERC20Permit: invalid signature'
        );
    }

    function verifyEIP712(
        address owner,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }

    function verifyPersonalSign(
        address owner,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }

    /**
     * @dev Builds a prefixed hash to mimic the behavior of eth_sign.
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../ERC20.sol";
import "../interfaces/IERC20Burnable.sol";

/**
 * @dev Based on @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol
 */
abstract contract ERC20Burnable is Context, ERC20, IERC20Burnable {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IERC20TokenRecover.sol';

/**
 * @title ERC20TokenRecover
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
contract ERC20TokenRecover is Ownable, IERC20TokenRecover {
    using SafeERC20 for IERC20;

    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual override onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) public virtual override onlyOwner {
        (bool sent, ) = owner().call{value: amount}('');
        require(sent, 'ERC20TokenRecover: SENDING_ETHER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Supports the Uniswap V1 + V2 structure
 */

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDEXPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IDEXRouter.sol";
import "./token/interfaces/IBEP20.sol";
import "./token/ERC1363/IERC1363.sol";
import "./token/ERC2612/IERC2612.sol";
import "./token/interfaces/IERC20Burnable.sol";
import "./token/interfaces/IERC20TokenRecover.sol";
import "./IInfinityRaiseDividendTracker.sol";

interface IInfinityRaise is IBEP20, IERC1363, IERC2612, IERC20Burnable, IERC20TokenRecover {
    function dexRouters(address router) external view returns (bool);

    // store addresses that are automatic market maker (dex) pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    function automatedMarketMakerPairs(address pair) external view returns (bool);

    function defaultDexRouter() external view returns (IDEXRouter);

    function defaultPair() external view returns (address);

    function dividendToken() external view returns (address);

    function marketingWallet() external view returns (address);

    function vault() external view returns (address);

    function liquidityWallet() external view returns (address);

    function dividendTracker() external view returns (IInfinityRaiseDividendTracker);

    function transfersEnabled() external view returns (bool);

    // Supply and amounts
    function swapTokensAtAmount() external view returns (uint256);

    function maxWalletToken() external view returns (uint256);

    // fees (from a total of 10000)
    function buyFeesCollected() external view returns (uint256);

    function buyDividendFee() external view returns (uint256);

    function buyLiquidityFee() external view returns (uint256);

    function buyMarketingFee() external view returns (uint256);

    function buyVaultFee() external view returns (uint256);

    function sellVaultFee() external view returns (uint256);

    function buyTotalFees() external view returns (uint256);

    function sellFeesCollected() external view returns (uint256);

    function sellDividendFee() external view returns (uint256);

    function sellLiquidityFee() external view returns (uint256);

    function sellMarketingFee() external view returns (uint256);

    function sellTotalFees() external view returns (uint256);

    function gasForProcessing() external view returns (uint256);

    // white listed adresses (excluded from fees and dividends)
    // these addresses can also make transfers before presale is over
    function whitelistedAddresses(address account) external view returns (bool);

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateDefaultDexRouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event FixedSaleBuy(
        address indexed account,
        uint256 indexed amount,
        bool indexed earlyParticipant,
        uint256 numberOfBuyers
    );

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    function initializeDividendTracker(IInfinityRaiseDividendTracker _dividendTracker) external;

    function setWhitelistAddress(address _whitelistAddress, bool whitelisted) external;

    function updateDividendTracker(address newAddress) external;

    function addNewRouter(address _router, bool makeDefault) external;

    function excludeFromFees(address account, bool excluded) external;

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;

    function updateMinTokenBalance(uint256 minTokens) external;

    function updateMarketingWallet(address newVault1) external;

    function updateVault(address newVault2) external;

    function updateLiquidityWallet(address newLiquidityWallet) external;

    function updateGasForProcessing(uint256 newValue) external;

    function updateClaimWait(uint256 claimWait) external;

    function getClaimWait() external view returns (uint256);

    function getTotalDividendsDistributed() external view returns (uint256);

    function isExcludedFromFees(address account) external view returns (bool);

    function withdrawableDividendOf(address account) external view returns (uint256);

    function dividendTokenBalanceOf(address account) external view returns (uint256);

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function processDividendTracker(uint256 gas) external;

    function claim() external;

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfDividendTokenHolders() external view returns (uint256);

    /**
     * Enable or disable transfers, used before presale and on critical problems in or with the token contract
     */
    function setTransfersEnabled(bool enabled) external;

    function updateBuyFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _gameVaultFee,
        uint256 _safetyVaultFee
    ) external;

    function updateSellFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _gameVaultFee,
        uint256 _safetyVaultFee
    ) external;

    function updateSwapTokensAtAmount(uint256 _swapTokensAtAmount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./token/interfaces/IBEP20.sol";
import "./token/interfaces/IDividendPayingTokenInterface.sol";
import "./token/interfaces/IDividendPayingTokenOptionalInterface.sol";
import "./token/interfaces/IERC20TokenRecover.sol";

interface IInfinityRaiseDividendTracker is
    IBEP20,
    IDividendPayingTokenInterface,
    IDividendPayingTokenOptionalInterface,
    IERC20TokenRecover
{
    function lastProcessedIndex() external view returns (uint256);

    function excludedFromDividends(address account) external view returns (bool);

    function lastClaimTimes(address account) external view returns (uint256);

    function deployer() external view returns (address);

    function claimWait() external view returns (uint256);

    function minimumTokenBalanceForDividends() external view returns (uint256);

    event ExcludeFromDividends(address indexed account);
    event IncludedInDividends(address indexed account);

    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    function excludeFromDividends(address account) external;

    function includeInDividends(address account) external;

    function updateClaimWait(uint256 newClaimWait) external;

    function updateMinTokenBalance(uint256 minTokens) external;

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfTokenHolders() external view returns (uint256);

    function getAccount(address _account)
        external
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        );

    function getAccountAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function ensureBalance(bool _process) external;

    function ensureBalanceForUsers(address payable[] memory accounts, bool _process) external;

    function ensureBalanceForUser(address payable account, bool _process) external;

    function setBalance(address payable account, uint256 newBalance) external;

    function process(uint256 gas)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function processAccount(address payable account, bool automatic) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363 Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for a Payable Token contract as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363 {
    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `recipient`
     * @return true unless throwing
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `recipient`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {
    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address operator,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363Spender Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Spender {
    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param sender address The address which called `approveAndCall` function
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))` unless throwing
     */
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Sets `value` as allowance of `spender` account over `owner` account's token,
     * given `owner` account's signed approval.
     * Emits {Approval} event.
     * Requirements:
     *   - `deadline` must be timestamp in future.
     *   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over
     *      EIP712-formatted function arguments.
     *   - the signature must use `owner` account's current nonce (see {nonces}).
     *   - the signer cannot be zero address and must be `owner` account.
     * For more information on signature format, see
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Same as permit, but also performs a transfer
     */
    function transferWithPermit(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Based on @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol
 */
interface IERC20Burnable {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC20TokenRecover
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
interface IERC20TokenRecover {
    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBEP20 is IERC20, IERC20Metadata {
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendPayingTokenInterface {
    function dividendToken() external view returns(address);

    function totalDividendsDistributed() external view returns(uint256);

    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` can withdraw.
     */
    function dividendOf(address _owner) external view returns (uint256);

    /**
     * @notice Withdraws the ether distributed to the sender.
     * @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` 
     *      SHOULD be 0 after the transfer.
     *      MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
     */
    function withdrawDividend() external;

    function distributeDividends(uint256 amount) external;

    /**
     * @dev This event MUST emit when ether is distributed to token holders.
     * @param from The address which sends ether to this contract.
     * @param weiAmount The amount of distributed ether in wei.
     */
    event DividendsDistributed(address indexed from, uint256 weiAmount);

    /**
     * @dev This event MUST emit when an address withdraws their dividend.
     * @param to The address which withdraws ether from this contract.
     * @param weiAmount The amount of withdrawn ether in wei.
     */
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendPayingTokenOptionalInterface {
    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` can withdraw.
     */
    function withdrawableDividendOf(address _owner) external view returns (uint256);

    /**
     * @notice View the amount of dividend in wei that an address has withdrawn.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` has withdrawn.
     */
    function withdrawnDividendOf(address _owner) external view returns (uint256);

    /**
     * @notice View the amount of dividend in wei that an address has earned in total.
     * @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` has earned in total.
     */
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}