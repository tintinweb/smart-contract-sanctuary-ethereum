// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IStaking.sol";
import "./interfaces/IPlatformHelper.sol";

contract PlatformHelper is Initializable, IPlatformHelper {
    uint16 private constant MAX_PERCENTAGE = 10000;

    IERC20 private govi;
    IStaking private staking;


    function initialize(IERC20 _govi, IStaking _staking) public initializer {
        govi = _govi;
        staking = _staking;
    }

    function dailyFundingFee(IPlatform _platform) external view override returns (uint256 fundingFeePercent) {
        (uint32 cviValue,,) = _platform.cviOracle().getCVILatestRoundData();
        (, fundingFeePercent) = _platform.feesCalculator().calculateSingleUnitPeriodFundingFee(IFeesCalculator.CVIValue(1 days, cviValue), premiumFeeCollateralRatio(_platform));
    }

    function fundingFeeValues(IPlatform _platform, uint32 _minCVI, uint32 _maxCVI, uint256 _minCollateral, uint256 _maxCollateral) external view override returns (uint256[][] memory fundingFeeRatePercent) {
        fundingFeeRatePercent = new uint256[][](_maxCollateral - _minCollateral + 1);
        uint256 currCollateralIndex = 0;
        for (uint256 currCollateral = _minCollateral; currCollateral <= _maxCollateral; currCollateral += 1) {
            uint256[] memory currValues = new uint256[](_maxCVI - _minCVI + 1);
            uint256 currCVIIndex = 0;
            for (uint32 currCVI = _minCVI * _platform.feesCalculator().oracleLeverage(); currCVI <= _maxCVI * _platform.feesCalculator().oracleLeverage(); currCVI += _platform.feesCalculator().oracleLeverage()) {
                (,uint256 feePercent) = _platform.feesCalculator().calculateSingleUnitPeriodFundingFee(IFeesCalculator.CVIValue(1 days, currCVI * 100), (currCollateral * _platform.PRECISION_DECIMALS()) / 100);
                currValues[currCVIIndex] = feePercent;
                currCVIIndex += 1;
            }
            fundingFeeRatePercent[currCollateralIndex] = currValues;
            currCollateralIndex += 1;
        }
    }

    function premiumFeeCollateralRatio(IPlatform _platform) public view override returns (uint256) {
        if (_platform.totalLeveragedTokensAmount() == 0) {
            return MAX_PERCENTAGE;
        }

        return _platform.feesCalculator().calculateCollateralRatio(_platform.totalLeveragedTokensAmount(), _platform.totalPositionUnitsAmount());
    }

    function collateralRatio(IPlatform _platform) public view override returns (uint256) {
        if (_platform.totalLeveragedTokensAmount() == 0) {
            return MAX_PERCENTAGE;
        }

        return _platform.totalPositionUnitsAmount() * _platform.PRECISION_DECIMALS() / _platform.totalLeveragedTokensAmount();
    }

    function volTokenIntrinsicPrice(IVolatilityToken _volToken) public view override returns (uint256) {
        require(IERC20(address(_volToken)).totalSupply() > 0, "No supply");

        uint256 volTokenBalance = calculateVolTokenPositionBalance(_volToken);

        return volTokenBalance * 10 ** ERC20(address(_volToken)).decimals() / IERC20(address(_volToken)).totalSupply();
    }

    function volTokenDexPrice(IThetaVault _thetaVault) external view override returns (uint256) {
        (,,,, uint256 usdcAmount, uint256 volTokenAmount) = _thetaVault.totalBalance();
        require(volTokenAmount > 0 && usdcAmount > 0, "No liquidity");
        return usdcAmount * 10 ** ERC20(address(_thetaVault.volToken())).decimals() / volTokenAmount;
    }

    function volTokenDexPriceV3(IUniswapV3LiquidityManager _uniswapLiquidityManager) external view override returns (uint256) {
        return _uniswapLiquidityManager.getDexPrice();
    }

    function maxWithdrawAmount(IThetaVault _thetaVault) external view override returns (uint256 maxAmount, uint256 maxUSDCAmount) {
        (uint256 totalBalance,,,,,) =_thetaVault.totalBalance();
        uint256 totalSupply = IERC20(address(_thetaVault)).totalSupply();
        uint256 totalLeveragedTokensAmount = _thetaVault.volToken().platform().totalLeveragedTokensAmount();
        uint256 maxPlatformWithdraw = totalLeveragedTokensAmount - _thetaVault.volToken().platform().totalPositionUnitsAmount();
        maxAmount = maxPlatformWithdraw * totalSupply / totalLeveragedTokensAmount;
        maxUSDCAmount = maxAmount * totalBalance / totalSupply;
    }

    function _simulateMint(uint256 _totalUnits, uint256 _totalTokens, uint256 _units, uint256 _amount) internal pure returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        newTotalUnits = _totalUnits + _units;
        newTotalTokens = _totalTokens + _amount;
    }

    function _simulateBurn(uint256 _totalUnits, uint256 _totalTokens, uint256 _units, uint256 _amount) internal pure returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        newTotalUnits = _totalUnits - _units;
        newTotalTokens = _totalTokens - _amount;
    }

    function _simulatePlatformDeposit(uint256 _totalUnits, uint256 _totalTokens, uint256 _amount) internal pure returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        newTotalUnits = _totalUnits;
        newTotalTokens = _totalTokens + _amount;
    }

    function _simulatePlatformWithdraw(uint256 _totalUnits, uint256 _totalTokens, uint256 _amount) internal pure returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        newTotalUnits = _totalUnits;
        newTotalTokens = _totalTokens - _amount;
    }

    function _simulateThetaDeposit(IThetaVault _thetaVault, uint256 _totalUnits, uint256 _totalTokens, uint256 _amount) internal view returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        uint256 liquidityAmount = _getLiquidityAmount(_thetaVault, _amount);
        (uint256 units, uint256 tokens) = _getPositionAmount(_thetaVault, _amount);

        (newTotalUnits, newTotalTokens) = _simulatePlatformDeposit(_totalUnits, _totalTokens, liquidityAmount);
        (newTotalUnits, newTotalTokens) = _simulateMint(newTotalUnits, newTotalTokens, units, tokens);
    }

    function _simulateThetaWithdraw(IThetaVault _thetaVault, uint256 _totalUnits, uint256 _totalTokens, uint256 _amount) internal view returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        uint256 liquidityAmount = _getLiquidityAmount(_thetaVault, _amount);
        (uint256 units, uint256 tokens) = _getPositionAmount(_thetaVault, _amount);

        (newTotalUnits, newTotalTokens) = _simulateBurn(_totalUnits, _totalTokens, units, tokens);
        (newTotalUnits, newTotalTokens) = _simulatePlatformWithdraw(newTotalUnits, newTotalTokens, liquidityAmount);
    }

    function _getLiquidityAmount(IThetaVault _thetaVault, uint256 _thetaAmount) internal view returns (uint256 liquidityAmount) {
        IPlatform platform = _thetaVault.volToken().platform();
        uint256 totalSupply = IERC20(address(_thetaVault)).totalSupply();
        uint256 thetaLPBalance = IERC20(address(platform)).balanceOf(address(_thetaVault));
        uint256 platformLPTokens = _thetaAmount * thetaLPBalance / totalSupply;
        uint256 totalPlatformBalance = platform.totalBalance(true);
        uint256 totalPlatformSupply = IERC20(address(platform)).totalSupply();
        return platformLPTokens * totalPlatformBalance / totalPlatformSupply;
    }

    function _getPositionAmount(IThetaVault _thetaVault, uint256 _thetaAmount) internal view returns (uint256 units, uint256 tokens) { 
        IVolatilityToken volToken = _thetaVault.volToken();
        IPlatform platform = volToken.platform();
        uint256 totalSupply = IERC20(address(_thetaVault)).totalSupply();
        uint256 totalVolTokenSupply = IERC20(address(volToken)).totalSupply();
        (,,,,, uint256 volTokenAmount) = _thetaVault.totalBalance();
        uint256 volTokensToBurn = _thetaAmount * volTokenAmount  / totalSupply;
        uint volTokenPositionBalance = calculateVolTokenPositionBalance(volToken);
        (uint256 totalVolTokenPosUnits,,,,) = platform.positions(address(volToken));
        units = volTokensToBurn * totalVolTokenPosUnits / totalVolTokenSupply;
        tokens = volTokenPositionBalance * volTokensToBurn / totalVolTokenSupply;
    }

    function _simulateRebalance(IThetaVault _thetaVault, uint256 _totalUnits, uint256 _totalTokens) internal view returns (uint256 newTotalUnits, uint256 newTotalTokens) {
        uint256 adjustedPositionUnits = _totalUnits * (MAX_PERCENTAGE + _thetaVault.extraLiquidityPercentage()) / MAX_PERCENTAGE;
        if (_totalTokens > adjustedPositionUnits) {
            uint256 extraLiquidityAmount = _totalTokens - adjustedPositionUnits;

            (newTotalUnits, newTotalTokens) = _simulatePlatformWithdraw(_totalUnits, _totalTokens, extraLiquidityAmount);
            (newTotalUnits, newTotalTokens) = _simulateThetaDeposit(_thetaVault, newTotalUnits, newTotalTokens, extraLiquidityAmount);
        } else {
            uint256 liquidityMissing = adjustedPositionUnits - _totalTokens;
            (uint256 balance,, uint256 intrinsicDEXVolTokenBalance,, uint256 dexUSDCAmount,) = _thetaVault.totalBalance();

            if (intrinsicDEXVolTokenBalance + dexUSDCAmount > liquidityMissing && 
                (intrinsicDEXVolTokenBalance + dexUSDCAmount - liquidityMissing) * MAX_PERCENTAGE / balance >= _thetaVault.minDexPercentageAllowed()) {

                (uint256 units, uint256 tokens) = _getPositionAmount(_thetaVault, liquidityMissing);
                (newTotalUnits, newTotalTokens) = _simulateBurn(_totalUnits, _totalTokens, units, tokens);
                (newTotalUnits, newTotalTokens) =  _simulatePlatformDeposit(newTotalUnits, newTotalTokens, liquidityMissing);
            }
        }
    }

    function willWithdrawSucceed(IThetaVault _thetaVault, uint256 _withdrawAmount) external view override returns (bool success) {
        IPlatform platform = _thetaVault.volToken().platform();

        uint256 totalPositionUnitsAmount = platform.totalPositionUnitsAmount();
        uint256 totalLeveragedTokensAmount = platform.totalLeveragedTokensAmount();

        (totalPositionUnitsAmount, totalLeveragedTokensAmount) = _simulateRebalance(_thetaVault, totalPositionUnitsAmount, totalLeveragedTokensAmount);
        (totalPositionUnitsAmount, totalLeveragedTokensAmount) = _simulateThetaWithdraw(_thetaVault, totalPositionUnitsAmount, totalLeveragedTokensAmount, _withdrawAmount);
        return totalLeveragedTokensAmount >= totalPositionUnitsAmount;
    }

    function maxMintAmount(IVolatilityToken _volToken) external view override returns (uint256 maxAmount) {
        (uint32 cviValue,,) = _volToken.platform().cviOracle().getCVILatestRoundData();
        (uint256 totalPositionUnitsAmount, uint256 totalLeveragedTokensAmount,) = calculateLiquidity(_volToken, 0, 0, 0);
        maxAmount = (totalLeveragedTokensAmount - totalPositionUnitsAmount) * cviValue / _volToken.platform().maxCVIValue();
    }

    function calculateLiquidity(IVolatilityToken _volToken, uint256 _tokenAmount, uint256 _openPositionFee, uint256 _buyingPremiumFee) private view returns (uint256 totalPositionUnitsAmount, uint256 totalLeveragedTokensAmount, bool insufficientLiquidity) {
        (uint32 cviValue,,) = _volToken.platform().cviOracle().getCVILatestRoundData();
        uint256 positionedTokenAmount = (_tokenAmount - _openPositionFee - _buyingPremiumFee) * _volToken.leverage();
        uint256 positionUnitsAmount = uint256(positionedTokenAmount) * _volToken.platform().maxCVIValue() / cviValue;
        totalPositionUnitsAmount = _volToken.platform().totalPositionUnitsAmount() + positionUnitsAmount;
        totalLeveragedTokensAmount = _volToken.platform().totalLeveragedTokensAmount() + positionedTokenAmount + _buyingPremiumFee;
        insufficientLiquidity = totalPositionUnitsAmount > totalLeveragedTokensAmount;
    }

    function calculateCommonFees(IVolatilityToken _volToken, bool _isKeepers, uint256 _tokenAmount, uint256 _timeWindow) private view returns (uint256 timeWindowFee, uint256 keepersFee) {
        timeWindowFee = _tokenAmount * _volToken.requestFeesCalculator().calculateTimeDelayFee(_timeWindow) / MAX_PERCENTAGE;
        keepersFee = _isKeepers ? _volToken.requestFeesCalculator().calculateKeepersFee(_tokenAmount) : 0; 
    }

    function calculatePenaltyFee(IVolatilityToken _volToken, bool _isKeepers, IVolatilityToken.Request memory _request, uint256 _tokenAmount) private view returns (uint256 timePenaltyFee) {
        timePenaltyFee = 0;
        if (!_isKeepers && (block.timestamp > _request.requestTimestamp + _volToken.requestFeesCalculator().minWaitTime() && block.timestamp < _request.targetTimestamp)) {
            timePenaltyFee = _tokenAmount * _volToken.requestFeesCalculator().calculateTimePenaltyFee(_request) / MAX_PERCENTAGE;
        }
    }

    function calculateMintFees(IVolatilityToken _volToken, uint256 _tokenAmount) private view returns (uint256 openPositionFee, uint256 buyingPremiumFee, uint buyingPremiumFeePercentage) {
        openPositionFee = _tokenAmount * _volToken.platform().feesCalculator().openPositionFeePercent() * _volToken.leverage() / MAX_PERCENTAGE;

        (uint32 cviValue,,) = _volToken.platform().cviOracle().getCVILatestRoundData();

        uint256 lastLeveragedTokensAmount = _volToken.platform().totalLeveragedTokensAmount();
        uint256 lastTotalPositionUnitsAmount =  _volToken.platform().totalPositionUnitsAmount();

        uint256 maxPositionUnitsAmount = (_tokenAmount - openPositionFee) * _volToken.leverage() * _volToken.platform().maxCVIValue() / cviValue;
        uint256 totalPositionUnitsAmount = _volToken.platform().totalPositionUnitsAmount() + maxPositionUnitsAmount;
        uint256 leveragedTokensAmount = _volToken.platform().totalLeveragedTokensAmount() + (_tokenAmount - openPositionFee) * _volToken.leverage();

        (buyingPremiumFee, buyingPremiumFeePercentage) = 
            _volToken.platform().feesCalculator().calculateBuyingPremiumFee(uint168(_tokenAmount), _volToken.leverage(), 
                lastLeveragedTokensAmount, lastTotalPositionUnitsAmount, leveragedTokensAmount, totalPositionUnitsAmount);
    }

    function calculateBurnFees(IVolatilityToken _volToken, uint256 _volTokensAmount) private view returns (uint256 burnUSDCAmountBeforeFees, uint256 closeFee) {
        burnUSDCAmountBeforeFees = _volTokensAmount * calculateVolTokenPositionBalance(_volToken) / IERC20(address(_volToken)).totalSupply();
        closeFee = burnUSDCAmountBeforeFees * (_volToken.platform().feesCalculator().closePositionLPFeePercent() + 
            _volToken.platform().feesCalculator().calculateClosePositionFeePercent(0, true)) / MAX_PERCENTAGE;
    }

    function calculatePreMint(IVolatilityToken _volToken, bool _isKeepers, uint256 _usdcAmount, uint256 _timeWindow) external view override returns (PreMintResult memory result) {
        (result.timeWindowFee, result.keepersFee) = calculateCommonFees(_volToken, _isKeepers, _usdcAmount, _timeWindow);
        result.netMintAmount = _usdcAmount - result.timeWindowFee - result.keepersFee;

        (result.openPositionFee, result.buyingPremiumFee, result.buyingPremiumFeePercentage) = calculateMintFees(_volToken, _usdcAmount);
        result.netMintAmount = result.netMintAmount - result.openPositionFee - uint168(result.buyingPremiumFee);

        uint256 supply = IERC20(address(_volToken)).totalSupply();
        uint256 balance = calculateVolTokenPositionBalance(_volToken);
        if (supply > 0 && balance > 0) {
            result.expectedVolTokensAmount = uint256(result.netMintAmount) * supply / balance;
        } else {
            result.expectedVolTokensAmount = uint256(result.netMintAmount) * _volToken.initialTokenToLPTokenRate();
        }
    }

    function checkMintRequest(IVolatilityToken _volToken, uint256 _requestId, bool _isKeepers) external view override returns (CheckMintResult memory result) {
        IVolatilityToken.Request memory request; 
        (request.requestType, request.tokenAmount,,,, request.requestTimestamp, request.targetTimestamp, request.useKeepers, request.maxBuyingPremiumFeePercentage) = _volToken.requests(_requestId);
        require(request.requestType == 1, 'Invalid request id');

        uint256 timeWindowFee;
        (timeWindowFee, result.keepersFee) = calculateCommonFees(_volToken, _isKeepers, request.tokenAmount, request.targetTimestamp - request.requestTimestamp);
        result.timePenaltyFee = calculatePenaltyFee(_volToken, _isKeepers, request, request.tokenAmount);
        result.netMintAmount = request.tokenAmount - timeWindowFee - result.keepersFee - result.timePenaltyFee;

        (result.openPositionFee, result.buyingPremiumFee, result.buyingPremiumFeePercentage) = calculateMintFees(_volToken, request.tokenAmount);
        result.netMintAmount = result.netMintAmount - uint168(result.openPositionFee) - uint168(result.buyingPremiumFee);

        (,, result.insufficientLiquidity) = calculateLiquidity(_volToken, request.tokenAmount, result.openPositionFee, result.buyingPremiumFee);
        result.insufficientSlippage = result.buyingPremiumFeePercentage > request.maxBuyingPremiumFeePercentage;

        uint256 supply = IERC20(address(_volToken)).totalSupply();
        uint256 balance = calculateVolTokenPositionBalance(_volToken);
        if (supply > 0 && balance > 0) {
            result.expectedVolTokensAmount = uint256(result.netMintAmount) * supply / balance;
        } else {
            result.expectedVolTokensAmount = uint256(result.netMintAmount) * _volToken.initialTokenToLPTokenRate();
        }
    }

    function calculatePreBurn(IVolatilityToken _volToken, bool _isKeepers, uint256 _volTokensAmount, uint256 _timeWindow) external view override returns (PreBurnResult memory result) {
        uint256 burnUSDCAmountBeforeFees;
        (burnUSDCAmountBeforeFees, result.closeFee) = calculateBurnFees(_volToken, _volTokensAmount);
        result.expectedUSDCAmount = burnUSDCAmountBeforeFees - result.closeFee;

        (result.timeWindowFee, result.keepersFee) = calculateCommonFees(_volToken, _isKeepers, result.expectedUSDCAmount, _timeWindow);

        result.expectedUSDCAmount = result.expectedUSDCAmount - result.timeWindowFee - result.keepersFee;
        result.netBurnAmount = _volTokensAmount * result.expectedUSDCAmount / burnUSDCAmountBeforeFees;
    }

    function checkBurnRequest(IVolatilityToken _volToken, uint256 _requestId, bool _isKeepers) external view override returns (CheckBurnResult memory result) {
        IVolatilityToken.Request memory request; 
        (request.requestType, request.tokenAmount,,,, request.requestTimestamp, request.targetTimestamp, request.useKeepers,) = _volToken.requests(_requestId);
        require(request.requestType == 2, 'Invalid request id');

        uint256 tokenAmount = IElasticToken(address(_volToken)).underlyingToValue(request.tokenAmount);

        uint256 burnUSDCAmountBeforeFees;
        (burnUSDCAmountBeforeFees, result.closeFee) = calculateBurnFees(_volToken, tokenAmount);
        result.expectedUSDCAmount = burnUSDCAmountBeforeFees - result.closeFee;

        result.timePenaltyFee = calculatePenaltyFee(_volToken, _isKeepers, request, burnUSDCAmountBeforeFees);
        uint256 timeWindowFee;
        (timeWindowFee, result.keepersFee) = calculateCommonFees(_volToken, _isKeepers, result.expectedUSDCAmount, request.targetTimestamp - request.requestTimestamp);

        result.expectedUSDCAmount = result.expectedUSDCAmount - timeWindowFee - result.timePenaltyFee - result.keepersFee;
        result.netBurnAmount = tokenAmount * result.expectedUSDCAmount / burnUSDCAmountBeforeFees;
    }

    function convertGOVIToXGOVI(uint256 _goviAmount) external view override returns (uint256 xGOVIAmount) { 
        uint256 totalStaked = govi.balanceOf(address(staking));
        uint256 addedReward = staking.rewardPerSecond() * (block.timestamp - staking.lastUpdateTime());
        uint256 totalSupply = IERC20(address(staking)).totalSupply();
        if (totalStaked + addedReward > 0) {
            xGOVIAmount = _goviAmount * totalSupply / (totalStaked + addedReward);
        }
    }

    function convertXGOVIToGOVI(uint256 _xGOVIAmount) external view override returns (uint256 goviAmount) { 
        uint256 totalStaked = govi.balanceOf(address(staking));
        uint256 addedReward = staking.rewardPerSecond() * (block.timestamp - staking.lastUpdateTime());
        uint256 totalSupply = IERC20(address(staking)).totalSupply();
        if (totalSupply > 0) {
            goviAmount = (totalStaked + addedReward) * _xGOVIAmount / totalSupply;
        }
    }

    function stakedGOVI(address _account) external view override returns (uint256 stakedAmount, uint256 share) {
        stakedAmount = this.convertXGOVIToGOVI(IERC20(address(staking)).balanceOf(_account));
        if (stakedAmount > 0) {
            share = IERC20(address(staking)).balanceOf(_account) * MAX_PERCENTAGE / IERC20(address(staking)).totalSupply();
        }
    }

    function calculateStakingAPR() external view override returns (uint256 apr) {
        uint256 totalStaked = govi.balanceOf(address(staking));
        uint256 periodReward = staking.rewardPerSecond() * 1 days * 365;
        apr = totalStaked == 0 ?  0 : periodReward * MAX_PERCENTAGE / totalStaked;
    }

    function calculateVolTokenPositionBalance(IVolatilityToken _volToken) private view returns (uint256 volTokenBalance) {
        IPlatform platform = _volToken.platform();

        bool isPositive = true;
        (uint256 currPositionUnits,,,,) = platform.positions(address(_volToken));
        if (currPositionUnits != 0) {
            (volTokenBalance, isPositive,,,,) = platform.calculatePositionBalance(address(_volToken));
        }
        require(isPositive, "Negative balance");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

    string private _name;
    string private _symbol;

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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStaking {
    event ProfitAdded(address indexed token, uint256 profit);
    event Staked(address indexed account, uint256 goviAmount, uint256 xGOVIMinted, uint256 xGOVIBalance);
    event Unstaked(address indexed account, uint256 xGOVIBurned, uint256 goviReward, uint256 xGOVIBalance);
    event RewardClaimed(address indexed account, address indexed token, uint256 reward);

	function stake(uint256 goviAmount) external returns (uint256 xGOVIAmount);
	function unstake(uint256 xGOVIAmount) external returns (uint256 goviAmount);

    function claimProfit(IERC20Upgradeable token) external returns (uint256);
    function claimAllProfits() external returns (uint256[] memory profits);

    function addClaimableToken(IERC20Upgradeable newClaimableToken) external;
    function removeClaimableToken(IERC20Upgradeable removedClaimableToken) external;

    function setStakingLockupTime(uint256 newLockupTime) external;
    function setRewardRate(uint256 newRewardPerSecond) external;

    function profitOf(address account, IERC20Upgradeable token) external view returns (uint256);
    function getClaimableTokens() external view returns (IERC20Upgradeable[] memory);

    function rewardPerSecond() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);

    receive() external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IPlatform.sol";
import "./IVolatilityToken.sol";
import "./IElasticToken.sol";
import "./IThetaVault.sol";
import "./IUniswapV3LiquidityManager.sol";

interface IPlatformHelper {

    struct PreMintResult {
        uint256 netMintAmount;
        uint256 expectedVolTokensAmount;
        uint256 buyingPremiumFeePercentage;
        uint256 openPositionFee;
        uint256 buyingPremiumFee;
        uint256 timeWindowFee;
        uint256 keepersFee;
    }

    struct PreBurnResult {
        uint256 netBurnAmount;
        uint256 expectedUSDCAmount;
        uint256 closeFee;
        uint256 timeWindowFee;
        uint256 keepersFee;
    }

    struct CheckMintResult {
        uint256 netMintAmount;
        uint256 expectedVolTokensAmount;
        uint256 buyingPremiumFeePercentage;
        uint256 openPositionFee;
        uint256 buyingPremiumFee;
        uint256 timePenaltyFee;
        uint256 keepersFee;
        bool insufficientLiquidity;
        bool insufficientSlippage;
    }

    struct CheckBurnResult {
        uint256 netBurnAmount;
        uint256 expectedUSDCAmount;
        uint256 closeFee;
        uint256 timePenaltyFee;
        uint256 keepersFee;
    }

    function dailyFundingFee(IPlatform platform) external view returns (uint256 fundingFeePercent);
    function fundingFeeValues(IPlatform platform, uint32 minCVI, uint32 maxCVI, uint256 minCollateral, uint256 maxCollateral) external view returns (uint256[][] memory fundingFeeRatePercent);   	
    function collateralRatio(IPlatform platform) external view returns (uint256);
    function premiumFeeCollateralRatio(IPlatform platform) external view returns (uint256);

    function volTokenIntrinsicPrice(IVolatilityToken volToken) external view returns (uint256);
    function volTokenDexPrice(IThetaVault thetaVault) external view returns (uint256);
    function volTokenDexPriceV3(IUniswapV3LiquidityManager _uniswapLiquidityManager) external view returns (uint256);

    function maxMintAmount(IVolatilityToken volToken) external view returns (uint256 maxAmount);
    function maxWithdrawAmount(IThetaVault thetaVault) external view returns (uint256 maxAmount, uint256 maxUSDCAmount);
    function willWithdrawSucceed(IThetaVault thetaVault, uint256 withdrawAmount) external view returns (bool success);

    function calculatePreMint(IVolatilityToken volToken, bool isKeepers, uint256 usdcAmount, uint256 timeWindow) external view returns (PreMintResult memory result);
    function calculatePreBurn(IVolatilityToken volToken, bool isKeepers, uint256 volTokensAmount, uint256 timeWindow) external view returns (PreBurnResult memory result);

    function checkMintRequest(IVolatilityToken volToken, uint256 requestId, bool isKeepers) external view returns (CheckMintResult memory result);
    function checkBurnRequest(IVolatilityToken volToken, uint256 requestId, bool isKeepers) external view returns (CheckBurnResult memory result);

    function convertGOVIToXGOVI(uint256 amount) external view returns (uint256 xGOVIAmount);
    function convertXGOVIToGOVI(uint256 xGOVIAmount) external view returns (uint256 goviAmount);
    function stakedGOVI(address account) external view returns (uint256 stakedAmount, uint256 share);
    function calculateStakingAPR() external view returns (uint256 apr);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IFeesCalculator.sol";
import "./IRewardsCollector.sol";
import "./IFeesCollector.sol";
import "./ILiquidation.sol";

interface IPlatform {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint32 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function increaseSharedPool(uint256 tokenAmount) external;

    function openPositionWithoutFee(uint168 tokenAmount, uint32 maxCVI, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function openPosition(uint168 tokenAmount, uint32 maxCVI, uint16 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionWithoutFee(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function closePosition(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);

    function setAddressSpecificParameters(address holderAddress, bool shouldLockPosition, bool noPremiumFeeAllowed, bool increaseSharedPoolAllowed, bool isLiquidityProvider) external;

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setSubContracts(IFeesCollector newCollector, ICVIOracle newOracle, IRewardsCollector newRewards, ILiquidation newLiquidation, address _newStakingContractAddress) external;
    function setFeesCalculator(IFeesCalculator newCalculator) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;
    function setMaxTimeAllowedAfterLatestRound(uint32 newMaxTimeAllowedAfterLatestRound) external;

    function setLockupPeriods(uint256 newLPLockupPeriod, uint256 newBuyersLockupPeriod) external;

    function setEmergencyParameters(bool newEmergencyWithdrawAllowed, bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance(bool _withAddendum) external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function cviOracle() external view returns (ICVIOracle);
    function feesCalculator() external view returns (IFeesCalculator);

    function PRECISION_DECIMALS() external view returns (uint256);

    function totalPositionUnitsAmount() external view returns (uint256);
    function totalLeveragedTokensAmount() external view returns (uint256);
    function totalFundingFeesAmount() external view returns (uint256);
    function latestFundingFees() external view returns (uint256);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint32 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
    function buyersLockupPeriod() external view returns (uint256);
    function maxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IPlatform.sol";
import "./IRequestFeesCalculator.sol";
import "./ICVIOracle.sol";

interface IVolatilityToken {

    struct Request {
        uint8 requestType; // 1 => mint, 2 => burn
        uint168 tokenAmount;
        uint16 timeDelayRequestFeesPercent;
        uint16 maxRequestFeesPercent;
        address owner;
        uint32 requestTimestamp;
        uint32 targetTimestamp;
        bool useKeepers;
        uint16 maxBuyingPremiumFeePercentage;
    }

    event SubmitRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 tokenAmount, uint256 submitFeesAmount, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
    event FulfillRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 fulfillFeesAmount, bool isAborted, bool useKeepers, bool keepersCalled, address indexed fulfiller, uint32 fulfillTimestamp);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 findersFeeAmount, bool useKeepers, uint32 liquidateTimestamp);
    event Mint(uint256 requestId, address indexed account, uint256 tokenAmount, uint256 positionedTokenAmount, uint256 mintedTokens, uint256 openPositionFee, uint256 buyingPremiumFee);
    event Burn(uint256 requestId, address indexed account, uint256 tokenAmountBeforeFees, uint256 tokenAmount, uint256 burnedTokens, uint256 closePositionFee, uint256 closingPremiumFee);

    function rebaseCVI() external;

    function submitMintRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersMintRequest(uint168 tokenAmount, uint32 timeDelay, uint16 maxBuyingPremiumFeePercentage) external returns (uint256 requestId);
    function submitBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);

    function fulfillMintRequest(uint256 requestId, uint16 maxBuyingPremiumFeePercentage, bool keepersCalled) external returns (uint256 tokensMinted, bool success);
    function fulfillBurnRequest(uint256 requestId, bool keepersCalled) external returns (uint256 tokensBurned);

    function mintTokens(uint168 tokenAmount) external returns (uint256 mintedTokens);
    function burnTokens(uint168 burnAmount) external returns (uint256 tokenAmount);

    function liquidateRequest(uint256 requestId) external returns (uint256 findersFeeAmount);

    function setMinter(address minter) external;
    function setPlatform(IPlatform newPlatform) external;
    function setFeesCalculator(IFeesCalculator newFeesCalculator) external;
    function setFeesCollector(IFeesCollector newCollector) external;
    function setRequestFeesCalculator(IRequestFeesCalculator newRequestFeesCalculator) external;
    function setCVIOracle(ICVIOracle newCVIOracle) external;
    function setDeviationParameters(uint16 newDeviationPercentagePerSingleRebaseLag, uint16 newMinDeviationPercentage, uint16 newMaxDeviationPercentage) external;
    function setVerifyTotalRequestsAmount(bool verifyTotalRequestsAmount) external;
    function setMaxTotalRequestsAmount(uint256 maxTotalRequestsAmount) external;
    function setCappedRebase(bool newCappedRebase) external;

    function setMinRequestId(uint256 newMinRequestId) external;
    function setMaxMinRequestIncrements(uint256 newMaxMinRequestIncrements) external;

    function setFulfiller(address fulfiller) external;

    function setKeepersFeeVaultAddress(address newKeepersFeeVaultAddress) external;

    function setMinKeepersAmounts(uint256 newMinKeepersMintAmount, uint256 newMinKeepersBurnAmount) external;

    function platform() external view returns (IPlatform);
    function requestFeesCalculator() external view returns (IRequestFeesCalculator);
    function leverage() external view returns (uint8);
    function initialTokenToLPTokenRate() external view returns (uint256);

    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint16 timeDelayRequestFeesPercent, uint16 maxRequestFeesPercent,
        address owner, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IElasticToken {

    event Rebase(uint256 epoch, uint256 prevScalingFactor, uint256 newScalingFactor);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function balanceOfUnderlying(address who) external view returns(uint256);
    function maxScalingFactor() external view returns (uint256);
    function underlyingToValue(uint256 unerlyingValue) external view returns (uint256);
    function valueToUnderlying(uint256 value) external view returns (uint256);

    function setRebaser(address rebaser) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-staking/contracts/interfaces/IRewardRouter.sol';

import "./IThetaVaultInfo.sol";
import "./IVolatilityToken.sol";

import './IUniswapHelper.sol';

import '../external/ISwapRouter.sol';
import '../external/INonfungiblePositionManager.sol';

interface IThetaVault is IThetaVaultInfo {

    event SubmitRequest(uint256 requestId, uint8 requestType, uint256 tokenAmount, uint32 targetTimestamp, address indexed account, uint256 totalUSDCBalance, uint256 totalSupply);
    event FulfillDeposit(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenUSDCAmount, uint256 dexVolTokenAmount, uint256 dexUSDCAmount, uint256 mintedThetaTokens);
    event FulfillWithdraw(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenAmount, uint256 dexUSDCVolTokenAmount, uint256 dexUSDCAmount, uint256 burnedThetaTokens);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 tokenAmount);

    function submitDepositRequest(uint168 tokenAmount/* , bool shouldStake */) external returns (uint256 requestId);
    function submitWithdrawRequest(uint168 thetaTokenAmount) external returns (uint256 requestId);

    function fulfillDepositRequest(uint256 requestId) external returns (uint256 thetaTokensMinted);
    function fulfillWithdrawRequest(uint256 requestId) external returns (uint256 tokenWithdrawnAmount);

    function liquidateRequest(uint256 requestId) external;

    function rebalance() external;

    function setRewardRouter(IRewardRouter rewardRouter) external;
    function setFulfiller(address newFulfiller) external;
    function setMinPoolSkew(uint16 newMinPoolSkewPercentage) external;
    function setLiquidityPercentages(uint16 newExtraLiquidityPercentage, uint16 minDexPercentageAllowed) external;
    function setRequestDelay(uint256 newRequestDelay) external;
    function setDepositCap(uint256 newDepositCap) external;
    function setPeriods(uint256 newLockupPeriod, uint256 newLiquidationPeriod) external;
    function setMinAmounts(uint256 newMinDepositAmount, uint256 newMinWithdrawAmount) external;
    function setDepositHoldings(uint16 newDepositHoldingsPercentage) external;
    
    function volToken() external view returns (IVolatilityToken);

    function totalBalance() external view returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount);
    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint32 targetTimestamp, address owner, bool shouldStake);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IUniswapV3LiquidityManager {

    function addDEXLiquidity(uint256 mintedVolTokenAmount, uint256 usdcAmount) external returns (uint256 addedUDSCAmount, uint256 addedVolTokenAmount);
    function removeDEXLiquidity(uint256 partOfAmount, uint256 totalAmount) external returns (uint256 removedVolTokensAmount, uint256 dexRemovedUSDC);
    function burnPosition() external;
    function setRange(uint160 minPriceSqrtX96, uint160 maxPriceSqrtX96) external;
    function collectFees() external returns (uint256 volTokenAmount, uint256 usdcAmount);
    function updatePoolPrice(uint256 volTokenPositionBalance) external;
    function hasPosition() external view returns (bool);
    function calculateDEXLiquidityUSDCAmount(uint256 tokenAmount) external view returns (uint256 usdcDEXAmount);
    function calculateArbitrageAmount(uint256 volTokenBalance) external view returns (uint256 usdcAmount);

    struct CalculateDepositParams {
        uint256 depositAmount;
        uint256 cviValue;
        uint256 intrinsicVolTokenPrice;
        uint256 maxCVIValue;
        uint256 extraLiquidityPercentage;
    }

    function calculateDepositMintVolTokensUSDCAmount(CalculateDepositParams calldata params) external view returns (uint256 mintVolTokenUDSCAmount);
    function getReserves() external view returns (uint256 volTokenAmount, uint256 dexUSDCByVolToken, uint256 usdcAmount);
    function getVaultDEXVolTokens() external view returns (uint256 vaultDEXVolTokens);
    function getVaultDEXBalance(uint256 intrinsicDEXVolTokenBalance, uint256 dexUSDCAmount) external view returns (uint256 vaultIntrinsicDEXVolTokenBalance, uint256 vaultDEXUSDCAmount);
    function getDexPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IThetaVaultInfo.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint32 cviValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint32 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 lastCVIValue, uint32 currCVIValue) external;

    function setOracle(ICVIOracle cviOracle) external;
    function setThetaVault(IThetaVaultInfo thetaVault) external;

    function setStateUpdator(address newUpdator) external;

    function setFundingFeeMinRate(uint32 newFundingFeeMinRate) external;
    function setFundingFeeMaxRate(uint32 newFundingFeeMaxRate) external;
    function setMinFundingFeeCviThreshold(uint32 newMinFundingFeeCviThreshold) external;
    function setMaxFundingFeeCviThreshold(uint32 newMaxFundingFeeCviThreshold) external;
    function setFundingFeeDivisionFactor(uint32 newFundingFeeDivisionFactor) external;
    function setFundingFeeCoefficients(uint32[] calldata newFundingFeeCoefficients) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setOpenPositionLPFee(uint16 newOpenPositionLPFeePercent) external;
    function setClosePositionLPFee(uint16 newClosePositionLPFeePercent) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setClosingPremiumFeeMax(uint16 newClosingPremiumFeeMaxPercentage) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;
    function setFundingFeeConstantRate(uint16 newfundingFeeConstantRate) external;
    function setCollateralToExtraFundingFeeMapping(uint32[] calldata newCollateralToExtraFundingFeeMapping) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 _lastCVIValue, uint32 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithAddendum(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);

    function calculateClosingPremiumFee() external view returns (uint16 combinedPremiumFeePercentage);

    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 fundingFee);
    function calculateSingleUnitPeriodFundingFee(CVIValue memory cviValue, uint256 collateralRatio) external view returns (uint256 fundingFee, uint256 fundingFeeRatePercents);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateClosePositionFeePercent(uint256 creationTimestamp, bool isNoLockPositionAddress) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function calculateCollateralRatio(uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 collateralRatio);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function openPositionLPFeePercent() external view returns (uint16);
    function closePositionLPFeePercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
    function oracleLeverage() external view returns (uint8);

    function getCollateralToBuyingPremiumMapping() external view returns(uint16[] memory);
    function getCollateralToExtraFundingFeeMapping() external view returns(uint32[] memory);
    function getFundingFeeCoefficients() external view returns(uint32[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRewardsCollector {
	function reward(address account, uint256 positionUnits, uint8 leverage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ILiquidation {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
	function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IThetaVaultInfo {
    function totalVaultLeveragedAmount() external view returns (uint256);
    function vaultPositionUnits() external view returns (uint256);
    function extraLiquidityPercentage() external view returns (uint16);
    function minDexPercentageAllowed() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IVolatilityToken.sol";

interface IRequestFeesCalculator {
    function calculateTimePenaltyFee(IVolatilityToken.Request calldata request) external view returns (uint16 feePercentage);
    function calculateTimeDelayFee(uint256 timeDelay) external view returns (uint16 feePercentage);
    function calculateFindersFee(uint256 tokensLeftAmount) external view returns (uint256 findersFeeAmount);
    function calculateKeepersFee(uint256 tokensAmount) external view returns (uint256 keepersFeeAmount);

    function isLiquidable(IVolatilityToken.Request calldata request) external view returns (bool liquidable);

    function minWaitTime() external view returns (uint32);

    function setTimeWindow(uint32 minTimeWindow, uint32 maxTimeWindow) external;
    function setTimeDelayFeesParameters(uint16 minTimeDelayFeePercent, uint16 maxTimeDelayFeePercent) external;
    function setMinWaitTime(uint32 newMinWaitTime) external;
    function setTimePenaltyFeeParameters(uint16 beforeTargetTimeMaxPenaltyFeePercent, uint32 afterTargetMidTime, uint16 afterTargetMidTimePenaltyFeePercent, uint32 afterTargetMaxTime, uint16 afterTargetMaxTimePenaltyFeePercent) external;
    function setFindersFee(uint16 findersFeePercent) external;
    function setKeepersFeePercent(uint16 keepersFeePercent) external;
    function setKeepersFeeMax(uint256 keepersFeeMax) external;

    function getMaxFees() external view returns (uint16 maxFeesPercent);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';
import './IVester.sol';

enum StakedTokenName {
  THETA_VAULT,
  ES_GOVI,
  GOVI,
  LENGTH
}

interface IRewardRouter {
  event StakeToken(address indexed account, address indexed tokenName, uint256 amount);
  event UnstakeToken(address indexed account, address indexed tokenName, uint256 amount);

  function stake(StakedTokenName _token, uint256 _amount) external;

  function stakeForAccount(
    StakedTokenName _token,
    address _account,
    uint256 _amount
  ) external;

  function batchStakeForAccount(
    StakedTokenName _tokenName,
    address[] memory _accounts,
    uint256[] memory _amounts
  ) external;

  function unstake(StakedTokenName _token, uint256 _amount) external;

  function claim(StakedTokenName _token) external;

  function compound(StakedTokenName _tokenName) external;

  function compoundForAccount(address _account, StakedTokenName _tokenName) external;

  function batchCompoundForAccounts(address[] memory _accounts, StakedTokenName _tokenName) external;

  function setRewardTrackers(StakedTokenName[] calldata _tokenNames, IRewardTracker[] calldata _rewardTrackers)
    external;

  function setVesters(StakedTokenName[] calldata _tokenNames, IVester[] calldata _vesters) external;

  function setTokens(StakedTokenName[] calldata _tokenNames, address[] calldata _tokens) external;

  function rewardTrackers(StakedTokenName _token) external view returns (IRewardTracker);

  function vesters(StakedTokenName _token) external view returns (IVester);

  function tokens(StakedTokenName _token) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6;

pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IUniswapHelper {

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external view returns (int24 tick);
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96);
    function getSpotPrice(IUniswapV3Pool pool, bool isVolTokenToken0) external view returns (uint256 price);
    function getTWAPPriceDelta(IUniswapV3Pool pool, uint32 interval) external view returns (uint256 priceChange, uint256 fromPrice);

    function getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0) external pure returns (uint128 liquidity);
    function getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount1) external pure returns (uint128 liquidity);
    function getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) external pure returns (uint256 amount0);
    function getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) external pure returns (uint256 amount1);
    function uint256ToX96(uint256 number) external pure returns (uint160 result);

    function PRECISION_DECIMALS() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

interface INonfungiblePositionManager is IERC721Metadata
{
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function burn(uint256 tokenId) external payable;

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

interface IRewardTracker {
  event Claim(address indexed receiver, uint256 amount);

  function stake(address _depositToken, uint256 _amount) external;

  function stakeForAccount(
    address _fundingAccount,
    address _account,
    address _depositToken,
    uint256 _amount
  ) external;

  function unstake(address _depositToken, uint256 _amount) external;

  function unstakeForAccount(
    address _account,
    address _depositToken,
    uint256 _amount,
    address _receiver
  ) external;

  function claim(address _receiver) external returns (uint256);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function updateRewards() external;

  function depositBalances(address _account, address _depositToken) external view returns (uint256);

  function stakedAmounts(address _account) external view returns (uint256);

  function averageStakedAmounts(address _account) external view returns (uint256);

  function cumulativeRewards(address _account) external view returns (uint256);

  function claimable(address _account) external view returns (uint256);

  function tokensPerInterval() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';

interface IVester {
  event Claim(address indexed receiver, uint256 amount);
  event Deposit(address indexed account, uint256 amount);
  event Withdraw(address indexed account, uint256 claimedAmount, uint256 balance);
  event PairTransfer(address indexed from, address indexed to, uint256 value);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function transferStakeValues(address _sender, address _receiver) external;

  function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

  function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

  function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

  function setBonusRewards(address _account, uint256 _amount) external;

  function rewardTracker() external view returns (IRewardTracker);

  function claimable(address _account) external view returns (uint256);

  function cumulativeClaimAmounts(address _account) external view returns (uint256);

  function claimedAmounts(address _account) external view returns (uint256);

  function pairAmounts(address _account) external view returns (uint256);

  function getVestedAmount(address _account) external view returns (uint256);

  function transferredAverageStakedAmounts(address _account) external view returns (uint256);

  function transferredCumulativeRewards(address _account) external view returns (uint256);

  function cumulativeRewardDeductions(address _account) external view returns (uint256);

  function bonusRewards(address _account) external view returns (uint256);

  function getMaxVestableAmount(address _account) external view returns (uint256);

  function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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