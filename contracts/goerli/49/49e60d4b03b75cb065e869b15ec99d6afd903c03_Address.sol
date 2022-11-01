// SPDX-License-Identifier: MIT
//                       ,ƒ   ,╗Γ                ╚╔,   \,
//                      ██L  ▓▐▌                  ▓▌╬Γ  ▀█
//                     ██▌▒, ╚▓▀▓                ╬█ß▌ ,@╟██
//                     ▐███/▒w▓╦█▓@g╖        ╓g╥▓█╦▓╔╫\███▌
//                      '█████▄ █████▓▄@w╤¢▄╬███▓█,╓█████'
//                         █████████▀▀▄▓██▓▄▀▀█████████`
//                           ╙████████▄▓▄▄▓▄████████▀
//                             ▄████▓▓██▀▀██▓▓████▄
//                            ███╣█████▌╬▓▐█████Ñ▀██
//                               ╘▓▀██]▓▓▓▓╝████┘
//                                 ╚╣████████▌╝
//                                    ▀████▀`

// ╫╬╬╬╬╬╬@╗    ,╬╬╬╖    ╫╬╬╬╬╬╬@╗ ╙╬╬╖   @╬╝  ╬╬     ╬╬  ,@╬╬╣╬╬@,  ╬╬     ╬╬U ╟╬╬
// ║╢╣,,,╓╢╬   ,╣╢ ╣╢┐   ║╢╣,,,╓╢╬   ╨╢@╓╬╣╜   ╢╢     ╢╢  ╟╢╢╖╖,```  ╢╢U,,,,╢╢U ╟╢╢
// ║╢╣╜╜╜╨║@  ,╣╢Ç,]╢╢,  ║╢╣╜╜╜╨╢@    `╢╢╣     ╢╢    ]╢╢    ╙╙╩╩╣╢@  ╢╢╨╨╨╨╨╢╢U ╟╢╢
// ║╢╣╦╦╦@╢╢  ╣╢╜╜╜╜╨╢╢  ║╢╣╦╦╦@╢╢     ╢╢[     ╚╢╣╦╦@╬╢╝  ╚╢╬╦╗╦╬╢╝  ╢╢     ╢╢U ╟╢╢

//    ╢ ╓╢╜╙╢╖ ║╢ ╢╢, ╢L    ╢╢╖  @╜╙╚N   ╢╜╙╙╢ ╢[  ║[ ╢    ║[   ║╢╙╙╢╖ ╢   ╢ ]╢╖  ╢
// ╓  ║ ╢[  ,║ ║╢ ║ ╙╢╢L   ╢╣╓║╖ ,╙╙╢@   ║╜╙╙╢ ╢[  ║[ ║    ║[   ║║╝╢╢  ║   ║ ]║╙╢╢║
// `╙╙╜  `╙╙"  ╙' ╙   ╙   "╜   ╙ `╙╙╙    ╙╙╙╙`  ╙╙╙`  ╙╙╙╙ ╙╙╙╙'╙╙  ╙"  ╙╙╙   ╙  `╙

// Is an improved fork token with
// the function of a passive staking protocol
// on the Ethereum network Mainnet,
// which is launched for the purpose
// of Continue the BULLISH trend

// https://babyushi.com/
// https://twitter.com/babyushieth
// https://t.me/babyushiengchat
// https://t.me/babyushieng

// Rewards 8%
// BuyBack 3%
// AutoLp 1%
// Marketing 8%

pragma solidity ^0.8.14;

import './RewardsTracker.sol';
import './Ownable.sol';
import './IDex.sol';
import './IERC20.sol';
import './ERC20.sol';

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

contract ERC20BABYUSH1 is ERC20, Ownable, RewardsTracker {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public antiBotSystem;
    bool public swapEnabled = true;

    address public marketingWallet = 0xdE747aeF6E223601352aD01A9115D34b7a333c04;
    address public buybackWallet = 0x5e901ca79A5CDe2804772910Fa3eC7eAC651F147;

    uint256 public swapTokensAtAmount = 10_000_000 * 10**18;
    uint256 public maxWalletAmount = 105_000_000 * 10**18;
    uint256 public gasLimit = 300_000;
    uint256 public goldenHourStart;

    struct Taxes {
        uint64 rewards;
        uint64 marketing;
        uint64 buyback;
        uint64 lp;
    }

    Taxes public buyTaxes = Taxes(8, 8, 3, 1);
    Taxes public sellTaxes = Taxes(8, 8, 3, 1);

    uint256 public totalBuyTax = 20;
    uint256 public totalSellTax = 20;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public antiBot;
    mapping(address => bool) public isPair;

    ///////////////
    //   Events  //
    ///////////////

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _router, address _rewardToken) ERC20('BUSHI', 'BUSHI') RewardsTracker(_router, _rewardToken) {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        isPair[pair] = true;

        minBalanceForRewards = 210_000 * 10**18;
        claimDelay = 1 hours;

        // exclude from receiving dividends
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[owner()] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(_router)] = true;
        excludedFromDividends[address(pair)] = true;

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[buybackWallet] = true;

        antiBotSystem = true;
        antiBot[address(this)] = true;
        antiBot[owner()] = true;
        antiBot[marketingWallet] = true;
        antiBot[buybackWallet] = true;

        // _mint is an internal function in ERC20.sol that is only called here,
        // and CANNOT be called ever again
        _mint(owner(), 21e9 * (10**18));
    }

    receive() external payable {}

    /// @notice Manual claim the dividends
    function claim() external {
        super._processAccount(payable(msg.sender));
    }

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        payable(owner()).sendValue(ETHbalance);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IRouter(newRouter);
    }

    /////////////////////////////////
    // Exclude / Include functions //
    /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    ///////////////////////
    //  Setter Functions //
    ///////////////////////

    function setRewardToken(address newToken) external onlyOwner {
        super._setRewardToken(newToken);
    }

    function startGoldenHour() external onlyOwner {
        goldenHourStart = block.timestamp;
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    function setBuybackWallet(address newWallet) external onlyOwner {
        buybackWallet = newWallet;
    }

    function setClaimDelay(uint256 amountInSeconds) external onlyOwner {
        claimDelay = amountInSeconds;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function setBuyTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback,
        uint64 _lp
    ) external onlyOwner {
        buyTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalBuyTax = _rewards + _marketing + _buyback + _lp;
    }

    function setSellTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback,
        uint64 _lp
    ) external onlyOwner {
        sellTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalSellTax = _rewards + _marketing + _buyback + _lp;
    }

    function setMaxWallet(uint256 maxWalletPercentage) external onlyOwner {
        maxWalletAmount = (maxWalletPercentage * totalSupply()) / 1000;
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        gasLimit = newGasLimit;
        //QWxsIHJpZ2h0cyBiZWxvbmcgdG8gQkFZVVNISS4gQ29weWluZyBhIGNvbnRyYWN0IGlzIGEgdmlvbGF0aW9uIGFuZCBzdWdnZXN0cyB0aGF0IHdob2V2ZXIgZGlkIGl0IGhhcyBzbW9vdGhpZXMgaW5zdGVhZCBvZiBicmFpbnMu
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setMinBalanceForRewards(uint256 minBalance) external onlyOwner {
        minBalanceForRewards = minBalance * 10**18;
    }

    function setAntiBotStatus(bool value) external onlyOwner {
        _setAntiBotStatus(value);
    }

    function _setAntiBotStatus(bool value) internal {
        antiBotSystem = value;
    }

    function addAntiBot(address _address) external onlyOwner {
        _addAntiBot(_address);
    }

    function addMultipleAntiBot(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addAntiBot(_addresses[i]);
        }
    }

    function _addAntiBot(address _address) internal {
        antiBot[_address] = true;
    }

    function removeMultipleAntiBot(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _removeAntiBot(_addresses[i]);
        }
    }

    function _removeAntiBot(address _address) internal {
        antiBot[_address] = false;
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setPair(address newPair, bool value) external onlyOwner {
        _setPair(newPair, value);
    }

    function _setPair(address newPair, bool value) private {
        isPair[newPair] = value;

        if (value) {
            excludedFromDividends[newPair] = true;
        }
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        if (antiBotSystem) {
            require(antiBot[tx.origin], 'Address is bot');
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping) {
            if (!isPair[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, 'You are exceeding maxWallet');
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !isPair[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            totalSellTax > 0
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!isPair[to] && !isPair[from]) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (isPair[to]) feeAmt = (amount * totalSellTax) / 100;
            else if (isPair[from]) {
                if (block.timestamp < goldenHourStart + 1 hours)
                    feeAmt = (amount * (buyTaxes.lp + buyTaxes.buyback)) / 100;
                else feeAmt = (amount * totalBuyTax) / 100;
            }

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        super.setBalance(from, balanceOf(from));
        super.setBalance(to, balanceOf(to));

        if (!swapping) {
            super.autoDistribute(gasLimit);
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        // Split the contract balance into halves
        uint256 denominator = totalSellTax * 2;
        uint256 tokensToAddLiquidityWith = (tokens * sellTaxes.lp) / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - sellTaxes.lp);
        uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.lp;

        if (bnbToAddLiquidityWith > 0) {
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send ETH to marketing
        uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
        if (marketingAmt > 0) {
            payable(marketingWallet).sendValue(marketingAmt);
        }

        // Send ETH to buyback
        uint256 buybackAmt = unitBalance * 2 * sellTaxes.buyback;
        if (buybackAmt > 0) {
            payable(buybackWallet).sendValue(buybackAmt);
        }

        // Send ETH to rewards
        uint256 dividends = unitBalance * 2 * sellTaxes.rewards;
        if (dividends > 0) super._distributeDividends(dividends);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path, // QWxsIHJpZ2h0cyBiZWxvbmcgdG8gQkFZVVNISS4gQ29weWluZyBhIGNvbnRyYWN0IGlzIGEgdmlvbGF0aW9uIGFuZCBzdWdnZXN0cyB0aGF0IHdob2V2ZXIgZGlkIGl0IGhhcyBzbW9vdGhpZXMgaW5zdGVhZCBvZiBicmFpbnMu
            address(this),
            block.timestamp
        );
    }
}