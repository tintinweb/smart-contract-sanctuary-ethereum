/// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@hifi/amm/contracts/IHifiPool.sol";
import "@hifi/protocol/contracts/core/balance-sheet/IBalanceSheetV2.sol";
import "@hifi/protocol/contracts/core/h-token/IHToken.sol";
import "@prb/contracts/token/erc20/IErc20.sol";
import "@prb/contracts/token/erc20/SafeErc20.sol";
import "@prb/contracts/token/erc20/IErc20Permit.sol";

import "./IHifiProxyTarget.sol";
import "./external/WethInterface.sol";

/// @title HifiProxyTarget
/// @author Hifi
contract HifiProxyTarget is IHifiProxyTarget {
    using SafeErc20 for IErc20;

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiProxyTarget
    function addLiquidity(
        IHifiPool hifiPool,
        uint256 underlyingOffered,
        uint256 maxHTokenRequired
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        (uint256 hTokenRequired, ) = hifiPool.getMintInputs(underlyingOffered);
        if (hTokenRequired > maxHTokenRequired) {
            revert HifiProxyTarget__AddLiquidityHTokenSlippage(maxHTokenRequired, hTokenRequired);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingOffered);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingOffered);

        // Transfer the hTokens to the DSProxy.
        IHToken hToken = hifiPool.hToken();
        hToken.transferFrom(msg.sender, address(this), hTokenRequired);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenRequired);

        // Add liquidity to the AMM.
        uint256 poolTokensMinted = hifiPool.mint(underlyingOffered);

        // The LP tokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.transfer(msg.sender, poolTokensMinted);
    }

    /// @inheritdoc IHifiProxyTarget
    function addLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingOffered,
        uint256 maxHTokenRequired,
        uint256 deadline,
        bytes memory signatureHToken,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), underlyingOffered, deadline, signatureUnderlying);
        permitInternal(hifiPool.hToken(), maxHTokenRequired, deadline, signatureHToken);
        addLiquidity(hifiPool, underlyingOffered, maxHTokenRequired);
    }

    /// @inheritdoc IHifiProxyTarget
    function borrowHToken(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 borrowAmount
    ) public override {
        balanceSheet.borrow(hToken, borrowAmount);

        // The hTokens are now in the DSProxy, so we relay them to the end user.
        hToken.transfer(msg.sender, borrowAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function borrowHTokenAndAddLiquidity(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        (uint256 hTokenRequired, ) = hifiPool.getMintInputs(underlyingOffered);
        if (hTokenRequired > maxBorrowAmount) {
            revert HifiProxyTarget__AddLiquidityHTokenSlippage(maxBorrowAmount, hTokenRequired);
        }

        // Borrow the hTokens.
        IHToken hToken = hifiPool.hToken();
        balanceSheet.borrow(hToken, hTokenRequired);

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingOffered);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingOffered);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenRequired);

        // Add liquidity to pool.
        uint256 poolTokensMinted = hifiPool.mint(underlyingOffered);

        // The LP tokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.transfer(msg.sender, poolTokensMinted);
    }

    /// @inheritdoc IHifiProxyTarget
    function borrowHTokenAndAddLiquidityWithSignature(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) public override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), underlyingOffered, deadline, signatureUnderlying);
        borrowHTokenAndAddLiquidity(balanceSheet, hifiPool, maxBorrowAmount, underlyingOffered);
    }

    /// @inheritdoc IHifiProxyTarget
    function borrowHTokenAndBuyUnderlying(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOut
    ) external override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 hTokenIn = hifiPool.getQuoteForBuyingUnderlying(underlyingOut);
        if (hTokenIn > maxBorrowAmount) {
            revert HifiProxyTarget__TradeSlippage(maxBorrowAmount, hTokenIn);
        }

        // Borrow the hTokens.
        IHToken hToken = hifiPool.hToken();
        balanceSheet.borrow(hToken, hTokenIn);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenIn);

        // Buy underlying and relay it to the end user.
        hifiPool.buyUnderlying(msg.sender, underlyingOut);

        emit BorrowHTokenAndBuyUnderlying(msg.sender, hTokenIn, underlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function borrowHTokenAndSellHToken(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 underlyingOut = hifiPool.getQuoteForSellingHToken(borrowAmount);
        if (underlyingOut < minUnderlyingOut) {
            revert HifiProxyTarget__TradeSlippage(minUnderlyingOut, underlyingOut);
        }

        // Borrow the hTokens.
        IHToken hToken = hifiPool.hToken();
        balanceSheet.borrow(hToken, borrowAmount);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), borrowAmount);

        // Sell the hTokens and relay the underlying to the end user.
        hifiPool.sellHToken(msg.sender, borrowAmount);

        emit BorrowHTokenAndSellHToken(msg.sender, borrowAmount, underlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHToken(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingIn
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 underlyingIn = hifiPool.getQuoteForBuyingHToken(hTokenOut);
        if (underlyingIn > maxUnderlyingIn) {
            revert HifiProxyTarget__TradeSlippage(maxUnderlyingIn, underlyingIn);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingIn);

        // Buy the hTokens and relay them to the end user.
        hifiPool.buyHToken(msg.sender, hTokenOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHTokenAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingAmount
    ) public override {
        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        uint256 underlyingIn = hifiPool.getQuoteForBuyingHToken(hTokenOut);
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingIn);

        // Buy the hTokens.
        hifiPool.buyHToken(address(this), hTokenOut);

        // Calculate how much underlying is required to provide "hTokenOut" liquidity to the AMM.
        IHToken hToken = hifiPool.hToken();
        uint256 underlyingRequired = getUnderlyingRequired(hifiPool, hTokenOut);

        // Ensure that we are within the user's slippage tolerance.
        uint256 totalUnderlyingAmount = underlyingIn + underlyingRequired;
        if (totalUnderlyingAmount > maxUnderlyingAmount) {
            revert HifiProxyTarget__AddLiquidityUnderlyingSlippage(maxUnderlyingAmount, totalUnderlyingAmount);
        }

        // Transfer the underlying to the DSProxy.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingRequired);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingRequired);
        approveSpender(hToken, address(hifiPool), hTokenOut);

        // Add liquidity to the AMM.
        (uint256 hTokenRequired, ) = hifiPool.getMintInputs(underlyingRequired);
        uint256 poolTokensMinted = hifiPool.mint(underlyingRequired);

        // The LP tokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.transfer(msg.sender, poolTokensMinted);

        // "hTokenOut" is greater or equal than "hTokenRequired", because not all of "hTokenOut" was used in the mint.
        // "normalizedUnderlyingRequired" was denormalized to "underlyingRequired", offsetting the trailing 12 digits.
        unchecked {
            uint256 hTokenDelta = hTokenOut - hTokenRequired;
            hToken.transfer(msg.sender, hTokenDelta);
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHTokenAndRepayBorrow(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 maxUnderlyingIn,
        uint256 hTokenOut
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 underlyingIn = hifiPool.getQuoteForBuyingHToken(hTokenOut);
        if (underlyingIn > maxUnderlyingIn) {
            revert HifiProxyTarget__TradeSlippage(maxUnderlyingIn, underlyingIn);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingIn);

        // Buy the hTokens.
        hifiPool.buyHToken(address(this), hTokenOut);

        // Query the amount of debt that the user owes.
        IHToken hToken = hifiPool.hToken();
        uint256 debtAmount = balanceSheet.getDebtAmount(address(this), hToken);

        // Use the recently bought hTokens to repay the borrow.
        if (debtAmount >= hTokenOut) {
            balanceSheet.repayBorrow(hToken, hTokenOut);
        } else {
            balanceSheet.repayBorrow(hToken, debtAmount);

            // Relay any remaining hTokens to the end user.
            unchecked {
                uint256 hTokenDelta = hTokenOut - debtAmount;
                hToken.transfer(msg.sender, hTokenDelta);
            }
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingIn,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) public override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), maxUnderlyingIn, deadline, signatureUnderlying);
        buyHToken(hifiPool, hTokenOut, maxUnderlyingIn);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHTokenAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(
            IErc20Permit(address(hifiPool.underlying())),
            maxUnderlyingAmount,
            deadline,
            signatureUnderlying
        );
        buyHTokenAndAddLiquidity(hifiPool, hTokenOut, maxUnderlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyHTokenAndRepayBorrowWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 maxUnderlyingIn,
        uint256 hTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), maxUnderlyingIn, deadline, signatureUnderlying);
        buyHTokenAndRepayBorrow(hifiPool, balanceSheet, maxUnderlyingIn, hTokenOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyUnderlying(
        IHifiPool hifiPool,
        uint256 underlyingOut,
        uint256 maxHTokenIn
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 hTokenIn = hifiPool.getQuoteForBuyingUnderlying(underlyingOut);
        if (hTokenIn > maxHTokenIn) {
            revert HifiProxyTarget__TradeSlippage(maxHTokenIn, hTokenIn);
        }

        // Transfer the hTokens to the DSProxy.
        IErc20 hToken = hifiPool.hToken();
        hToken.transferFrom(msg.sender, address(this), hTokenIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenIn);

        // Buy the underlying and relay it to the end user.
        hifiPool.buyUnderlying(msg.sender, underlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyUnderlyingAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 maxHTokenAmount,
        uint256 underlyingOffered
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 hTokenIn = hifiPool.getQuoteForBuyingUnderlying(underlyingOffered);
        if (hTokenIn > maxHTokenAmount) {
            revert HifiProxyTarget__TradeSlippage(maxHTokenAmount, hTokenIn);
        }

        // Transfer the hTokens to the DSProxy.
        IHToken hToken = hifiPool.hToken();
        hToken.transferFrom(msg.sender, address(this), hTokenIn);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), maxHTokenAmount);

        // Buy the underlying.
        hifiPool.buyUnderlying(address(this), underlyingOffered);

        // Ensure that we are within the user's slippage tolerance.
        (uint256 hTokenRequired, ) = hifiPool.getMintInputs(underlyingOffered);
        uint256 totalhTokenAmount = hTokenIn + hTokenRequired;
        if (totalhTokenAmount > maxHTokenAmount) {
            revert HifiProxyTarget__AddLiquidityHTokenSlippage(maxHTokenAmount, totalhTokenAmount);
        }

        // Transfer the hTokens to the DSProxy. We are calling the "transfer" function twice because we couldn't
        // have known what value "hTokenRequired" will have had after the call to "buyUnderlying".
        hToken.transferFrom(msg.sender, address(this), hTokenRequired);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(hifiPool.underlying(), address(hifiPool), underlyingOffered);

        // Add liquidity to the AMM.
        uint256 poolTokensMinted = hifiPool.mint(underlyingOffered);

        // The LP tokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.transfer(msg.sender, poolTokensMinted);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyUnderlyingWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingOut,
        uint256 maxHTokenIn,
        uint256 deadline,
        bytes memory signatureHToken
    ) external override {
        permitInternal(hifiPool.hToken(), maxHTokenIn, deadline, signatureHToken);
        buyUnderlying(hifiPool, underlyingOut, maxHTokenIn);
    }

    /// @inheritdoc IHifiProxyTarget
    function buyUnderlyingAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 maxHTokenAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureHToken
    ) external override {
        permitInternal(hifiPool.hToken(), maxHTokenAmount, deadline, signatureHToken);
        buyUnderlyingAndAddLiquidity(hifiPool, maxHTokenAmount, underlyingOffered);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateral(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 depositAmount
    ) public override {
        // Transfer the collateral to the DSProxy.
        collateral.safeTransferFrom(msg.sender, address(this), depositAmount);

        // Deposit the collateral into the BalanceSheet contract.
        depositCollateralInternal(balanceSheet, collateral, depositAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHToken(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHToken hToken,
        uint256 depositAmount,
        uint256 borrowAmount
    ) public override {
        depositCollateral(balanceSheet, collateral, depositAmount);
        borrowHToken(balanceSheet, hToken, borrowAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHTokenAndAddLiquidity(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered
    ) public override {
        depositCollateral(balanceSheet, collateral, depositAmount);
        borrowHTokenAndAddLiquidity(balanceSheet, hifiPool, maxBorrowAmount, underlyingOffered);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHTokenAndSellHToken(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) public override {
        depositCollateral(balanceSheet, collateral, depositAmount);
        borrowHTokenAndSellHToken(balanceSheet, hifiPool, borrowAmount, minUnderlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlying(IHToken hToken, uint256 underlyingAmount) public override {
        uint256 oldHTokenBalance = hToken.balanceOf(address(this));
        depositUnderlyingInternal(hToken, underlyingAmount);

        unchecked {
            // Calculate how many hTokens were minted.
            uint256 newHTokenBalance = hToken.balanceOf(address(this));
            uint256 hTokenAmount = newHTokenBalance - oldHTokenBalance;

            // The hTokens are now in the DSProxy, so we relay them to the end user.
            hToken.transfer(msg.sender, hTokenAmount);
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlyingAndBorrowHTokenAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 underlyingOffered
    ) public override {
        // When the underlying moonlights as the collateral, the user can borrow on a one-to-one basis.
        uint256 maxBorrowAmount = normalize(depositAmount, hifiPool.underlyingPrecisionScalar());

        // Ensure that we are within the user's slippage tolerance.
        (uint256 hTokenRequired, ) = hifiPool.getMintInputs(underlyingOffered);
        if (hTokenRequired > maxBorrowAmount) {
            revert HifiProxyTarget__AddLiquidityHTokenSlippage(maxBorrowAmount, hTokenRequired);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        uint256 totalUnderlyingAmount = depositAmount + underlyingOffered;
        underlying.safeTransferFrom(msg.sender, address(this), totalUnderlyingAmount);

        // Deposit the underlying in the HToken contract to mint hTokens.
        IHToken hToken = hifiPool.hToken();
        depositUnderlyingInternal(hToken, depositAmount);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingOffered);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenRequired);

        // Add liquidity to pool.
        uint256 poolTokensMinted = hifiPool.mint(underlyingOffered);

        // The LP tokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.transfer(msg.sender, poolTokensMinted);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlyingAndRepayBorrow(
        IHToken hToken,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingAmount
    ) public override {
        uint256 oldHTokenBalance = hToken.balanceOf(address(this));
        depositUnderlyingInternal(hToken, underlyingAmount);

        unchecked {
            // Calculate how many hTokens were minted.
            uint256 newHTokenBalance = hToken.balanceOf(address(this));
            uint256 hTokenAmount = newHTokenBalance - oldHTokenBalance;

            // Use the newly minted hTokens to repay the debt.
            balanceSheet.repayBorrow(hToken, hTokenAmount);
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        uint256 depositAmount,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external override {
        permitInternal(collateral, depositAmount, deadline, signatureCollateral);
        depositCollateral(balanceSheet, collateral, depositAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHTokenWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHToken hToken,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external override {
        permitInternal(collateral, depositAmount, deadline, signatureCollateral);
        depositCollateralAndBorrowHToken(balanceSheet, collateral, hToken, depositAmount, borrowAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHTokenAndAddLiquidityWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureCollateral,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(collateral, depositAmount, deadline, signatureCollateral);
        permitInternal(IErc20Permit(address(hifiPool.underlying())), underlyingOffered, deadline, signatureUnderlying);
        depositCollateralAndBorrowHTokenAndAddLiquidity(
            balanceSheet,
            collateral,
            hifiPool,
            depositAmount,
            maxBorrowAmount,
            underlyingOffered
        );
    }

    /// @inheritdoc IHifiProxyTarget
    function depositCollateralAndBorrowHTokenAndSellHTokenWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external override {
        permitInternal(collateral, depositAmount, deadline, signatureCollateral);
        depositCollateralAndBorrowHTokenAndSellHToken(
            balanceSheet,
            collateral,
            hifiPool,
            depositAmount,
            borrowAmount,
            minUnderlyingOut
        );
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlyingWithSignature(
        IHToken hToken,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hToken.underlying())), underlyingAmount, deadline, signatureUnderlying);
        depositUnderlying(hToken, underlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlyingAndBorrowHTokenAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        uint256 totalUnderlyingAmount = depositAmount + underlyingOffered;
        permitInternal(
            IErc20Permit(address(hifiPool.underlying())),
            totalUnderlyingAmount,
            deadline,
            signatureUnderlying
        );

        depositUnderlyingAndBorrowHTokenAndAddLiquidity(hifiPool, depositAmount, underlyingOffered);
    }

    /// @inheritdoc IHifiProxyTarget
    function depositUnderlyingAndRepayBorrowWithSignature(
        IHToken hToken,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hToken.underlying())), underlyingAmount, deadline, signatureUnderlying);
        depositUnderlyingAndRepayBorrow(hToken, balanceSheet, underlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function redeem(
        IHToken hToken,
        uint256 hTokenAmount,
        uint256 underlyingAmount
    ) public override {
        // Transfer the hTokens to the DSProxy.
        hToken.transferFrom(msg.sender, address(this), hTokenAmount);

        // Redeem the underlying.
        IErc20 underlying = hToken.underlying();
        hToken.redeem(underlyingAmount);

        // The underlying is now in the DSProxy, so we relay it to the end user.
        underlying.safeTransfer(msg.sender, underlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function redeemWithSignature(
        IHToken hToken,
        uint256 hTokenAmount,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureHToken
    ) external override {
        permitInternal(hToken, hTokenAmount, deadline, signatureHToken);
        redeem(hToken, hTokenAmount, underlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidity(IHifiPool hifiPool, uint256 poolTokensBurned) public override {
        // Transfer the LP tokens to the DSProxy.
        hifiPool.transferFrom(msg.sender, address(this), poolTokensBurned);

        // Burn the LP tokens.
        (uint256 underlyingReturned, uint256 hTokenReturned) = hifiPool.burn(poolTokensBurned);

        // The underlying and the hTokens are now in the DSProxy, so we relay them to the end user.
        hifiPool.underlying().safeTransfer(msg.sender, underlyingReturned);
        hifiPool.hToken().transfer(msg.sender, hTokenReturned);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndRedeem(IHifiPool hifiPool, uint256 poolTokensBurned) public override {
        // Transfer the LP tokens to the DSProxy.
        hifiPool.transferFrom(msg.sender, address(this), poolTokensBurned);

        // Burn the LP tokens.
        (uint256 underlyingReturned, uint256 hTokenReturned) = hifiPool.burn(poolTokensBurned);

        // Calculate how much underlying will be redeemed,
        uint256 underlyingRedeemed = normalize(hTokenReturned, hifiPool.underlyingPrecisionScalar());

        // Redeem the underlying.
        IHToken hToken = hifiPool.hToken();
        hToken.redeem(hTokenReturned);

        // Relay all the underlying it to the end user.
        uint256 totalUnderlyingAmount = underlyingReturned + underlyingRedeemed;
        hToken.underlying().safeTransfer(msg.sender, totalUnderlyingAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndRepayBorrowAndWithdrawCollateral(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 poolTokensBurned,
        uint256 repayAmount,
        uint256 withdrawAmount
    ) public override {
        // Transfer the LP tokens to the DSProxy.
        hifiPool.transferFrom(msg.sender, address(this), poolTokensBurned);

        // Burn the LP tokens.
        (uint256 underlyingReturned, uint256 hTokenReturned) = hifiPool.burn(poolTokensBurned);

        // Repay the borrow.
        IHToken hToken = hifiPool.hToken();
        balanceSheet.repayBorrow(hToken, repayAmount);

        // Relay any remaining hTokens to the end user.
        if (hTokenReturned > repayAmount) {
            unchecked {
                uint256 hTokenDelta = hTokenReturned - repayAmount;
                hToken.transfer(msg.sender, hTokenDelta);
            }
        }

        // Withdraw the collateral and relay the underlying to the end user.
        IErc20 underlying = hifiPool.underlying();
        if (collateral == underlying) {
            balanceSheet.withdrawCollateral(collateral, withdrawAmount);
            uint256 totalUnderlyingAmount = underlyingReturned + withdrawAmount;
            underlying.safeTransfer(msg.sender, totalUnderlyingAmount);
        } else {
            withdrawCollateral(balanceSheet, collateral, withdrawAmount);
            underlying.safeTransfer(msg.sender, underlyingReturned);
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndSellHToken(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 minUnderlyingOut
    ) public override {
        // Transfer the LP tokens to the DSProxy.
        hifiPool.transferFrom(msg.sender, address(this), poolTokensBurned);

        // Burn the LP tokens.
        (uint256 underlyingReturned, uint256 hTokenReturned) = hifiPool.burn(poolTokensBurned);

        // The underlying is now in the DSProxy, so we relay it to the end user.
        hifiPool.underlying().safeTransfer(msg.sender, underlyingReturned);

        // Ensure that we are within the user's slippage tolerance.
        uint256 underlyingOut = hifiPool.getQuoteForSellingHToken(hTokenReturned);
        if (underlyingOut < minUnderlyingOut) {
            revert HifiProxyTarget__TradeSlippage(minUnderlyingOut, underlyingOut);
        }

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hifiPool.hToken(), address(hifiPool), hTokenReturned);

        // Sell the hTokens and relay the underlying to the end user.
        hifiPool.sellHToken(msg.sender, hTokenReturned);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external override {
        permitInternal(hifiPool, poolTokensBurned, deadline, signatureLPToken);
        removeLiquidity(hifiPool, poolTokensBurned);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndRedeemWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external override {
        permitInternal(hifiPool, poolTokensBurned, deadline, signatureLPToken);
        removeLiquidityAndRedeem(hifiPool, poolTokensBurned);
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndRepayBorrowAndWithdrawCollateralWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 poolTokensBurned,
        uint256 repayAmount,
        uint256 withdrawAmount,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external override {
        permitInternal(hifiPool, poolTokensBurned, deadline, signatureLPToken);
        removeLiquidityAndRepayBorrowAndWithdrawCollateral(
            hifiPool,
            balanceSheet,
            collateral,
            poolTokensBurned,
            repayAmount,
            withdrawAmount
        );
    }

    /// @inheritdoc IHifiProxyTarget
    function removeLiquidityAndSellHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external override {
        permitInternal(hifiPool, poolTokensBurned, deadline, signatureLPToken);
        removeLiquidityAndSellHToken(hifiPool, poolTokensBurned, minUnderlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function repayBorrow(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 repayAmount
    ) public override {
        // Transfer the hTokens to the DSProxy.
        hToken.transferFrom(msg.sender, address(this), repayAmount);

        // Repay the borrow.
        balanceSheet.repayBorrow(hToken, repayAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function repayBorrowWithSignature(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 repayAmount,
        uint256 deadline,
        bytes memory signatureHToken
    ) external override {
        permitInternal(hToken, repayAmount, deadline, signatureHToken);
        repayBorrow(balanceSheet, hToken, repayAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function sellHToken(
        IHifiPool hifiPool,
        uint256 hTokenIn,
        uint256 minUnderlyingOut
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 underlyingOut = hifiPool.getQuoteForSellingHToken(hTokenIn);
        if (underlyingOut < minUnderlyingOut) {
            revert HifiProxyTarget__TradeSlippage(minUnderlyingOut, underlyingOut);
        }

        // Transfer the hTokens to the DSProxy.
        IHToken hToken = hifiPool.hToken();
        hToken.transferFrom(msg.sender, address(this), hTokenIn);

        // Allow the HifiPool contract to spend hTokens from the DSProxy.
        approveSpender(hToken, address(hifiPool), hTokenIn);

        // Sell the hTokens and relay the underlying to the end user.
        hifiPool.sellHToken(msg.sender, hTokenIn);
    }

    /// @inheritdoc IHifiProxyTarget
    function sellHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenIn,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureHToken
    ) external override {
        // Transfer the hTokens to the DSProxy.
        IHToken hToken = hifiPool.hToken();
        permitInternal(hToken, hTokenIn, deadline, signatureHToken);
        sellHToken(hifiPool, hTokenIn, minUnderlyingOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function sellUnderlying(
        IHifiPool hifiPool,
        uint256 underlyingIn,
        uint256 minHTokenOut
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 hTokenOut = hifiPool.getQuoteForSellingUnderlying(underlyingIn);
        if (hTokenOut < minHTokenOut) {
            revert HifiProxyTarget__TradeSlippage(minHTokenOut, hTokenOut);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.transferFrom(msg.sender, address(this), underlyingIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingIn);

        // Sell the underlying and relay the hTokens to the end user.
        hifiPool.sellUnderlying(msg.sender, underlyingIn);
    }

    /// @inheritdoc IHifiProxyTarget
    function sellUnderlyingAndRepayBorrow(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingIn,
        uint256 minHTokenOut
    ) public override {
        // Ensure that we are within the user's slippage tolerance.
        uint256 hTokenOut = hifiPool.getQuoteForSellingUnderlying(underlyingIn);
        if (hTokenOut < minHTokenOut) {
            revert HifiProxyTarget__TradeSlippage(minHTokenOut, hTokenOut);
        }

        // Transfer the underlying to the DSProxy.
        IErc20 underlying = hifiPool.underlying();
        underlying.transferFrom(msg.sender, address(this), underlyingIn);

        // Allow the HifiPool contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hifiPool), underlyingIn);

        // Sell the underlying.
        hifiPool.sellUnderlying(address(this), underlyingIn);

        // Query the amount of debt that the user owes.
        IHToken hToken = hifiPool.hToken();
        uint256 debtAmount = balanceSheet.getDebtAmount(address(this), hToken);

        // Repay the borrow.
        if (debtAmount >= hTokenOut) {
            balanceSheet.repayBorrow(hToken, hTokenOut);
        } else {
            balanceSheet.repayBorrow(hToken, debtAmount);

            // Relay any remaining hTokens to the end user.
            unchecked {
                uint256 hTokenDelta = hTokenOut - debtAmount;
                hToken.transfer(msg.sender, hTokenDelta);
            }
        }
    }

    /// @inheritdoc IHifiProxyTarget
    function sellUnderlyingWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingIn,
        uint256 minHTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), underlyingIn, deadline, signatureUnderlying);
        sellUnderlying(hifiPool, underlyingIn, minHTokenOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function sellUnderlyingAndRepayBorrowWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingIn,
        uint256 minHTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external override {
        permitInternal(IErc20Permit(address(hifiPool.underlying())), underlyingIn, deadline, signatureUnderlying);
        sellUnderlyingAndRepayBorrow(hifiPool, balanceSheet, underlyingIn, minHTokenOut);
    }

    /// @inheritdoc IHifiProxyTarget
    function withdrawCollateral(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 withdrawAmount
    ) public override {
        balanceSheet.withdrawCollateral(collateral, withdrawAmount);

        // The collateral is now in the DSProxy, so we relay it to the end user.
        collateral.safeTransfer(msg.sender, withdrawAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function wrapEthAndDepositCollateral(WethInterface weth, IBalanceSheetV2 balanceSheet) public payable override {
        uint256 depositAmount = msg.value;

        // Convert the received ETH to WETH.
        weth.deposit{ value: depositAmount }();

        // Deposit the collateral into the BalanceSheet contract.
        depositCollateralInternal(balanceSheet, IErc20(address(weth)), depositAmount);
    }

    /// @inheritdoc IHifiProxyTarget
    function wrapEthAndDepositAndBorrowHTokenAndSellHToken(
        WethInterface weth,
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) external payable override {
        wrapEthAndDepositCollateral(weth, balanceSheet);
        borrowHTokenAndSellHToken(balanceSheet, hifiPool, borrowAmount, minUnderlyingOut);
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @notice Downscales from normalized amount, i.e. 18 decimals of precision.
    /// @param amount The amount with 18 decimals of precision.
    /// @param precisionScalar The ratio between normalized precision and the desired precision.
    /// @param denormalizedAmount The amount with fewer decimals of precision.
    function denormalize(uint256 amount, uint256 precisionScalar) internal pure returns (uint256 denormalizedAmount) {
        unchecked {
            denormalizedAmount = precisionScalar != 1 ? amount / precisionScalar : amount;
        }
    }

    /// @notice Upscales to normalized form, i.e. 18 decimals of precision.
    /// @param amount The amount to normalize.
    /// @param precisionScalar The ratio between normalized precision and the desired precision.
    /// @param normalizedAmount The amount with 18 decimals of precision.
    function normalize(uint256 amount, uint256 precisionScalar) internal pure returns (uint256 normalizedAmount) {
        normalizedAmount = precisionScalar != 1 ? amount * precisionScalar : amount;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function approveSpender(
        IErc20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.approve(spender, type(uint256).max);
        }
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function depositCollateralInternal(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 collateralAmount
    ) internal {
        // Allow the BalanceSheet contract to spend collateral from the DSProxy.
        approveSpender(collateral, address(balanceSheet), collateralAmount);

        // Deposit the collateral into the BalanceSheet contract.
        balanceSheet.depositCollateral(collateral, collateralAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function depositUnderlyingInternal(IHToken hToken, uint256 underlyingAmount) internal {
        //IRedemptionPool redemptionPool = hToken.redemptionPool();
        IErc20 underlying = hToken.underlying();

        // Transfer the underlying to the DSProxy.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Allow the HToken contract to spend underlying from the DSProxy.
        approveSpender(underlying, address(hToken), underlyingAmount);

        // Deposit the underlying in the HToken contract to mint hTokens.
        hToken.depositUnderlying(underlyingAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function getUnderlyingRequired(IHifiPool hifiPool, uint256 hTokenOut)
        internal
        view
        returns (uint256 underlyingRequired)
    {
        // Calculate how much underlying is required to provide "hTokenOut" liquidity to the AMM.
        IHToken hToken = hifiPool.hToken();
        uint256 normalizedUnderlyingReserves = hifiPool.getNormalizedUnderlyingReserves();
        uint256 hTokenReserves = hToken.balanceOf(address(hifiPool));
        uint256 normalizedUnderlyingRequired = (normalizedUnderlyingReserves * hTokenOut) / hTokenReserves;
        underlyingRequired = denormalize(normalizedUnderlyingRequired, hifiPool.underlyingPrecisionScalar());
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function permitInternal(
        IErc20Permit token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) internal {
        if (signature.length > 0) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@hifi/protocol/contracts/core/h-token/IHToken.sol";
import "@prb/contracts/token/erc20/IErc20.sol";
import "@prb/contracts/token/erc20/IErc20Permit.sol";

/// @title IHifiPool
/// @author Hifi
interface IHifiPool is IErc20Permit {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the bond matured.
    error HifiPool__BondMatured();

    /// @notice Emitted when attempting to buy a zero amount of hTokens.
    error HifiPool__BuyHTokenZero();

    /// @notice Emitted when attempting to buy hTokens with a zero amount of underlying.
    error HifiPool__BuyHTokenUnderlyingZero();

    /// @notice Emitted when attempting to buy a zero amount of underlying.
    error HifiPool__BuyUnderlyingZero();

    /// @notice Emitted when offering zero underlying to mint LP tokens.
    error HifiPool__BurnZero();

    /// @notice Emitted when offering zero underlying to mint LP tokens.
    error HifiPool__MintZero();

    /// @notice Emitted when buying hTokens or selling underlying and the resultant hToken reserves would become
    /// smaller than the underlying reserves.
    error HifiPool__NegativeInterestRate(
        uint256 virtualHTokenReserves,
        uint256 hTokenOut,
        uint256 normalizedUnderlyingReserves,
        uint256 normalizedUnderlyingIn
    );

    /// @notice Emitted when attempting to sell a zero amount of hToken.
    error HifiPool__SellHTokenZero();

    /// @notice Emitted when attempting to sell hTokens in exchange for a zero amount of underlying.
    error HifiPool__SellHTokenUnderlyingZero();

    /// @notice Emitted when attempting to sell a zero amount of underlying.
    error HifiPool__SellUnderlyingZero();

    /// @notice Emitted when trying to convert a uint256 number that doesn't fit within int256.
    error HifiPool__ToInt256CastOverflow(uint256 number);

    /// @notice Emitted when the hToken balance added to the total supply of LP tokens overflows uint256.
    error HifiPool__VirtualHTokenReservesOverflow(uint256 hTokenBalance, uint256 totalSupply);

    /// EVENTS ///

    /// @notice Emitted when liquidity is added to the AMM.
    /// @param maturity The maturity of the hToken.
    /// @param provider The address of the liquidity provider.
    /// @param underlyingAmount The amount of underlying provided.
    /// @param hTokenAmount The amount of hTokens provided.
    /// @param poolTokenAmount The amount of pool tokens minted.
    event AddLiquidity(
        uint256 maturity,
        address indexed provider,
        uint256 underlyingAmount,
        uint256 hTokenAmount,
        uint256 poolTokenAmount
    );

    /// @notice Emitted when liquidity is removed from the AMM.
    /// @param maturity The maturity of the hToken.
    /// @param provider The address of the liquidity withdrawn.
    /// @param underlyingAmount The amount of underlying withdrawn.
    /// @param hTokenAmount The amount of hTokens provided.
    /// @param poolTokenAmount The amount of pool tokens burned.
    event RemoveLiquidity(
        uint256 maturity,
        address indexed provider,
        uint256 underlyingAmount,
        uint256 hTokenAmount,
        uint256 poolTokenAmount
    );

    /// @notice Emitted when a trade is made in the AMM.
    /// @param maturity The maturity of the hToken.
    /// @param from The account sending the tokens to the AMM.
    /// @param to The account receiving the tokens from the AMM.
    /// @param underlyingAmount The amount of underlying bought or sold.
    /// @param hTokenAmount The amount of hTokens bought or sold.
    event Trade(
        uint256 maturity,
        address indexed from,
        address indexed to,
        int256 underlyingAmount,
        int256 hTokenAmount
    );

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Quotes how much underlying would be required to buy `hTokenOut` hToken.
    ///
    /// @dev Requirements:
    /// - Cannot be called after maturity.
    ///
    /// @param hTokenOut The hypothetical amount of hTokens to sell.
    /// @return underlyingIn The hypothetical amount of underlying required.
    function getQuoteForBuyingHToken(uint256 hTokenOut) external view returns (uint256 underlyingIn);

    /// @notice Quotes how many hTokens would be required to buy `underlyingOut` underlying.
    ///
    /// @dev Requirements:
    /// - Cannot be called after maturity.
    ///
    /// @param underlyingOut The hypothetical amount of underlying desired.
    /// @return hTokenIn The hypothetical amount of hTokens required.
    function getQuoteForBuyingUnderlying(uint256 underlyingOut) external view returns (uint256 hTokenIn);

    /// @notice Calculates how many hTokens would be required and how many LP tokens would be issued for a given
    /// amount of underlying invested.
    /// @param underlyingOffered The amount of underlying tokens invested.
    /// @return hTokenRequired The hypothetical amount of hTokens required to mint new LP tokens.
    /// @return poolTokensMinted The amount of LP tokens to mint.
    function getMintInputs(uint256 underlyingOffered)
        external
        view
        returns (uint256 hTokenRequired, uint256 poolTokensMinted);

    /// @notice Calculates how much underlying and hToken would be returned for a given amount of LP tokens.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @return underlyingReturned The amount of reserve underlying retrieved.
    /// @return hTokenReturned The amount of reserve hToken retrieved.
    function getBurnOutputs(uint256 poolTokensBurned)
        external
        view
        returns (uint256 underlyingReturned, uint256 hTokenReturned);

    /// @notice Quotes how much underlying would be obtained by selling `hTokenIn` hToken.
    ///
    /// @dev Requirements:
    /// - Cannot be called after maturity.
    ///
    /// @param hTokenIn The hypothetical amount of hTokens to sell.
    /// @return underlyingOut The hypothetical amount of underlying that would be obtained.
    function getQuoteForSellingHToken(uint256 hTokenIn) external view returns (uint256 underlyingOut);

    /// @notice Quotes how many hTokens would be obtained by selling `underlyingIn` underlying.
    ///
    /// @dev Requirements:
    /// - Cannot be called after maturity.
    ///
    /// @param underlyingIn The hypothetical amount of underlying to sell.
    /// @return hTokenOut The hypothetical amount of hTokens that would be obtained.
    function getQuoteForSellingUnderlying(uint256 underlyingIn) external view returns (uint256 hTokenOut);

    /// @notice Returns the normalized underlying reserves, i.e. the Erc20 balance scaled to have 18 decimals.
    function getNormalizedUnderlyingReserves() external view returns (uint256 normalizedUnderlyingReserves);

    /// @notice Returns the virtual hToken reserves, as explained in the whitepaper.
    /// @dev Adds the Erc20 hToken balance to the total supply of LP tokens.
    function getVirtualHTokenReserves() external view returns (uint256 virtualHTokenReserves);

    /// @notice The unix timestamp at which the hToken expires.
    function maturity() external view returns (uint256);

    /// @notice The hToken traded in this pool.
    function hToken() external view returns (IHToken);

    /// @notice The underlying token traded in this pool.
    function underlying() external view returns (IErc20);

    /// @notice The ratio between our native precision (18) and the underlying precision.
    function underlyingPrecisionScalar() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Burns LP tokens in exchange for underlying tokens and hTokens.
    ///
    /// @dev Emits a {RemoveLiquidity} event.
    ///
    /// Requirements:
    /// - The amount to burn cannot be zero.
    ///
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @return underlyingReturned The amount of reserve underlying retrieved.
    /// @return hTokenReturned The amount of reserve hToken retrieved.
    function burn(uint256 poolTokensBurned) external returns (uint256 underlyingReturned, uint256 hTokenReturned);

    /// @notice Buys hToken with underlying.
    ///
    /// @dev Emits a {Trade} event.
    ///
    /// Requirements:
    /// - All from "getQuoteForBuyingHToken".
    /// - The caller must have allowed this contract to spend `underlyingIn` tokens.
    /// - The caller must have at least `underlyingIn` in their account.
    ///
    /// @param to The account that receives the hToken being bought.
    /// @param hTokenOut The amount of hTokens being bought that will be transferred to the `to` account.
    /// @return underlyingIn The amount of underlying that will be taken from the caller's account.
    function buyHToken(address to, uint256 hTokenOut) external returns (uint256 underlyingIn);

    /// @notice Buys underlying with hToken.
    ///
    /// Requirements:
    /// - All from "getQuoteForBuyingUnderlying".
    /// - The caller must have allowed this contract to spend `hTokenIn` tokens.
    /// - The caller must have at least `hTokenIn` in their account.
    ///
    /// @param to The account that receives the underlying being bought.
    /// @param underlyingOut The amount of underlying being bought that will be transferred to the `to` account.
    /// @return hTokenIn The amount of hTokens that will be taken from the caller's account.
    function buyUnderlying(address to, uint256 underlyingOut) external returns (uint256 hTokenIn);

    /// @notice Mints LP tokens in exchange for adding underlying tokens and hTokens. An appropriate amount of
    /// hTokens gets calculated and taken from the caller to be investigated alongside underlying tokens.
    ///
    /// @dev Emits an {AddLiquidity} event.
    ///
    /// Requirements:
    /// - The caller must have allowed this contract to spend `underlyingOffered` and `hTokenRequired` tokens.
    ///
    /// @param underlyingOffered The amount of underlying tokens invested.
    /// @return poolTokensMinted The amount of LP tokens to mint.
    function mint(uint256 underlyingOffered) external returns (uint256 poolTokensMinted);

    /// @notice Sells hToken for underlying.
    ///
    /// @dev Emits a {Trade} event.
    ///
    /// Requirements:
    /// - All from "getQuoteForSellingHToken".
    /// - The caller must have allowed this contract to spend `hTokenIn` tokens.
    /// - The caller must have at least `hTokenIn` in their account.
    ///
    /// @param to The account that receives the underlying being bought.
    /// @param hTokenIn The amount of underlying being sold that is taken from the caller's account.
    /// @return underlyingOut The amount of underlying that will be transferred to the `to` account.
    function sellHToken(address to, uint256 hTokenIn) external returns (uint256 underlyingOut);

    /// @notice Sells underlying for hToken.
    ///
    /// @dev Emits a {Trade} event.
    ///
    /// Requirements:
    /// - All from "getQuoteForSellingUnderlying".
    /// - The caller must have allowed this contract to spend `underlyingIn` tokens.
    /// - The caller must have at least `underlyingIn` in their account.
    ///
    /// @param to The account that receives the hToken being bought.
    /// @param underlyingIn The amount of underlying being sold that is taken from the caller's account.
    /// @return hTokenOut The amount of hTokenOut that will be transferred to the `to` account.
    function sellUnderlying(address to, uint256 underlyingIn) external returns (uint256 hTokenOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@prb/contracts/token/erc20/IErc20.sol";

import "../fintroller/IFintroller.sol";
import "../h-token/IHToken.sol";
import "../../access/IOwnableUpgradeable.sol";
import "../../oracles/IChainlinkOperator.sol";

/// @title IBalanceSheetV2
/// @author Hifi
/// @notice Manages the collaterals and the debts for all users.
interface IBalanceSheetV2 is IOwnableUpgradeable {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the bond matured.
    error BalanceSheet__BondMatured(IHToken bond);

    /// @notice Emitted when the account exceeds the maximum numbers of bonds permitted.
    error BalanceSheet__BorrowMaxBonds(IHToken bond, uint256 newBondListLength, uint256 maxBonds);

    /// @notice Emitted when borrows are not allowed by the Fintroller contract.
    error BalanceSheet__BorrowNotAllowed(IHToken bond);

    /// @notice Emitted when borrowing a zero amount of hTokens.
    error BalanceSheet__BorrowZero();

    /// @notice Emitted when the new collateral amount exceeds the collateral ceiling.
    error BalanceSheet__CollateralCeilingOverflow(uint256 newTotalSupply, uint256 debtCeiling);

    /// @notice Emitted when the new total amount of debt exceeds the debt ceiling.
    error BalanceSheet__DebtCeilingOverflow(uint256 newCollateralAmount, uint256 debtCeiling);

    /// @notice Emitted when collateral deposits are not allowed by the Fintroller contract.
    error BalanceSheet__DepositCollateralNotAllowed(IErc20 collateral);

    /// @notice Emitted when depositing a zero amount of collateral.
    error BalanceSheet__DepositCollateralZero();

    /// @notice Emitted when setting the Fintroller contract to the zero address.
    error BalanceSheet__FintrollerZeroAddress();

    /// @notice Emitted when there is not enough collateral to seize.
    error BalanceSheet__LiquidateBorrowInsufficientCollateral(
        address account,
        uint256 vaultCollateralAmount,
        uint256 seizableAmount
    );

    /// @notice Emitted when borrow liquidations are not allowed by the Fintroller contract.
    error BalanceSheet__LiquidateBorrowNotAllowed(IHToken bond);

    /// @notice Emitted when the borrower is liquidating themselves.
    error BalanceSheet__LiquidateBorrowSelf(address account);

    /// @notice Emitted when there is a liquidity shortfall.
    error BalanceSheet__LiquidityShortfall(address account, uint256 shortfallLiquidity);

    /// @notice Emitted when there is no liquidity shortfall.
    error BalanceSheet__NoLiquidityShortfall(address account);

    /// @notice Emitted when setting the oracle contract to the zero address.
    error BalanceSheet__OracleZeroAddress();

    /// @notice Emitted when the repayer does not have enough hTokens to repay the debt.
    error BalanceSheet__RepayBorrowInsufficientBalance(IHToken bond, uint256 repayAmount, uint256 hTokenBalance);

    /// @notice Emitted when repaying more debt than the borrower owes.
    error BalanceSheet__RepayBorrowInsufficientDebt(IHToken bond, uint256 repayAmount, uint256 debtAmount);

    /// @notice Emitted when borrow repays are not allowed by the Fintroller contract.
    error BalanceSheet__RepayBorrowNotAllowed(IHToken bond);

    /// @notice Emitted when repaying a borrow with a zero amount of hTokens.
    error BalanceSheet__RepayBorrowZero();

    /// @notice Emitted when withdrawing more collateral than there is in the vault.
    error BalanceSheet__WithdrawCollateralUnderflow(
        address account,
        uint256 vaultCollateralAmount,
        uint256 withdrawAmount
    );

    /// @notice Emitted when withdrawing a zero amount of collateral.
    error BalanceSheet__WithdrawCollateralZero();

    /// EVENTS ///

    /// @notice Emitted when a borrow is made.
    /// @param account The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param borrowAmount The amount of hTokens borrowed.
    event Borrow(address indexed account, IHToken indexed bond, uint256 borrowAmount);

    /// @notice Emitted when collateral is deposited.
    /// @param account The address of the borrower.
    /// @param collateral The related collateral.
    /// @param collateralAmount The amount of deposited collateral.
    event DepositCollateral(address indexed account, IErc20 indexed collateral, uint256 collateralAmount);

    /// @notice Emitted when a borrow is liquidated.
    /// @param liquidator The address of the liquidator.
    /// @param borrower The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of repaid funds.
    /// @param collateral The address of the collateral contract.
    /// @param seizedCollateralAmount The amount of seized collateral.
    event LiquidateBorrow(
        address indexed liquidator,
        address indexed borrower,
        IHToken indexed bond,
        uint256 repayAmount,
        IErc20 collateral,
        uint256 seizedCollateralAmount
    );

    /// @notice Emitted when a borrow is repaid.
    /// @param payer The address of the payer.
    /// @param borrower The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of repaid funds.
    /// @param newDebtAmount The amount of the new debt.
    event RepayBorrow(
        address indexed payer,
        address indexed borrower,
        IHToken indexed bond,
        uint256 repayAmount,
        uint256 newDebtAmount
    );

    /// @notice Emitted when a new Fintroller contract is set.
    /// @param owner The address of the owner.
    /// @param oldFintroller The address of the old Fintroller contract.
    /// @param newFintroller The address of the new Fintroller contract.
    event SetFintroller(address indexed owner, address oldFintroller, address newFintroller);

    /// @notice Emitted when a new oracle contract is set.
    /// @param owner The address of the owner.
    /// @param oldOracle The address of the old oracle contract.
    /// @param newOracle The address of the new oracle contract.
    event SetOracle(address indexed owner, address oldOracle, address newOracle);

    /// @notice Emitted when collateral is withdrawn.
    /// @param account The address of the borrower.
    /// @param collateral The related collateral.
    /// @param collateralAmount The amount of withdrawn collateral.
    event WithdrawCollateral(address indexed account, IErc20 indexed collateral, uint256 collateralAmount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the list of bond markets the given account entered.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    function getBondList(address account) external view returns (IHToken[] memory);

    /// @notice Returns the amount of collateral deposited by the given account for the given collateral type.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    /// @param collateral The collateral to make the query against.
    function getCollateralAmount(address account, IErc20 collateral) external view returns (uint256 collateralAmount);

    /// @notice Returns the list of collaterals the given account deposited.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    function getCollateralList(address account) external view returns (IErc20[] memory);

    /// @notice Calculates the current account liquidity.
    /// @param account The account to make the query against.
    /// @return excessLiquidity account liquidity in excess of collateral requirements.
    /// @return shortfallLiquidity account shortfall below collateral requirements
    function getCurrentAccountLiquidity(address account)
        external
        view
        returns (uint256 excessLiquidity, uint256 shortfallLiquidity);

    /// @notice Returns the amount of debt accrued by the given account in the given bond market.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    /// @param bond The bond to make the query against.
    function getDebtAmount(address account, IHToken bond) external view returns (uint256 debtAmount);

    /// @notice Calculates the account liquidity given a modified collateral, collateral amount, bond and debt amount,
    /// using the current prices provided by the oracle.
    ///
    /// @dev Works by summing up each collateral amount multiplied by the USD value of each unit and divided by its
    /// respective collateral ratio, then dividing the sum by the total amount of debt drawn by the user.
    ///
    /// Caveats:
    /// - This function expects that the "collateralList" and the "bondList" are each modified in advance to include
    /// the collateral and bond due to be modified.
    ///
    /// @param account The account to make the query against.
    /// @param collateralModify The collateral to make the check against.
    /// @param collateralAmountModify The hypothetical normalized amount of collateral.
    /// @param bondModify The bond to make the check against.
    /// @param debtAmountModify The hypothetical amount of debt.
    /// @return excessLiquidity hypothetical account liquidity in excess of collateral requirements.
    /// @return shortfallLiquidity hypothetical account shortfall below collateral requirements
    function getHypotheticalAccountLiquidity(
        address account,
        IErc20 collateralModify,
        uint256 collateralAmountModify,
        IHToken bondModify,
        uint256 debtAmountModify
    ) external view returns (uint256 excessLiquidity, uint256 shortfallLiquidity);

    /// @notice Calculates the amount of hTokens that should be repaid in order to seize a given amount of collateral.
    /// Note that this is for informational purposes only, it doesn't say anything about whether the user can be
    /// liquidated.
    /// @dev The formula used is:
    /// repayAmount = (seizableCollateralAmount * collateralPriceUsd) / (liquidationIncentive * underlyingPriceUsd)
    /// @param collateral The collateral to make the query against.
    /// @param seizableCollateralAmount The amount of collateral to seize.
    /// @param bond The bond to make the query against.
    /// @return repayAmount The amount of hTokens that should be repaid.
    function getRepayAmount(
        IErc20 collateral,
        uint256 seizableCollateralAmount,
        IHToken bond
    ) external view returns (uint256 repayAmount);

    /// @notice Calculates the amount of collateral that can be seized when liquidating a borrow. Note that this
    /// is for informational purposes only, it doesn't say anything about whether the user can be liquidated.
    /// @dev The formula used is:
    /// seizableCollateralAmount = repayAmount * liquidationIncentive * underlyingPriceUsd / collateralPriceUsd
    /// @param bond The bond to make the query against.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param collateral The collateral to make the query against.
    /// @return seizableCollateralAmount The amount of seizable collateral.
    function getSeizableCollateralAmount(
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) external view returns (uint256 seizableCollateralAmount);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Increases the debt of the caller and mints new hTokens.
    ///
    /// @dev Emits a {Borrow} event.
    ///
    /// Requirements:
    ///
    /// - The Fintroller must allow this action to be performed.
    /// - The maturity of the bond must be in the future.
    /// - The amount to borrow cannot be zero.
    /// - The new length of the bond list must be below the max bonds limit.
    /// - The new total amount of debt cannot exceed the debt ceiling.
    /// - The caller must not end up having a shortfall of liquidity.
    ///
    /// @param bond The address of the bond contract.
    /// @param borrowAmount The amount of hTokens to borrow and print into existence.
    function borrow(IHToken bond, uint256 borrowAmount) external;

    /// @notice Deposits collateral in the caller's account.
    ///
    /// @dev Emits a {DepositCollateral} event.
    ///
    /// Requirements:
    ///
    /// - The Fintroller must allow this action to be performed.
    /// - The amount to deposit cannot be zero.
    /// - The caller must have allowed this contract to spend `collateralAmount` tokens.
    /// - The new collateral amount cannot exceed the collateral ceiling.
    ///
    /// @param collateral The address of the collateral contract.
    /// @param depositAmount The amount of collateral to deposit.
    function depositCollateral(IErc20 collateral, uint256 depositAmount) external;

    /// @notice Repays the debt of the borrower and rewards the caller with a surplus of collateral.
    ///
    /// @dev Emits a {LiquidateBorrow} event.
    ///
    /// Requirements:
    ///
    /// - All from "repayBorrow".
    /// - The caller cannot be the same with the borrower.
    /// - The Fintroller must allow this action to be performed.
    /// - The borrower must have a shortfall of liquidity if the bond didn't mature.
    /// - The amount of seized collateral cannot be more than what the borrower has in the vault.
    ///
    /// @param bond The address of the bond contract.
    /// @param borrower The account to liquidate.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param collateral The address of the collateral contract.
    function liquidateBorrow(
        address borrower,
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) external;

    /// @notice Erases the borrower's debt and takes the hTokens out of circulation.
    ///
    /// @dev Emits a {RepayBorrow} event.
    ///
    /// Requirements:
    ///
    /// - The amount to repay cannot be zero.
    /// - The Fintroller must allow this action to be performed.
    /// - The caller must have at least `repayAmount` hTokens.
    /// - The caller must have at least `repayAmount` debt.
    ///
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of hTokens to repay.
    function repayBorrow(IHToken bond, uint256 repayAmount) external;

    /// @notice Erases the borrower's debt and takes the hTokens out of circulation.
    ///
    /// @dev Emits a {RepayBorrow} event.
    ///
    /// Requirements:
    /// - Same as the `repayBorrow` function, but here `borrower` is the account that must have at least
    /// `repayAmount` hTokens to repay the borrow.
    ///
    /// @param borrower The borrower account for which to repay the borrow.
    /// @param bond The address of the bond contract
    /// @param repayAmount The amount of hTokens to repay.
    function repayBorrowBehalf(
        address borrower,
        IHToken bond,
        uint256 repayAmount
    ) external;

    /// @notice Updates the Fintroller contract this BalanceSheet is connected to.
    ///
    /// @dev Emits a {SetFintroller} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The new address cannot be the zero address.
    ///
    /// @param newFintroller The new Fintroller contract.
    function setFintroller(IFintroller newFintroller) external;

    /// @notice Updates the oracle contract.
    ///
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The new address cannot be the zero address.
    ///
    /// @param newOracle The new oracle contract.
    function setOracle(IChainlinkOperator newOracle) external;

    /// @notice Withdraws a portion or all of the collateral.
    ///
    /// @dev Emits a {WithdrawCollateral} event.
    ///
    /// Requirements:
    ///
    /// - The amount to withdraw cannot be zero.
    /// - There must be enough collateral in the vault.
    /// - The caller's account cannot fall below the collateral ratio.
    ///
    /// @param collateral The address of the collateral contract.
    /// @param withdrawAmount The amount of collateral to withdraw.
    function withdrawCollateral(IErc20 collateral, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@prb/contracts/access/IOwnable.sol";
import "@prb/contracts/token/erc20/IErc20.sol";
import "@prb/contracts/token/erc20/IErc20Permit.sol";
import "@prb/contracts/token/erc20/IErc20Recover.sol";

import "../balance-sheet/IBalanceSheetV2.sol";
import "../fintroller/IFintroller.sol";

/// @title IHToken
/// @author Hifi
/// @notice Zero-coupon bond that tracks an Erc20 underlying asset.
interface IHToken is
    IOwnable, // no dependency
    IErc20Permit, // one dependency
    IErc20Recover // one dependency
{
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the bond matured.
    error HToken__BondMatured(uint256 now, uint256 maturity);

    /// @notice Emitted when the bond did not mature.
    error HToken__BondNotMatured(uint256 now, uint256 maturity);

    /// @notice Emitted when burning hTokens and the caller is not the BalanceSheet contract.
    error HToken__BurnNotAuthorized(address caller);

    /// @notice Emitted when underlying deposits are not allowed by the Fintroller contract.
    error HToken__DepositUnderlyingNotAllowed();

    /// @notice Emitted when depositing a zero amount of underlying.
    error HToken__DepositUnderlyingZero();

    /// @notice Emitted when the maturity is in the past.
    error HToken__MaturityPassed(uint256 now, uint256 maturity);

    /// @notice Emitted when minting hTokens and the caller is not the BalanceSheet contract.
    error HToken__MintNotAuthorized(address caller);

    /// @notice Emitted when redeeming more underlying that there is in the reserve.
    error HToken__RedeemInsufficientLiquidity(uint256 underlyingAmount, uint256 totalUnderlyingReserve);

    /// @notice Emitted when redeeming a zero amount of underlying.
    error HToken__RedeemZero();

    /// @notice Emitted when constructing the contract and the underlying has more than 18 decimals.
    error HToken__UnderlyingDecimalsOverflow(uint256 decimals);

    /// @notice Emitted when constructing the contract and the underlying has zero decimals.
    error HToken__UnderlyingDecimalsZero();

    /// @notice Emitted when withdrawing more underlying than there is available.
    error HToken__WithdrawUnderlyingUnderflow(address depositor, uint256 availableAmount, uint256 underlyingAmount);

    /// @notice Emitted when withdrawing a zero amount of underlying.
    error HToken__WithdrawUnderlyingZero();

    /// EVENTS ///

    /// @notice Emitted when tokens are burnt.
    /// @param holder The address of the holder.
    /// @param burnAmount The amount of burnt tokens.
    event Burn(address indexed holder, uint256 burnAmount);

    /// @notice Emitted when underlying is deposited in exchange for an equivalent amount of hTokens.
    /// @param depositor The address of the depositor.
    /// @param depositUnderlyingAmount The amount of deposited underlying.
    /// @param hTokenAmount The amount of minted hTokens.
    event DepositUnderlying(address indexed depositor, uint256 depositUnderlyingAmount, uint256 hTokenAmount);

    /// @notice Emitted when tokens are minted.
    /// @param beneficiary The address of the holder.
    /// @param mintAmount The amount of minted tokens.
    event Mint(address indexed beneficiary, uint256 mintAmount);

    /// @notice Emitted when underlying is redeemed.
    /// @param account The account redeeming the underlying.
    /// @param underlyingAmount The amount of redeemed underlying.
    /// @param hTokenAmount The amount of provided hTokens.
    event Redeem(address indexed account, uint256 underlyingAmount, uint256 hTokenAmount);

    /// @notice Emitted when the BalanceSheet is set.
    /// @param owner The address of the owner.
    /// @param oldBalanceSheet The address of the old BalanceSheet.
    /// @param newBalanceSheet The address of the new BalanceSheet.
    event SetBalanceSheet(address indexed owner, IBalanceSheetV2 oldBalanceSheet, IBalanceSheetV2 newBalanceSheet);

    /// @notice Emitted when a depositor withdraws previously deposited underlying.
    /// @param depositor The address of the depositor.
    /// @param underlyingAmount The amount of withdrawn underlying.
    /// @param hTokenAmount The amount of minted hTokens.
    event WithdrawUnderlying(address indexed depositor, uint256 underlyingAmount, uint256 hTokenAmount);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Returns the BalanceSheet contract this HToken is connected to.
    function balanceSheet() external view returns (IBalanceSheetV2);

    /// @notice Returns the balance of the given depositor.
    function getDepositorBalance(address depositor) external view returns (uint256 amount);

    /// @notice Returns the Fintroller contract this HToken is connected to.
    function fintroller() external view returns (IFintroller);

    /// @notice Checks if the bond matured.
    /// @return bool true = bond matured, otherwise it didn't.
    function isMatured() external view returns (bool);

    /// @notice Unix timestamp in seconds for when this HToken matures.
    function maturity() external view returns (uint256);

    /// @notice The amount of underlying redeemable after maturation.
    function totalUnderlyingReserve() external view returns (uint256);

    /// @notice The Erc20 underlying asset for this HToken.
    function underlying() external view returns (IErc20);

    /// @notice The ratio between normalized precision (1e18) and the underlying precision.
    function underlyingPrecisionScalar() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    ///
    /// @dev Emits a {Burn} and a {Transfer} event.
    ///
    /// Requirements:
    /// - Can only be called by the BalanceSheet contract.
    ///
    /// @param holder The account whose hTokens to burn.
    /// @param burnAmount The amount of hTokens to burn.
    function burn(address holder, uint256 burnAmount) external;

    /// @notice Deposits underlying in exchange for an equivalent amount of hTokens.
    ///
    /// @dev Emits a {DepositUnderlying} event.
    ///
    /// Requirements:
    ///
    /// - The Fintroller must allow this action to be performed.
    /// - The underlying amount to deposit cannot be zero.
    /// - The caller must have allowed this contract to spend `underlyingAmount` tokens.
    ///
    /// @param underlyingAmount The amount of underlying to deposit.
    function depositUnderlying(uint256 underlyingAmount) external;

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the total supply.
    ///
    /// @dev Emits a {Mint} and a {Transfer} event.
    ///
    /// Requirements:
    /// - Can only be called by the BalanceSheet contract.
    ///
    /// @param beneficiary The account to mint the hTokens for.
    /// @param mintAmount The amount of hTokens to print into existence.
    function mint(address beneficiary, uint256 mintAmount) external;

    /// @notice Pays the token holder the face value after maturation.
    ///
    /// @dev Emits a {Redeem} event.
    ///
    /// Requirements:
    ///
    /// - Can only be called after maturation.
    /// - The amount of underlying to redeem cannot be zero.
    /// - There must be enough liquidity in the contract.
    ///
    /// @param underlyingAmount The amount of underlying to redeem.
    function redeem(uint256 underlyingAmount) external;

    /// @notice Updates the BalanceSheet contract this HToken is connected to.
    ///
    /// @dev Throws a {SetBalanceSheet} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newBalanceSheet The address of the new BalanceSheet contract.
    function _setBalanceSheet(IBalanceSheetV2 newBalanceSheet) external;

    /// @notice Withdraws underlying in exchange for hTokens.
    ///
    /// @dev Emits a {WithdrawUnderlying} event.
    ///
    /// Requirements:
    ///
    /// - The underlying amount to withdraw cannot be zero.
    /// - Can only be called before maturation.
    ///
    /// @param underlyingAmount The amount of underlying to withdraw.
    function withdrawUnderlying(uint256 underlyingAmount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "../../utils/Address.sol";

/// @notice Emitted when the call is made to a non-contract.
error SafeErc20__CallToNonContract(address target);

/// @notice Emitted when there is no return data.
error SafeErc20__NoReturnData();

/// @title SafeErc20.sol
/// @author Paul Razvan Berg
/// @notice Wraps around Erc20 operations that throw on failure (when the token contract
/// returns false). Tokens that return no value (and instead revert or throw
/// on failure) are also supported, non-reverting calls are assumed to be successful.
///
/// To use this library you can add a `using SafeErc20 for IErc20;` statement to your contract,
/// which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Address.sol
library SafeErc20 {
    using Address for address;

    /// INTERNAL FUNCTIONS ///

    function safeTransfer(
        IErc20 token,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IErc20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    /// PRIVATE FUNCTIONS ///

    /// @dev Imitates a Solidity high-level call (a regular function call to a contract), relaxing the requirement
    /// on the return value: the return value is optional (but if data is returned, it cannot be false).
    /// @param token The token targeted by the call.
    /// @param data The call data (encoded using abi.encode or one of its variants).
    function callOptionalReturn(IErc20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = functionCall(address(token), data, "SafeErc20LowLevelCall");
        if (returndata.length > 0) {
            // Return data is optional.
            if (!abi.decode(returndata, (bool))) {
                revert SafeErc20__NoReturnData();
            }
        }
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!target.isContract()) {
            revert SafeErc20__CallToNonContract(target);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present.
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly.
                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: Unlicense
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);
}

/// SPDX-License-Identifier: LGPL-3.0-or-later
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

import "@hifi/amm/contracts/IHifiPool.sol";
import "@hifi/protocol/contracts/core/balance-sheet/IBalanceSheetV2.sol";
import "@hifi/protocol/contracts/core/h-token/IHToken.sol";
import "@prb/contracts/token/erc20/IErc20Permit.sol";

import "./external/WethInterface.sol";

/// @title IHifiProxyTarget
/// @author Hifi
/// @notice DSProxy target contract with scripts for the Hifi protocol, which works with ERC-20 functions.
/// @dev Meant to be used with a DSProxy contract via DELEGATECALL.
interface IHifiProxyTarget {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the hToken slippage is higher than what the user is willing to tolerate.
    error HifiProxyTarget__AddLiquidityHTokenSlippage(uint256 expectedHTokenRequired, uint256 actualHTokenRequired);

    /// @notice Emitted when the underlying slippage is higher than what the user is willing to tolerate.
    error HifiProxyTarget__AddLiquidityUnderlyingSlippage(
        uint256 expectedUnderlyingRequired,
        uint256 actualUnderlyingRequired
    );

    /// @notice Emitted when the slippage is higher than what the user is willing to tolerate.
    error HifiProxyTarget__TradeSlippage(uint256 expectedAmount, uint256 actualAmount);

    /// EVENTS

    /// @notice Emitted when hTokens are borrowed and used to buy underlying.
    /// @param borrower The address of the borrower.
    /// @param borrowAmount The amount of hTokens borrowed and sold.
    /// @param underlyingAmount The amount of underlying bought.
    event BorrowHTokenAndBuyUnderlying(address indexed borrower, uint256 borrowAmount, uint256 underlyingAmount);

    /// @notice Emitted when hTokens are borrowed and sold for underlying.
    /// @param borrower The address of the borrower.
    /// @param borrowAmount The amount of hTokens borrowed and sold.
    /// @param underlyingAmount The amount of underlying bought.
    event BorrowHTokenAndSellHToken(address indexed borrower, uint256 borrowAmount, uint256 underlyingAmount);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Adds liquidity to the AMM.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `underlyingAmount` and `maxHTokenRequired` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param maxHTokenRequired The maximum amount of hTokens that the user is willing to accept.
    function addLiquidity(
        IHifiPool hifiPool,
        uint256 underlyingOffered,
        uint256 maxHTokenRequired
    ) external;

    /// @notice Adds liquidity to the AMM using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by caller to the DSProxy to spend `underlyingAmount`
    /// and `maxHTokenRequired` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param maxHTokenRequired The maximum amount of hTokens that the user is willing to accept.
    /// @param deadline The deadline beyond which the signatures are not valid anymore.
    /// @param signatureHToken The packed signature for the hToken.
    /// @param signatureUnderlying The packed signature for the underlying.
    function addLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingOffered,
        uint256 maxHTokenRequired,
        uint256 deadline,
        bytes memory signatureHToken,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Borrows hTokens.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hToken The address of the HToken contract.
    /// @param borrowAmount The amount of hTokens to borrow.
    function borrowHToken(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 borrowAmount
    ) external;

    /// @notice Borrows hTokens and adds liquidity to the AMM.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `underlyingAmount` tokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param maxBorrowAmount The amount of hTokens to borrow and the max amount that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    function borrowHTokenAndAddLiquidity(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered
    ) external;

    /// @notice Borrows hTokens and adds liquidity to the AMM using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    /// `underlyingOffered` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param maxBorrowAmount The amount of hTokens to borrow and the max amount that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function borrowHTokenAndAddLiquidityWithSignature(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Borrows hTokens and buys underlying.
    ///
    /// @dev Emits a {BorrowHTokenAndBuyUnderlying} event.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param maxBorrowAmount The amount of hTokens to borrow and the max amount that the user is willing to pay.
    /// @param underlyingOut The exact amount of underlying that the user wants to buy.
    function borrowHTokenAndBuyUnderlying(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 maxBorrowAmount,
        uint256 underlyingOut
    ) external;

    /// @notice Borrows hTokens and sells them.
    ///
    /// @dev Emits a {BorrowHTokenAndSellHToken} event.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param borrowAmount The exact amount of hTokens to borrow and sell.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    function borrowHTokenAndSellHToken(
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) external;

    /// @notice Buys hTokens with underlying.
    ///
    /// Requirements:
    /// - The caller must have allowed DSProxy to spend `maxUnderlyingIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenOut The exact amount of hTokens that the user wants to buy.
    /// @param maxUnderlyingIn The maximum amount of underlying that the user is willing to pay.
    function buyHToken(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingIn
    ) external;

    /// @notice Buys hTokens and adds liquidity to the AMM.
    ///
    /// Requirements:
    /// - The caller must have allowed DSProxy to spend `maxUnderlyingIn + underlyingOffered` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenOut The amount of hTokens to buy.
    /// @param maxUnderlyingAmount The maximum amount of underlying that the user is willing to sell and invest.
    function buyHTokenAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingAmount
    ) external;

    /// @notice Buys hTokens with underlying and repays the borrow.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `maxUnderlyingIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param maxUnderlyingIn The maximum amount of underlying that the user is willing to pay.
    /// @param hTokenOut The exact amount of hTokens to buy and the amount to repay and the maximum amount to repay.
    function buyHTokenAndRepayBorrow(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 maxUnderlyingIn,
        uint256 hTokenOut
    ) external;

    /// @notice Buys hTokens and adds liquidity to the AMM using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    /// `maxUnderlyingIn + underlyingOffered` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenOut The amount of hTokens to buy.
    /// @param maxUnderlyingAmount The maximum amount of underlying that the user is willing to sell and invest.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function buyHTokenAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Buys hTokens with underlying and repays the borrow.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `maxUnderlyingIn`
    /// tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param maxUnderlyingIn The maximum amount of underlying that the user is willing to pay.
    /// @param hTokenOut The exact amount of hTokens to buy and the amount to repay and the maximum amount to repay.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function buyHTokenAndRepayBorrowWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 maxUnderlyingIn,
        uint256 hTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Buys hTokens with underlying using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `maxUnderlyingIn`
    /// tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenOut The exact amount of hTokens that the user wants to buy.
    /// @param maxUnderlyingIn The maximum amount of underlying that the user is willing to pay.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function buyHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenOut,
        uint256 maxUnderlyingIn,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Buys underlying with hTokens.
    ///
    /// Requirements:
    /// - The caller must have allowed DSProxy to spend `maxHTokenIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingOut The exact amount of underlying that the user wants to buy.
    /// @param maxHTokenIn The maximum amount of hTokens that the user is willing to pay.
    function buyUnderlying(
        IHifiPool hifiPool,
        uint256 underlyingOut,
        uint256 maxHTokenIn
    ) external;

    /// @notice Buys underlying and adds liquidity to the AMM.
    ///
    /// - The caller must have allowed DSProxy to spend `maxHTokenAmount` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param maxHTokenAmount maxHTokenAmount The maximum amount of hTokens that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    function buyUnderlyingAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 maxHTokenAmount,
        uint256 underlyingOffered
    ) external;

    /// @notice Buys underlying with hTokens using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `maxHTokenIn`
    /// tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingOut The exact amount of underlying that the user wants to buy.
    /// @param maxHTokenIn The maximum amount of hTokens that the user is willing to pay.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureHToken The packed signature for the hToken.
    function buyUnderlyingWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingOut,
        uint256 maxHTokenIn,
        uint256 deadline,
        bytes memory signatureHToken
    ) external;

    /// @notice Buys underlying and adds liquidity to the AMM.
    ///
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    /// `maxHTokenAmount` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param maxHTokenAmount maxHTokenAmount The maximum amount of hTokens that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureHToken The packed signature for the hToken.
    function buyUnderlyingAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 maxHTokenAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureHToken
    ) external;

    /// @notice Deposits collateral into the vault.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param depositAmount The amount of collateral to deposit.
    function depositCollateral(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 depositAmount
    ) external;

    /// @notice Deposits collateral into the vault and borrows hTokens.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hToken The address of the HToken contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param borrowAmount The amount of hTokens to borrow.
    function depositCollateralAndBorrowHToken(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHToken hToken,
        uint256 depositAmount,
        uint256 borrowAmount
    ) external;

    /// @notice Deposits collateral into the vault, borrows hTokens and adds liquidity to the AMM.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param maxBorrowAmount The amount of hTokens to borrow and the max amount that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    function depositCollateralAndBorrowHTokenAndAddLiquidity(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered
    ) external;

    /// @notice Deposits collateral into the vault, borrows hTokens and sells them.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `collateralAmount` tokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param borrowAmount The exact amount of hTokens to borrow.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    function depositCollateralAndBorrowHTokenAndSellHToken(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) external;

    /// @notice Deposits the underlying in the HToken contract to mint hTokens.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `underlyingAmount` tokens.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param underlyingAmount The amount of underlying to deposit.
    function depositUnderlying(IHToken hToken, uint256 underlyingAmount) external;

    /// @notice Deposits underlying in the HToken contract to mint hTokens, borrows hTokens and adds liquidity
    /// to the AMM.
    ///
    /// Requirements:
    /// - The caller must have allowed the DSProxy to spend `depositAmount + underlyingOffered` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of underlying to deposit as collateral.
    /// @param underlyingOffered The amount of underlying to invest.
    function depositUnderlyingAndBorrowHTokenAndAddLiquidity(
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 underlyingOffered
    ) external;

    /// @notice Deposits underlying in the HToken contract to mint hTokens, and repays the borrow.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `underlyingAmount` tokens.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param underlyingAmount The amount of underlying to deposit.
    function depositUnderlyingAndRepayBorrow(
        IHToken hToken,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingAmount
    ) external;

    /// @notice Deposits collateral into the vault using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    /// `depositAmount` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureCollateral The packed signature for the collateral.
    function depositCollateralWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        uint256 depositAmount,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external;

    /// @notice Deposits collateral into the vault and borrows hTokens using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    /// `depositAmount` `collateral` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hToken The address of the HToken contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param borrowAmount The amount of hTokens to borrow.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureCollateral The packed signature for the collateral.
    function depositCollateralAndBorrowHTokenWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHToken hToken,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external;

    /// @notice Deposits collateral into the vault, borrows hTokens and adds liquidity to the AMM using EIP-2612
    /// signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `collateralAmount`
    /// and `underlyingAmount` tokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param maxBorrowAmount The amount of hTokens to borrow and the max amount that the user is willing to invest.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param deadline The deadline beyond which the signatures are not valid anymore.
    /// @param signatureCollateral The packed signature for the collateral.
    /// @param signatureUnderlying The packed signature for the underlying.
    function depositCollateralAndBorrowHTokenAndAddLiquidityWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 maxBorrowAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureCollateral,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Deposits collateral into the vault, borrows hTokens and sells them.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `collateralAmount`
    /// and `underlyingAmount` for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of collateral to deposit.
    /// @param borrowAmount The exact amount of hTokens to borrow.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureCollateral The packed signature for the collateral.
    function depositCollateralAndBorrowHTokenAndSellHTokenWithSignature(
        IBalanceSheetV2 balanceSheet,
        IErc20Permit collateral,
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 borrowAmount,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureCollateral
    ) external;

    /// @notice Supplies the underlying to mint hTokens using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `underlyingAmount`
    ///   for the given `deadline` and the caller's current nonce.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param underlyingAmount The amount of underlying to supply.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function depositUnderlyingWithSignature(
        IHToken hToken,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Deposits underlying as collateral into the vault, borrows hTokens and adds liquidity to the AMM using
    /// EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend
    ///  `depositAmount + underlyingOffered` for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param depositAmount The amount of underlying to deposit as collateral.
    /// @param underlyingOffered The amount of underlying to invest.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function depositUnderlyingAndBorrowHTokenAndAddLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 depositAmount,
        uint256 underlyingOffered,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Supplies underlying to mint hTokens and repay the hToken borrow using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `underlyingAmount`
    ///   for the given `deadline` and the caller's current nonce.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param underlyingAmount The amount of underlying to supply.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function depositUnderlyingAndRepayBorrowWithSignature(
        IHToken hToken,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Redeems the underlying in exchange for hTokens.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `hTokenAmount` hTokens.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param hTokenAmount The amount of hTokens to provide.
    /// @param underlyingAmount The amount of underlying to redeem.
    function redeem(
        IHToken hToken,
        uint256 hTokenAmount,
        uint256 underlyingAmount
    ) external;

    /// @notice Redeems hTokens for underlying using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend  `hTokenAmount`
    ///  for the given `deadline` and the caller's current nonce.
    ///
    /// @param hToken The address of the HToken contract.
    /// @param hTokenAmount The amount of hTokens to redeem.
    /// @param underlyingAmount The amount of underlying to redeem.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureHToken The packed signature for hToken.
    function redeemWithSignature(
        IHToken hToken,
        uint256 hTokenAmount,
        uint256 underlyingAmount,
        uint256 deadline,
        bytes memory signatureHToken
    ) external;

    /// @notice Removes liquidity from the AMM.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `poolTokensBurned` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    function removeLiquidity(IHifiPool hifiPool, uint256 poolTokensBurned) external;

    /// @notice Removes liquidity from the AMM and redeems underlying in exchange for all hTokens
    /// retrieved from the AMM.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `poolTokensBurned` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    function removeLiquidityAndRedeem(IHifiPool hifiPool, uint256 poolTokensBurned) external;

    /// @notice Removes liquidity from the AMM, repays the borrow and withdraws collateral.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `poolTokensBurned` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param withdrawAmount The amount of collateral to withdraw.
    function removeLiquidityAndRepayBorrowAndWithdrawCollateral(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 poolTokensBurned,
        uint256 repayAmount,
        uint256 withdrawAmount
    ) external;

    /// @notice Removes liquidity from the AMM, and sells all hTokens for the underlying.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `poolTokensBurned` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    function removeLiquidityAndSellHToken(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 minUnderlyingOut
    ) external;

    /// @notice Removes liquidity from the AMM using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `poolTokensBurned`
    ///  for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureLPToken The packed signature for LP tokens.
    function removeLiquidityWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external;

    /// @notice Removes liquidity from the AMM, and redeems all hTokens for the underlying using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `poolTokensBurned`
    ///  for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureLPToken The packed signature for LP tokens.
    function removeLiquidityAndRedeemWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external;

    /// @notice Removes liquidity from the AMM, repays the borrow and withdraws collateral using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `poolTokensBurned`
    ///  for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param withdrawAmount The amount of collateral to withdraw.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureLPToken The packed signature for LP tokens.
    function removeLiquidityAndRepayBorrowAndWithdrawCollateralWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 poolTokensBurned,
        uint256 repayAmount,
        uint256 withdrawAmount,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external;

    /// @notice Removes liquidity from the AMM, and sells all hTokens for underlying using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `poolTokensBurned`
    ///  for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param poolTokensBurned The amount of LP tokens to burn.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureLPToken The packed signature for LP tokens.
    function removeLiquidityAndSellHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 poolTokensBurned,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureLPToken
    ) external;

    /// @notice Repays the hToken borrow.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `repayAmount` hTokens.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hToken The address of the HToken contract.
    /// @param repayAmount The amount of hTokens to repay.
    function repayBorrow(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 repayAmount
    ) external;

    /// @notice Repays the hToken borrow using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `repayAmount`
    ///  hTokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hToken The address of the HToken contract.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureHToken The packed signature for HTokens.
    function repayBorrowWithSignature(
        IBalanceSheetV2 balanceSheet,
        IHToken hToken,
        uint256 repayAmount,
        uint256 deadline,
        bytes memory signatureHToken
    ) external;

    /// @notice Sells hTokens for underlying.
    ///
    /// Requirements:
    /// - The caller must have allowed DSProxy to spend `hTokenIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenIn The exact amount of hTokens that the user wants to sell.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    function sellHToken(
        IHifiPool hifiPool,
        uint256 hTokenIn,
        uint256 minUnderlyingOut
    ) external;

    /// @notice Sells hTokens for underlying using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `hTokenIn`
    ///  hTokens for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param hTokenIn The exact amount of hTokens that the user wants to sell.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureHToken The packed signature for HTokens.
    function sellHTokenWithSignature(
        IHifiPool hifiPool,
        uint256 hTokenIn,
        uint256 minUnderlyingOut,
        uint256 deadline,
        bytes memory signatureHToken
    ) external;

    /// @notice Sells underlying for hTokens.
    ///
    /// Requirements:
    /// - The caller must have allowed DSProxy to spend `underlyingIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingIn The exact amount of underlying that the user wants to sell.
    /// @param minHTokenOut The minimum amount of hTokens that the user is willing to accept.
    function sellUnderlying(
        IHifiPool hifiPool,
        uint256 underlyingIn,
        uint256 minHTokenOut
    ) external;

    /// @notice Sells underlying for hTokens, then uses them to repay the hToken borrow.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the DSProxy to spend `underlyingIn` tokens.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param underlyingIn The exact amount of underlying that the user wants to sell.
    /// @param minHTokenOut The minimum amount of hTokens that the user is willing to accept and the maximum
    /// amount to repay.
    function sellUnderlyingAndRepayBorrow(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingIn,
        uint256 minHTokenOut
    ) external;

    /// @notice Sells underlying for hTokens using EIP-2612 signatures.
    ///
    /// Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `underlyingIn`
    ///   for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param underlyingIn The exact amount of underlying that the user wants to sell.
    /// @param minHTokenOut The minimum amount of hTokens that the user is willing to accept.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function sellUnderlyingWithSignature(
        IHifiPool hifiPool,
        uint256 underlyingIn,
        uint256 minHTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Sells underlying for hTokens, then uses them to repay the hToken borrow using EIP-2612 signatures.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the DSProxy to spend `underlyingIn`
    ///   for the given `deadline` and the caller's current nonce.
    ///
    /// @param hifiPool The address of the HifiPool contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param underlyingIn The exact amount of underlying that the user wants to sell.
    /// @param minHTokenOut The minimum amount of hTokens that the user is willing to accept and the maximum
    /// amount to repay.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signatureUnderlying The packed signature for the underlying.
    function sellUnderlyingAndRepayBorrowWithSignature(
        IHifiPool hifiPool,
        IBalanceSheetV2 balanceSheet,
        uint256 underlyingIn,
        uint256 minHTokenOut,
        uint256 deadline,
        bytes memory signatureUnderlying
    ) external;

    /// @notice Withdraws collateral from the vault.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param collateral The address of the collateral contract.
    /// @param withdrawAmount The amount of collateral to withdraw.
    function withdrawCollateral(
        IBalanceSheetV2 balanceSheet,
        IErc20 collateral,
        uint256 withdrawAmount
    ) external;

    /// @notice Wraps ETH into WETH and makes a collateral deposit in the BalanceSheet contract.
    /// @dev This is a payable function so it can receive ETH transfers.
    /// @param weth The address of the WETH contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    function wrapEthAndDepositCollateral(WethInterface weth, IBalanceSheetV2 balanceSheet) external payable;

    /// @notice Wraps ETH into WETH, deposits collateral into the vault, borrows hTokens and sells them.
    ///
    /// @dev This is a payable function so it can receive ETH transfers.
    ///
    /// @param weth The address of the WETH contract.
    /// @param balanceSheet The address of the BalanceSheet contract.
    /// @param hifiPool  The address of the HifiPool contract.
    /// @param borrowAmount The exact amount of hTokens to borrow and sell for underlying.
    /// @param minUnderlyingOut The minimum amount of underlying that the user is willing to accept.
    function wrapEthAndDepositAndBorrowHTokenAndSellHToken(
        WethInterface weth,
        IBalanceSheetV2 balanceSheet,
        IHifiPool hifiPool,
        uint256 borrowAmount,
        uint256 minUnderlyingOut
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @title WethInterface
/// @author Hifi
interface WethInterface {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IOwnable
/// @author Paul Razvan Berg
/// @notice Contract module that provides a basic access control mechanism, where there is an
/// account (an owner) that can be granted exclusive access to specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This can later be
/// changed with {transfer}.
///
/// This module is used through inheritance. It will make available the modifier `onlyOwner`,
/// which can be applied to your functions to restrict their use to the owner.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
interface IOwnable {
    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Leaves the contract without owner, so it will not be possible to call `onlyOwner`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an owner, thereby removing any
    /// functionality that is only available to the owner.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    function _renounceOwnership() external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The account of the new owner.
    function _transferOwnership(address newOwner) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    /// @return The address of the owner.
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "../../access/IOwnable.sol";

/// @title IErc20Recover
/// @author Paul Razvan Berg
/// @notice Contract that gives the owner the ability to recover the Erc20 tokens that were sent
/// (accidentally, or not) to the contract.
interface IErc20Recover is IOwnable {
    /// EVENTS ///

    /// @notice Emitted when tokens are recovered.
    /// @param owner The address of the owner recoverring the tokens.
    /// @param token The address of the recovered token.
    /// @param recoverAmount The amount of recovered tokens.
    event Recover(address indexed owner, IErc20 token, uint256 recoverAmount);

    /// @notice Emitted when tokens are set as non-recoverable.
    /// @param owner The address of the owner calling the function.
    /// @param nonRecoverableTokens An array of token addresses.
    event SetNonRecoverableTokens(address indexed owner, IErc20[] nonRecoverableTokens);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Recover Erc20 tokens sent to this contract (by accident or otherwise).
    /// @dev Emits a {RecoverToken} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The contract must be initialized.
    /// - The amount to recover cannot be zero.
    /// - The token to recover cannot be among the non-recoverable tokens.
    ///
    /// @param token The token to make the recover for.
    /// @param recoverAmount The uint256 amount to recover, specified in the token's decimal system.
    function _recover(IErc20 token, uint256 recoverAmount) external;

    /// @notice Sets the tokens that this contract cannot recover.
    ///
    /// @dev Emits a {SetNonRecoverableTokens} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The contract cannot be already initialized.
    ///
    /// @param tokens The array of tokens to set as non-recoverable.
    function _setNonRecoverableTokens(IErc20[] calldata tokens) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The tokens that can be recovered cannot be in this mapping.
    function nonRecoverableTokens(uint256 index) external view returns (IErc20);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@prb/contracts/token/erc20/IErc20.sol";
import "@prb/contracts/access/IOwnable.sol";

import "../h-token/IHToken.sol";

/// @notice IFintroller
/// @author Hifi
/// @notice Controls the financial permissions and risk parameters for the Hifi protocol.
interface IFintroller is IOwnable {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when interacting with a bond that is not listed.
    error Fintroller__BondNotListed(IHToken bond);

    /// @notice Emitted when listing a collateral that has more than 18 decimals.
    error Fintroller__CollateralDecimalsOverflow(uint256 decimals);

    /// @notice Emitted when listing a collateral that has zero decimals.
    error Fintroller__CollateralDecimalsZero();

    /// @notice Emitted when interacting with a collateral that is not listed.
    error Fintroller__CollateralNotListed(IErc20 collateral);

    /// @notice Emitted when setting a new collateral ratio that is above the upper bound.
    error Fintroller__CollateralRatioOverflow(uint256 newCollateralRatio);

    /// @notice Emitted when setting a new collateral ratio that is below the lower bound.
    error Fintroller__CollateralRatioUnderflow(uint256 newCollateralRatio);

    /// @notice Emitted when setting a new debt ceiling that is below the total supply of hTokens.
    error Fintroller__DebtCeilingUnderflow(uint256 newDebtCeiling, uint256 totalSupply);

    /// @notice Emitted when setting a new liquidation incentive that is above the upper bound.
    error Fintroller__LiquidationIncentiveOverflow(uint256 newLiquidationIncentive);

    /// @notice Emitted when setting a new liquidation incentive that is below the lower bound.
    error Fintroller__LiquidationIncentiveUnderflow(uint256 newLiquidationIncentive);

    /// EVENTS ///

    /// @notice Emitted when a new bond is listed.
    /// @param owner The address of the contract owner.
    /// @param bond The newly listed bond.
    event ListBond(address indexed owner, IHToken indexed bond);

    /// @notice Emitted when a new collateral is listed.
    /// @param owner The address of the contract owner.
    /// @param collateral The newly listed collateral.
    event ListCollateral(address indexed owner, IErc20 indexed collateral);

    /// @notice Emitted when the borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if borrowing is allowed.
    event SetBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the collateral ceiling is updated.
    /// @param owner The address of the contract owner.
    /// @param collateral The related collateral.
    /// @param oldCollateralCeiling The old collateral ceiling.
    /// @param newCollateralCeiling The new collateral ceiling.
    event SetCollateralCeiling(
        address indexed owner,
        IErc20 indexed collateral,
        uint256 oldCollateralCeiling,
        uint256 newCollateralCeiling
    );

    /// @notice Emitted when the collateral ratio is updated.
    /// @param owner The address of the contract owner.
    /// @param collateral The related HToken.
    /// @param oldCollateralRatio The old collateral ratio.
    /// @param newCollateralRatio the new collateral ratio.
    event SetCollateralRatio(
        address indexed owner,
        IErc20 indexed collateral,
        uint256 oldCollateralRatio,
        uint256 newCollateralRatio
    );

    /// @notice Emitted when the debt ceiling for a bond is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param oldDebtCeiling The old debt ceiling.
    /// @param newDebtCeiling The new debt ceiling.
    event SetDebtCeiling(address indexed owner, IHToken indexed bond, uint256 oldDebtCeiling, uint256 newDebtCeiling);

    /// @notice Emitted when the deposit collateral permission is updated.
    /// @param owner The address of the contract owner.
    /// @param state True if depositing collateral is allowed.
    event SetDepositCollateralAllowed(address indexed owner, IErc20 indexed collateral, bool state);

    /// @notice Emitted when the deposit underlying permission is set.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if deposit underlying is allowed.
    event SetDepositUnderlyingAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the liquidate borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if liquidating borrow is allowed.
    event SetLiquidateBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the collateral liquidation incentive is set.
    /// @param owner The address of the contract owner.
    /// @param collateral The related collateral.
    /// @param oldLiquidationIncentive The old liquidation incentive.
    /// @param newLiquidationIncentive The new liquidation incentive.
    event SetLiquidationIncentive(
        address indexed owner,
        IErc20 collateral,
        uint256 oldLiquidationIncentive,
        uint256 newLiquidationIncentive
    );

    /// @notice Emitted when a new max bonds value is set.
    /// @param owner The address indexed owner.
    /// @param oldMaxBonds The address of the old max bonds value.
    /// @param newMaxBonds The address of the new max bonds value.
    event SetMaxBonds(address indexed owner, uint256 oldMaxBonds, uint256 newMaxBonds);

    /// @notice Emitted when the redeem permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if redeeming is allowed.
    event SetRedeemAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the repay borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if repaying borrow is allowed.
    event SetRepayBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// STRUCTS ///

    struct Bond {
        uint256 debtCeiling;
        bool isBorrowAllowed;
        bool isDepositUnderlyingAllowed;
        bool isLiquidateBorrowAllowed;
        bool isListed;
        bool isRedeemHTokenAllowed;
        bool isRepayBorrowAllowed;
    }

    struct Collateral {
        uint256 ceiling;
        uint256 ratio;
        uint256 liquidationIncentive;
        bool isDepositCollateralAllowed;
        bool isListed;
    }

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the Bond struct instance associated to the given address.
    /// @dev It is not an error to provide an invalid address.
    /// @param bond The address of the bond contract.
    /// @return The bond object.
    function getBond(IHToken bond) external view returns (Bond memory);

    /// @notice Checks if the account should be allowed to borrow hTokens.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Returns the Collateral struct instance associated to the given address.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral object.
    function getCollateral(IErc20 collateral) external view returns (Collateral memory);

    /// @notice Returns the collateral ceiling.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral ceiling as a uint256, or zero if an invalid address was provided.
    function getCollateralCeiling(IErc20 collateral) external view returns (uint256);

    /// @notice Returns the collateral ratio.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral ratio, or zero if an invalid address was provided.
    function getCollateralRatio(IErc20 collateral) external view returns (uint256);

    /// @notice Returns the debt ceiling for the given bond.
    /// @dev It is not an error to provide an invalid address.
    /// @param bond The address of the bond contract.
    /// @return The debt ceiling as a uint256, or zero if an invalid address was provided.
    function getDebtCeiling(IHToken bond) external view returns (uint256);

    /// @notice Checks if collateral deposits are allowed.
    /// @dev The collateral must be listed.
    /// @param collateral The collateral to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getDepositCollateralAllowed(IErc20 collateral) external view returns (bool);

    /// @notice Checks if underlying deposits are allowed.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getDepositUnderlyingAllowed(IHToken bond) external view returns (bool);

    /// @notice Returns the liquidation incentive of the given collateral.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The liquidation incentive, or zero if an invalid address was provided.
    function getLiquidationIncentive(IErc20 collateral) external view returns (uint256);

    /// @notice Checks if the account should be allowed to liquidate hToken borrows.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getLiquidateBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Checks if the account should be allowed to repay borrows.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getRepayBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Checks if the bond is listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = listed, otherwise not.
    function isBondListed(IHToken bond) external view returns (bool);

    /// @notice Checks if the collateral is listed.
    /// @param collateral The collateral to make the check against.
    /// @return bool true = listed, otherwise not.
    function isCollateralListed(IErc20 collateral) external view returns (bool);

    /// @notice Returns the maximum number of bond markets a single account can enter.
    function maxBonds() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Marks the bond as listed in this registry.
    ///
    /// @dev It is not an error to list a bond twice. Emits a {ListBond} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param bond The hToken contract to list.
    function listBond(IHToken bond) external;

    /// @notice Marks the collateral as listed in this registry.
    ///
    /// @dev Emits a {ListCollateral} event. It is not an error to list a bond twice.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must have between 1 and 18 decimals.
    ///
    /// @param collateral The collateral contract to list.
    function listCollateral(IErc20 collateral) external;

    /// @notice Updates the state of the permission accessed by the hToken before a borrow.
    ///
    /// @dev Emits a {SetBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The bond to update the permission for.
    /// @param state The new state to put in storage.
    function setBorrowAllowed(IHToken bond, bool state) external;

    /// @notice Updates the collateral ceiling.
    ///
    /// @dev Emits a {SetCollateralCeiling} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    ///
    /// @param collateral The collateral to update the ceiling for.
    /// @param newCollateralCeiling The new collateral ceiling.
    function setCollateralCeiling(IHToken collateral, uint256 newCollateralCeiling) external;

    /// @notice Updates the collateral ratio.
    ///
    /// @dev Emits a {SetCollateralRatio} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    /// - The new collateral ratio cannot be higher than the maximum collateral ratio.
    /// - The new collateral ratio cannot be lower than the minimum collateral ratio.
    ///
    /// @param collateral The collateral to update the collateral ratio for.
    /// @param newCollateralRatio The new collateral ratio.
    function setCollateralRatio(IErc20 collateral, uint256 newCollateralRatio) external;

    /// @notice Updates the debt ceiling for the given bond.
    ///
    /// @dev Emits a {SetDebtCeiling} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    /// - The debt ceiling cannot fall below the current total supply of hTokens.
    ///
    /// @param bond The bond to update the debt ceiling for.
    /// @param newDebtCeiling The new debt ceiling.
    function setDebtCeiling(IHToken bond, uint256 newDebtCeiling) external;

    /// @notice Updates the state of the permission accessed by the BalanceSheet before a collateral deposit.
    ///
    /// @dev Emits a {SetDepositCollateralAllowed} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param collateral The collateral to update the permission for.
    /// @param state The new state to put in storage.
    function setDepositCollateralAllowed(IErc20 collateral, bool state) external;

    /// @notice Updates the state of the permission accessed by the hToken before an underlying deposit.
    ///
    /// @dev Emits a {SetDepositUnderlyingAllowed} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param bond The bond to update the permission for.
    /// @param state The new state to put in storage.
    function setDepositUnderlyingAllowed(IHToken bond, bool state) external;

    /// @notice Updates the collateral liquidation incentive.
    ///
    /// @dev Emits a {SetLiquidationIncentive} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    /// - The new liquidation incentive cannot be higher than the maximum liquidation incentive.
    /// - The new liquidation incentive cannot be lower than the minimum liquidation incentive.
    ///
    /// @param collateral The collateral to update the liquidation incentive for.
    /// @param newLiquidationIncentive The new liquidation incentive.
    function setLiquidationIncentive(IErc20 collateral, uint256 newLiquidationIncentive) external;

    /// @notice Updates the state of the permission accessed by the hToken before a liquidate borrow.
    ///
    /// @dev Emits a {SetLiquidateBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The hToken contract to update the permission for.
    /// @param state The new state to put in storage.
    function setLiquidateBorrowAllowed(IHToken bond, bool state) external;

    /// @notice Sets max bonds value, which controls how many bond markets a single account can enter.
    ///
    /// @dev Emits a {SetMaxBonds} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newMaxBonds New max bonds value.
    function setMaxBonds(uint256 newMaxBonds) external;

    /// @notice Updates the state of the permission accessed by the hToken before a repay borrow.
    ///
    /// @dev Emits a {SetRepayBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The hToken contract to update the permission for.
    /// @param state The new state to put in storage.
    function setRepayBorrowAllowed(IHToken bond, bool state) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

/// @title IOwnableUpgradeable
/// @author Hifi
interface IOwnableUpgradeable {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the caller is not the owner.
    error OwnableUpgradeable__NotOwner(address owner, address caller);

    /// @notice Emitted when setting the owner to the zero address.
    error OwnableUpgradeable__OwnerZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Leaves the contract without an owner, so it will not be possible to call `onlyOwner`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an owner, thereby removing any
    /// functionality that is only available to the owner.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    function _renounceOwnership() external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The account of the new owner.
    function _transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@prb/contracts/token/erc20/IErc20.sol";
import "@prb/contracts/access/IOwnable.sol";

import "../external/chainlink/IAggregatorV3.sol";

/// @title IChainlinkOperator
/// @author Hifi
/// @notice Aggregates the price feeds provided by Chainlink.
interface IChainlinkOperator {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the decimal precision of the feed is not the same as the expected number.
    error ChainlinkOperator__DecimalsMismatch(string symbol, uint256 decimals);

    /// @notice Emitted when trying to interact with a feed not set yet.
    error ChainlinkOperator__FeedNotSet(string symbol);

    /// @notice Emitted when the price returned by the oracle is zero.
    error ChainlinkOperator__PriceZero(string symbol);

    /// EVENTS ///

    /// @notice Emitted when a feed is deleted.
    /// @param asset The related asset.
    /// @param feed The related feed.
    event DeleteFeed(IErc20 indexed asset, IAggregatorV3 indexed feed);

    /// @notice Emitted when a feed is set.
    /// @param asset The related asset.
    /// @param feed The related feed.
    event SetFeed(IErc20 indexed asset, IAggregatorV3 indexed feed);

    /// STRUCTS ///

    struct Feed {
        IErc20 asset;
        IAggregatorV3 id;
        bool isSet;
    }

    /// CONSTANT FUNCTIONS ///

    /// @notice Gets the official feed for a symbol.
    /// @param symbol The symbol to return the feed for.
    /// @return (address asset, address id, bool isSet).
    function getFeed(string memory symbol)
        external
        view
        returns (
            IErc20,
            IAggregatorV3,
            bool
        );

    /// @notice Gets the official price for a symbol and adjusts it have 18 decimals instead of the
    /// format used by Chainlink, which has 8 decimals.
    ///
    /// @dev Requirements:
    /// - The normalized price cannot overflow.
    ///
    /// @param symbol The Erc20 symbol of the token for which to query the price.
    /// @return The normalized price.
    function getNormalizedPrice(string memory symbol) external view returns (uint256);

    /// @notice Gets the official price for a symbol in the default format used by Chainlink, which
    /// has 8 decimals.
    ///
    /// @dev Requirements:
    ///
    /// - The feed must be set.
    /// - The price returned by the oracle cannot be zero.
    ///
    /// @param symbol The symbol to fetch the price for.
    /// @return The price denominated in USD, with 8 decimals.
    function getPrice(string memory symbol) external view returns (uint256);

    /// @notice Chainlink price precision for USD-quoted data.
    function pricePrecision() external view returns (uint256);

    /// @notice The ratio between normalized precision (1e18) and the Chainlink price precision (1e8).
    function pricePrecisionScalar() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deletes a previously set Chainlink price feed.
    ///
    /// @dev Emits a {DeleteFeed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The feed must be set already.
    ///
    /// @param symbol The Erc20 symbol of the asset to delete the feed for.
    function deleteFeed(string memory symbol) external;

    /// @notice Sets a Chainlink price feed.
    ///
    /// @dev It is not an error to set a feed twice. Emits a {SetFeed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The number of decimals of the feed must be 8.
    ///
    /// @param asset The address of the Erc20 contract for which to get the price.
    /// @param feed The address of the Chainlink price feed contract.
    function setFeed(IErc20 asset, IAggregatorV3 feed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title IAggregatorV3
/// @author Hifi
/// @dev Forked from Chainlink
/// github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    /// getRoundData and latestRoundData should both raise "No data present" if they do not have
    /// data to report, instead of returning unset values which could be misinterpreted as
    /// actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title Address
/// @author Paul Razvan Berg
/// @notice Collection of functions related to the address type.
/// @dev Forked from OpenZeppelin
/// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.0/contracts/utils/Address.sol
library Address {
    /// @dev Returns true if `account` is a contract.
    ///
    /// IMPORTANT: It is unsafe to assume that an address for which this function returns false is an
    /// externally-owned account (EOA) and not a contract.
    ///
    /// Among others, `isContract` will return false for the following types of addresses:
    ///
    /// - An externally-owned account
    /// - A contract in construction
    /// - An address where a contract will be created
    /// - An address where a contract lived, but was destroyed
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`.
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}