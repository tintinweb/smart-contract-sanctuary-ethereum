pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/gmx/StaxGmxManager.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/external/gmx/IGmxRewardRouter.sol";
import "../../interfaces/investments/gmx/IStaxGmxManager.sol";
import "../../interfaces/investments/gmx/IStaxGmxDepositor.sol";
import "../../interfaces/common/IMintableToken.sol";
import "../../interfaces/external/gmx/IGmxVault.sol";
import "../../interfaces/external/gmx/IGlpManager.sol";
import "../../interfaces/external/gmx/IGmxVaultPriceFeed.sol";

import "../../common/access/Operators.sol";
import "../../common/Executable.sol";
import "../../common/CommonEventsAndErrors.sol";

/// @title STAX GMX/GLP Manager
/// @notice Manages STAX's GMX and GLP positions, policy decisions and rewards harvesting/compounding.
contract StaxGmxManager is IStaxGmxManager, Ownable, Operators {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;
    using FractionalAmount for FractionalAmount.Data;

    // Note: The below (GMX.io) contracts can be found here: https://gmxio.gitbook.io/gmx/contracts

    /// @notice $GMX (GMX.io)
    IERC20 public immutable gmxToken;

    /// @notice $GLP (GMX.io)
    IERC20 public immutable glpToken;

    /// @notice The GMX glpManager contract, responsible for buying/selling $GLP (GMX.io)
    IGlpManager public immutable glpManager;

    /// @notice The GMX Vault contract, required for calculating accurate quotes for buying/selling $GLP (GMX.io)
    IGmxVault public immutable gmxVault;

    /// @notice $wrappedNative - wrapped ETH/AVAX
    address public immutable override wrappedNativeToken;

    /// @notice $stxGMX - The STAX liquid wrapper token over $GMX
    /// Users get stxGMX for initial $GMX deposits, and for each esGMX which STAX is rewarded,
    /// minus a fee.
    IMintableToken public immutable stxGmxToken;

    /// @notice $stxGLP - The STAX liquid wrapper token over $GLP
    /// Users get stxGLP for initial $GLP deposits.
    IMintableToken public immutable stxGlpToken;

    /// @notice Percentages of Native Token (ETH/AVAX) rewards that STAX retains as a fee
    FractionalAmount.Data public nativeRewardsFeeRate;

    /// @notice Percentages of stxGMX rewards (minted based off esGMX rewards) that STAX retains as a fee
    FractionalAmount.Data public stxGmxRewardsFeeRate;

    /// @notice Percentages of stxGMX/stxGLP that STAX retains as a fee when users sell out of their position
    FractionalAmount.Data public sellFeeRate;

    /// @notice Percentage of esGMX rewards that STAX will vest into GMX (1/365 per day).
    /// The remainder is staked.
    FractionalAmount.Data public esGmxVestingRate;

    /// @notice The GMX vault rewards aggregator - any harvested rewards from staked GMX/esGMX/mult points are sent here
    address public gmxRewardsAggregator;

    /// @notice The GLP vault rewards aggregator - any harvested rewards from staked GLP are sent here.
    address public glpRewardsAggregator;

    /// @notice The set of reward tokens that the GMX manager yields to users.
    /// [ ETH/AVAX, stxGMX ]
    address[] public rewardTokens;

    /// @notice The address used to collect the STAX fees.
    address public feeCollector;

    /// @notice The STAX contract holding the staked GMX/GLP/multiplier points/esGMX
    IStaxGmxDepositor public depositor;

    event NativeRewardsFeeRateSet(uint128 numerator, uint128 denominator);
    event StxGmxRewardsFeeRateSet(uint128 numerator, uint128 denominator);
    event SellFeeRateSet(uint128 numerator, uint128 denominator);
    event EsGmxVestingRateSet(uint128 numerator, uint128 denominator);
    event FeeCollectorSet(address indexed feeCollector);
    event RewardsAggregatorsSet(address gmxRewardsAggregator, address glpRewardsAggregator);
    event DepositorSet(address indexed depositor);

    constructor(
        address _gmxRewardRouter,
        address _stxGmxTokenAddr,
        address _stxGlpTokenAddr,
        address _feeCollectorAddr,
        address _depositor
    ) {
        IGmxRewardRouter gmxRewardRouter = IGmxRewardRouter(_gmxRewardRouter);
        glpManager = IGlpManager(gmxRewardRouter.glpManager());
        gmxToken = IERC20(gmxRewardRouter.gmx());
        glpToken = IERC20(gmxRewardRouter.glp());
        wrappedNativeToken = gmxRewardRouter.weth();
        stxGmxToken = IMintableToken(_stxGmxTokenAddr);
        stxGlpToken = IMintableToken(_stxGlpTokenAddr);
        gmxVault = IGmxVault(glpManager.vault());

        // Reward tokens are effectively immutable
        rewardTokens = [address(wrappedNativeToken), _stxGmxTokenAddr];

        depositor = IStaxGmxDepositor(_depositor);
        feeCollector = _feeCollectorAddr;

        // All numerators start at 0 on construction
        nativeRewardsFeeRate.denominator = 100;
        stxGmxRewardsFeeRate.denominator = 100;
        sellFeeRate.denominator = 100;
        esGmxVestingRate.denominator = 100;
    }

    /// @notice Set the fee rate STAX takes on ETH/AVAX rewards
    function setNativeRewardsFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        nativeRewardsFeeRate.set(_numerator, _denominator);
        emit NativeRewardsFeeRateSet(_numerator, _denominator);
    }

    /// @notice Set the fee rate STAX takes on stxGMX rewards
    /// (which are minted based off the quantity of esGMX rewards we receive)
    function setStxGmxRewardsFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        stxGmxRewardsFeeRate.set(_numerator, _denominator);
        emit StxGmxRewardsFeeRateSet(_numerator, _denominator);
    }

    /// @notice Set the proportion of esGMX that we vest whenever rewards are harvested.
    /// The remainder are staked.
    function setEsGmxVestingRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        esGmxVestingRate.set(_numerator, _denominator);
        emit EsGmxVestingRateSet(_numerator, _denominator);
    }

    /// @notice Set the proportion of fees stxGMX/stxGLP STAX retains when users sell out
    /// of their position.
    function setSellFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        sellFeeRate.set(_numerator, _denominator);
        emit SellFeeRateSet(_numerator, _denominator);
    }

    /// @notice Set the address for where STAX fees are sent
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit FeeCollectorSet(_feeCollector);
    }

    /// @notice Set the STAX depositor responsible for holding staked GMX/GLP/esGMX/mult points on GMX.io
    function setDepositor(address _depositor) external onlyOwner {
        if (_depositor == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        depositor = IStaxGmxDepositor(_depositor);
        emit DepositorSet(_depositor);
    }

    /// @notice Set the STAX GMX/GLP rewards aggregators
    function setRewardsAggregators(address _gmxRewardsAggregator, address _glpRewardsAggregator) external onlyOwner {
        gmxRewardsAggregator = _gmxRewardsAggregator;
        glpRewardsAggregator = _glpRewardsAggregator;
        emit RewardsAggregatorsSet(_gmxRewardsAggregator, _glpRewardsAggregator);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice The set of reward tokens we give to the staking contract.
    function rewardTokensList() external view override returns (address[] memory tokens) {
        return rewardTokens;
    }

    /// @notice The amount of rewards up to this block that STAX is due to distribute to users.
    /// @param forStakedGlpRewards If true, get the reward rates for just staked GLP rewards. Else the reward rates for combined GMX/esGMX/mult points
    /// ie the net amount after STAX has deducted it's fees.
    function harvestableRewards(bool forStakedGlpRewards) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);

        // Pull the currently claimable amount from the depositor's staked positions.
        (uint256 depositorNativeAmount, uint256 depositorEsGmxAmount) = depositor.harvestableRewards(forStakedGlpRewards);

        // Ignore any portions we will be retaining as fees.
        (, amounts[0]) = nativeRewardsFeeRate.split(depositorNativeAmount);
        (, amounts[1]) = stxGmxRewardsFeeRate.split(depositorEsGmxAmount);
    }

    /// @notice The current native token and stxGMX reward rates per second
    /// @param forStakedGlpRewards If true, get the reward rates for just staked GLP rewards. Else the reward rates for combined GMX/esGMX/mult points
    /// @dev Based on the current total STAX rewards, minus any portion of fees which we will take
    function projectedRewardRates(bool forStakedGlpRewards) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);

        // Pull the reward rates from the depositor's staked positions.
        (uint256 depositorNativeRewardRate, uint256 depositorEsGmxRewardRate) = depositor.rewardRates(forStakedGlpRewards);

        // Ignore any portions we will be retaining as fees.
        (, amounts[0]) = nativeRewardsFeeRate.split(depositorNativeRewardRate);
        (, amounts[1]) = stxGmxRewardsFeeRate.split(depositorEsGmxRewardRate);
    }

    /** 
     * @notice Harvest any claimable rewards up to this block from GMX.io
     * 1/ Mints stxGMX 1:1 for any esGMX that we've collected
     * 2/ Vest and/or stake the esGMX according to policy
     * 3/ Compound any vested GMX by staking it at GMX.io
     * 4/ Retain a portion of stxGMX and ETH/AVAX as fees
     * 5/ Pay the rest of the stxGMX and ETH/AVAX as rewards the GMX and GLP rewards aggregators
     */
    function harvestRewards() external override {
        // Harvest rewards from the depositor - any vestedGMX is collected to this contract.
        (
            uint256 wrappedNativeClaimedFromGmx,
            uint256 wrappedNativeClaimedFromGlp,
            uint256 esGmxClaimedFromGmx,
            uint256 esGmxClaimedFromGlp,
            uint256 vestedGmxClaimed
        ) = depositor.harvestRewards(esGmxVestingRate);

        // Apply any of the newly vested GMX
        if (vestedGmxClaimed > 0) {
            _applyGmx(vestedGmxClaimed);
        }

        // Handle esGMX rewards -- mint stxGMX rewards and collect fees
        uint256 totalFees;
        uint256 _fees;
        uint256 _rewards;
        {
            // Any rewards claimed from staked GMX/esGMX/mult points => GMX Investment Manager
            if (esGmxClaimedFromGmx > 0) {
                (_fees, _rewards) = stxGmxRewardsFeeRate.split(esGmxClaimedFromGmx);
                totalFees += _fees;
                if (_rewards > 0) stxGmxToken.mint(gmxRewardsAggregator, _rewards);
            }

            // Any rewards claimed from staked GLP => GLP Investment Manager
            if (esGmxClaimedFromGlp > 0) {
                (_fees, _rewards) = stxGmxRewardsFeeRate.split(esGmxClaimedFromGlp);
                totalFees += _fees;
                if (_rewards > 0) stxGmxToken.mint(glpRewardsAggregator, _rewards);
            }

            // Mint the total stxGMX fees
            if (totalFees > 0) {
                stxGmxToken.mint(feeCollector, totalFees);
            }
        }

        // Handle ETH/AVAX rewards
        {
            totalFees = 0;

            // Any rewards claimed from staked GMX/esGMX/mult points => GMX Investment Manager
            if (wrappedNativeClaimedFromGmx > 0) {
                (_fees, _rewards) = nativeRewardsFeeRate.split(wrappedNativeClaimedFromGmx);
                totalFees += _fees;
                if (_rewards > 0) IERC20(wrappedNativeToken).safeTransfer(gmxRewardsAggregator, _rewards);
            }

            // Any rewards claimed from staked GLP => GLP Investment Manager
            if (wrappedNativeClaimedFromGlp > 0) {
                (_fees, _rewards) = nativeRewardsFeeRate.split(wrappedNativeClaimedFromGlp);
                totalFees += _fees;
                if (_rewards > 0) IERC20(wrappedNativeToken).safeTransfer(glpRewardsAggregator, _rewards);
            }

            // Transfer any ETH/AVAX fees
            if (totalFees > 0) {
                IERC20(wrappedNativeToken).safeTransfer(feeCollector, totalFees);
            }
        }
    }

    /// @notice Apply any unstaked GMX (eg from user deposits) of $GMX into depositors for staking.
    function applyGmx(uint256 _amount) external {
        if (_amount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        _applyGmx(_amount);
    }

    function _applyGmx(uint256 _amount) internal {
        gmxToken.safeTransfer(address(depositor), _amount);
        depositor.stakeGmx(_amount);
    }

    /// @notice Get a quote for selling stxGMX - 1:1 but with exit fees applied.
    function sellStxGmxQuote(uint256 _stxGmxAmount) external view returns (
        uint256 staxFeeBasisPoints, uint256 gmxAmountOut
    ) {
        staxFeeBasisPoints = sellFeeRate.asBasisPoints();
        (, gmxAmountOut) = sellFeeRate.split(_stxGmxAmount);
    }

    /// @notice The set of whitelisted GMX.io tokens which can be used to buy GLP (and hence stxGLP)
    /// @dev Native tokens (ETH/AVAX) and using staked GLP can also be used and are
    /// not included in this list.
    function whitelistedTokens() external view override returns (address[] memory tokens) {
        uint256 length = gmxVault.allWhitelistedTokensLength();
        tokens = new address[](length);
        for (uint256 i; i < length; i++) {
            tokens[i] = gmxVault.allWhitelistedTokens(i);
        }
    }

    /// @notice Get a quote to buy stxGLP, with a GMX.io whitelisted token
    function buyStxGlpQuote(
        uint256 _amount,
        address _token
    ) external view override returns (uint256 gmxFeeBasisPoints, uint256 usdgAmountOut, uint256 glpAmountOut) {
        // GMX.io don't provide on-contract external functions to obtain the quote. Logic extracted from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/GlpManager.sol#L160
        if (_amount == 0) return (gmxFeeBasisPoints, usdgAmountOut, glpAmountOut);
        uint256 aumInUsdg = glpManager.getAumInUsdg(true); // Assets Under Management
        uint256 glpSupply = IERC20(glpManager.glp()).totalSupply();
        (gmxFeeBasisPoints, usdgAmountOut) = buyUsdgQuote(_amount, _token);
        glpAmountOut = (aumInUsdg == 0) ? usdgAmountOut : usdgAmountOut * glpSupply / aumInUsdg;
    }

    /// @notice Get a quote to sell stxGLP to a GMX whitelisted token
    /// @dev STAX retains a portion of the stxGLP as a fee and then gets a quote to sell
    /// the remaining portion 1:1 as GLP
    function sellStxGlpQuote(
        uint256 _stxGlpAmount,
        address _toToken
    ) external view returns (uint256 staxFeeBasisPoints, uint256 gmxFeeBasisPoints, uint256 tokenAmountOut) {
        // GMX.io don't provide on-contract external functions to obtain the quote. Logic extracted from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/GlpManager.sol#L183
        staxFeeBasisPoints = sellFeeRate.asBasisPoints();
        (, uint256 glpAmount) = sellFeeRate.split(_stxGlpAmount);
        if (glpAmount == 0) return (staxFeeBasisPoints, gmxFeeBasisPoints, tokenAmountOut);
        uint256 aumInUsdg = glpManager.getAumInUsdg(false); // Assets Under Management
        uint256 glpSupply = IERC20(glpManager.glp()).totalSupply();
        uint256 usdgAmount = (glpSupply == 0) ? 0 : glpAmount * aumInUsdg / glpSupply;
        (gmxFeeBasisPoints, tokenAmountOut) = sellUsdgQuote(usdgAmount, _toToken);
    }

    /// @notice Sell stxGMX to GMX. STAX retains a portion of the staked GMX as a fee and unstakes the remaining GMX and sends to the user.
    /// @dev This burns the full amount of stxGMX, and then unstakes only the portion it needs to return to the user.
    function sellStxGmx(
        uint256 _sellAmount,
        address _recipient
    ) external override onlyOperators returns (uint256) {
        if (_sellAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        (uint256 fees, uint256 nonFees) = sellFeeRate.split(_sellAmount);

        // Send the stxGlp fees to the fee collector
        if (fees > 0) {
            stxGmxToken.safeTransfer(feeCollector, fees);
        }

        if (nonFees > 0) {
            // Burn the users stxGmx
            stxGmxToken.burn(address(this), nonFees);

            // Use any balance of GMX sitting in this account first as it may not have been applied/staked in GMX's contracts yet.
            // Unstaking GMX will burn multiplier points proportional to percentage of GMX we've previously staked.
            // So best to avoid if possible.
            uint256 unstakedBal = gmxToken.balanceOf(address(this));

            // No need to check that we have enough staked balance across the depositors, as that's a given.
            // Iteratively unstake the amounts required from the depositors, most recent (smallest) depositor first.
            if (nonFees > unstakedBal) {
                depositor.unstakeGmx(nonFees - unstakedBal);
            }

            gmxToken.safeTransfer(_recipient, nonFees);
        }

        return nonFees;
    }

    /// @notice Sell stxGLP to a whitelisted token. STAX retains a portion of the staked GLP as a fee and unstakes/sells the remaining GLP and sends the _toToken to the user.
    /// @dev This burns the full amount of stxGLP, and then unstakes and sends the `_toToken` amount to the recipient.
    function sellStxGlp(
        uint256 _sellAmount,
        address _toToken,
        uint256 _minAmountOut,
        address _recipient
    ) external override onlyOperators returns (uint256 amountOut) {
        if (_sellAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        (uint256 fees, uint256 nonFees) = sellFeeRate.split(_sellAmount);

        // Send the stxGlp fees to the fee collector
        if (fees > 0) {
            stxGlpToken.safeTransfer(feeCollector, fees);
        }

        if (nonFees > 0) {
            // Burn the remaining stxGlp
            stxGlpToken.burn(address(this), nonFees);

            // Sell and send the resulting token to the recipient.
            amountOut = depositor.unstakeAndRedeemGlp(
                nonFees,
                _toToken,
                _minAmountOut,
                _recipient
            );
        }
    }

    /// @notice Sell stxGLP to Staked GLP to the recipient. STAX retains a portion of the staked GLP as a fee and returns the rest to the user.
    /// @dev This burns the full amount of stxGLP, and then unstakes and sends the `_toToken` amount to the recipient.
    function sellStxGlpToStakedGlp(
        uint256 _sellAmount,
        address _recipient
    ) external override onlyOperators returns (uint256) {
        if (_sellAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        (uint256 fees, uint256 nonFees) = sellFeeRate.split(_sellAmount);

        // Send the stxGlp fees to the fee collector
        if (fees > 0) {
            stxGlpToken.safeTransfer(feeCollector, fees);
        }

        if (nonFees > 0) {
            // Burn the users stxGlp
            stxGlpToken.burn(address(this), nonFees);

            // Transfer the remaining staked GLP to the recipient
            depositor.transferStakedGlp(
                nonFees,
                _recipient
            );
        }

        return nonFees;
    }

    function buyUsdgQuote(uint256 fromAmount, address fromToken) internal view returns (
        uint256 feeBasisPoints,
        uint256 usdgAmountOut
    ) {
        // Used as part of the quote to buy GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/Vault.sol#L452
        if (!gmxVault.whitelistedTokens(fromToken)) revert CommonEventsAndErrors.InvalidToken(fromToken);
        uint256 price = IGmxVaultPriceFeed(gmxVault.priceFeed()).getPrice(fromToken, false, true, true);
        uint256 pricePrecision = gmxVault.PRICE_PRECISION();
        uint256 basisPointsDivisor = FractionalAmount.BASIS_POINTS_DIVISOR;
        address usdg = gmxVault.usdg();
        uint256 usdgAmount = fromAmount * price / pricePrecision;
        usdgAmount = gmxVault.adjustForDecimals(usdgAmount, fromToken, usdg);

        feeBasisPoints = getFeeBasisPoints(
            fromToken, usdgAmount, 
            true  // true for buy, false for sell
        );

        uint256 amountAfterFees = fromAmount * (basisPointsDivisor - feeBasisPoints) / basisPointsDivisor;
        usdgAmountOut = gmxVault.adjustForDecimals(amountAfterFees * price / pricePrecision, fromToken, usdg);
    }

    function sellUsdgQuote(
        uint256 usdgAmount, address toToken
    ) internal view returns (uint256 feeBasisPoints, uint256 amountOut) {
        // Used as part of the quote to sell GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/Vault.sol#L484
        if (usdgAmount == 0) return (feeBasisPoints, amountOut);
        if (!gmxVault.whitelistedTokens(toToken)) revert CommonEventsAndErrors.InvalidToken(toToken);
        uint256 pricePrecision = gmxVault.PRICE_PRECISION();
        uint256 price = IGmxVaultPriceFeed(gmxVault.priceFeed()).getPrice(toToken, true, true, true);
        address usdg = gmxVault.usdg();
        uint256 redemptionAmount = gmxVault.adjustForDecimals(usdgAmount * pricePrecision / price, usdg, toToken);

        feeBasisPoints = getFeeBasisPoints(
            toToken, usdgAmount,
            false  // true for buy, false for sell
        );

        uint256 basisPointsDivisor = FractionalAmount.BASIS_POINTS_DIVISOR;
        amountOut = redemptionAmount * (basisPointsDivisor - feeBasisPoints) / basisPointsDivisor;
    }

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, bool _increment) internal view returns (uint256) {
        // Used as part of the quote to buy/sell GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/VaultUtils.sol#L143
        uint256 feeBasisPoints = gmxVault.mintBurnFeeBasisPoints();
        uint256 taxBasisPoints = gmxVault.taxBasisPoints();
        if (!gmxVault.hasDynamicFees()) { return feeBasisPoints; }

        // The GMX.io website sell quotes are slightly off when calculating the fee. When actually selling, 
        // the code already has the sell amount (_usdgDelta) negated from initialAmount and usdgSupply,
        // however when getting a quote, it doesn't have this amount taken off - so we get slightly different results.
        // To have the quotes match the exact amounts received when selling, this tweak is required.
        // https://github.com/gmx-io/gmx-contracts/issues/28
        uint256 initialAmount = gmxVault.usdgAmounts(_token);
        uint256 usdgSupply = IERC20(gmxVault.usdg()).totalSupply();
        if (!_increment) {
            initialAmount = (_usdgDelta > initialAmount) ? 0 : initialAmount - _usdgDelta;
            usdgSupply = (_usdgDelta > usdgSupply) ? 0 : usdgSupply - _usdgDelta;
        }
        // End tweak

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = (usdgSupply == 0)
            ? 0
            : gmxVault.tokenWeights(_token) * usdgSupply / gmxVault.totalTokenWeights();
        if (targetAmount == 0) { return feeBasisPoints; }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = taxBasisPoints * initialDiff / targetAmount;
            return rebateBps > feeBasisPoints ? 0 : feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }

        uint256 taxBps = taxBasisPoints * averageDiff / targetAmount;
        return feeBasisPoints + taxBps;
    }

    /// @notice Owner can recover tokens
    function recoverToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxRewardRouter.sol)

interface IGmxRewardRouter {
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function stakeEsGmx(uint256 _amount) external;
    function gmx() external view returns (address);
    function glp() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function weth() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);
    function glpManager() external view returns (address);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxManager.sol)

import "../../staking/IStaxInvestmentManager.sol";
import "./IStaxGmxDepositor.sol";

interface IStaxGmxManager {
    function harvestableRewards(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function projectedRewardRates(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function harvestRewards() external;
    function rewardTokensList() external view returns (address[] memory tokens);
    function wrappedNativeToken() external view returns (address);
    function depositor() external view returns (IStaxGmxDepositor);
    function sellStxGmxQuote(uint256 _stxGmxAmount) external view returns (uint256 staxFeeBasisPoints, uint256 gmxAmountOut);
    function sellStxGmx(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
    function whitelistedTokens() external view returns (address[] memory);
    function buyStxGlpQuote(uint256 _amount, address _token) external view returns (uint256 gmxFeeBasisPoints, uint256 usdgAmountOut, uint256 glpAmountOut);
    function sellStxGlpQuote(uint256 _stxGlpAmount, address _toToken) external view returns (uint256 staxFeeBasisPoints, uint256 gmxFeeBasisPoints, uint256 tokenAmountOut);
    function sellStxGlp(
        uint256 _sellAmount,
        address _toToken,
        uint256 _minAmountOut,
        address _recipient
    ) external returns (uint256 amountOut);
    function sellStxGlpToStakedGlp(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxDepositor.sol)

import "../../../common/FractionalAmount.sol";

interface IStaxGmxDepositor {
    function rewardRates(bool forStakedGlpRewards) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(bool forStakedGlpRewards) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 vestedGmxClaimed
    );
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;
    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IMintableToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxVault.sol)

interface IGmxVault {
    function getMinPrice(address _token) external view returns (uint256);
    function BASIS_POINTS_DIVISOR() external view returns (uint256);
    function PRICE_PRECISION() external view returns (uint256);
    function usdg() external view returns (address);
    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function priceFeed() external view returns (address);
    function whitelistedTokens(address token) external view returns (bool);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function usdgAmounts(address _token) external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function totalTokenWeights() external view returns (uint256);
    function tokenWeights(address token) external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGlpManager.sol)

interface IGlpManager {
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function glp() external view returns (address);
    function vault() external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxVaultPriceFeed.sol)

interface IGmxVaultPriceFeed {
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxInvestmentManager.sol)

interface IStaxInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {

    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    /// @notice Return the fractional amount as basis points (ie fractional amount at precision of 10k)
    function asBasisPoints(Data storage self) internal view returns (uint256) {
        return (self.numerator * BASIS_POINTS_DIVISOR) / self.denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0 || self.denominator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}