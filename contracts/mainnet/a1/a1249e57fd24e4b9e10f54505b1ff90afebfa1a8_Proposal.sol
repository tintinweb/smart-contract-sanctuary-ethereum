/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

pragma solidity 0.6.7;

contract SafeMath {
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
    function addition(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        return subtract(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function subtract(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        return divide(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function divide(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
contract SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function multiply(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function divide(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function subtract(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function addition(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

/**
Reflexer PI Controller License 1.0

Definitions

Primary License: This license agreement
Secondary License: GNU General Public License v2.0 or later
Effective Date of Secondary License: May 5, 2023

Licensed Software:

Software License Grant: Subject to and dependent upon your adherence to the terms and conditions of this Primary License, and subject to explicit approval by Reflexer, Inc., Reflexer, Inc., hereby grants you the right to copy, modify or otherwise create derivative works, redistribute, and use the Licensed Software solely for internal testing and development, and solely until the Effective Date of the Secondary License.  You may not, and you agree you will not, use the Licensed Software outside the scope of the limited license grant in this Primary License.

You agree you will not (i) use the Licensed Software for any commercial purpose, and (ii) deploy the Licensed Software to a blockchain system other than as a noncommercial deployment to a testnet in which tokens or transactions could not reasonably be expected to have or develop commercial value.You agree to be bound by the terms and conditions of this Primary License until the Effective Date of the Secondary License, at which time the Primary License will expire and be replaced by the Secondary License. You Agree that as of the Effective Date of the Secondary License, you will be bound by the terms and conditions of the Secondary License.

You understand and agree that any violation of the terms and conditions of this License will automatically terminate your rights under this License for the current and all other versions of the Licensed Software.

You understand and agree that any use of the Licensed Software outside the boundaries of the limited licensed granted in this Primary License renders the license granted in this Primary License null and void as of the date you first used the Licensed Software in any way (void ab initio).You understand and agree that you may purchase a commercial license to use a version of the Licensed Software under the terms and conditions set by Reflexer, Inc.  You understand and agree that you will display an unmodified copy of this Primary License with each Licensed Software, and any derivative work of the Licensed Software.

TO THE EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED SOFTWARE IS PROVIDED ON AN “AS IS” BASIS. REFLEXER, INC HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS OR IMPLIED, INCLUDING (WITHOUT LIMITATION) ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND TITLE.

You understand and agree that all copies of the Licensed Software, and all derivative works thereof, are each subject to the terms and conditions of this License. Notwithstanding the foregoing, You hereby grant to Reflexer, Inc. a fully paid-up, worldwide, fully sublicensable license to use,for any lawful purpose, any such derivative work made by or for You, now or in the future. You agree that you will, at the request of Reflexer, Inc., provide Reflexer, Inc. with the complete source code to such derivative work.

Copyright © 2021 Reflexer Inc. All Rights Reserved
**/

contract PIScaledPerSecondCalculator is SafeMath, SignedSafeMath {
    // --- Authorities ---
    mapping (address => uint) public authorities;
    function addAuthority(address account) external isAuthority { authorities[account] = 1; }
    function removeAuthority(address account) external isAuthority { authorities[account] = 0; }
    modifier isAuthority {
        require(authorities[msg.sender] == 1, "PIScaledPerSecondCalculator/not-an-authority");
        _;
    }

    // --- Readers ---
    mapping (address => uint) public readers;
    function addReader(address account) external isAuthority { readers[account] = 1; }
    function removeReader(address account) external isAuthority { readers[account] = 0; }
    modifier isReader {
        require(either(allReaderToggle == 1, readers[msg.sender] == 1), "PIScaledPerSecondCalculator/not-a-reader");
        _;
    }

    // --- Structs ---
    struct ControllerGains {
        // This value is multiplied with the proportional term
        int Kp;                                      // [EIGHTEEN_DECIMAL_NUMBER]
        // This value is multiplied with priceDeviationCumulative
        int Ki;                                      // [EIGHTEEN_DECIMAL_NUMBER]
    }
    struct DeviationObservation {
        // The timestamp when this observation was stored
        uint timestamp;
        // The proportional term stored in this observation
        int  proportional;
        // The integral term stored in this observation
        int  integral;
    }

    // -- Static & Default Variables ---
    // The Kp and Ki values used in this calculator
    ControllerGains internal controllerGains;

    // Flag that can allow anyone to read variables
    uint256 public   allReaderToggle;
    // The minimum percentage deviation from the redemption price that allows the contract to calculate a non null redemption rate
    uint256 internal noiseBarrier;                   // [EIGHTEEN_DECIMAL_NUMBER]
    // The default redemption rate to calculate in case P + I is smaller than noiseBarrier
    uint256 internal defaultRedemptionRate;          // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The maximum value allowed for the redemption rate
    uint256 internal feedbackOutputUpperBound;       // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The minimum value allowed for the redemption rate
    int256  internal feedbackOutputLowerBound;       // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The minimum delay between two computeRate calls
    uint256 internal integralPeriodSize;             // [seconds]

    // --- Fluctuating/Dynamic Variables ---
    // Array of observations storing the latest timestamp as well as the proportional and integral terms
    DeviationObservation[] internal deviationObservations;
    // Array of historical priceDeviationCumulative
    int256[]               internal historicalCumulativeDeviations;

    // The integral term (sum of deviations at each calculateRate call minus the leak applied at every call)
    int256  internal priceDeviationCumulative;             // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // The per second leak applied to priceDeviationCumulative before the latest deviation is added
    uint256 internal perSecondCumulativeLeak;              // [TWENTY_SEVEN_DECIMAL_NUMBER]
    // Timestamp of the last update
    uint256 internal lastUpdateTime;                       // [timestamp]
    // Flag indicating that the rate computed is per second
    uint256 constant internal defaultGlobalTimeline = 1;

    // Address that can validate seeds
    address public seedProposer;

    uint256 internal constant NEGATIVE_RATE_LIMIT         = TWENTY_SEVEN_DECIMAL_NUMBER - 1;
    uint256 internal constant TWENTY_SEVEN_DECIMAL_NUMBER = 10 ** 27;
    uint256 internal constant EIGHTEEN_DECIMAL_NUMBER     = 10 ** 18;

    constructor(
        int256 Kp_,
        int256 Ki_,
        uint256 perSecondCumulativeLeak_,
        uint256 integralPeriodSize_,
        uint256 noiseBarrier_,
        uint256 feedbackOutputUpperBound_,
        int256  feedbackOutputLowerBound_,
        int256[] memory importedState
    ) public {
        defaultRedemptionRate           = TWENTY_SEVEN_DECIMAL_NUMBER;

        require(both(feedbackOutputUpperBound_ < subtract(subtract(uint(-1), defaultRedemptionRate), 1), feedbackOutputUpperBound_ > 0), "PIScaledPerSecondCalculator/invalid-foub");
        require(both(feedbackOutputLowerBound_ < 0, feedbackOutputLowerBound_ >= -int(NEGATIVE_RATE_LIMIT)), "PIScaledPerSecondCalculator/invalid-folb");
        require(integralPeriodSize_ > 0, "PIScaledPerSecondCalculator/invalid-ips");
        require(uint(importedState[0]) <= now, "PIScaledPerSecondCalculator/invalid-imported-time");
        require(both(noiseBarrier_ > 0, noiseBarrier_ <= EIGHTEEN_DECIMAL_NUMBER), "PIScaledPerSecondCalculator/invalid-nb");
        require(both(Kp_ >= -int(EIGHTEEN_DECIMAL_NUMBER), Kp_ <= int(EIGHTEEN_DECIMAL_NUMBER)), "PIScaledPerSecondCalculator/invalid-sg");
        require(both(Ki_ >= -int(EIGHTEEN_DECIMAL_NUMBER), Ki_ <= int(EIGHTEEN_DECIMAL_NUMBER)), "PIScaledPerSecondCalculator/invalid-ag");

        authorities[msg.sender]         = 1;
        readers[msg.sender]             = 1;

        feedbackOutputUpperBound        = feedbackOutputUpperBound_;
        feedbackOutputLowerBound        = feedbackOutputLowerBound_;
        integralPeriodSize              = integralPeriodSize_;
        controllerGains                 = ControllerGains(Kp_, Ki_);
        perSecondCumulativeLeak         = perSecondCumulativeLeak_;
        priceDeviationCumulative        = importedState[3];
        noiseBarrier                    = noiseBarrier_;
        lastUpdateTime                  = uint(importedState[0]);

        if (importedState[4] > 0) {
          deviationObservations.push(
            DeviationObservation(uint(importedState[4]), importedState[1], importedState[2])
          );
        }

        historicalCumulativeDeviations.push(priceDeviationCumulative);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the address parameter to change
    * @param addr The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthority {
        if (parameter == "seedProposer") {
          readers[seedProposer] = 0;
          seedProposer = addr;
          readers[seedProposer] = 1;
        }
        else revert("PIScaledPerSecondCalculator/modify-unrecognized-param");
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthority {
        if (parameter == "nb") {
          require(both(val > 0, val <= EIGHTEEN_DECIMAL_NUMBER), "PIScaledPerSecondCalculator/invalid-nb");
          noiseBarrier = val;
        }
        else if (parameter == "ips") {
          require(val > 0, "PIScaledPerSecondCalculator/null-ips");
          integralPeriodSize = val;
        }
        else if (parameter == "foub") {
          require(both(val < subtract(subtract(uint(-1), defaultRedemptionRate), 1), val > 0), "PIScaledPerSecondCalculator/invalid-foub");
          feedbackOutputUpperBound = val;
        }
        else if (parameter == "pscl") {
          require(val <= TWENTY_SEVEN_DECIMAL_NUMBER, "PIScaledPerSecondCalculator/invalid-pscl");
          perSecondCumulativeLeak = val;
        }
        else if (parameter == "allReaderToggle") {
          allReaderToggle = val;
        }
        else revert("PIScaledPerSecondCalculator/modify-unrecognized-param");
    }
    /*
    * @notify Modify an int256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, int256 val) external isAuthority {
        if (parameter == "folb") {
          require(both(val < 0, val >= -int(NEGATIVE_RATE_LIMIT)), "PIScaledPerSecondCalculator/invalid-folb");
          feedbackOutputLowerBound = val;
        }
        else if (parameter == "sg") {
          require(both(val >= -int(EIGHTEEN_DECIMAL_NUMBER), val <= int(EIGHTEEN_DECIMAL_NUMBER)), "PIScaledPerSecondCalculator/invalid-sg");
          controllerGains.Kp = val;
        }
        else if (parameter == "ag") {
          require(both(val >= -int(EIGHTEEN_DECIMAL_NUMBER), val <= int(EIGHTEEN_DECIMAL_NUMBER)), "PIScaledPerSecondCalculator/invalid-ag");
          controllerGains.Ki = val;
        }
        else if (parameter == "pdc") {
          require(controllerGains.Ki == 0, "PIScaledPerSecondCalculator/cannot-set-pdc");
          priceDeviationCumulative = val;
        }
        else revert("PIScaledPerSecondCalculator/modify-unrecognized-param");
    }

    // --- PI Specific Math ---
    function riemannSum(int x, int y) internal pure returns (int z) {
        return addition(x, y) / 2;
    }
    function absolute(int x) internal pure returns (uint z) {
        z = (x < 0) ? uint(-x) : uint(x);
    }

    // --- PI Utils ---
    /*
    * Return the last proportional term stored in deviationObservations
    */
    function getLastProportionalTerm() public isReader view returns (int256) {
        if (oll() == 0) return 0;
        return deviationObservations[oll() - 1].proportional;
    }
    /*
    * Return the last integral term stored in deviationObservations
    */
    function getLastIntegralTerm() external isReader view returns (int256) {
        if (oll() == 0) return 0;
        return deviationObservations[oll() - 1].integral;
    }
    /*
    * @notice Return the length of deviationObservations
    */
    function oll() public isReader view returns (uint256) {
        return deviationObservations.length;
    }
    /*
    * @notice Return a redemption rate bounded by feedbackOutputLowerBound and feedbackOutputUpperBound as well as the
              timeline over which that rate will take effect
    * @param piOutput The raw redemption rate computed from the proportional and integral terms
    */
    function getBoundedRedemptionRate(int piOutput) public isReader view returns (uint256, uint256) {
        int  boundedPIOutput = piOutput;
        uint newRedemptionRate;

        if (piOutput < feedbackOutputLowerBound) {
          boundedPIOutput = feedbackOutputLowerBound;
        } else if (piOutput > int(feedbackOutputUpperBound)) {
          boundedPIOutput = int(feedbackOutputUpperBound);
        }

        // newRedemptionRate cannot be lower than 10^0 (1) because of the way rpower is designed
        bool negativeOutputExceedsHundred = (boundedPIOutput < 0 && -boundedPIOutput >= int(defaultRedemptionRate));

        // If it is smaller than 1, set it to the nagative rate limit
        if (negativeOutputExceedsHundred) {
          newRedemptionRate = NEGATIVE_RATE_LIMIT;
        } else {
          // If boundedPIOutput is lower than -int(NEGATIVE_RATE_LIMIT) set newRedemptionRate to 1
          if (boundedPIOutput < 0 && boundedPIOutput <= -int(NEGATIVE_RATE_LIMIT)) {
            newRedemptionRate = uint(addition(int(defaultRedemptionRate), -int(NEGATIVE_RATE_LIMIT)));
          } else {
            // Otherwise add defaultRedemptionRate and boundedPIOutput together
            newRedemptionRate = uint(addition(int(defaultRedemptionRate), boundedPIOutput));
          }
        }

        return (newRedemptionRate, defaultGlobalTimeline);
    }
    /*
    * @notice Returns whether the P + I sum exceeds the noise barrier
    * @param piSum Represents a sum between P + I
    * @param redemptionPrice The system coin redemption price
    */
    function breaksNoiseBarrier(uint piSum, uint redemptionPrice) public isReader view returns (bool) {
        uint deltaNoise = subtract(multiply(uint(2), EIGHTEEN_DECIMAL_NUMBER), noiseBarrier);
        return piSum >= subtract(divide(multiply(redemptionPrice, deltaNoise), EIGHTEEN_DECIMAL_NUMBER), redemptionPrice);
    }
    /*
    * @notice Compute a new priceDeviationCumulative (integral term)
    * @param proportionalTerm The proportional term (redemptionPrice - marketPrice) * TWENTY_SEVEN_DECIMAL_NUMBER / redemptionPrice
    * @param accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the new time adjusted deviation
    */
    function getNextPriceDeviationCumulative(int proportionalTerm, uint accumulatedLeak) public isReader view returns (int256, int256) {
        int256 lastProportionalTerm      = getLastProportionalTerm();
        uint256 timeElapsed              = (lastUpdateTime == 0) ? 0 : subtract(now, lastUpdateTime);
        int256 newTimeAdjustedDeviation  = multiply(riemannSum(proportionalTerm, lastProportionalTerm), int(timeElapsed));
        int256 leakedPriceCumulative     = divide(multiply(int(accumulatedLeak), priceDeviationCumulative), int(TWENTY_SEVEN_DECIMAL_NUMBER));

        return (
          addition(leakedPriceCumulative, newTimeAdjustedDeviation),
          newTimeAdjustedDeviation
        );
    }
    /*
    * @notice Apply Kp to the proportional term and Ki to the integral term (by multiplication) and then sum P and I
    * @param proportionalTerm The proportional term
    * @param integralTerm The integral term
    */
    function getGainAdjustedPIOutput(int proportionalTerm, int integralTerm) public isReader view returns (int256) {
        (int adjustedProportional, int adjustedIntegral) = getGainAdjustedTerms(proportionalTerm, integralTerm);
        return addition(adjustedProportional, adjustedIntegral);
    }
    /*
    * @notice Independently return and calculate P * Kp and I * Ki
    * @param proportionalTerm The proportional term
    * @param integralTerm The integral term
    */
    function getGainAdjustedTerms(int proportionalTerm, int integralTerm) public isReader view returns (int256, int256) {
        return (
          multiply(proportionalTerm, int(controllerGains.Kp)) / int(EIGHTEEN_DECIMAL_NUMBER),
          multiply(integralTerm, int(controllerGains.Ki)) / int(EIGHTEEN_DECIMAL_NUMBER)
        );
    }

    // --- Rate Validation/Calculation ---
    /*
    * @notice Compute a new redemption rate
    * @param marketPrice The system coin market price
    * @param redemptionPrice The system coin redemption price
    * @param accumulatedLeak The total leak that will be applied to priceDeviationCumulative (the integral) before the latest
    *        proportional term is added
    */
    function computeRate(
      uint marketPrice,
      uint redemptionPrice,
      uint accumulatedLeak
    ) external returns (uint256) {
        // Only the seed proposer can call this
        require(seedProposer == msg.sender, "PIScaledPerSecondCalculator/invalid-msg-sender");
        // Ensure that at least integralPeriodSize seconds passed since the last update or that this is the first update
        require(subtract(now, lastUpdateTime) >= integralPeriodSize || lastUpdateTime == 0, "PIScaledPerSecondCalculator/wait-more");
        // Scale the market price by 10^9 so it also has 27 decimals like the redemption price
        uint256 scaledMarketPrice = multiply(marketPrice, 10**9);
        // Calculate the proportional term as (redemptionPrice - marketPrice) * TWENTY_SEVEN_DECIMAL_NUMBER / redemptionPrice
        int256 proportionalTerm = multiply(subtract(int(redemptionPrice), int(scaledMarketPrice)), int(TWENTY_SEVEN_DECIMAL_NUMBER)) / int(redemptionPrice);
        // Update the integral term by passing the proportional (current deviation) and the total leak that will be applied to the integral
        updateDeviationHistory(proportionalTerm, accumulatedLeak);
        // Set the last update time to now
        lastUpdateTime = now;
        // Multiply P by Kp and I by Ki and then sum P & I in order to return the result
        int256 piOutput = getGainAdjustedPIOutput(proportionalTerm, priceDeviationCumulative);
        // If the P * Kp + I * Ki output breaks the noise barrier, you can recompute a non null rate. Also make sure the sum is not null
        if (
          breaksNoiseBarrier(absolute(piOutput), redemptionPrice) &&
          piOutput != 0
        ) {
          // Get the new redemption rate by taking into account the feedbackOutputUpperBound and feedbackOutputLowerBound
          (uint newRedemptionRate, ) = getBoundedRedemptionRate(piOutput);
          return newRedemptionRate;
        } else {
          return TWENTY_SEVEN_DECIMAL_NUMBER;
        }
    }
    /*
    * @notice Push new observations in deviationObservations & historicalCumulativeDeviations while also updating priceDeviationCumulative
    * @param proportionalTerm The proportionalTerm
    * @param accumulatedLeak The total leak (similar to a negative interest rate) applied to priceDeviationCumulative before proportionalTerm is added to it
    */
    function updateDeviationHistory(int proportionalTerm, uint accumulatedLeak) internal {
        (int256 virtualDeviationCumulative, ) =
          getNextPriceDeviationCumulative(proportionalTerm, accumulatedLeak);
        priceDeviationCumulative = virtualDeviationCumulative;
        historicalCumulativeDeviations.push(priceDeviationCumulative);
        deviationObservations.push(DeviationObservation(now, proportionalTerm, priceDeviationCumulative));
    }
    /*
    * @notice Compute and return the upcoming redemption rate
    * @param marketPrice The system coin market price
    * @param redemptionPrice The system coin redemption price
    * @param accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the proportionalTerm
    */
    function getNextRedemptionRate(uint marketPrice, uint redemptionPrice, uint accumulatedLeak)
      public isReader view returns (uint256, int256, int256, uint256) {
        uint256 scaledMarketPrice = multiply(marketPrice, 10**9);
        int256 proportionalTerm = multiply(subtract(int(redemptionPrice), int(scaledMarketPrice)), int(TWENTY_SEVEN_DECIMAL_NUMBER)) / int(redemptionPrice);
        (int cumulativeDeviation, ) = getNextPriceDeviationCumulative(proportionalTerm, accumulatedLeak);
        int piOutput = getGainAdjustedPIOutput(proportionalTerm, cumulativeDeviation);
        if (
          breaksNoiseBarrier(absolute(piOutput), redemptionPrice) &&
          piOutput != 0
        ) {
          (uint newRedemptionRate, uint rateTimeline) = getBoundedRedemptionRate(piOutput);
          return (newRedemptionRate, proportionalTerm, cumulativeDeviation, rateTimeline);
        } else {
          return (TWENTY_SEVEN_DECIMAL_NUMBER, proportionalTerm, cumulativeDeviation, defaultGlobalTimeline);
        }
    }

    // --- Parameter Getters ---
    /*
    * @notice Get the timeline over which the computed redemption rate takes effect e.g rateTimeline = 3600 so the rate is
    *         computed over 1 hour
    */
    function rt(uint marketPrice, uint redemptionPrice, uint accumulatedLeak) external isReader view returns (uint256) {
        (, , , uint rateTimeline) = getNextRedemptionRate(marketPrice, redemptionPrice, accumulatedLeak);
        return rateTimeline;
    }
    /*
    * @notice Return Kp
    */
    function sg() external isReader view returns (int256) {
        return controllerGains.Kp;
    }
    /*
    * @notice Return Ki
    */
    function ag() external isReader view returns (int256) {
        return controllerGains.Ki;
    }
    function nb() external isReader view returns (uint256) {
        return noiseBarrier;
    }
    function drr() external isReader view returns (uint256) {
        return defaultRedemptionRate;
    }
    function foub() external isReader view returns (uint256) {
        return feedbackOutputUpperBound;
    }
    function folb() external isReader view returns (int256) {
        return feedbackOutputLowerBound;
    }
    function ips() external isReader view returns (uint256) {
        return integralPeriodSize;
    }
    function dos(uint256 i) external isReader view returns (uint256, int256, int256) {
        return (deviationObservations[i].timestamp, deviationObservations[i].proportional, deviationObservations[i].integral);
    }
    function hcd(uint256 i) external isReader view returns (int256) {
        return historicalCumulativeDeviations[i];
    }
    function pdc() external isReader view returns (int256) {
        return priceDeviationCumulative;
    }
    function pscl() external isReader view returns (uint256) {
        return perSecondCumulativeLeak;
    }
    function lut() external isReader view returns (uint256) {
        return lastUpdateTime;
    }
    function dgt() external isReader view returns (uint256) {
        return defaultGlobalTimeline;
    }
    /*
    * @notice Returns the time elapsed since the last calculateRate call minus integralPeriodSize
    */
    function adat() external isReader view returns (uint256) {
        uint elapsed = subtract(now, lastUpdateTime);
        if (elapsed < integralPeriodSize) {
          return 0;
        }
        return subtract(elapsed, integralPeriodSize);
    }
    /*
    * @notice Returns the time elapsed since the last calculateRate call
    */
    function tlv() external isReader view returns (uint256) {
        uint elapsed = (lastUpdateTime == 0) ? 0 : subtract(now, lastUpdateTime);
        return elapsed;
    }
}

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) external virtual;
    function updateRate(address) external virtual;
    function pidCalculator() external virtual view returns (address);
}

abstract contract CalculatorLike {
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
    function addAuthority(address) external virtual;
    function removeAuthority(address) external virtual;
    function seedProposer() external virtual view returns (address);
    function authorities(address) external virtual view returns (uint);
    function sg() external virtual view returns (int256);
    function ag() external virtual view returns (int256);
    function pscl() external virtual view returns (uint256);
    function ips() external virtual view returns (uint256);
    function nb() external virtual view returns (uint256);
    function foub() external virtual view returns (uint256);
    function folb() external virtual view returns (int256);
    function pdc() external virtual view returns (int256);
    function lut() external virtual view returns (uint256);
    function oll() external virtual view returns (uint256);
    function dos(uint256) external virtual view returns (uint256, int256, int256);
    function allReaderToggle() external virtual view returns (uint256);
}

abstract contract OracleRelayerLike {
    function redemptionPrice() virtual external returns (uint256);
}

contract Proposal is SignedSafeMath {
    CalculatorLike    constant GEB_RRFM_CALCULATOR_OLD = CalculatorLike(0xddA334de7A9C57A641616492175ca203Ba8Cf981);
    RateSetterLike    constant GEB_RRFM_SETTER         = RateSetterLike(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48);
    OracleRelayerLike constant GEB_ORACLE_RELAYER      = OracleRelayerLike(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851);
    int256            constant RAY                     = 10**27;


    function execute(bool) public {
        int256 redemptionPrice = int256(GEB_ORACLE_RELAYER.redemptionPrice());

        // Fetch last observation data to populate next controller state
        int256[] memory adjustedState = getAdjustedCalculatorState(GEB_RRFM_CALCULATOR_OLD, redemptionPrice);

        PIScaledPerSecondCalculator newCalculator = new PIScaledPerSecondCalculator(
            divide(multiply(GEB_RRFM_CALCULATOR_OLD.sg(), redemptionPrice), RAY), // kp
            divide(multiply(GEB_RRFM_CALCULATOR_OLD.ag(), redemptionPrice), RAY), // ki
            GEB_RRFM_CALCULATOR_OLD.pscl(),                                       // perSecondCumulativeLeak
            GEB_RRFM_CALCULATOR_OLD.ips(),                                        // integralPeriodSize
            GEB_RRFM_CALCULATOR_OLD.nb(),                                         // noiseBarrier
            GEB_RRFM_CALCULATOR_OLD.foub(),                                       // feedbackOutputUpperBound
            GEB_RRFM_CALCULATOR_OLD.folb(),                                       // feedbackOutputLowerBound
            adjustedState
        );

        // set allReaderToggle
        newCalculator.modifyParameters("allReaderToggle", uint256(1));

        // swap controller con rate setter
        GEB_RRFM_SETTER.modifyParameters("pidCalculator", address(newCalculator));
        newCalculator.modifyParameters("seedProposer", address(GEB_RRFM_SETTER));
    }

    function getAdjustedCalculatorState(CalculatorLike calculator, int256 redemptionPrice) internal view returns (int256[] memory state) {
        (
            uint256 deviationTimestamp,
            int256  deviationProportional,
            int256  deviationIntegral
        ) = calculator.dos(calculator.oll() - 1);

        state = new int256[](5);
        state[0] = int256(calculator.lut());                                      // lastUpdateTime
        state[1] = divide(multiply(deviationProportional, RAY), redemptionPrice); // deviationObservations.proportional
        state[2] = divide(multiply(deviationIntegral, RAY), redemptionPrice);     // deviationObservations.integral
        state[3] = divide(multiply(calculator.pdc(), RAY), redemptionPrice);      // deviationObservations.priceDeviationCumulative
        state[4] = int256(deviationTimestamp);                                    // deviationObservations.timestamp
    }
}