/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// File: contracts/compound/interfaces/ICToken.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ICToken {
    // return Error, cTokenBalance, borrowBalance, exchangeRateMantissa
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

}

// File: contracts/compound/interfaces/IComptroller.sol

// MIT
pragma solidity 0.8.16;

// import {ICToken} from './ICToken.sol';
// import {IPriceOracle} from './IPriceOracle.sol';

interface IComptroller {

    /**
    * @notice Returns the assets an account has entered
    * @param account The address of the account to pull assets for
    * @return A dynamic list with the assets the account has entered
    */
    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address ctoken) external view returns(bool, uint256, bool);// isListed,collateralFactorMantissa,isComped

    function oracle() external view returns(address);

}

// File: contracts/compound/interfaces/IPriceOracle.sol

// MIT
pragma solidity 0.8.16;


interface IPriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(ICToken cToken) external view returns (uint);
}

// File: contracts/compound/CompoundStat.sol

// MIT
pragma solidity 0.8.16;




interface IComptroller2 {

    function markets(address ctoken) external view returns(bool, uint256);// isListed,collateralFactorMantissa,isComped

}

contract CompoundStat {
    
    uint constant ERROR = 1;
    uint constant NO_ERROR = 0;

    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;


    struct Exp {
        uint mantissa;
    }

    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint cTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        uint256 collateralFactorMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    struct StatAssetInfo {
        uint cTokenBalance;
        uint borrowBalance;
        uint currentPrice;
        Exp collateralFactor;
        Exp exchangeRate;
    }

    struct LiquidationPrice {
        address user;
        address statAsset;
        uint256 price;
        address liquidationAsset;
        uint256 liquidationAmountMax;
        uint256 liquidationAssetCurrentPrice;
    }

    function calcuUserLiquidationPrice(
        address[] memory users,
        address statAsset,
        address[] memory againstAsset,
        address comptroller,
        uint256 direct
    ) external view returns(LiquidationPrice[] memory) {
        LiquidationPrice[] memory arr = new LiquidationPrice[](users.length);
        for(uint i=0; i<users.length; i++){
            
            LiquidationPrice memory varlp;
            varlp.user = users[i];
            varlp.statAsset = statAsset;
            if (direct == 1){
                varlp.liquidationAsset = statAsset;
            } else if (direct == 2){
                varlp.liquidationAsset = againstAsset[0];
            }

            (varlp.price, 
            varlp.liquidationAmountMax, 
            varlp.liquidationAssetCurrentPrice) = calculateLiquidationPrice(comptroller,users[i], statAsset, againstAsset, direct);
            arr[i] = varlp;
        }

        return arr;
    }

    function calculateLiquidationPrice(address comptroller, address account, address statAsset,address[] memory againstAsset, uint256 direct) 
        internal view returns(uint256, uint256, uint256) {
        
        address[] memory assets = IComptroller(comptroller).getAssetsIn(account);
        AccountLiquidityLocalVars memory vars;
        uint oErr;
        if (direct == 1) {
            StatAssetInfo memory info;

            // For each asset the account is in
            for (uint i = 0; i < assets.length; i++) {
                ICToken asset = ICToken(assets[i]);

                // Read the balances and exchange rate from the cToken
                (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
                if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                    return (0, 0, 0);
                }

                // deposit
                if (vars.cTokenBalance > 0 && statAsset != address(asset)) {
                    return (0, 0, 0);
                }

                // borrow
                if (vars.borrowBalance > 0 && !contains(againstAsset, address(asset))) {
                    return (0, 0, 0);
                }

                (,vars.collateralFactorMantissa) = IComptroller2(comptroller).markets(address(asset));
                vars.collateralFactor = Exp({mantissa: vars.collateralFactorMantissa});
                vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

                // Get the normalized price of the asset
                vars.oraclePriceMantissa = IPriceOracle(IComptroller(comptroller).oracle()).getUnderlyingPrice(asset);
                if (vars.oraclePriceMantissa == 0) {
                    return (0, 0, 0);
                }
                vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

                if (statAsset == address(asset)) {
                    info.cTokenBalance = vars.cTokenBalance;
                    info.collateralFactor = vars.collateralFactor;
                    info.exchangeRate = vars.exchangeRate;
                    info.currentPrice = vars.oraclePriceMantissa;
                }

                // Pre-compute a conversion factor from tokens -> ether (normalized price value)
                // vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

                // sumCollateral += tokensToDenom * cTokenBalance
                // vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

                // sumBorrowPlusEffects += oraclePrice * borrowBalance
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            }
            //return(liquidationPrice, collateralAmount, currentPrice)
            return (
                vars.sumBorrowPlusEffects * expScale / ((info.collateralFactor.mantissa * info.exchangeRate.mantissa / expScale) * info.cTokenBalance / expScale),
                info.exchangeRate.mantissa * info.cTokenBalance / expScale,
                info.currentPrice
            );
        } else if (direct == 2) {
            if (againstAsset.length !=1) {
                return (0,0,0);
            }

            StatAssetInfo memory info;

            // For each asset the account is in
            for (uint i = 0; i < assets.length; i++) {
                ICToken asset = ICToken(assets[i]);

                // Read the balances and exchange rate from the cToken
                (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
                if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                    return (0, 0, 0);
                }

                // deposit
                if (vars.cTokenBalance > 0 && !contains(againstAsset, address(asset))) {
                    return (0, 0, 0);
                }

                // borrow
                if (vars.borrowBalance > 0 && statAsset != address(asset)) {
                    return (0, 0, 0);
                }

                (,vars.collateralFactorMantissa) = IComptroller2(comptroller).markets(address(asset));
                vars.collateralFactor = Exp({mantissa: vars.collateralFactorMantissa});
                vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

                // Get the normalized price of the asset
                vars.oraclePriceMantissa = IPriceOracle(IComptroller(comptroller).oracle()).getUnderlyingPrice(asset);
                if (vars.oraclePriceMantissa == 0) {
                    return (0, 0, 0);
                }
                vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

                if (statAsset == address(asset)) {
                    info.borrowBalance = vars.borrowBalance;
                }
                if (contains(againstAsset, address(asset))) {
                    info.currentPrice = vars.oraclePriceMantissa;
                    info.cTokenBalance = vars.cTokenBalance;
                    info.exchangeRate = vars.exchangeRate;
                }

                // Pre-compute a conversion factor from tokens -> ether (normalized price value)
                vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

                // sumCollateral += tokensToDenom * cTokenBalance
                vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

                // sumBorrowPlusEffects += oraclePrice * borrowBalance
                // vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            }
            return(
                vars.sumCollateral * expScale / info.borrowBalance,
                info.exchangeRate.mantissa * info.cTokenBalance / expScale,
                info.currentPrice
            );
        }
        // vars.sumCollateral - vars.sumBorrowPlusEffects = 0 liquidation
        return (0,0,0);
    }

    function contains(address[] memory stablecoins, address asset) internal pure returns(bool) {
      for(uint i=0; i<stablecoins.length; i++) {
          if(asset==stablecoins[i]){
              return true;
          }
      }
      return false;
  }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral cToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        ICToken cTokenModify,
        uint redeemTokens,
        uint borrowAmount,
        address comptroller) public view returns (uint, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        address[] memory assets = IComptroller(comptroller).getAssetsIn(account);
        for (uint i = 0; i < assets.length; i++) {
            ICToken asset = ICToken(assets[i]);

            // Read the balances and exchange rate from the cToken
            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (ERROR, 0, 0);
            }
            (,vars.collateralFactorMantissa) = IComptroller2(comptroller).markets(address(asset));
            vars.collateralFactor = Exp({mantissa: vars.collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = IPriceOracle(IComptroller(comptroller).oracle()).getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * cTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with cTokenModify
            if (asset == cTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

     /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    // function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
    //     return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    // }

    // function mul_(Double memory a, uint b) pure internal returns (Double memory) {
    //     return Double({mantissa: mul_(a.mantissa, b)});
    // }

    // function mul_(uint a, Double memory b) pure internal returns (uint) {
    //     return mul_(a, b.mantissa) / doubleScale;
    // }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

}