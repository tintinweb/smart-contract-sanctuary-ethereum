// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';
import '../libraries/Math.sol';
import '../libraries/WadRayMath.sol';
import '../libraries/TimeConverter.sol';

library AssetBond {
  using WadRayMath for uint256;
  using AssetBond for DataStruct.AssetBondData;

  uint256 constant NONCE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00;
  uint256 constant COUNTRY_CODE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC003FF;
  uint256 constant COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000003FFFFF;
  uint256 constant COLLATERAL_LATITUDE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000FFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LATITUDE_SIGNS =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LONGITUDE =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0000001FFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_LONGITUDE_SIGNS =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_DETAILS =
    0xFFFFFFFFFFFFFFFFFFFFFC0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant COLLATERAL_CATEGORY =
    0xFFFFFFFFFFFFFFFFFFF003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 constant PRODUCT_NUMBER =
    0xFFFFFFFFFFFFFFFFC00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  uint256 constant NONCE_START = 0;
  uint256 constant COUNTRY_CODE_START = 10;
  uint256 constant COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER_START = 22;
  uint256 constant COLLATERAL_LATITUDE_START = 72;
  uint256 constant COLLATERAL_LATITUDE_SIGNS_START = 100;
  uint256 constant COLLATERAL_LONGITUDE_START = 101;
  uint256 constant COLLATERAL_LONGITUDE_SIGNS_START = 129;
  uint256 constant COLLATERAL_DETAILS_START = 130;
  uint256 constant COLLATERAL_CATEGORY_START = 170;
  uint256 constant PRODUCT_NUMBER_START = 180;

  function parseAssetBondId(uint256 tokenId)
    public
    pure
    returns (DataStruct.AssetBondIdData memory)
  {
    DataStruct.AssetBondIdData memory vars;
    vars.nonce = tokenId & ~NONCE;
    vars.countryCode = (tokenId & ~COUNTRY_CODE) >> COUNTRY_CODE_START;
    vars.collateralServiceProviderIdentificationNumber =
      (tokenId & ~COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER) >>
      COLLATERAL_SERVICE_PROVIDER_IDENTIFICATION_NUMBER_START;
    vars.collateralLatitude = (tokenId & ~COLLATERAL_LATITUDE) >> COLLATERAL_LATITUDE_START;
    vars.collateralLatitudeSign =
      (tokenId & ~COLLATERAL_LATITUDE_SIGNS) >>
      COLLATERAL_LATITUDE_SIGNS_START;
    vars.collateralLongitude = (tokenId & ~COLLATERAL_LONGITUDE) >> COLLATERAL_LONGITUDE_START;
    vars.collateralLongitudeSign =
      (tokenId & ~COLLATERAL_LONGITUDE_SIGNS) >>
      COLLATERAL_LONGITUDE_SIGNS_START;
    vars.collateralDetail = (tokenId & ~COLLATERAL_DETAILS) >> COLLATERAL_DETAILS_START;
    vars.collateralCategory = (tokenId & ~COLLATERAL_CATEGORY) >> COLLATERAL_CATEGORY_START;
    vars.productNumber = (tokenId & ~PRODUCT_NUMBER) >> PRODUCT_NUMBER_START;

    return vars;
  }

  function getAssetBondDebtData(DataStruct.AssetBondData memory assetBondData)
    public
    view
    returns (uint256, uint256)
  {
    if (assetBondData.state != DataStruct.AssetBondState.COLLATERALIZED) {
      return (0, 0);
    }

    uint256 accruedDebtOnMoneyPool = Math
    .calculateCompoundedInterest(
      assetBondData.interestRate,
      assetBondData.collateralizeTimestamp,
      block.timestamp
    ).rayMul(assetBondData.principal);

    uint256 feeOnCollateralServiceProvider = calculateFeeOnRepayment(
      assetBondData,
      block.timestamp
    );

    return (accruedDebtOnMoneyPool, feeOnCollateralServiceProvider);
  }

  struct CalculateFeeOnRepaymentLocalVars {
    TimeConverter.DateTime paymentDateTimeStruct;
    uint256 paymentDate;
    uint256 firstTermRate;
    uint256 secondTermRate;
    uint256 secondTermOverdueRate;
    uint256 thirdTermRate;
    uint256 totalRate;
  }

  function calculateFeeOnRepayment(
    DataStruct.AssetBondData memory assetBondData,
    uint256 paymentTimestamp
  ) internal pure returns (uint256) {
    CalculateFeeOnRepaymentLocalVars memory vars;

    vars.firstTermRate = Math.calculateCompoundedInterest(
      assetBondData.couponRate,
      assetBondData.loanStartTimestamp,
      assetBondData.collateralizeTimestamp
    );

    vars.paymentDateTimeStruct = TimeConverter.parseTimestamp(paymentTimestamp);
    vars.paymentDate = TimeConverter.toTimestamp(
      vars.paymentDateTimeStruct.year,
      vars.paymentDateTimeStruct.month,
      vars.paymentDateTimeStruct.day + 1
    );

    if (paymentTimestamp <= assetBondData.liquidationTimestamp) {
      vars.secondTermRate =
        Math.calculateCompoundedInterest(
          assetBondData.couponRate - assetBondData.interestRate,
          assetBondData.collateralizeTimestamp,
          paymentTimestamp
        ) -
        WadRayMath.ray();
      vars.thirdTermRate =
        Math.calculateCompoundedInterest(
          assetBondData.couponRate,
          paymentTimestamp,
          vars.paymentDate
        ) -
        WadRayMath.ray();

      vars.totalRate = vars.firstTermRate + vars.secondTermRate + vars.thirdTermRate;

      return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
    }

    vars.secondTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate - assetBondData.interestRate,
        assetBondData.collateralizeTimestamp,
        assetBondData.maturityTimestamp
      ) -
      WadRayMath.ray();
    vars.secondTermOverdueRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate - assetBondData.interestRate,
        assetBondData.maturityTimestamp,
        paymentTimestamp
      ) -
      WadRayMath.ray();
    vars.thirdTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate,
        paymentTimestamp,
        vars.paymentDate
      ) -
      WadRayMath.ray();

    vars.totalRate =
      vars.firstTermRate +
      vars.secondTermRate +
      vars.secondTermOverdueRate +
      vars.thirdTermRate;

    return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
  }

  function getAssetBondLiquidationData(DataStruct.AssetBondData memory assetBondData)
    internal
    view
    returns (uint256, uint256)
  {
    uint256 accruedDebtOnMoneyPool = Math
    .calculateCompoundedInterest(
      assetBondData.interestRate,
      assetBondData.collateralizeTimestamp,
      block.timestamp
    ).rayMul(assetBondData.principal);

    uint256 feeOnCollateralServiceProvider = calculateDebtAmountToLiquidation(
      assetBondData,
      block.timestamp
    );

    return (accruedDebtOnMoneyPool, feeOnCollateralServiceProvider);
  }

  struct CalculateDebtAmountToLiquidationLocalVars {
    TimeConverter.DateTime paymentDateTimeStruct;
    uint256 paymentDate;
    uint256 firstTermRate;
    uint256 secondTermRate;
    uint256 totalRate;
  }

  function calculateDebtAmountToLiquidation(
    DataStruct.AssetBondData memory assetBondData,
    uint256 paymentTimestamp
  ) internal pure returns (uint256) {
    CalculateDebtAmountToLiquidationLocalVars memory vars;
    vars.firstTermRate = Math.calculateCompoundedInterest(
      assetBondData.couponRate,
      assetBondData.loanStartTimestamp,
      assetBondData.maturityTimestamp
    );

    vars.paymentDateTimeStruct = TimeConverter.parseTimestamp(paymentTimestamp);
    vars.paymentDate = TimeConverter.toTimestamp(
      vars.paymentDateTimeStruct.year,
      vars.paymentDateTimeStruct.month,
      vars.paymentDateTimeStruct.day + 1
    );

    vars.secondTermRate =
      Math.calculateCompoundedInterest(
        assetBondData.couponRate + assetBondData.delinquencyRate,
        assetBondData.maturityTimestamp,
        vars.paymentDate
      ) -
      WadRayMath.ray();
    vars.totalRate = vars.firstTermRate + vars.secondTermRate;

    return assetBondData.principal.rayMul(vars.totalRate) - assetBondData.principal;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

library DataStruct {
  /**
    @notice The main reserve data struct.
   */
  struct ReserveData {
    uint256 moneyPoolFactor;
    uint256 lTokenInterestIndex;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 lastUpdateTimestamp;
    address lTokenAddress;
    address dTokenAddress;
    address interestModelAddress;
    address tokenizerAddress;
    uint8 id;
    bool isPaused;
    bool isActivated;
  }

  /**
   * @notice The asset bond data struct.
   * @param ipfsHash The IPFS hash that contains the informations and contracts
   * between Collateral Service Provider and lender.
   * @param maturityTimestamp The amount of time measured in seconds that can elapse
   * before the NPL company liquidate the loan and seize the asset bond collateral.
   * @param borrower The address of the borrower.
   */
  struct AssetBondData {
    AssetBondState state;
    address borrower;
    address signer;
    address collateralServiceProvider;
    uint256 principal;
    uint256 debtCeiling;
    uint256 couponRate;
    uint256 interestRate;
    uint256 delinquencyRate;
    uint256 loanStartTimestamp;
    uint256 collateralizeTimestamp;
    uint256 maturityTimestamp;
    uint256 liquidationTimestamp;
    string ipfsHash; // refactor : gas
    string signerOpinionHash;
  }

  struct AssetBondIdData {
    uint256 nonce;
    uint256 countryCode;
    uint256 collateralServiceProviderIdentificationNumber;
    uint256 collateralLatitude;
    uint256 collateralLatitudeSign;
    uint256 collateralLongitude;
    uint256 collateralLongitudeSign;
    uint256 collateralDetail;
    uint256 collateralCategory;
    uint256 productNumber;
  }

  /**
    @notice The states of asset bond
    * EMPTY: After
    * SETTLED:
    * CONFIRMED:
    * COLLATERALIZED:
    * DELINQUENT:
    * REDEEMED:
    * LIQUIDATED:
   */
  enum AssetBondState {
    EMPTY,
    SETTLED,
    CONFIRMED,
    COLLATERALIZED,
    DELINQUENT,
    REDEEMED,
    LIQUIDATED
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import './WadRayMath.sol';

library Math {
  using WadRayMath for uint256;

  uint256 internal constant SECONDSPERYEAR = 365 days;

  function calculateLinearInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    uint256 timeDelta = currentTimestamp - uint256(lastUpdateTimestamp);

    return ((rate * timeDelta) / SECONDSPERYEAR) + WadRayMath.ray();
  }

  /**
   * @notice Author : AAVE
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - lastUpdateTimestamp;

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    // loss of precision is endurable
    // slither-disable-next-line divide-before-multiply
    uint256 ratePerSecond = rate / SECONDSPERYEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
    uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

    return WadRayMath.ray() + (ratePerSecond * exp) + secondTerm + thirdTerm;
  }

  function calculateRateInIncreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountIn,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountIn.wadToRay().rayMul(rate);

    uint256 newTotalBalance = totalBalance + amountIn;
    uint256 newAverageRate = (weightedAverageRate + weightedAmountRate).rayDiv(
      newTotalBalance.wadToRay()
    );

    return (newTotalBalance, newAverageRate);
  }

  function calculateRateInDecreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountOut,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    // if decreasing amount exceeds totalBalance,
    // overall rate and balacne would be set 0
    if (totalBalance <= amountOut) {
      return (0, 0);
    }

    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountOut.wadToRay().rayMul(rate);

    if (weightedAverageRate <= weightedAmountRate) {
      return (0, 0);
    }

    uint256 newTotalBalance = totalBalance - amountOut;

    uint256 newAverageRate = (weightedAverageRate - weightedAmountRate).rayDiv(
      newTotalBalance.wadToRay()
    );

    return (newTotalBalance, newAverageRate);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Ethereum timestamp conversion library
 * @author ethereum-datatime
 */
library TimeConverter {
  struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  uint256 constant DAY_IN_SECONDS = 86400;
  uint256 constant YEAR_IN_SECONDS = 31536000;
  uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint256 constant HOUR_IN_SECONDS = 3600;
  uint256 constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint256 year) internal pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (isLeapYear(year)) {
      return 29;
    } else {
      return 28;
    }
  }

  function parseTimestamp(uint256 timestamp) public pure returns (DateTime memory dateTime) {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;

    // Year
    dateTime.year = getYear(timestamp);
    buf = leapYearsBefore(dateTime.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dateTime.year - ORIGIN_YEAR - buf);

    // Month
    uint256 secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dateTime.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dateTime.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dateTime.month, dateTime.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dateTime.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dateTime.hour = getHour(timestamp);
    // Minute
    dateTime.minute = getMinute(timestamp);
    // Second
    dateTime.second = getSecond(timestamp);
    // Day of week.
    dateTime.weekday = getWeekday(timestamp);
  }

  function getYear(uint256 timestamp) internal pure returns (uint16) {
    uint256 secondsAccountedFor = 0;
    uint16 year;
    uint256 numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) internal pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) public pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) public pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) public pure returns (uint256 timestamp) {
    uint16 i;

    // Year
    for (i = ORIGIN_YEAR; i < year; i++) {
      if (isLeapYear(i)) {
        timestamp += LEAP_YEAR_IN_SECONDS;
      } else {
        timestamp += YEAR_IN_SECONDS;
      }
    }

    // Month
    uint8[12] memory monthDayCounts;
    monthDayCounts[0] = 31;
    if (isLeapYear(year)) {
      monthDayCounts[1] = 29;
    } else {
      monthDayCounts[1] = 28;
    }
    monthDayCounts[2] = 31;
    monthDayCounts[3] = 30;
    monthDayCounts[4] = 31;
    monthDayCounts[5] = 30;
    monthDayCounts[6] = 31;
    monthDayCounts[7] = 31;
    monthDayCounts[8] = 30;
    monthDayCounts[9] = 31;
    monthDayCounts[10] = 30;
    monthDayCounts[11] = 31;

    for (i = 1; i < month; i++) {
      timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
    }

    // Day
    timestamp += DAY_IN_SECONDS * (day - 1);
    // Hour
    timestamp += HOUR_IN_SECONDS * (hour);
    // Minute
    timestamp += MINUTE_IN_SECONDS * (minute);
    // Second
    timestamp += second;

    return timestamp;
  }
}