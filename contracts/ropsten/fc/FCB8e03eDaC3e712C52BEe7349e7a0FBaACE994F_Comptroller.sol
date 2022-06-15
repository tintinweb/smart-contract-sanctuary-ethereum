pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./CNftInterface.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./ComptrollerStorage.sol";
import "./ZBond.sol";
import "./ComptrollerInterface.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */

contract Comptroller is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ComptrollerInterface,
    ComptrollerErrorReporter,
    Exponential,
    ComptrollerStorage
{
    /// @notice Emitted when an owner supports a market
    event MarketListed(CNftInterface cNFT, ZBond zBond);

    /// @notice Emitted when close factor is changed by owner
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    /// @notice Emitted when a collateral factor is changed by owner
    event NewCollateralFactor(
        CNftInterface cNFT,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by owner
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(
        PriceOracle oldPriceOracle,
        PriceOracle newPriceOracle
    );

    /// @notice Emitted when price oracle is changed
    event NewNFTPriceOracle(
        NftPriceOracle oldPriceOracle,
        NftPriceOracle newPriceOracle
    );

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(address asset, string action, bool pauseState);

    event DecreasedBalance(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event IncreasedBalance(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 1e18; // 1

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    function initialize() public initializer {
        __Ownable_init();
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param zBond The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(
        address zBond,
        address minter,
        uint256 mintAmount
    ) external view override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[zBond], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[zBond].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        // updateCompSupplyIndex(zBond);
        // distributeSupplierComp(zBond, minter);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param zBond The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of zBonds to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(
        address zBond,
        address redeemer,
        uint256 redeemTokens
    ) external view override returns (uint256) {
        uint256 allowed = redeemAllowedInternal(zBond, redeemer, redeemTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        // updateCompSupplyIndex(zBond);
        // distributeSupplierComp(zBond, redeemer);

        return uint256(Error.NO_ERROR);
    }

    function redeemAllowedInternal(
        address asset,
        address redeemer,
        uint256 redeemTokens
    ) internal view returns (uint256) {
        if (!markets[asset].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (
            Error err,
            ,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                redeemer,
                asset,
                asset,
                redeemTokens,
                0
            );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall > 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param zBond Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(
        address zBond,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external pure override {
        // Shh - currently unused
        zBond;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param zBond The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(
        address zBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[zBond], "borrow is paused");
        require(
            duration < ZBond(zBond).maximumLoanDuration(),
            "Borrow term too long."
        );

        // require the caller of this function to be supported zbond
        require(markets[address(zBond)].isListed, "zBond not listed.");

        // total borrow has to be lower than the reserved pool.
        require(
            borrowAmount <= ZBond(zBond).provisioningPool().getCashBalance(),
            "cannot borrow more than the provisioning pool"
        );
        require(markets[zBond].isListed, "market not listed.");
        require(oracle.getUnderlyingPrice(zBond) != 0, "asset price == 0");

        uint256 borrowCap = borrowCaps[zBond];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = ZBond(zBond).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        address correspondingCNFTAddress = address(ZBond(zBond).cNFT());
        (
            Error err,
            ,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                borrower,
                zBond,
                correspondingCNFTAddress,
                0,
                borrowAmount
            );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall > 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }

        // when borrow. increase the amount of effective balance that accumulates zumer.
        //increaseBalance(zBond, borrower, borrowAmount);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param zBond The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address zBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external override returns (uint256) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[zBond].isListed) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        // after repay, decrease the effective balance
        // require the caller of this function to be supported zbond
        require(markets[address(zBond)].isListed, "zBond not listed.");
        //decreaseBalance(zBond, borrower, repayAmount);

        return uint256(Error.NO_ERROR);
    }

    /**

        There will be only one NFT being liquidated per overdue.
        This function calculates how much to repay for that one NFT.
        Need to convert credit into the correct unit
        TODO: what if liquidation and overdue conditions both satisfy.
        TODO: change function name to calculateOverdueRepayAmount
    */
    /**
     * @notice Container for borrow balance information
     */
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInteretRate;
    }

    function calculateLiquidationAmount(
        address borrower,
        address zBondBorrowed,
        uint256[] calldata id,
        address cNFT
    ) external view override returns (uint256) {
        // calculate the credit offered by one NFT
        // numNFTs * price * collateralRate
        Exp memory nftCollateralFactor = Exp({
            mantissa: markets[address(cNFT)].collateralFactorMantissa
        });
        uint256 nftPriceMantissa = oracle.getUnderlyingPrice(cNFT);

        Exp memory priceNFT = Exp({mantissa: nftPriceMantissa});
        Exp memory maxRepay = Exp(
            mul_((id.length), mul_(nftCollateralFactor, priceNFT))
        );

        // calculate the borrowed balance equivalent value
        uint256 borrowBalance = ZBond(zBondBorrowed)
            .getAccountCurrentBorrowBalance(borrower);
        uint256 priceMantissa = oracle.getUnderlyingPrice(zBondBorrowed);
        Exp memory borrowedAssetPrice = Exp({mantissa: priceMantissa});
        Exp memory borrowValue = mul_(borrowedAssetPrice, borrowBalance);

        if (greaterThanExp(maxRepay, borrowValue)) {
            // if borrowed asset is less expensive than the NFT, can liquidate all borrow balance
            return borrowBalance;
        } else {
            // if borrowed assets is more expensive than the NFT, can only liquidate the collateral value of NFT
            return div_(maxRepay, borrowedAssetPrice).mantissa;
        }
    }

    /**
     * @notice Calculate number of cNFT tokens to seize given an underlying amount
     * @dev Used in liquidation (called in zBond.liquidateBorrowFreshNft)
     * @param zBondBorrowed The address of the borrowed zBond
     * @param actualRepayAmount The amount of zBondBorrowed underlyin to convert into NFTs
     * @return (errorCode, number of cNft tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeNfts(
        address zBondBorrowed,
        address cNftCollateral,
        uint256 actualRepayAmount
    ) external view override returns (uint256, uint256) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(
            zBondBorrowed
        );
        uint256 priceCollateralMantissa = nftOracle.getUnderlyingPrice(
            CNftInterface(cNftCollateral)
        );
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint256(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeTokens = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         */
        uint256 seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(
            Exp({mantissa: liquidationIncentiveMantissa}),
            Exp({mantissa: priceBorrowedMantissa})
        );
        denominator = Exp({mantissa: priceCollateralMantissa});
        ratio = div_(numerator, denominator);

        seizeTokens = truncate(mul_(ratio, Exp({mantissa: actualRepayAmount})));

        return (uint256(Error.NO_ERROR), seizeTokens);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param zBondBorrowed Asset which was borrowed by the borrower
     * @param cNFT Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     */
    function liquidateBorrowAllowed(
        address zBondBorrowed,
        address cNFT,
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external override returns (uint256) {
        // Shh - currently unused
        liquidator;

        require(markets[zBondBorrowed].isListed, "zBond market not listed");
        require(liquidator != borrower, "Cannot liquidate self");
        require(id.length == 1, "Cannot only liquidate 1 NFT a time.");
        for (uint256 i = 0; i < id.length; i++) {
            require(
                CNftInterface(cNFT).ownerOf(id[i]) == borrower,
                "Cannot liquidate NFT that the borrower do not own."
            );
        }
        if (sequenceOfLiquidation[cNFT][borrower].length != 0) {
            uint256 last = sequenceOfLiquidation[cNFT][borrower][
                sequenceOfLiquidation[cNFT][borrower].length - 1
            ];
            sequenceOfLiquidation[cNFT][borrower].pop();
            while (last != id[0]) {
                if (CNftInterface(cNFT).ownerOf(last) != borrower) {
                    last = sequenceOfLiquidation[cNFT][borrower][
                        sequenceOfLiquidation[cNFT][borrower].length - 1
                    ];
                    sequenceOfLiquidation[cNFT][borrower].pop();
                } else {
                    require(
                        last != id[0],
                        "Not the preferred NFT to be liquidated"
                    ); // TODO: should we throw or should we just assign this NFT to be liquidated
                    //id[0] = last;
                }
            }
        }

        uint256 borrowBalance = ZBond(zBondBorrowed)
            .getAccountCurrentBorrowBalance(borrower);

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint256 shortfall) = getAccountLiquidityInternal(
            borrower,
            cNFT
        );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }

        if (shortfall != 0) {
            return uint256(Error.NO_ERROR);
        }

        // if the credit line is fine, then check overdue

        //require(id.length == 1, "Cannot seize over 1 NFT when overdue");

        BorrowSnapshot memory borrowSnapshot;
        (
            borrowSnapshot.deadline,
            borrowSnapshot.loanDuration,
            borrowSnapshot.minimumPaymentDue,
            borrowSnapshot.principalBorrow,
            borrowSnapshot.weightedInteretRate
        ) = ZBond(zBondBorrowed).accountBorrows(borrower);

        if (
            (borrowSnapshot.minimumPaymentDue < block.timestamp &&
                borrowSnapshot.minimumPaymentDue != 0) ||
            (borrowSnapshot.deadline < block.timestamp &&
                borrowSnapshot.deadline != 0)
        ) {
            return uint256(Error.NO_ERROR);
        } else {
            revert("Insufficient shortfall to liquidate or not overdue.");
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param zBondCollateral Asset which was used as collateral and will be seized
     * @param zBondBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address zBondCollateral,
        address zBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external view override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (
            !markets[zBondCollateral].isListed ||
            !markets[zBondBorrowed].isListed
        ) {
            return uint256(Error.MARKET_NOT_LISTED);
        }

        if (
            ZBond(zBondCollateral).comptroller() !=
            ZBond(zBondBorrowed).comptroller()
        ) {
            return uint256(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        // updateCompSupplyIndex(zBondCollateral);
        // distributeSupplierComp(zBondCollateral, borrower);
        // distributeSupplierComp(zBondCollateral, liquidator);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param zBond The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of zBonds to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address zBond,
        address src,
        address dst,
        uint256 transferTokens
    ) external view override returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint256 allowed = redeemAllowedInternal(zBond, src, transferTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        // updateCompSupplyIndex(zBond);
        // distributeSupplierComp(zBond, src);
        // distributeSupplierComp(zBond, dst);

        return uint256(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `zBondBalance` is the number of zBonds the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 zBondBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        uint256 nftOraclePriceMantissa;
        Exp collateralFactor;
        Exp nftCollateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp nftOraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account, address cNFT)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            Error err,
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                account,
                address(0),
                cNFT,
                0,
                0
            );

        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account, address cNFT)
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        return
            getHypotheticalAccountLiquidityInternal(
                account,
                address(0),
                cNFT,
                0,
                0
            );
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param assetModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address assetModify,
        address cNFT,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            Error err,
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                account,
                assetModify,
                cNFT,
                redeemTokens,
                borrowAmount
            );
        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param assetModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemNFTAmount The amount of underlying to hypothetically borrow
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral zBond using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address assetModify,
        address cNFT,
        uint256 redeemNFTAmount,
        uint256 borrowAmount
    )
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint256 oErr;

        if ((assetModify != cNFT) && assetModify != address(0)) {
            require(
                allMarkets[CNftInterface(cNFT)][ZBond(assetModify)],
                "Market mismatch"
            );
        }

        // For each ZBond the cNFT corresponds to
        ZBond[] memory assets = CNftInterface(cNFT).getZBonds();
        for (uint256 i = 0; i < assets.length; i++) {
            ZBond asset = assets[i];

            // Read the balances and exchange rate from the zBond
            vars.borrowBalance = asset.getAccountCurrentBorrowBalance(account);

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(
                address(asset)
            );
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );

            // Calculate effects of interacting with zBondModify
            if (address(asset) == assetModify) {
                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects += mul_ScalarTruncate(
                    vars.oraclePrice,
                    borrowAmount
                );
            }
        }

        // calculate cnft collateral value with or without changes
        uint256 nftBalance = CNftInterface(cNFT).balanceOf(account);

        if (nftBalance > 0) {
            // Get the price of the NFT and the collateral factor
            vars.nftOraclePriceMantissa = nftOracle.getUnderlyingPrice(
                CNftInterface(cNFT)
            );
            require(vars.nftOraclePriceMantissa != 0, "NFT price error");
            vars.nftOraclePrice = Exp({mantissa: vars.nftOraclePriceMantissa});
            vars.nftCollateralFactor = Exp({
                mantissa: markets[address(cNFT)].collateralFactorMantissa
            });

            // sumCollateral += nftOraclePrice * collateralFactor * nftBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                mul_(
                    vars.nftOraclePrice,
                    markets[address(cNFT)].collateralFactorMantissa
                ),
                nftBalance,
                vars.sumCollateral
            );
            if (assetModify == address(cNFT)) {
                // sumBorrowPlusEffects += nftOraclePrice * collateralFactor * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    mul_(
                        vars.nftOraclePrice,
                        markets[address(cNFT)].collateralFactorMantissa
                    ),
                    redeemNFTAmount,
                    vars.sumBorrowPlusEffects
                );
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (
                Error.NO_ERROR,
                vars.sumCollateral - vars.sumBorrowPlusEffects,
                0
            );
        } else {
            return (
                Error.NO_ERROR,
                0,
                vars.sumBorrowPlusEffects - vars.sumCollateral
            );
        }
    }

    function changeSequenceOfLiquidation(
        CNftInterface cNFT,
        uint256[] calldata sequence
    ) public {
        require(markets[address(cNFT)].isListed, "NFT not supported");
        for (uint256 i = 0; i < sequence.length; i++) {
            require(
                cNFT.ownerOf(sequence[i]) == msg.sender,
                "Sender does not own this NFT."
            );
        }
        sequenceOfLiquidation[address(cNFT)][msg.sender] = sequence;
    }

    /*** Owner Functions ***/

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Owner function to set a new price oracle
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPriceOracle(PriceOracle newOracle)
        public
        onlyOwner
        returns (uint256)
    {
        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Owner function to set a new price oracle
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setNftPriceOracle(NftPriceOracle newOracle)
        public
        onlyOwner
        returns (uint256)
    {
        // Track the old oracle for the comptroller
        NftPriceOracle oldOracle = nftOracle;
        // Set comptroller's nft oracle to newOracle
        nftOracle = newOracle;

        emit NewNFTPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Owner function to set closeFactor
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure
     */
    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        onlyOwner
        returns (uint256)
    {
        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Owner function to set per-market collateralFactor
     * @param cNFT The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCollateralFactor(
        CNftInterface cNFT,
        uint256 newCollateralFactorMantissa
    ) external onlyOwner returns (uint256) {
        //  verify the market is NFT
        Market storage market = markets[address(cNFT)];
        require(cNFT.isCNft(), "NFTs collaterals only");

        // Verify market is listed
        require(
            market.isListed,
            "Cannot set non-exisiting market collateral factors."
        );

        Exp memory newCollateralFactorExp = Exp({
            mantissa: newCollateralFactorMantissa
        });

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return
                fail(
                    Error.INVALID_COLLATERAL_FACTOR,
                    FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION
                );
        }

        // If collateral factor != 0, fail if price == 0
        if (
            newCollateralFactorMantissa != 0 &&
            nftOracle.getUnderlyingPrice(cNFT) == 0
        ) {
            return
                fail(
                    Error.PRICE_ERROR,
                    FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE
                );
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(
            cNFT,
            oldCollateralFactorMantissa,
            newCollateralFactorMantissa
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Owner function to set liquidationIncentive
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        onlyOwner
        returns (uint256)
    {
        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(
            oldLiquidationIncentiveMantissa,
            newLiquidationIncentiveMantissa
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Owner function to set isListed and add support for the market
     * @param zBond The address of the market (token) to list
     * @param cNFT The address of the market (token) to list
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */

    function _supportMarket(CNftInterface cNFT, ZBond zBond)
        external
        onlyOwner
        returns (uint256)
    {
        require(cNFT.isCNft(), "cNFT is not NFT");
        require(zBond.isZBond(), "zBond is not ZBond");
        require(!markets[address(zBond)].isListed, "zBond already listed");
        require(
            address(zBond.cNFT()) == address(cNFT),
            "zBond cNFT do not match"
        );

        markets[address(zBond)].isListed = true;
        markets[address(cNFT)].isListed = true;
        allMarkets[cNFT][zBond] = true;
        cNFT.setZBond(zBond);

        add(0, address(zBond), true);
        add(0, address(zBond.provisioningPool()), true);

        emit MarketListed(cNFT, zBond);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Owner function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian)
        public
        onlyOwner
        returns (uint256)
    {
        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint256(Error.NO_ERROR);
    }

    function _setMintPaused(address asset, bool state) public returns (bool) {
        require(
            markets[asset].isListed,
            "cannot pause a market that is not listed"
        );
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "only owner can unpause"
        );

        mintGuardianPaused[asset] = state;

        emit ActionPaused(asset, "Mint", state);

        return state;
    }

    function _setBorrowPaused(ZBond zBond, bool state) public returns (bool) {
        require(
            markets[address(zBond)].isListed,
            "cannot pause a market that is not listed"
        );
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "only owner can unpause"
        );

        borrowGuardianPaused[address(zBond)] = state;
        emit ActionPaused(address(zBond), "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "only owner can unpause"
        );

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "only owner can unpause"
        );

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _setZumer(address zumer_) public onlyOwner {
        zumer = IERC20(zumer_);
    }

    /**
     * @notice Returns true if the given zBond market has been deprecated
     * @dev All borrows in a deprecated zBond market can be immediately liquidated
     * @param zBond The market to check if deprecated
     */
    function isDeprecated(ZBond zBond) public view returns (bool) {
        return
            markets[address(zBond)].collateralFactorMantissa == 0 &&
            borrowGuardianPaused[address(zBond)] == true;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    // token rewards functions

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _pool,
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        uint256 id = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                pool: _pool,
                balance: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accZumerPerShare: 0
            })
        );

        poolToID[_pool] = id;
    }

    // Update the given pool's ZUMER allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return (_to - _from) * BONUS_MULTIPLIER;
        } else if (_from >= bonusEndBlock) {
            return _to - _from;
        } else {
            return
                (bonusEndBlock - _from) *
                BONUS_MULTIPLIER +
                (_to - bonusEndBlock);
        }
    }

    // View function to see pending ZUMERs on frontend.
    function pendingZumer(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZumerPerShare = pool.accZumerPerShare;
        uint256 lpSupply = pool.balance;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 zumerReward = (multiplier *
                zumerPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accZumerPerShare =
                accZumerPerShare +
                ((zumerReward * 1e12) / lpSupply);
        }
        return (user.amount * accZumerPerShare) / 1e12 - (user.rewardDebt);
    }

    // an even better pending zumer function
    function pendingZumerAll(uint256[] memory _pids, address _user)
        public
        view
        returns (uint256)
    {
        uint256 all = 0;
        for (uint256 i; i < _pids.length; i++) {
            all += pendingZumer(_pids[i], _user);
        }
        return all;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.balance;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 zumerReward = (multiplier * zumerPerBlock * pool.allocPoint) /
            totalAllocPoint;

        pool.accZumerPerShare =
            pool.accZumerPerShare +
            (zumerReward * 1e12) /
            lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // relevant contracts (provisioning pool, zbond) call this method to make sure that the users balance that
    // claim the zumer tokens is properly recorded
    function increaseBalance(
        address poolAddress,
        address account,
        uint256 _amount
    ) internal {
        uint256 _pid = poolToID[poolAddress];
        PoolInfo storage pool = poolInfo[_pid];

        //require(msg.sender == pool.pool, "Only certified contracts can change balances.");

        UserInfo storage user = userInfo[_pid][account];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accZumerPerShare) /
                1e12 -
                user.rewardDebt;
            zumer.transfer(account, pending);
        }
        pool.balance += _amount;
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e12;

        emit IncreasedBalance(account, _pid, _amount);
    }

    function decreaseBalance(
        address poolAddress,
        address account,
        uint256 _amount
    ) internal {
        uint256 _pid = poolToID[poolAddress];
        PoolInfo storage pool = poolInfo[_pid];

        UserInfo storage user = userInfo[_pid][account];
        require(user.amount >= _amount, "decrease balance: not enough balance");

        updatePool(_pid);
        uint256 pending = (user.amount * pool.accZumerPerShare) /
            1e12 -
            user.rewardDebt;

        zumer.transfer(account, pending);

        pool.balance -= _amount;
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e12;

        emit DecreasedBalance(account, _pid, _amount);
    }

    function claimAllZumers(address[] memory poolAddresses) external {
        for (uint256 i; i < poolAddresses.length; i++) {
            uint256 _pid = poolToID[poolAddresses[i]];
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][msg.sender];
            updatePool(_pid);
            if (user.amount > 0) {
                uint256 pending = (user.amount * pool.accZumerPerShare) /
                    1e12 -
                    user.rewardDebt;
                zumer.transfer(msg.sender, pending);
            }
            user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e12;
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ZBond.sol";
import "./AuctionMarket.sol";

abstract contract CNftInterface is ERC721Upgradeable, IERC721Receiver {
    address public underlying;
    bool isPunk;
    string public uri;
    address public comptroller;
    AuctionMarket public auctionMarket;
    bool public constant isCNft = true;

    /**
     * We will likely support other erc tokens other than wETH.
     */
    ZBond[] public zBonds;
    /**
     * @notice Event emitted when cNFTs are minted
     */
    event Mint(address minter, uint256[] mintIds);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256[] redeemIds);

    function seize(
        address liquidator,
        address borrower,
        uint256[] calldata seizeIds
    ) external virtual;

    function mint(uint256[] calldata tokenIds, address minter)
        external
        virtual
        returns (uint256);

    function redeem(uint256[] calldata tokenIds, address redeemer)
        external
        virtual
        returns (uint256);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external virtual;

    function getZBonds() external view virtual returns (ZBond[] memory);

    function setZBond(ZBond zBond) external virtual;
}

pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

pragma solidity ^0.8.0;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The asset to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address asset)
        external
        view
        virtual
        returns (uint256);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CNftInterface.sol";
import "./ZBond.sol";
import "./NftPriceOracle.sol";
import "./PriceOracle.sol";

abstract contract UnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of Unitroller
     */
    address public comptrollerImplementation;

    /**
     * @notice Pending brains of Unitroller
     */
    address public pendingComptrollerImplementation;
}

contract ComptrollerStorage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => mapping(address => ZBond[])) public accountAssets;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
    }

    struct BorrowState {
        uint256 dueTime;
        uint256 initialBorrow;
    }
    /**
     * @notice Official mapping of asset -> collateral metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets for a cNFT market
    mapping(CNftInterface => mapping(ZBond => bool)) public allMarkets;

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each zBond address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice Last block at which a contributor's COMP rewards have been allocated
    mapping(address => uint256) public lastContributorBlock;

    NftPriceOracle public nftOracle;

    mapping(address => mapping(address => uint256[]))
        public sequenceOfLiquidation; // nft => user => id

    // token awards storage

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ZUMERs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZumerPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZumerPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address pool; // Address of the contract being rewarded.
        uint256 balance; // balance of the tokens that will be used in the calculation.
        uint256 allocPoint; // How many allocation points assigned to this pool. ZUMERs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ZUMERs distribution occurs.
        uint256 accZumerPerShare; // Accumulated ZUMERs per share, times 1e12. See below.
    }

    // The ZUMER TOKEN!
    IERC20 public zumer;
    // Block number when bonus ZUMER period ends.
    uint256 public bonusEndBlock;
    // ZUMER tokens created per block.
    uint256 public zumerPerBlock;
    // Bonus muliplier for early zumer makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolToID;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ZUMER mining starts.
    uint256 public startBlock;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./ComptrollerInterface.sol";
import "./FeeSelector.sol";
import "./ProvisioningPool.sol";
import "./ExponentialNoError.sol";
import "./CNftInterface.sol";

interface ZBondInterface {
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(
        address minter,
        uint256 mintAmount,
        uint256 mintTokens,
        uint256 totalSupply
    );
    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 totalBorrows,
        uint256 duration
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        CNftInterface cTokenCollateral
    );

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
}

abstract contract ZBondStorage is ZBondInterface {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /** 
        how much time that a user can borrow without paying interests until they get margin call
    */
    uint256 public minimumPaymentDueFrequency = 30 days; // TODO

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current funding cost should be
     */
    FeeSelector public feeSelector;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public provisioningPoolMantissa;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total number of underlying accumulated in the contract plus the borrowed token
     */
    uint256 public totalSupplyPrinciplePlusInterest;

    /**
     * @notice Underlying
     */
    IERC20 public underlying;

    /**
     * @notice Container for borrow balance information
     */
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInteretRate;
    }

    struct SupplySnapshot {
        uint256 principalSupply;
        uint256 startDate;
    }

    /**
     * @notice days that one has to pledge in the pool to get all the awards
     */
    uint256 public fullAwardCollectionDuration = 30 days;

    uint256 public maximumLoanDuration = 180 days;
    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;

    mapping(address => SupplySnapshot) public accountSupplies;

    mapping(address => uint256[]) public userLiquidationSequence;

    CNftInterface public cNFT;
    ProvisioningPool public provisioningPool;
    bool public isZBond = true;

    uint256 public creditCostRatioMantissa = 0.05 * 1e18;

    uint256 public underwritingFeeRatioMantissa = 0.01 * 1e18;
}

contract ZBond is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    Exponential,
    ZBondStorage
{
    function initialize(
        string memory name_,
        string memory symbol_,
        CNftInterface cNFT_,
        FeeSelector feeSelector_,
        ComptrollerInterface comptroller_,
        IERC20 underlying_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        cNFT = cNFT_;
        feeSelector = feeSelector_;
        comptroller = comptroller_;
        underlying = underlying_;
    }

    /**
        amountIn: the underlying asset that will be transfered in the contract.
     */
    function mintInternal(uint256 amountIn) internal returns (uint256) {
        uint256 mintAmount = mulScalarTruncate(
            Exp(getExchangeRateMantissa()),
            amountIn
        );
        _mint(msg.sender, mintAmount);

        // effects
        // change user state
        accountSupplies[msg.sender].principalSupply += amountIn;
        if (accountSupplies[msg.sender].startDate == 0) {
            accountSupplies[msg.sender].startDate = block.timestamp;
        }

        // change global state
        totalSupplyPrinciplePlusInterest += amountIn;

        // interaction
        doTransferIn(msg.sender, amountIn);
        emit Mint(
            msg.sender,
            amountIn,
            mintAmount,
            totalSupplyPrinciplePlusInterest
        );

        return mintAmount;
    }

    /**
        amountIn: the underlying asset that will be transfered out from the contract contract.
     */
    function redeemInternal(uint256 amountOut) internal returns (uint256) {
        // effects
        uint256 burnAmount = mulScalarTruncate(
            Exp(getExchangeRateMantissa()),
            amountOut
        );
        require(
            burnAmount <= balanceOf(msg.sender),
            "Not enough balance to redeem"
        );

        // reduce total supply
        totalSupplyPrinciplePlusInterest -= amountOut;
        _burn(msg.sender, burnAmount);

        // interaction
        emit Redeem(msg.sender, amountOut, burnAmount);

        doTransferOut(msg.sender, amountOut);

        return burnAmount;
    }

    function borrowInternal(uint256 amount, uint256 duration)
        internal
        returns (uint256, uint256)
    {
        require(
            comptroller.borrowAllowed(
                address(this),
                msg.sender,
                amount,
                duration
            ) == 0,
            "Comptroller rejected borrow"
        );
        uint256 fundingRateMantissa = feeSelector.getFundingCostForDuration(
            duration,
            maximumLoanDuration
        );

        fundingRateMantissa += creditCostRatioMantissa;

        // effects
        updateUserStateAfterBorrow(
            msg.sender,
            amount,
            duration,
            fundingRateMantissa
        );
        totalBorrows += amount;

        // interactions
        // transfer underwriting fee to the admin
        uint256 underwritingFee = mul_(
            amount,
            Exp(underwritingFeeRatioMantissa)
        );
        doTransferOut(owner(), underwritingFee);
        // transfer principle borrow to the user
        doTransferOut(msg.sender, amount - underwritingFee);

        emit Borrow(msg.sender, amount, totalBorrows, duration);

        //zumerMiner.increaseBalance(msg.sender, amount);
    }

    /**
    
        returns actual amount paid and the interest that are transfered to the provisioining pool.
     */
    function repayBorrowInternal(address borrower, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        require(
            comptroller.repayBorrowAllowed(
                address(this),
                msg.sender,
                msg.sender,
                amount
            ) == 0,
            "Comptroller rejected repay"
        );

        // effects
        (uint256 overpay, uint256 interestPaid) = updateUserStateAfterRepay(
            borrower,
            amount
        );
        uint256 provisioningInterest = mulScalarTruncate(
            Exp(provisioningPoolMantissa),
            interestPaid
        );
        totalSupplyPrinciplePlusInterest += (interestPaid -
            provisioningInterest);

        // interactions
        doTransferIn(msg.sender, amount - overpay);

        if (address(provisioningPool) != address(0)) {
            doTransferOut(address(provisioningPool), provisioningInterest);
        } else {
            doTransferOut(owner(), provisioningInterest);
        }

        // update zumer claims

        //zumerMiner.decreaseBalance(msg.sender, amount);

        return (amount - overpay, provisioningInterest);
    }

    function liquidateBorrowInternal(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) internal returns (uint256) {
        uint256 err = comptroller.liquidateBorrowAllowed(
            address(this),
            address(cNFT),
            liquidator,
            borrower,
            id
        );
        require(err == 0, "Comptroller rejected liquidation");

        uint256 repayAmount = comptroller.calculateLiquidationAmount(
            borrower,
            address(this),
            id,
            address(cNFT)
        );
        (
            uint256 actualPayBack,
            uint256 provisioningPoolInterestPaid
        ) = repayBorrowInternal(borrower, repayAmount);

        // seize collaterals;
        cNFT.seize(liquidator, borrower, id);

        emit LiquidateBorrow(liquidator, borrower, repayAmount, cNFT);
        return actualPayBack;
    }

    /**
        Gets the rate betwen the total supply of zBondToken: totalSupply
     */
    function getExchangeRateMantissa() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        } else {
            return
                getExp(totalSupply(), totalSupplyPrinciplePlusInterest)
                    .mantissa;
        }
    }

    /** 
        update the users' borrow state
        returns (overpay, interest paid).   
    */
    function updateUserStateAfterRepay(address borrower, uint256 paid)
        internal
        returns (uint256, uint256)
    {
        uint256 borrowBalance = accountBorrows[borrower].principalBorrow;
        uint256 currentInterestToPay = getAccountCurrentBorrowBalance(
            borrower
        ) - borrowBalance;
        if (paid < currentInterestToPay) {
            return (0, paid);
        } else {
            // if user closed position, then delete user borrow position
            if (borrowBalance + currentInterestToPay <= paid) {
                delete accountBorrows[borrower];
                return (
                    paid - (borrowBalance + currentInterestToPay),
                    currentInterestToPay
                );
            }
            // if user reduced position (or at least paid all of their interests), then reduce initial borrow and carry over the minimum payment due time, total loan due time is not affected
            else {
                accountBorrows[borrower].minimumPaymentDue =
                    block.timestamp +
                    minimumPaymentDueFrequency;
                accountBorrows[borrower].principalBorrow =
                    borrowBalance +
                    currentInterestToPay -
                    paid;

                return (0, currentInterestToPay);
            }
        }
    }

    function updateUserStateAfterBorrow(
        address borrower,
        uint256 borrowAmount,
        uint256 duration,
        uint256 interest
    ) internal {
        // initialize borrow state if dueTime is not set
        if (accountBorrows[borrower].minimumPaymentDue == 0) {
            accountBorrows[borrower].minimumPaymentDue =
                block.timestamp +
                minimumPaymentDueFrequency;
        }
        if (accountBorrows[borrower].deadline == 0) {
            accountBorrows[borrower].loanDuration = duration;
            accountBorrows[borrower].deadline =
                block.timestamp +
                accountBorrows[borrower].loanDuration;
        }

        // set weighted interest
        uint256 timeLeft = accountBorrows[borrower].deadline - block.timestamp;
        if (accountBorrows[borrower].principalBorrow == 0) {
            accountBorrows[borrower].weightedInteretRate = interest;
        } else {
            accountBorrows[borrower].weightedInteretRate = getExp(
                (accountBorrows[borrower].weightedInteretRate *
                    accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    interest *
                    borrowAmount *
                    timeLeft),
                (accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    borrowAmount *
                    timeLeft)
            ).mantissa;
        }

        accountBorrows[borrower].principalBorrow += borrowAmount;

        require(
            (accountBorrows[borrower].minimumPaymentDue >= block.timestamp) &&
                (accountBorrows[borrower].minimumPaymentDue >= block.timestamp),
            "cannot increase position if overdue"
        );
    }

    function getAccountCurrentBorrowBalance(address borrower)
        public
        view
        returns (uint256)
    {
        uint256 principle = accountBorrows[borrower].principalBorrow;

        if (principle == 0) {
            return 0;
        }

        uint256 interestRate = accountBorrows[borrower].weightedInteretRate;
        uint256 duration = accountBorrows[borrower].loanDuration;
        uint256 deadline = accountBorrows[borrower].deadline;
        uint256 accruedPeriod;

        if (block.timestamp > deadline) {
            // if overdue, balance should be all the principle and all the interests
            accruedPeriod = duration;
        } else {
            accruedPeriod = deadline - block.timestamp;
        }

        Exp memory ratio = getExp(accruedPeriod, duration);
        // interest = (timeleft / totalLoanDuration) * principle * interestRate
        uint256 interest = mul_(mul_(principle, Exp(interestRate)), ratio);

        return principle + interest;
    }

    function pledgeThenBorrow(
        uint256[] calldata ids,
        uint256 amount,
        uint256 duration
    ) public {
        cNFT.mint(ids, msg.sender);
        borrowInternal(amount, duration);
    }

    function repayAllThenRedeem(uint256[] calldata ids) public {
        uint256 borrowBalance = getAccountCurrentBorrowBalance(msg.sender);
        repayBorrowInternal(msg.sender, borrowBalance);
        cNFT.redeem(ids, msg.sender);
    }

    function setProvisioningPool(
        address provisioningPoolAddress,
        uint256 provisioingPoolMantissa_
    ) public onlyOwner {
        provisioningPool = ProvisioningPool(payable(provisioningPoolAddress));
        provisioningPoolMantissa = provisioingPoolMantissa_;
    }

    function setUnderwritingFeeRatio(uint256 underwritingFeeRatioMantissa_)
        public
        onlyOwner
    {
        underwritingFeeRatioMantissa = underwritingFeeRatioMantissa_;
    }

    function setCreditCostRatio(uint256 creditCostRatioMantissa_)
        public
        onlyOwner
    {
        creditCostRatioMantissa = creditCostRatioMantissa_;
    }

    function mint(uint256 amount) external returns (uint256) {
        return mintInternal(amount);
    }

    function redeem(uint256 amount) external {
        redeemInternal(amount);
    }

    function borrow(uint256 amount, uint256 duration) external {
        borrowInternal(amount, duration);
    }

    function repayBorrow(uint256 amount) external {
        repayBorrowInternal(msg.sender, amount);
    }

    function doTransferIn(address sender, uint256 amount) internal {
        underlying.transferFrom(sender, address(this), amount);
    }

    function doTransferOut(address receiver, uint256 amount) internal {
        underlying.transferFrom(address(this), receiver, amount);
    }

    function liquidateOverdueBorrow(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external returns (uint256) {
        return liquidateBorrowInternal(liquidator, borrower, id);
    }

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256[] calldata ids
    ) external returns (uint256) {
        return liquidateBorrowInternal(liquidator, borrower, ids);
    }

    function getCashBalance() external view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

pragma solidity ^0.8.0;

/// @dev Keep in sync with ComptrollerInterface080.sol.
abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Policy Hooks ***/
    function mintAllowed(
        address zBond,
        address minter,
        uint256 mintAmount
    ) external virtual returns (uint256);

    function redeemAllowed(
        address zBond,
        address redeemer,
        uint256 redeemTokens
    ) external virtual returns (uint256);

    function redeemVerify(
        address zBond,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external virtual;

    function borrowAllowed(
        address zBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external virtual returns (uint256);

    function repayBorrowAllowed(
        address zBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function calculateLiquidationAmount(
        address borrower,
        address zBondBorrowed,
        uint256[] calldata id,
        address cNFT
    ) external virtual returns (uint256);

    function liquidateBorrowAllowed(
        address zBondBorrowed,
        address cNFT,
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external virtual returns (uint256);

    function seizeAllowed(
        address zBondCollateral,
        address zBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    function transferAllowed(
        address zBond,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual returns (uint256);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeNfts(
        address zBondBorrowed,
        address zBondCollateral,
        uint256 repayAmount
    ) external view virtual returns (uint256, uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProvisioningPool.sol";

contract AuctionMarket is Ownable {
    event Start(
        CNftInterface cNFT,
        uint256 id,
        uint256 repayAmount,
        address originalOwner,
        uint256 endTime
    );
    event Bid(
        address indexed bidder,
        CNftInterface cNFT,
        uint256 id,
        uint256 amount
    );
    event Withdraw(
        address indexed bidder,
        CNftInterface cNFT,
        uint256 id,
        uint256 amout
    );
    event CloseBid(
        address winnder,
        CNftInterface cNFT,
        uint256 id,
        uint256 closeAmount
    );

    uint256 bidExtension = 10 minutes;
    mapping(address => mapping(uint256 => AuctionInfo)) public auctionInfo; // cNFT -> id -> Auction info so that this auction market can do auction for all nfts.
    mapping(address => mapping(uint256 => bool)) public insurance; // if true then the NFT is being protected by insurance
    mapping(CNftInterface => mapping(address => uint256))
        public accountInsurance; // hit points of the users insurance
    ProvisioningPool[] public provisioningPools;
    uint32 immutable redeemDuration = 24 hours;
    /**
        isOnAuction: is auction still going
        redeemEndAt: the time when the borrower can no longer depay borrow debt to redeem.
        auctionEndAt: the time when the auction ends and the highest bid gets the NFT.
        highestBidder: 
        highestBid:
        borrowBalance: the balance that the borrower have to repay to redeem the NFT.
        bids: bidder vs. their bid amount
        borrower: address of the borrower who originally own the NFT. 
     */

    struct AuctionInfo {
        bool isOnAuction;
        uint256 redeemEndAt;
        uint256 auctionEndAt;
        address highestBidder;
        uint256 highestBid;
        uint256 borrowRepay;
        mapping(address => uint256) bids;
        address borrower;
    }

    function setProvisioningPool(ProvisioningPool pp) public onlyOwner {
        provisioningPools.push(pp);
    }

    /** Pay penalty */
    function redeemAndPayPenalty(uint256 id, CNftInterface cNftCollateral)
        external
        payable
    {
        require(
            block.timestamp <
                auctionInfo[address(cNftCollateral)][id].redeemEndAt,
            "Redeem period over."
        );
        require(
            msg.sender == auctionInfo[address(cNftCollateral)][id].borrower,
            "redeemer not the borrower"
        );
        uint256 repay = auctionInfo[address(cNftCollateral)][id].borrowRepay;
        require(msg.value >= repay, "insufficient redeem amount");
        if (msg.value > repay) {
            //payable(msg.sender).transfer(msg.value - repay);
        }
        // return the NFT
        cNftCollateral.safeTransferFrom(address(this), msg.sender, id);

        // end bid
        endBid(id, repay, address(cNftCollateral));
    }

    /** Auction */
    /**

        struct AuctionInfo {
        bool isOnAuction;
        uint32 redeemEndAt;
        uint32 auctionEndAt;
        address highestBidder;
        uint highestBid;
        uint borrowBalance;
        mapping(address => uint) bids;
        }
     */
    function startAuction(
        uint256 id,
        uint256 repayAmount,
        address originalOwner,
        CNftInterface cNftCollateral
    ) public {
        //require(address(cNftCollateral.comptroller()) == comptroller, "comptroller does not match");
        require(
            cNftCollateral.ownerOf(id) == address(this),
            "Auct pool does not own this NFT."
        );
        require(
            !auctionInfo[address(cNftCollateral)][id].isOnAuction,
            "NFT already on auction."
        );

        // initialize the auction
        auctionInfo[address(cNftCollateral)][id].isOnAuction = true;

        if (accountInsurance[cNftCollateral][originalOwner] > 0) {
            auctionInfo[address(cNftCollateral)][id].redeemEndAt =
                block.timestamp +
                redeemDuration;
            spendInsurance(cNftCollateral, originalOwner);
        } else {
            auctionInfo[address(cNftCollateral)][id].redeemEndAt = block
                .timestamp;
        }
        auctionInfo[address(cNftCollateral)][id].redeemEndAt =
            block.timestamp +
            redeemDuration;
        auctionInfo[address(cNftCollateral)][id].auctionEndAt =
            block.timestamp +
            redeemDuration;
        auctionInfo[address(cNftCollateral)][id].borrowRepay = repayAmount;
        auctionInfo[address(cNftCollateral)][id].borrower = originalOwner;

        emit Start(
            cNftCollateral,
            id,
            repayAmount,
            originalOwner,
            block.timestamp + redeemDuration
        );
    }

    function bid(uint256 id, address cNftCollateral) public payable {
        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];

        require(
            msg.value + auction.bids[msg.sender] > auction.highestBid,
            "Bid must be higher than the highest bid"
        );
        require(
            msg.value + auction.bids[msg.sender] > auction.borrowRepay,
            "Bid must be higher than the borrow repay"
        );
        require(
            block.timestamp < auction.auctionEndAt && auction.isOnAuction,
            "Auction ended"
        );
        auction.bids[msg.sender] += msg.value;
        auction.highestBid += msg.value;
        auction.highestBidder = msg.sender;

        // extend bid time if within the last bidding period.
        if (block.timestamp > auction.auctionEndAt - bidExtension) {
            auction.auctionEndAt = block.timestamp + bidExtension;
        }

        emit Bid(msg.sender, CNftInterface(cNftCollateral), id, msg.value);
    }

    function withdrawBid(uint256 id, address cNftCollateral) public {
        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];
        require(msg.sender != auction.highestBidder, "Highest bidder"); // highest bidder cannot withdraw
        require(auction.bids[msg.sender] > 0, "Non existing bidder");

        // transfer bid & reset the bid
        auction.bids[msg.sender] = 0;
        //payable(msg.sender).transfer(auction.bids[msg.sender]); // TODO

        emit Withdraw(
            msg.sender,
            CNftInterface(cNftCollateral),
            id,
            auction.bids[msg.sender]
        );
    }

    function withdrawBidAll(uint256[] calldata id, address cNftCollateral)
        public
    {
        for (uint256 i = 0; i < id.length; i++) {
            withdrawBid(id[i], cNftCollateral);
        }
    }

    function winBid(uint256 id, ProvisioningPool provisioningPool) public {
        CNftInterface cNftCollateral = provisioningPool.cNftCollateral();
        AuctionInfo storage auction = auctionInfo[address(cNftCollateral)][id];

        require(block.timestamp > auction.auctionEndAt, "Auction ongoing");
        require(auction.isOnAuction, "Auction ended");
        if (auction.highestBidder != address(0)) {
            cNftCollateral.transferFrom(
                address(this),
                auction.highestBidder,
                id
            );
            // end the auction
            endBid(id, auction.highestBid, address(cNftCollateral)); // end bid and replenish money in the Provisioning pool
            //payable(provisioningPool).transfer(auction.highestBid);
        } else {
            // if no one bids, continue auction
            auction.auctionEndAt = block.timestamp + redeemDuration;
            emit Start(
                cNftCollateral,
                id,
                auction.borrowRepay,
                auction.borrower,
                block.timestamp + redeemDuration
            );
        }
    }

    function endBid(
        uint256 id,
        uint256 closeAmount,
        address cNftCollateral
    ) internal {
        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];
        auction.isOnAuction = false;
        auction.redeemEndAt = 0;
        auction.auctionEndAt = 0;
        auction.borrowRepay = 0;
        auction.highestBidder = address(0);
        auction.highestBid = 0;
        auction.borrower = address(0);
        emit CloseBid(
            auction.highestBidder,
            CNftInterface(cNftCollateral),
            id,
            closeAmount
        );
    }

    function activateInsurance(
        CNftInterface cNftCollateralAddress,
        address originalOwner,
        uint256 amount
    ) public {
        accountInsurance[cNftCollateralAddress][originalOwner] += amount;
    }

    function spendInsurance(
        CNftInterface cNftCollateralAddress,
        address originalOwner
    ) internal {
        // spend insurance on the event of being liquidatedated
        accountInsurance[cNftCollateralAddress][originalOwner] -= 1; // spend insurance
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Exponential.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract FeeSelector is Exponential {
    /**
        _decisionToken: token that is used to decide the fee
        upperBound: upper bound of the funding cost
        lowerBound
    */

    struct UserVotes {
        uint256 upperLong;
        uint256 lowerLong;
        uint256 upperShort;
        uint256 lowerShort;
    }

    IERC20 public decisionToken;

    struct PoolInfo {
        uint256 upperBound;
        uint256 lowerBound;
        uint256 upperTotal;
        uint256 lowerTotal;
    }

    PoolInfo public longPool;

    PoolInfo public shortPool;

    mapping(address => UserVotes) public userAcounts;

    constructor(
        IERC20 _decisionToken,
        uint256 _upperBoundLong,
        uint256 _lowerBoundLong,
        uint256 _upperBoundShort,
        uint256 _lowerBoundShort
    ) {
        decisionToken = _decisionToken;
        longPool.upperBound = _upperBoundLong;
        longPool.lowerBound = _lowerBoundLong;

        shortPool.upperBound = _upperBoundShort;
        shortPool.lowerBound = _lowerBoundShort;
    }

    function stake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong += upperAmount;
            userAcounts[msg.sender].lowerLong += lowerAmount;

            longPool.upperTotal += upperAmount;
            longPool.lowerTotal += lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort += upperAmount;
            userAcounts[msg.sender].lowerShort += lowerAmount;

            shortPool.upperTotal += upperAmount;
            shortPool.lowerTotal += lowerAmount;
        }

        decisionToken.transferFrom(
            msg.sender,
            address(this),
            upperAmount + lowerAmount
        );
    }

    function unstake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong -= upperAmount;
            userAcounts[msg.sender].lowerLong -= lowerAmount;

            longPool.upperTotal -= upperAmount;
            longPool.lowerTotal -= lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort -= upperAmount;
            userAcounts[msg.sender].lowerShort -= lowerAmount;

            shortPool.upperTotal -= upperAmount;
            shortPool.lowerTotal -= lowerAmount;
        }

        decisionToken.transferFrom(
            address(this),
            msg.sender,
            upperAmount + lowerAmount
        );
    }

    /**
        Returns the rate per second. (*1e18)
     */
    function getFundingCostForDuration(
        uint256 loanDuration,
        uint256 maximumLoanDuration
    ) public view returns (uint256) {
        (uint256 upper, uint256 lower) = getFundingCostRateFx();
        return ((upper + lower) * loanDuration) / maximumLoanDuration;
    }

    function getFundingCost(PoolInfo memory pool)
        public
        pure
        returns (uint256)
    {
        if (pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return
            (pool.upperBound *
                pool.upperTotal +
                pool.lowerBound *
                pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    function getFundingCostRateFx() public view returns (uint256, uint256) {
        uint256 upper = getFundingCost(longPool);
        uint256 lower = getFundingCost(shortPool);

        return (upper, lower);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./Exponential.sol";
import "./ZBond.sol";
import "./CNftInterface.sol";
import "./ComptrollerInterface.sol";
import "./AuctionMarket.sol";

abstract contract ProvisioningPoolStorage {
    CNftInterface public cNftCollateral;
    ComptrollerInterface public comptroller;
    ZBond public zBond;
    uint256 public penaltyMantissa;
    AuctionMarket public auctionMarket;
    uint256 public expireDuration = 30 days;

    uint256 public totalStakedUnderlying;
    IERC20 public underlying;

    struct StakeData {
        uint256 expireTime;
        uint256 staked;
        uint256 unstaked;
    }
    mapping(address => StakeData[]) public userStakeData;
}

/**
    @title Zumer's Provioning Pool
    @notice 

 */
contract ProvisioningPool is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    Exponential,
    ProvisioningPoolStorage
{
    event Staked(address staker, uint256 amount, uint256 expiration);
    event Unstaked(address staker, uint256 amount, uint256 expiration);
    event Received(address sender, uint256 amount);

    function initialize(
        ComptrollerInterface _comptroller,
        CNftInterface _cNftCollateral,
        ZBond _zBond,
        string memory _name,
        string memory _symbol,
        AuctionMarket _auctionMarket,
        IERC20 _underlying
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);

        comptroller = _comptroller;
        cNftCollateral = _cNftCollateral;
        zBond = _zBond;
        auctionMarket = _auctionMarket;
        underlying = _underlying;
    }

    /**
        Stakes in the provisioning pool. Returns the number of ppToken minted.
    
     */
    function stakeInternal(uint256 amount, uint256 time)
        internal
        returns (uint256)
    {
        require(time >= expireDuration, "Stake should be at least 30 days.");
        uint256 mintAmount = mulScalarTruncate(
            Exp(getCurrentExchangeRateMantissa()),
            amount
        );
        _mint(msg.sender, mintAmount);

        totalStakedUnderlying += amount;
        emit Staked(msg.sender, mintAmount, time + block.timestamp);

        // update user timestamp data.
        StakeData memory stakeData = StakeData(
            time + block.timestamp,
            mintAmount,
            0
        );
        userStakeData[msg.sender].push(stakeData);

        // interaction
        doTransferIn(msg.sender, amount);

        //zumerMiner.increaseBalance(msg.sender, amount);

        return mintAmount;
    }

    /**
        Unstakes in the provisioning pool. Returns the number of ppToken burned.
    
     */
    function unstakeInternal(uint256 amount) internal returns (uint256) {
        require(
            address(this).balance > 0,
            "Not enough to unstake in the provisioning pool."
        );

        // effects

        uint256 burnAmount = mulExp(amount, getCurrentExchangeRateMantissa())
            .mantissa;
        _burn(msg.sender, burnAmount);
        totalStakedUnderlying -= amount;

        // interaction
        doTransferOut(msg.sender, amount);

        //zumerMiner.decreaseBalance(msg.sender, amount);

        return burnAmount;
    }

    function unstakeAll() external returns (uint256) {
        uint256 burnedPPAmount = 0;
        uint256 numOfUnstakes = 0;
        uint256 length = userStakeData[msg.sender].length;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for (uint256 i = 0; i < length; i++) {
            if (sd[i].expireTime < block.timestamp) {
                burnedPPAmount += sd[i].staked - sd[i].unstaked;
                sd[i].unstaked = sd[i].staked;
                numOfUnstakes += 1;
                emit Unstaked(msg.sender, burnedPPAmount, sd[i].expireTime);
            }
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
        /*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        } */

        // interaction
        uint256 burnAmount = unstakeInternal(burnedPPAmount);
        return burnAmount;
    }

    /**
        returns pp token burned and the amount 
     */
    function unstakeAmount(uint256 amount)
        external
        returns (uint256 burnAmount, uint256)
    {
        uint256 burnedPPAmount = 0;
        uint256 numOfUnstakes = 0;
        uint256 length = userStakeData[msg.sender].length;
        uint256 insufficientAmount = amount;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for (uint256 i = 0; i < length; i++) {
            if (sd[i].expireTime < block.timestamp) {
                if (amount >= sd[i].staked - sd[i].unstaked) {
                    // if we have enough tokens to unstake then unstake
                    burnedPPAmount += sd[i].staked - sd[i].unstaked;
                    numOfUnstakes += 1;
                    amount -= sd[i].staked - sd[i].unstaked;
                    sd[i].unstaked = sd[i].staked;
                } else {
                    // else only unstake some then terminate
                    burnedPPAmount += amount;
                    sd[i].unstaked += amount;
                    amount = 0;
                    break;
                }
            }
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
        /*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        }
 */

        // interaction
        burnAmount = unstakeInternal(burnedPPAmount);
        return (burnAmount, insufficientAmount - amount);
    }

    /** Liquidation */
    function liquidateOverDueNFT(address borrower, uint256[] calldata id)
        public
    {
        // require(address(address(cNftCollateral).comptroller()) == comptroller, "comptroller does not match");

        address originalOwner = cNftCollateral.ownerOf(id[0]);

        uint256 repayFromProvisioning = comptroller.calculateLiquidationAmount(
            borrower,
            address(zBond),
            id,
            address(cNftCollateral)
        );
        uint256 actualRepayAmount = repayAndSeize(address(this), borrower, id);
        require(
            cNftCollateral.ownerOf(id[0]) == address(this),
            "NFT liquidation failed"
        );

        // send to auction
        uint256 repay;
        if (penaltyMantissa <= 1e18) {
            repay = actualRepayAmount;
        } else {
            repay = mul_(actualRepayAmount, Exp({mantissa: penaltyMantissa}));
        }

        // start auction
        auctionMarket.startAuction(
            id[0],
            repay,
            originalOwner,
            CNftInterface(address(cNftCollateral))
        );
    }

    /**
        Gets the exchange rate of ppToken: underlying. Scaled by 1e18;
     */
    function getCurrentExchangeRateMantissa() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        } else {
            return getExp(totalSupply(), totalStakedUnderlying).mantissa;
        }
    }

    function getMaxBurn(address account) public view returns (uint256) {
        // calculate maximum claimable.
        uint256 maxBurn = 0;
        for (uint256 i = 0; i < userStakeData[account].length; i++) {
            StakeData memory sd = userStakeData[account][i];
            if (sd.expireTime < block.timestamp) {
                maxBurn += sd.staked - sd.unstaked;
            }
        }
        return maxBurn;
    }

    /** Replenish lending pool */
    /**
        When the lending pool run out of money, replenish the pool with money from the provisioning pool. 
    require(msg.sender == address(zBond) || msg.sender == address(auctionMarket));
        require(amount <= address(this).balance, "provisioning: insufficient funds");
     */
    function replenishLendingPoolInternal(uint256 amount) internal {
        totalStakedUnderlying -= amount;
        doTransferOut(address(zBond), amount);
    }

    function doTransferIn(address sender, uint256 amount) internal {
        underlying.transferFrom(sender, address(this), amount);
    }

    function doTransferOut(address receiver, uint256 amount) internal {
        underlying.transferFrom(address(this), receiver, amount);
    }

    function getCashBalance() external view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /** Replenish lending pool */
    /**
        When the lending pool run out of money, replenish the pool with money from the provisioning pool. 
    require(msg.sender == address(zBondETH) || msg.sender == address(auctionMarket));
        require(amount <= address(this).balance, "provisioning: insufficient funds");
     */
    function replenishLendingPool(uint256 amount) external {
        require(
            msg.sender == address(zBond) || msg.sender == address(auctionMarket)
        );
        require(
            amount <= address(this).balance,
            "provisioning: insufficient funds"
        );
        replenishLendingPoolInternal(amount);
    }

    function stake(uint256 amount, uint256 time) external returns (uint256) {
        return stakeInternal(amount, time);
    }

    function repayAndSeize(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) public returns (uint256 actualRepayAmount) {
        (zBond).liquidateOverdueBorrow(liquidator, borrower, id);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    struct Double {
        uint256 mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint256 scalar)
        internal
        pure
        returns (uint256)
    {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return (truncate(product) + addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint224)
    {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        return Exp({mantissa: (a.mantissa + b.mantissa)});
    }

    function add_(Double memory a, Double memory b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: (a.mantissa + b.mantissa)});
    }

    function sub_(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        return Exp({mantissa: a.mantissa - b.mantissa});
    }

    function sub_(Double memory a, Double memory b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: a.mantissa - b.mantissa});
    }

    function mul_(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        return Exp({mantissa: (a.mantissa * b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: a.mantissa * b});
    }

    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return (a * b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: (a.mantissa * b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint256 b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: a.mantissa * b});
    }

    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return (a * b.mantissa) / doubleScale;
    }

    function div_(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        return Exp({mantissa: ((a.mantissa * expScale) / b.mantissa)});
    }

    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: (a.mantissa / b)});
    }

    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return ((a * expScale) / b.mantissa);
    }

    function div_(Double memory a, Double memory b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: ((a.mantissa * doubleScale) / b.mantissa)});
    }

    function div_(Double memory a, uint256 b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: (a.mantissa / b)});
    }

    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return ((a * doubleScale) / b.mantissa);
    }

    function fraction(uint256 a, uint256 b)
        internal
        pure
        returns (Double memory)
    {
        return Double({mantissa: ((a * doubleScale) / b)});
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.0;

import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint256 num, uint256 denom)
        internal
        pure
        returns (Exp memory)
    {
        uint256 scaledNumerator = num * expScale;
        uint256 rational = scaledNumerator / denom;
        return (Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        uint256 result = a.mantissa + b.mantissa;

        return (Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        uint256 result = a.mantissa - b.mantissa;

        return (Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar)
        internal
        pure
        returns (Exp memory)
    {
        uint256 scaledMantissa = a.mantissa * scalar;

        return Exp({mantissa: scaledMantissa});
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint256 scalar)
        internal
        pure
        returns (uint256)
    {
        Exp memory product = mulScalar(a, scalar);

        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mulScalar(a, scalar);

        return truncate(product) + addend;
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar)
        internal
        pure
        returns (Exp memory)
    {
        uint256 descaledMantissa = (a.mantissa / scalar);

        return (Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (Exp memory)
    {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        uint256 numerator = (expScale * scalar);
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (uint256)
    {
        Exp memory fraction = divScalarByExp(scalar, divisor);

        return (truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        uint256 doubleScaledProduct = (a.mantissa * b.mantissa);

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        uint256 doubleScaledProductWithHalfScale = (halfExpScale +
            doubleScaledProduct);

        uint256 product = (doubleScaledProductWithHalfScale / expScale);

        return (Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint256 a, uint256 b) internal pure returns (Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (Exp memory) {
        Exp memory ab = mulExp(a, b);
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Exp memory)
    {
        return getExp(a.mantissa, b.mantissa);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CNftInterface.sol";

abstract contract NftPriceOracle {
    /// @notice Indicator that this is a NftPriceOracle contract (for inspection)
    bool public constant isNftPriceOracle = true;

    /**
     * @notice Get the underlying price of a cNft asset
     * @param cNft The cNft to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(CNftInterface cNft)
        external
        view
        virtual
        returns (uint256);
}