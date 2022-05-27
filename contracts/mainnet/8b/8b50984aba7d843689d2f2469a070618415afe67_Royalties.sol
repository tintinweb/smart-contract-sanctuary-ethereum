// SPDX-License-Identifier: MIT

/*

.########...#######..##....##....###....##.......########.####.########..######.
.##.....##.##.....##..##..##....##.##...##..........##.....##..##.......##....##
.##.....##.##.....##...####....##...##..##..........##.....##..##.......##......
.########..##.....##....##....##.....##.##..........##.....##..######....######.
.##...##...##.....##....##....#########.##..........##.....##..##.............##
.##....##..##.....##....##....##.....##.##..........##.....##..##.......##....##
.##.....##..#######.....##....##.....##.########....##....####.########..######.


https://t.me/RoyaltiesERC
https://twitter.com/RoyaltiesERC

*/

pragma solidity ^0.8.4;

import "./RoyaltiesDividendTracker.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./UniswapV2PriceImpactCalculator.sol";
import "./LiquidityBurnCalculator.sol";
import "./MaxWalletCalculator.sol";
import "./RoyaltiesStorage.sol";

contract Royalties is ERC20, Ownable {
    using SafeMath for uint256;
    using RoyaltiesStorage for RoyaltiesStorage.Data;
    using Fees for Fees.Data;
    using BiggestBuyer for BiggestBuyer.Data;
    using Referrals for Referrals.Data;
    using Transfers for Transfers.Data;

    RoyaltiesStorage.Data private _storage;

    uint256 public constant MAX_SUPPLY = 1000000 * (10**18);

    uint256 private hatchTime;

    bool private swapping;
    uint256 public liquidityTokensAvailableToBurn;
    uint256 public liquidityBurnTime;

    RoyaltiesDividendTracker public dividendTracker;

    uint256 private swapTokensAtAmount = 200 * (10**18);
    uint256 private swapTokensMaxAmount = 1000 * (10**18);

    // exlcude from fees and max transaction amount
    mapping (address => bool) public isExcludedFromFees;

    event UpdateDividendTracker(address indexed newAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event LiqudityBurn(uint256 value);

    event LiquidityBurn(
        uint256 amount
    );

    event ClaimTokens(
        address indexed account,
        uint256 amount
    );

    event UpdateMysteryContract(address mysteryContract);

    constructor() ERC20("Royalties", "$RLTS") {
        _storage.router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _storage.pair = IUniswapV2Pair(
          IUniswapV2Factory(_storage.router.factory()
        ).createPair(address(this), _storage.router.WETH()));


        _mint(owner(), MAX_SUPPLY);

        _approve(address(this), address(_storage.router), type(uint).max);
        IUniswapV2Pair(_storage.pair).approve(address(_storage.router), type(uint).max);

        _storage.fees.init(_storage, address(_storage.pair));
        _storage.biggestBuyer.init();
        _storage.referrals.init();
        _storage.transfers.init(address(_storage.router), address(_storage.pair));

        _storage.dividendTracker = new RoyaltiesDividendTracker(payable(address(this)), address(_storage.pair), _storage.router.WETH());

        setupDividendTracker();

        _storage.marketingWallet1 = 0x3B256a48b2CF0B837783425E791E30d1B82d43a7;
        _storage.marketingWallet2 = 0x3F3f539462779C4F9A2277Df347eF6fa49F00415;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(_storage.router), true);
        excludeFromFees(address(_storage.dividendTracker), true);
        excludeFromFees(_storage.marketingWallet1, true);
        excludeFromFees(_storage.marketingWallet2, true);
    }

    receive() external payable {

  	}

    function approve(address spender, uint256 amount) public override returns (bool) {
        //Piggyback off approvals to burn tokens
        burnLiquidityTokens();
        return super.approve(spender, amount);
    }

    function approveWithoutBurn(address spender, uint256 amount) public returns (bool) {
        return super.approve(spender, amount);
    }

    function updateMysteryContract(address mysteryContract) public onlyOwner {
        _storage.mysteryContract = IMysteryContract(mysteryContract);
        emit UpdateMysteryContract(mysteryContract);
        isExcludedFromFees[mysteryContract] = true;

        //ensure the functions exist
        _storage.mysteryContract.handleBuy(address(0), 0, 0);
        _storage.mysteryContract.handleSell(address(0), 0, 0);
    }

    function updateBaseFee(uint256 baseFee) public onlyOwner {
        _storage.fees.updateBaseFee(baseFee);
    }

    function updateFeeImpacts(uint256 sellImpact, uint256 timeImpact) public onlyOwner {
        _storage.fees.updateFeeSellImpact(sellImpact);
        _storage.fees.updateFeeTimeImpact(timeImpact);
    }

    function updateFeeDestinationPercents(uint256 dividendsPercent, uint256 marketingPercent, uint256 mysteryPercent) public onlyOwner {
        _storage.fees.updateFeeDestinationPercents(_storage, dividendsPercent, marketingPercent, mysteryPercent);
    }

    function updateBiggestBuyerRewardFactor(uint256 value) public onlyOwner {
        _storage.biggestBuyer.updateRewardFactor(value);
    }

    function updateReferrals(uint256 referralBonus, uint256 referredBonus, uint256 tokensNeeded) public onlyOwner {
        _storage.referrals.updateReferralBonus(referralBonus);
        _storage.referrals.updateReferredBonus(referredBonus);
        _storage.referrals.updateTokensNeededForReferralNumber(tokensNeeded);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        _storage.dividendTracker = RoyaltiesDividendTracker(payable(newAddress));

        require(_storage.dividendTracker.owner() == address(this));

        setupDividendTracker();

        emit UpdateDividendTracker(newAddress);
    }

    function setupDividendTracker() private {
        _storage.dividendTracker.excludeFromDividends(address(_storage.dividendTracker));
        _storage.dividendTracker.excludeFromDividends(address(this));
        _storage.dividendTracker.excludeFromDividends(owner());
        _storage.dividendTracker.excludeFromDividends(address(_storage.router));
        _storage.dividendTracker.excludeFromDividends(address(_storage.pair));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account) public onlyOwner {
        _storage.dividendTracker.excludeFromDividends(account);
    }

    function updateVestingDuration(uint256 vestingDuration) external onlyOwner {
        _storage.dividendTracker.updateVestingDuration(vestingDuration);
    }

    function updateUnvestedDividendsMarketingFee(uint256 unvestedDividendsMarketingFee) external onlyOwner {
        _storage.dividendTracker.updateUnvestedDividendsMarketingFee(unvestedDividendsMarketingFee);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(amount < 1000 * (10**18));
        swapTokensAtAmount = amount;
    }

    function setSwapTokensMaxAmount(uint256 amount) external onlyOwner {
        require(amount < 10000 * (10**18));
        swapTokensMaxAmount = amount;
    }

    function manualSwapAccumulatedFees() external onlyOwner {
        _storage.fees.swapAccumulatedFees(_storage, balanceOf(address(this)));
    }

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256 referralCode, int256 buyFee, uint256 sellFee, address biggestBuyerCurrentHour, uint256 biggestBuyerAmountCurrentHour, uint256 biggestBuyerRewardCurrentHour, address biggestBuyerPreviousHour, uint256 biggestBuyerAmountPreviousHour, uint256 biggestBuyerRewardPreviousHour, uint256 blockTimestamp) {
        dividendInfo = _storage.dividendTracker.getDividendInfo(account);

        referralCode = _storage.referrals.getReferralCode(account);

        (buyFee,
        sellFee) = _storage.fees.getCurrentFees();

        uint256 hour = _storage.biggestBuyer.getHour();

        (biggestBuyerCurrentHour, biggestBuyerAmountCurrentHour,) = _storage.biggestBuyer.getBiggestBuyer(hour);

        biggestBuyerRewardCurrentHour = _storage.biggestBuyer.calculateBiggestBuyerReward(getLiquidityTokenBalance());

        if(hour > 0) {
            (biggestBuyerPreviousHour, biggestBuyerAmountPreviousHour, biggestBuyerRewardPreviousHour) = _storage.biggestBuyer.getBiggestBuyer(hour - 1);

            if(biggestBuyerPreviousHour != address(0) &&
               biggestBuyerRewardPreviousHour == 0) {
                biggestBuyerRewardPreviousHour = biggestBuyerRewardCurrentHour;
            }
        }

        blockTimestamp = block.timestamp;
    }

    function getLiquidityTokenBalance() private view returns (uint256) {
        return balanceOf(address(_storage.pair));
    }

    function claimDividends() external {
		_storage.dividendTracker.claimDividends(
            msg.sender,
            _storage.marketingWallet1,
            _storage.marketingWallet2,
            false);
    }

    function burnLiquidityTokens() public {
        uint256 burnAmount = LiquidityBurnCalculator.calculateBurn(
            getLiquidityTokenBalance(),
            liquidityTokensAvailableToBurn,
            liquidityBurnTime);

        if(burnAmount == 0) {
            return;
        }

        liquidityBurnTime = block.timestamp;
        liquidityTokensAvailableToBurn -= burnAmount;

        _burn(address(_storage.pair), burnAmount);
        _storage.pair.sync();

        emit LiquidityBurn(burnAmount);
    }

    function hatch() external onlyOwner {
        require(hatchTime == 0);

        _storage.router.addLiquidityETH {
            value: address(this).balance
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        hatchTime = block.timestamp;
    }

    function takeFees(address from, uint256 amount, uint256 feeFactor) private returns (uint256) {
        uint256 fees = Fees.calculateFees(amount, feeFactor);
        amount = amount.sub(fees);
        super._transfer(from, address(this), fees);
        return amount;
    }

    function mintFromLiquidity(address account, uint256 amount) private {
        if(amount == 0) {
            return;
        }
        liquidityTokensAvailableToBurn += amount;
        _mint(account, amount);
    }

    function handleNewBalanceForReferrals(address account) private {
        if(isExcludedFromFees[account]) {
            return;
        }

        if(account == address(_storage.pair)) {
            return;
        }

        _storage.referrals.handleNewBalance(account, balanceOf(account));
    }

    function payBiggestBuyer(uint256 hour) public {
        uint256 liquidityTokenBalance = getLiquidityTokenBalance();

        (address winner, uint256 amountWon) = _storage.biggestBuyer.payBiggestBuyer(hour, liquidityTokenBalance);

        if(winner != address(0))  {
            mintFromLiquidity(winner, amountWon);
            handleNewBalanceForReferrals(winner);
            _storage.dividendTracker.setBalance(winner, balanceOf(winner));
        }
    }

    function maxWallet() public view returns (uint256) {
        return MaxWalletCalculator.calculateMaxWallet(MAX_SUPPLY, hatchTime);
    }

    function executePossibleSwap(address from, address to, uint256 amount) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(from != owner() && to != owner()) {
            if(
                to != address(this) &&
                to != address(_storage.pair) &&
                to != address(_storage.router)
            ) {
                require(balanceOf(to) + amount <= maxWallet());
            }

            if(
                canSwap &&
                !swapping &&
                from != address(_storage.pair) &&
                hatchTime > 0 &&
                block.timestamp > hatchTime
            ) {
                swapping = true;

                uint256 swapAmount = contractTokenBalance;

                if(swapAmount > swapTokensMaxAmount) {
                    swapAmount = swapTokensMaxAmount;
                }

                _approve(address(this), address(_storage.router), swapAmount);

                _storage.fees.swapAccumulatedFees(_storage, swapAmount);

                swapping = false;
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        executePossibleSwap(from, to, amount);

        bool takeFee = !swapping &&
                        !isExcludedFromFees[from] &&
                        !isExcludedFromFees[to];

        uint256 originalAmount = amount;
        int256 transferFees = 0;

        if(takeFee) {
            address referrer = _storage.referrals.getReferrerFromTokenAmount(amount);

            if(!_storage.referrals.isValidReferrer(referrer, balanceOf(referrer), to)) {
                referrer = address(0);
            }

            (uint256 fees,
            uint256 buyerMint,
            uint256 referrerMint) =
            _storage.transfers.handleTransferWithFees(_storage, from, to, amount, referrer);

            transferFees = int256(fees) - int256(buyerMint);

            if(fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }

            if(buyerMint > 0) {
                mintFromLiquidity(to, buyerMint);
            }

            if(referrerMint > 0) {
                mintFromLiquidity(referrer, referrerMint);
                _storage.dividendTracker.setBalance(referrer, balanceOf(referrer));
            }
        }

        super._transfer(from, to, amount);

        handleNewBalanceForReferrals(to);

        uint256 hour = _storage.biggestBuyer.getHour();

        if(hour > 0) {
            payBiggestBuyer(hour - 1);
        }

        _storage.dividendTracker.setBalance(from, balanceOf(from));
        _storage.dividendTracker.setBalance(to, balanceOf(to));

        _storage.handleTransfer(from, to, originalAmount, transferFees);
    }
}