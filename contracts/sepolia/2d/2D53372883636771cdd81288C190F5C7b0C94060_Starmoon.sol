// SPDX-License-Identifier: MIT


pragma solidity ^0.8.11;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./Pausable.sol";


contract Starmoon is ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private _isSwapping;

    SMTDividendTracker public dividendTracker;

    address public liquidityWallet;
    address public marketingWallet = 0xE9AA50c422e9923CD12967245f8c4f43A54009ba;
    address public devWallet = 0x7f80973fA37E9dB9b2e401cea1d89510ea2E25cE;
    address constant private  DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _swapTokensAtAmount = 1 * 10 ** 3 * (10**9); // 0.1% of supply
    uint256 public maxSellTransactionAmount = 1* 10 ** 3 * (10**9); // 0.1% of supply

    uint256 public sellRewardFee = 5;
    uint256 public sellLiquidityFee = 5;
    uint256 public sellMarketingFee = 3;
    uint256 public sellDevFee = 2;

    uint256 public buyRewardFee = 5;
    uint256 public buyLiquidityFee = 5;
    uint256 public buyMarketingFee = 3;
    uint256 public buyDevFee = 2;

    uint256 public totalSellFees;
    uint256 public totalBuyFees;

    uint256 private _marketingCurrentAccumulatedFee;
    uint256 private _devCurrentAccumulatedFee;
    uint256 private _rewardCurrentAccumulatedFee;
    uint256 private _liquidityCurrentAccumulatedFee;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    // addresses that can make transfers before listing
    mapping (address => bool) private _canTransferBeforeTradingIsEnabled;
    bool _presaleAddressIsAdded;

    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public tradingEnabledTimestamp = 1656633600; // 01/07/2022 00:00:00 UTC, will be changed
    // exclude from max sell transaction amount
    mapping (address => bool) private _isExcludedFromMaxTx;
    // exclude from fees 
    mapping (address => bool) private _isExcludedFromFees;
    // exclude from transactions
    mapping(address=>bool) private _isBlacklisted;

    // store addresses that a automatic market maker pairs.
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UniswapV2RouterUpdated(address indexed newAddress, address indexed oldAddress);

    event UniswapV2PairUpdated(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event BlackList(address indexed account, bool isBlacklisted);

    event ExcludeFromMaxTx(address indexed account, bool isExcluded);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    event MaxTxAmountUpdated(uint256 amount);
    event SellFeesUpdated(uint8 rewardFee,uint8 liquidityFee,uint8 marketingFee, uint8 devFee);
    event BuyFeesUpdated(uint8 rewardFee,uint8 liquidityFee,uint8 marketingFee, uint8 devFee);

    event Burn(uint256 amount);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SendHolderDividends(uint256 amount);

    event SendMarketingDividends(uint256 amount);

    event SenddevDividends(uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("Starmoon", "SMT") {

        totalSellFees = sellRewardFee + sellLiquidityFee + sellMarketingFee + sellDevFee;
        totalBuyFees = buyRewardFee + buyLiquidityFee + buyMarketingFee + buyDevFee;

        dividendTracker = new SMTDividendTracker();

        liquidityWallet = owner();
        
        uniswapV2Router = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
        dividendTracker.excludeFromDividends(address(marketingWallet));
        dividendTracker.excludeFromDividends(address(devWallet));

        // exclude from paying fees
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(this), true);

        // exclude from max transaction amount
        excludeFromMaxTx(owner(),true);

        // enable owner to send tokens before listing on PancakeSwap
        _canTransferBeforeTradingIsEnabled[owner()] = true;

        _mint(owner(), 1 * 10 ** 6 * (10**9)); // 1 000 000
    }

    receive() external payable {
    }
    // Called after send stablecoins to holders
    function unpause() public authorized {
        _unpause();
    }
    // Called before send stablecoins to holders
    function pause() public authorized  {
        _pause();
    }
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "SMT: The dividend tracker has already that address");

        SMTDividendTracker newDividendTracker = SMTDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "SMT: The new dividend tracker must be owned by the SMT token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(marketingWallet));
        newDividendTracker.excludeFromDividends(address(devWallet));
        newDividendTracker.excludeFromDividends(address(uniswapV2Pair));

        

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapRouter(address newAddress) public authorized {
        require(newAddress != address(uniswapV2Router), "SMT: The router has already that address");
        emit UniswapV2RouterUpdated(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        dividendTracker.excludeFromDividends(address(newAddress));
    }

    function updateUniswapPair(address newAddress) external authorized {
        require(newAddress != address(uniswapV2Pair), "SMT: The pair address has already that address");
        emit UniswapV2PairUpdated(newAddress, address(uniswapV2Pair));
        uniswapV2Pair = newAddress;
        _setAutomatedMarketMakerPair(newAddress, true);
    }

    function excludeFromFees(address account, bool excluded) public authorized {
        require(_isExcludedFromFees[account] != excluded, "SMT: Account has already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public authorized {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludeFromFees(accounts[i],excluded);
        }
    }

    function excludeFromMaxTx(address account, bool excluded) public authorized {
        require(_isExcludedFromMaxTx[account] != excluded, "SMT: Account has already the value of 'excluded'");
        _isExcludedFromMaxTx[account] = excluded;
        emit ExcludeFromMaxTx(account,excluded);
    }


    function setAutomatedMarketMakerPair(address pair, bool value) public authorized {
        require(pair != uniswapV2Pair, "SMT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SMT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function setBuyFeePercents(uint8 rewardFee,uint8 liquidityFee,uint8 marketingFee, uint8 devFee) external authorized {
        uint8 newTotalBuyFees = rewardFee + liquidityFee + marketingFee + devFee;
        require(newTotalBuyFees <= 15 && newTotalBuyFees >=0,"SMT: Total fees must be between 0 and 15");
        buyRewardFee = rewardFee;
        buyLiquidityFee = liquidityFee;
        buyMarketingFee = marketingFee;
        buyDevFee = devFee;
        totalBuyFees = newTotalBuyFees;
        emit BuyFeesUpdated(rewardFee, liquidityFee, marketingFee, devFee);
    }
    function setSellFeePercents(uint8 rewardFee,uint8 liquidityFee,uint8 marketingFee, uint8 devFee) external authorized {
        uint8 newTotalSellFees = rewardFee + liquidityFee + marketingFee + devFee;
        require(newTotalSellFees <= 15 && newTotalSellFees >=0, "SMT: Total fees must be between 0 and 15");
        sellRewardFee = rewardFee;
        sellLiquidityFee = liquidityFee;
        sellMarketingFee = marketingFee;
        sellDevFee = devFee;
        totalSellFees = newTotalSellFees;
        emit SellFeesUpdated(rewardFee, liquidityFee, marketingFee, devFee);
    }
   
    function setMaxSellTransactionAmount(uint256 amount) external authorized {
        require(amount >= 100 && amount <= 10000, "SMT: Amount must be bewteen 100 and 10000");
        maxSellTransactionAmount = amount *10**9;
        emit MaxTxAmountUpdated(amount);
    }

    function updateGasForProcessing(uint256 newValue) public authorized {
        require(newValue >= 100000 && newValue <= 500000, "SMT: gasForProcessing must be between 100,000 and 500,000");
        require(newValue != gasForProcessing, "SMT: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external authorized {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function isExcludedFromDividends(address account) public view returns(bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }
    function isBlacklisted(address account) public view returns(bool) {
        return _isBlacklisted[account];
    }
    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function setTradingEnabledTimestamp(uint256 timestamp) external authorized {
        require(tradingEnabledTimestamp > block.timestamp, "SMT: Changing the timestamp is not allowed if the listing has already started");
        tradingEnabledTimestamp = timestamp;
    }
    
    function addPresaleAddress(address account) external authorized {
        require(!_canTransferBeforeTradingIsEnabled[account],"SMT: This account is already added");
        require(!_presaleAddressIsAdded,"SMT: The presale address is already added");
        _canTransferBeforeTradingIsEnabled[account] = true;
        _presaleAddressIsAdded = true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(to != address(0), "ERC20: Transfer to the zero address");
        require(amount >= 0, "ERC20: Transfer amount must be greater or equals to zero");
        require(!_isBlacklisted[to], "SMT: Recipient is backlisted");
        require(!_isBlacklisted[from], "SMT: Sender is backlisted");
        require(!paused(), "SMT: The smart contract is paused");

        bool tradingIsEnabled = getTradingIsEnabled();
        // only whitelisted addresses can make transfers before the official PancakeSwap listing
        if(!tradingIsEnabled) {
            require(_canTransferBeforeTradingIsEnabled[from], "SMT: This account cannot send tokens until trading is enabled");
        }
        bool isSellTransfer = automatedMarketMakerPairs[to];
        if( 
            !_isSwapping &&
            tradingIsEnabled &&
            isSellTransfer && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromMaxTx[to] &&
            !_isExcludedFromMaxTx[from] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "SMT: Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if(
            tradingIsEnabled && 
            canSwap &&
            !_isSwapping &&
            !automatedMarketMakerPairs[from] && // not during buying
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            _isSwapping = true;

            swapAndDistribute();

            _isSwapping = false;
        }
        bool isBuyTransfer = automatedMarketMakerPairs[from];
        bool takeFee = tradingIsEnabled && !_isSwapping && (isBuyTransfer || isSellTransfer);

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 totalFees;
            // Buy
            if(isBuyTransfer){
                totalFees = totalBuyFees;
                _liquidityCurrentAccumulatedFee+= amount.mul(buyLiquidityFee).div(100);
                _marketingCurrentAccumulatedFee+= amount.mul(buyMarketingFee).div(100);
                _devCurrentAccumulatedFee+= amount.mul(buyDevFee).div(100);
                _rewardCurrentAccumulatedFee+= amount.mul(buyRewardFee).div(100);
            }
            // Sell 
            else if(isSellTransfer)  {
                totalFees = totalSellFees;
                _liquidityCurrentAccumulatedFee+= amount.mul(sellLiquidityFee).div(100);
                _marketingCurrentAccumulatedFee+= amount.mul(sellMarketingFee).div(100);
                _devCurrentAccumulatedFee+= amount.mul(sellDevFee).div(100);
                _rewardCurrentAccumulatedFee+= amount.mul(sellRewardFee).div(100);
            }
            uint256 fees = amount.mul(totalFees).div(100);
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!_isSwapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } 
            catch {

            }
        }
    }

     function tryToDistributeTokensManually() external payable authorized {        
        if(
            getTradingIsEnabled() && 
            !_isSwapping
        ) {
            _isSwapping = true;

            swapAndDistribute();

            _isSwapping = false;
        }
    } 
    function swapAndDistribute() private {
        uint256 totalTokens = balanceOf(address(this));
        // Get the unknown tokens that are on the contract and add them to the amount that goes to the liquidity pool
        uint256 unknownSourcetokens = totalTokens.sub(_devCurrentAccumulatedFee).sub(_marketingCurrentAccumulatedFee).sub(_liquidityCurrentAccumulatedFee).sub(_rewardCurrentAccumulatedFee);
        _liquidityCurrentAccumulatedFee+= unknownSourcetokens;
        uint256 liquidityTokensToNotSwap = _liquidityCurrentAccumulatedFee.div(2);

        uint256 initialBalance = address(this).balance;
        // swap tokens for BNB
        swapTokensForEth(totalTokens.sub(liquidityTokensToNotSwap));

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 marketingAmount = newBalance.mul(_marketingCurrentAccumulatedFee).div(totalTokens.sub(liquidityTokensToNotSwap));
        uint256 rewardAmount = newBalance.mul(_rewardCurrentAccumulatedFee).div(totalTokens.sub(liquidityTokensToNotSwap));
        uint256 devAmount = newBalance.mul(_devCurrentAccumulatedFee).div(totalTokens.sub(liquidityTokensToNotSwap));
        uint256 liquidityAmount = newBalance.sub(marketingAmount).sub(rewardAmount).sub(devAmount);
        _marketingCurrentAccumulatedFee = 0;
        _devCurrentAccumulatedFee = 0;
        _rewardCurrentAccumulatedFee = 0;
        _liquidityCurrentAccumulatedFee = 0;

        // add liquidity to Pancakeswap
        addLiquidity(liquidityTokensToNotSwap, liquidityAmount);
        sendHolderDividends(rewardAmount);
        sendMarketingDividends(marketingAmount);
        sendDevDividends(devAmount);
        emit SwapAndLiquify(totalTokens.sub(liquidityTokensToNotSwap), newBalance, liquidityTokensToNotSwap);

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }
    function sendHolderDividends(uint256 amount) private {

        (bool success,) = payable(address(dividendTracker)).call{value: amount}("");

        if(success) {
            emit SendHolderDividends(amount);
        }
    }

    function sendMarketingDividends(uint256 amount) private {
        (bool success,) = payable(address(marketingWallet)).call{value: amount}("");

        if(success) {
            emit SendMarketingDividends(amount);
        }
    }
    function sendDevDividends(uint256 amount) private {
        (bool success,) = payable(address(devWallet)).call{value: amount}("");

        if(success) {
            emit SenddevDividends(amount);
        }
    }

    function excludeFromDividends(address account) external authorized {
        dividendTracker.excludeFromDividends(account);
    }

    function includeInDividends(address account) external authorized {
        dividendTracker.includeInDividends(account,balanceOf(account));
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply().sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function burn(uint256 amount) external returns (bool) {
        _transfer(_msgSender(), DEAD, amount);
        emit Burn(amount);
        return true;
    }
    function setLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "SMT: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != marketingWallet, "The marketing wallet has already that address");
        emit MarketingWalletUpdated(newWallet,marketingWallet);
        marketingWallet = newWallet;
        excludeFromFees(newWallet, true);
        dividendTracker.excludeFromDividends(newWallet);
    }

    function setDevWallet(address payable newWallet) external onlyOwner {
        require(newWallet != devWallet, "The dev wallet has already that address");
        emit MarketingWalletUpdated(newWallet,devWallet);
        devWallet = newWallet;
        excludeFromFees(newWallet, true);
        dividendTracker.excludeFromDividends(newWallet);
    }

    function getStuckBNBs(address payable to) external onlyOwner {
        require(address(this).balance > 0, "SMT: There are no BNBs in the contract");
        to.transfer(address(this).balance);
    } 

    function blackList(address _account ) public authorized {
        require(!_isBlacklisted[_account], "SMT: This address is already blacklisted");
        require(_account != owner(), "SMT: Blacklisting the owner is not allowed");
        require(_account != address(0), "SMT: Blacklisting the 0 address is not allowed");
        require(_account != uniswapV2Pair, "SMT: Blacklisting the pair address is not allowed");
        require(_account != address(this), "SMT: Blacklisting the contract address is not allowed");

        _isBlacklisted[_account] = true;
        emit BlackList(_account,true);
    }
    
    function removeFromBlacklist(address _account) public authorized {
        require(_isBlacklisted[_account], "SMT: This address already whitelisted");
        _isBlacklisted[_account] = false;
        emit BlackList(_account,false);
    }

    function setSwapTokenAtAmount(uint256 amount) external authorized {
        require(amount > 0 && amount < totalSupply() /10**9, "SMT: Amount must be bewteen 0 and total supply");
        _swapTokensAtAmount = amount *10**9;

    }

    // Don't forget to approve the amount you want to send on the stablecoin contract (by default USDT) with the token address: SMT_Dividend_Tracker
    function distributeStableCoinsToAllHolders(uint256 amountToDistribute, uint32 startAt, uint32 endAt) public authorized returns (uint32){
        uint32 nbrHolders = dividendTracker.distributeStableCoinsToAllHolders(_msgSender(), amountToDistribute, startAt, endAt);
        return nbrHolders;
    }
    function setStableCoinContract(address newContract) external authorized{
         dividendTracker.setStableCoinContract(newContract);
    }

    function setGasForWithdrawingDividendOfUser(uint16 newGas) external authorized{
        dividendTracker.setGasForWithdrawingDividendOfUser(newGas);
    }

}

contract SMTDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IERC20 StableCoinContract;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) private _excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable MINIMUM_TOKEN_BALANCE_FOR_DIVIDENDS; 

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SetBalance(address payable account, uint256 newBalance);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("SMT_Dividend_Tracker", "SMT_Dividend_Tracker") {
        claimWait = 43200; // 12h
        MINIMUM_TOKEN_BALANCE_FOR_DIVIDENDS = 50 * (10**9); //must hold 50 + tokens
        StableCoinContract = IERC20(0x7169D38820dfd117C3FA1f22a697dBA58d90BA06); // USDT
    }

    function setStableCoinContract(address newContract) external {
        require(StableCoinContract != IERC20(newContract), "SMT_Dividend_Tracker: The new contract must be different from the old one");
        StableCoinContract = IERC20(newContract);
    }
    

    function distributeStableCoinsToAllHolders(address sender, uint256 amountToDistribute, uint32 startAt, uint32 endAt) public returns (uint32){
        amountToDistribute = amountToDistribute * (10 ** 18);
        uint256 totalSupply = super.totalSupply();
        address[] memory holderAddresses = tokenHoldersMap.keys;
        uint256 totalHolders = tokenHoldersMap.size();
        if(endAt > totalHolders -1) { endAt = uint32(totalHolders -1);}
        for(uint32 i = startAt ; i <= endAt ; i++) {
            bool isSuccess = StableCoinContract.transferFrom(sender,holderAddresses[i],tokenHoldersMap.values[holderAddresses[i]].mul(amountToDistribute).div(totalSupply));
            if(!isSuccess) return i;
        }

        return uint32(endAt);
    }
    function _transfer(address, address, uint256) pure internal override {
        require(false, "SMT_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "SMT_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SMT contract.");
    }
    function isExcludedFromDividends(address account) external view returns(bool) {
        return _excludedFromDividends[account];
    }
    function excludeFromDividends(address account) external onlyOwner {
        require(!_excludedFromDividends[account]);
        _excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account, uint256 balance) external onlyOwner {
        require(_excludedFromDividends[account]);
        _excludedFromDividends[account] = false;
        if(balance >= MINIMUM_TOKEN_BALANCE_FOR_DIVIDENDS) {
            _setBalance(account, balance);
            tokenHoldersMap.set(account, balance);
        }
        emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "SMT_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SMT_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.size();
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(_excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= MINIMUM_TOKEN_BALANCE_FOR_DIVIDENDS) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
            emit SetBalance(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
            emit SetBalance(account, 0);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.size();

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function setGasForWithdrawingDividendOfUser(uint16 newGas) external onlyOwner{
        _setGasForWithdrawingDividendOfUser(newGas);
    }
}