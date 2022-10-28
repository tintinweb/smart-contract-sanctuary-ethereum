// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IShopLoan} from "../../interfaces/IShopLoan.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {IBNFTRegistry} from "../../interfaces/IBNFTRegistry.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeMath} from "../math/SafeMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {IAddressesProvider} from "../../interfaces/IAddressesProvider.sol";

/**
 * @title GenericLogic library
 * @author Bend
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using PercentageMath for uint256;
    using SafeMath for uint256;
    using ShopConfiguration for DataTypes.ShopConfiguration;
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

    struct CalculateLoanDataVars {
        uint256 reserveUnitPrice;
        uint256 reserveUnit;
        uint256 reserveDecimals;
        uint256 healthFactor;
        uint256 totalCollateralInETH;
        uint256 totalCollateralInReserve;
        uint256 totalDebtInETH;
        uint256 totalDebtInReserve;
        uint256 nftLtv;
        uint256 nftLiquidationThreshold;
        address nftAsset;
        uint256 nftTokenId;
        uint256 nftUnitPrice;
    }

    /**
     * @dev Calculates the nft loan data.
     * this includes the total collateral/borrow balances in Reserve,
     * the Loan To Value, the Liquidation Ratio, and the Health factor.
     * @param reserveData Data of the reserve
     * @param reserveOracle The price oracle address of reserve
     * @param nftOracle The price oracle address of nft
     * @return The total collateral and total debt of the loan in Reserve, the ltv, liquidation threshold and the HF
     **/
    function calculateLoanData(
        IAddressesProvider provider,
        DataTypes.ShopConfiguration storage config,
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address loanAddress,
        uint256 loanId,
        address reserveOracle,
        address nftOracle
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        CalculateLoanDataVars memory vars;

        vars.nftLtv = config.getLtv();
        vars.nftLiquidationThreshold = provider.liquidationThreshold();

        // calculate total borrow balance for the loan
        if (loanId != 0) {
            (
                vars.totalDebtInETH,
                vars.totalDebtInReserve
            ) = calculateNftDebtData(
                reserveAddress,
                reserveData,
                loanAddress,
                loanId,
                reserveOracle
            );
        }

        // calculate total collateral balance for the nft
        (
            vars.totalCollateralInETH,
            vars.totalCollateralInReserve
        ) = calculateNftCollateralData(
            reserveAddress,
            reserveData,
            nftAddress,
            reserveOracle,
            nftOracle
        );

        // calculate health by borrow and collateral
        vars.healthFactor = calculateHealthFactorFromBalances(
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.nftLiquidationThreshold
        );

        return (
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.healthFactor
        );
    }

    function calculateNftDebtData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address loanAddress,
        uint256 loanId,
        address reserveOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        // all asset price has converted to ETH based, unit is in WEI (18 decimals)

        vars.reserveDecimals = reserveData.decimals;
        vars.reserveUnit = 10**vars.reserveDecimals;

        vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAddress);

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            loanAddress
        ).totalDebtInReserve(loanId, 0);
        vars.totalDebtInReserve = borrowAmount + interest + fee;
        vars.totalDebtInETH =
            (vars.totalDebtInReserve * vars.reserveUnitPrice) /
            vars.reserveUnit;

        return (vars.totalDebtInETH, vars.totalDebtInReserve);
    }

    function calculateNftCollateralData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address reserveOracle,
        address nftOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        vars.nftUnitPrice = INFTOracleGetter(nftOracle).getAssetPrice(
            nftAddress
        );
        vars.totalCollateralInETH = vars.nftUnitPrice;

        if (reserveAddress != address(0)) {
            vars.reserveDecimals = reserveData.decimals;
            vars.reserveUnit = 10**vars.reserveDecimals;

            vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
                .getAssetPrice(reserveAddress);

            vars.totalCollateralInReserve =
                (vars.totalCollateralInETH * vars.reserveUnit) /
                vars.reserveUnitPrice;
        }

        return (vars.totalCollateralInETH, vars.totalCollateralInReserve);
    }

    /**
     * @dev Calculates the health factor from the corresponding balances
     * @param totalCollateral The total collateral
     * @param totalDebt The total debt
     * @param liquidationThreshold The avg liquidation threshold
     * @return The health factor calculated from the balances provided
     **/
    function calculateHealthFactorFromBalances(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        if (totalDebt == 0) return type(uint256).max;

        return (totalCollateral.percentMul(liquidationThreshold)) / totalDebt;
    }

    struct CalculateInterestInfoVars {
        uint256 lastRepaidAt;
        uint256 borrowAmount;
        uint256 interestRate;
        uint256 repayAmount;
        uint256 platformFeeRate;
        uint256 interestDuration;
    }

    function calculateInterestInfo(CalculateInterestInfoVars memory vars)
        internal
        view
        returns (
            uint256 totalDebt,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 platformFee
        )
    {
        if (vars.interestDuration == 0) {
            vars.interestDuration = 86400; //1day
        }
        uint256 sofarLoanDay = (
            (block.timestamp - vars.lastRepaidAt).div(vars.interestDuration)
        ).add(1);
        interest = vars
            .borrowAmount
            .mul(vars.interestRate)
            .mul(sofarLoanDay)
            .div(uint256(10000))
            .div(uint256(365 * 86400) / vars.interestDuration);
        platformFee = vars.borrowAmount.mul(vars.platformFeeRate).div(10000);
        if (vars.repayAmount > 0) {
            require(
                vars.repayAmount > interest,
                Errors.LP_REPAY_AMOUNT_NOT_ENOUGH
            );
            repayPrincipal = vars.repayAmount - interest;
            if (repayPrincipal > vars.borrowAmount.add(platformFee)) {
                repayPrincipal = vars.borrowAmount;
            } else {
                repayPrincipal = repayPrincipal.mul(10000).div(
                    10000 + vars.platformFeeRate
                );
                platformFee = repayPrincipal.mul(vars.platformFeeRate).div(
                    10000
                );
            }
        }
        totalDebt = vars.borrowAmount.add(interest).add(platformFee);
        return (totalDebt, repayPrincipal, interest, platformFee);
    }

    struct CalcLiquidatePriceLocalVars {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 nftPriceInETH;
        uint256 nftPriceInReserve;
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 totalDebt;
        uint256 repayPrincipal;
        uint256 interest;
        uint256 platformFee;
    }

    function calculateLoanLiquidatePrice(
        IAddressesProvider provider,
        uint256 loanId,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        CalcLiquidatePriceLocalVars memory vars;

        /*
         * 0                   CR                  LH                  100
         * |___________________|___________________|___________________|
         *  <       Borrowing with Interest        <
         * CR: Callteral Ratio;
         * LH: Liquidate Threshold;
         * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
         * Liquidate Price: (100% - BonusRatio) * NFT Price;
         */

        vars.reserveDecimals = reserveData.decimals;

        // TODO base theo pawnshop
        DataTypes.LoanData memory loan = IShopLoan(provider.loanManager())
            .getLoan(loanId);
        (
            vars.totalDebt,
            ,
            vars.interest,
            vars.platformFee
        ) = calculateInterestInfo(
            CalculateInterestInfoVars({
                lastRepaidAt: loan.lastRepaidAt,
                borrowAmount: loan.borrowAmount,
                interestRate: loan.interestRate,
                repayAmount: 0,
                platformFeeRate: provider.platformFeePercentage(),
                interestDuration: provider.interestDuration()
            })
        );

        //does not calculate interest after auction
        if (
            loan.state == DataTypes.LoanState.Auction &&
            loan.bidBorrowAmount > 0
        ) {
            vars.totalDebt = loan.bidBorrowAmount;
        }

        vars.liquidationThreshold = provider.liquidationThreshold();
        vars.liquidationBonus = provider.liquidationBonus();

        require(
            vars.liquidationThreshold > 0,
            Errors.LP_INVALID_LIQUIDATION_THRESHOLD
        );

        vars.nftPriceInETH = INFTOracleGetter(provider.nftOracle())
            .getAssetPrice(nftAsset);
        vars.reservePriceInETH = IReserveOracleGetter(provider.reserveOracle())
            .getAssetPrice(reserveAsset);

        vars.nftPriceInReserve =
            ((10**vars.reserveDecimals) * vars.nftPriceInETH) /
            vars.reservePriceInETH;

        vars.thresholdPrice = vars.nftPriceInReserve.percentMul(
            vars.liquidationThreshold
        );

        vars.liquidatePrice = vars.nftPriceInReserve.percentMul(
            PercentageMath.PERCENTAGE_FACTOR - vars.liquidationBonus
        );

        return (
            vars.totalDebt,
            vars.thresholdPrice,
            vars.liquidatePrice,
            vars.platformFee
        );
    }

    struct CalcLoanBidFineLocalVars {
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 baseBidFineInReserve;
        uint256 minBidFinePct;
        uint256 minBidFineInReserve;
        uint256 bidFineInReserve;
        uint256 debtAmount;
    }

    function calculateLoanBidFine(
        IAddressesProvider provider,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset,
        DataTypes.LoanData memory loanData,
        address poolLoan,
        address reserveOracle
    ) external view returns (uint256, uint256) {
        nftAsset;

        if (loanData.bidPrice == 0) {
            return (0, 0);
        }

        CalcLoanBidFineLocalVars memory vars;

        vars.reserveDecimals = reserveData.decimals;
        vars.reservePriceInETH = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAsset);
        vars.baseBidFineInReserve =
            (1 ether * 10**vars.reserveDecimals) /
            vars.reservePriceInETH;

        vars.minBidFinePct = provider.minBidFine();
        vars.minBidFineInReserve = vars.baseBidFineInReserve.percentMul(
            vars.minBidFinePct
        );

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            poolLoan
        ).totalDebtInReserve(loanData.loanId, 0);

        vars.debtAmount = borrowAmount + interest + fee;

        vars.bidFineInReserve = vars.debtAmount.percentMul(
            provider.redeemFine()
        );
        if (vars.bidFineInReserve < vars.minBidFineInReserve) {
            vars.bidFineInReserve = vars.minBidFineInReserve;
        }

        return (vars.minBidFineInReserve, vars.bidFineInReserve);
    }

    function calculateLoanAuctionEndTimestamp(
        IAddressesProvider provider,
        uint256 bidStartTimestamp
    )
        external
        view
        returns (uint256 auctionEndTimestamp, uint256 redeemEndTimestamp)
    {
        auctionEndTimestamp = bidStartTimestamp + provider.auctionDuration();

        redeemEndTimestamp = bidStartTimestamp + provider.redeemDuration();
    }

    /**
     * @dev Calculates the equivalent amount that an user can borrow, depending on the available collateral and the
     * average Loan To Value
     * @param totalCollateral The total collateral
     * @param totalDebt The total borrow balance
     * @param ltv The average loan to value
     * @return the amount available to borrow for the user
     **/

    function calculateAvailableBorrows(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 ltv
    ) external pure returns (uint256) {
        uint256 availableBorrows = totalCollateral.percentMul(ltv);

        if (availableBorrows < totalDebt) {
            return 0;
        }

        availableBorrows = availableBorrows - totalDebt;
        return availableBorrows;
    }

    function getBNftAddress(IAddressesProvider provider, address nftAsset)
        external
        view
        returns (address bNftAddress)
    {
        IBNFTRegistry bnftRegistry = IBNFTRegistry(provider.bnftRegistry());
        bNftAddress = bnftRegistry.getBNFTAddresses(nftAsset);
        return bNftAddress;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library DataTypes {
    struct ShopData {
        uint256 id;
        address creator;
    }

    struct ReservesInfo {
        uint8 id;
        address contractAddress;
        bool active;
        string symbol;
        uint256 decimals;
    }
    struct NftsInfo {
        uint8 id;
        bool active;
        address contractAddress;
        string collection;
        uint256 maxSupply;
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }
    struct LoanData {
        uint256 shopId;
        //the id of the nft loan
        uint256 loanId;
        //the current state of the loan
        LoanState state;
        //address of borrower
        address borrower;
        //address of nft asset token
        address nftAsset;
        //the id of nft token
        uint256 nftTokenId;
        //address of reserve asset token
        address reserveAsset;
        //borrow amount
        uint256 borrowAmount;
        //start time of first bid time
        uint256 bidStartTimestamp;
        //bidder address of higest bid
        address bidderAddress;
        //price of higest bid
        uint256 bidPrice;
        //borrow amount of loan
        uint256 bidBorrowAmount;
        //bidder address of first bid
        address firstBidderAddress;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 lastRepaidAt;
        uint256 expiredAt;
        uint256 interestRate;
    }

    struct GlobalConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ShopConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ExecuteLendPoolStates {
        uint256 pauseStartTime;
        uint256 pauseDurationTime;
    }

    struct ExecuteBorrowParams {
        address initiator;
        address asset;
        uint256 amount;
        address nftAsset;
        uint256 nftTokenId;
        address onBehalfOf;
    }
    struct ExecuteBatchBorrowParams {
        address initiator;
        address[] assets;
        uint256[] amounts;
        address[] nftAssets;
        uint256[] nftTokenIds;
        address onBehalfOf;
    }
    struct ExecuteRepayParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        address shopCreator;
    }

    struct ExecuteBatchRepayParams {
        address initiator;
        uint256[] loanIds;
        uint256[] amounts;
        address shopCreator;
    }
    struct ExecuteAuctionParams {
        address initiator;
        uint256 loanId;
        uint256 bidPrice;
        address onBehalfOf;
    }

    struct ExecuteRedeemParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        uint256 bidFine;
        address shopCreator;
    }

    struct ExecuteLiquidateParams {
        address initiator;
        uint256 loanId;
        address shopCreator;
    }

    struct ShopConfigParams {
        address reserveAddress;
        address nftAddress;
        uint256 interestRate;
        uint256 ltvRate;
        bool active;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Bend
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 constant ONE_PERCENT = 1e2; //100, 1%
    uint256 constant TEN_PERCENT = 1e3; //1000, 10%
    uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
    uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @author Bend
 * @notice Defines the error messages emitted by the different contracts of the Bend protocol
 */
library Errors {
    enum ReturnCode {
        SUCCESS,
        FAILED
    }

    string public constant SUCCESS = "0";

    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
    string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
    string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
    string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
    string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";

    //math library erros
    string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
    string public constant MATH_ADDITION_OVERFLOW = "201";
    string public constant MATH_DIVISION_BY_ZERO = "202";

    //validation & check errors
    string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
    string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "307"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_ACTIVE_NFT = "310";
    string public constant VL_NFT_FROZEN = "311";
    string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
    string public constant VL_INVALID_HEALTH_FACTOR = "313";
    string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
    string public constant VL_INVALID_TARGET_ADDRESS = "315";
    string public constant VL_INVALID_RESERVE_ADDRESS = "316";
    string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
    string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
    string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD =
        "319";

    //lend pool errors
    string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
    string public constant LP_NOT_CONTRACT = "403";
    string
        public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD_OR_EXPIRED =
        "404";
    string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
    string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
    string public constant LP_INVALIED_USER_NFT_AMOUNT = "407";
    string public constant LP_INCONSISTENT_PARAMS = "408";
    string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
    string public constant LP_CALLER_MUST_BE_AN_BTOKEN = "410";
    string public constant LP_INVALIED_NFT_AMOUNT = "411";
    string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
    string public constant LP_DELEGATE_CALL_FAILED = "413";
    string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
    string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
    string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
    string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
    string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
    string public constant LP_CALLER_NOT_SHOP_CREATOR = "419";
    string public constant LP_INVALID_LIQUIDATION_THRESHOLD = "420";
    string public constant LP_REPAY_AMOUNT_NOT_ENOUGH = "421";
    string public constant LP_NFT_ALREADY_INITIALIZED = "422"; // 'Nft has already been initialized'

    //lend pool loan errors
    string public constant LPL_INVALID_LOAN_STATE = "480";
    string public constant LPL_INVALID_LOAN_AMOUNT = "481";
    string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
    string public constant LPL_AMOUNT_OVERFLOW = "483";
    string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
    string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
    string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
    string public constant LPL_BID_USER_NOT_SAME = "487";
    string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
    string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
    string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
    string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
    string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
    string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
    string public constant LPL_INVALID_BID_FINE = "494";

    //common token errors
    string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
    string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
    string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
    string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

    //reserve logic errors
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

    //configure errors
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
    string public constant LPC_INVALIED_BNFT_ADDRESS = "703";
    string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
    string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";

    //reserve config errors
    string public constant RC_INVALID_LTV = "730";
    string public constant RC_INVALID_LIQ_THRESHOLD = "731";
    string public constant RC_INVALID_LIQ_BONUS = "732";
    string public constant RC_INVALID_DECIMALS = "733";
    string public constant RC_INVALID_RESERVE_FACTOR = "734";
    string public constant RC_INVALID_REDEEM_DURATION = "735";
    string public constant RC_INVALID_AUCTION_DURATION = "736";
    string public constant RC_INVALID_REDEEM_FINE = "737";
    string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
    string public constant RC_INVALID_MIN_BID_FINE = "739";
    string public constant RC_INVALID_MAX_BID_FINE = "740";
    string public constant RC_NOT_ACTIVE = "741";
    string public constant RC_INVALID_INTEREST_RATE = "742";

    //address provider erros
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

library ShopConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant INTEREST_RATE_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant INTEREST_RATE_POSITION = 128;

    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_INTEREST_RATE = 65535;

    /**
     * @dev Sets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @param ltv the new ltv
     **/
    function setLtv(DataTypes.ShopConfiguration memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @dev Gets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @dev Sets the active state of the NFT
     * @param self The NFT configuration
     * @param active The active state
     **/
    function setActive(DataTypes.ShopConfiguration memory self, bool active)
        internal
        pure
    {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the NFT
     * @param self The NFT configuration
     * @return The active state
     **/
    function getActive(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the min & max threshold of the NFT
     * @param self The NFT configuration
     * @param interestRate The interestRate
     **/
    function setInterestRate(
        DataTypes.ShopConfiguration memory self,
        uint256 interestRate
    ) internal pure {
        require(
            interestRate <= MAX_VALID_INTEREST_RATE,
            Errors.RC_INVALID_INTEREST_RATE
        );

        self.data =
            (self.data & INTEREST_RATE_MASK) |
            (interestRate << INTEREST_RATE_POSITION);
    }

    /**
     * @dev Gets interate of the NFT
     * @param self The NFT configuration
     * @return The interest
     **/
    function getInterestRate(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return ((self.data & ~INTEREST_RATE_MASK) >> INTEREST_RATE_POSITION);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IShopLoan {
    /**
     * @dev Emitted on initialization to share location of dependent notes
     * @param pool The address of the associated lend pool
     */
    event Initialized(address indexed pool);

    /**
     * @dev Emitted when a loan is created
     * @param user The address initiating the action
     */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is updated
     * @param user The address initiating the action
     */
    event LoanPartialRepay(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 repayAmount,
        uint256 currentInterest
    );

    /**
     * @dev Emitted when a loan is repaid by the borrower
     * @param user The address initiating the action
     */
    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is auction by the liquidator
     * @param user The address initiating the action
     */
    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice
    );

    /**
     * @dev Emitted when a loan is redeemed
     * @param user The address initiating the action
     */
    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amountTaken
    );

    /**
     * @dev Emitted when a loan is liquidate by the liquidator
     * @param user The address initiating the action
     */
    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    function initNft(address nftAsset) external;

    /**
     * @dev Create store a loan object with some params
     * @param initiator The address of the user initiating the borrow
     */
    function createLoan(
        uint256 shopId,
        address initiator,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount,
        uint256 interestRate
    ) external returns (uint256);

    /**
     * @dev Update the given loan with some params
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The loan must be in state Active
     * @param initiator The address of the user initiating the borrow
     */
    function partialRepayLoan(
        address initiator,
        uint256 loanId,
        uint256 repayAmount
    ) external;

    /**
     * @dev Repay the given loan
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the repay
     * @param loanId The loan getting burned
     */
    function repayLoan(
        address initiator,
        uint256 loanId,
        uint256 amount
    ) external;

    /**
     * @dev Auction the given loan
     *
     * Requirements:
     *  - The price must be greater than current highest price
     *  - The loan must be in state Active or Auction
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting auctioned
     * @param bidPrice The bid price of this auction
     */
    function auctionLoan(
        address initiator,
        uint256 loanId,
        address onBehalfOf,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    // /**
    //  * @dev Redeem the given loan with some params
    //  *
    //  * Requirements:
    //  *  - The caller must be a holder of the loan
    //  *  - The loan must be in state Auction
    //  * @param initiator The address of the user initiating the borrow
    //  */
    function redeemLoan(
        address initiator,
        uint256 loanId,
        uint256 amountTaken
    )
        external
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    /**
     * @dev Liquidate the given loan
     *
     * Requirements:
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting burned
     */
    function liquidateLoan(
        address initiator,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function borrowerOf(uint256 loanId) external view returns (address);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId)
        external
        view
        returns (uint256);

    function getLoan(uint256 loanId)
        external
        view
        returns (DataTypes.LoanData memory loanData);

    function totalDebtInReserve(uint256 loanId, uint256 repayAmount)
        external
        view
        returns (
            address asset,
            uint256 borrowAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    function getLoanHighestBid(uint256 loanId)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title IReserveOracleGetter interface
@notice Interface for getting Reserve price oracle.*/
interface IReserveOracleGetter {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(address _priceFeedKey, uint256 _interval)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBNFTRegistry {
    event Initialized(string namePrefix, string symbolPrefix);
    event BNFTCreated(
        address indexed nftAsset,
        address bNftProxy,
        uint256 totals
    );
    event CustomeSymbolsAdded(address[] nftAssets, string[] symbols);
    event ClaimAdminUpdated(address oldAdmin, address newAdmin);

    function getBNFTAddresses(address nftAsset)
        external
        view
        returns (address bNftProxy);

    function getBNFTAddressesByIndex(uint16 index)
        external
        view
        returns (address bNftProxy);

    function getBNFTAssetList() external view returns (address[] memory);

    function allBNFTAssetLength() external view returns (uint256);

    function initialize(
        address genericImpl,
        string memory namePrefix_,
        string memory symbolPrefix_
    ) external;

    /**
     * @dev Create bNFT proxy and implement, then initialize it
     * @param nftAsset The address of the underlying asset of the BNFT
     **/
    function createBNFT(address nftAsset) external returns (address bNftProxy);

    /**
     * @dev Adding custom symbol for some special NFTs like CryptoPunks
     * @param nftAssets_ The addresses of the NFTs
     * @param symbols_ The custom symbols of the NFTs
     **/
    function addCustomeSymbols(
        address[] memory nftAssets_,
        string[] memory symbols_
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface IAddressesProvider {
    function owner() external view returns (address);

    /// @notice nftOracle
    function nftOracle() external view returns (address);

    /// @notice reserveOracle
    function reserveOracle() external view returns (address);

    function userClaimRegistry() external view returns (address);

    function bnftRegistry() external view returns (address);

    function shopFactory() external view returns (address);

    function loanManager() external view returns (address);

    //tien phat toi thieu theo % reserve price (ex : vay eth, setup 2% => phat 1*2/100 = 0.02 eth, 1 la ty le giua dong vay voi ETH) khi redeem nft bi auction
    function minBidFine() external view returns (uint256);

    //tien phat toi thieu theo % khoan vay khi redeem nft bi auction ex: vay 10 ETH, setup 5% => phat 10*5/100=0.5 ETH
    function redeemFine() external view returns (uint256);

    //thoi gian co the redeem nft sau khi bi auction tinh = hour
    function redeemDuration() external view returns (uint256);

    function auctionDuration() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    //% giam gia khi thanh ly tai san
    function liquidationBonus() external view returns (uint256);

    function redeemThreshold() external view returns (uint256);

    function maxLoanDuration() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //platform fee tinh theo pricipal
    function platformFeePercentage() external view returns (uint256);

    function interestDuration() external view returns (uint256);
}