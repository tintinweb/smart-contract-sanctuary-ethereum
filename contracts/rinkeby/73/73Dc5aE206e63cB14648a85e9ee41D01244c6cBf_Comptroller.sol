// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "Token.sol";
import "TokenInterfaces.sol";
import "ErrorReporter.sol";
import "Price.sol";
import "ComptrollerInterface.sol";
import "ComptrollerStorage.sol";
import "Unitroller.sol";
import "Comp.sol";
contract Comptroller is ComptrollerV7Storage, ComptrollerInterface, ComptrollerErrorReporter, ExponentialNoError {
    /// @notice Emitted when an admin supports a market
    event MarketListed(Token token);

    /// @notice Emitted when an account enters a market
    event MarketEntered(Token token, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(Token token, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(Token token, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price Price is changed
    event NewPrice(Price oldPrice, Price newPrice);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(Token token, string action, bool pauseState);

    /// @notice Emitted when a new borrow-side COMP speed is calculated for a market
    event CompBorrowSpeedUpdated(Token indexed token, uint newSpeed);

    /// @notice Emitted when a new supply-side COMP speed is calculated for a market
    event CompSupplySpeedUpdated(Token indexed token, uint newSpeed);

    /// @notice Emitted when a new COMP speed is set for a contributor
    event ContributorCompSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when COMP is distributed to a supplier
    event DistributedSupplierComp(Token indexed token, address indexed supplier, uint compDelta, uint compSupplyIndex);

    /// @notice Emitted when COMP is distributed to a borrower
    event DistributedBorrowerComp(Token indexed token, address indexed borrower, uint compDelta, uint compBorrowIndex);

    /// @notice Emitted when borrow cap for a token is changed
    event NewBorrowCap(Token indexed token, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when COMP is granted by admin
    event CompGranted(address recipient, uint amount);

    /// @notice Emitted when COMP accrued for a user has been manually adjusted.
    event CompAccruedAdjusted(address indexed user, uint oldCompAccrued, uint newCompAccrued);

    /// @notice Emitted when COMP receivable for a user has been updated.
    event CompReceivableUpdated(address indexed user, uint oldCompReceivable, uint newCompReceivable);

    /// @notice The initial COMP index for a market
    uint224 public constant compInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    constructor() public {
        admin = msg.sender;
    }

    /*** Assets You Are In ***/
    function getAssetsIn(address account) external view returns (Token[] memory) {
        Token[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }
    function checkMembership(address account, Token token) external view returns (bool) {
        return markets[address(token)].accountMembership[account];
    }
    function enterMarkets(address[] memory tokens) public override returns (uint[] memory) {
        uint len = tokens.length;
        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            Token token = Token(tokens[i]);
            results[i] = uint(addToMarketInternal(token, msg.sender));
        }
        return results;
    }
    function addToMarketInternal(Token token, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(token)];
        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }
        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(token);
        emit MarketEntered(token, borrower);
        return Error.NO_ERROR;
    }
    function exitMarket(address tokenAddress) external override returns (uint) {
        Token token = Token(tokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the token */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = token.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code
        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }
        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(tokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }
        Market storage marketToExit = markets[address(token)];
        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }
        /* Set token account membership to false */
        delete marketToExit.accountMembership[msg.sender];
        /* Delete token from the account’s list of assets */
        // load into memory for faster iteration
        Token[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == token) {
                assetIndex = i;
                break;
            }
        }
        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);
        // copy last item in list to location of item to be removed, reduce length by 1
        Token[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();
        emit MarketExited(token, msg.sender);
        return uint(Error.NO_ERROR);
    }
    /*** Policy Hooks ***/
    function mintAllowed(address token, address minter, uint mintAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[token], "mint is paused");
        // Shh - currently unused
        minter;
        mintAmount;
        if (!markets[token].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        // Keep the flywheel moving
        updateCompSupplyIndex(token);
        distributeSupplierComp(token, minter);
        return uint(Error.NO_ERROR);
    }
    function mintVerify(address token, address minter, uint actualMintAmount, uint mintTokens) external override {
        // Shh - currently unused
        token;
        minter;
        actualMintAmount;
        mintTokens;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function redeemAllowed(address token, address redeemer, uint redeemTokens) external override returns (uint) {
        uint allowed = redeemAllowedInternal(token, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }
        // Keep the flywheel moving
        updateCompSupplyIndex(token);
        distributeSupplierComp(token, redeemer);
        return uint(Error.NO_ERROR);
    }
    function redeemAllowedInternal(address token, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[token].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[token].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }
        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, Token(token), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }
        return uint(Error.NO_ERROR);
    }
    function redeemVerify(address token, address redeemer, uint redeemAmount, uint redeemTokens) external override {
        // Shh - currently unused
        token;
        redeemer;
        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }
    function borrowAllowed(address token, address borrower, uint borrowAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[token], "borrow is paused");
        if (!markets[token].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        if (!markets[token].accountMembership[borrower]) {
            // only tokens may call borrowAllowed if borrower not in market
            require(msg.sender == token, "sender must be token");
            // attempt to add borrower to the market
            Error err = addToMarketInternal(Token(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }
            // it should be impossible to break the important invariant
            assert(markets[token].accountMembership[borrower]);
        }
        if (price.getUnderlyingPrice(Token(token)) == 0) {
            return uint(Error.PRICE_ERROR);
        }
        uint borrowCap = borrowCaps[token];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = Token(token).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, Token(token), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }
        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: Token(token).borrowIndex()});
        updateCompBorrowIndex(token, borrowIndex);
        distributeBorrowerComp(token, borrower, borrowIndex);
        return uint(Error.NO_ERROR);
    }
    function borrowVerify(address token, address borrower, uint borrowAmount) external override{
        // Shh - currently unused
        token;
        borrower;
        borrowAmount;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function repayBorrowAllowed(
        address token,
        address payer,
        address borrower,
        uint repayAmount) external override returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;
        if (!markets[token].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: Token(token).borrowIndex()});
        updateCompBorrowIndex(token, borrowIndex);
        distributeBorrowerComp(token, borrower, borrowIndex);
        return uint(Error.NO_ERROR);
        }
    function repayBorrowVerify(
        address token,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) external override {
        // Shh - currently unused
        token;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function liquidateBorrowAllowed(
        address tokenBorrowed,
        address tokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external override returns (uint) {
        // Shh - currently unused
        liquidator;
        if (!markets[tokenBorrowed].isListed || !markets[tokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        uint borrowBalance = Token(tokenBorrowed).borrowBalanceStored(borrower);
        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(Token(tokenBorrowed))) {
            require(borrowBalance >= repayAmount, "Can not repay more than the total borrow");
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }
            if (shortfall == 0) {
                return uint(Error.INSUFFICIENT_SHORTFALL);
            }
            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
            if (repayAmount > maxClose) {
                return uint(Error.TOO_MUCH_REPAY);
            }
        }
        return uint(Error.NO_ERROR);
    }
    function liquidateBorrowVerify(
        address tokenBorrowed,
        address tokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) external override {
        // Shh - currently unused
        tokenBorrowed;
        tokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function seizeAllowed(
        address tokenCollateral,
        address tokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");
        // Shh - currently unused
        seizeTokens;
        if (!markets[tokenCollateral].isListed || !markets[tokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }
        if (Token(tokenCollateral).comptroller() != Token(tokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }
        // Keep the flywheel moving
        updateCompSupplyIndex(tokenCollateral);
        distributeSupplierComp(tokenCollateral, borrower);
        distributeSupplierComp(tokenCollateral, liquidator);
        return uint(Error.NO_ERROR);
    }
    function seizeVerify(
        address tokenCollateral,
        address tokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external override {
        // Shh - currently unused
        tokenCollateral;
        tokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function transferAllowed(address token, address src, address dst, uint transferTokens) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");
        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(token, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }
        // Keep the flywheel moving
        updateCompSupplyIndex(token);
        distributeSupplierComp(token, src);
        distributeSupplierComp(token, dst);
        return uint(Error.NO_ERROR);
    }
    function transferVerify(address token, address src, address dst, uint transferTokens) external override {
        // Shh - currently unused
        token;
        src;
        dst;
        transferTokens;
        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    /*** Liquidity/Liquidation Calculations ***/
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint tokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint PriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp _Price;
        Exp tokensToDenom;
    }
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, Token(0), 0, 0);
        return (uint(err), liquidity, shortfall);
    }
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, Token(0), 0, 0);
    }
    function getHypotheticalAccountLiquidity(
        address account,
        address tokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, Token(tokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }
    function getHypotheticalAccountLiquidityInternal(
        address account,
        Token tokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;
        // For each asset the account is in
        Token[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            Token asset = assets[i];
            // Read the balances and exchange rate from the token
            (oErr, vars.tokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});
            // Get the normalized price of the asset
            vars.PriceMantissa = price.getUnderlyingPrice(asset);
            if (vars.PriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars._Price = Exp({mantissa: vars.PriceMantissa});
            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars._Price);
            // sumCollateral += tokensToDenom * tokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.tokenBalance, vars.sumCollateral);
            // sumBorrowPlusEffects += _Price * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars._Price, vars.borrowBalance, vars.sumBorrowPlusEffects);
            // Calculate effects of interacting with tokenModify
            if (asset == tokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                // borrow effect
                // sumBorrowPlusEffects += _Price * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars._Price, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }
    function liquidateCalculateSeizeTokens(address tokenBorrowed, address tokenCollateral, uint actualRepayAmount) external view  override returns (uint, uint) {
        /* Read  prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = price.getUnderlyingPrice(Token(tokenBorrowed));
        uint priceCollateralMantissa = price.getUnderlyingPrice(Token(tokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }
        uint exchangeRateMantissa = Token(tokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);
        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);
        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/
    function _setPrice(Price new_Price) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_OWNER_CHECK);
        }
        // Track the old Price for the comptroller
        Price old_Price = price;
        // Set comptroller's Price to new_Price
        price = new_Price;
        // Emit NewPricePrice(old_Price, new_Price)
        emit NewPrice(old_Price, new_Price);
        return uint(Error.NO_ERROR);
    }
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");
        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);
        return uint(Error.NO_ERROR);
    }
    function _setCollateralFactor(Token token, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }
        // Verify market is listed
        Market storage market = markets[address(token)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }
        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});
        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }
        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && price.getUnderlyingPrice(token) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }
        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;
        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(token, oldCollateralFactorMantissa, newCollateralFactorMantissa);
        return uint(Error.NO_ERROR);
    }
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }
        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;
        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);
        return uint(Error.NO_ERROR);
    }
    function _supportMarket(Token token) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }
        if (markets[address(token)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }
        //token.isToken(); // Sanity check to make sure its really a Token
        // Note that isComped is not in active use anymore
        markets[address(token)] = Market({isListed: true, isComped: false, collateralFactorMantissa: 0});
        _addMarketInternal(address(token));
        _initializeMarket(address(token));
        emit MarketListed(token);
        return uint(Error.NO_ERROR);
    }
    function _addMarketInternal(address token) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != Token(token), "market already added");
        }
        allMarkets.push(Token(token));
    }
    function _initializeMarket(address token) internal {
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        CompMarketState storage supplyState = compSupplyState[token];
        CompMarketState storage borrowState = compBorrowState[token];
        /*
         * Update market state indices
         */
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = compInitialIndex;
        }
        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = compInitialIndex;
        }
        /*
         * Update market state block numbers
         */
         supplyState.block = borrowState.block = blockNumber;
    }
    function _setMarketBorrowCaps(Token[] calldata tokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == admin || msg.sender == borrowCapGuardian, "only admin or borrow cap guardian can set borrow caps"); 
        uint numMarkets = tokens.length;
        uint numBorrowCaps = newBorrowCaps.length;
        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");
        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(tokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(tokens[i], newBorrowCaps[i]);
        }
    }
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "only admin can set borrow cap guardian");
        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;
        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;
        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }
        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;
        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;
        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
        return uint(Error.NO_ERROR);
    }
    function _setMintPaused(Token token, bool state) public returns (bool) {
        require(markets[address(token)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");
        mintGuardianPaused[address(token)] = state;
        emit ActionPaused(token, "Mint", state);
        return state;
    }
    function _setBorrowPaused(Token token, bool state) public returns (bool) {
        require(markets[address(token)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");
        borrowGuardianPaused[address(token)] = state;
        emit ActionPaused(token, "Borrow", state);
        return state;
    }
    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");
        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }
    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");
        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }
    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        require(unitroller._acceptImplementation() == 0, "change not authorized");
    }
    /// @notice Delete this function after proposal 65 is executed
    function fixBadAccruals(address[] calldata affectedUsers, uint[] calldata amounts) external {
        require(msg.sender == admin, "Only admin can call this function"); // Only the timelock can call this function
        require(!proposal65FixExecuted, "Already executed this one-off function"); // Require that this function is only called once
        require(affectedUsers.length == amounts.length, "Invalid input");
        // Loop variables
        address user;
        uint currentAccrual;
        uint amountToSubtract;
        uint newAccrual;
        // Iterate through all affected users
        for (uint i = 0; i < affectedUsers.length; ++i) {
            user = affectedUsers[i];
            currentAccrual = compAccrued[user];
            amountToSubtract = amounts[i];
            // The case where the user has claimed and received an incorrect amount of COMP.
            // The user has less currently accrued than the amount they incorrectly received.
            if (amountToSubtract > currentAccrual) {
                // Amount of COMP the user owes the protocol
                uint accountReceivable = amountToSubtract - currentAccrual; // Underflow safe since amountToSubtract > currentAccrual
                uint oldReceivable = compReceivable[user];
                uint newReceivable = add_(oldReceivable, accountReceivable);
                // Accounting: record the COMP debt for the user
                compReceivable[user] = newReceivable;
                emit CompReceivableUpdated(user, oldReceivable, newReceivable);
                amountToSubtract = currentAccrual;
            }
            if (amountToSubtract > 0) {
                // Subtract the bad accrual amount from what they have accrued.
                // Users will keep whatever they have correctly accrued.
                compAccrued[user] = newAccrual = sub_(currentAccrual, amountToSubtract);
                emit CompAccruedAdjusted(user, currentAccrual, newAccrual);
            }
        }
        proposal65FixExecuted = true; // Makes it so that this function cannot be called again
    }
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }
    /*** Comp Distribution ***/
    function setCompSpeedInternal(Token token, uint supplySpeed, uint borrowSpeed) internal {
        Market storage market = markets[address(token)];
        require(market.isListed, "comp market is not listed");
        if (compSupplySpeeds[address(token)] != supplySpeed) {
            // Supply speed updated so let's update supply state to ensure that
            //  1. COMP accrued properly for the old speed, and
            //  2. COMP accrued at the new speed starts after this block.
            updateCompSupplyIndex(address(token));
            // Update speed and emit event
            compSupplySpeeds[address(token)] = supplySpeed;
            emit CompSupplySpeedUpdated(token, supplySpeed);
        }
        if (compBorrowSpeeds[address(token)] != borrowSpeed) {
            // Borrow speed updated so let's update borrow state to ensure that
            //  1. COMP accrued properly for the old speed, and
            //  2. COMP accrued at the new speed starts after this block.
            Exp memory borrowIndex = Exp({mantissa: token.borrowIndex()});
            updateCompBorrowIndex(address(token), borrowIndex);

            // Update speed and emit event
            compBorrowSpeeds[address(token)] = borrowSpeed;
            emit CompBorrowSpeedUpdated(token, borrowSpeed);
        }
    }
    function updateCompSupplyIndex(address token) internal {
        CompMarketState storage supplyState = compSupplyState[token];
        uint supplySpeed = compSupplySpeeds[token];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint deltaBlocks = sub_(uint(blockNumber), uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = Token(token).totalSupply();
            uint compAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(compAccrued, supplyTokens) : Double({mantissa: 0});
            supplyState.index = safe224(add_(Double({mantissa: supplyState.index}), ratio).mantissa, "new index exceeds 224 bits");
            supplyState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            supplyState.block = blockNumber;
        }
    }
    function updateCompBorrowIndex(address token, Exp memory marketBorrowIndex) internal {
        CompMarketState storage borrowState = compBorrowState[token];
        uint borrowSpeed = compBorrowSpeeds[token];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint deltaBlocks = sub_(uint(blockNumber), uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(Token(token).totalBorrows(), marketBorrowIndex);
            uint compAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(compAccrued, borrowAmount) : Double({mantissa: 0});
            borrowState.index = safe224(add_(Double({mantissa: borrowState.index}), ratio).mantissa, "new index exceeds 224 bits");
            borrowState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            borrowState.block = blockNumber;
        }
    }
    function distributeSupplierComp(address token, address supplier) internal {
        // TODO: Don't distribute supplier COMP if the user is not in the supplier market.
        // This check should be as gas efficient as possible as distributeSupplierComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.
        CompMarketState storage supplyState = compSupplyState[token];
        uint supplyIndex = supplyState.index;
        uint supplierIndex = compSupplierIndex[token][supplier];
        // Update supplier's index to the current index since we are distributing accrued COMP
        compSupplierIndex[token][supplier] = supplyIndex;
        if (supplierIndex == 0 && supplyIndex >= compInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with COMP accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = compInitialIndex;
        }
        // Calculate change in the cumulative sum of the COMP per token accrued
        Double memory deltaIndex = Double({mantissa: sub_(supplyIndex, supplierIndex)});
        uint supplierTokens = Token(token).balanceOf(supplier);
        // Calculate COMP accrued: tokenAmount * accruedPerToken
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(compAccrued[supplier], supplierDelta);
        compAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierComp(Token(token), supplier, supplierDelta, supplyIndex);
    }
    function distributeBorrowerComp(address token, address borrower, Exp memory marketBorrowIndex) internal {
        // TODO: Don't distribute supplier COMP if the user is not in the borrower market.
        // This check should be as gas efficient as possible as distributeBorrowerComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.
        CompMarketState storage borrowState = compBorrowState[token];
        uint borrowIndex = borrowState.index;
        uint borrowerIndex = compBorrowerIndex[token][borrower];
        // Update borrowers's index to the current index since we are distributing accrued COMP
        compBorrowerIndex[token][borrower] = borrowIndex;
        if (borrowerIndex == 0 && borrowIndex >= compInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with COMP accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = compInitialIndex;
        }
        // Calculate change in the cumulative sum of the COMP per borrowed unit accrued
        Double memory deltaIndex = Double({mantissa: sub_(borrowIndex, borrowerIndex)});
        uint borrowerAmount = div_(Token(token).borrowBalanceStored(borrower), marketBorrowIndex);
        // Calculate COMP accrued: tokenAmount * accruedPerBorrowedUnit
        uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
        uint borrowerAccrued = add_(compAccrued[borrower], borrowerDelta);
        compAccrued[borrower] = borrowerAccrued;
        emit DistributedBorrowerComp(Token(token), borrower, borrowerDelta, borrowIndex);
    }
    function updateContributorRewards(address contributor) public {
        uint compSpeed = compContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && compSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, compSpeed);
            uint contributorAccrued = add_(compAccrued[contributor], newAccrued);
            compAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }
    function claimComp(address holder) public {
        return claimComp(holder, allMarkets);
    }
    function claimComp(address holder, Token[] memory tokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimComp(holders, tokens, true, true);
    }
    function claimComp(address[] memory holders, Token[] memory tokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < tokens.length; i++) {
            Token token = tokens[i];
            require(markets[address(token)].isListed, "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: token.borrowIndex()});
                updateCompBorrowIndex(address(token), borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerComp(address(token), holders[j], borrowIndex);
                }
            }
            if (suppliers == true) {
                updateCompSupplyIndex(address(token));
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierComp(address(token), holders[j]);
                }
            }
        }
        for (uint j = 0; j < holders.length; j++) {
            compAccrued[holders[j]] = grantCompInternal(holders[j], compAccrued[holders[j]]);
        }
    }
    function grantCompInternal(address user, uint amount) internal returns (uint) {
        Comp comp = Comp(getCompAddress());
        uint compRemaining = comp.balanceOf(address(this));
        if (amount > 0 && amount <= compRemaining) {
            comp.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /*** Comp Distribution Admin ***/
    function _grantComp(address recipient, uint amount) public {
        require(adminOrInitializing(), "only admin can grant comp");
        uint amountLeft = grantCompInternal(recipient, amount);
        require(amountLeft == 0, "insufficient comp for grant");
        emit CompGranted(recipient, amount);
    }
    function _setCompSpeeds(Token[] memory tokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) public {
        require(adminOrInitializing(), "only admin can set comp speed");
        uint numTokens = tokens.length;
        require(numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length, "Comptroller::_setCompSpeeds invalid input");
        for (uint i = 0; i < numTokens; ++i) {
            setCompSpeedInternal(tokens[i], supplySpeeds[i], borrowSpeeds[i]);
        }
    }
    function _setContributorCompSpeed(address contributor, uint compSpeed) public {
        require(adminOrInitializing(), "only admin can set comp speed");
        // note that COMP speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (compSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        compContributorSpeeds[contributor] = compSpeed;
        emit ContributorCompSpeedUpdated(contributor, compSpeed);
    }
    function getAllMarkets() public view returns (Token[] memory) {
        return allMarkets;
    }
    function isDeprecated(Token token) public view returns (bool) {
        return
            markets[address(token)].collateralFactorMantissa == 0 && 
            borrowGuardianPaused[address(token)] == true && 
            token.reserveFactorMantissa() == 1e18
        ;
    }
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
    function getCompAddress() public view returns (address) {
        return 0x46D8c4415950ca75062acB143302E763a37afC3b;
    }
}