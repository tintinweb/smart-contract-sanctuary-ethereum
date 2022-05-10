// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./MToken.sol";
import "./SupervisorInterface.sol";
import "./SupervisorStorage.sol";
import "./Governance/Mnt.sol";

/**
 * @title Minterest Supervisor Contract
 * @author Minterest
 */
contract Supervisor is SupervisorV1Storage, SupervisorInterface {
    using SafeCast for uint256;

    /// @notice Emitted when an admin supports a market
    event MarketListed(MToken mToken);

    /// @notice Emitted when an account enable a market
    event MarketEnabledAsCollateral(MToken mToken, address account);

    /// @notice Emitted when an account disable a market
    event MarketDisabledAsCollateral(MToken mToken, address account);

    /// @notice Emitted when a utilisation factor is changed by admin
    event NewUtilisationFactor(
        MToken mToken,
        uint256 oldUtilisationFactorMantissa,
        uint256 newUtilisationFactorMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when buyback is changed
    event NewBuyback(Buyback oldBuyback, Buyback newBuyback);

    /// @notice Emitted when EmissionBooster contract is installed
    event NewEmissionBooster(EmissionBooster emissionBooster);

    /// @notice Emitted when Business Development System contract is installed
    event NewBusinessDevelopmentSystem(BDSystem oldBDSystem, BDSystem newBDSystem);

    /// @notice Event emitted when whitelist is changed
    event NewWhitelist(WhitelistInterface oldWhitelist, WhitelistInterface newWhitelist);

    /// @notice Emitted when liquidator is changed
    event NewLiquidator(Liquidation oldLiquidator, Liquidation newLiquidator);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event MarketActionPaused(MToken mToken, string action, bool pauseState);

    /// @notice Emitted when a new supply MNT emission rate is calculated for a market
    event MntSupplyEmissionRateUpdated(MToken indexed mToken, uint256 newSupplyEmissionRate);

    /// @notice Emitted when a new borrow MNT emission rate is calculated for a market
    event MntBorrowEmissionRateUpdated(MToken indexed mToken, uint256 newBorrowEmissionRate);

    /// @notice Emitted when liquidation fee is changed by admin
    event NewLiquidationFee(MToken marketAddress, uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /// @notice Emitted when MNT is distributed to a supplier
    event DistributedSupplierMnt(
        MToken indexed mToken,
        address indexed supplier,
        uint256 mntDelta,
        uint256 mntSupplyIndex
    );

    /// @notice Emitted when MNT is distributed to a borrower
    event DistributedBorrowerMnt(
        MToken indexed mToken,
        address indexed borrower,
        uint256 mntDelta,
        uint256 mntBorrowIndex
    );

    /// @notice Emitted when MNT is withdrew to a holder
    event WithdrawnMnt(address indexed holder, uint256 withdrewAmount);

    /// @notice Emitted when MNT is distributed to a business development representative
    event DistributedRepresentativeMnt(MToken indexed mToken, address indexed representative, uint256 mntDelta);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(MToken indexed mToken, uint256 newBorrowCap);

    /// @notice Emitted when MNT is granted by admin
    event MntGranted(address recipient, uint256 amount);

    /// @notice Emitted when withdraw allowance changed
    event WithdrawAllowanceChanged(address owner, address withdrawer, bool allowed);

    /// @notice The initial MNT index for a market
    uint224 public constant mntInitialIndex = 1e36;

    // No utilisationFactorMantissa may exceed this value
    uint256 public constant utilisationFactorMaxMantissa = 0.9e18; // 0.9

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    function initialize(address admin_) external {
        require(initializedVersion == 0, ErrorCodes.SECOND_INITIALIZATION);
        initializedVersion = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);
    }

    /***  Manage your collateral assets ***/

    /**
     * @notice Returns the assets an account has enabled as collateral
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has enabled as collateral
     */
    function getAccountAssets(address account) external view returns (MToken[] memory) {
        return accountAssets[account];
    }

    /**
     * @notice Returns whether the given account is enabled as collateral in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, MToken mToken) external view returns (bool) {
        return markets[address(mToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled as collateral
     */
    function enableAsCollateral(address[] memory mTokens) external override {
        uint256 len = mTokens.length;
        for (uint256 i = 0; i < len; i++) {
            enableMarketAsCollateralInternal(MToken(mTokens[i]), msg.sender);
        }
    }

    /**
     * @dev Add the market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enable as collateral
     * @param account The address of the account to modify
     */
    function enableMarketAsCollateralInternal(MToken mToken, address account) internal {
        Market storage marketToEnableAsCollateral = markets[address(mToken)];
        require(marketToEnableAsCollateral.isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (marketToEnableAsCollateral.accountMembership[account]) {
            return; // already joined
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if particular market is enabled for an account
        marketToEnableAsCollateral.accountMembership[account] = true;
        accountAssets[account].push(mToken);

        emit MarketEnabledAsCollateral(mToken, account);
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     */
    function disableAsCollateral(address mTokenAddress) external override {
        MToken mToken = MToken(mTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        (uint256 tokensHeld, uint256 amountOwed, ) = mToken.getAccountSnapshot(msg.sender);

        /* Fail if the sender has a borrow balance */
        require(amountOwed == 0, ErrorCodes.BALANCE_OWED);

        /* Fail if the sender is not permitted to redeem all of their tokens */
        beforeRedeemInternal(mTokenAddress, msg.sender, tokensHeld);

        Market storage marketToDisable = markets[address(mToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToDisable.accountMembership[msg.sender]) {
            return;
        }

        /* Set mToken account membership to false */
        delete marketToDisable.accountMembership[msg.sender];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        MToken[] memory accountAssetList = accountAssets[msg.sender];
        uint256 len = accountAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (accountAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        MToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketDisabledAsCollateral(mToken, msg.sender);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Makes checks if the account should be allowed to lend tokens in the given market
     * @param mToken The market to verify the lend against
     * @param lender The account which would get the lent tokens
     * @param wrapBalance Wrap balance of lender account before lend
     */
    // slither-disable-next-line reentrancy-benign
    function beforeLend(
        address mToken,
        address lender,
        uint256 wrapBalance
    ) external override whitelistMode(lender) {
        // Bells and whistles to notify user - operation is paused.
        require(!lendKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (wrapBalance == 0) {
            enableMarketAsCollateralInternal(MToken(mToken), lender);
        }

        // Trigger Emission system
        updateMntSupplyIndex(mToken);
        //slither-disable-next-line reentrancy-events
        distributeSupplierMnt(mToken, lender);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market and triggers emission system
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     */
    //slither-disable-next-line reentrancy-benign
    function beforeRedeem(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) external override nonReentrant whitelistMode(redeemer) {
        beforeRedeemInternal(mToken, redeemer, redeemTokens);

        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, redeemer);
    }

    /**
     * @dev Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     */
    function beforeRedeemInternal(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[mToken].accountMembership[redeemer]) {
            return;
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (, uint256 shortfall) = getHypotheticalAccountLiquidity(redeemer, MToken(mToken), redeemTokens, 0);
        require(shortfall <= 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external pure override {
        // Require tokens is zero or amount is also zero
        require(redeemTokens > 0 || redeemAmount == 0, ErrorCodes.INVALID_REDEEM);
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     */
    //slither-disable-next-line reentrancy-benign
    function beforeBorrow(
        address mToken,
        address borrower,
        uint256 borrowAmount
    ) external override nonReentrant whitelistMode(borrower) {
        // Bells and whistles to notify user - operation is paused.
        require(!borrowKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        if (!markets[mToken].accountMembership[borrower]) {
            // only mTokens may call beforeBorrow if borrower not in market
            require(msg.sender == mToken, ErrorCodes.INVALID_SENDER);

            // attempt to enable market for the borrower
            enableMarketAsCollateralInternal(MToken(msg.sender), borrower);

            // it should be impossible to break the important invariant
            assert(markets[mToken].accountMembership[borrower]);
        }

        require(oracle.getUnderlyingPrice(MToken(mToken)) > 0, ErrorCodes.INVALID_PRICE);

        uint256 borrowCap = borrowCaps[mToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = MToken(mToken).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(nextTotalBorrows < borrowCap, ErrorCodes.BORROW_CAP_REACHED);
        }

        (, uint256 shortfall) = getHypotheticalAccountLiquidity(borrower, MToken(mToken), 0, borrowAmount);
        require(shortfall <= 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        // Trigger Emission system
        uint224 borrowIndex = MToken(mToken).borrowIndex().toUint224();
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMnt(mToken, borrower, borrowIndex);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param borrower The account which would borrowed the asset
     */
    //slither-disable-next-line reentrancy-benign
    function beforeRepayBorrow(address mToken, address borrower)
        external
        override
        nonReentrant
        whitelistMode(borrower)
    {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        // Trigger Emission system
        uint224 borrowIndex = MToken(mToken).borrowIndex().toUint224();
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMnt(mToken, borrower, borrowIndex);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur (auto liquidation process)
     * @param mToken Asset which was used as collateral and will be seized
     * @param liquidator_ The address of liquidator contract
     * @param borrower The address of the borrower
     */
    //slither-disable-next-line reentrancy-benign
    function beforeAutoLiquidationSeize(
        address mToken,
        address liquidator_,
        address borrower
    ) external override nonReentrant {
        isLiquidator(liquidator_);
        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, borrower);
    }

    /**
     * @notice Checks if the address is the Liquidation contract
     * @dev Used in liquidation process
     * @param liquidator_ Prospective address of the Liquidation contract
     */
    function isLiquidator(address liquidator_) public view override {
        require(liquidator == Liquidation(liquidator_), ErrorCodes.UNRELIABLE_LIQUIDATOR);
    }

    /**
     * @notice Checks if the sender should be allowed to repay borrow in the given market (auto liquidation process)
     * @param liquidator_ The address of liquidator contract
     * @param borrower_ The account which borrowed the asset
     * @param mToken_ The market to verify the repay against
     * @param borrowIndex_ Accumulator of the total earned interest rate since the opening of the market
     */
    //slither-disable-next-line reentrancy-benign
    function beforeAutoLiquidationRepay(
        address liquidator_,
        address borrower_,
        address mToken_,
        uint224 borrowIndex_
    ) external override nonReentrant {
        isLiquidator(liquidator_);
        //slither-disable-next-line reentrancy-events
        updateMntBorrowIndex(mToken_, borrowIndex_);
        distributeBorrowerMnt(mToken_, borrower_, borrowIndex_);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-no-eth
    function beforeTransfer(
        address mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external override nonReentrant {
        // Bells and whistles to notify user - operation is paused.
        require(!transferKeeperPaused, ErrorCodes.OPERATION_PAUSED);

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        beforeRedeemInternal(mToken, src, transferTokens);

        // Trigger Emission system
        //slither-disable-next-line reentrancy-events
        updateMntSupplyIndex(mToken);
        distributeSupplierMnt(mToken, src);
        distributeSupplierMnt(mToken, dst);
    }

    /**
     * @notice Makes checks before flash loan in MToken
     * @param mToken The address of the token
     * receiver - The address of the loan receiver
     * amount - How much tokens to flash loan
     * fee - Flash loan fee
     */
    function beforeFlashLoan(
        address mToken,
        address, /* receiver */
        uint256, /* amount */
        uint256 /* fee */
    ) external view override {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(!flashLoanKeeperPaused[mToken], ErrorCodes.OPERATION_PAUSED);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 mTokenBalance;
        uint256 borrowBalance;
        uint256 utilisationFactor;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 tokensToDenom;
    }

    /**
     * @notice Calculate account liquidity in USD related to utilisation factors of underlying assets
     * @return (USD value above total utilisation requirements of all assets,
     *           USD value below total utilisation requirements of all assets)
     */
    function getAccountLiquidity(address account) external view returns (uint256, uint256) {
        return getHypotheticalAccountLiquidity(account, MToken(address(0)), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        MToken mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        // For each asset the account is in
        MToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            MToken asset = assets[i];

            // Read the balances and exchange rate from the mToken
            //slither-disable-next-line calls-loop
            (vars.mTokenBalance, vars.borrowBalance, vars.exchangeRate) = asset.getAccountSnapshot(account);
            vars.utilisationFactor = markets[address(asset)].utilisationFactorMantissa;

            // Get the normalized price of the asset
            //slither-disable-next-line calls-loop
            vars.oraclePrice = oracle.getUnderlyingPrice(asset);
            require(vars.oraclePrice > 0, ErrorCodes.INVALID_PRICE);

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom =
                (((vars.utilisationFactor * vars.exchangeRate) / EXP_SCALE) * vars.oraclePrice) /
                EXP_SCALE;

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral += (vars.tokensToDenom * vars.mTokenBalance) / EXP_SCALE;

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects += (vars.oraclePrice * vars.borrowBalance) / EXP_SCALE;

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects += (vars.tokensToDenom * redeemTokens) / EXP_SCALE;

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects += (vars.oraclePrice * borrowAmount) / EXP_SCALE;
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Get liquidationFeeMantissa and utilisationFactorMantissa for market
     * @param market Market for which values are obtained
     * @return (liquidationFeeMantissa, utilisationFactorMantissa)
     */
    function getMarketData(MToken market) external view returns (uint256, uint256) {
        return (markets[address(market)].liquidationFeeMantissa, markets[address(market)].utilisationFactorMantissa);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new price oracle for the supervisor
     * @dev Admin function to set a new price oracle
     */
    function setPriceOracle(PriceOracle newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PriceOracle oldOracle = oracle;
        oracle = newOracle;
        emit NewPriceOracle(oldOracle, newOracle);
    }

    /**
     * @notice Sets a new buyback for the supervisor
     * @dev Admin function to set a new buyback
     */
    function setBuyback(Buyback newBuyback) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Buyback oldBuyback = buyback;
        buyback = newBuyback;
        emit NewBuyback(oldBuyback, newBuyback);
    }

    /**
     * @notice Sets a new emissionBooster for the supervisor
     * @dev Admin function to set a new EmissionBooster. Can only be installed once.
     */
    function setEmissionBooster(EmissionBooster _emissionBooster) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(Address.isContract(address(_emissionBooster)), ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE);
        require(address(emissionBooster) == address(0), ErrorCodes.CONTRACT_ALREADY_SET);
        emissionBooster = _emissionBooster;
        emit NewEmissionBooster(emissionBooster);
    }

    /// @notice function to set BDSystem contract
    /// @param newBDSystem_ new Business Development system contract address
    function setBDSystem(BDSystem newBDSystem_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BDSystem oldBDSystem = bdSystem;
        bdSystem = newBDSystem_;
        emit NewBusinessDevelopmentSystem(oldBDSystem, newBDSystem_);
    }

    /*
     * @notice Sets a new whitelist for the supervisor
     * @dev Admin function to set a new whitelist
     */
    function setWhitelist(WhitelistInterface newWhitelist_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        WhitelistInterface oldWhitelist = whitelist;
        whitelist = newWhitelist_;
        emit NewWhitelist(oldWhitelist, newWhitelist_);
    }

    /**
     * @notice Sets a new liquidator for the supervisor
     * @dev Admin function to set a new liquidation contract
     */
    function setLiquidator(Liquidation newLiquidator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Liquidation oldLiquidator = liquidator;
        liquidator = newLiquidator;
        emit NewLiquidator(oldLiquidator, newLiquidator);
    }

    /**
     * @notice Sets the utilisationFactor for a market
     * @dev Admin function to set per-market utilisationFactor
     * @param mToken The market to set the factor on
     * @param newUtilisationFactorMantissa The new utilisation factor, scaled by 1e18
     */
    function setUtilisationFactor(MToken mToken, uint256 newUtilisationFactorMantissa) external onlyRole(TIMELOCK) {
        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        // Check utilisation factor <= 0.9
        require(
            newUtilisationFactorMantissa <= utilisationFactorMaxMantissa,
            ErrorCodes.INVALID_UTILISATION_FACTOR_MANTISSA
        );

        // If utilisation factor = 0 than price can be any. Otherwise price must be > 0.
        require(newUtilisationFactorMantissa == 0 || oracle.getUnderlyingPrice(mToken) > 0, ErrorCodes.INVALID_PRICE);

        // Set market's utilisation factor to new utilisation factor, remember old value
        uint256 oldUtilisationFactorMantissa = market.utilisationFactorMantissa;
        market.utilisationFactorMantissa = newUtilisationFactorMantissa;

        // Emit event with asset, old utilisation factor, and new utilisation factor
        emit NewUtilisationFactor(mToken, oldUtilisationFactorMantissa, newUtilisationFactorMantissa);
    }

    /**
     * @notice Sets the liquidationFee for a market
     * @dev Admin function to set per-market liquidationFee
     * @param mToken The market to set the fee on
     * @param newLiquidationFeeMantissa The new liquidation fee, scaled by 1e18
     */
    function setLiquidationFee(MToken mToken, uint256 newLiquidationFeeMantissa) external onlyRole(TIMELOCK) {
        require(newLiquidationFeeMantissa > 0, ErrorCodes.LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO);

        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        uint256 oldLiquidationFeeMantissa = market.liquidationFeeMantissa;
        market.liquidationFeeMantissa = newLiquidationFeeMantissa;

        emit NewLiquidationFee(mToken, oldLiquidationFeeMantissa, newLiquidationFeeMantissa);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed, also initialize MNT market state.
     * @dev Admin function to set isListed and add support for the market
     * @param mToken The address of the market (token) to list
     */
    function supportMarket(MToken mToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            mToken.supportsInterface(type(MTokenInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(!markets[address(mToken)].isListed, ErrorCodes.MARKET_ALREADY_LISTED);

        markets[address(mToken)].isListed = true;
        markets[address(mToken)].utilisationFactorMantissa = 0;
        markets[address(mToken)].liquidationFeeMantissa = 0;
        allMarkets.push(mToken);

        // Initialize supplyState and borrowState for market
        MntMarketState storage supplyState = mntSupplyState[address(mToken)];
        MntMarketState storage borrowState = mntBorrowState[address(mToken)];

        // Update market state indices
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = mntInitialIndex;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = mntInitialIndex;
        }

        // Update market state block numbers
        supplyState.block = borrowState.block = uint32(getBlockNumber());

        emit MarketListed(mToken);
    }

    /**
     * @notice Set the given borrow caps for the given mToken markets.
     *         Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or gateKeeper function to set the borrow caps.
     *      A borrow cap of 0 corresponds to unlimited borrowing.
     * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set.
     *                      A value of 0 corresponds to unlimited borrowing.
     */
    function setMarketBorrowCaps(MToken[] calldata mTokens, uint256[] calldata newBorrowCaps)
        external
        onlyRole(GATEKEEPER)
    {
        uint256 numMarkets = mTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, ErrorCodes.INVALID_MTOKENS_OR_BORROW_CAPS);

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[address(mTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    function setLendPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        lendKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "Lend", state);
        return state;
    }

    function setBorrowPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        borrowKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "Borrow", state);
        return state;
    }

    function setFlashLoanPaused(MToken mToken, bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        flashLoanKeeperPaused[address(mToken)] = state;
        emit MarketActionPaused(mToken, "FlashLoan", state);
        return state;
    }

    function setTransferPaused(bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        transferKeeperPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function setWithdrawMntPaused(bool state) external onlyRole(GATEKEEPER) returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || state, ErrorCodes.ADMIN_ONLY); // Only admin can unpause
        withdrawMntKeeperPaused = state;
        emit ActionPaused("WithdrawMnt", state);
        return state;
    }

    /*** Mnt Distribution ***/

    /**
     * @dev Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     */
    //slither-disable-next-line reentrancy-no-eth
    function setMntEmissionRates(
        MToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external onlyRole(TIMELOCK) nonReentrant {
        Market storage market = markets[address(mToken)];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);
        if (mntSupplyEmissionRate[address(mToken)] != newMntSupplyEmissionRate) {
            // Supply emission rate updated so let's update supply state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            //slither-disable-next-line reentrancy-events
            updateMntSupplyIndex(address(mToken));

            // Update emission rate and emit event
            mntSupplyEmissionRate[address(mToken)] = newMntSupplyEmissionRate;
            emit MntSupplyEmissionRateUpdated(mToken, newMntSupplyEmissionRate);
        }

        if (mntBorrowEmissionRate[address(mToken)] != newMntBorrowEmissionRate) {
            // Borrow emission rate updated so let's update borrow state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            uint224 borrowIndex = mToken.borrowIndex().toUint224();
            updateMntBorrowIndex(address(mToken), borrowIndex);

            // Update emission rate and emit event
            mntBorrowEmissionRate[address(mToken)] = newMntBorrowEmissionRate;
            emit MntBorrowEmissionRateUpdated(mToken, newMntBorrowEmissionRate);
        }
    }

    /**
     * @dev Calculates the new state of the market.
     * @param state The block number the index was last updated at and the market's last updated mntBorrowIndex
     * or mntSupplyIndex in this block
     * @param emissionRate MNT rate that each market currently receives (supply or borrow)
     * @param totalBalance Total market balance (totalSupply or totalBorrow)
     * Note: this method doesn't return anything, it only mutates memory variable `state`.
     */
    function calculateUpdatedMarketState(
        MntMarketState memory state,
        uint256 emissionRate,
        uint256 totalBalance
    ) internal view {
        uint256 blockNumber = getBlockNumber();

        if (emissionRate > 0) {
            uint256 deltaBlocks = blockNumber - state.block;
            uint256 mntAccrued_ = deltaBlocks * emissionRate;
            uint256 ratio = totalBalance > 0 ? (mntAccrued_ * DOUBLE_SCALE) / totalBalance : 0;
            // index = lastUpdatedIndex + deltaBlocks * emissionRate / amount
            state.index += ratio.toUint224();
        }

        state.block = uint32(blockNumber);
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntSupplyIndex(address mToken) internal view returns (MntMarketState memory supplyState) {
        supplyState = mntSupplyState[mToken];
        //slither-disable-next-line calls-loop
        calculateUpdatedMarketState(supplyState, mntSupplyEmissionRate[mToken], MToken(mToken).totalSupply());
        return supplyState;
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntBorrowIndex(address mToken, uint224 marketBorrowIndex)
        internal
        view
        returns (MntMarketState memory borrowState)
    {
        borrowState = mntBorrowState[mToken];
        //slither-disable-next-line calls-loop
        uint256 borrowAmount = (MToken(mToken).totalBorrows() * EXP_SCALE) / marketBorrowIndex;
        calculateUpdatedMarketState(borrowState, mntBorrowEmissionRate[mToken], borrowAmount);
        return borrowState;
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT supply index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT supply index to update
     */
    function updateMntSupplyIndex(address mToken) internal {
        uint32 lastUpdatedBlock = mntSupplyState[mToken].block;
        /* Short-circuit. Indexes already updated */
        //slither-disable-next-line incorrect-equality
        if (lastUpdatedBlock == getBlockNumber()) return;

        //slither-disable-next-line calls-loop
        if (emissionBooster != EmissionBooster(address(0)) && emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntSupplyState[mToken].index;
            MntMarketState memory currentState = getUpdatedMntSupplyIndex(mToken);
            mntSupplyState[mToken] = currentState;
            //slither-disable-next-line calls-loop
            emissionBooster.updateSupplyIndexesHistory(
                MToken(mToken),
                lastUpdatedBlock,
                lastUpdatedIndex,
                currentState.index
            );
        } else {
            mntSupplyState[mToken] = getUpdatedMntSupplyIndex(mToken);
        }
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT borrow index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT borrow index to update
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    function updateMntBorrowIndex(address mToken, uint224 marketBorrowIndex) internal {
        uint32 lastUpdatedBlock = mntBorrowState[mToken].block;
        /* Short-circuit. Indexes already updated */
        //slither-disable-next-line incorrect-equality
        if (lastUpdatedBlock == getBlockNumber()) return;

        //slither-disable-next-line calls-loop
        if (emissionBooster != EmissionBooster(address(0)) && emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntBorrowState[mToken].index;
            MntMarketState memory currentState = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
            mntBorrowState[mToken] = currentState;
            //slither-disable-next-line calls-loop
            emissionBooster.updateBorrowIndexesHistory(
                MToken(mToken),
                lastUpdatedBlock,
                lastUpdatedIndex,
                currentState.index
            );
        } else {
            mntBorrowState[mToken] = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
        }
    }

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(MToken market) external returns (uint224, uint224) {
        MntMarketState memory supplyState = getUpdatedMntSupplyIndex(address(market));
        mntSupplyState[address(market)] = supplyState;

        uint224 borrowIndex = market.borrowIndex().toUint224();
        MntMarketState memory borrowState = getUpdatedMntBorrowIndex(address(market), borrowIndex);
        mntBorrowState[address(market)] = borrowState;

        return (supplyState.index, borrowState.index);
    }

    /**
     * @dev Calculate MNT accrued by a supplier. The calculation takes into account business development system and
     * NFT emission boosts. NFT emission boost doesn't work with liquidity provider emission boost at the same time.
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MNT to
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-events
    function distributeSupplierMnt(address mToken, address supplier) internal {
        uint32 currentBlock = uint32(getBlockNumber());
        uint224 supplyIndex = mntSupplyState[mToken].index;
        uint32 supplierLastUpdatedBlock = mntSupplierState[mToken][supplier].block;
        uint224 supplierIndex = mntSupplierState[mToken][supplier].index;

        if (supplierIndex == 0 && supplyIndex >= mntInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with MNT accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = mntInitialIndex;
            supplierLastUpdatedBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        mntSupplierState[mToken][supplier] = MntMarketAccountState({index: supplyIndex, block: currentBlock});
        //slither-disable-next-line calls-loop
        uint256 supplierTokens = MToken(mToken).balanceOf(supplier);

        uint256 deltaIndex = supplyIndex - supplierIndex;
        address representative = address(0);
        uint256 representativeBonus = 0;
        uint256 deltaIndexBoost = 0;

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
        if (address(bdSystem) != address(0)) {
            //slither-disable-next-line calls-loop
            (representative, representativeBonus, deltaIndexBoost) = bdSystem.calculateEmissionBoost(
                supplier,
                deltaIndex
            );
        }

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
        // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
        // slither-disable-next-line incorrect-equality
        if (deltaIndexBoost == 0 && emissionBooster != EmissionBooster(address(0))) {
            //slither-disable-next-line calls-loop
            deltaIndexBoost = emissionBooster.calculateEmissionBoost(
                MToken(mToken),
                supplier,
                supplierIndex,
                supplierLastUpdatedBlock,
                supplyIndex,
                true
            );
        }

        uint256 accrueDelta = (supplierTokens * (deltaIndex + deltaIndexBoost)) / DOUBLE_SCALE;

        if (accrueDelta > 0) {
            mntAccrued[supplier] += accrueDelta;
            emit DistributedSupplierMnt(MToken(mToken), supplier, accrueDelta, supplyIndex);

            if (representative != address(0)) {
                uint256 representativeAccruedDelta = (accrueDelta * representativeBonus) / EXP_SCALE;
                mntAccrued[representative] += representativeAccruedDelta;
                emit DistributedRepresentativeMnt(MToken(mToken), representative, representativeAccruedDelta);
            }
        }
    }

    /**
     * @dev Calculate MNT accrued by a borrower. The calculation takes into account business development system and
     * NFT emission boosts. NFT emission boost doesn't work with liquidity provider emission boost at the same time.
     * Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MNT to
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    //slither-disable-next-line reentrancy-benign,reentrancy-events
    function distributeBorrowerMnt(
        address mToken,
        address borrower,
        uint224 marketBorrowIndex
    ) internal {
        uint32 currentBlock = uint32(getBlockNumber());
        uint224 borrowIndex = mntBorrowState[mToken].index;
        uint32 borrowerLastUpdatedBlock = mntBorrowerState[mToken][borrower].block;
        uint224 borrowerIndex = mntBorrowerState[mToken][borrower].index;

        if (borrowerIndex == 0 && borrowIndex >= mntInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with MNT accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = mntInitialIndex;
            borrowerLastUpdatedBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        mntBorrowerState[mToken][borrower] = MntMarketAccountState({index: borrowIndex, block: currentBlock});
        //slither-disable-next-line calls-loop
        uint256 borrowerAmount = (MToken(mToken).borrowBalanceStored(borrower) * EXP_SCALE) / marketBorrowIndex;

        uint256 deltaIndex = borrowIndex - borrowerIndex;
        address representative = address(0);
        uint256 representativeBonus = 0;
        uint256 deltaIndexBoost = 0;

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
        if (address(bdSystem) != address(0)) {
            //slither-disable-next-line calls-loop
            (representative, representativeBonus, deltaIndexBoost) = bdSystem.calculateEmissionBoost(
                borrower,
                deltaIndex
            );
        }

        // Calculate change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
        // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
        // slither-disable-next-line incorrect-equality
        if (deltaIndexBoost == 0 && emissionBooster != EmissionBooster(address(0))) {
            //slither-disable-next-line calls-loop
            deltaIndexBoost = emissionBooster.calculateEmissionBoost(
                MToken(mToken),
                borrower,
                borrowerIndex,
                borrowerLastUpdatedBlock,
                borrowIndex,
                false
            );
        }

        uint256 accrueDelta = (borrowerAmount * (deltaIndex + deltaIndexBoost)) / DOUBLE_SCALE;

        if (accrueDelta > 0) {
            mntAccrued[borrower] += accrueDelta;
            emit DistributedBorrowerMnt(MToken(mToken), borrower, accrueDelta, borrowIndex);

            if (representative != address(0)) {
                uint256 representativeAccruedDelta = (accrueDelta * representativeBonus) / EXP_SCALE;
                mntAccrued[representative] += representativeAccruedDelta;
                emit DistributedRepresentativeMnt(MToken(mToken), representative, representativeAccruedDelta);
            }
        }
    }

    /**
     * @notice Updates market indices and distributes tokens (if any) for holder
     * @dev Updates indices and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param holder The address to distribute MNT for
     */
    function distributeAllMnt(address holder) external nonReentrant {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        return distributeMnt(holders, allMarkets, true, true);
    }

    /**
     * @notice Distribute all MNT accrued by the holders
     * @param holders The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    //slither-disable-next-line reentrancy-no-eth
    function distributeMnt(
        address[] memory holders,
        MToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) public {
        uint256 numberOfMTokens = mTokens.length;
        uint256 numberOfHolders = holders.length;

        for (uint256 i = 0; i < numberOfMTokens; i++) {
            MToken mToken = mTokens[i];
            require(markets[address(mToken)].isListed, ErrorCodes.MARKET_NOT_LISTED);

            for (uint256 j = 0; j < numberOfHolders; j++) {
                address holder = holders[j];
                if (borrowers) {
                    //slither-disable-next-line calls-loop
                    uint256 holderBorrowUnderlying = mToken.borrowBalanceStored(holder);
                    if (holderBorrowUnderlying > 0) {
                        //slither-disable-next-line calls-loop
                        uint224 borrowIndex = mToken.borrowIndex().toUint224();
                        //slither-disable-next-line reentrancy-events,reentrancy-benign
                        updateMntBorrowIndex(address(mToken), borrowIndex);
                        distributeBorrowerMnt(address(mToken), holders[j], borrowIndex);
                    }
                }

                if (suppliers) {
                    //slither-disable-next-line calls-loop
                    uint256 holderSupplyWrap = mToken.balanceOf(holder);
                    if (holderSupplyWrap > 0) {
                        updateMntSupplyIndex(address(mToken));
                        //slither-disable-next-line reentrancy-events,reentrancy-benign
                        distributeSupplierMnt(address(mToken), holder);
                    }
                }
            }
        }
    }

    /**
     * @param account The address of the account whose MNT are withdrawn
     * @param withdrawer The address of the withdrawer
     * @return true if `withdrawer` can withdraw MNT in behalf of `account`
     */
    function isWithdrawAllowed(address account, address withdrawer) public view returns (bool) {
        return withdrawAllowances[account][withdrawer];
    }

    /**
     * @notice Allow `withdrawer` to withdraw MNT on sender's behalf
     * @param withdrawer The address of the withdrawer
     */
    function allowWithdraw(address withdrawer) external {
        withdrawAllowances[msg.sender][withdrawer] = true;
        emit WithdrawAllowanceChanged(msg.sender, withdrawer, true);
    }

    /**
     * @notice Deny `withdrawer` from withdrawing MNT on sender's behalf
     * @param withdrawer The address of the withdrawer
     */
    function denyWithdraw(address withdrawer) external {
        withdrawAllowances[msg.sender][withdrawer] = false;
        emit WithdrawAllowanceChanged(msg.sender, withdrawer, false);
    }

    /**
     * @notice Withdraw mnt accrued by the holders for a given amounts
     * @dev If `amount_ == MaxUint256` withdraws all accrued MNT tokens.
     * @param holders The addresses to withdraw MNT for
     * @param amounts Amount of tokens to withdraw for every holder
     */
    function withdrawMnt(address[] memory holders, uint256[] memory amounts) external {
        require(!withdrawMntKeeperPaused, ErrorCodes.OPERATION_PAUSED);
        require(holders.length == amounts.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);

        // We are transferring MNT to the account. If there is not enough MNT, we do not perform the transfer all.
        // Also check withdrawal allowance
        for (uint256 j = 0; j < holders.length; j++) {
            address holder = holders[j];
            uint256 amount = amounts[j];
            require(holder == msg.sender || isWithdrawAllowed(holder, msg.sender), ErrorCodes.WITHDRAW_NOT_ALLOWED);
            if (amount == type(uint256).max) {
                amount = mntAccrued[holder];
            } else {
                require(amount <= mntAccrued[holder], ErrorCodes.INCORRECT_AMOUNT);
            }

            // slither-disable-next-line reentrancy-no-eth
            uint256 transferredAmount = amount - grantMntInternal(holder, amount);
            mntAccrued[holder] -= transferredAmount;
            //slither-disable-next-line reentrancy-events
            emit WithdrawnMnt(holder, transferredAmount);

            //slither-disable-next-line calls-loop
            if (buyback != Buyback(address(0))) buyback.restakeFor(holder);
        }
    }

    /**
     * @dev Transfer MNT to the account. If there is not enough MNT, we do not perform the transfer all.
     * @param account The address of the account to transfer MNT to
     * @param amount The amount of MNT to (possibly) transfer
     * @return The amount of MNT which was NOT transferred to the account
     */
    function grantMntInternal(address account, uint256 amount) internal returns (uint256) {
        Mnt mnt = Mnt(getMntAddress());
        //slither-disable-next-line calls-loop
        uint256 mntRemaining = mnt.balanceOf(address(this));
        if (amount > 0 && amount <= mntRemaining) {
            //slither-disable-next-line calls-loop
            require(mnt.transfer(account, amount));
            return 0;
        }
        return amount;
    }

    /*** Mnt Distribution Admin ***/

    /**
     * @notice Transfer MNT to the recipient
     * @dev Note: If there is not enough MNT, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer MNT to
     * @param amount The amount of MNT to (possibly) transfer
     */
    //slither-disable-next-line reentrancy-events
    function grantMnt(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 amountLeft = grantMntInternal(recipient, amount);
        require(amountLeft <= 0, ErrorCodes.INSUFFICIENT_MNT_FOR_GRANT);
        emit MntGranted(recipient, amount);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (MToken[] memory) {
        return allMarkets;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(SupervisorInterface).interfaceId || super.supportsInterface(interfaceId);
    }

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Return the address of the MNT token
     * @return The address of MNT
     */
    function getMntAddress() public view virtual returns (address) {
        return 0x95966457BbAd4391EdaC349a43Db5798625720B4;
    }

    /**
     * @dev Check protocol operation mode. In whitelist mode, only members from whitelist and who have Minterest NFT
      can work with protocol.
     */
    modifier whitelistMode(address account) {
        require(address(whitelist) == address(0) || whitelist.isWhitelisted(account), ErrorCodes.WHITELISTED_ONLY);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./SupervisorInterface.sol";
import "./MTokenInterfaces.sol";
import "./InterestRateModel.sol";
import "./ErrorCodes.sol";

/**
 * @title Minterest MToken Contract
 * @notice Abstract base for MTokens
 * @author Minterest
 */
contract MToken is MTokenInterface, MTokenStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /**
     * @notice Initialize the money market
     * @param supervisor_ The address of the Supervisor
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     * @param underlying_ The address of the underlying asset
     */
    function initialize(
        address admin_,
        SupervisorInterface supervisor_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IERC20 underlying_
    ) external {
        //slither-disable-next-line incorrect-equality
        require(accrualBlockNumber == 0 && borrowIndex == 0, ErrorCodes.SECOND_INITIALIZATION);

        // Set initial exchange rate
        require(initialExchangeRateMantissa_ > 0, ErrorCodes.ZERO_EXCHANGE_RATE);
        initialExchangeRateMantissa = initialExchangeRateMantissa_;

        // Set the supervisor
        _setSupervisor(supervisor_);

        // Initialize block number and borrow index (block number mocks depend on supervisor being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = EXP_SCALE; // = 1e18

        // Set the interest rate model (depends on block number / borrow index)
        setInterestRateModelFresh(interestRateModel_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);

        underlying = underlying_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        maxFlashLoanShare = 0.1e18; // 10%
        flashLoanFeeShare = 0.0005e18; // 0.05%
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    //slither-disable-next-line reentrancy-benign
    function transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        /* Do not allow self-transfers */
        require(src != dst, ErrorCodes.INVALID_DESTINATION);

        /* Fail if transfer not allowed */
        //slither-disable-next-line reentrancy-events
        supervisor.beforeTransfer(address(this), src, dst, tokens);

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[src] -= tokens;
        accountTokens[dst] += tokens;

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = startingAllowance - tokens;
        }

        emit Transfer(src, dst, tokens);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view override returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint256) {
        return (accountTokens[owner] * exchangeRateCurrent()) / EXP_SCALE;
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 mTokenBalance = accountTokens[account];
        uint256 borrowBalance = borrowBalanceStoredInternal(account);
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();
        return (mTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    //slither-disable-next-line dead-code
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view override returns (uint256) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view override returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                getCashPrior(),
                totalBorrows,
                totalProtocolInterest,
                protocolInterestFactorMantissa
            );
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view override returns (uint256) {
        return borrowBalanceStoredInternal(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return the calculated balance
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) return 0;

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        return (borrowSnapshot.principal * borrowIndex) / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override nonReentrant returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view override returns (uint256) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() internal view virtual returns (uint256) {
        if (totalTokenSupply <= 0) {
            /*
             * If there are no tokens lent:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalProtocolInterest) / totalTokenSupply
             */
            return ((getCashPrior() + totalBorrows - totalProtocolInterest) * EXP_SCALE) / totalTokenSupply;
        }
    }

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view override returns (uint256) {
        return getCashPrior();
    }

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public virtual override {
        /* Remember the initial block number */
        uint256 currentBlockNumber = getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) return;

        /* Read the previous values out of storage */
        uint256 cashPrior = getCashPrior();
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, totalBorrows, totalProtocolInterest);
        require(borrowRateMantissa <= borrowRateMaxMantissa, ErrorCodes.BORROW_RATE_TOO_HIGH);

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and protocol interest and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrows += interestAccumulated
         *  totalProtocolInterest += interestAccumulated * protocolInterestFactor
         *  borrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
         */
        uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
        uint256 interestAccumulated = (totalBorrows * simpleInterestFactor) / EXP_SCALE;
        totalBorrows += interestAccumulated;
        totalProtocolInterest += (interestAccumulated * protocolInterestFactorMantissa) / EXP_SCALE;
        borrowIndex = borrowIndexPrior + (borrowIndexPrior * simpleInterestFactor) / EXP_SCALE;

        accrualBlockNumber = currentBlockNumber;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndex, totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external override {
        accrueInterest();
        lendFresh(msg.sender, lendAmount, true);
    }

    /**
     * @notice Account supplies assets into the market and receives mTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param lender The address of the account which is supplying the assets
     * @param lendAmount The amount of the underlying asset to supply
     * @return actualLendAmount actual lend amount
     */
    function lendFresh(
        address lender,
        uint256 lendAmount,
        bool isERC20based
    ) internal nonReentrant returns (uint256 actualLendAmount) {
        uint256 wrapBalance = accountTokens[lender];
        supervisor.beforeLend(address(this), lender, wrapBalance);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        /*
         *  We call `doTransferIn` for the lender and the lendAmount.
         *  Note: The mToken must handle variations between ERC-20 underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the mToken holds an additional `actualLendAmount`
         *  of cash.
         */
        // slither-disable-next-line reentrancy-eth
        if (isERC20based) {
            actualLendAmount = doTransferIn(lender, lendAmount);
        } else {
            actualLendAmount = lendAmount;
        }
        /*
         * We get the current exchange rate and calculate the number of mTokens to be lent:
         *  lendTokens = actualLendAmount / exchangeRate
         */
        uint256 lendTokens = (actualLendAmount * EXP_SCALE) / exchangeRateMantissa;

        /*
         * We calculate the new total supply of mTokens and lender token balance, checking for overflow:
         *  totalTokenSupply = totalTokenSupply + lendTokens
         *  accountTokens = accountTokens[lender] + lendTokens
         */
        uint256 newTotalTokenSupply = totalTokenSupply + lendTokens;
        totalTokenSupply = newTotalTokenSupply;
        accountTokens[lender] = wrapBalance + lendTokens;

        emit Lend(lender, actualLendAmount, lendTokens, newTotalTokenSupply);
        emit Transfer(address(this), lender, lendTokens);
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external override {
        accrueInterest();
        redeemFresh(msg.sender, redeemTokens, 0, true);
    }

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external override {
        accrueInterest();
        redeemFresh(msg.sender, 0, redeemAmount, true);
    }

    /**
     * @notice Account redeems mTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokens The number of mTokens to redeem into underlying
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmount The number of underlying tokens to receive from redeeming mTokens
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    //slither-disable-next-line reentrancy-no-eth
    function redeemFresh(
        address redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount,
        bool isERC20based
    ) internal nonReentrant returns (uint256) {
        require(redeemTokens == 0 || redeemAmount == 0, ErrorCodes.REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO);

        /* exchangeRate = invoke Exchange Rate Stored() */
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        if (redeemTokens > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokens
             *  redeemAmount = redeemTokens * exchangeRateCurrent
             */
            redeemAmount = (redeemTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmount / exchangeRate
             *  redeemAmount = redeemAmount
             */
            redeemTokens = (redeemAmount * EXP_SCALE) / exchangeRateMantissa;
        }

        /* Fail if redeem not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeRedeem(address(this), redeemer, redeemTokens);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(accountTokens[redeemer] >= redeemTokens, ErrorCodes.REDEEM_TOO_MUCH);
        require(totalTokenSupply >= redeemTokens, ErrorCodes.INVALID_REDEEM);

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         *  totalSupplyNew = totalTokenSupply - redeemTokens
         */
        uint256 accountTokensNew = accountTokens[redeemer] - redeemTokens;
        uint256 totalSupplyNew = totalTokenSupply - redeemTokens;

        /* Fail gracefully if protocol has insufficient cash */
        require(getCashPrior() >= redeemAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        totalTokenSupply = totalSupplyNew;
        accountTokens[redeemer] = accountTokensNew;

        //slither-disable-next-line reentrancy-events
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, totalSupplyNew);

        if (isERC20based) doTransferOut(redeemer, redeemAmount);

        /* We call the defense hook */
        supervisor.redeemVerify(redeemAmount, redeemTokens);

        return redeemAmount;
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */

    //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
    function borrow(uint256 borrowAmount) external override {
        accrueInterest();
        borrowFresh(borrowAmount, true);
    }

    function borrowFresh(uint256 borrowAmount, bool isERC20based) internal nonReentrant {
        address borrower = msg.sender;

        /* Fail if borrow not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeBorrow(address(this), borrower, borrowAmount);

        /* Fail gracefully if protocol has insufficient underlying cash */
        require(getCashPrior() >= borrowAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsNew = borrowBalanceStoredInternal(borrower) + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        //slither-disable-next-line reentrancy-events
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);

        if (isERC20based) doTransferOut(borrower, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, msg.sender, repayAmount, true);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, repayAmount, true);
    }

    /**
     * @notice Borrows are repaid by another account (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned
     * @return actualRepayAmount the actual repayment amount
     */
    function repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount,
        bool isERC20based
    ) internal nonReentrant returns (uint256 actualRepayAmount) {
        /* Fail if repayBorrow not allowed */
        supervisor.beforeRepayBorrow(address(this), borrower);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower);

        if (repayAmount == type(uint256).max) {
            repayAmount = borrowBalance;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        if (isERC20based) {
            actualRepayAmount = doTransferIn(payer, repayAmount);
        } else {
            actualRepayAmount = repayAmount;
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint256 accountBorrowsNew = borrowBalance - actualRepayAmount;
        uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external override nonReentrant {
        // Fail if repayBorrow not allowed
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeAutoLiquidationRepay(msg.sender, borrower_, address(this), borrowIndex.toUint224());

        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(totalProtocolInterest >= repayAmount_, ErrorCodes.INSUFFICIENT_TOTAL_PROTOCOL_INTEREST);

        // We fetch the amount the borrower owes, with accumulated interest
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower_);

        accountBorrows[borrower_].principal = borrowBalance - repayAmount_;
        accountBorrows[borrower_].interestIndex = borrowIndex;
        totalBorrows -= repayAmount_;
        totalProtocolInterest -= repayAmount_;

        //slither-disable-next-line reentrancy-events
        emit AutoLiquidationRepayBorrow(
            borrower_,
            repayAmount_,
            accountBorrows[borrower_].principal,
            totalBorrows,
            totalProtocolInterest
        );
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(IERC20 token, address receiver_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != underlying, ErrorCodes.INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver_, balance);
    }

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    //slither-disable-next-line reentrancy-benign
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external nonReentrant {
        //slither-disable-next-line reentrancy-events
        supervisor.beforeAutoLiquidationSeize(address(this), msg.sender, borrower_);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        uint256 borrowerSeizeTokens;

        // Infinity means all account's collateral has to be burn.
        if (seizeUnderlyingAmount_ == type(uint256).max) {
            borrowerSeizeTokens = accountTokens[borrower_];
            seizeUnderlyingAmount_ = (borrowerSeizeTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            borrowerSeizeTokens = (seizeUnderlyingAmount_ * EXP_SCALE) / exchangeRateMantissa;
        }

        uint256 borrowerTokensNew = accountTokens[borrower_] - borrowerSeizeTokens;
        uint256 totalSupplyNew = totalTokenSupply - borrowerSeizeTokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[borrower_] = borrowerTokensNew;
        totalTokenSupply = totalSupplyNew;

        if (isLoanInsignificant_) {
            totalProtocolInterest = totalProtocolInterest + seizeUnderlyingAmount_;
            emit ProtocolInterestAdded(msg.sender, seizeUnderlyingAmount_, totalProtocolInterest);
        } else {
            doTransferOut(receiver_, seizeUnderlyingAmount_);
        }

        emit Seize(
            borrower_,
            receiver_,
            borrowerSeizeTokens,
            borrowerTokensNew,
            totalSupplyNew,
            seizeUnderlyingAmount_
        );
    }

    /*** Flash loans ***/

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view override returns (uint256) {
        return token == address(underlying) ? _maxFlashLoan() : 0;
    }

    function _maxFlashLoan() internal view returns (uint256) {
        return (getCashPrior() * maxFlashLoanShare) / EXP_SCALE;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * flashLoanFeeShare) / EXP_SCALE;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    // slither-disable-next-line reentrancy-benign
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        require(amount <= _maxFlashLoan(), ErrorCodes.FL_AMOUNT_IS_TOO_LARGE);

        accrueInterest();

        // Make supervisor checks
        uint256 fee = _flashFee(amount);
        supervisor.beforeFlashLoan(address(this), address(receiver), amount, fee);

        // Transfer lend amount to receiver and call its callback
        underlying.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_LOAN_SUCCESS,
            ErrorCodes.FL_CALLBACK_FAILED
        );

        // Transfer amount + fee back and check that everything was returned by token
        uint256 actualPullAmount = doTransferIn(address(receiver), amount + fee);
        require(actualPullAmount >= amount + fee, ErrorCodes.FL_PULL_AMOUNT_IS_TOO_LOW);

        // Fee is the protocol interest so we increase it
        totalProtocolInterest += fee;

        emit FlashLoanExecuted(address(receiver), amount, fee);

        return true;
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new supervisor for the market
     * @dev Admin function to set a new supervisor
     */
    function setSupervisor(SupervisorInterface newSupervisor) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSupervisor(newSupervisor);
    }

    function _setSupervisor(SupervisorInterface newSupervisor) internal {
        require(
            newSupervisor.supportsInterface(type(SupervisorInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );

        SupervisorInterface oldSupervisor = supervisor;
        supervisor = newSupervisor;
        emit NewSupervisor(oldSupervisor, newSupervisor);
    }

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa)
        external
        override
        onlyRole(TIMELOCK)
        nonReentrant
    {
        // Check newProtocolInterestFactor ≤ maxProtocolInterestFactor
        require(
            newProtocolInterestFactorMantissa <= protocolInterestFactorMaxMantissa,
            ErrorCodes.INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA
        );

        accrueInterest();

        uint256 oldProtocolInterestFactorMantissa = protocolInterestFactorMantissa;
        protocolInterestFactorMantissa = newProtocolInterestFactorMantissa;

        emit NewProtocolInterestFactor(oldProtocolInterestFactorMantissa, newProtocolInterestFactorMantissa);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external override nonReentrant {
        accrueInterest();
        addProtocolInterestInternal(msg.sender, addAmount_);
    }

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external override nonReentrant {
        supervisor.isLiquidator(msg.sender);
        addProtocolInterestInternal(payer_, addAmount_);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from payer_
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestInternal(address payer_, uint256 addAmount_) internal {
        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        uint256 actualAddAmount = doTransferIn(payer_, addAmount_);
        uint256 totalProtocolInterestNew = totalProtocolInterest + actualAddAmount;

        // Store protocolInterest[n+1] = protocolInterest[n] + actualAddAmount
        totalProtocolInterest = totalProtocolInterestNew;

        emit ProtocolInterestAdded(payer_, actualAddAmount, totalProtocolInterestNew);
    }

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     */
    function reduceProtocolInterest(uint256 reduceAmount, address receiver_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        accrueInterest();

        // Check if protocol has insufficient underlying cash
        require(getCashPrior() >= reduceAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);
        require(totalProtocolInterest >= reduceAmount, ErrorCodes.INVALID_REDUCE_AMOUNT);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        uint256 totalProtocolInterestNew = totalProtocolInterest - reduceAmount;
        totalProtocolInterest = totalProtocolInterestNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(receiver_, reduceAmount);

        emit ProtocolInterestReduced(receiver_, reduceAmount, totalProtocolInterestNew);
    }

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        accrueInterest();
        setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal {
        require(
            newInterestRateModel.supportsInterface(type(InterestRateModel).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        InterestRateModel oldInterestRateModel = interestRateModel;
        interestRateModel = newInterestRateModel;

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     */
    function setFlashLoanMaxShare(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMax <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanMaxShare(maxFlashLoanShare, newMax);
        maxFlashLoanShare = newMax;
    }

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     */
    function setFlashLoanFeeShare(uint256 newFee) external onlyRole(TIMELOCK) {
        require(newFee <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanFee(flashLoanFeeShare, newFee);
        flashLoanFeeShare = newFee;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(from, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, ErrorCodes.TOKEN_TRANSFER_IN_UNDERFLOW);
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer`
     *      and returns an explanatory error code rather than reverting. If caller has not
     *      called checked protocol's balance, this may revert due to insufficient cash held
     *      in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address to, uint256 amount) internal virtual {
        underlying.safeTransfer(to, amount);
    }

    /**
     * @notice Admin call to delegate the votes of the MNT-like underlying
     * @param mntLikeDelegatee The address to delegate votes to
     * @dev MTokens whose underlying are not MntLike should revert here
     */
    function delegateMntLikeTo(address mntLikeDelegatee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MntLike(address(underlying)).delegate(mntLikeDelegatee);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(MTokenInterface).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC3156FlashLender).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface SupervisorInterface is IERC165 {
    /***  Manage your collateral assets ***/

    function enableAsCollateral(address[] calldata mTokens) external;

    function disableAsCollateral(address mToken) external;

    /*** Policy Hooks ***/

    function beforeLend(
        address mToken,
        address lender,
        uint256 wrapBalance
    ) external;

    function beforeRedeem(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) external;

    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external;

    function beforeBorrow(
        address mToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function beforeRepayBorrow(address mToken, address borrower) external;

    function beforeAutoLiquidationSeize(
        address mToken,
        address liquidator_,
        address borrower
    ) external;

    function beforeAutoLiquidationRepay(
        address liquidator,
        address borrower,
        address mToken,
        uint224 borrowIndex
    ) external;

    function beforeTransfer(
        address mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function beforeFlashLoan(
        address mToken,
        address receiver,
        uint256 amount,
        uint256 fee
    ) external;

    function isLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./MToken.sol";
import "./Oracles/PriceOracle.sol";
import "./Buyback.sol";
import "./BDSystem.sol";
import "./EmissionBooster.sol";
import "./Liquidation.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract SupervisorV1Storage is AccessControl, ReentrancyGuard {
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);
    uint256 internal constant EXP_SCALE = 1e18;
    uint256 internal constant DOUBLE_SCALE = 1e36;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => MToken[]) public accountAssets;

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint256 utilisationFactorMantissa;
        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        // Multiplier representing the additional collateral which is taken from borrowers
        // as a penalty for being liquidated
        uint256 liquidationFeeMantissa;
    }

    /**
     * @notice Official mapping of mTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The gate keeper can pause certain actions as a safety mechanism
     *  and can set borrowCaps to any number for any market.
     *  Actions which allow accounts to remove their own assets cannot be paused.
     *  Transfer can only be paused globally, not by market.
     *  Lowering the borrow cap could disable borrowing on the given market.
     */
    bool public transferKeeperPaused;
    bool public withdrawMntKeeperPaused;
    mapping(address => bool) public lendKeeperPaused;
    mapping(address => bool) public borrowKeeperPaused;
    mapping(address => bool) public flashLoanKeeperPaused;

    struct MntMarketState {
        // The market's last updated mntBorrowIndex or mntSupplyIndex
        uint224 index;
        // The block number the index was last updated at
        uint32 block;
    }

    struct MntMarketAccountState {
        // The account's last updated mntBorrowIndex or mntSupplyIndex
        uint224 index;
        // The block number in which the index for the account was last updated.
        uint32 block;
    }

    /// @notice A list of all markets
    MToken[] public allMarkets;

    /// @notice The rate at which MNT is distributed to the corresponding supply market (per block)
    mapping(address => uint256) public mntSupplyEmissionRate;

    /// @notice The rate at which MNT is distributed to the corresponding borrow market (per block)
    mapping(address => uint256) public mntBorrowEmissionRate;

    /// @notice The MNT market supply state for each market
    mapping(address => MntMarketState) public mntSupplyState;

    /// @notice The MNT market borrow state for each market
    mapping(address => MntMarketState) public mntBorrowState;

    /// @notice The MNT supply index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(address => mapping(address => MntMarketAccountState)) public mntSupplierState;

    /// @notice The MNT borrow index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(address => mapping(address => MntMarketAccountState)) public mntBorrowerState;

    /// @notice The MNT accrued but not yet transferred to each account
    mapping(address => uint256) public mntAccrued;

    // @notice Borrow caps enforced by beforeBorrow for each mToken address.
    //         Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice Allowances to withdraw MNT on behalf of others
    mapping(address => mapping(address => bool)) public withdrawAllowances;

    /// @notice Buyback contract that implements buy-back logic for all users
    Buyback public buyback;

    /// @notice EmissionBooster contract that provides boost logic for MNT distribution rewards
    EmissionBooster public emissionBooster;

    /// @notice Liquidation contract that can automatically liquidate accounts' insolvent loans
    Liquidation public liquidator;

    /// @notice Contract which manage access to main functionality
    WhitelistInterface public whitelist;

    /// @notice Contract to create agreement and calculate rewards for representative and liquidity provider
    BDSystem public bdSystem;

    uint8 internal initializedVersion;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./MntVotes.sol";

contract Mnt is ERC20, ERC20Permit, MntVotes {
    /// @notice Total number of tokens in circulation
    uint256 internal constant TOTAL_SUPPLY = 100_000_030e18; // 100,000,030 MNT

    constructor(address account, address admin) ERC20("Minterest", "MNT") ERC20Permit("Minterest") {
        _mint(account, uint256(TOTAL_SUPPLY));
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // The functions below are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, MntVotes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, MntVotes) {
        super._mint(to, amount);
    }

    //slither-disable-next-line dead-code
    function _burn(address, uint256) internal pure override(ERC20) {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./SupervisorInterface.sol";
import "./InterestRateModel.sol";
import "./WhitelistInterface.sol";

abstract contract MTokenStorage is AccessControl, ReentrancyGuard {
    uint256 internal constant EXP_SCALE = 1e18;
    bytes32 internal constant FLASH_LOAN_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    /**
     * @notice Underlying asset for this MToken
     */
    IERC20 public underlying;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for protocol interest
     */
    uint256 internal constant protocolInterestFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    SupervisorInterface public supervisor;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    uint256 public initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    uint256 public protocolInterestFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    uint256 public totalProtocolInterest;

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 internal totalTokenSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @param principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @param interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /// @dev Share of market's current underlying  token balance that can be used as flash loan (scaled by 1e18).
    uint256 public maxFlashLoanShare;

    /// @dev Share of flash loan amount that would be taken as fee (scaled by 1e18).
    uint256 public flashLoanFeeShare;
}

interface MTokenInterface is IERC20, IERC3156FlashLender, IERC165 {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalProtocolInterest
    );

    /**
     * @notice Event emitted when tokens are lended
     */
    event Lend(address lender, uint256 lendAmount, uint256 lendTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are seized
     */
    event Seize(
        address borrower,
        address receiver,
        uint256 seizeTokens,
        uint256 accountsTokens,
        uint256 totalSupply,
        uint256 seizeUnderlyingAmount
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
     * @notice Event emitted when a borrow is repaid during autoliquidation
     */
    event AutoLiquidationRepayBorrow(
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrowsNew,
        uint256 totalBorrowsNew,
        uint256 TotalProtocolInterestNew
    );

    /**
     * @notice Event emitted when flash loan is executed
     */
    event FlashLoanExecuted(address receiver, uint256 amount, uint256 fee);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when supervisor is changed
     */
    event NewSupervisor(SupervisorInterface oldSupervisor, SupervisorInterface newSupervisor);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the protocol interest factor is changed
     */
    event NewProtocolInterestFactor(
        uint256 oldProtocolInterestFactorMantissa,
        uint256 newProtocolInterestFactorMantissa
    );

    /**
     * @notice Event emitted when the flash loan max share is changed
     */
    event NewFlashLoanMaxShare(uint256 oldMaxShare, uint256 newMaxShare);

    /**
     * @notice Event emitted when the flash loan fee is changed
     */
    event NewFlashLoanFee(uint256 oldFee, uint256 newFee);

    /**
     * @notice Event emitted when the protocol interest are added
     */
    event ProtocolInterestAdded(address benefactor, uint256 addAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Event emitted when the protocol interest reduced
     */
    event ProtocolInterestReduced(address admin, uint256 reduceAmount, uint256 newTotalProtocolInterest);

    /*** User Interface ***/

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external;

    function lend(uint256 lendAmount) external;

    function redeem(uint256 redeemTokens) external;

    function redeemUnderlying(uint256 redeemAmount) external;

    function borrow(uint256 borrowAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    function autoLiquidationRepayBorrow(address borrower, uint256 repayAmount) external;

    function sweepToken(IERC20 token, address admin_) external;

    function addProtocolInterestBehalf(address payer, uint256 addAmount) external;

    /*** Admin Functions ***/

    function setSupervisor(SupervisorInterface newSupervisor) external;

    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    function setInterestRateModel(InterestRateModel newInterestRateModel) external;

    function addProtocolInterest(uint256 addAmount) external;
}

interface MntLike {
    function delegate(address delegatee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface InterestRateModel is IERC165 {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant WITHDRAW_NOT_ALLOWED = "E204";
    string internal constant MARKET_NOT_LISTED = "E205";
    string internal constant INSUFFICIENT_LIQUIDITY = "E206";
    string internal constant INVALID_SENDER = "E207";
    string internal constant BORROW_CAP_REACHED = "E208";
    string internal constant BALANCE_OWED = "E209";
    string internal constant UNRELIABLE_LIQUIDATOR = "E210";
    string internal constant INVALID_DESTINATION = "E211";
    string internal constant CONTRACT_DOES_NOT_SUPPORT_INTERFACE = "E212";
    string internal constant INSUFFICIENT_STAKE = "E213";
    string internal constant INVALID_DURATION = "E214";
    string internal constant INVALID_PERIOD_RATE = "E215";
    string internal constant EB_TIER_LIMIT_REACHED = "E216";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E217";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E218";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E219";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E220";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E221";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E222";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E223";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E224";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E225";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E226";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E227";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E228";
    string internal constant NO_VESTING_SCHEDULE = "E229";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E230";
    string internal constant SCHEDULE_START_IS_ZERO = "E231";
    string internal constant MNT_AMOUNT_IS_ZERO = "E232";
    string internal constant RECEIVER_ALREADY_LISTED = "E233";
    string internal constant RECEIVER_ADDRESS_CANNOT_BE_ZERO = "E234";
    string internal constant CURRENCY_ADDRESS_CANNOT_BE_ZERO = "E235";
    string internal constant INCORRECT_AMOUNT = "E236";
    string internal constant RECEIVER_NOT_IN_APPROVED_LIST = "E237";
    string internal constant MEMBERSHIP_LIMIT = "E238";
    string internal constant MEMBER_NOT_EXIST = "E239";
    string internal constant MEMBER_ALREADY_ADDED = "E240";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E241";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E242";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E243";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E244";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E245";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E246";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E247";
    string internal constant FL_CALLBACK_FAILED = "E248";
    string internal constant DD_UNSUPPORTED_TOKEN = "E249";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E250";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E251";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E252";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E253";
    string internal constant DD_MARKET_NOT_FOUND = "E254";
    string internal constant DD_ROUTER_NOT_FOUND = "E255";
    string internal constant DD_RECEIVER_NOT_FOUND = "E256";
    string internal constant DD_BOT_NOT_FOUND = "E257";
    string internal constant DD_ROUTER_ALREADY_SET = "E258";
    string internal constant DD_RECEIVER_ALREADY_SET = "E259";
    string internal constant DD_BOT_ALREADY_SET = "E260";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E261";
    string internal constant MV_BLOCK_NOT_YET_MINED = "E262";
    string internal constant MV_SIGNATURE_EXPIRED = "E263";
    string internal constant MV_INVALID_NONCE = "E264";
    string internal constant DD_EXPIRED_DEADLINE = "E265";
    string internal constant LQ_INVALID_DRR_ARRAY = "E266";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E267";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E268";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E269";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E270";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant INSUFFICIENT_FUNDS = "E321";
    string internal constant ORACLE_PRICE_EXPIRED = "E322";
    string internal constant TOKEN_NOT_FOUND = "E323";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E324";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E325";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E326";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E327";
    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant NEW_ORACLE_MISMATCH = "E406";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E407";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E408";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E409";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E411";
    string internal constant CONTRACT_ALREADY_SET = "E412";
    string internal constant INVALID_TOKEN = "E413";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E414";
    string internal constant INVALID_REDUCE_AMOUNT = "E415";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E416";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E417";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E418";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E419";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E420";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E421";
    string internal constant EC_INVALID_BOOSTS = "E422";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E423";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E424";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E425";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E426";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E427";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E428";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E429";
    string internal constant DELAY_LIST_LIMIT = "E430";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface WhitelistInterface is IERC165 {
    function addMember(address _newAccount) external;

    function removeMember(address _accountToRemove) external;

    function turnOffWhitelistMode() external;

    function setMaxMembers(uint256 _newThreshold) external;

    function isWhitelisted(address _who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "../MToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice Get the underlying price of a mToken asset
    /// @param mToken The mToken to get the underlying price of
    /// @return The underlying asset price mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function getUnderlyingPrice(MToken mToken) external view virtual returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Supervisor.sol";
import "./Vesting.sol";
import "./WhitelistInterface.sol";

/**
 * @title Buyback
 */
contract Buyback is AccessControl {
    using SafeERC20 for Mnt;

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Tole that's allowed to initiate buyback
    /// @dev Value is the Keccak-256 hash of "DISTRIBUTOR"
    bytes32 public constant DISTRIBUTOR = bytes32(0x85faced7bde13e1a7dad704b895f006e704f207617d68166b31ba2d79624862d);

    uint256 internal constant SHARE_SCALE = 1e36;
    uint256 internal constant CURVE_SCALE = 1e18;

    uint256 public constant SECS_PER_YEAR = 365 * 24 * 60 * 60;

    /// buyback curve approximates discount rate of the e^-kt, k = 0.725, t = days/365 with the polynomial.
    /// polynomial function f(x) = A + (B * x) + (C * x^2) + (D * x^3) + (E * x^4)
    /// e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4, x in range
    /// of 0 .. 4.44 years in seconds, with good precision
    /// e^-kt gives a steady discount rate of approximately 48% per year on the function range
    /// polynomial approximation gives similar results on most of the range and then smoothly reduces it
    /// to the constant value of about 4.75% (flatRate) starting from the kink point, i.e. when
    /// blockTime >= flatSeconds, result value equals the flatRate
    /// kink point (flatSeconds) calculated as df/dx = 0 for approximation polynomial
    /// A..E are as follows, B and D values are negative in the formula,
    /// substraction is used in the calculations instead
    /// result formula is f(x) = A + C*x^2 + E*x^4 - B*x - D * x^3
    uint256 internal constant A = 1e18;
    uint256 internal constant B = 0.7120242e18; // negative
    uint256 internal constant C = 0.2339357e18; // positive
    uint256 internal constant D = 0.04053335e18; // negative
    uint256 internal constant E = 0.00294642e18; // positive

    /// @notice Seconds from protocol start when approximation function has minimum value
    ///     ~ 4.44 years of the perfect year, at this point df/dx == 0
    uint256 public constant flatSeconds = 140119200;

    /// @notice Flat rate of the discounted MNTs after the kink point, equal to the percentage at flatSeconds time
    uint256 public constant flatRate = 47563813360365998;

    /// @notice Timestamp from which the discount starts
    uint256 public startTimestamp;

    Mnt public mnt;
    Supervisor public supervisor;
    Vesting public vesting;

    /// @notice How much MNT claimed from the buyback
    /// @param participating Marks account as legally participating in Buyback
    /// @param weight Total weight of accounts' funds
    /// @param lastShareAccMantissa The cumulative buyback share which was claimed last time
    struct MemberData {
        bool participating;
        uint256 weight;
        uint256 lastShareAccMantissa;
    }

    /// @param amount The amount of staked MNT
    /// @param discounted The amount of staked MNT with discount
    struct StakeData {
        uint256 amount;
        uint256 discounted;
    }

    /// @notice Member info of accounts
    mapping(address => MemberData) public members;
    /// @notice Stake info of accounts
    mapping(address => StakeData) public stakes;

    /// @notice The sum of all members' weights
    uint256 public weightSum;
    /// @notice The accumulated buyback share per 1 weight.
    uint256 public shareAccMantissa;

    /// @notice is stake function paused
    bool public isStakePaused;
    /// @notice is unstake function paused
    bool public isUnstakePaused;
    /// @notice is leave function paused
    bool public isLeavePaused;
    /// @notice is restake function paused
    bool public isRestakePaused;

    event ClaimReward(address who, uint256 amount);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackActionPaused(string action, bool pauseState);
    event DistributorChanged(address oldDistributor, address newDistributor);

    function initialize(
        Mnt mnt_,
        Supervisor supervisor_,
        Vesting vesting_,
        address admin_
    ) external {
        require(startTimestamp == 0, ErrorCodes.SECOND_INITIALIZATION);
        supervisor = supervisor_;
        startTimestamp = getTime();
        mnt = mnt_;
        vesting = vesting_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(DISTRIBUTOR, admin_);
    }

    /// @param account_ The account address
    /// @return Does the account legally participating Buyback
    function isParticipating(address account_) public view returns (bool) {
        return members[account_].participating;
    }

    /// @notice function to change stake enabled mode
    /// @param isPaused_ new state of stake allowance
    function setStakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Stake", isPaused_);
        isStakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of stake allowance
    function setUnstakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Unstake", isPaused_);
        isUnstakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of restake allowance
    function setRestakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Restake", isPaused_);
        isRestakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of _leave allowance
    function setLeavePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Leave", isPaused_);
        isLeavePaused = isPaused_;
    }

    /// @notice How much weight address has
    /// @param who_ Buyback member address
    /// @return Weight
    function weight(address who_) external view returns (uint256) {
        return members[who_].weight;
    }

    /// @notice Applies current discount rate to supplied amount
    /// @param amount_ The amount to discount
    /// @return Discounted amount in range [0; amount]
    function discountAmount(uint256 amount_) public view returns (uint256) {
        uint256 realPassed = getTime() - startTimestamp;
        return (amount_ * getPolynomialFactor(realPassed)) / CURVE_SCALE;
    }

    /// @notice Calculates value of polynomial approximation of e^-kt, k = 0.725, t in seconds of a perfect year
    ///         function follows e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4
    ///         up to the minimum and then continues with a flat rate
    /// @param secondsElapsed_ Seconds elapsed from the start block
    /// @return Discount rate in range [0..1] with precision mantissa 1e18
    function getPolynomialFactor(uint256 secondsElapsed_) public pure returns (uint256) {
        if (secondsElapsed_ >= flatSeconds) return flatRate;

        uint256 x = (CURVE_SCALE * secondsElapsed_) / SECS_PER_YEAR;
        uint256 x2 = (x * x) / CURVE_SCALE;
        uint256 bX = (B * x) / CURVE_SCALE;
        uint256 cX = (C * x2) / CURVE_SCALE;
        uint256 dX = (((D * x2) / CURVE_SCALE) * x) / CURVE_SCALE;
        uint256 eX = (((E * x2) / CURVE_SCALE) * x2) / CURVE_SCALE;

        return A + cX + eX - bX - dX;
    }

    /// @notice Calculates current weight of an account.
    /// @dev Reads a parameter mntAccrued from the supervisor's storage. Make sure you update the MNT supply and
    ///      borrow indexes and distribute MNT tokens for `who`.
    /// @param who_ The account under study
    /// @return Weight
    function calcWeight(address who_) public view returns (uint256) {
        return supervisor.mntAccrued(who_) + vesting.releasableAmount(who_) + stakes[who_].discounted;
    }

    /// @notice Stakes the specified amount of MNT and transfers them to this contract.
    ///         Sender's weight would increase by the discounted amount of staked funds.
    /// @notice This contract should be approved to transfer MNT from sender account
    /// @param amount_ The amount of MNT to stake
    function stake(uint256 amount_) external {
        WhitelistInterface whitelist = supervisor.whitelist();
        require(address(whitelist) == address(0) || whitelist.isWhitelisted(msg.sender), ErrorCodes.WHITELISTED_ONLY);
        require(isParticipating(msg.sender), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(!isStakePaused, ErrorCodes.OPERATION_PAUSED);

        StakeData storage staked = stakes[msg.sender];
        staked.amount += amount_;
        staked.discounted += discountAmount(amount_);

        _restakeFor(msg.sender);
        mnt.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
    ///         in the Buyback system, otherwise just transfers MNT tokens to the sender.
    ///         Sender's weight would decrease by discounted amount of unstaked funds, but resulting weight
    ///         would not be greater than staked amount left. If `amount_ == MaxUint256` unstakes all staked tokens.
    /// @param amount_ The amount of MNT to unstake
    function unstake(uint256 amount_) external {
        require(amount_ > 0, ErrorCodes.INCORRECT_AMOUNT);
        require(!isUnstakePaused, ErrorCodes.OPERATION_PAUSED);

        StakeData storage staked = stakes[msg.sender];

        // Check if the sender is a member of the Buyback system
        bool isSenderParticipating = isParticipating(msg.sender);

        if (amount_ == type(uint256).max || amount_ == staked.amount) {
            amount_ = staked.amount;
            delete stakes[msg.sender];
        } else {
            require(amount_ < staked.amount, ErrorCodes.INSUFFICIENT_STAKE);
            staked.amount -= amount_;
            // Recalculate the discount if the sender participates in the Buyback system
            if (isSenderParticipating) {
                uint256 newDiscounted = staked.discounted - discountAmount(amount_);
                /// Stake amount can be greater if discount is high leading to small discounted delta
                staked.discounted = Math.min(newDiscounted, staked.amount);
            }
        }

        emit Unstake(msg.sender, amount_);

        // Restake for the sender if he participates in the Buyback system
        if (isSenderParticipating) _restakeFor(msg.sender);

        mnt.safeTransfer(msg.sender, amount_);
    }

    /// @notice Stakes buyback reward and updates the sender's weight
    function restake() external {
        _restakeFor(msg.sender);
    }

    /// @notice Stakes buyback reward and updates the specified account's weight.
    /// @param who_ Address to claim for
    function restakeFor(address who_) external {
        _restakeFor(who_);
    }

    /// @notice Stakes buyback reward and updates the specified account's weight. Also updates MNT supply and
    ///         borrow indices and distributes for "who" MNT tokens
    /// @param who_ Address to claim for
    function restakeForWithDistribution(address who_) external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        supervisor.distributeAllMnt(who_);
        _restakeFor(who_);
    }

    function _restakeFor(address who_) internal {
        require(!isRestakePaused, ErrorCodes.OPERATION_PAUSED);

        if (!isParticipating(who_)) return;
        MemberData storage member = members[who_];
        _claimReward(who_, member);

        uint256 oldWeight = member.weight;
        uint256 newWeight = calcWeight(who_);

        if (newWeight != oldWeight) {
            member.weight = newWeight;
            weightSum = weightSum + newWeight - oldWeight;

            mnt.updateVotesForAccount(who_, uint224(newWeight), uint224(weightSum));
        }
    }

    function _claimReward(address who_, MemberData storage member_) internal {
        if (member_.lastShareAccMantissa >= shareAccMantissa) return;
        if (member_.weight == 0) {
            // member weight 0 means account is not participating in buyback yet, we need
            // to initialize it first. There is nothing to claim so function simply returns
            member_.lastShareAccMantissa = shareAccMantissa;
            return;
        }

        uint256 shareDiffMantissa = shareAccMantissa - member_.lastShareAccMantissa;
        uint256 rewardMnt = (member_.weight * shareDiffMantissa) / SHARE_SCALE;
        if (rewardMnt <= 0) return;

        stakes[who_].amount += rewardMnt;
        stakes[who_].discounted += rewardMnt;
        member_.lastShareAccMantissa = shareAccMantissa;

        emit ClaimReward(who_, rewardMnt);
    }

    /// @notice Does a buyback using the specified amount of MNT from sender's account
    /// @param amount_ The amount of MNT to take and distribute as buyback
    function buyback(uint256 amount_) external onlyRole(DISTRIBUTOR) {
        require(amount_ > 0, ErrorCodes.NOTHING_TO_DISTRIBUTE);
        require(weightSum > 0, ErrorCodes.NOT_ENOUGH_PARTICIPATING_ACCOUNTS);

        uint256 shareMantissa = (amount_ * SHARE_SCALE) / weightSum;
        shareAccMantissa = shareAccMantissa + shareMantissa;

        emit NewBuyback(amount_, shareMantissa);

        mnt.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// @notice Make account participating in the buyback. If the sender has a staked balance, then
    /// the weight will be equal to the discounted amount of staked funds.
    function participate() external {
        require(!isParticipating(msg.sender), ErrorCodes.ALREADY_PARTICIPATING_IN_BUYBACK);

        members[msg.sender].participating = true;
        emit ParticipateBuyback(msg.sender);

        StakeData storage staked = stakes[msg.sender];
        if (staked.amount > 0) staked.discounted = discountAmount(staked.amount);

        _restakeFor(msg.sender);
    }

    ///@notice Make accounts participate in buyback before its start.
    /// @param accounts_ Address to make participate in buyback.
    function participateOnBehalf(address[] memory accounts_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(shareAccMantissa == 0, ErrorCodes.BUYBACK_DRIPS_ALREADY_HAPPENED);
        for (uint256 i = 0; i < accounts_.length; i++) {
            members[accounts_[i]].participating = true;
        }
    }

    /// @notice Leave buyback participation, claim any MNTs rewarded by the buyback and withdraw all staked MNTs
    function leave() external {
        _leave(msg.sender);
    }

    /// @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
    /// withdraw all staked MNTs.
    /// @dev Admin function to leave on behalf.
    /// Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
    /// @param participant_ Address to leave for
    function leaveOnBehalf(address participant_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!mnt.isParticipantActive(participant_), ErrorCodes.BB_ACCOUNT_RECENTLY_VOTED);
        _leave(participant_);
    }

    /// @notice Leave buyback participation, set discounted amount for the `_participant` to zero.
    function _leave(address participant_) internal {
        require(isParticipating(participant_), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(!isLeavePaused, ErrorCodes.OPERATION_PAUSED);

        _claimReward(participant_, members[participant_]);

        weightSum -= members[participant_].weight;
        delete members[participant_];
        stakes[participant_].discounted = 0;

        emit LeaveBuyback(participant_, stakes[participant_].amount);

        mnt.updateVotesForAccount(msg.sender, uint224(0), uint224(weightSum));
    }

    /// @return timestamp
    // slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ErrorCodes.sol";
import "./Supervisor.sol";
import "./Buyback.sol";
import "./Governance/Mnt.sol";

contract BDSystem is AccessControl {
    uint256 internal constant EXP_SCALE = 1e18;
    using SafeERC20 for Mnt;

    struct Agreement {
        /// Emission boost for liquidity provider
        uint256 liquidityProviderBoost;
        /// Percentage of the total emissions earned by the representative
        uint256 representativeBonus;
        /// The number of the block in which agreement ends.
        uint32 endBlock;
        /// Business Development Representative
        address representative;
    }
    /// Linking the liquidity provider with the agreement
    mapping(address => Agreement) public providerToAgreement;
    /// Counts liquidity providers of the representative
    mapping(address => uint256) public representativesProviderCounter;

    Supervisor public supervisor;

    event AgreementAdded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 startBlock,
        uint32 endBlock
    );
    event AgreementEnded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 endBlock
    );

    constructor(address admin_, Supervisor supervisor_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        supervisor = supervisor_;
    }

    /*** Admin functions ***/

    /**
     * @notice Creates a new agreement between liquidity provider and representative
     * @dev Admin function to create a new agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the liquidity provider representative.
     * @param representativeBonus_ percentage of the emission boost for representative
     * @param liquidityProviderBoost_ percentage of the boost for liquidity provider
     * @param endBlock_ The number of the first block when agreement will not be in effect
     */
    function createAgreement(
        address liquidityProvider_,
        address representative_,
        uint256 representativeBonus_,
        uint256 liquidityProviderBoost_,
        uint32 endBlock_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // (1 + liquidityProviderBoost) * (1 + representativeBonus) <= 150%
        require(
            (EXP_SCALE + liquidityProviderBoost_) * (EXP_SCALE + representativeBonus_) <= 1.5e36,
            ErrorCodes.EC_INVALID_BOOSTS
        );
        // one account at one time can be a liquidity provider once,
        require(!isAccountLiquidityProvider(liquidityProvider_), ErrorCodes.EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER);
        // one account can't be a liquidity provider and a representative at the same time
        require(
            !isAccountRepresentative(liquidityProvider_) && !isAccountLiquidityProvider(representative_),
            ErrorCodes.EC_PROVIDER_CANT_BE_REPRESENTATIVE
        );

        // we are distribution MNT tokens for liquidity provider
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        supervisor.distributeAllMnt(liquidityProvider_);

        // we are creating agreement between liquidity provider and representative
        providerToAgreement[liquidityProvider_] = Agreement({
            representative: representative_,
            liquidityProviderBoost: liquidityProviderBoost_,
            representativeBonus: representativeBonus_,
            endBlock: endBlock_
        });
        representativesProviderCounter[representative_]++;

        emit AgreementAdded(
            liquidityProvider_,
            representative_,
            representativeBonus_,
            liquidityProviderBoost_,
            uint32(_getBlockNumber()),
            endBlock_
        );
    }

    /**
     * @notice Removes a agreement between liquidity provider and representative
     * @dev Admin function to remove a agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the representative.
     */
    function removeAgreement(address liquidityProvider_, address representative_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Agreement storage agreement = providerToAgreement[liquidityProvider_];
        require(agreement.representative == representative_, ErrorCodes.EC_INVALID_PROVIDER_REPRESENTATIVE);

        emit AgreementEnded(
            liquidityProvider_,
            representative_,
            agreement.representativeBonus,
            agreement.liquidityProviderBoost,
            agreement.endBlock
        );

        // We call emission system for liquidity provider, so liquidity provider and his representative will accrue
        // MNT tokens with their emission boosts
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
        supervisor.distributeAllMnt(liquidityProvider_);

        // We remove agreement between liquidity provider and representative
        delete providerToAgreement[liquidityProvider_];
        representativesProviderCounter[representative_]--;
    }

    /*** Helper special functions ***/

    /**
     * @notice Calculates boosts for liquidity provider and representative.
     * @param liquidityProvider_ address of the liquidity provider,
     * @param deltaIndex_ difference between the current MNT index and the index of the last update for
     *        the liquidity provider
     */
    function calculateEmissionBoost(address liquidityProvider_, uint256 deltaIndex_)
        public
        view
        returns (
            address representative,
            uint256 representativeBonus,
            uint256 providerBoostedIndex
        )
    {
        // get a representative for the account_ and his representative bonus
        Agreement storage agreement = providerToAgreement[liquidityProvider_];
        representative = agreement.representative;

        // if account isn't liquidity provider we return from method.
        if (representative == address(0)) return (address(0), 0, 0);

        representativeBonus = agreement.representativeBonus;
        providerBoostedIndex = (deltaIndex_ * agreement.liquidityProviderBoost) / EXP_SCALE;
    }

    /**
     * @notice checks if `account_` is liquidity provider.
     * @dev account_ is liquidity provider if he has agreement.
     * @param account_ address to check
     * @return `true` if `account_` is liquidity provider, otherwise returns false
     */
    function isAccountLiquidityProvider(address account_) public view returns (bool) {
        return providerToAgreement[account_].representative != address(0);
    }

    /**
     * @notice checks if `account_` is business development representative.
     * @dev account_ is business development representative if he has liquidity providers.
     * @param account_ address to check
     * @return `true` if `account_` is business development representative, otherwise returns false
     */
    function isAccountRepresentative(address account_) public view returns (bool) {
        return representativesProviderCounter[account_] > 0;
    }

    /**
     * @notice checks if agreement is expired
     * @dev reverts if the `account_` is not a valid liquidity provider
     * @param account_ address of the liquidity provider
     * @return `true` if agreement is expired, otherwise returns false
     */
    function isAgreementExpired(address account_) external view returns (bool) {
        require(isAccountLiquidityProvider(account_), ErrorCodes.EC_ACCOUNT_HAS_NO_AGREEMENT);
        return providerToAgreement[account_].endBlock <= _getBlockNumber();
    }

    /// @dev Function to simply retrieve block number
    ///      This exists mainly for inheriting test contracts to stub this result.
    // slither-disable-next-line dead-code
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Supervisor.sol";
import "./MToken.sol";

contract EmissionBooster is AccessControl, ReentrancyGuard {
    /// @dev Based on bitmap size used in TierCheckpoint
    uint256 internal constant MAX_TIERS = 224;

    /// @notice Address of the Minterest NFT.
    address public minterestNFT;

    /// @notice The address of the Minterest supervisor.
    Supervisor public supervisor;

    /// @dev The Tier for each MinterestNFT token
    mapping(uint256 => uint256) public tokenTier;

    /// @dev Bitmap with accounts tiers
    mapping(address => uint256) internal accountToTiers;

    /// @dev Stores how much tokens of one tier account have
    mapping(address => mapping(uint256 => uint256)) internal accountToTierAmounts;

    /// @notice A list of all created Tiers
    TierData[] public tiers;

    /// @dev Contains end block of checkpoint and what tiers where active during it
    struct TierCheckpoint {
        uint32 startBlock;
        uint224 activeTiers;
    }

    /// @dev A list of checkpoints of tiers
    TierCheckpoint[] internal checkpoints;

    /// @notice Indicates whether the emission boost mode is enabled.
    /// If enabled - we perform calculations of the emission boost for MNT distribution,
    /// if disabled - additional calculations are not performed. This flag can only be activated once.
    bool public isEmissionBoostingEnabled;

    struct TierData {
        // Block number in which the emission boost starts work. This block number is stored at the moment
        // the category is activated.
        uint32 startBlock;
        // Block number in which the emission boost ends.
        uint32 endBlock;
        // Emissions Boost for MNT Emissions Rewards, scaled by 1e18
        uint256 emissionBoost;
    }

    /// @dev Indicates the Tier that should be updated next in a specific market.
    mapping(MToken => uint256) internal tierToBeUpdatedSupplyIndex;
    mapping(MToken => uint256) internal tierToBeUpdatedBorrowIndex;

    /// @notice Stores markets indexes per block.
    mapping(MToken => mapping(uint256 => uint256)) public marketSupplyIndexes;
    mapping(MToken => mapping(uint256 => uint256)) public marketBorrowIndexes;

    /// @notice Emitted when new Tier was created
    event NewTierCreated(uint256 createdTier, uint32 endBoostBlock, uint256 emissionBoost);

    /// @notice Emitted when Tier was enabled
    event TierEnabled(
        MToken market,
        uint256 enabledTier,
        uint32 startBoostBlock,
        uint224 mntSupplyIndex,
        uint224 mntBorrowIndex
    );

    /// @notice Emitted when new Supervisor was installed
    event SupervisorInstalled(Supervisor supervisor);

    /// @notice Emitted when emission boost mode was enabled
    event EmissionBoostEnabled(address caller);

    /// @notice Emitted when MNT supply index of the tier ending on the market was saved to storage
    event SupplyIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /// @notice Emitted when MNT borrow index of the tier ending on the market was saved to storage
    event BorrowIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /// @param admin_ Address of the Admin
    /// @param minterestNFT_ Address of the Minterest NFT contract
    /// @param supervisor_ Address of the Supervisor contract
    function initialize(
        address admin_,
        address minterestNFT_,
        Supervisor supervisor_
    ) external {
        require(minterestNFT == address(0), ErrorCodes.SECOND_INITIALIZATION);
        require(admin_ != address(0), ErrorCodes.ADMIN_ADDRESS_CANNOT_BE_ZERO);
        require(minterestNFT_ != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        minterestNFT = minterestNFT_;
        supervisor = supervisor_;

        // Create zero Tier. Zero Tier is always disabled.
        tiers.push(TierData({startBlock: 0, endBlock: 0, emissionBoost: 0}));
    }

    //// NFT callback functions ////

    function onMintToken(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        uint256[] memory tiers_
    ) external {
        require(msg.sender == minterestNFT, ErrorCodes.UNAUTHORIZED);

        uint256 transferredTiers = 0;
        for (uint256 i = 0; i < ids_.length; i++) {
            uint256 tier = tiers_[i];
            if (tier == 0) continue; // Process only positive tiers

            require(tierExists(tier), ErrorCodes.EB_TIER_DOES_NOT_EXIST);
            require(!isTierActive(tier), ErrorCodes.EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER);

            tokenTier[ids_[i]] = tier;
            accountToTierAmounts[to_][tier] += amounts_[i];
            transferredTiers |= _tierMask(tier);
        }

        // Update only if receiver has got new tiers
        uint256 tiersDiff = accountToTiers[to_] ^ transferredTiers;
        if (tiersDiff > 0) {
            // slither-disable-next-line reentrancy-no-eth
            supervisor.distributeAllMnt(to_);
            accountToTiers[to_] |= transferredTiers;
        }
    }

    /// @param from_ Address of the tokens previous owner. Should not be zero (minter).
    function onTransferToken(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external {
        require(msg.sender == minterestNFT, ErrorCodes.UNAUTHORIZED);

        uint256 removedTiers = 0;
        uint256 transferredTiers = 0;
        for (uint256 i = 0; i < ids_.length; i++) {
            (uint256 id, uint256 amount) = (ids_[i], amounts_[i]);
            if (amount == 0) continue;

            uint256 tier = tokenTier[id];
            if (tier == 0) continue;

            uint256 mask = _tierMask(tier);
            transferredTiers |= mask;

            accountToTierAmounts[from_][tier] -= amount;
            if (accountToTierAmounts[from_][tier] == 0) removedTiers |= mask;

            accountToTierAmounts[to_][tier] += amount;
        }

        // Update only if sender has removed tiers
        if (removedTiers > 0) {
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
            supervisor.distributeAllMnt(from_);
            accountToTiers[from_] &= ~removedTiers;
        }

        // Update only if receiver has got new tiers
        uint256 tiersDiff = accountToTiers[to_] ^ transferredTiers;
        if (tiersDiff > 0) {
            // slither-disable-next-line reentrancy-no-eth
            supervisor.distributeAllMnt(to_);
            accountToTiers[to_] |= transferredTiers;
        }
    }

    //// Admin Functions ////

    /// @notice Enables emission boost mode.
    /// @dev Admin function for enabling emission boosts.
    function enableEmissionBoosting() external {
        address whitelist = address(supervisor.whitelist());
        require(whitelist != address(0) && msg.sender == whitelist, ErrorCodes.UNAUTHORIZED);
        isEmissionBoostingEnabled = true;
        // we do not activate the zero tier
        uint256[] memory tiersForEnabling = new uint256[](tiers.length - 1);
        for (uint256 i = 0; i < tiersForEnabling.length; i++) {
            tiersForEnabling[i] = i + 1;
        }

        enableTiersInternal(tiersForEnabling);
        emit EmissionBoostEnabled(msg.sender);
    }

    /// @notice Creates new Tiers for MinterestNFT tokens
    /// @dev Admin function for creating Tiers
    /// @param endBoostBlocks Emission boost end blocks for created Tiers
    /// @param emissionBoosts Emission boosts for created Tiers, scaled by 1e18
    /// Note: The arrays passed to the function must be of the same length and the order of the elements must match
    ///      each other
    function createTiers(uint32[] memory endBoostBlocks, uint256[] memory emissionBoosts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(endBoostBlocks.length == emissionBoosts.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);
        require(
            tiers.length + endBoostBlocks.length - 1 <= MAX_TIERS, // Subtract zero tier
            ErrorCodes.EB_TIER_LIMIT_REACHED
        );

        for (uint256 i = 0; i < endBoostBlocks.length; i++) {
            uint32 end = endBoostBlocks[i];
            uint256 boost = emissionBoosts[i];

            require(_getBlockNumber() < end, ErrorCodes.EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT);
            require(boost > 0 && boost <= 0.5e18, ErrorCodes.EB_EMISSION_BOOST_IS_NOT_IN_RANGE);

            tiers.push(TierData({startBlock: 0, endBlock: end, emissionBoost: boost}));
            emit NewTierCreated(tiers.length - 1, end, boost);
        }
    }

    /// @notice Enables emission boost in specified Tiers
    /// @param tiersForEnabling Tier for enabling emission boost
    function enableTiers(uint256[] memory tiersForEnabling) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        enableTiersInternal(tiersForEnabling);
    }

    /// @notice Enables emission boost in specified Tiers
    /// @param tiersForEnabling Tier for enabling emission boost
    // slither-disable-next-line reentrancy-no-eth
    function enableTiersInternal(uint256[] memory tiersForEnabling) internal {
        uint32 currentBlock = uint32(_getBlockNumber());

        // For each tier of tiersForEnabling set startBlock
        for (uint256 i = 0; i < tiersForEnabling.length; i++) {
            uint256 tier = tiersForEnabling[i];
            require(tier != 0, ErrorCodes.EB_ZERO_TIER_CANNOT_BE_ENABLED);
            require(tierExists(tier), ErrorCodes.EB_TIER_DOES_NOT_EXIST);
            require(!isTierActive(tier), ErrorCodes.EB_ALREADY_ACTIVATED_TIER);
            require(currentBlock < tiers[tier].endBlock, ErrorCodes.EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT);
            tiers[tier].startBlock = currentBlock;
        }

        _rebuildCheckpoints();

        // For all markets update mntSupplyIndex and mntBorrowIndex, and set marketSpecificData index
        MToken[] memory markets = supervisor.getAllMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            MToken market = markets[i];
            tierToBeUpdatedSupplyIndex[market] = getNextTierToBeUpdatedIndex(market, true);
            tierToBeUpdatedBorrowIndex[market] = getNextTierToBeUpdatedIndex(market, false);
            // slither-disable-next-line reentrancy-events,calls-loop
            (uint224 mntSupplyIndex, uint224 mntBorrowIndex) = supervisor.updateAndGetMntIndexes(market);
            for (uint256 index = 0; index < tiersForEnabling.length; index++) {
                uint256 tier = tiersForEnabling[index];
                marketSupplyIndexes[market][currentBlock] = mntSupplyIndex;
                marketBorrowIndexes[market][currentBlock] = mntBorrowIndex;
                emit TierEnabled(market, tier, currentBlock, mntSupplyIndex, mntBorrowIndex);
            }
        }
    }

    /// @dev Rebuilds tier checkpoints array from scratch.
    /// Checkpoints have end block and bitmap with active tiers.
    /// Final checkpoint has the same block as previous but empty bitmap.
    ///           10     20     30     40     50     50
    ///     _0001_|_0011_|_1111_|_0101_|_0001_|_0000_|
    function _rebuildCheckpoints() internal {
        TierData[] memory tiers_ = tiers;

        // Find bounds of all tiers
        uint256 firstStartBlock = type(uint256).max;
        uint256 lastEndBlock = type(uint256).min;
        for (uint256 tier = 1; tier < tiers_.length; tier++) {
            uint256 tierStart = tiers_[tier].startBlock;
            if (tierStart == 0) continue; // Skip disabled tiers

            uint256 tierEnd = tiers_[tier].endBlock;
            if (tierStart < firstStartBlock) firstStartBlock = tierStart;
            if (tierEnd > lastEndBlock) lastEndBlock = tierEnd;
        }

        // Build checkpoints...
        uint256 checkpointsLen = checkpoints.length;
        uint256 checkpointsIdx = 0; // First zero checkpoint
        uint256 currStartBlock = firstStartBlock;

        // Add empty checkpoint at the start
        // Used to close first tier in boost calculation
        if (checkpointsIdx < checkpointsLen) {
            checkpoints[checkpointsIdx] = TierCheckpoint(0, 0);
            checkpointsIdx++;
        } else {
            checkpoints.push(TierCheckpoint(0, 0));
        }

        while (currStartBlock < lastEndBlock) {
            uint256 nextChangeBlock = type(uint256).max;
            uint256 activeTiers = 0;

            for (uint256 tier = 1; tier < tiers_.length; tier++) {
                uint256 tierStart = tiers_[tier].startBlock;
                if (tierStart == 0) continue; // Skip disabled tiers

                uint256 tierEnd = tiers_[tier].endBlock;

                // Find next tier state change
                if (tierStart > currStartBlock && tierStart < nextChangeBlock) nextChangeBlock = tierStart;
                if (tierEnd > currStartBlock && tierEnd < nextChangeBlock) nextChangeBlock = tierEnd;

                // If tier starts now and ends later - it's active
                if (tierStart <= currStartBlock && tierEnd > currStartBlock) activeTiers |= _tierMask(tier);
            }

            // Overwrite old checkpoint or push new one
            if (checkpointsIdx < checkpointsLen) {
                checkpoints[checkpointsIdx] = TierCheckpoint(uint32(currStartBlock), uint224(activeTiers));
                checkpointsIdx++;
            } else {
                checkpoints.push(TierCheckpoint(uint32(currStartBlock), uint224(activeTiers)));
            }

            currStartBlock = nextChangeBlock;
        }

        // Add empty checkpoint at the end
        // Used to close final tier in boost calculation
        if (checkpointsIdx < checkpointsLen) {
            checkpoints[checkpointsIdx] = TierCheckpoint(uint32(lastEndBlock), 0);
        } else {
            checkpoints.push(TierCheckpoint(uint32(lastEndBlock), 0));
        }
    }

    /*** Helper special functions ***/

    /// @notice Return the number of created Tiers
    /// @return The number of created Tiers
    function getNumberOfTiers() external view returns (uint256) {
        return tiers.length;
    }

    /// @dev Function to simply retrieve block number
    ///      This exists mainly for inheriting test contracts to stub this result.
    // slither-disable-next-line dead-code
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @notice Checks if the specified Tier is active
    /// @param tier_ The Tier that is being checked
    function isTierActive(uint256 tier_) public view returns (bool) {
        return tiers[tier_].startBlock > 0;
    }

    /// @notice Checks if the specified Tier exists
    /// @param tier_ The Tier that is being checked
    function tierExists(uint256 tier_) public view returns (bool) {
        return tier_ < tiers.length;
    }

    /// @param account_ The address of the account
    /// @return Bitmap of all accounts tiers
    function getAccountTiersBitmap(address account_) external view returns (uint256) {
        return accountToTiers[account_];
    }

    /// @param account_ The address of the account to check if they have any tokens with tier
    function isAccountHaveTiers(address account_) public view returns (bool) {
        return accountToTiers[account_] > 0;
    }

    /// @param account_ Address of the account
    /// @return tier Highest tier number
    /// @return boost Highest boost amount
    function getCurrentAccountBoost(address account_) external view returns (uint256 tier, uint256 boost) {
        uint256 active = accountToTiers[account_];
        uint256 blockN = _getBlockNumber();
        // We shift `active` and use it as condition to continue loop.
        for (uint256 ti = 1; active > 0; ti++) {
            if (active & 1 == 1) {
                TierData storage tr = tiers[ti];
                if (tr.emissionBoost > boost && tr.startBlock <= blockN && blockN < tr.endBlock) {
                    tier = ti;
                    boost = tr.emissionBoost;
                }
            }
            active >>= 1;
        }
    }

    struct CalcEmissionVars {
        uint256 currentBlock;
        uint256 accountTiers;
        uint256 highIndex;
        uint256 prevBoost;
        uint256 prevCpIndex;
    }

    /// @notice Calculates emission boost for the account.
    /// @param market_ Market for which we are calculating emission boost
    /// @param account_ The address of the account for which we are calculating emission boost
    /// @param userLastIndex_ The account's last updated mntBorrowIndex or mntSupplyIndex
    /// @param userLastBlock_ The block number in which the index for the account was last updated
    /// @param marketIndex_ The market's current mntBorrowIndex or mntSupplyIndex
    /// @param isSupply_ boolean value, if true, then return calculate emission boost for suppliers
    /// @return boostedIndex Boost part of delta index
    function calculateEmissionBoost(
        MToken market_,
        address account_,
        uint256 userLastIndex_,
        uint256 userLastBlock_,
        uint256 marketIndex_,
        bool isSupply_
    ) public view virtual returns (uint256 boostedIndex) {
        require(marketIndex_ >= userLastIndex_, ErrorCodes.EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX);
        require(userLastIndex_ >= 1e36, ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL);

        // If emission boosting is disabled or account doesn't have NFT return nothing
        if (!isEmissionBoostingEnabled || !isAccountHaveTiers(account_)) {
            return 0;
        }

        // User processed every checkpoint and can't receive any boosts because they are ended.
        if (userLastBlock_ > checkpoints[checkpoints.length - 1].startBlock) {
            return 0;
        }

        // Thesaurus:
        //   Checkpoint, CP - Marks the end of the period and what tiers where active during it.
        //   Segment - Interval with the same boost amount.
        //   Low index, LI - Starting index of the segment.
        //   High index, HI - Ending index of the segment.

        CalcEmissionVars memory vars = CalcEmissionVars({
            currentBlock: _getBlockNumber(),
            accountTiers: accountToTiers[account_],
            highIndex: 0,
            prevBoost: 0,
            prevCpIndex: 0
        });

        // Remember, we are iterating in reverse: from recent checkpoints to the old ones.
        for (uint256 cpi = checkpoints.length; cpi > 0; cpi--) {
            TierCheckpoint memory cp = checkpoints[cpi - 1];

            // Skip if this checkpoint is not started yet
            if (cp.startBlock >= vars.currentBlock) continue;

            uint256 active = uint256(cp.activeTiers) & vars.accountTiers;
            uint256 cpIndex = isSupply_
                ? marketSupplyIndexes[market_][cp.startBlock]
                : marketBorrowIndexes[market_][cp.startBlock];

            if (active == 0) {
                // No active tiers in this checkpoint.

                if (vars.prevBoost > 0) {
                    // Payout - Tier start
                    // Prev tier started after we had no active tiers in this CP.

                    uint256 deltaIndex = vars.highIndex - vars.prevCpIndex;
                    boostedIndex += (deltaIndex * vars.prevBoost) / 1e18;

                    // No active tiers in this checkpoint, so we zero out values.
                    vars.highIndex = 0;
                    vars.prevBoost = 0;
                }

                // We reached checkpoint that was active last time and can exit.
                if (cp.startBlock <= userLastBlock_) break;

                vars.prevCpIndex = cpIndex;
                continue;
            }

            uint256 highestBoost = _findHighestTier(active);

            if (vars.prevBoost == highestBoost && cp.startBlock >= userLastBlock_) {
                vars.prevCpIndex = cpIndex;
                continue;
            }

            if (vars.prevBoost == 0) {
                // If there was no previous tier then we starting new segment.

                // When we are processing first (last in time) started checkpoint we have no prevCpIndex.
                // In that case we should use marketIndex_ and prevCpIndex otherwise.
                vars.highIndex = vars.prevCpIndex > 0 ? vars.prevCpIndex : marketIndex_;
            } else if (vars.prevBoost != highestBoost) {
                // Payout - Change tier
                // In this checkpoint is active other tier than in previous one.

                uint256 deltaIndex = vars.highIndex - vars.prevCpIndex;
                boostedIndex += (deltaIndex * vars.prevBoost) / 1e18;

                // Remember lowest index of previous segment as the highest index of new segment.
                vars.highIndex = vars.prevCpIndex;
            }

            if (cp.startBlock <= userLastBlock_) {
                // Payout - Deep break
                // We reached checkpoint that was active last time.
                // Since this is active tier we can use user index as LI.

                uint256 deltaIndex = vars.highIndex - userLastIndex_;
                boostedIndex += (deltaIndex * highestBoost) / 1e18;

                break;
            }

            // Save data about current checkpoint
            vars.prevBoost = highestBoost;
            vars.prevCpIndex = cpIndex;
        }
    }

    /// @dev Finds tier with highest boost value from supplied bitmap
    /// @param active Set of tiers in form of bitmap to find the highest tier from
    /// @return highestBoost Highest tier boost amount with subtracted 1e18
    function _findHighestTier(uint256 active) internal view returns (uint256 highestBoost) {
        // We shift `active` and use it as condition to continue loop.
        for (uint256 ti = 1; active > 0; ti++) {
            if (active & 1 == 1) {
                uint256 tierEmissionBoost = tiers[ti].emissionBoost;
                if (tierEmissionBoost > highestBoost) {
                    highestBoost = tierEmissionBoost;
                }
            }
            active >>= 1;
        }
    }

    /// @notice Update MNT supply index for market for NFT tiers that are expired but not yet updated.
    /// @dev This function checks if there are tiers to update and process them one by one:
    ///      calculates the MNT supply index depending on the delta index and delta blocks between
    ///      last MNT supply index update and the current state,
    ///      emits SupplyIndexUpdated event and recalculates next tier to update.
    /// @param market Address of the market to update
    /// @param lastUpdatedBlock Last updated block number
    /// @param lastUpdatedIndex Last updated index value
    /// @param currentSupplyIndex Current MNT supply index value
    function updateSupplyIndexesHistory(
        MToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentSupplyIndex
    ) public virtual {
        require(msg.sender == address(supervisor), ErrorCodes.UNAUTHORIZED);
        require(
            currentSupplyIndex >= 1e36 && lastUpdatedIndex >= 1e36,
            ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL
        );

        uint256 nextTier = tierToBeUpdatedSupplyIndex[market];
        // If parameter nextTier is equal to zero, it means that all Tiers have already been updated.
        if (nextTier == 0) return;

        uint256 currentBlock = _getBlockNumber();
        uint256 endBlock = tiers[nextTier].endBlock;
        uint256 period = currentBlock - lastUpdatedBlock;

        // calculate and fill all expired markets that were not updated
        // we expect that there will be only one expired tier at a time, but will parse all just in case
        while (endBlock <= currentBlock) {
            if (isTierActive(nextTier) && (marketSupplyIndexes[market][endBlock] == 0)) {
                uint224 newIndex = uint224(
                    lastUpdatedIndex +
                        (((currentSupplyIndex - lastUpdatedIndex) * (endBlock - lastUpdatedBlock)) / period)
                );

                marketSupplyIndexes[market][endBlock] = newIndex;

                emit SupplyIndexUpdated(address(market), nextTier, newIndex, uint32(endBlock));
            }

            nextTier = getNextTierToBeUpdatedIndex(market, true);
            tierToBeUpdatedSupplyIndex[market] = nextTier;

            if (nextTier == 0) break;

            endBlock = tiers[nextTier].endBlock;
        }
    }

    /// @notice Update MNT borrow index for market for NFT tiers that are expired but not yet updated.
    /// @dev This function checks if there are tiers to update and process them one by one:
    ///      calculates the MNT borrow index depending on the delta index and delta blocks between
    ///      last MNT borrow index update and the current state,
    ///      emits BorrowIndexUpdated event and recalculates next tier to update.
    /// @param market Address of the market to update
    /// @param lastUpdatedBlock Last updated block number
    /// @param lastUpdatedIndex Last updated index value
    /// @param currentBorrowIndex Current MNT borrow index value
    function updateBorrowIndexesHistory(
        MToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentBorrowIndex
    ) public virtual {
        require(msg.sender == address(supervisor), ErrorCodes.UNAUTHORIZED);
        require(
            currentBorrowIndex >= 1e36 && lastUpdatedIndex >= 1e36,
            ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL
        );

        uint256 nextTier = tierToBeUpdatedBorrowIndex[market];
        // If parameter nextTier is equal to zero, it means that all Tiers have already been updated.
        if (nextTier == 0) return;

        uint256 currentBlock = _getBlockNumber();
        uint256 endBlock = tiers[nextTier].endBlock;
        uint256 period = currentBlock - lastUpdatedBlock;

        // calculate and fill all expired markets that were not updated
        while (endBlock <= currentBlock) {
            if (isTierActive(nextTier) && (marketBorrowIndexes[market][endBlock] == 0)) {
                uint224 newIndex = uint224(
                    lastUpdatedIndex +
                        (((currentBorrowIndex - lastUpdatedIndex) * (endBlock - lastUpdatedBlock)) / period)
                );

                marketBorrowIndexes[market][endBlock] = newIndex;

                emit BorrowIndexUpdated(address(market), nextTier, newIndex, uint32(endBlock));
            }

            nextTier = getNextTierToBeUpdatedIndex(market, false);
            tierToBeUpdatedBorrowIndex[market] = nextTier;

            if (nextTier == 0) break;

            endBlock = tiers[nextTier].endBlock;
        }
    }

    /// @notice Get Id of NFT tier to update next on provided market MNT index, supply or borrow
    /// @param market Market for which should the next Tier to update be updated
    /// @param isSupply_ Flag that indicates whether MNT supply or borrow market should be updated
    /// @return Id of tier to update
    function getNextTierToBeUpdatedIndex(MToken market, bool isSupply_) public view virtual returns (uint256) {
        // Find the next Tier that should be updated. We are skipping Zero Tier.
        uint256 numberOfBoostingTiers = tiers.length - 1;

        // return zero if no next tier available
        if (numberOfBoostingTiers < 1) return 0;

        // set closest tier to update to be tier 1
        // we expect this list to be ordered but we have to check anyway
        uint256 closest = 0;
        uint256 bestTier = 0;

        for (uint256 tier = 1; tier <= numberOfBoostingTiers; tier++) {
            // skip non-started tiers
            if (!isTierActive(tier)) continue;

            // skip any finalized market
            uint256 current = tiers[tier].endBlock;
            if (isSupply_) {
                if (marketSupplyIndexes[market][current] != 0) continue;
            } else {
                if (marketBorrowIndexes[market][current] != 0) continue;
            }

            // init closest with the first non-passed yet tier
            if (closest == 0) {
                closest = current;
                bestTier = tier;
                continue;
            }

            // we are here if potentially closest tier is found, performing final check
            if (current < closest) {
                closest = current;
                bestTier = tier;
            }
        }

        return bestTier;
    }

    function _tierMask(uint256 tier) internal pure returns (uint256) {
        return tier > 0 ? 1 << (tier - 1) : 0;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./Oracles/PriceOracle.sol";
import "./MToken.sol";
import "./Supervisor.sol";
import "./DeadDrop.sol";

/**
 * This contract provides the liquidation functionality.
 */

contract Liquidation is AccessControl, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;

    uint256 private constant EXP_SCALE = 1e18;

    /**
     * @notice The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    uint256 public healthyFactorLimit = 1.2e18; // 120%

    /**
     * @notice Maximum sum in USD for internal liquidation. Collateral for loans that are less than this parameter will
     * be counted as protocol interest, scaled by 1e18
     */
    uint256 public insignificantLoanThreshold = 100e18; // 100$

    /// @notice Value is the Keccak-256 hash of "TRUSTED_LIQUIDATOR"
    /// @dev Role that's allowed to liquidate in Auto mode
    bytes32 public constant TRUSTED_LIQUIDATOR =
        bytes32(0xf81d27a41879d78d5568e0bc2989cb321b89b84d8e1b49895ee98604626c0218);
    /// @notice Value is the Keccak-256 hash of "MANUAL_LIQUIDATOR"
    /// @dev Role that's allowed to liquidate in Manual mode.
    ///      Each MANUAL_LIQUIDATOR address has to be appended to TRUSTED_LIQUIDATOR role too.
    bytes32 public constant MANUAL_LIQUIDATOR =
        bytes32(0x53402487d33e65b38c49f6f89bd08cbec4ff7c074cddd2357722b7917cd13f1e);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    /**
     * @notice Minterest deadDrop contract
     */
    DeadDrop public deadDrop;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Minterest supervisor contract
     */
    Supervisor public supervisor;

    event HealthyFactorLimitChanged(uint256 oldValue, uint256 newValue);
    event NewSupervisor(Supervisor oldSupervisor, Supervisor newSupervisor);
    event NewPriceOracle(PriceOracle oldOracle, PriceOracle newOracle);
    event NewDeadDrop(DeadDrop oldDeadDrop, DeadDrop newDeadDrop);
    event NewInsignificantLoanThreshold(uint256 oldValue, uint256 newValue);
    event ReliableLiquidation(
        bool isManualLiquidation,
        bool isDebtHealthy,
        address liquidator,
        address borrower,
        MToken[] marketAddresses,
        uint256[] seizeIndexes,
        uint256[] debtRates
    );

    /**
     * @notice Construct a Liquidation contract
     * @param deadDrop_ Minterest deadDrop address
     * @param liquidators_ Array of addresses of liquidators
     * @param supervisor_ The address of the Supervisor contract
     * @param admin_ The address of the admin
     */
    constructor(
        address[] memory liquidators_,
        DeadDrop deadDrop_,
        Supervisor supervisor_,
        address admin_
    ) {
        require(
            supervisor_.supportsInterface(type(SupervisorInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(address(deadDrop_) != address(0), ErrorCodes.ZERO_ADDRESS);

        supervisor = supervisor_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TRUSTED_LIQUIDATOR, admin_);
        _grantRole(MANUAL_LIQUIDATOR, admin_);
        _grantRole(TIMELOCK, admin_);
        oracle = supervisor_.oracle();
        deadDrop = deadDrop_;

        for (uint256 i = 0; i < liquidators_.length; i++) {
            _grantRole(TRUSTED_LIQUIDATOR, liquidators_[i]);
        }
    }

    /**
     * @dev Local accountState for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct AccountLiquidationAmounts {
        uint256 accountTotalSupplyUsd;
        uint256 accountTotalCollateralUsd;
        uint256 accountPresumedTotalSeizeUsd;
        uint256 accountTotalBorrowUsd;
        uint256[] repayAmounts;
        uint256[] seizeAmounts;
    }

    /**
     * @notice Liquidate insolvent debt position
     * @param borrower_ Account which is being liquidated
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_  An array of debt redemption rates for each debt markets (scaled by 1e18).
     */
    //slither-disable-next-line reentrancy-benign
    function liquidateUnsafeLoan(
        address borrower_,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external onlyRole(TRUSTED_LIQUIDATOR) nonReentrant {
        AccountLiquidationAmounts memory accountState;

        MToken[] memory accountAssets = supervisor.getAccountAssets(borrower_);
        verifyExternalData(accountAssets.length, seizeIndexes_, debtRates_);

        //slither-disable-next-line reentrancy-events
        accrue(accountAssets, seizeIndexes_, debtRates_);
        accountState = calculateLiquidationAmounts(borrower_, accountAssets, seizeIndexes_, debtRates_);

        require(
            accountState.accountTotalCollateralUsd < accountState.accountTotalBorrowUsd,
            ErrorCodes.INSUFFICIENT_SHORTFALL
        );

        bool isManualLiquidation = hasRole(MANUAL_LIQUIDATOR, msg.sender);
        bool isDebtHealthy = accountState.accountPresumedTotalSeizeUsd <= accountState.accountTotalSupplyUsd;

        seize(
            borrower_,
            accountAssets,
            accountState.seizeAmounts,
            accountState.accountTotalBorrowUsd <= insignificantLoanThreshold,
            isManualLiquidation
        );
        repay(borrower_, accountAssets, accountState.repayAmounts, isManualLiquidation);

        if (isDebtHealthy) {
            require(approveBorrowerHealthyFactor(borrower_, accountAssets), ErrorCodes.HEALTHY_FACTOR_NOT_IN_RANGE);
        }

        emit ReliableLiquidation(
            isManualLiquidation,
            isDebtHealthy,
            msg.sender,
            borrower_,
            accountAssets,
            seizeIndexes_,
            debtRates_
        );
    }

    /**
     * @notice Checks if input data meets requirements
     * @param accountAssetsLength The length of borrower's accountAssets array
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18).
     * @dev Indexes for arrays accountAssets && debtRates match each other
     */
    function verifyExternalData(
        uint256 accountAssetsLength,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) internal pure {
        uint256 debtRatesLength = debtRates_.length;
        uint256 seizeIndexesLength = seizeIndexes_.length;

        require(accountAssetsLength != 0 && debtRatesLength == accountAssetsLength, ErrorCodes.LQ_INVALID_DRR_ARRAY);
        require(
            seizeIndexesLength != 0 && seizeIndexesLength <= accountAssetsLength,
            ErrorCodes.LQ_INVALID_SEIZE_ARRAY
        );

        // Check all DRR are <= 100%
        for (uint256 i = 0; i < debtRatesLength; i++) {
            require(debtRates_[i] <= EXP_SCALE, ErrorCodes.LQ_INVALID_DEBT_REDEMPTION_RATE);
        }

        // Check all seizeIndexes are <= to (accountAssetsLength - 1)
        for (uint256 i = 0; i < seizeIndexesLength; i++) {
            require(seizeIndexes_[i] <= (accountAssetsLength - 1), ErrorCodes.LQ_INVALID_SEIZE_INDEX);
            // Check seizeIndexes array does not contain duplicates
            for (uint256 j = i + 1; j < seizeIndexesLength; j++) {
                require(seizeIndexes_[i] != seizeIndexes_[j], ErrorCodes.LQ_DUPLICATE_SEIZE_INDEX);
            }
        }
    }

    /**
     * @notice Accrues interest for all required borrower's markets
     * @dev Accrue is required if market is used as borrow (debtRate > 0)
     *      or collateral (seizeIndex arr contains market index)
     *      The caller must ensure that the lengths of arrays 'accountAssets' and 'debtRates' are the same,
     *      array 'seizeIndexes' does not contain duplicates and none of the indexes exceeds the value
     *      (accountAssets.length - 1).
     * @param accountAssets An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     */
    function accrue(
        MToken[] memory accountAssets,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) public {
        for (uint256 i = 0; i < accountAssets.length; i++) {
            //slither-disable-next-line calls-loop
            if (debtRates_[i] > 0 || includes(i, seizeIndexes_)) accountAssets[i].accrueInterest();
        }
    }

    /**
     * @notice Determines whether an array includes a certain value among its entries
     * @param index_ The value to search for
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     * @return bool Returning true or false as appropriate.
     */
    function includes(uint256 index_, uint256[] memory seizeIndexes_) internal pure returns (bool) {
        for (uint256 i = 0; i < seizeIndexes_.length; i++) {
            if (seizeIndexes_[i] == index_) return true;
        }
        return false;
    }

    /**
     * @dev Local marketParams for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct MarketParams {
        uint256 supplyWrap;
        uint256 borrowUnderlying;
        uint256 exchangeRateMantissa;
        uint256 liquidationFeeMantissa;
        uint256 utilisationFactorMantissa;
    }

    /**
     * @notice For each market calculates the liquidation amounts based on borrower's state.
     * @param account_ The address of the borrower
     * @param marketAddresses An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     * @return accountState Struct that contains all balance parameters
     *         All arrays calculated in underlying assets, all total values calculated in USD.
     *         (the array indexes match each other)
     */
    function calculateLiquidationAmounts(
        address account_,
        MToken[] memory marketAddresses,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) public view virtual returns (AccountLiquidationAmounts memory accountState) {
        uint256 actualSeizeUsd = 0;
        uint256 accountMarketsLen = marketAddresses.length;
        uint256[] memory supplyAmountsUsd = new uint256[](accountMarketsLen);
        uint256[] memory oraclePrices = new uint256[](accountMarketsLen);

        accountState.repayAmounts = new uint256[](accountMarketsLen);
        accountState.seizeAmounts = new uint256[](accountMarketsLen);

        // For each market the borrower is in calculate liquidation amounts
        for (uint256 i = 0; i < accountMarketsLen; i++) {
            MToken market = marketAddresses[i];

            oraclePrices[i] = oracle.getUnderlyingPrice(market);
            require(oraclePrices[i] > 0, ErrorCodes.INVALID_PRICE);

            //slither-disable-next-line uninitialized-local
            MarketParams memory vars;
            (vars.supplyWrap, vars.borrowUnderlying, vars.exchangeRateMantissa) = market.getAccountSnapshot(account_);
            (vars.liquidationFeeMantissa, vars.utilisationFactorMantissa) = supervisor.getMarketData(market);

            if (vars.borrowUnderlying > 0) {
                // accountTotalBorrowUsd += borrowUnderlying * oraclePrice
                uint256 accountBorrowUsd = (vars.borrowUnderlying * oraclePrices[i]) / EXP_SCALE;
                accountState.accountTotalBorrowUsd += accountBorrowUsd;

                // accountPresumedTotalSeizeUsd parameter showing what the totalSeize would be under the condition of
                // complete liquidation.
                // accountPresumedTotalSeizeUsd += borrowUnderlying * oraclePrice * (1 + liquidationFee)
                uint256 fullSeizeUsd = (accountBorrowUsd * (vars.liquidationFeeMantissa + EXP_SCALE)) / EXP_SCALE;
                accountState.accountPresumedTotalSeizeUsd += fullSeizeUsd;

                // repayAmountUnderlying = borrowUnderlying * redemptionRate
                // actualSeizeUsd += borrowUnderlying * oraclePrice * (1 + liquidationFee) * redemptionRate
                if (debtRates_[i] > 0) {
                    accountState.repayAmounts[i] = (vars.borrowUnderlying * debtRates_[i]) / EXP_SCALE;
                    actualSeizeUsd += (fullSeizeUsd * debtRates_[i]) / EXP_SCALE;
                }
            }

            if (vars.supplyWrap > 0) {
                // supplyAmount = supplyWrap * exchangeRate
                uint256 supplyAmount = (vars.supplyWrap * vars.exchangeRateMantissa) / EXP_SCALE;

                // accountTotalSupplyUsd += supplyWrap * exchangeRate * oraclePrice
                uint256 accountSupplyUsd = (supplyAmount * oraclePrices[i]) / EXP_SCALE;
                accountState.accountTotalSupplyUsd += accountSupplyUsd;
                supplyAmountsUsd[i] = accountSupplyUsd;

                // accountTotalCollateralUsd += accountSupplyUSD * utilisationFactor
                accountState.accountTotalCollateralUsd +=
                    (accountSupplyUsd * vars.utilisationFactorMantissa) /
                    EXP_SCALE;
            }
        }

        if (actualSeizeUsd > 0) {
            for (uint256 i = 0; i < seizeIndexes_.length; i++) {
                uint256 marketIndex = seizeIndexes_[i];
                uint256 marketSupply = supplyAmountsUsd[marketIndex];

                if (marketSupply <= actualSeizeUsd) {
                    accountState.seizeAmounts[marketIndex] = type(uint256).max;
                    actualSeizeUsd -= marketSupply;
                } else {
                    accountState.seizeAmounts[marketIndex] = (actualSeizeUsd * EXP_SCALE) / oraclePrices[marketIndex];
                    actualSeizeUsd = 0;
                    break;
                }
            }
            require(actualSeizeUsd == 0, ErrorCodes.LQ_INVALID_SEIZE_DISTRIBUTION);
        }
        return (accountState);
    }

    /**
     * @dev Burns collateral tokens at the borrower's address, transfer underlying assets
     *      to the deadDrop or ManualLiquidator address, if loan is not insignificant, otherwise, all account's
     *      collateral is credited to the protocolInterest. Process all borrower's markets.
     * @param borrower_ The account having collateral seized
     * @param marketAddresses_ Array of markets the borrower is in
     * @param seizeUnderlyingAmounts_ Array of seize amounts in underlying assets
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     *        protocolInterest
     * @param isManualLiquidation_ Marker for manual liquidation process.
     */
    function seize(
        address borrower_,
        MToken[] memory marketAddresses_,
        uint256[] memory seizeUnderlyingAmounts_,
        bool isLoanInsignificant_,
        bool isManualLiquidation_
    ) internal {
        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            uint256 seizeUnderlyingAmount = seizeUnderlyingAmounts_[i];
            if (seizeUnderlyingAmount > 0) {
                address receiver = isManualLiquidation_ ? msg.sender : address(deadDrop);

                MToken seizeMarket = marketAddresses_[i];
                seizeMarket.autoLiquidationSeize(borrower_, seizeUnderlyingAmount, isLoanInsignificant_, receiver);
            }
        }
    }

    /**
     * @dev Liquidator repays a borrow belonging to borrower. Process all borrower's markets.
     * @param borrower_ The account with the debt being payed off
     * @param marketAddresses_ Array of markets the borrower is in
     * @param repayAmounts_ Array of repay amounts in underlying assets
     * @param isManualLiquidation_ Marker for manual liquidation process.
     * Note: The calling code must be sure that the oracle price for all processed markets is greater than zero.
     */
    function repay(
        address borrower_,
        MToken[] memory marketAddresses_,
        uint256[] memory repayAmounts_,
        bool isManualLiquidation_
    ) internal {
        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            uint256 repayAmount = repayAmounts_[i];
            if (repayAmount > 0) {
                MToken repayMarket = marketAddresses_[i];

                if (isManualLiquidation_) {
                    repayMarket.addProtocolInterestBehalf(msg.sender, repayAmount);
                }

                repayMarket.autoLiquidationRepayBorrow(borrower_, repayAmount);
            }
        }
    }

    /**
     * @dev Approve that current healthy factor satisfies the condition:
     *      currentHealthyFactor <= healthyFactorLimit
     * @param borrower_ The account with the debt being payed off
     * @param marketAddresses_ Array of markets the borrower is in
     * @return Whether or not the current account healthy factor is correct
     */
    function approveBorrowerHealthyFactor(address borrower_, MToken[] memory marketAddresses_)
        internal
        view
        returns (bool)
    {
        uint256 accountTotalCollateral = 0;
        uint256 accountTotalBorrow = 0;

        uint256 supplyWrap;
        uint256 borrowUnderlying;
        uint256 exchangeRateMantissa;
        uint256 utilisationFactorMantissa;

        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            MToken market = marketAddresses_[i];
            uint256 oraclePriceMantissa = oracle.getUnderlyingPrice(market);
            require(oraclePriceMantissa > 0, ErrorCodes.INVALID_PRICE);

            (supplyWrap, borrowUnderlying, exchangeRateMantissa) = market.getAccountSnapshot(borrower_);

            if (borrowUnderlying > 0) {
                accountTotalBorrow += ((borrowUnderlying * oraclePriceMantissa) / EXP_SCALE);
            }
            if (supplyWrap > 0) {
                (, utilisationFactorMantissa) = supervisor.getMarketData(market);
                uint256 supplyAmountUsd = ((((supplyWrap * exchangeRateMantissa) / EXP_SCALE) * oraclePriceMantissa) /
                    EXP_SCALE);
                accountTotalCollateral += (supplyAmountUsd * utilisationFactorMantissa) / EXP_SCALE;
            }
        }
        // currentHealthyFactor = accountTotalCollateral / accountTotalBorrow
        uint256 currentHealthyFactor = (accountTotalCollateral * EXP_SCALE) / accountTotalBorrow;

        return (currentHealthyFactor <= healthyFactorLimit);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new value for healthyFactorLimit
     */
    function setHealthyFactorLimit(uint256 newValue_) external onlyRole(TIMELOCK) {
        uint256 oldValue = healthyFactorLimit;

        require(newValue_ != oldValue, ErrorCodes.IDENTICAL_VALUE);
        healthyFactorLimit = newValue_;

        emit HealthyFactorLimitChanged(oldValue, newValue_);
    }

    /**
     * @notice Sets a new supervisor for the market
     */
    function setSupervisor(Supervisor newSupervisor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            newSupervisor_.supportsInterface(type(SupervisorInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );

        Supervisor oldSupervisor = supervisor;
        supervisor = newSupervisor_;

        emit NewSupervisor(oldSupervisor, newSupervisor_);
    }

    /**
     * @notice Sets a new price oracle for the liquidation contract
     */
    function setPriceOracle(PriceOracle newOracle_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOracle_ == supervisor.oracle(), ErrorCodes.NEW_ORACLE_MISMATCH);

        PriceOracle oldOracle = oracle;
        oracle = newOracle_;

        emit NewPriceOracle(oldOracle, newOracle_);
    }

    /**
     * @notice Sets a new minterest deadDrop
     */
    function setDeadDrop(DeadDrop newDeadDrop_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(newDeadDrop_) != address(0), ErrorCodes.ZERO_ADDRESS);
        DeadDrop oldDeadDrop = deadDrop;
        deadDrop = newDeadDrop_;

        emit NewDeadDrop(oldDeadDrop, newDeadDrop_);
    }

    /**
     * @notice Sets a new insignificantLoanThreshold
     */
    function setInsignificantLoanThreshold(uint256 newValue_) external onlyRole(TIMELOCK) {
        uint256 oldValue = insignificantLoanThreshold;
        insignificantLoanThreshold = newValue_;

        emit NewInsignificantLoanThreshold(oldValue, newValue_);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Governance/Mnt.sol";
import "./Buyback.sol";
import "./ErrorCodes.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 *
 * Interface.
 *
 * - `withdraw` - withdraw released tokens.
 * - `createVestingSchedule` - allows admin to create a new vesting schedule for an account.
 * - `revokeVestingSchedule` - allows admin to revoke the vesting schedule. Tokens already vested
 * transfer to the account, the rest are returned to the vesting contract.
 */

contract Vesting is AccessControl {
    /**
     * @notice The structure is used in the contract constructor for create vesting schedules
     * during contract deploying.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * @param revocable whether the vesting is revocable or not.
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice Vesting schedules of an account.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * `released amount` of tokens to his address.
     * @param revocable whether the vesting is revocable or not.
     */
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice The address of the Minterest governance token.
     */
    IERC20 public mnt;

    /**
     * @notice Vesting schedule of an account.
     */
    mapping(address => VestingSchedule) public schedules;

    /**
     * @notice The number of MNT tokens that are currently not allocated in the vesting. This number of tokens
     * is free and can used to create vesting schedule for accounts. When the contract are deployed,
     * all tokens (49,967,630 MNT tokens) are vested according to the account's vesting schedules
     * and this value is equal to zero.
     */
    uint256 public freeAllocation = 49_967_630 ether;

    /**
     * @notice The address of the Minterest buyback.
     */
    Buyback public buyback;

    /// @notice Whether or not the account is in the delay list
    mapping(address => bool) public delayList;

    /// @notice is stake function paused
    bool public isWithdrawPaused;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    /// @notice An event that's emitted when a new vesting schedule for a account is created.
    event VestingScheduleAdded(address target, VestingSchedule schedule);

    /// @notice An event that's emitted when a vesting schedule revoked.
    event VestingScheduleRevoked(address target, uint256 unreleased, uint256 locked);

    /// @notice An event that's emitted when the account Withdrawn the released tokens.
    event Withdrawn(address, uint256 withdrawn);

    /// @notice Emitted when buyback is changed
    event NewBuyback(Buyback oldBuyback, Buyback newBuyback);

    /// @notice Emitted when an action is paused
    event VestingActionPaused(string action, bool pauseState);

    /// @notice Emitted when an account is added to the delay list
    event AddedToDelayList(address account);

    /// @notice Emitted when an account is removed from the delay list
    event RemovedFromDelayList(address account);

    /**
     * @notice Construct a vesting contract.
     * @param _admin The address of the Admin
     * @param _mnt The address of the MNT contract.
     */
    constructor(address _admin, IERC20 _mnt) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        mnt = _mnt;
    }

    function setBuyback(Buyback buyback_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Buyback oldBuyback = buyback;
        require(oldBuyback != buyback_, ErrorCodes.IDENTICAL_VALUE);
        buyback = buyback_;
        emit NewBuyback(oldBuyback, buyback_);
    }

    /**
     * @notice function to change withdraw enabled mode
     * @param isPaused_ new state of stake allowance
     */
    function setWithdrawPaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit VestingActionPaused("Withdraw", isPaused_);
        isWithdrawPaused = isPaused_;
    }

    /**
     * @notice Withdraw the specified number of tokens. For a successful transaction, the requirement
     * `amount_ > 0 && amount_ <= unreleased` must be met.
     * If `amount_ == MaxUint256` withdraw all unreleased tokens.
     * @param amount_ The number of tokens to withdraw.
     */
    function withdraw(uint256 amount_) external {
        require(!isWithdrawPaused, ErrorCodes.OPERATION_PAUSED);
        require(!delayList[msg.sender], ErrorCodes.DELAY_LIST_LIMIT);

        VestingSchedule storage schedule = schedules[msg.sender];

        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULES);

        uint256 unreleased = releasableAmount(msg.sender);
        if (amount_ == type(uint256).max) {
            amount_ = unreleased;
        }
        require(amount_ > 0 && amount_ <= unreleased, ErrorCodes.INSUFFICIENT_UNRELEASED_TOKENS);

        uint256 mntRemaining = mnt.balanceOf(address(this));
        require(amount_ <= mntRemaining, ErrorCodes.INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT);

        schedule.released = schedule.released + amount_;
        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released == schedule.totalAmount) {
            delete schedules[msg.sender];
        }

        emit Withdrawn(msg.sender, amount_);
        if (buyback != Buyback(address(0))) buyback.restakeFor(msg.sender);

        require(mnt.transfer(msg.sender, amount_));
    }

    /// @notice Allows the admin to create a new vesting schedules.
    /// @param schedulesData an array of vesting schedules that will be created.
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = schedulesData.length;

        uint256 mntRemaining = mnt.balanceOf(address(this));
        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            ensureValidVestingSchedule(schedule.target, schedule.start, schedule.totalAmount);
            require(schedules[schedule.target].start == 0, ErrorCodes.VESTING_SCHEDULE_ALREADY_EXISTS);

            require(
                freeAllocation >= schedule.totalAmount && mntRemaining >= freeAllocation,
                ErrorCodes.INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE
            );

            schedules[schedule.target] = VestingSchedule({
                totalAmount: schedule.totalAmount,
                released: 0,
                start: schedule.start,
                duration: schedule.duration,
                revocable: schedule.revocable
            });

            //slither-disable-next-line costly-loop
            freeAllocation -= schedule.totalAmount;

            emit VestingScheduleAdded(schedule.target, schedules[schedule.target]);
            //slither-disable-next-line calls-loop
            if (buyback != Buyback(address(0))) buyback.restakeFor(schedule.target);
        }
    }

    /// @notice Allows the admin to revoke the vesting schedule. Tokens already vested
    ///  transfer to the account, the rest are returned to the vesting contract.
    /// @param target_ the address from which the vesting schedule is revoked.
    function revokeVestingSchedule(address target_) external onlyRole(GATEKEEPER) {
        require(schedules[target_].start != 0, ErrorCodes.NO_VESTING_SCHEDULE);
        require(schedules[target_].revocable, ErrorCodes.SCHEDULE_IS_IRREVOCABLE);

        uint256 locked = lockedAmount(target_);
        uint256 unreleased = releasableAmount(target_);
        uint256 mntRemaining = mnt.balanceOf(address(this));

        require(mntRemaining >= unreleased, ErrorCodes.INSUFFICIENT_TOKENS_FOR_RELEASE);

        freeAllocation += locked;
        delete schedules[target_];
        delete delayList[target_];

        emit VestingScheduleRevoked(target_, unreleased, locked);
        if (buyback != Buyback(address(0))) buyback.restakeFor(target_);

        require(mnt.transfer(target_, unreleased));
    }

    /// @notice Calculates the end of the vesting.
    /// @param who_ account address for which the parameter is returned.
    /// @return the end of the vesting.
    function endOfVesting(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return uint256(schedule.start) + uint256(schedule.duration);
    }

    /// @notice Calculates locked amount for a given `time`.
    /// @param who_ account address for which the parameter is returned.
    /// @return locked amount for a given `time`.
    function lockedAmount(address who_) public view returns (uint256) {
        // lockedAmount = (end - time) * totalAmount / duration;
        // if the parameter `duration` is zero, it means that the allocated tokens are not locked for address `who`.

        // solhint-disable-next-line not-rely-on-time
        uint256 _now = getTime();
        VestingSchedule storage schedule = schedules[who_];

        uint256 _start = uint256(schedule.start);
        uint256 _duration = uint256(schedule.duration);
        uint256 _end = _start + _duration;
        if (schedule.duration == 0 || _now > _end) {
            return 0;
        }
        if (_now < _start) {
            return schedule.totalAmount;
        }
        return ((_end - _now) * schedule.totalAmount) / _duration;
    }

    /// @notice Calculates the amount that has already vested.
    /// @param who_ account address for which the parameter is returned.
    /// @return the amount that has already vested.
    function vestedAmount(address who_) public view returns (uint256) {
        return schedules[who_].totalAmount - lockedAmount(who_);
    }

    /// @notice Calculates the amount that has already vested but hasn't been released yet.
    /// @param who_ account address for which the parameter is returned.
    /// @return the amount that has already vested but hasn't been released yet.
    function releasableAmount(address who_) public view returns (uint256) {
        return vestedAmount(who_) - schedules[who_].released;
    }

    /// @notice Checks if the Vesting schedule is correct.
    /// @param target_ the address on which the vesting schedule is created.
    /// @param start_ the time (as Unix time) at which point vesting starts.
    /// @param amount_ the balance for which the vesting schedule is created.
    function ensureValidVestingSchedule(
        address target_,
        uint32 start_,
        uint256 amount_
    ) public pure {
        require(target_ != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
        require(amount_ > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        // Star should not be zero, because this parameter is used to check for the existence of a schedule.
        require(start_ > 0, ErrorCodes.SCHEDULE_START_IS_ZERO);
    }

    /// @notice Add an account with revocable schedule to the delay list
    /// @param who_ The account that is being added to the delay list
    function addToDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(schedules[who_].revocable, ErrorCodes.SHOULD_HAVE_REVOCABLE_SCHEDULE);
        emit AddedToDelayList(who_);
        delayList[who_] = true;
    }

    /// @notice Remove an account from the delay list
    /// @param who_ The account that is being removed from the delay list
    function removeFromDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(delayList[who_], ErrorCodes.MEMBER_NOT_IN_DELAY_LIST);
        emit RemovedFromDelayList(who_);
        delete delayList[who_];
    }

    /// @return timestamp truncated to minutes
    //slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp / 1 minutes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IERC20Votes.sol";
import "./MntErrorCodes.sol";
import "./MntGovernor.sol";

/**
 * @dev Extension of MNT token based on OpenZeppelin ERC20Votes Compound-like voting v4.2 with reduced features.
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * Token balance does not account for voting power, instead Buyback contract is responsible for updating the
 * voting power during the stake and unstake actions performed by the account. This extension requires accounts to
 * delegate to themselves in order to activate checkpoints and have their voting power tracked.
 */
abstract contract MntVotes is IERC20Votes, ERC20Permit, AccessControl {
    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] internal _totalSupplyCheckpoints;

    /// @dev Will be used instead of token balances for the accounts
    mapping(address => uint224) private _votingBalance;

    /// @dev Buyback will push this value after each account weight update, so we don't have to pull it
    /// when new proposal acquired and total supply checkpoint should be added to the list
    /// this will cost some gas every call but allows to keep total votes logic in the buyback
    uint224 private _totalVotesCurrent;

    address private buyback;

    MntGovernor public governor;

    uint256 public constant SECS_PER_YEAR = 365 * 24 * 60 * 60;

    /// @notice If the account has not voted within this time, admin can call the method `leaveOnBehalf()` for him from
    /// Minterest buyback system
    uint256 public maxNonVotingPeriod = SECS_PER_YEAR;

    /// @notice timestamp of last vote for accounts
    mapping(address => uint256) public lastVotingTimestamp;

    /// @notice timestamp of the last delegation of votes for the account
    mapping(address => uint256) public lastDelegatingTimestamp;

    /// @notice Emitted when buyback is set
    event NewBuyback(address oldBuyback, address newBuyback);

    /// @notice Emitted when governor is set
    event NewGovernor(MntGovernor oldGovernor, MntGovernor newGovernor);

    event MaxNonVotingPeriodChanged(uint256 oldValue, uint256 newValue);

    /// @notice Emitted when total votes updated
    event TotalVotesUpdated(uint224 oldTotalVotes, uint224 newTotalVotes);

    /// @notice Emitted when account votes updated
    event VotesUpdated(address account, uint224 oldVotingPower, uint224 newVotingPower);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, MntErrorCodes.MV_BLOCK_NOT_YET_MINED);
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all discounted MNTs
     * staked to buyback contract in order to get Buyback rewards and to participate in the voting process.
     * Requirements:
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, MntErrorCodes.MV_BLOCK_NOT_YET_MINED);
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // Each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        //solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= expiry, MntErrorCodes.MV_SIGNATURE_EXPIRED);
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), MntErrorCodes.MV_INVALID_NONCE);
        _delegate(signer, delegatee);
    }

    /**
     * @dev Mint does not change voting power.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
    }

    /**
     * @dev We don't move voting power when tokens are transferred.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = _votingBalance[delegator];
        _delegates[delegator] = delegatee;

        if (lastVotingTimestamp[currentDelegate] > lastDelegatingTimestamp[delegator])
            lastVotingTimestamp[delegator] = lastVotingTimestamp[currentDelegate];
        lastDelegatingTimestamp[delegator] = block.timestamp;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint256 oldWeight;
                uint256 newWeight;
                (oldWeight, newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                uint256 oldWeight;
                uint256 newWeight;
                (oldWeight, newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        // Don't create new checkpoint if votes change in the same block
        // slither-disable-next-line incorrect-equality
        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    // slither-disable-next-line dead-code
    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    // slither-disable-next-line dead-code
    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    // end of OpenZeppelin implementation; MNT-specific code listed below

    /// @dev Throws if called by any account other than the buyback.
    modifier buybackOnly() {
        require(buyback != address(0) && buyback == msg.sender, MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /// @dev Throws if called by any account other than the governor.
    modifier governorOnly() {
        require(governor != MntGovernor(payable(0)) && address(governor) == msg.sender, MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /// @notice Set buyback implementation that is responsible for voting power calculations
    function setBuyback(address newBuyback) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBuyback != address(0), MntErrorCodes.ZERO_ADDRESS);
        address oldBuyback = buyback;
        buyback = newBuyback;
        emit NewBuyback(oldBuyback, newBuyback);
    }

    /// @notice Set governor implementation that is responsible for voting
    function setGovernor(MntGovernor newGovernor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(newGovernor_) != address(0), MntErrorCodes.ZERO_ADDRESS);
        MntGovernor oldGovernor = governor;
        require(oldGovernor == MntGovernor(payable(0)), MntErrorCodes.SECOND_INITIALIZATION);
        governor = newGovernor_;
        emit NewGovernor(oldGovernor, newGovernor_);
    }

    /// @notice Update votes for account and total voting volume on the current block
    function updateVotesForAccount(
        address account,
        uint224 balance,
        uint224 volume
    ) external buybackOnly {
        require(account != address(0), MntErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);

        // update total votes volume
        _totalVotesCurrent = volume;

        // update voting power
        uint224 oldBalance = _votingBalance[account];
        if (oldBalance == balance) {
            // don't create new point and return immediately
            return;
        }

        if (oldBalance < balance) {
            // increase voting balance of account and voting power of its delegatee
            uint224 delta = balance - oldBalance;
            _votingBalance[account] = balance;
            // "mint" some voting power
            _moveVotingPower(address(0), delegates(account), delta);
        } else {
            // decrease voting balance of account and voting power of its delegatee
            uint224 delta = oldBalance - balance;
            _votingBalance[account] = balance;
            // "burn" some voting power
            _moveVotingPower(delegates(account), address(0), delta);
        }

        emit VotesUpdated(account, oldBalance, _votingBalance[account]);
    }

    /// @notice Create checkpoint by voting volume on the current block
    function updateTotalVotes() external governorOnly {
        if (_totalSupplyCheckpoints.length > 0) {
            uint224 oldVotes = _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes;
            if (oldVotes > _totalVotesCurrent) {
                _writeCheckpoint(_totalSupplyCheckpoints, _subtract, oldVotes - _totalVotesCurrent);
            } else {
                _writeCheckpoint(_totalSupplyCheckpoints, _add, _totalVotesCurrent - oldVotes);
            }

            emit TotalVotesUpdated(oldVotes, _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes);
        } else {
            _writeCheckpoint(_totalSupplyCheckpoints, _add, _totalVotesCurrent);

            emit TotalVotesUpdated(0, _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes);
        }
    }

    /// @notice Checks user activity for the last `maxNonVotingPeriod` blocks
    /// @param account_ The address of the account
    /// @return returns true if the user voted or his delegatee voted for the last maxNonVotingPeriod blocks,
    /// otherwise returns false
    function isParticipantActive(address account_) public view virtual returns (bool) {
        return lastActivityTimestamp(account_) > block.timestamp - maxNonVotingPeriod;
    }

    /// @notice Gets the latest voting timestamp for account.
    /// @dev If the user delegated his votes, then it also checks the timestamp of the last vote of the delegatee
    /// @param account_ The address of the account
    /// @return latest voting timestamp for account
    function lastActivityTimestamp(address account_) public view virtual returns (uint256) {
        address delegatee = _delegates[account_];
        uint256 lastVoteAccount = lastVotingTimestamp[account_];

        // if the votes are not delegated to anyone, then we return the timestamp of the last vote of the account
        if (delegatee == address(0)) return lastVoteAccount;
        uint256 lastVoteDelegatee = lastVotingTimestamp[delegatee];

        // if delegatee voted after delegation, then returns the timestamp for the delegatee
        if (lastVoteDelegatee > lastDelegatingTimestamp[account_]) {
            return lastVoteDelegatee;
        }

        return lastVoteAccount;
    }

    /**
     * @notice Sets the maxNonVotingPeriod
     * @dev Admin function to set maxNonVotingPeriod
     * @param newPeriod_ The new maxNonVotingPeriod (in sec). Must be greater than 90 days and lower than 2 years.
     */
    function setMaxNonVotingPeriod(uint256 newPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPeriod_ >= 90 days && newPeriod_ <= 2 * SECS_PER_YEAR, MntErrorCodes.MNT_INVALID_NONVOTING_PERIOD);

        uint256 oldPeriod = maxNonVotingPeriod;
        require(newPeriod_ != oldPeriod, MntErrorCodes.IDENTICAL_VALUE);

        emit MaxNonVotingPeriodChanged(oldPeriod, newPeriod_);
        maxNonVotingPeriod = newPeriod_;
    }

    /**
     * @notice function to change lastVotingTimestamp
     * @param account_ The address of the account
     * @param timestamp_ New timestamp of account user last voting
     */
    function setLastVotingTimestamp(address account_, uint256 timestamp_) external governorOnly {
        lastVotingTimestamp[account_] = timestamp_;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Votes is IERC20 {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function delegates(address owner) external view returns (address);

    function checkpoints(address account, uint32 pos) external view returns (Checkpoint memory);

    function numCheckpoints(address account) external view returns (uint32);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

library MntErrorCodes {
    string internal constant UNAUTHORIZED = "E102";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E225";
    string internal constant MV_BLOCK_NOT_YET_MINED = "E262";
    string internal constant MV_SIGNATURE_EXPIRED = "E263";
    string internal constant MV_INVALID_NONCE = "E264";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E420";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MntVotes.sol";
import "./MntErrorCodes.sol";

contract MntGovernor is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovernorTimelockControlUpgradeable
{
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor() initializer {} /* solhint-disable-line no-empty-blocks */

    function initialize(ERC20VotesUpgradeable _token, TimelockControllerUpgradeable _timelock) external initializer {
        __Governor_init("MntGovernor");
        __GovernorSettings_init(
            720, // Set voting delay between the proposal and voting period to 3 hours (in blocks, 15 second per block)
            40320, // Set voting period to 1 week of (in blocks, 15 second per block)
            100e18 // Set minimal voting power required to create the proposal to 100 MNT
        );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);

        // Set % of quorum required for a proposal to pass. Usually it is about 4% of total token supply
        // available. We use Buyback weights as voting power, it is available only for accounts that
        // committed to perform voting actions by participating in Buyback, so quorum is going to be
        // much higher. We set 30% votes of the participants that vote For or Abstain for proposal to be applied
        __GovernorVotesQuorumFraction_init(30);
        __GovernorTimelockControl_init(_timelock);
    }

    /**
     * @dev Modifier to make a function callable only by a proposer role defined in timelock contract.
     */
    modifier onlyProposer() {
        AccessControlUpgradeable ac = AccessControlUpgradeable(timelock());
        require(ac.hasRole(PROPOSER_ROLE, msg.sender), MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /**
     * @dev Modifier to make a function callable only by a proposer role defined in timelock contract. In
     * addition to checking the sender's role, `address(0)` 's role is also considered. Granting a role
     * to `address(0)` is equivalent to enabling this role for everyone.
     */
    modifier onlyProposerOrOpenRole() {
        AccessControlUpgradeable ac = AccessControlUpgradeable(timelock());
        require(
            ac.hasRole(PROPOSER_ROLE, msg.sender) || ac.hasRole(PROPOSER_ROLE, address(0)),
            MntErrorCodes.UNAUTHORIZED
        );
        _;
    }

    // The following functions are overrides required by Solidity.

    /// @notice Delay (in number of blocks) since the proposal is submitted until voting power is fixed and voting
    /// starts. This can be used to enforce a delay after a proposal is published for users to buy tokens,
    /// or delegate their votes.
    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /// @notice Delay (in number of blocks) since the proposal starts until voting ends.
    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /// @notice Quorum required for a proposal to be successful. This function includes a blockNumber argument so
    /// the quorum can adapt through time
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /// @notice Voting power of an account at a specific blockNumber.
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @notice Current state of a proposal, see the { ProposalState } for details.
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @notice Create a new proposal. Vote start votingDelay blocks after the proposal is created and ends
    /// votingPeriod blocks after the voting starts. Emits a ProposalCreated event.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) onlyProposerOrOpenRole returns (uint256) {
        MntVotes(address(token)).updateTotalVotes();
        return super.propose(targets, values, calldatas, description);
    }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    //slither-disable-next-line dead-code
    function _execute(
        uint256,
        address[] memory,
        uint256[] memory,
        bytes[] memory,
        bytes32
    ) internal pure override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        revert();
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external onlyProposer returns (uint256) {
        return _cancel(targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal override returns (uint256) {
        // We write the timestamp of the last vote of the account
        MntVotes mntVotes = MntVotes(address(token));
        mntVotes.setLastVotingTimestamp(account, block.timestamp);
        return super._castVote(proposalId, account, support, reason);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/Governor.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSAUpgradeable.sol";
import "../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../utils/math/SafeCastUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/TimersUpgradeable.sol";
import "./IGovernorUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract GovernorUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, EIP712Upgradeable, IGovernorUpgradeable {
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    /**
     * @dev Restrict access to governor executing address. Some module might override the _executor function to make
     * sure this modifier is consistant with the execution model.
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    function __Governor_init(string memory name_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __EIP712_init_unchained(name_, version());
        __IGovernor_init_unchained();
        __Governor_init_unchained(name_);
    }

    function __Governor_init_unchained(string memory name_) internal onlyInitializing {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IGovernorUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * accross multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore memory proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.voteStart.getDeadline() >= block.number) {
            return ProposalState.Pending;
        } else if (proposal.voteEnd.getDeadline() >= block.number) {
            return ProposalState.Active;
        } else if (proposal.voteEnd.isExpired()) {
            return
                _quorumReached(proposalId) && _voteSucceeded(proposalId)
                    ? ProposalState.Succeeded
                    : ProposalState.Defeated;
        } else {
            revert("Governor: unknown proposal id");
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(msg.sender, block.number - 1) >= proposalThreshold(),
            "GovernorCompatibilityBravo: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _execute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overriden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = getVotes(account, proposal.voteStart.getDeadline());
        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight, reason);

        return weight;
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettingsUpgradeable is Initializable, GovernorUpgradeable {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    function __GovernorSettings_init(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorSettings_init_unchained(initialVotingDelay, initialVotingPeriod, initialProposalThreshold);
    }

    function __GovernorSettings_init_unchained(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimpleUpgradeable is Initializable, GovernorUpgradeable {
    function __GovernorCountingSimple_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorCountingSimple_init_unchained();
    }

    function __GovernorCountingSimple_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "../../utils/math/MathUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesUpgradeable is Initializable, GovernorUpgradeable {
    ERC20VotesUpgradeable public token;

    function __GovernorVotes_init(ERC20VotesUpgradeable tokenAddress) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorVotes_init_unchained(tokenAddress);
    }

    function __GovernorVotes_init_unchained(ERC20VotesUpgradeable tokenAddress) internal onlyInitializing {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {IGovernor-getVotes}).
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "./GovernorVotesUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFractionUpgradeable is Initializable, GovernorVotesUpgradeable {
    uint256 private _quorumNumerator;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    function __GovernorVotesQuorumFraction_init(uint256 quorumNumeratorValue) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __GovernorVotesQuorumFraction_init_unchained(quorumNumeratorValue);
    }

    function __GovernorVotesQuorumFraction_init_unchained(uint256 quorumNumeratorValue) internal onlyInitializing {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumerator;
    }

    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
    }

    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = _quorumNumerator;
        _quorumNumerator = newQuorumNumerator;

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "./IGovernorTimelockUpgradeable.sol";
import "../GovernorUpgradeable.sol";
import "../TimelockControllerUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (an ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * _Available since v4.3._
 */
abstract contract GovernorTimelockControlUpgradeable is Initializable, IGovernorTimelockUpgradeable, GovernorUpgradeable {
    TimelockControllerUpgradeable private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    function __GovernorTimelockControl_init(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __IGovernor_init_unchained();
        __IGovernorTimelock_init_unchained();
        __GovernorTimelockControl_init_unchained(timelockAddress);
    }

    function __GovernorTimelockControl_init_unchained(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, GovernorUpgradeable) returns (bool) {
        return interfaceId == type(IGovernorTimelockUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overriden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overriden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overriden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled and executed using the {Governor} workflow.
     */
    function updateTimelock(TimelockControllerUpgradeable newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockControllerUpgradeable newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library TimersUpgradeable {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorUpgradeable is Initializable, IERC165Upgradeable {
    function __IGovernor_init() internal onlyInitializing {
        __IGovernor_init_unchained();
    }

    function __IGovernor_init_unchained() internal onlyInitializing {
    }
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast.
     *
     * Note: `support` values should be seen as buckets. There interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
     * quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20PermitUpgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../utils/math/SafeCastUpgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20VotesUpgradeable is Initializable, ERC20PermitUpgradeable {
    function __ERC20Votes_init_unchained() internal onlyInitializing {
    }
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        __Context_init_unchained();
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "../IGovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelockUpgradeable is Initializable, IGovernorUpgradeable {
    function __IGovernorTimelock_init() internal onlyInitializing {
        __IGovernor_init_unchained();
        __IGovernorTimelock_init_unchained();
    }

    function __IGovernorTimelock_init_unchained() internal onlyInitializing {
    }
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControlUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockControllerUpgradeable is Initializable, AccessControlUpgradeable {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    function __TimelockController_init(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __TimelockController_init_unchained(minDelay, proposers, executors);
    }

    function __TimelockController_init_unchained(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) internal onlyInitializing {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Multicall.sol)

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./MToken.sol";
import "./ErrorCodes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DeadDrop is AccessControl {
    using SafeERC20 for IERC20;

    /// @notice Whitelist for markets allowed as a withdrawal destination.
    mapping(IERC20 => MToken) public allowedMarkets;
    /// @notice Whitelist for swap routers
    mapping(IUniswapV2Router02 => bool) public allowedSwapRouters;
    /// @notice Whitelist for users who can be a withdrawal recipients
    mapping(address => bool) public allowedWithdrawReceivers;
    /// @notice Whitelist for bots
    mapping(address => bool) public allowedBots;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GUARDIAN = bytes32(0x8b5b16d04624687fcf0d0228f19993c9157c1ed07b41d8d430fd9100eb099fe8);

    event WithdrewToProtocolInterest(uint256 amount, IERC20 token, MToken market);
    event SwapTokensForExactTokens(
        uint256 amountInMax,
        uint256 amountInActual,
        uint256 amountOut,
        IUniswapV2Router02 router,
        address[] path,
        uint256 deadline
    );
    event SwapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountOutActual,
        IUniswapV2Router02 router,
        address[] path,
        uint256 deadline
    );
    event Withdraw(address token, address to, uint256 amount);
    event NewAllowedSwapRouter(IUniswapV2Router01 router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedBot(address bot);
    event NewAllowedMarket(IERC20 token, MToken market);
    event AllowedSwapRouterRemoved(IUniswapV2Router01 router);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedBotRemoved(address bot);
    event AllowedMarketRemoved(IERC20 token, MToken market);

    constructor(address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GUARDIAN, admin_);
    }

    /************************************************************************/
    /*                          BOT FUNCTIONS                               */
    /************************************************************************/

    /**
     * @notice Withdraw underlying asset to market's protocol interest
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     */
    //slither-disable-next-line reentrancy-events
    function withdrawToProtocolInterest(uint256 amount, IERC20 underlying) external onlyRole(GUARDIAN) {
        MToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        underlying.safeIncreaseAllowance(address(market), amount);
        market.addProtocolInterest(amount);
        emit WithdrewToProtocolInterest(amount, underlying, market);
    }

    /**
     * @dev Wrapper over UniswapV2Router02 swapTokensForExactTokens()
     * @notice Withdraw token[0], change to token[1] on DEX and send result to market's protocol interest
     * @param amountInMax Max amount to swap
     * @param amountOut Exact amount to swap for
     * @param path Swap path 0 - source token, n - destination token
     * @param router UniswapV2Router02 router
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    //slither-disable-next-line reentrancy-events
    function swapTokensForExactTokens(
        uint256 amountInMax,
        uint256 amountOut,
        address[] memory path,
        IUniswapV2Router02 router,
        uint256 deadline
    ) external onlyRole(GUARDIAN) allowedRouter(router) {
        require(deadline >= block.timestamp, ErrorCodes.DD_EXPIRED_DEADLINE);
        IERC20 tokenIn = IERC20(path[0]);

        uint256 tokenInBalance = tokenIn.balanceOf(address(this));
        require(tokenInBalance >= amountInMax, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        tokenIn.safeIncreaseAllowance(address(router), amountInMax);
        //slither-disable-next-line unused-return
        router.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);

        uint256 newTokenInBalance = tokenIn.balanceOf(address(this));

        emit SwapTokensForExactTokens(
            amountInMax,
            tokenInBalance - newTokenInBalance,
            amountOut,
            router,
            path,
            deadline
        );
    }

    /**
     * @dev Wrapper over UniswapV2Router02 swapExactTokensForTokens()
     * @notice Withdraw token[0], change to token[1] on DEX and send result to market's protocol interest
     * @param amountIn Exact amount to swap
     * @param amountOutMin Min amount to swap for
     * @param path Swap path 0 - source token, n - destination token
     * @param router UniswapV2Router02 router
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    //slither-disable-next-line reentrancy-events
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        IUniswapV2Router02 router,
        uint256 deadline
    ) external onlyRole(GUARDIAN) allowedRouter(router) {
        require(deadline >= block.timestamp, ErrorCodes.DD_EXPIRED_DEADLINE);
        uint256 pathLength = path.length;
        IERC20 tokenIn = IERC20(path[0]);
        IERC20 tokenOut = IERC20(path[pathLength - 1]);

        require(tokenIn.balanceOf(address(this)) >= amountIn, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        uint256 tokenOutBalance = tokenOut.balanceOf(address(this));

        tokenIn.safeIncreaseAllowance(address(router), amountIn);
        //slither-disable-next-line unused-return
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint256 newTokenOutBalance = tokenOut.balanceOf(address(this));
        uint256 amountOutActual = newTokenOutBalance - tokenOutBalance;

        emit SwapExactTokensForTokens(amountIn, amountOutMin, amountOutActual, router, path, deadline);
    }

    /************************************************************************/
    /*                        ADMIN FUNCTIONS                               */
    /************************************************************************/

    /* --- LOGIC --- */

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Receipient address
     */
    //slither-disable-next-line reentrancy-events
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) allowedReceiversOnly(to) {
        require(underlying.balanceOf(address(this)) >= amount, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        underlying.safeTransfer(to, amount);
        emit Withdraw(address(underlying), to, amount);
    }

    /* --- SETTERS --- */

    /// @notice Add new market to the whitelist
    function addAllowedMarket(MToken market) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(market) != address(0), ErrorCodes.DD_MARKET_ADDRESS_IS_ZERO);
        require(
            market.supportsInterface(type(MTokenInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        allowedMarkets[market.underlying()] = market;
        emit NewAllowedMarket(market.underlying(), market);
    }

    /// @notice Add new IUniswapV2Router02 router to the whitelist
    function addAllowedRouter(IUniswapV2Router02 router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(router) != address(0), ErrorCodes.DD_ROUTER_ADDRESS_IS_ZERO);
        require(!allowedSwapRouters[router], ErrorCodes.DD_ROUTER_ALREADY_SET);
        allowedSwapRouters[router] = true;
        emit NewAllowedSwapRouter(router);
    }

    /// @notice Add new withdraw receiver address to the whitelist
    function addAllowedReceiver(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receiver != address(0), ErrorCodes.DD_RECEIVER_ADDRESS_IS_ZERO);
        require(!allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_ALREADY_SET);
        allowedWithdrawReceivers[receiver] = true;
        emit NewAllowedWithdrawReceiver(receiver);
    }

    /// @notice Add new bot address to the whitelist
    function addAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bot != address(0), ErrorCodes.DD_BOT_ADDRESS_IS_ZERO);
        require(!allowedBots[bot], ErrorCodes.DD_BOT_ALREADY_SET);
        allowedBots[bot] = true;
        emit NewAllowedBot(bot);
    }

    /* --- REMOVERS --- */

    /// @notice Remove market from the whitelist
    function removeAllowedMarket(IERC20 underlying) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_MARKET_NOT_FOUND);
        delete allowedMarkets[underlying];
        emit AllowedMarketRemoved(underlying, market);
    }

    /// @notice Remove IUniswapV2Router02 router from the whitelist
    function removeAllowedRouter(IUniswapV2Router02 router)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedRouter(router)
    {
        delete allowedSwapRouters[router];
        emit AllowedSwapRouterRemoved(router);
    }

    /// @notice Remove withdraw receiver address from the whitelist
    function removeAllowedReceiver(address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedReceiversOnly(receiver)
    {
        delete allowedWithdrawReceivers[receiver];
        emit AllowedWithdrawReceiverRemoved(receiver);
    }

    /// @notice Remove withdraw bot address from the whitelist
    function removeAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) allowedBotsOnly(bot) {
        delete allowedBots[bot];
        emit AllowedBotRemoved(bot);
    }

    /************************************************************************/
    /*                          INTERNAL FUNCTIONS                          */
    /************************************************************************/

    modifier allowedRouter(IUniswapV2Router02 router) {
        require(allowedSwapRouters[router], ErrorCodes.DD_ROUTER_NOT_FOUND);
        _;
    }

    modifier allowedReceiversOnly(address receiver) {
        require(allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_NOT_FOUND);
        _;
    }

    modifier allowedBotsOnly(address bot) {
        require(allowedBots[bot], ErrorCodes.DD_BOT_NOT_FOUND);
        _;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}