// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "../interfaces/vaults/IIntegrationVault.sol";
import "../interfaces/vaults/IUniV3Vault.sol";
import "../interfaces/vaults/IAaveVault.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/external/TickMath.sol";
import "../libraries/external/LiquidityAmounts.sol";
import "../strategies/HStrategy.sol";
import "./UniV3Helper.sol";

contract HStrategyHelper {
    uint32 constant DENOMINATOR = 10**9;

    /// @notice calculates the ratios of the capital on all vaults using price from the oracle
    /// @param domainPositionParams the current state of the position, pool and oracle prediction
    /// @return ratios ratios of the capital
    function calculateExpectedRatios(HStrategy.DomainPositionParams memory domainPositionParams)
        external
        pure
        returns (HStrategy.ExpectedRatios memory ratios)
    {
        uint256 denominatorX96 = CommonLibrary.Q96 *
            2 -
            FullMath.mulDiv(
                domainPositionParams.domainLowerPriceSqrtX96,
                CommonLibrary.Q96,
                domainPositionParams.intervalPriceSqrtX96
            ) -
            FullMath.mulDiv(
                domainPositionParams.intervalPriceSqrtX96,
                CommonLibrary.Q96,
                domainPositionParams.domainUpperPriceSqrtX96
            );

        uint256 nominator0X96 = FullMath.mulDiv(
            domainPositionParams.intervalPriceSqrtX96,
            CommonLibrary.Q96,
            domainPositionParams.upperPriceSqrtX96
        ) -
            FullMath.mulDiv(
                domainPositionParams.intervalPriceSqrtX96,
                CommonLibrary.Q96,
                domainPositionParams.domainUpperPriceSqrtX96
            );

        uint256 nominator1X96 = FullMath.mulDiv(
            domainPositionParams.lowerPriceSqrtX96,
            CommonLibrary.Q96,
            domainPositionParams.intervalPriceSqrtX96
        ) -
            FullMath.mulDiv(
                domainPositionParams.domainLowerPriceSqrtX96,
                CommonLibrary.Q96,
                domainPositionParams.intervalPriceSqrtX96
            );

        ratios.token0RatioD = uint32(FullMath.mulDiv(nominator0X96, DENOMINATOR, denominatorX96));
        ratios.token1RatioD = uint32(FullMath.mulDiv(nominator1X96, DENOMINATOR, denominatorX96));

        ratios.uniV3RatioD = DENOMINATOR - ratios.token0RatioD - ratios.token1RatioD;
    }

    /// @notice calculates amount of missing tokens for uniV3 and money vaults
    /// @param moneyVault the strategy money vault
    /// @param expectedTokenAmounts the amount of tokens we expect after rebalance
    /// @param domainPositionParams current position and pool state combined with predictions from the oracle
    /// @param liquidity current liquidity in position
    /// @return missingTokenAmounts amounts of missing tokens
    function calculateMissingTokenAmounts(
        IIntegrationVault moneyVault,
        HStrategy.TokenAmounts memory expectedTokenAmounts,
        HStrategy.DomainPositionParams memory domainPositionParams,
        uint128 liquidity
    ) external view returns (HStrategy.TokenAmounts memory missingTokenAmounts) {
        // for uniV3Vault
        {
            uint256 token0Amount = 0;
            uint256 token1Amount = 0;
            (token0Amount, token1Amount) = LiquidityAmounts.getAmountsForLiquidity(
                domainPositionParams.intervalPriceSqrtX96,
                domainPositionParams.lowerPriceSqrtX96,
                domainPositionParams.upperPriceSqrtX96,
                liquidity
            );

            if (token0Amount < expectedTokenAmounts.uniV3Token0) {
                missingTokenAmounts.uniV3Token0 = expectedTokenAmounts.uniV3Token0 - token0Amount;
            }
            if (token1Amount < expectedTokenAmounts.uniV3Token1) {
                missingTokenAmounts.uniV3Token1 = expectedTokenAmounts.uniV3Token1 - token1Amount;
            }
        }

        // for moneyVault
        {
            (, uint256[] memory maxTvl) = moneyVault.tvl();
            uint256 token0Amount = maxTvl[0];
            uint256 token1Amount = maxTvl[1];

            if (token0Amount < expectedTokenAmounts.moneyToken0) {
                missingTokenAmounts.moneyToken0 = expectedTokenAmounts.moneyToken0 - token0Amount;
            }

            if (token1Amount < expectedTokenAmounts.moneyToken1) {
                missingTokenAmounts.moneyToken1 = expectedTokenAmounts.moneyToken1 - token1Amount;
            }
        }
    }

    /// @notice calculates extra tokens on uniV3 vault
    /// @param expectedTokenAmounts the amount of tokens we expect after rebalance
    /// @param domainPositionParams current position and pool state combined with predictions from the oracle
    /// @return tokenAmounts extra token amounts on UniV3Vault
    function calculateExtraTokenAmountsForUniV3Vault(
        HStrategy.TokenAmounts memory expectedTokenAmounts,
        HStrategy.DomainPositionParams memory domainPositionParams
    ) external pure returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](2);
        (tokenAmounts[0], tokenAmounts[1]) = LiquidityAmounts.getAmountsForLiquidity(
            domainPositionParams.intervalPriceSqrtX96,
            domainPositionParams.lowerPriceSqrtX96,
            domainPositionParams.upperPriceSqrtX96,
            domainPositionParams.liquidity
        );

        if (tokenAmounts[0] > expectedTokenAmounts.uniV3Token0) {
            tokenAmounts[0] -= expectedTokenAmounts.uniV3Token0;
        } else {
            tokenAmounts[0] = 0;
        }

        if (tokenAmounts[1] > expectedTokenAmounts.uniV3Token1) {
            tokenAmounts[1] -= expectedTokenAmounts.uniV3Token1;
        } else {
            tokenAmounts[1] = 0;
        }
    }

    /// @notice calculates extra tokens on money vault
    /// @param moneyVault the strategy money vault
    /// @param expectedTokenAmounts the amount of tokens we expect after rebalance
    /// @return tokenAmounts extra token amounts on MoneyVault
    function calculateExtraTokenAmountsForMoneyVault(
        IIntegrationVault moneyVault,
        HStrategy.TokenAmounts memory expectedTokenAmounts
    ) external view returns (uint256[] memory tokenAmounts) {
        (tokenAmounts, ) = moneyVault.tvl();

        if (tokenAmounts[0] > expectedTokenAmounts.moneyToken0) {
            tokenAmounts[0] -= expectedTokenAmounts.moneyToken0;
        } else {
            tokenAmounts[0] = 0;
        }

        if (tokenAmounts[1] > expectedTokenAmounts.moneyToken1) {
            tokenAmounts[1] -= expectedTokenAmounts.moneyToken1;
        } else {
            tokenAmounts[1] = 0;
        }
    }

    /// @notice calculates expected amounts of tokens after rebalance
    /// @param expectedRatios ratios of the capital on different assets
    /// @param expectedTokenAmountsInToken0 expected capitals (in token0) on the strategy vaults
    /// @param domainPositionParams current position and pool state combined with predictions from the oracle
    /// @param uniV3Helper helper for uniswap V3 calculations
    /// @return amounts amounts of tokens expected after rebalance on the strategy vaults
    function calculateExpectedTokenAmountsByExpectedRatios(
        HStrategy.ExpectedRatios memory expectedRatios,
        HStrategy.TokenAmountsInToken0 memory expectedTokenAmountsInToken0,
        HStrategy.DomainPositionParams memory domainPositionParams,
        UniV3Helper uniV3Helper
    ) external pure returns (HStrategy.TokenAmounts memory amounts) {
        amounts.erc20Token0 = FullMath.mulDiv(
            expectedRatios.token0RatioD,
            expectedTokenAmountsInToken0.erc20TokensAmountInToken0,
            expectedRatios.token0RatioD + expectedRatios.token1RatioD
        );
        amounts.erc20Token1 = FullMath.mulDiv(
            expectedTokenAmountsInToken0.erc20TokensAmountInToken0 - amounts.erc20Token0,
            domainPositionParams.spotPriceX96,
            CommonLibrary.Q96
        );

        amounts.moneyToken0 = FullMath.mulDiv(
            expectedRatios.token0RatioD,
            expectedTokenAmountsInToken0.moneyTokensAmountInToken0,
            expectedRatios.token0RatioD + expectedRatios.token1RatioD
        );
        amounts.moneyToken1 = FullMath.mulDiv(
            expectedTokenAmountsInToken0.moneyTokensAmountInToken0 - amounts.moneyToken0,
            domainPositionParams.spotPriceX96,
            CommonLibrary.Q96
        );

        (amounts.uniV3Token0, amounts.uniV3Token1) = uniV3Helper.getPositionTokenAmountsByCapitalOfToken0(
            domainPositionParams.lowerPriceSqrtX96,
            domainPositionParams.upperPriceSqrtX96,
            domainPositionParams.intervalPriceSqrtX96,
            domainPositionParams.spotPriceX96,
            expectedTokenAmountsInToken0.uniV3TokensAmountInToken0
        );
    }

    /// @notice calculates current amounts of tokens
    /// @param erc20Vault the erc20 vault of the strategy
    /// @param moneyVault the money vault of the strategy
    /// @param params current position and pool state combined with predictions from the oracle
    /// @return amounts amounts of tokens
    function calculateCurrentTokenAmounts(
        IIntegrationVault erc20Vault,
        IIntegrationVault moneyVault,
        HStrategy.DomainPositionParams memory params
    ) external returns (HStrategy.TokenAmounts memory amounts) {
        (amounts.uniV3Token0, amounts.uniV3Token1) = LiquidityAmounts.getAmountsForLiquidity(
            params.intervalPriceSqrtX96,
            params.lowerPriceSqrtX96,
            params.upperPriceSqrtX96,
            params.liquidity
        );

        {
            if (moneyVault.supportsInterface(type(IAaveVault).interfaceId)) {
                IAaveVault(address(moneyVault)).updateTvls();
            }
            (uint256[] memory minMoneyTvl, ) = moneyVault.tvl();
            amounts.moneyToken0 = minMoneyTvl[0];
            amounts.moneyToken1 = minMoneyTvl[1];
        }
        {
            (uint256[] memory erc20Tvl, ) = erc20Vault.tvl();
            amounts.erc20Token0 = erc20Tvl[0];
            amounts.erc20Token1 = erc20Tvl[1];
        }
    }

    /// @notice calculates current capital of the strategy in token0
    /// @param params current position and pool state combined with predictions from the oracle
    /// @param currentTokenAmounts amounts of the tokens on the erc20 and money vaults
    /// @return capital total capital measured in token0
    function calculateCurrentCapitalInToken0(
        HStrategy.DomainPositionParams memory params,
        HStrategy.TokenAmounts memory currentTokenAmounts
    ) external pure returns (uint256 capital) {
        capital =
            currentTokenAmounts.erc20Token0 +
            FullMath.mulDiv(currentTokenAmounts.erc20Token1, CommonLibrary.Q96, params.spotPriceX96) +
            currentTokenAmounts.uniV3Token0 +
            FullMath.mulDiv(currentTokenAmounts.uniV3Token1, CommonLibrary.Q96, params.spotPriceX96) +
            currentTokenAmounts.moneyToken0 +
            FullMath.mulDiv(currentTokenAmounts.moneyToken1, CommonLibrary.Q96, params.spotPriceX96);
    }

    /// @notice calculates expected capitals on the vaults after rebalance
    /// @param totalCapitalInToken0 total capital in token0
    /// @param expectedRatios ratios of the capitals on the vaults expected after rebalance
    /// @param ratioParams_ ratio of the tokens between erc20 and money vault combined with needed deviations for rebalance to be called
    /// @return amounts capitals expected after rebalance measured in token0
    function calculateExpectedTokenAmountsInToken0(
        uint256 totalCapitalInToken0,
        HStrategy.ExpectedRatios memory expectedRatios,
        HStrategy.RatioParams memory ratioParams_
    ) external pure returns (HStrategy.TokenAmountsInToken0 memory amounts) {
        amounts.erc20TokensAmountInToken0 = FullMath.mulDiv(
            totalCapitalInToken0,
            ratioParams_.erc20CapitalRatioD,
            DENOMINATOR
        );
        amounts.uniV3TokensAmountInToken0 = FullMath.mulDiv(
            totalCapitalInToken0 - amounts.erc20TokensAmountInToken0,
            expectedRatios.uniV3RatioD,
            DENOMINATOR
        );
        amounts.moneyTokensAmountInToken0 =
            totalCapitalInToken0 -
            amounts.erc20TokensAmountInToken0 -
            amounts.uniV3TokensAmountInToken0;
        amounts.totalTokensInToken0 = totalCapitalInToken0;
    }

    /// @notice return true if the token swap is needed. It is needed if we cannot mint a new position without it
    /// @param currentTokenAmounts the amounts of tokens on the vaults
    /// @param expectedTokenAmounts the amounts of tokens expected after rebalancing
    /// @param ratioParams ratio of the tokens between erc20 and money vault combined with needed deviations for rebalance to be called
    /// @param domainPositionParams the current state of the position, pool and oracle prediction
    /// @return needed true if the token swap is needed
    function swapNeeded(
        HStrategy.TokenAmounts memory currentTokenAmounts,
        HStrategy.TokenAmounts memory expectedTokenAmounts,
        HStrategy.RatioParams memory ratioParams,
        HStrategy.DomainPositionParams memory domainPositionParams
    ) external pure returns (bool needed) {
        uint256 expectedTotalToken0Amount = expectedTokenAmounts.erc20Token0 +
            expectedTokenAmounts.moneyToken0 +
            expectedTokenAmounts.uniV3Token0;
        uint256 expectedTotalToken1Amount = expectedTokenAmounts.erc20Token1 +
            expectedTokenAmounts.moneyToken1 +
            expectedTokenAmounts.uniV3Token1;

        uint256 currentTotalToken0Amount = currentTokenAmounts.erc20Token0 +
            currentTokenAmounts.moneyToken0 +
            currentTokenAmounts.uniV3Token0;
        int256 token0Delta = int256(currentTotalToken0Amount) - int256(expectedTotalToken0Amount);
        if (token0Delta < 0) {
            token0Delta = -token0Delta;
        }
        int256 minDeviation = int256(
            FullMath.mulDiv(
                expectedTotalToken0Amount +
                    FullMath.mulDiv(expectedTotalToken1Amount, CommonLibrary.Q96, domainPositionParams.spotPriceX96),
                ratioParams.minRebalanceDeviationD,
                DENOMINATOR
            )
        );
        return token0Delta >= minDeviation;
    }

    /// @notice returns true if the rebalance between assets on different vaults is needed
    /// @param currentTokenAmounts the current amounts of tokens on the vaults
    /// @param expectedTokenAmounts the amounts of tokens expected after rebalance
    /// @param ratioParams ratio of the tokens between erc20 and money vault combined with needed deviations for rebalance to be called
    /// @return needed true if the rebalance is needed
    function tokenRebalanceNeeded(
        HStrategy.TokenAmounts memory currentTokenAmounts,
        HStrategy.TokenAmounts memory expectedTokenAmounts,
        HStrategy.RatioParams memory ratioParams
    ) external pure returns (bool needed) {
        uint256 totalToken0Amount = expectedTokenAmounts.erc20Token0 +
            expectedTokenAmounts.moneyToken0 +
            expectedTokenAmounts.uniV3Token0;
        uint256 totalToken1Amount = expectedTokenAmounts.erc20Token1 +
            expectedTokenAmounts.moneyToken1 +
            expectedTokenAmounts.uniV3Token1;

        uint256 minToken0Deviation = FullMath.mulDiv(ratioParams.minCapitalDeviationD, totalToken0Amount, DENOMINATOR);
        uint256 minToken1Deviation = FullMath.mulDiv(ratioParams.minCapitalDeviationD, totalToken1Amount, DENOMINATOR);

        {
            if (
                currentTokenAmounts.erc20Token0 + minToken0Deviation < expectedTokenAmounts.erc20Token0 ||
                currentTokenAmounts.erc20Token0 > expectedTokenAmounts.erc20Token0 + minToken0Deviation ||
                currentTokenAmounts.erc20Token1 + minToken1Deviation < expectedTokenAmounts.erc20Token1 ||
                currentTokenAmounts.erc20Token1 > expectedTokenAmounts.erc20Token1 + minToken1Deviation
            ) {
                return true;
            }
        }

        {
            if (
                currentTokenAmounts.moneyToken0 + minToken0Deviation < expectedTokenAmounts.moneyToken0 ||
                currentTokenAmounts.moneyToken0 > expectedTokenAmounts.moneyToken0 + minToken0Deviation ||
                currentTokenAmounts.moneyToken1 + minToken1Deviation < expectedTokenAmounts.moneyToken1 ||
                currentTokenAmounts.moneyToken1 > expectedTokenAmounts.moneyToken1 + minToken1Deviation
            ) {
                return true;
            }
        }

        {
            if (
                currentTokenAmounts.uniV3Token0 + minToken0Deviation < expectedTokenAmounts.uniV3Token0 ||
                currentTokenAmounts.uniV3Token0 > expectedTokenAmounts.uniV3Token0 + minToken0Deviation ||
                currentTokenAmounts.uniV3Token1 + minToken1Deviation < expectedTokenAmounts.uniV3Token1 ||
                currentTokenAmounts.uniV3Token1 > expectedTokenAmounts.uniV3Token1 + minToken1Deviation
            ) {
                return true;
            }
        }
    }

    /// @param tick current price tick
    /// @param strategyParams_ the current parameters of the strategy
    /// @param uniV3Nft the nft of the position from position manager
    /// @param positionManager_ the position manager for uniV3
    function calculateAndCheckDomainPositionParams(
        int24 tick,
        HStrategy.StrategyParams memory strategyParams_,
        uint256 uniV3Nft,
        INonfungiblePositionManager positionManager_
    ) external view returns (HStrategy.DomainPositionParams memory params) {
        (, , , , , int24 lowerTick, int24 upperTick, uint128 liquidity, , , , ) = positionManager_.positions(uniV3Nft);

        params = HStrategy.DomainPositionParams({
            nft: uniV3Nft,
            liquidity: liquidity,
            lowerTick: lowerTick,
            upperTick: upperTick,
            domainLowerTick: strategyParams_.domainLowerTick,
            domainUpperTick: strategyParams_.domainUpperTick,
            lowerPriceSqrtX96: TickMath.getSqrtRatioAtTick(lowerTick),
            upperPriceSqrtX96: TickMath.getSqrtRatioAtTick(upperTick),
            domainLowerPriceSqrtX96: TickMath.getSqrtRatioAtTick(strategyParams_.domainLowerTick),
            domainUpperPriceSqrtX96: TickMath.getSqrtRatioAtTick(strategyParams_.domainUpperTick),
            intervalPriceSqrtX96: TickMath.getSqrtRatioAtTick(tick),
            spotPriceX96: 0
        });
        params.spotPriceX96 = FullMath.mulDiv(
            params.intervalPriceSqrtX96,
            params.intervalPriceSqrtX96,
            CommonLibrary.Q96
        );
        if (params.intervalPriceSqrtX96 < params.lowerPriceSqrtX96) {
            params.intervalPriceSqrtX96 = params.lowerPriceSqrtX96;
        } else if (params.intervalPriceSqrtX96 > params.upperPriceSqrtX96) {
            params.intervalPriceSqrtX96 = params.upperPriceSqrtX96;
        }
    }

    /// @param tick current price tick
    /// @param pool_ address of uniV3 pool
    /// @param oracleParams_ oracle parameters
    /// @param uniV3Helper helper for uniswap V3 calculations
    function checkSpotTickDeviationFromAverage(
        int24 tick,
        address pool_,
        HStrategy.OracleParams memory oracleParams_,
        UniV3Helper uniV3Helper
    ) external view {
        (bool withFail, int24 deviation) = uniV3Helper.getTickDeviationForTimeSpan(
            tick,
            pool_,
            oracleParams_.averagePriceTimeSpan
        );
        require(!withFail, ExceptionsLibrary.INVALID_STATE);
        if (deviation < 0) {
            deviation = -deviation;
        }
        require(uint24(deviation) <= oracleParams_.maxTickDeviation, ExceptionsLibrary.LIMIT_OVERFLOW);
    }

    /// @param spotTick current price tick
    /// @param strategyParams_ parameters of strategy
    /// @return lowerTick lower tick of new position
    /// @return upperTick upper tick of new position
    function calculateNewPositionTicks(int24 spotTick, HStrategy.StrategyParams memory strategyParams_)
        external
        pure
        returns (int24 lowerTick, int24 upperTick)
    {
        if (spotTick < strategyParams_.domainLowerTick) {
            spotTick = strategyParams_.domainLowerTick;
        } else if (spotTick > strategyParams_.domainUpperTick) {
            spotTick = strategyParams_.domainUpperTick;
        }

        int24 deltaToLowerTick = spotTick - strategyParams_.domainLowerTick;
        deltaToLowerTick -= (deltaToLowerTick % strategyParams_.halfOfShortInterval);
        int24 lowerEstimationCentralTick = strategyParams_.domainLowerTick + deltaToLowerTick;
        int24 upperEstimationCentralTick = lowerEstimationCentralTick + strategyParams_.halfOfShortInterval;
        int24 centralTick = 0;
        if (spotTick - lowerEstimationCentralTick <= upperEstimationCentralTick - spotTick) {
            centralTick = lowerEstimationCentralTick;
        } else {
            centralTick = upperEstimationCentralTick;
        }

        lowerTick = centralTick - strategyParams_.halfOfShortInterval;
        upperTick = centralTick + strategyParams_.halfOfShortInterval;

        if (lowerTick < strategyParams_.domainLowerTick) {
            lowerTick = strategyParams_.domainLowerTick;
            upperTick = lowerTick + (strategyParams_.halfOfShortInterval << 1);
        } else if (upperTick > strategyParams_.domainUpperTick) {
            upperTick = strategyParams_.domainUpperTick;
            lowerTick = upperTick - (strategyParams_.halfOfShortInterval << 1);
        }
    }

    /// @param currentTokenAmounts current token amounts on vaults in both tokens
    /// @param domainPositionParams the current state of the position, pool and oracle prediction
    /// @param hStrategyHelper_ address of HStrategyHelper
    /// @param uniV3Helper helper for uniswap V3 calculations
    /// @param ratioParams ratio parameters
    /// @return expectedTokenAmounts expected amounts of tokens after rebalance on vaults
    function calculateExpectedTokenAmounts(
        HStrategy.TokenAmounts memory currentTokenAmounts,
        HStrategy.DomainPositionParams memory domainPositionParams,
        HStrategyHelper hStrategyHelper_,
        UniV3Helper uniV3Helper,
        HStrategy.RatioParams memory ratioParams
    ) external pure returns (HStrategy.TokenAmounts memory expectedTokenAmounts) {
        HStrategy.ExpectedRatios memory expectedRatios = hStrategyHelper_.calculateExpectedRatios(domainPositionParams);
        uint256 currentCapitalInToken0 = hStrategyHelper_.calculateCurrentCapitalInToken0(
            domainPositionParams,
            currentTokenAmounts
        );
        HStrategy.TokenAmountsInToken0 memory expectedTokenAmountsInToken0 = hStrategyHelper_
            .calculateExpectedTokenAmountsInToken0(currentCapitalInToken0, expectedRatios, ratioParams);
        return
            hStrategyHelper_.calculateExpectedTokenAmountsByExpectedRatios(
                expectedRatios,
                expectedTokenAmountsInToken0,
                domainPositionParams,
                uniV3Helper
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IPeripheryImmutableState, IERC721 {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
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

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/erc/IERC1271.sol";
import "./IVault.sol";

interface IIntegrationVault is IVault, IERC1271 {
    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    /// When called by vault owner this method just pulls the tokens from the protocol to the `to` address
    /// When called by strategy on vault other than zero vault it pulls the tokens to zero vault (required `to` == zero vault)
    /// When called by strategy on zero vault it pulls the tokens to zero vault, pushes tokens on the `to` vault, and reclaims everything that's left.
    /// Thus any vault other than zero vault cannot have any tokens on it
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Pull is fulfilled on the best effort basis, i.e. if the tokenAmounts overflows available funds it withdraws all the funds.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Claim ERC20 tokens from vault balance to zero vault.
    /// @dev Cannot be called from zero vault.
    /// @param tokens Tokens to claim
    /// @return actualTokenAmounts Amounts reclaimed
    function reclaimTokens(address[] memory tokens) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Execute one of whitelisted calls.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param to Address of the reward pool
    /// @param selector Selector of the call
    /// @param data Abi encoded parameters to `to::selector`
    /// @return result Result of execution of the call
    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IIntegrationVault.sol";
import "../external/univ3/INonfungiblePositionManager.sol";
import "../external/univ3/IUniswapV3Pool.sol";

interface IUniV3Vault is IERC721Receiver, IIntegrationVault {
    struct Options {
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Reference to INonfungiblePositionManager of UniswapV3 protocol.
    function positionManager() external view returns (INonfungiblePositionManager);

    /// @notice Reference to UniswapV3 pool.
    function pool() external view returns (IUniswapV3Pool);

    /// @notice NFT of UniV3 position manager
    function uniV3Nft() external view returns (uint256);

    /// @notice Returns tokenAmounts corresponding to liquidity, based on the current Uniswap position
    /// @param liquidity Liquidity that will be converted to token amounts
    /// @return tokenAmounts Token amounts for the specified liquidity
    function liquidityToTokenAmounts(uint128 liquidity) external view returns (uint256[] memory tokenAmounts);

    /// @notice Returns liquidity corresponding to token amounts, based on the current Uniswap position
    /// @param tokenAmounts Token amounts that will be converted to liquidity
    /// @return liquidity Liquidity for the specified token amounts
    function tokenAmountsToLiquidity(uint256[] memory tokenAmounts) external view returns (uint128 liquidity);

    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param fee_ Fee of the UniV3 pool
    /// @param uniV3Helper_ address of helper for UniV3 arithmetic with ticks
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        uint24 fee_,
        address uniV3Helper_
    ) external;

    /// @notice Collect UniV3 fees to zero vault.
    function collectEarnings() external returns (uint256[] memory collectedEarnings);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/aave/ILendingPool.sol";
import "./IIntegrationVault.sol";

interface IAaveVault is IIntegrationVault {
    /// @notice Reference to Aave protocol lending pool.
    function lendingPool() external view returns (ILendingPool);

    /// @notice Update all tvls to current aToken balances.
    function updateTvls() external;

    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    function initialize(uint256 nft_, address[] memory vaultTokens_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./external/FullMath.sol";
import "./ExceptionsLibrary.sol";

/// @notice CommonLibrary shared utilities
library CommonLibrary {
    uint256 constant DENOMINATOR = 10**9;
    uint256 constant D18 = 10**18;
    uint256 constant YEAR = 365 * 24 * 3600;
    uint256 constant Q128 = 2**128;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q160 = 2**160;
    uint256 constant UNI_FEE_DENOMINATOR = 10**6;

    /// @notice Sort uint256 using bubble sort. The sorting is done in-place.
    /// @param arr Array of uint256
    function sortUint(uint256[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; ++i) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Projects tokenAmounts onto subset or superset of tokens
    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Calculated sqrt of uint in X96 format
    /// @param xX96 input number in X96 format
    /// @return sqrt of xX96 in X96 format
    function sqrtX96(uint256 xX96) internal pure returns (uint256) {
        uint256 sqX96 = sqrt(xX96);
        return sqX96 << 48;
    }

    /// @notice Calculated sqrt of uint
    /// @param x input number
    /// @return sqrt of x
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    /// @notice Recovers signer address from signed message hash
    /// @param _ethSignedMessageHash signed message
    /// @param _signature contatenated ECDSA r, s, v (65 bytes)
    /// @return Recovered address if the signature is valid, address(0) otherwise
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Get ECDSA r, s, v from signature
    /// @param sig signature (65 bytes)
    /// @return r ECDSA r
    /// @return s ECDSA s
    /// @return v ECDSA v
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, ExceptionsLibrary.INVALID_LENGTH);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        // diff: original require(absTick <= uint256(MAX_TICK), "T");
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "../interfaces/external/univ3/IUniswapV3Pool.sol";
import "../interfaces/external/univ3/IUniswapV3Factory.sol";
import "../interfaces/external/univ3/ISwapRouter.sol";
import "../interfaces/vaults/IERC20Vault.sol";
import "../interfaces/vaults/IUniV3Vault.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/external/FullMath.sol";
import "../libraries/external/TickMath.sol";
import "../utils/DefaultAccessControlLateInit.sol";
import "../utils/HStrategyHelper.sol";
import "../utils/ContractMeta.sol";
import "../utils/UniV3Helper.sol";

contract HStrategy is ContractMeta, Multicall, DefaultAccessControlLateInit {
    using SafeERC20 for IERC20;

    // IMMUTABLES
    uint32 public constant DENOMINATOR = 10**9;
    bytes4 public constant APPROVE_SELECTOR = 0x095ea7b3;
    bytes4 public constant EXACT_INPUT_SINGLE_SELECTOR = ISwapRouter.exactInputSingle.selector;
    ISwapRouter public immutable router;

    IERC20Vault public erc20Vault;
    IIntegrationVault public moneyVault;
    IUniV3Vault public uniV3Vault;
    address[] public tokens;

    INonfungiblePositionManager private immutable _positionManager;
    IUniswapV3Pool public pool;
    UniV3Helper private immutable _uniV3Helper;
    HStrategyHelper private immutable _hStrategyHelper;
    Interval private shortInterval;
    bool private needPositionRebalance;
    bool private newPositionMinted;

    // MUTABLE PARAMS

    /// @notice general params of the strategy - responsible for emulating interval and rebalance conditions
    /// @param halfOfShortInterval half of width of the uniV3 position measured in the strategy in ticks
    /// @param tickNeighborhood width of the neighbourhood of the current position border, in which rebalance can be called.
    /// Example: if the upperTick=10, tickNeighbourhood=5, rebalance can be called for all ticks greater than 10 - 5 = 5
    /// @param domainLowerTick the lower tick of the domain uniV3 position
    /// @param domainUpperTick the upper tick of the domain uniV3 position
    struct StrategyParams {
        int24 halfOfShortInterval;
        int24 tickNeighborhood;
        int24 domainLowerTick;
        int24 domainUpperTick;
    }

    /// @notice params of the actual minted position
    /// @param minToken0ForOpening the amount of token0 are tried to be depositted on the new position
    /// @param minToken1ForOpening the amount of token1 are tried to be depositted on the new position
    struct MintingParams {
        uint256 minToken0ForOpening;
        uint256 minToken1ForOpening;
    }

    /// @notice params of the interaction with oracle
    /// @param averagePriceTimeSpan delta in seconds, passed to oracle to get the price averagePriceTimeSpan seconds ago
    /// @param maxTickDeviation the upper bound for an absolute deviation between the spot price and the price for given number seconds ago
    struct OracleParams {
        uint32 averagePriceTimeSpan;
        uint24 maxTickDeviation;
    }

    /// @param erc20CapitalRatioD the ratio of tokens kept in money vault instead of erc20. The ratio is maintained for each token
    /// @param minCapitalDeviationD the needed deviation from target amount of capital in some vault to call rebalance or swap tokens
    /// @param minRebalanceDeviationD the needed deviation from expected amounts to call swap of tokens
    struct RatioParams {
        uint256 erc20CapitalRatioD;
        uint256 minCapitalDeviationD;
        uint256 minRebalanceDeviationD;
    }

    StrategyParams public strategyParams;
    MintingParams public mintingParams;
    OracleParams public oracleParams;
    RatioParams public ratioParams;

    // INTERNAL STRUCTURES

    /// @notice parameters of the current position
    /// @param lowerTick lower tick of interval
    /// @param upperTick upper tick of interval
    struct Interval {
        int24 lowerTick;
        int24 upperTick;
    }

    /// @notice rebalance parameters restricting the tokens transfer
    struct RebalanceTokenAmounts {
        uint256[] pulledToUniV3Vault;
        uint256[] pulledFromUniV3Vault;
        int256[] swappedAmounts;
        uint256[] burnedAmounts;
        uint256 deadline;
    }

    /// @notice structure for keeping information about capital in different vaults
    /// @param erc20TokensAmountInToken0 the capital of erc20 vault calculated in token0
    /// @param moneyTokensAmountInToken0 the capital of money vault calculated in token0
    /// @param uniV3TokensAmountInToken0 the capital of uniV3 vault calculated in token0
    /// @param totalTokensInToken0 the total capital calculated in token0
    struct TokenAmountsInToken0 {
        uint256 erc20TokensAmountInToken0;
        uint256 moneyTokensAmountInToken0;
        uint256 uniV3TokensAmountInToken0;
        uint256 totalTokensInToken0;
    }

    /// @notice structure for calculation of the current and expected amounts of tokens on all vaults
    /// @param erc20Token0 the current amount of token0 on erc20 vault
    /// @param erc20Token1 the current amount of token1 on erc20 vault
    /// @param moneyToken0 the current amount of token0 on money vault
    /// @param moneyToken1 the current amount of token1 on money vault
    /// @param uniV3Token0 the current amount of token0 on uniV3 vault
    /// @param uniV3Token1 the current amount of token1 on uniV3 vault
    struct TokenAmounts {
        uint256 erc20Token0;
        uint256 erc20Token1;
        uint256 moneyToken0;
        uint256 moneyToken1;
        uint256 uniV3Token0;
        uint256 uniV3Token1;
    }

    /// @notice structure for the calculation of expected ratios between capitals in different assets
    /// @param token0RatioD the ratio of the capital in token0 / totalCapital
    /// @param token1RatioD the ratio of the capital in token1 / totalCapital
    /// @param uniV3RatioD the ratio of the capital in uniV3 / totalCapital
    struct ExpectedRatios {
        uint32 token0RatioD;
        uint32 token1RatioD;
        uint32 uniV3RatioD;
    }

    /// @notice structure for keeping information about the current position, pool state and oracle price
    /// @param nft the nft of the position in positionManager
    /// @param liquidity the total liquidity of the position
    /// @param lowerTick the lower tick of the position
    /// @param upperTick the upper tick of the position
    /// @param domainLowerTick the lower tick of the domain position
    /// @param domainUpperTick the upper tick of the domain position
    /// @param lowerPriceSqrtX96 the square root of the price at lower tick of the position
    /// @param upperPriceSqrtX96 the square root of the price at upper tick of the position
    /// @param domainLowerPriceSqrtX96 the square root of the price at lower tick of the domain position
    /// @param domainUpperPriceSqrtX96 the square root of the price at upper tick of the domain position
    /// @param intervalPriceSqrtX96 the square root of the spot price limited by the boundaries of the domain interval
    /// @param spotPriceX96 the spot price
    struct DomainPositionParams {
        uint256 nft;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        int24 domainLowerTick;
        int24 domainUpperTick;
        uint160 lowerPriceSqrtX96;
        uint160 upperPriceSqrtX96;
        uint160 domainLowerPriceSqrtX96;
        uint160 domainUpperPriceSqrtX96;
        uint160 intervalPriceSqrtX96;
        uint256 spotPriceX96;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice constructs a strategy
    /// @param positionManager_ the position manager for uniV3
    /// @param router_ the uniV3 router for swapping tokens
    /// @param uniV3Helper_ the address of the helper contract for uniV3
    /// @param hStrategyHelper_ the address of the strategy helper contract
    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        address uniV3Helper_,
        address hStrategyHelper_
    ) {
        require(address(positionManager_) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(router_) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(uniV3Helper_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(hStrategyHelper_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _positionManager = positionManager_;
        router = router_;
        _uniV3Helper = UniV3Helper(uniV3Helper_);
        _hStrategyHelper = HStrategyHelper(hStrategyHelper_);
        DefaultAccessControlLateInit.init(address(this));
    }

    /// @notice initializes the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @param erc20Vault_ the address of the erc20 vault
    /// @param moneyVault_ the address of the moneyVault. It is expected to be yEarn or AAVE
    /// @param uniV3Vault_ the address of uniV3Vault. It is expected to not hold the position
    /// @param fee_ the fee of the uniV3 pool on which the vault operates
    /// @param admin_ the addres of the admin of the strategy
    function initialize(
        address[] memory tokens_,
        IERC20Vault erc20Vault_,
        IIntegrationVault moneyVault_,
        IUniV3Vault uniV3Vault_,
        uint24 fee_,
        address admin_
    ) external {
        DefaultAccessControlLateInit.init(admin_); // call once is checked here
        address[] memory erc20Tokens = erc20Vault_.vaultTokens();
        address[] memory moneyTokens = moneyVault_.vaultTokens();
        address[] memory uniV3Tokens = uniV3Vault_.vaultTokens();
        require(tokens_.length == 2, ExceptionsLibrary.INVALID_LENGTH);
        require(erc20Tokens.length == 2, ExceptionsLibrary.INVALID_LENGTH);
        require(moneyTokens.length == 2, ExceptionsLibrary.INVALID_LENGTH);
        require(uniV3Tokens.length == 2, ExceptionsLibrary.INVALID_LENGTH);
        for (uint256 i = 0; i < 2; i++) {
            require(erc20Tokens[i] == tokens_[i], ExceptionsLibrary.INVARIANT);
            require(moneyTokens[i] == tokens_[i], ExceptionsLibrary.INVARIANT);
            require(uniV3Tokens[i] == tokens_[i], ExceptionsLibrary.INVARIANT);
        }
        erc20Vault = erc20Vault_;
        moneyVault = moneyVault_;
        uniV3Vault = uniV3Vault_;
        tokens = tokens_;
        IUniswapV3Factory factory = IUniswapV3Factory(_positionManager.factory());
        pool = IUniswapV3Pool(factory.getPool(tokens_[0], tokens_[1], fee_));
        require(address(pool) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
    }

    /// @notice creates the clone of the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @param erc20Vault_ the address of the erc20 vault
    /// @param moneyVault_ the address of the moneyVault. It is expected to be yEarn or AAVE
    /// @param uniV3Vault_ the address of uniV3Vault. It is expected to not hold the position
    /// @param fee_ the fee of the uniV3 pool on which the vault operates
    /// @param admin_ the addres of the admin of the strategy
    /// @return strategy the address of new strategy
    function createStrategy(
        address[] memory tokens_,
        IERC20Vault erc20Vault_,
        IIntegrationVault moneyVault_,
        IUniV3Vault uniV3Vault_,
        uint24 fee_,
        address admin_
    ) external returns (HStrategy strategy) {
        strategy = HStrategy(Clones.clone(address(this)));
        strategy.initialize(tokens_, erc20Vault_, moneyVault_, uniV3Vault_, fee_, admin_);
    }

    /// @notice updates parameters of the strategy. Can be called only by admin
    /// @param newStrategyParams the new parameters
    function updateStrategyParams(StrategyParams calldata newStrategyParams) external {
        _requireAdmin();
        int24 tickSpacing = pool.tickSpacing();
        require(
            newStrategyParams.halfOfShortInterval > 0 &&
                (newStrategyParams.halfOfShortInterval % tickSpacing == 0) &&
                newStrategyParams.tickNeighborhood <= newStrategyParams.halfOfShortInterval &&
                newStrategyParams.tickNeighborhood >= TickMath.MIN_TICK,
            ExceptionsLibrary.INVARIANT
        );

        int24 globalIntervalWidth = newStrategyParams.domainUpperTick - newStrategyParams.domainLowerTick;
        require(
            (newStrategyParams.domainLowerTick % tickSpacing == 0) &&
                (newStrategyParams.domainUpperTick % tickSpacing == 0) &&
                globalIntervalWidth > newStrategyParams.halfOfShortInterval &&
                (globalIntervalWidth % newStrategyParams.halfOfShortInterval == 0),
            ExceptionsLibrary.INVARIANT
        );
        StrategyParams memory strategyParams_ = strategyParams;
        if (
            newStrategyParams.halfOfShortInterval != strategyParams_.halfOfShortInterval ||
            newStrategyParams.domainLowerTick != strategyParams_.domainLowerTick ||
            newStrategyParams.domainUpperTick != strategyParams_.domainUpperTick
        ) {
            needPositionRebalance = true;
        }
        strategyParams = newStrategyParams;
        emit UpdateStrategyParams(tx.origin, msg.sender, newStrategyParams);
    }

    /// @notice updates parameters for minting position. Can be called only by admin
    /// @param newMintingParams the new parameters
    function updateMintingParams(MintingParams calldata newMintingParams) external {
        _requireAdmin();
        require(
            newMintingParams.minToken0ForOpening > 0 &&
                newMintingParams.minToken1ForOpening > 0 &&
                (newMintingParams.minToken0ForOpening <= 1000000000) &&
                (newMintingParams.minToken1ForOpening <= 1000000000),
            ExceptionsLibrary.INVARIANT
        );
        mintingParams = newMintingParams;
        emit UpdateMintingParams(tx.origin, msg.sender, newMintingParams);
    }

    /// @notice updates oracle parameters. Can be called only by admin
    /// @param newOracleParams the new parameters
    function updateOracleParams(OracleParams calldata newOracleParams) external {
        _requireAdmin();
        require(
            newOracleParams.averagePriceTimeSpan > 0 && newOracleParams.maxTickDeviation <= uint24(TickMath.MAX_TICK),
            ExceptionsLibrary.INVARIANT
        );
        oracleParams = newOracleParams;
        emit UpdateOracleParams(tx.origin, msg.sender, newOracleParams);
    }

    /// @notice updates parameters of the capital ratios and deviation. Can be called only by admin
    /// @param newRatioParams the new parameters
    function updateRatioParams(RatioParams calldata newRatioParams) external {
        _requireAdmin();
        require(
            newRatioParams.erc20CapitalRatioD <= DENOMINATOR &&
                newRatioParams.minCapitalDeviationD <= newRatioParams.erc20CapitalRatioD &&
                newRatioParams.minRebalanceDeviationD > 0 &&
                newRatioParams.minRebalanceDeviationD <= DENOMINATOR,
            ExceptionsLibrary.INVARIANT
        );
        ratioParams = newRatioParams;
        emit UpdateRatioParams(tx.origin, msg.sender, newRatioParams);
    }

    /// @notice manual pulling tokens from vault. Can be called only by admin
    /// @param fromVault the address of the vault to pull tokens from
    /// @param toVault the address of the vault to pull tokens to
    /// @param tokenAmounts the amount of tokens to be pulled
    /// @param vaultOptions additional options for `pull` method
    function manualPull(
        IIntegrationVault fromVault,
        IIntegrationVault toVault,
        uint256[] memory tokenAmounts,
        bytes memory vaultOptions
    ) external {
        _requireAdmin();
        fromVault.pull(address(toVault), tokens, tokenAmounts, vaultOptions);
    }

    /// @notice rebalance method. Need to be called if the new position is needed
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param moneyVaultOptions additional parameters for pulling for `pull` method for money vault
    /// @return actualPulledAmounts actual transferred amounts
    /// @return burnedAmounts actual burned amounts from uniV3 position
    function rebalance(RebalanceTokenAmounts memory restrictions, bytes memory moneyVaultOptions)
        external
        returns (RebalanceTokenAmounts memory actualPulledAmounts, uint256[] memory burnedAmounts)
    {
        _requireAtLeastOperator();
        IUniswapV3Pool pool_ = pool;
        (, int24 tick, , , , , ) = pool_.slot0();
        _hStrategyHelper.checkSpotTickDeviationFromAverage(tick, address(pool_), oracleParams, _uniV3Helper);
        burnedAmounts = _partialRebalanceOfUniV3Position(restrictions, tick);
        actualPulledAmounts = _capitalRebalance(restrictions, moneyVaultOptions, tick);
    }

    /// @notice rebalance, that if needed burns old univ3 position and mints new
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param tick current price tick
    /// @return burnedAmounts actual transferred amounts of tokens from position while burn
    function _partialRebalanceOfUniV3Position(RebalanceTokenAmounts memory restrictions, int24 tick)
        internal
        returns (uint256[] memory burnedAmounts)
    {
        IIntegrationVault erc20Vault_ = erc20Vault;
        IUniV3Vault uniV3Vault_ = uniV3Vault;
        uint256 uniV3Nft = uniV3Vault_.uniV3Nft();
        StrategyParams memory strategyParams_ = strategyParams;
        IUniswapV3Pool pool_ = pool;
        address[] memory tokens_ = tokens;
        burnedAmounts = new uint256[](2);
        burnedAmounts[0] = type(uint256).max;
        burnedAmounts[1] = type(uint256).max;
        newPositionMinted = false;
        {
            Interval memory shortInterval_ = shortInterval;
            int24 tickNeighborhood = strategyParams_.tickNeighborhood;

            if (
                shortInterval_.lowerTick + tickNeighborhood <= tick &&
                shortInterval_.upperTick - tickNeighborhood >= tick &&
                !needPositionRebalance
            ) {
                return burnedAmounts;
            }
            needPositionRebalance = false;

            (int24 newLowerTick, int24 newUpperTick) = _hStrategyHelper.calculateNewPositionTicks(
                tick,
                strategyParams_
            );

            if (newLowerTick == shortInterval_.lowerTick && shortInterval_.upperTick == newUpperTick) {
                return burnedAmounts;
            }

            shortInterval = Interval({lowerTick: newLowerTick, upperTick: newUpperTick});
        }

        if (uniV3Nft != 0) {
            // cannot burn only if it is first call of the rebalance function
            // and we dont have any position
            burnedAmounts = _drainPosition(restrictions, erc20Vault_, uniV3Vault_, uniV3Nft, tokens_);
        }

        _mintPosition(pool_, restrictions.deadline, _positionManager, uniV3Vault_, uniV3Nft, tokens_);
    }

    /// @notice rebalance amount of tokens between vaults. Need to be called when no new position is needed
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param moneyVaultOptions additional parameters for pulling for `pull` method for money vault
    /// @param tick spot tick for calculations
    /// @return actualPulledAmounts actual transferred amounts
    function _capitalRebalance(
        RebalanceTokenAmounts memory restrictions,
        bytes memory moneyVaultOptions,
        int24 tick
    ) internal returns (RebalanceTokenAmounts memory actualPulledAmounts) {
        HStrategyHelper hStrategyHelper_ = _hStrategyHelper;
        IUniV3Vault uniV3Vault_ = uniV3Vault;
        DomainPositionParams memory domainPositionParams;
        {
            uint256 uniV3Nft = uniV3Vault_.uniV3Nft();
            require(uniV3Nft != 0, ExceptionsLibrary.INVARIANT);
            domainPositionParams = hStrategyHelper_.calculateAndCheckDomainPositionParams(
                tick,
                strategyParams,
                uniV3Nft,
                _positionManager
            );
        }
        IIntegrationVault moneyVault_ = moneyVault;
        IIntegrationVault erc20Vault_ = erc20Vault;
        TokenAmounts memory currentTokenAmounts = hStrategyHelper_.calculateCurrentTokenAmounts(
            erc20Vault_,
            moneyVault_,
            domainPositionParams
        );
        TokenAmounts memory expectedTokenAmounts = hStrategyHelper_.calculateExpectedTokenAmounts(
            currentTokenAmounts,
            domainPositionParams,
            hStrategyHelper_,
            _uniV3Helper,
            ratioParams
        );

        if (!hStrategyHelper_.tokenRebalanceNeeded(currentTokenAmounts, expectedTokenAmounts, ratioParams)) {
            return actualPulledAmounts;
        }

        address[] memory tokens_ = tokens;
        actualPulledAmounts.pulledFromUniV3Vault = _pullExtraTokens(
            hStrategyHelper_,
            expectedTokenAmounts,
            restrictions,
            moneyVaultOptions,
            domainPositionParams,
            erc20Vault_,
            moneyVault_,
            uniV3Vault_,
            tokens_
        );

        if (hStrategyHelper_.swapNeeded(currentTokenAmounts, expectedTokenAmounts, ratioParams, domainPositionParams)) {
            actualPulledAmounts.swappedAmounts = _swapTokens(
                currentTokenAmounts,
                expectedTokenAmounts,
                restrictions,
                erc20Vault_,
                tokens_
            );
        }

        TokenAmounts memory missingTokenAmounts;
        {
            (, , , , , , , uint128 liquidity, , , , ) = _positionManager.positions(uniV3Vault_.uniV3Nft());
            missingTokenAmounts = hStrategyHelper_.calculateMissingTokenAmounts(
                moneyVault_,
                expectedTokenAmounts,
                domainPositionParams,
                liquidity
            );
        }
        actualPulledAmounts.pulledToUniV3Vault = _pullMissingTokens(
            missingTokenAmounts,
            restrictions,
            moneyVaultOptions,
            erc20Vault_,
            moneyVault_,
            uniV3Vault_,
            tokens_
        );
    }

    // -------------------  INTERNAL, MUTABLE  -------------------

    /// @notice determining the amount of tokens to be swapped and swapping it
    /// @param currentTokenAmounts the current amount of tokens
    /// @param expectedTokenAmounts the amount of tokens we expect to have after rebalance
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param erc20Vault_ ERC20 vault of the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @return swappedAmounts acutal amount of swapped tokens
    function _swapTokens(
        TokenAmounts memory currentTokenAmounts,
        TokenAmounts memory expectedTokenAmounts,
        RebalanceTokenAmounts memory restrictions,
        IIntegrationVault erc20Vault_,
        address[] memory tokens_
    ) internal returns (int256[] memory swappedAmounts) {
        (uint256 expectedToken0Amount, uint256 expectedToken1Amount) = _accumulateTokens(expectedTokenAmounts);
        (uint256 currentToken0Amount, uint256 currentToken1Amount) = _accumulateTokens(currentTokenAmounts);

        if (currentToken0Amount >= expectedToken0Amount && currentToken1Amount <= expectedToken1Amount) {
            swappedAmounts = _swapTokensOnERC20Vault(
                currentToken0Amount - expectedToken0Amount,
                0,
                restrictions,
                erc20Vault_,
                tokens_
            );
        } else if (currentToken0Amount <= expectedToken0Amount && currentToken1Amount >= expectedToken1Amount) {
            swappedAmounts = _swapTokensOnERC20Vault(
                currentToken1Amount - expectedToken1Amount,
                1,
                restrictions,
                erc20Vault_,
                tokens_
            );
        } else {
            revert(ExceptionsLibrary.INVALID_STATE);
        }
    }

    /// @notice pulling extra tokens from money and uniV3 vaults on erc20
    /// @param hStrategyHelper_ the helper of the strategy
    /// @param expectedTokenAmounts the amount of tokens we expect to have after rebalance
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param moneyVaultOptions additional parameters for pulling for `pull` method for money vault
    /// @param domainPositionParams the current state of the pool and position
    /// @param erc20Vault_ ERC20 vault of the strategy
    /// @param moneyVault_ Money vault of the strategy
    /// @param uniV3Vault_ UniswapV3 vault of the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @return pulledFromUniV3Vault the actual amount of tokens pulled from UniV3Vault
    function _pullExtraTokens(
        HStrategyHelper hStrategyHelper_,
        TokenAmounts memory expectedTokenAmounts,
        RebalanceTokenAmounts memory restrictions,
        bytes memory moneyVaultOptions,
        DomainPositionParams memory domainPositionParams,
        IIntegrationVault erc20Vault_,
        IIntegrationVault moneyVault_,
        IUniV3Vault uniV3Vault_,
        address[] memory tokens_
    ) internal returns (uint256[] memory pulledFromUniV3Vault) {
        pulledFromUniV3Vault = new uint256[](2);
        if (!newPositionMinted) {
            uint256[] memory extraTokenAmountsForPull = hStrategyHelper_.calculateExtraTokenAmountsForUniV3Vault(
                expectedTokenAmounts,
                domainPositionParams
            );

            if (extraTokenAmountsForPull[0] > 0 || extraTokenAmountsForPull[1] > 0) {
                pulledFromUniV3Vault = uniV3Vault_.pull(address(erc20Vault_), tokens_, extraTokenAmountsForPull, "");
                _compareAmounts(restrictions.pulledFromUniV3Vault, pulledFromUniV3Vault);
            }
        }

        {
            uint256[] memory extraTokenAmountsForPull = hStrategyHelper_.calculateExtraTokenAmountsForMoneyVault(
                moneyVault_,
                expectedTokenAmounts
            );

            if (extraTokenAmountsForPull[0] > 0 || extraTokenAmountsForPull[1] > 0) {
                moneyVault_.pull(address(erc20Vault_), tokens_, extraTokenAmountsForPull, moneyVaultOptions);
            }
        }
    }

    /// @notice pulling missing tokens from erc20 vault on money and uniV3 vaults
    /// @param missingTokenAmounts the amount of missing tokens
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param moneyVaultOptions additional parameters for pulling for `pull` method for money vault
    /// @param erc20Vault_ ERC20 vault of the strategy
    /// @param moneyVault_ Money vault of the strategy
    /// @param uniV3Vault_ UniswapV3 vault of the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @return pulledToUniV3Vault the actual amount of tokens pulled into UniV3Vault
    function _pullMissingTokens(
        TokenAmounts memory missingTokenAmounts,
        RebalanceTokenAmounts memory restrictions,
        bytes memory moneyVaultOptions,
        IIntegrationVault erc20Vault_,
        IIntegrationVault moneyVault_,
        IUniV3Vault uniV3Vault_,
        address[] memory tokens_
    ) internal returns (uint256[] memory pulledToUniV3Vault) {
        pulledToUniV3Vault = new uint256[](2);
        uint256[] memory extraTokenAmountsForPull = new uint256[](2);
        {
            if (missingTokenAmounts.uniV3Token0 > 0 || missingTokenAmounts.uniV3Token1 > 0) {
                extraTokenAmountsForPull[0] = missingTokenAmounts.uniV3Token0;
                extraTokenAmountsForPull[1] = missingTokenAmounts.uniV3Token1;
                pulledToUniV3Vault = erc20Vault_.pull(address(uniV3Vault_), tokens_, extraTokenAmountsForPull, "");
                _compareAmounts(restrictions.pulledToUniV3Vault, pulledToUniV3Vault);
            }
        }
        {
            if (missingTokenAmounts.moneyToken0 > 0 || missingTokenAmounts.moneyToken1 > 0) {
                extraTokenAmountsForPull[0] = missingTokenAmounts.moneyToken0;
                extraTokenAmountsForPull[1] = missingTokenAmounts.moneyToken1;
                erc20Vault_.pull(address(moneyVault_), tokens_, extraTokenAmountsForPull, moneyVaultOptions);
            }
        }
    }

    /// @notice minting new position inside the domain interval
    /// @param pool_ address of uniV3 pool
    /// @param deadline maximal duration of swap offer on uniV3
    /// @param positionManager_ uniV3 position manager
    /// @param uniV3Vault_ UniswapV3 vault of the strategy
    /// @param oldNft the nft of the burning position
    /// @param tokens_ addresses of tokens of strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    function _mintPosition(
        IUniswapV3Pool pool_,
        uint256 deadline,
        INonfungiblePositionManager positionManager_,
        IUniV3Vault uniV3Vault_,
        uint256 oldNft,
        address[] memory tokens_
    ) internal {
        uint256 minToken0ForOpening;
        uint256 minToken1ForOpening;
        {
            MintingParams memory mintingParams_ = mintingParams;
            minToken0ForOpening = mintingParams_.minToken0ForOpening;
            minToken1ForOpening = mintingParams_.minToken1ForOpening;
        }
        IERC20(tokens_[0]).safeApprove(address(positionManager_), minToken0ForOpening);
        IERC20(tokens_[1]).safeApprove(address(positionManager_), minToken1ForOpening);
        Interval memory shortInterval_ = shortInterval;
        (uint256 newNft, , , ) = positionManager_.mint(
            INonfungiblePositionManager.MintParams({
                token0: tokens_[0],
                token1: tokens_[1],
                fee: pool_.fee(),
                tickLower: shortInterval_.lowerTick,
                tickUpper: shortInterval_.upperTick,
                amount0Desired: minToken0ForOpening,
                amount1Desired: minToken1ForOpening,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: deadline
            })
        );
        IERC20(tokens_[0]).safeApprove(address(positionManager_), 0);
        IERC20(tokens_[1]).safeApprove(address(positionManager_), 0);

        positionManager_.safeTransferFrom(address(this), address(uniV3Vault_), newNft);
        if (oldNft != 0) {
            positionManager_.burn(oldNft);
        }
        newPositionMinted = true;
        emit MintUniV3Position(newNft, shortInterval_.lowerTick, shortInterval_.upperTick);
    }

    /// @notice draining all assets from uniV3
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param erc20Vault_ ERC20 vault of the strategy
    /// @param uniV3Vault_ UniswapV3 vault of the strategy
    /// @param uniV3Nft the nft of the position from position manager
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @return drainedTokens actual amount of tokens got from draining position
    function _drainPosition(
        RebalanceTokenAmounts memory restrictions,
        IIntegrationVault erc20Vault_,
        IUniV3Vault uniV3Vault_,
        uint256 uniV3Nft,
        address[] memory tokens_
    ) internal returns (uint256[] memory drainedTokens) {
        drainedTokens = uniV3Vault_.liquidityToTokenAmounts(type(uint128).max);
        drainedTokens = uniV3Vault_.pull(address(erc20Vault_), tokens_, drainedTokens, "");
        _compareAmounts(restrictions.burnedAmounts, drainedTokens);
        emit BurnUniV3Position(uniV3Nft);
    }

    /// @notice swapping tokens
    /// @param amountIn amount of tokens to be swapped
    /// @param tokenInIndex the index of token to be swapped (0 or 1)
    /// @param restrictions the restrictions of the amount of tokens to be transferred
    /// @param erc20Vault_ ERC20 vault of the strategy
    /// @param tokens_ the addresses of the tokens managed by the strategy
    /// @return amountsOut actual amount of tokens got from swap
    function _swapTokensOnERC20Vault(
        uint256 amountIn,
        uint256 tokenInIndex,
        RebalanceTokenAmounts memory restrictions,
        IIntegrationVault erc20Vault_,
        address[] memory tokens_
    ) internal returns (int256[] memory amountsOut) {
        {
            (uint256[] memory tvl, ) = erc20Vault_.tvl();
            if (tvl[tokenInIndex] < amountIn) {
                amountIn = tvl[tokenInIndex];
            }
        }

        bytes memory routerResult;
        if (amountIn > 0) {
            ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
                tokenIn: tokens_[tokenInIndex],
                tokenOut: tokens_[tokenInIndex ^ 1],
                fee: pool.fee(),
                recipient: address(erc20Vault_),
                deadline: restrictions.deadline,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            bytes memory data = abi.encode(swapParams);
            erc20Vault_.externalCall(tokens_[tokenInIndex], APPROVE_SELECTOR, abi.encode(address(router), amountIn)); // approve
            routerResult = erc20Vault_.externalCall(address(router), EXACT_INPUT_SINGLE_SELECTOR, data); // swap
            erc20Vault_.externalCall(tokens_[tokenInIndex], APPROVE_SELECTOR, abi.encode(address(router), 0)); // reset allowance
            uint256 amountOut = abi.decode(routerResult, (uint256));

            require(
                restrictions.swappedAmounts[tokenInIndex ^ 1] >= 0 && restrictions.swappedAmounts[tokenInIndex] <= 0,
                ExceptionsLibrary.INVARIANT
            );
            require(
                restrictions.swappedAmounts[tokenInIndex ^ 1] <= int256(amountOut),
                ExceptionsLibrary.LIMIT_UNDERFLOW
            );
            require(restrictions.swappedAmounts[tokenInIndex] >= -int256(amountIn), ExceptionsLibrary.LIMIT_OVERFLOW);

            amountsOut = new int256[](2);
            amountsOut[tokenInIndex ^ 1] = int256(amountOut);
            amountsOut[tokenInIndex] = -int256(amountIn);

            emit SwapTokensOnERC20Vault(tx.origin, swapParams);
        } else {
            require(restrictions.swappedAmounts[tokenInIndex ^ 1] == 0, ExceptionsLibrary.LIMIT_OVERFLOW);
            require(restrictions.swappedAmounts[tokenInIndex] == 0, ExceptionsLibrary.LIMIT_UNDERFLOW);
            return new int256[](2);
        }
    }

    // -------------------  INTERNAL, VIEW  -------------------

    /// @notice method comparing needed amount of tokens and actual. Reverts in for any elent holds needed[i] > actual[i]
    /// @param needed the needed amount of tokens from some action
    /// @param actual actual amount of tokens from the action
    function _compareAmounts(uint256[] memory needed, uint256[] memory actual) internal pure {
        for (uint256 i = 0; i < 2; i++) {
            require(needed[i] <= actual[i], ExceptionsLibrary.LIMIT_UNDERFLOW);
        }
    }

    /// @notice method calculates sums for both tokens along all vaults
    /// @param tokenAmouts given token amounts
    /// @return token0 amount of token 0 over all vaults for given tokenAmouts
    /// @return token1 amount of token 1 over all vaults for given tokenAmouts
    function _accumulateTokens(TokenAmounts memory tokenAmouts) internal pure returns (uint256 token0, uint256 token1) {
        token0 = tokenAmouts.erc20Token0 + tokenAmouts.moneyToken0 + tokenAmouts.uniV3Token0;
        token1 = tokenAmouts.erc20Token1 + tokenAmouts.moneyToken1 + tokenAmouts.uniV3Token1;
    }

    function _contractName() internal pure override returns (bytes32) {
        return bytes32("HStrategy");
    }

    function _contractVersion() internal pure override returns (bytes32) {
        return bytes32("1.0.0");
    }

    /// @notice Emitted when new position in UniV3Pool has been minted.
    /// @param uniV3Nft nft of new minted position
    /// @param lowerTick lowerTick of that position
    /// @param upperTick upperTick of that position
    event MintUniV3Position(uint256 uniV3Nft, int24 lowerTick, int24 upperTick);

    /// @notice Emitted when position in UniV3Pool has been burnt.
    /// @param uniV3Nft nft of new minted position
    event BurnUniV3Position(uint256 uniV3Nft);

    /// @notice Emitted when swap is initiated.
    /// @param origin Origin of the transaction (tx.origin)
    /// @param swapParams Swap domainPositionParams
    event SwapTokensOnERC20Vault(address indexed origin, ISwapRouter.ExactInputSingleParams swapParams);

    /// @notice Emitted when Strategy strategyParams are set.
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param strategyParams Updated strategyParams
    event UpdateStrategyParams(address indexed origin, address indexed sender, StrategyParams strategyParams);

    /// @notice Emitted when Strategy mintingParams are set.
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param mintingParams Updated mintingParams
    event UpdateMintingParams(address indexed origin, address indexed sender, MintingParams mintingParams);

    /// @notice Emitted when Strategy oracleParams are set.
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param oracleParams Updated oracleParams
    event UpdateOracleParams(address indexed origin, address indexed sender, OracleParams oracleParams);

    /// @notice Emitted when Strategy ratioParams are set.
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param ratioParams Updated ratioParams
    event UpdateRatioParams(address indexed origin, address indexed sender, RatioParams ratioParams);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "../interfaces/external/univ3/IUniswapV3Pool.sol";
import "../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/external/TickMath.sol";
import "../libraries/external/LiquidityAmounts.sol";
import "../libraries/external/OracleLibrary.sol";

contract UniV3Helper {
    function liquidityToTokenAmounts(
        uint128 liquidity,
        IUniswapV3Pool pool,
        uint256 uniV3Nft,
        INonfungiblePositionManager positionManager
    ) external view returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](2);
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = positionManager.positions(uniV3Nft);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (tokenAmounts[0], tokenAmounts[1]) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity
        );
    }

    function tokenAmountsToLiquidity(
        uint256[] memory tokenAmounts,
        IUniswapV3Pool pool,
        uint256 uniV3Nft,
        INonfungiblePositionManager positionManager
    ) external view returns (uint128 liquidity) {
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = positionManager.positions(uniV3Nft);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            tokenAmounts[0],
            tokenAmounts[1]
        );
    }

    function _getFeeGrowthInside(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        unchecked {
            (, , uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128, , , , ) = pool.ticks(
                tickLower
            );
            (, , uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128, , , , ) = pool.ticks(
                tickUpper
            );

            // calculate fee growth below
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < tickUpper) {
                feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    function calculatePositionInfo(
        INonfungiblePositionManager positionManager,
        IUniswapV3Pool pool,
        uint256 uniV3Nft
    )
        external
        view
        returns (
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        (
            ,
            ,
            ,
            ,
            ,
            tickLower,
            tickUpper,
            liquidity,
            feeGrowthInside0LastX128,
            feeGrowthInside1LastX128,
            tokensOwed0,
            tokensOwed1
        ) = positionManager.positions(uniV3Nft);

        if (liquidity == 0) {
            return (tickLower, tickUpper, liquidity, tokensOwed0, tokensOwed1);
        }

        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        (, int24 tick, , , , , ) = pool.slot0();

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = _getFeeGrowthInside(
            pool,
            tickLower,
            tickUpper,
            tick,
            feeGrowthGlobal0X128,
            feeGrowthGlobal1X128
        );

        uint256 feeGrowthInside0DeltaX128;
        uint256 feeGrowthInside1DeltaX128;
        unchecked {
            feeGrowthInside0DeltaX128 = feeGrowthInside0X128 - feeGrowthInside0LastX128;
            feeGrowthInside1DeltaX128 = feeGrowthInside1X128 - feeGrowthInside1LastX128;
        }

        tokensOwed0 += uint128(FullMath.mulDiv(feeGrowthInside0DeltaX128, liquidity, CommonLibrary.Q128));

        tokensOwed1 += uint128(FullMath.mulDiv(feeGrowthInside1DeltaX128, liquidity, CommonLibrary.Q128));
    }

    // TODO: add test for oracleObservationDelta, when pool exists less time
    function getTickDeviationForTimeSpan(
        int24 tick,
        address pool_,
        uint32 secondsAgo
    ) external view returns (bool withFail, int24 deviation) {
        int24 averageTick;
        (averageTick, , withFail) = OracleLibrary.consult(pool_, secondsAgo);
        deviation = tick - averageTick;
    }

    /// @dev calculates the distribution of tokens that can be added to the position after swap for given capital in token 0
    function getPositionTokenAmountsByCapitalOfToken0(
        uint256 lowerPriceSqrtX96,
        uint256 upperPriceSqrtX96,
        uint256 spotPriceForSqrtFormulasX96,
        uint256 spotPriceX96,
        uint256 capital
    ) external pure returns (uint256 token0Amount, uint256 token1Amount) {
        // sqrt(upperPrice) * (sqrt(price) - sqrt(lowerPrice))
        uint256 lowerPriceTermX96 = FullMath.mulDiv(
            upperPriceSqrtX96,
            spotPriceForSqrtFormulasX96 - lowerPriceSqrtX96,
            CommonLibrary.Q96
        );
        // sqrt(price) * (sqrt(upperPrice) - sqrt(price))
        uint256 upperPriceTermX96 = FullMath.mulDiv(
            spotPriceForSqrtFormulasX96,
            upperPriceSqrtX96 - spotPriceForSqrtFormulasX96,
            CommonLibrary.Q96
        );

        token1Amount = FullMath.mulDiv(
            FullMath.mulDiv(capital, spotPriceX96, CommonLibrary.Q96),
            lowerPriceTermX96,
            lowerPriceTermX96 + upperPriceTermX96
        );

        token0Amount = capital - FullMath.mulDiv(token1Amount, CommonLibrary.Q96, spotPriceX96);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
pragma solidity 0.8.9;

interface IERC1271 {
    /// @notice Verifies offchain signature.
    /// @dev Should return whether the signature provided is valid for the provided hash
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///
    /// MUST allow external calls
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Existential amounts for each token
    function pullExistentials() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param maxTokensPerVault Max different token addresses that could be managed by the vault
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury The address that collects protocolFees, if protocolFee is not zero
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IUniswapV3PoolActions.sol";
import "./pool/IUniswapV3PoolImmutables.sol";
import "./pool/IUniswapV3PoolState.sol";
import "./pool/IUniswapV3PoolDerivedState.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions
{

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
pragma solidity =0.8.9;

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
    function protocolPerformanceFees() external view returns (uint128 token0, uint128 token1);

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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant INVALID_INTERFACE = "INVI";
    string constant INVALID_SELECTOR = "INVS";
    string constant INVALID_STATE = "INVST";
    string constant INVALID_LENGTH = "INVL";
    string constant LOCK = "LCKD";
    string constant DISABLED = "DIS";
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/aave/ILendingPool.sol";
import "./IIntegrationVault.sol";

interface IERC20Vault is IIntegrationVault {
    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    function initialize(uint256 nft_, address[] memory vaultTokens_) external;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interfaces/utils/IDefaultAccessControl.sol";
import "../libraries/ExceptionsLibrary.sol";

/// @notice This is a default access control with 3 roles:
///
/// - ADMIN: allowed to do anything
/// - ADMIN_DELEGATE: allowed to do anything except assigning ADMIN and ADMIN_DELEGATE roles
/// - OPERATOR: low-privileged role, generally keeper or some other bot
contract DefaultAccessControlLateInit is IDefaultAccessControl, AccessControlEnumerable {
    bool public initialized;

    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");

    // -------------------------  EXTERNAL, VIEW  ------------------------------

    /// @inheritdoc IDefaultAccessControl
    function isAdmin(address sender) public view returns (bool) {
        return hasRole(ADMIN_ROLE, sender) || hasRole(ADMIN_DELEGATE_ROLE, sender);
    }

    /// @inheritdoc IDefaultAccessControl
    function isOperator(address sender) public view returns (bool) {
        return hasRole(OPERATOR, sender);
    }

    // -------------------------  EXTERNAL, MUTATING  ------------------------------

    /// @notice Initializes a new contract with roles and single ADMIN.
    /// @param admin Admin of the contract
    function init(address admin) public {
        require(admin != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(!initialized, ExceptionsLibrary.INIT);

        _setupRole(OPERATOR, admin);
        _setupRole(ADMIN_ROLE, admin);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN_DELEGATE_ROLE);

        initialized = true;
    }

    // -------------------------  INTERNAL, VIEW  ------------------------------

    function _requireAdmin() internal view {
        require(isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    function _requireAtLeastOperator() internal view {
        require(isAdmin(msg.sender) || isOperator(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "../interfaces/utils/IContractMeta.sol";

abstract contract ContractMeta is IContractMeta {
    // -------------------  EXTERNAL, VIEW  -------------------

    function contractName() external pure returns (string memory) {
        return _bytes32ToString(_contractName());
    }

    function contractNameBytes() external pure returns (bytes32) {
        return _contractName();
    }

    function contractVersion() external pure returns (string memory) {
        return _bytes32ToString(_contractVersion());
    }

    function contractVersionBytes() external pure returns (bytes32) {
        return _contractVersion();
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure virtual returns (bytes32);

    function _contractVersion() internal pure virtual returns (bytes32);

    function _bytes32ToString(bytes32 b) internal pure returns (string memory s) {
        s = new string(32);
        uint256 len = 32;
        for (uint256 i = 0; i < 32; ++i) {
            if (uint8(b[i]) == 0) {
                len = i;
                break;
            }
        }
        assembly {
            mstore(s, len)
            mstore(add(s, 0x20), b)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "./FullMath.sol";
import "./TickMath.sol";
import "../../interfaces/external/univ3/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    /// @return withFail Flag that true if function observe of IUniswapV3Pool reverts with some error
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (
            int24 arithmeticMeanTick,
            uint128 harmonicMeanLiquidity,
            bool withFail
        )
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        try IUniswapV3Pool(pool).observe(secondsAgos) returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
                secondsPerLiquidityCumulativeX128s[0];

            arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0))
                arithmeticMeanTick--;

            // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
            uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
            harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
        } catch {
            return (0, 0, true);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

interface IContractMeta {
    function contractName() external view returns (string memory);
    function contractNameBytes() external view returns (bytes32);

    function contractVersion() external view returns (string memory);
    function contractVersionBytes() external view returns (bytes32);
}