//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../amm_adapter/IAmmAdapter.sol";
import "../amm_adapter/IAmmAdapterCallback.sol";
import "../external/IERC677Receiver.sol";
import "../external/IWETH9.sol";
import "../incentives/IStakingIncentives.sol";
import "../external/IERC677Receiver.sol";
import "../external/IWETH9.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "../token/ILiquidityToken.sol";
import "../upgrade/FsBase.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IExchangeLedger.sol";
import "./TokenVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title The implementation of an AMM that hedges its positions by trading in the spot market.
/// @notice This AMM takes the opposite position to the aggregate trader positions on the Futureswap
/// exchange (can be 0 if trader longs and shorts are perfectly balanced). This AMM hedges its position by taking an
/// opposite position on an external market and thus ideally stay market neutral. Example: aggregate trader position
/// on the Futureswap exchange is long 200 asset tokens. The AMM's position there would be short 200 asset token. But
/// it also has a 200 asset long position on the external spot market. This allows it to make the fees without being
/// exposed to market risks (relatively to LPs' original 50:50 allocation in value between stable:asset).
/// @dev This AMM should never directly hold funds and should send any tokens directly to the token vault.
contract SpotMarketAmm is FsBase, IAmm, IAmmAdapterCallback, IERC677Receiver {
    using SafeERC20 for IERC20;

    /// @dev This is immutable as it will stay fixed across the entire system.
    address public immutable wethToken;

    IAmmAdapter public ammAdapter;
    IExchangeLedger public exchangeLedger;
    TokenVault public tokenVault;
    ILiquidityToken public liquidityToken;
    address public liquidityIncentives;
    IOracle public oracle;
    address public assetToken;
    address public stableToken;
    AmmConfig public ammConfig;

    /// @notice A flag to guard against functions being illegally called outside of trading flow.
    bool private inTradingExecution;

    /// @notice The AMM's collateral includes both original stable liquidity added and its position on spot market to
    /// hedge against its position on the Futureswap exchange.
    /// The two positions (on Futureswap exchange and external spot market) should perfectly cancel each other out,
    /// excluding fees (Trade and time fees that are paid from traders to the AMM). The only exception that can cause
    /// a mismatch between the AMM's two positions is when ADL happens, which partially closes the AMM's position on
    /// the Futureswap exchange but leaves its corresponding hedge (position on Spot market) still open. When this
    /// happens, the AMM's book is not market neutral and is exposed to market risks. But this only happens in the
    /// extreme case where ADL runs out of opposite trader positions on the Futureswap exchange and should rarely, if
    /// ever, happen in real life.
    int256 public collateral;

    /// @notice The AMM's tolerance to trade errors
    int256 public tradeTolerance;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[987] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    /// @notice Emitted when liquidity is added by a liquidity provider
    /// @param provider The provider's address
    /// @param assetAmount The amount of asset tokens the liquidity provider provided
    /// @param stableAmount The amount of stable tokens the liquidity provider provided
    /// @param liquidityTokenAmount The amount of liquidity tokens that were issued
    /// @param liquidityTokenSupply The new total supply of liquidity tokens
    event LiquidityAdded(
        address indexed provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount,
        int256 liquidityTokenSupply
    );

    /// @notice Emitted when liquidity is removed by a liquidity provider
    /// @param provider The provider's address
    /// @param assetAmount The amount of asset tokens the liquidity provider received
    /// @param stableAmount The amount of stable tokens the liquidity provider received
    /// @param liquidityTokenAmount The amount of liquidity tokens that were burnt
    /// @param liquidityTokenSupply The new total supply of liquidity tokens
    event LiquidityRemoved(
        address indexed provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount,
        int256 liquidityTokenSupply
    );

    event OracleChanged(address oldOracle, address newOracle);
    event AmmConfigChanged(AmmConfig oldConfig, AmmConfig newConfig);
    event TradeToleranceChanged(int256 oldTradeTolerance, int256 newTradeTolerance);
    event AmmAdapterChanged(address oldAmmAdapter, address newAmmAdapter);
    event LiquidityIncentivesChanged(
        address oldLiquidityIncentives,
        address newLiquidityIncentives
    );

    struct AmmConfig {
        // A fee for removing liquidity, range: [0, 1 ether). 0 is 0% and 1 ether is 100% (it should never be 100%).
        int256 removeLiquidityFee;
        // A minimum reserve of asset/stable tokens that needs to be present after each swap expressed as a percentage
        // of total liquidity converted to stable using the current asset price. Range: [0, 1 ether]; 0 is 0% and
        // 1 ether is 100%.
        int256 tradeLiquidityReserveFactor;
    }

    /// @notice Can be used together with an ERC677 onTokenTransfer to remove liquidity.
    /// When LP tokens are redeemed for stable/asset, an instance of this type is
    /// expected as the `data` argument in an `transferAndCall` call between either the LP token or the
    /// `StakingIncentives` and the `SpotMarketAmm` contracts.  The `receiver` field allows the caller contract
    /// to specify the receiver of the stable and asset tokens.
    struct RemoveLiquidityData {
        // The recipient of the redeemed liquidity.
        address receiver;
        // The minimum amount of asset tokens to redeem in exchange for the provided share of liquidity.
        int256 minAssetAmount;
        // The minimum amount of stable tokens to redeem in exchange for the provided share of liquidity.
        int256 minStableAmount;
        // Whether to pay out liquidity using raw ETH for whichever token is WETH.
        bool useEth;
    }

    modifier atomicTradingExecution() {
        require(!inTradingExecution, "Not in trading flow");
        inTradingExecution = true;
        _;
        inTradingExecution = false;
    }

    /// @param _wethToken WETH's address used for dealing with WETH/ETH transfers.
    constructor(address _wethToken) {
        // slither-disable-next-line missing-zero-check
        wethToken = FsUtils.nonNull(_wethToken);
    }

    /// @notice Allow ETH to be sent to this contract for unwrapping WETH only.
    receive() external payable {
        require(msg.sender == wethToken, "Wrong sender");
    }

    /// @param _exchangeLedger The exchangeLedger associated with the token vault.
    /// @param _tokenVault Address of the token vault the AMM can draw funds from for hedging.
    /// @param _assetToken Address of the asset token for liquidity and trade calculations.
    /// @param _stableToken Address of the stable token for liquidity and trade calculations.
    /// @param _liquidityToken Address of the LP token LPs receive for providing liquidity.
    /// @param _liquidityIncentives Address of the incentives minted LP tokens are sent to for staking.
    /// @param _ammAdapter Address of the associated amm adapter.
    /// @param _oracle Address of the associated oracle.
    function initialize(
        address _exchangeLedger,
        address _tokenVault,
        address _assetToken,
        address _stableToken,
        address _liquidityToken,
        address _liquidityIncentives,
        address _ammAdapter,
        address _oracle,
        AmmConfig memory _ammConfig
    ) external initializer {
        initializeFsOwnable();

        // slither-disable-next-line missing-zero-check
        exchangeLedger = IExchangeLedger(FsUtils.nonNull(_exchangeLedger));
        // slither-disable-next-line missing-zero-check
        tokenVault = TokenVault(FsUtils.nonNull(_tokenVault));
        // slither-disable-next-line missing-zero-check
        assetToken = FsUtils.nonNull(_assetToken);
        // slither-disable-next-line missing-zero-check
        stableToken = FsUtils.nonNull(_stableToken);
        // slither-disable-next-line missing-zero-check
        liquidityToken = ILiquidityToken(FsUtils.nonNull(_liquidityToken));
        // slither-disable-next-line missing-zero-check
        liquidityIncentives = FsUtils.nonNull(_liquidityIncentives);
        // slither-disable-next-line missing-zero-check
        ammAdapter = IAmmAdapter(FsUtils.nonNull(_ammAdapter));
        // slither-disable-next-line missing-zero-check
        oracle = IOracle(FsUtils.nonNull(_oracle));
        setAmmConfig(_ammConfig);
        inTradingExecution = false;
    }

    /// @inheritdoc IAmm
    function getAssetPrice() external view override returns (int256 assetPrice) {
        return ammAdapter.getPrice(assetToken, stableToken);
    }

    /// @inheritdoc IAmm
    function trade(
        int256 assetAmount,
        int256 assetPrice,
        bool isClosingTraderPosition
    ) external override atomicTradingExecution returns (int256 stableAmount) {
        require(msg.sender == address(exchangeLedger), "Wrong sender");

        int256 stableBalanceBefore = vaultBalance(stableToken);
        int256 assetBalanceBefore = vaultBalance(assetToken);

        // This total value is the same before and after swap because the exchange ledger doesn't update the amm's
        // position after this trade function finishes executing.
        (int256 ammStableBalance, int256 ammAssetBalance) = ammBalance(assetPrice);
        int256 totalValue = ammStableBalance + FsMath.assetToStable(ammAssetBalance, assetPrice);

        // Swap and send received tokens directly to the vault. This eliminates the risk of having any funds being stuck
        // in this AMM.
        stableAmount = ammAdapter.swap(address(tokenVault), stableToken, assetToken, assetAmount);

        // Update the AMM's collateral to include its new stable position on the external spot
        // market.
        //
        // `atomicTradingExecution` prevents a reentrancy attack here.  We can not update
        // `collateral` before we know the `stableAmount` value.
        // Also, Slither suggests that changes to `collateral` should trigger events. It is not
        // completely wrong, but we would need to expose more internal state if we want to be able
        // to track all the changes in our accounting, so ignoring this suggestion for now.
        // slither-disable-next-line reentrancy-no-eth,events-maths
        collateral += stableAmount;

        int256 assetBalanceAfter = vaultBalance(assetToken);
        require(
            vaultBalance(stableToken) >= stableBalanceBefore + stableAmount,
            "Wrong stable balance"
        );
        require(
            assetBalanceAfter >= assetBalanceBefore + assetAmount - tradeTolerance,
            "Wrong asset balance"
        );

        requireEnoughLiquidityLeft(
            isClosingTraderPosition,
            totalValue,
            assetBalanceAfter,
            assetPrice
        );
    }

    /// @inheritdoc IAmmAdapterCallback
    function sendPayment(
        address recipient,
        address token0,
        address token1,
        int256 amount0Owed,
        int256 amount1Owed
    ) external override {
        // We'll verify that payment is only requested as part of an ongoing trade execution to protect against a
        // malicious ammAdapter or a potential exploit that allows an attacker to take over the ammAdapter and call the
        // AMM from it.
        require(inTradingExecution, "Not in trading execution flow");

        require(msg.sender == address(ammAdapter), "Wrong address");
        require(
            (token0 == stableToken && token1 == assetToken) ||
                (token0 == assetToken && token1 == stableToken),
            "Wrong token"
        );
        // Validate that we need to send payment for exactly one of the two tokens.
        require(
            (amount0Owed > 0 && amount1Owed <= 0) || (amount1Owed > 0 && amount0Owed <= 0),
            "Invalid amount"
        );

        // There should be no risk of reentrancy here with transfers as the end users cannot call the AMM directly.
        // System-wide reentrancy should be handled at the TokenManager and exchangeLedger level.
        if (amount0Owed > 0) {
            // We could extract amount out of the if/else conditions but that'd require an unsafe cast
            // from int256 to int256.
            // slither-disable-next-line safe-cast
            uint256 amount = uint256(amount0Owed);
            // This might not be enough to cover token that charges a fee for transfer. An example is USDT.
            // The spot market would likely revert in those cases due to insufficient payment.
            // This is fine for now as we don't support those tokens yet.
            tokenVault.transfer(recipient, token0, amount);
        } else {
            // We have a `require` call above to validate that if `amount0Owed` is zero or negative,
            // then `amount1Owed` is positive.
            // slither-disable-next-line safe-cast
            uint256 amount = uint256(amount1Owed);
            tokenVault.transfer(recipient, token1, amount);
        }
    }

    /// @notice Add liquidity to the AMM
    /// Callers are expected to have approved the AMM with sufficient limits to pay for the stable/asset required
    /// for adding liquidity.
    ///
    /// When calculating the liquidity pool value, we convert value of the "asset" tokens
    /// into the "stable" tokens, using price provided by the price oracle.
    ///
    /// @param stableAmount The amount of liquidity to provide denoted in stable. The AMM will request payment for an
    /// equal amount of stable and asset tokens value wise.
    /// @param maxAssetAmount The maximum amount of assets to provide as liquidity. This allows the user to set bounds
    /// on prices as they need to provide equal values of stables and assets. 0 means no bounds.
    /// @return The amount of tokens that were minted to the liquidity provider.
    function addLiquidity(int256 stableAmount, int256 maxAssetAmount)
        external
        payable
        returns (int256)
    {
        // Liquidity can only be added if the exchange is in normal operation
        require(
            exchangeLedger.exchangeState() == IExchangeLedger.ExchangeState.NORMAL,
            "Exchange not in normal state"
        );

        // Don't accept raw ETH from msg.value if neither of the accepted tokens is WETH.
        if (msg.value > 0) {
            require(
                stableToken == wethToken || assetToken == wethToken,
                "Not a WETH pool, invalid msg.value"
            );
        }

        (int256 liquidityTokens, int256 totalShares, int256 assetAmount) =
            calculateAddLiquidityAmounts(stableAmount);
        // Users can set a bound so that if the price changes too much, the transaction would revert.
        // This removes the ability to front-run large liquidity providers.
        // A `maxAssetAmount` of zero means the user did not set a bound.
        if (maxAssetAmount != 0) {
            require(assetAmount <= maxAssetAmount, "maxAssetAmount requirement violated");
        }

        address provider = msg.sender;
        int256 newTotalShares = totalShares + liquidityTokens;
        emit LiquidityAdded(provider, assetAmount, stableAmount, liquidityTokens, newTotalShares);
        handleLiquidityPayment(provider, assetAmount, stableAmount, liquidityTokens);

        collateral += stableAmount;
        return liquidityTokens;
    }

    /// @dev Remove liquidity from the AMM
    /// Callers are expected to transfer the liquidity token into the AMM. The AMM will then attempt to burn tokenAmount
    /// to redeem liquidity.
    ///
    /// `minAssetAmount` and `minStableAmount` allow the liquidity provider to only withdraw when the volume of asset
    /// and share, respectively, is at or above the specified values.
    ///
    /// @param recipient The recipient of the redeemed liquidity.
    /// @param liquidityTokenAmount The amount of liquidity tokens to burn.
    /// @param minAssetAmount The minimum amount of asset tokens to redeem in exchange for the provided share of
    /// liquidity. Happens regardless of the amount of asset in the result.
    /// @param minStableAmount The minimum amount of stable tokens to redeem in exchange for the provided share of
    /// liquidity.
    /// @param useEth Whether to pay out liquidity using raw ETH for whichever token is WETH.
    function removeLiquidity(
        address recipient,
        int256 liquidityTokenAmount,
        int256 minAssetAmount,
        int256 minStableAmount,
        bool useEth
    ) private {
        // Liquidity can be removed if the exchange is in normal operation or paused
        require(
            exchangeLedger.exchangeState() != IExchangeLedger.ExchangeState.STOPPED,
            "Exchange is stopped"
        );

        if (liquidityTokenAmount == 0) return;

        FsUtils.Assert(liquidityTokenAmount > 0); // guaranteed by onTokenTransfer
        // Because this function is called by onTokenTransfer which guarantees we have
        FsUtils.Assert(uint256(liquidityTokenAmount) <= liquidityToken.balanceOf(address(this)));

        int256 price = oracle.getPrice(assetToken);
        (int256 assetAmount, int256 stableAmount) =
            calculateRemoveLiquidityAmounts(liquidityTokenAmount, price);

        // Users can set a bound so that if the pool ratio changes their transaction
        // will not mine. This removes the ability to front-run large liquidity providers.
        // A `minAssetAmount` or `minStableAmount` of zero means the user did not set a bound.
        require(assetAmount >= minAssetAmount, "minAssetAmount requirement violated");
        require(stableAmount >= minStableAmount, "minStableAmount requirement violated");

        // Check that we have enough asset and stable balance to return liquidity to LP.
        // For better error reporting, revert with insufficient asset/stable liquidity.
        (int256 stableBalance, int256 assetBalance) = ammBalance(price);
        require(int256(assetAmount) <= assetBalance, "Insufficient asset liquidity");
        require(int256(stableAmount) <= stableBalance, "Insufficient stable liquidity");

        // Update state before transfer calls in case of reentrancy.
        collateral -= stableAmount;

        // Burn the liquidity tokens corresponding to the withdrawn liquidity. burn() will only burn
        // tokens in this AMM's possession. The AMM by default has no liquidity token balance so if
        // we are able to burn `amount` of tokens this means that msg.sender must have transferred
        // these tokens in.
        liquidityToken.burn(FsMath.safeCastToUnsigned(liquidityTokenAmount));

        pay(recipient, assetToken, assetAmount, useEth);
        pay(recipient, stableToken, stableAmount, useEth);

        int256 updatedTotalSupply = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        emit LiquidityRemoved(
            recipient,
            assetAmount,
            stableAmount,
            liquidityTokenAmount,
            updatedTotalSupply
        );
    }

    /// @inheritdoc IERC677Receiver
    /// @notice Receive transfer of LP token and allow LP to remove liquidity. Data is expected to contain an encoded
    /// version of `RemoveLiquidityData`.
    ///
    /// AMM will determine the split between asset and stable that a liquidity provider receives based on an internal
    /// state. But the total value will always be equal to the share of the total assets owned by the AMM, based on the
    /// share of the provided liquidity tokens.
    /// @param amount the amount of LP tokens send
    /// @param data the abi encoded RemoveLiquidityData struct describing the remove liquidity call.
    ///             See struct definition for the parameters and explanation.
    function onTokenTransfer(
        address, /* from */
        uint256 amount,
        bytes calldata data
    ) external override returns (bool success) {
        // Only accepts transfer of LP tokens. Other tokens should not be sent directly here without calling
        // addLiquidity.
        require(msg.sender == address(liquidityToken), "Incorrect sender");

        RemoveLiquidityData memory decodedData = abi.decode(data, (RemoveLiquidityData));
        address receiver = decodedData.receiver;
        int256 minAssetAmount = decodedData.minAssetAmount;
        int256 minStableAmount = decodedData.minStableAmount;
        bool useEth = decodedData.useEth;
        removeLiquidity(
            receiver,
            FsMath.safeCastToSigned(amount),
            minAssetAmount,
            minStableAmount,
            useEth
        );

        // Always return true as we would revert if something is unexpected.
        return true;
    }

    /// @notice Updates the config of the AMM, can only be performed by the voting executor.
    function setAmmConfig(AmmConfig memory _ammConfig) public onlyOwner {
        // removeLiquidityFee cannot be 100%.
        require(
            0 <= _ammConfig.removeLiquidityFee && _ammConfig.removeLiquidityFee < 1 ether,
            "Invalid remove liquidity fee"
        );
        require(
            0 <= _ammConfig.tradeLiquidityReserveFactor &&
                _ammConfig.tradeLiquidityReserveFactor <= 1 ether,
            "Invalid trade liquidity reserve factor"
        );

        emit AmmConfigChanged(ammConfig, _ammConfig);
        ammConfig = _ammConfig;
    }

    /// @notice Updates the config of the AMM, can only be performed by the voting executor.
    function setTradeTolerance(int256 _tradeTolerance) public onlyOwner {
        emit TradeToleranceChanged(tradeTolerance, _tradeTolerance);
        tradeTolerance = _tradeTolerance;
    }

    /// @notice Updates the oracle the AMM uses to compute prices for adding/removing liquidity, can only be performed
    /// by the voting executor.
    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(oracle)) {
            return;
        }
        address oldOracle = address(oracle);
        oracle = IOracle(FsUtils.nonNull(_oracle));
        emit OracleChanged(oldOracle, _oracle);
    }

    /// @notice Allows voting executor to change the amm adapter. This can effectively change the spot market this AMM
    /// trades with.
    function setAmmAdapter(address _ammAdapter) external onlyOwner {
        if (_ammAdapter == address(ammAdapter)) {
            return;
        }
        emit AmmAdapterChanged(address(ammAdapter), address(_ammAdapter));
        ammAdapter = IAmmAdapter(_ammAdapter);
    }

    /// @notice Allows voting executor to change the liquidity incentives.
    function setLiquidityIncentives(address _liquidityIncentives) external onlyOwner {
        if (_liquidityIncentives == liquidityIncentives) {
            return;
        }
        emit LiquidityIncentivesChanged(liquidityIncentives, _liquidityIncentives);
        liquidityIncentives = _liquidityIncentives;
    }

    /// @notice Returns the amount of asset required to provide a given stableAmount. Also
    /// returns the number of liquidity tokens that currently would be minted for the stableAmount and assetAmount.
    /// @param stableAmount The amount of stable tokens the user wants to supply.
    function getLiquidityTokenAmount(int256 stableAmount)
        external
        view
        returns (int256 assetAmount, int256 liquidityTokenAmount)
    {
        (liquidityTokenAmount, , assetAmount) = calculateAddLiquidityAmounts(stableAmount);
    }

    /// @notice Returns the amounts of stable and asset the given amount of liquidity token owns.
    function getLiquidityValue(int256 liquidityTokenAmount)
        external
        view
        returns (int256 assetAmount, int256 stableAmount)
    {
        return getLiquidityValueInternal(liquidityTokenAmount, oracle.getPrice(assetToken));
    }

    /// @notice Returns the number of liquidity token amount that can be redeemed given current AMM positions.
    /// Since the AMM actively uses liquidity to swap with spot markets, the amount of remaining asset or stable tokens
    /// is potentially less than originally provided by LPs. Therefore, not 100% shares are redeemable at any point in
    /// time.
    function getRedeemableLiquidityTokenAmount() external view returns (int256) {
        int256 totalShares = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        (int256 ammStable, int256 ammAsset) = ammBalance(oracle.getPrice(assetToken));
        int256 maxSharesForAsset =
            calculateMaxShares(ammAsset, vaultBalance(assetToken), totalShares);
        int256 maxSharesForStable =
            calculateMaxShares(ammStable, vaultBalance(stableToken), totalShares);
        return FsMath.min(maxSharesForAsset, maxSharesForStable);
    }

    function calculateMaxShares(
        int256 totalTokens,
        int256 availableTokens,
        int256 totalShares
    ) private pure returns (int256) {
        if (totalTokens <= availableTokens) {
            // Pool owns less than the available tokens, so all shares can be redeemed.
            return totalShares;
        } else {
            // This branch implies totalTokens > availableTokens and thus totalTokens is not-zero
            return (totalShares * availableTokens) / totalTokens;
        }
    }

    /// @notice Returns the asset and stable amounts, excluding fees, that the LP is entitled to for the specified
    /// amount of liquidity token.
    function calculateRemoveLiquidityAmounts(int256 _liquidityTokenAmount, int256 price)
        private
        view
        returns (int256 assetAmountSubFee, int256 stableAmountSubFee)
    {
        (int256 assetAmount, int256 stableAmount) =
            getLiquidityValueInternal(_liquidityTokenAmount, price);

        int256 remainingPortionAfterFee = FsMath.FIXED_POINT_BASED - ammConfig.removeLiquidityFee;
        assetAmountSubFee = (assetAmount * remainingPortionAfterFee) / FsMath.FIXED_POINT_BASED;
        stableAmountSubFee = (stableAmount * remainingPortionAfterFee) / FsMath.FIXED_POINT_BASED;
    }

    /// @notice Compute the amounts of stables/assets a given amount of LP token is worth. Allowing passing price in for
    /// gas saving (so that upstream functions only need to get oracle price once).
    function getLiquidityValueInternal(int256 liquidityTokenAmount, int256 price)
        private
        view
        returns (int256 assetAmount, int256 stableAmount)
    {
        int256 totalLPTokenSupply = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        // Avoid division by 0. If there has been no liquidity added, LP tokens are worth nothing although unless
        // something went wrong somewhere, there should be LP tokens in circulation if there's been no liquidity added.
        if (totalLPTokenSupply == 0) {
            return (0, 0);
        }

        (int256 originalStableLiquidity, int256 originalAssetLiquidity) = ammBalance(price);
        assetAmount = (originalAssetLiquidity * liquidityTokenAmount) / totalLPTokenSupply;
        stableAmount = (originalStableLiquidity * liquidityTokenAmount) / totalLPTokenSupply;
    }

    /// @notice Request payment from msg.sender to add liquidity.
    function handleLiquidityPayment(
        address provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount
    ) private {
        // Collect payments from msg.sender directly. We might potentially receive fewer tokens if there's a transfer
        // fee but this is alright for now as we'll control which tokens we support.
        handlePayment(provider, assetToken, assetAmount);
        handlePayment(provider, stableToken, stableAmount);

        // Mint the liquidity provider the liquidity token.
        // This should be done after payment to prevent reentrancy attacks.
        liquidityToken.mint(FsMath.safeCastToUnsigned(liquidityTokenAmount));

        //slither-disable-next-line uninitialized-local
        IStakingIncentives.StakingDeposit memory sd;
        sd.account = provider;

        // Send the newly minted LP tokens to the incentives contract for "forced" staking. LPs will be able to interact
        // with the LP incentives contract for token withdrawal/rewards.
        require(
            IERC677Token(liquidityToken).transferAndCall(
                liquidityIncentives,
                FsMath.safeCastToUnsigned(liquidityTokenAmount),
                abi.encode(sd)
            ),
            "TransferAndCall failed"
        );
    }

    /// @notice Takes payments from the caller for a specified amount. Raw ETH is accepted if the payment token is
    /// weth.
    function handlePayment(
        address provider,
        address token,
        int256 _amount
    ) private {
        uint256 amount = FsMath.safeCastToUnsigned(_amount);
        address vaultAddress = address(tokenVault);
        if (token == wethToken && msg.value > 0) {
            // There's no risk of collecting msg.value multiple times here because:
            // (1) Stable and asset tokens cannot be the same token so they can't both be weth.
            // (2) We wrap ETH into WETH using this contract's balance. This contract never has remaining balance
            // after a transaction as all funds are sent to the vault so if for some reason handlePayment is called
            // more than once, wrapping would fail.
            uint256 msgValue = msg.value;
            require(msgValue == amount, "msg.value doesn't match deltaStable");
            IWETH9(wethToken).deposit{ value: msgValue }();
            IERC20(wethToken).safeTransfer(vaultAddress, msgValue);
        } else {
            IERC20(token).safeTransferFrom(provider, vaultAddress, amount);
        }
    }

    /// @notice Pay the recipient a specified amount. Can pay in raw ETH if token is WETH and ETH payment is requested.
    function pay(
        address recipient,
        address token,
        int256 _amount,
        bool useEth
    ) private {
        uint256 amount = FsMath.safeCastToUnsigned(_amount);
        if (token == wethToken && useEth) {
            // Need to transfer WETH to this contract for unwrapping.
            tokenVault.transfer(address(this), wethToken, amount);
            IWETH9(wethToken).withdraw(amount);
            Address.sendValue(payable(recipient), amount);
        } else {
            tokenVault.transfer(recipient, token, amount);
        }
    }

    /// @notice Returns the asset amount to pair with the given stable amount to provide liquidity, the current total
    /// amount of LP shares (LP tokens), and the number of shares the LP would get by providing the given liquidity
    /// amount.
    function calculateAddLiquidityAmounts(int256 stableAmount)
        private
        view
        returns (
            int256 liquidityTokens,
            int256 totalLiquidityShares,
            int256 assetAmount
        )
    {
        int256 assetPrice = oracle.getPrice(assetToken);
        assetAmount = FsMath.stableToAsset(stableAmount, assetPrice);
        totalLiquidityShares = FsMath.safeCastToSigned(liquidityToken.totalSupply());

        if (totalLiquidityShares == 0) {
            // No existing liquidity so these are first shares we're minting.
            liquidityTokens = stableAmount;
        } else {
            int256 totalOriginalLiquidityValue = getOriginalLiquidityValue(assetPrice);
            require(totalOriginalLiquidityValue > 0, "Pool bankrupt");
            // Liquidity provider provides equal value of stable and asset token. Hence 2 * stableAmount is the
            // liquidity added to the pool.
            liquidityTokens =
                (2 * stableAmount * totalLiquidityShares) /
                totalOriginalLiquidityValue;
        }
    }

    /// @notice Returns the total value the original liquidity valued in stable token that this AMM got from LPs given
    /// the asset's price (in stable)
    function getOriginalLiquidityValue(int256 assetPrice) private view returns (int256) {
        (int256 stable, int256 asset) = ammBalance(assetPrice);
        return stable + FsMath.assetToStable(asset, assetPrice);
    }

    /// @notice Returns the AMM's balance of the stable / asset tokens in the vault.
    function ammBalance(int256 price)
        public
        view
        returns (int256 ammStableBalance, int256 ammAssetBalance)
    {
        (int256 ammStablePositionOnExchange, int256 ammAssetPositionOnExchange) =
            exchangeLedger.getAmmPosition(price, block.timestamp);
        // AMM's collateral includes its position on the external spot market which should net out against its stable
        // position on the internal Futureswap exchange to equal the fees (trade and time fees) the AMM has received
        // from traders. This is then added on top of the original liquidity added to get the total amount of stable
        // the AMM owns.
        ammStableBalance = collateral + ammStablePositionOnExchange;
        ammAssetBalance = vaultBalance(assetToken) + ammAssetPositionOnExchange;
    }

    /// @notice Returns the balance of the vault in specified tokens as an int256 for calculation convenience.
    function vaultBalance(address token) private view returns (int256) {
        return FsMath.safeCastToSigned(IERC20(token).balanceOf(address(tokenVault)));
    }

    /// @notice Check that there's enough liquidity left in the vault.
    /// vaultAssetBalance is only passed in to save gas as this function can technically recompute it easily.
    function requireEnoughLiquidityLeft(
        bool isClosingTraderPosition,
        int256 totalValue,
        int256 vaultAssetBalance,
        int256 assetPrice
    ) private view {
        // Skipping liquidity check if the trade is for closing a position. This avoids the system getting completely
        // stuck because low liquidity (e.g. LPs withdrawing too much liquidity).
        if (isClosingTraderPosition) {
            return;
        }

        int256 requiredReserves =
            (totalValue * ammConfig.tradeLiquidityReserveFactor) / FsMath.FIXED_POINT_BASED;
        require(requiredReserves >= 0, "Invalid required reserve value");

        // The amount of available AMM stable and asset balances that can be used to continue its market neutral
        // strategy.
        int256 availableAmmStable = collateral;
        int256 availableAmmAsset = FsMath.assetToStable(vaultAssetBalance, assetPrice);
        require(availableAmmStable >= requiredReserves, "Stable balance below required reserves");
        require(availableAmmAsset >= requiredReserves, "Asset balance below required reserves");
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title IAmmAdapter interface.
/// @notice Implementations of this interface have all the details needed to interact with a particular AMM.
/// This pattern allows Futureswap to be extended to use several AMMs like UniswapV2 (and forks like Trader Joe),
/// UniswapV3, Trident, etc while keeping the details to connect to them outside of our core system.
interface IAmmAdapter {
    /// @notice Swaps `token1Amount` of `token1` for `token0`. If `token1Amount` is positive, then the `recipient`
    /// will receive `token1`, and if negative, they receive `token0`.
    /// @param recipient The recipient to send tokens to.
    /// @param token0 Must be one of the tokens the adapter supports.
    /// @param token1 Must be one of the tokens the adapter supports.
    /// @param token1Amount Amount of `token1` to swap. This method will revert if token1Amount is zero.
    /// @return token0Amount The amount of `token0` paid (negative) or received (positive).
    function swap(
        address recipient,
        address token0,
        address token1,
        int256 token1Amount
    ) external returns (int256 token0Amount);

    /// @notice Returns a spot price of exchanging 1 unit of token0 in units of token1.
    ///     Representation is fixed point integer with precision set by `FsMath.FIXED_POINT_BASED`
    ///     (defined to be `10**18`).
    ///
    /// @param token0 The token to return price for.
    /// @param token1 The token to return price relatively to.
    function getPrice(address token0, address token1) external view returns (int256 price);

    /// @notice Returns the tokens that this AMM adapter and underlying pool support. Order of the tokens should be the
    /// the same as the order defined by the AMM pool.
    function supportedTokens() external view returns (address[] memory tokens);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IAmmAdapterCallback {
    /// @notice Adapter callback for collecting payment. Only one of the two tokens, stable or asset, can be positive,
    /// which indicates a payment due. Negative indicates we'll receive that token as a result of the swap.
    /// Implementations of this method should protect against malicious calls, and ensure that payments are triggered
    /// only by authorized contracts or as part of a valid trade flow.
    /// @param recipient The address to send payment to.
    /// @param token0 Token corresponding to amount0Owed.
    /// @param token1 Token corresponding to amount1Owed.
    /// @param amount0Owed Token amount in underlying decimals we owe for token0.
    /// @param amount1Owed Token amount in underlying decimals we owe for token1.
    function sendPayment(
        address recipient,
        address token0,
        address token1,
        int256 amount0Owed,
        int256 amount1Owed
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title Interface for ERC677 token receiver
interface IERC677Receiver {
    /// @dev Called by a token to indicate a transfer into the callee
    /// @param _from The account that has sent the token
    /// @param _amount The amount of tokens sent
    /// @param _data The extra data being passed to the receiving contract
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool success);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Calling deposit with msg.value returns the token
    function deposit() external payable;

    /// @notice Calling withdraw returns eth to the caller
    function withdraw(uint256) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../external/IERC677Receiver.sol";

/// @title StakingIncentives allow users to stake a token to receive a reward.
interface IStakingIncentives is IERC677Receiver {
    // Used in IERC677 deposits
    struct StakingDeposit {
        // The account that is depositing the staking token
        address account;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title Utility methods basic math operations.
///      NOTE In order for the fuzzing tests to be isolated, all functions in this library need to
///      be `internal`.  Otherwise a contract that uses this library has a dependency on the
///      library.
///
///      Our current Echidna setup requires contracts to be deployable in isolation, so make sure to
///      keep the functions `internal`, until we update our Echidna tests to support more complex
///      setups.
library FsMath {
    uint256 constant BITS_108 = (1 << 108) - 1;
    int256 constant BITS_108_MIN = -(1 << 107);
    uint256 constant BITS_108_MASKED = ~BITS_108;
    uint256 constant BITS_108_SIGN = 1 << 107;
    int256 constant FIXED_POINT_BASED = 1 ether;

    function abs(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            return uint256(value);
        }
        // slither-disable-next-line safe-cast
        return uint256(-value);
    }

    function sabs(int256 value) internal pure returns (int256) {
        if (value >= 0) {
            return value;
        }
        return -value;
    }

    function sign(int256 value) internal pure returns (int256) {
        if (value < 0) {
            return -1;
        } else if (value > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    // Clip val into interval [lower, upper]
    function clip(
        int256 val,
        int256 lower,
        int256 upper
    ) internal pure returns (int256) {
        return min(max(val, lower), upper);
    }

    function safeCastToSigned(uint256 x) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        int256 ret = int256(x);
        require(ret >= 0, "Cast overflow");
        return ret;
    }

    function safeCastToUnsigned(int256 x) internal pure returns (uint256) {
        require(x >= 0, "Cast underflow");
        // slither-disable-next-line safe-cast
        return uint256(x);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    function encodeValue(int256 value) external pure returns (string memory) {
        return encodeValueStatic(value);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    ///
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    function encodeValueStatic(int256 value) internal pure returns (string memory) {
        // We are going to encode the two's complement representation.  To be consumed
        // by`decodeValue()`.
        // slither-disable-next-line safe-cast
        bytes32 y = bytes32(uint256(value));
        bytes memory bytesArray = new bytes(8 + 64);
        bytesArray[0] = "s";
        bytesArray[1] = "t";
        bytesArray[2] = "a";
        bytesArray[3] = "b";
        bytesArray[4] = "l";
        bytesArray[5] = "e";
        bytesArray[6] = "0";
        bytesArray[7] = "x";
        for (uint256 i = 0; i < 32; i++) {
            // slither-disable-next-line safe-cast
            uint8 x = uint8(y[i]);
            uint8 u = x >> 4;
            uint8 l = x & 0xF;
            bytesArray[8 + 2 * i] = u >= 10 ? bytes1(u + 65 - 10) : bytes1(u + 48);
            bytesArray[8 + 2 * i + 1] = l >= 10 ? bytes1(l + 65 - 10) : bytes1(l + 48);
        }
        // Bytes we generated above are valid UTF-8.
        // slither-disable-next-line safe-cast
        return string(bytesArray);
    }

    /// @notice Decode an encoded int256 value above.
    /// @return 0 if string is not of the right format.
    function decodeValue(bytes memory r) external pure returns (int256) {
        return decodeValueStatic(r);
    }

    /// @notice Decode an encoded int256 value above.
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    /// @return 0 if string is not of the right format.
    function decodeValueStatic(bytes memory r) internal pure returns (int256) {
        if (
            r.length == 8 + 64 &&
            r[0] == "s" &&
            r[1] == "t" &&
            r[2] == "a" &&
            r[3] == "b" &&
            r[4] == "l" &&
            r[5] == "e" &&
            r[6] == "0" &&
            r[7] == "x"
        ) {
            uint256 y;
            for (uint256 i = 0; i < 64; i++) {
                // slither-disable-next-line safe-cast
                uint8 h = uint8(r[8 + i]);
                uint256 x;
                if (h >= 65) {
                    if (h >= 65 + 16) return 0;
                    x = (h + 10) - 65;
                } else {
                    if (!(h >= 48 && h < 48 + 10)) return 0;
                    x = h - 48;
                }
                y |= x << (256 - 4 - 4 * i);
            }
            // We were decoding a two's complement representation.  Produced by `encodeValue()`.
            // slither-disable-next-line safe-cast
            return int256(y);
        } else {
            return 0;
        }
    }

    /// @notice Returns the lower 108 bits of data as a positive int256
    function read108(uint256 data) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        return int256(data & BITS_108);
    }

    /// @notice Returns the lower 108 bits sign extended as a int256
    function readSigned108(uint256 data) internal pure returns (int256) {
        uint256 temp = data & BITS_108;

        if (temp & BITS_108_SIGN > 0) {
            temp = temp | BITS_108_MASKED;
        }
        // slither-disable-next-line safe-cast
        return int256(temp);
    }

    /// @notice Performs a range check and returns the lower 108 bits of the value
    function pack108(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            require(value <= int256(BITS_108), "RE");
        } else {
            require(value >= BITS_108_MIN, "RE");
        }

        // Ranges were checked above.  And we expect negative values to be encoded in a two's
        // complement form, as this is how we decode them in `readSigned108()`.
        // slither-disable-next-line safe-cast
        return uint256(value) & BITS_108;
    }

    /// @notice Calculate the leverage amount given amounts of stable/asset and the asset price.
    function calculateLeverage(
        int256 assetAmount,
        int256 stableAmount,
        int256 assetPrice
    ) internal pure returns (uint256) {
        // Return early for gas saving.
        if (assetAmount == 0) {
            return 0;
        }
        int256 assetInStable = assetToStable(assetAmount, assetPrice);
        int256 collateral = assetInStable + stableAmount;
        // Avoid division by 0.
        require(collateral > 0, "Insufficient collateral");
        // slither-disable-next-line safe-cast
        return FsMath.abs(assetInStable * FIXED_POINT_BASED) / uint256(collateral);
    }

    /// @notice Returns the worth of the given asset amount in stable token.
    function assetToStable(int256 assetAmount, int256 assetPrice) internal pure returns (int256) {
        return (assetAmount * assetPrice) / FIXED_POINT_BASED;
    }

    /// @notice Returns the worth of the given stable amount in asset token.
    function stableToAsset(int256 stableAmount, int256 assetPrice) internal pure returns (int256) {
        return (stableAmount * FIXED_POINT_BASED) / assetPrice;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;







library FsUtils {
    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    // Slither sees this function is not used, but it is convenient to have it around, as it
    // actually provides better error messages than `nonNull` above.
    // slither-disable-next-line dead-code
    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }

    // Assert a condition. Assert should be used to assert an invariant that should be true
    // logically.
    // This is useful for readability and debugability. A failing assert is always a bug.
    //
    // In production builds (non-hardhat, and non-localhost deployments) this method is a noop.
    //
    // Use "require" to enforce requirements on data coming from outside of a contract. Ie.,
    //
    // ```solidity
    // function nonNegativeX(int x) external { require(x >= 0, "non-negative"); }
    // ```
    //
    // But
    // ```solidity
    // function nonNegativeX(int x) private { assert(x >= 0); }
    // ```
    //
    // If a private function has a pre-condition that it should only be called with non-negative
    // values it's a bug in the contract if it's called with a negative value.
    function Assert(bool cond) internal pure {



    }
























}

contract ImmutableOwnable {
    address public immutable owner;

    constructor(address _owner) {
        // slither-disable-next-line missing-zero-check
        owner = FsUtils.nonNull(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
}

// Contracts deriving from this contract will have a public pure function
// that returns a gitCommitHash at the moment it was compiled.
contract GitCommitHash {
    // A purely random string that's being replaced in a prod build by
    // the git hash at build time.
    uint256 public immutable gitCommitHash =
        0x00000000000000000000000000000000000000000000000069e26a2de9e44bd97a824718819dfb8aeaac243f;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../external/IERC677Token.sol";

/// @title The interface for the Futureswap liquidity token that is used in IExchange.
interface ILiquidityToken is IERC677Token {
    /// @notice Mints a given amount of tokens to the exchange
    /// @param _amount The amount of tokens to mint
    function mint(uint256 _amount) external;

    /// @notice Burn a given amount of tokens from the exchange
    /// @param _amount The amount of tokens to burn
    function burn(uint256 _amount) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./FsOwnable.sol";
import "../lib/Utils.sol";

contract FsBase is Initializable, FsOwnable, GitCommitHash {
    /// @notice We reserve 1000 slots for the base contract in case
    //          we ever need to add fields to the contract.
    //slither-disable-next-line unused-state
    uint256[999] private _____baseGap;

    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title An interface for the internal AMM that trades with the users of an exchange.
///
/// @notice When a user trades on an exchange, the AMM will automatically take the opposite position, effectively
/// acting like a market maker in a traditional order book market.
///
/// An AMM can execute any hedging or arbitraging strategies internally. For example, it can trade with a spot market
/// such as Uniswap to hedge a position.
interface IAmm {
    /// @notice Takes a position in token1 against token0. Can only be called by the exchange to take the opposite
    /// position to a trader. The trade can fail for several different reasons: its hedging strategy failed, it has
    /// insufficient funds, out of gas, etc.
    ///
    /// @param _assetAmount The position to take in asset. Positive for long and negative for short.
    /// @param _oraclePrice The reference price for the trade.
    /// @param _isClosingTraderPosition Whether the trade is for closing a trader's position partially or fully.
    /// @return stableAmount The amount of stable amount received or paid.
    function trade(
        int256 _assetAmount,
        int256 _oraclePrice,
        bool _isClosingTraderPosition
    ) external returns (int256 stableAmount);

    /// @notice Returns the asset price that this AMM quotes for trading with it.
    /// @return assetPrice The asset price that this AMM quotes for trading with it
    function getAssetPrice() external view returns (int256 assetPrice);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IAmm.sol";
import "./IOracle.sol";

/// @title Futureswap V4.1 exchange for a single pair of tokens.
///
/// @notice An API for an exchange that manages leveraged trades for one pair of tokens.  One token
/// is called "asset" and it's address is returned by `assetToken()`. The other token is called
/// "stable" and it's address is returned by `stableToken()`.  Exchange is mostly symmetrical with
/// regard to how "asset" and "stable" are treated.
///
/// The exchange only deals with abstract accounting. It requires a trusted setup with a TokenRouter
/// to do actual transfers of ERC20's. The two basic operations are
///
///  - Trade: Implemented by `changePosition()`, requires collateral to be deposited by caller.
///  - Liquidation bot(s): Implemented by `liquidate()`.
///
interface IExchangeLedger {
    /// @notice Restricts exchange functionality.
    enum ExchangeState {
        // All functions are operational.
        NORMAL,
        // Only allow positions to be closed and liquidity removed.
        PAUSED,
        // No operations all allowed.
        STOPPED
    }

    /// @notice Emitted on all trades/liquidations containing all information of the update.
    /// @param cpd The `ChangePositionData` struct that contains all information collected.
    event PositionChanged(ChangePositionData cpd);

    /// @notice Emitted when exchange config is updated.
    event ExchangeConfigChanged(ExchangeConfig previousConfig, ExchangeConfig newConfig);

    /// @notice Emitted when the exchange state is updated.
    /// @param previousState the old state.
    /// @param previousPausePrice the oracle price the exchange is paused at.
    /// @param newState the new state.
    /// @param newPausePrice the new oracle price in case the exchange is paused.
    event ExchangeStateChanged(
        ExchangeState previousState,
        int256 previousPausePrice,
        ExchangeState newState,
        int256 newPausePrice
    );

    /// @notice Emitted when exchange hook is updated.
    event ExchangeHookAddressChanged(address previousHook, address newHook);

    /// @notice Emitted when AMM used by the exchange is updated.
    event AmmAddressChanged(address previousAmm, address newAmm);

    /// @notice Emitted when the TradeRouter authorized by the exchange is updated.
    event TradeRouterAddressChanged(address previousTradeRouter, address newTradeRouter);

    /// @notice Emitted when an ADL happens against the pool.
    /// @param deltaAsset How much asset transferred to pool.
    /// @param deltaStable How much stable transferred to pool.
    event AmmAdl(int256 deltaAsset, int256 deltaStable);

    /// @notice Emitted if the hook call fails.
    /// @param reason Revert reason.
    /// @param cpd The change position data of this trade.
    event OnChangePositionHookFailed(string reason, ChangePositionData cpd);

    /// @notice Emitted when a tranche is ADL'd.
    /// @param tranche This risk tranche
    /// @param trancheIdx The id of the tranche that was ADL'd.
    /// @param assetADL Amount of asset ADL'd against this tranche.
    /// @param stableADL Amount of stable ADL'd against this tranche.
    /// @param totalTrancheShares Total amount of shares in this tranche.
    event TrancheAutoDeleveraged(
        uint8 tranche,
        uint32 trancheIdx,
        int256 assetADL,
        int256 stableADL,
        int256 totalTrancheShares
    );

    /// @notice Represents a payout of `amount` with recipient `to`.
    struct Payout {
        address to;
        uint256 amount;
    }

    /// @dev Data tracked throughout changePosition and used in the `PositionChanged` event.
    struct ChangePositionData {
        // The address of the trader whose position is being changed.
        address trader;
        // The liquidator address is only non zero if this is a liquidation.
        address liquidator;
        // Whether or not this change is a request to close the trade.
        bool isClosing;
        // The change in asset that we are being asked to make to the position.
        int256 deltaAsset;
        // The change in stable that we are being asked to make to the position.
        int256 deltaStable;
        // A bound for the amount in stable paid / received for making the change.
        // Note: If this is set to zero no bounds are enforced.
        // Note: This is set to zero for liquidations.
        int256 stableBound;
        // Oracle price
        int256 oraclePrice;
        // Time used to compute funding.
        uint256 time;
        // Time fee charged.
        int256 timeFeeCharged;
        // Funding paid from longs to shorts (negative if other direction).
        int256 dfrCharged;
        // The amount of stable tokens being paid to liquidity providers as a trade fee.
        int256 tradeFee;
        // The amount of asset the position had before changing it.
        int256 startAsset;
        // The amount of stable the position had before changing it.
        int256 startStable;
        // The amount of asset the position had after changing it.
        int256 totalAsset;
        // The amount of stable the position had after changing it.
        int256 totalStable;
        // The amount of stable tokens being paid to the trader.
        int256 traderPayment;
        // The amount of stable tokens being paid to the liquidator.
        int256 liquidatorPayment;
        // The amount of stable tokens being paid to the treasury.
        int256 treasuryPayment;
        // The price at which the trade was executed.
        int256 executionPrice;
    }

    /// @dev Exchange config parameters
    struct ExchangeConfig {
        // The trade fee to be charged in percent for a trade range: [0, 1 ether]
        int256 tradeFeeFraction;
        // The time fee to be charged in percent for a trade range: [0, 1 ether]
        int256 timeFee;
        // The maximum leverage that the exchange allows before a trade becomes liquidatable, range: [0, 200 ether),
        // 0 (inclusive) to 200x leverage (exclusive)
        uint256 maxLeverage;
        // The minimum of collateral (stable token amount) a position needs to have. If a position falls below this
        // number it becomes liquidatable
        uint256 minCollateral;
        // The percentage of the trade fee being paid to the treasury, range: [0, 1 ether]
        int256 treasuryFraction;
        // A fee for imbalancing the exchange, range: [0, 1 ether].
        int256 dfrRate;
        // A fee that is paid to a liquidator for liquidating a trade expressed as percentage of remaining collateral,
        // range: [0, 1 ether]
        int256 liquidatorFrac;
        // A maximum amount of stable tokens that a liquidator can receive for a liquidation.
        int256 maxLiquidatorFee;
        // A fee that is paid to a liquidity providers if a trade gets liquidated expressed as percentage of
        // remaining collateral, range: [0, 1 ether]
        int256 poolLiquidationFrac;
        // A maximum amount of stable tokens that the liquidity providers can receive for a liquidation.
        int256 maxPoolLiquidationFee;
        // A fee that a trade experiences if its causing other trades to get ADL'ed, range: [0, 1 ether].
        int256 adlFeePercent;
    }

    /// @notice Returns the current state of the exchange. See description on ExchangeState for details.
    function exchangeState() external view returns (ExchangeState);

    /// @notice Returns the price that exchange was paused at.
    /// If the exchange got paused, this price overrides the oracle price for liquidations and liquidity
    /// providers redeeming their liquidity.
    function pausePrice() external view returns (int256);

    /// @notice Address of the amm this exchange calls to take the opposite of trades.
    function amm() external view returns (IAmm);

    /// @notice Changes a traders position in the exchange.
    /// @param deltaStable The amount of stable to change the position by.
    /// Positive values will add stable to the position (move stable token from the trader) into the exchange
    /// Negative values will remove stable from the position and send the trader tokens
    /// @param deltaAsset  The amount of asset the position should be changed by.
    /// @param stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the
    /// `deltaAsset` change.
    /// If the user is buying asset (deltaAsset > 0), the user will have to choose a maximum negative number that he is
    /// going to be in debt for.
    /// If the user is selling asset (deltaAsset < 0) the user will have to choose a minimum positive number of stable
    /// that he wants to be credited with.
    /// @return the payouts that need to be made, plus serialized of the `ChangePositionData` struct
    function changePosition(
        address trader,
        int256 deltaStable,
        int256 deltaAsset,
        int256 stableBound,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Liquidates a trader's position.
    /// For a position to be liquidatable, it needs to either have less collateral (stable) left than
    /// ExchangeConfig.minCollateral or exceed a leverage higher than ExchangeConfig.maxLeverage.
    /// If this is a case, anyone can liquidate the position and receive a reward.
    /// @param trader The trader to liquidate.
    /// @return The needed payouts plus a serialized `ChangePositionData`.
    function liquidate(
        address trader,
        address liquidator,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Position for a particular trader.
    /// @param trader The address to use for obtaining the position.
    /// @param price The oracle price at which to evaluate funding/
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getPosition(
        address trader,
        int256 price,
        uint256 time
    )
        external
        view
        returns (
            int256 asset,
            int256 stable,
            uint32 trancheIdx
        );

    /// @notice Returns the position of the AMM in the exchange.
    /// @param price The oracle price at which to evaluate funding.
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getAmmPosition(int256 price, uint256 time)
        external
        view
        returns (int256 stableAmount, int256 assetAmount);

    /// @notice Updates the config of the exchange, can only be performed by the voting executor.
    function setExchangeConfig(ExchangeConfig calldata _config) external;

    /// @notice Update the exchange state.
    /// Is used to PAUSE or STOP the exchange. When PAUSED, trades cannot open, liquidity cannot be added, and a
    /// fixed oracle price is set. When STOPPED no user actions can occur.
    function setExchangeState(ExchangeState _state, int256 _pausePrice) external;

    /// @notice Update the exchange hook.
    function setHook(address _hook) external;

    /// @notice Update the AMM used in the exchange.
    function setAmm(address _amm) external;

    /// @notice Update the TradeRouter authorized for this exchange.
    function setTradeRouter(address _tradeRouter) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/Utils.sol";
import "../upgrade/FsAdmin.sol";

/// @title TokenVault implementation.
/// @notice TokenVault is the only contract in the Futureswap system that stores ERC20 tokens, including both collateral
/// and liquidity. Each exchange has its own instance of TokenVault, which provides isolation of the funds between
/// different exchanges and adds an additional layer of protection in case one exchange gets compromised.
/// Users are not meant to interact with this contract directly. For each exchange, only the TokenRouter and the
/// corresponding implementation of IAmm (for example, SpotMarketAmm) are authorized to withdraw funds. If new versions
/// of these contracts become available, then they can be approved and the old ones disapproved.
///
/// @dev We decided to make TokenVault non-upgradable. The implementation is very simple and in case of an emergency
/// recovery of funds, the VotingExecutor (which should be the owner of TokenVault) can approve arbitrary addresses
/// to withdraw funds.
contract TokenVault is Ownable, FsAdmin, GitCommitHash {
    using SafeERC20 for IERC20;

    /// @notice Mapping to track addresses that are approved to move funds from this vault.
    mapping(address => bool) public isApproved;

    /// @notice When the TokenVault is frozen, no transfer of funds in or out of the contract can happen.
    bool isFrozen;

    /// @notice Requires caller to be an approved address.
    modifier onlyApprovedAddress() {
        require(isApproved[msg.sender], "Not an approved address");
        _;
    }

    /// @notice Emitted when approvals for `userAddress` changes. Reports the value before the change in
    /// `previousApproval` and the value after the change in `currentApproval`.
    event VaultApprovalChanged(
        address indexed userAddress,
        bool previousApproval,
        bool currentApproval
    );

    /// @notice Emitted when `amount` tokens are transfered from the TokenVault to the `recipient`.
    event VaultTokensTransferred(address recipient, address token, uint256 amount);

    /// @notice Emitted when the vault is frozen/unfrozen.
    event VaultFreezeStateChanged(bool previousFreezeState, bool freezeState);

    constructor(address _admin) {
        initializeFsAdmin(_admin);
    }

    /// @notice Changes the approval status of an address. If an address is approved, it's allowed to move funds from
    /// the vault. Can only be called by the VotingExecutor.
    ///
    /// @param userAddress The address to change approvals for. Can't be the zero address.
    /// @param approved Whether to approve or disapprove the address.
    function setAddressApproval(address userAddress, bool approved) external onlyOwner {
        // This does allow an arbitrary address to be approved to withdraw funds from the vault but this risk
        // is mitigated as only the owner can call this function. As long as the owner is the VotingExecutor,
        // which is controlled by governance, no single individual would be able to approve a malicious address.
        // slither-disable-next-line missing-zero-check
        userAddress = FsUtils.nonNull(userAddress);
        bool previousApproval = isApproved[userAddress];

        if (previousApproval == approved) {
            return;
        }

        isApproved[userAddress] = approved;
        emit VaultApprovalChanged(userAddress, previousApproval, approved);
    }

    /// @notice Transfers the given amount of token from the vault to a given address.
    /// This can only be called by an approved address.
    ///
    /// @param recipient The address to transfer tokens to.
    /// @param token Which token to transfer.
    /// @param amount The amount to transfer, represented in the token's underlying decimals.
    function transfer(
        address recipient,
        address token,
        uint256 amount
    ) external onlyApprovedAddress {
        require(!isFrozen, "Vault is frozen");

        emit VaultTokensTransferred(recipient, token, amount);
        // There's no risk of a malicious token being passed here, leading to reentrancy attack
        // because:
        // (1) Only approved addresses can call this method to move tokens from the vault.
        // (2) Only tokens associated with the exchange would ever be moved.
        // OpenZeppelin safeTransfer doesn't return a value and will revert if any issue occurs.
        IERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice For security we allow admin/voting to freeze/unfreeze the vault this allows an admin
    /// to freeze funds, but not move them.
    function setIsFrozen(bool _isFrozen) external {
        if (isFrozen == _isFrozen) {
            return;
        }

        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin");
        emit VaultFreezeStateChanged(isFrozen, _isFrozen);
        isFrozen = _isFrozen;
    }
}

// SPDX-License-Identifier: MIT

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677Token is IERC20 {
    /// @dev transfer token to a contract address with additional data if the recipient is a contract.
    /// @param _receiver The address to transfer to.
    /// @param _amount The amount to be transferred.
    /// @param _data The extra data to be passed to the receiving contract.
    function transferAndCall(
        address _receiver,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract FsOwnable is Context {
    address private _owner;
    // We removed a field here, but we do not want to change a layout, as this contract is use as
    // abase by a lot of other contracts.
    // slither-disable-next-line unused-state,constable-states
    bool private ____unused1;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initializeFsOwnable() internal {
        require(_owner == address(0), "Non zero owner");

        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /// @dev Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title An interface for interacting with oracles such as Chainlink, Uniswap V2/V3 TWAP, Band etc.
/// @notice This interface allows fetching prices for two tokens.
interface IOracle {
    /// @notice Address of the first token this oracle adapter supports.
    function token0() external view returns (address);

    /// @notice Address of the second token this oracle adapter supports.
    function token1() external view returns (address);

    /// @notice Returns the price of a supported token, relatively to the other token.
    function getPrice(address _token) external view returns (int256);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract FsAdmin {
    /// @notice The admin of the VotingExecutor, the admin can call the execute method
    ///         directly. Admin will be phased out
    address public admin;

    /// @notice A newly proposed admin. Admin is handed over to an address and needs to be confirmed
    ///         before a new admin becomes live. This prevents using an unusable address as a new admin
    address public proposedNewAdmin;

    /// @notice Initializes the VotingExecutor with a given admin, can only be called once
    /// @param _admin The admin of the VotingExectuor, see field description for more detail
    function initializeFsAdmin(address _admin) internal {
        //slither-disable-next-line missing-zero-check
        admin = nonNullAdmin(_admin);
    }

    /// @notice Remove the admin from the contract, can only be called by the current admin
    function removeAdmin() external onlyAdmin {
        emit AdminRemoved(admin);
        admin = address(0);
    }

    /// @notice Propose a new admin, the new address has to call acceptAdmin for adminship to be handed over
    /// @param _newAdmin The newly proposed admin
    function proposeNewAdmin(address _newAdmin) external onlyAdmin {
        //slither-disable-next-line missing-zero-check
        proposedNewAdmin = nonNullAdmin(_newAdmin);
        emit NewAdminProposed(_newAdmin);
    }

    /// @notice Accept adminship over the contract. This can only be called by a proposed admin
    function acceptAdmin() external {
        require(msg.sender == proposedNewAdmin, "Invalid caller");
        address oldAdmin = admin;
        admin = msg.sender;
        proposedNewAdmin = address(0);
        emit AdminAccepted(oldAdmin, msg.sender);
    }

    /// @dev Prevents calling from any address except the admin address
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function nonNullAdmin(address _address) private pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    /// @notice Emitted if adminship is revoked from the contract
    /// @param admin The address that gave up adminship
    event AdminRemoved(address admin);

    /// @notice Emitted when a new admin address is proposed
    /// @param newAdmin The new admin address
    event NewAdminProposed(address newAdmin);

    /// @notice Emitted when a new admin address has accepted adminship
    /// @param oldAdmin The old admin address
    /// @param newAdmin The new admin address
    event AdminAccepted(address oldAdmin, address newAdmin);
}