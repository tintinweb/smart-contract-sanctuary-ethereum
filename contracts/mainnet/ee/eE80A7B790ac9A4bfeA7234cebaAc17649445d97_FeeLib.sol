// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// interfaces
import {IOracle} from "grappa/interfaces/IOracle.sol";

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library FeeLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param vaultDetails VaultDetails struct
     * @param managementFee charged at each round
     * @param performanceFee charged if the vault performs
     * @return totalFees all fees taken in round
     * @return balances is the asset balances at the start of the next round
     */
    function processFees(VaultDetails calldata vaultDetails, uint256 managementFee, uint256 performanceFee)
        external
        pure
        returns (uint256[] memory totalFees, uint256[] memory balances)
    {
        uint256 arrayLength = vaultDetails.currentBalances.length;

        totalFees = new uint256[](arrayLength);
        balances = new uint256[](arrayLength);

        for (uint256 i; i < vaultDetails.currentBalances.length;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            balances[i] = vaultDetails.currentBalances[i];

            // primary asset amount used to calculating the amount of secondary assets deposited in the round
            uint256 pendingBalance =
                vaultDetails.roundStartingBalances[i].mulDivDown(vaultDetails.totalPending, vaultDetails.roundStartingBalances[0]);

            // At round 1, currentBalance == totalPending so we do not take fee on the first round
            if (balances[i] > pendingBalance) {
                lockedBalanceSansPending = balances[i] - pendingBalance;
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(managementFee, 100 * PERCENT_MULTIPLIER);

            // Performance fee charged ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > vaultDetails.roundStartingBalances[i]) {
                if (performanceFee > 0) {
                    uint256 performanceAmount = lockedBalanceSansPending - vaultDetails.roundStartingBalances[i];

                    performanceFeeInAsset = performanceAmount.mulDivDown(performanceFee, 100 * PERCENT_MULTIPLIER);
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            // deducting fees from current balances
            balances[i] -= totalFees[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates Net Asset Value of the vault and pending deposits
     * @dev prices are based on expiry, if rolling close then spot is used
     * @param details NAVDetails struct
     * @return totalNav of all the assets
     * @return pendingNAV of just the pending assets
     * @return prices of the different assets
     */
    function calculateNAVs(NAVDetails calldata details)
        external
        view
        returns (uint256 totalNav, uint256 pendingNAV, uint256[] memory prices)
    {
        IOracle oracle = IOracle(details.oracleAddr);

        uint256 collateralLength = details.collaterals.length;

        prices = new uint256[](collateralLength);

        // primary asset that all other assets will be quotes in
        address quote = details.collaterals[0].addr;

        for (uint256 i; i < collateralLength;) {
            prices[i] = UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (i > 0) prices[i] = _getPrice(oracle, details.collaterals[i].addr, quote, details.expiry);

            // sum of all asset(s) value
            totalNav += details.currentBalances[i].mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            // calculated pending deposit based on the primary asset
            uint256 pendingBalance = details.totalPending.mulDivDown(details.startingBalances[i], details.startingBalances[0]);

            // sum of pending assets value
            pendingNAV += pendingBalance.mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balance(s)
     * @dev used in pending deposits per account
     */
    function calculateRelativeNAV(
        Collateral[] memory collaterals,
        uint256[] memory roundStartingBalances,
        uint256[] memory collateralPrices,
        uint256 primaryDeposited
    ) external pure returns (uint256 nav) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = roundStartingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            nav += balance.mulDivDown(collateralPrices[i], 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param navPerShare is the price in asset per share
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return nav.mulDivDown(UNIT, navPerShare);
    }

    function pricePerShare(uint256 totalSupply, uint256 totalNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalNAV - pendingNAV).mulDivDown(UNIT, totalSupply) : UNIT;
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracle abstracted chainlink oracle
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(IOracle oracle, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        // if timestamp is the placeholder (1) or zero then get the spot
        if (expiry <= PLACEHOLDER_UINT) price = oracle.getSpotPrice(base, quote);
        else (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
    }

    function _sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return shares.mulDivDown(navPerShare, UNIT);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

// Placeholder uint value to prevent cold writes
uint256 constant PLACEHOLDER_UINT = 1;

// Fees are 18-decimal places. For example: 20 * 10**18 = 20%
uint256 constant PERCENT_MULTIPLIER = 10 ** 18;

uint32 constant SECONDS_PER_DAY = 86400;
uint32 constant DAYS_PER_YEAR = 365;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();
error BadAddress();

// BaseVault
error BV_ActiveRound();
error BV_BadCollateral();
error BV_BadExpiry();
error BV_BadLevRatio();
error BV_ExpiryMismatch();
error BV_MarginEngineMismatch();
error BV_RoundClosed();
error BV_BadFee();
error BV_BadRoundConfig();
error BV_BadDepositAmount();
error BV_BadAmount();
error BV_BadRound();
error BV_BadNumShares();
error BV_ExceedsAvailable();
error BV_BadPPS();
error BV_BadSB();
error BV_BadCP();
error BV_BadRatios();

// OptionsVault
error OV_ActiveRound();
error OV_BadRound();
error OV_BadCollateral();
error OV_RoundClosed();
error OV_OptionNotExpired();
error OV_NoCollateralPending();
error OV_VaultExercised();

// PhysicalOptionVault
error POV_CannotRequestWithdraw();
error POV_NotExercised();
error POV_NoCollateral();
error POV_OptionNotExpired();
error POV_BadExerciseWindow();

// Fee Utils
error FL_NPSLow();

// Vault Utils
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_BadOwnerAddress();
error VL_BadManagerAddress();
error VL_BadFeeAddress();
error VL_BadOracleAddress();
error VL_BadPauserAddress();
error VL_BadFee();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();

// StructureLib
error SL_BadExpiryDate();

// Vault Pauser
error VP_VaultNotPermissioned();
error VP_PositionPaused();
error VP_Overflow();
error VP_CustomerNotPermissioned();
error VP_RoundOpen();

// Vault Share
error VS_SupplyExceeded();

// Whitelist Manager
error WL_BadRole();
error WL_Paused();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice Initialization parameters for the vault.
 * @param _owner is the owner of the vault with critical permissions
 * @param _manager is the address that is responsible for advancing the vault
 * @param _feeRecipient is the address to receive vault performance and management fees
 * @param _oracle is used to calculate NAV
 * @param _whitelist is used to check address access permissions
 * @param _managementFee is the management fee pct.
 * @param _performanceFee is the performance fee pct.
 * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
 * @param _collateralRatios is the array of round starting balances to set the initial collateral ratios
 * @param _collaterals is the assets used in the vault
 * @param _roundConfig sets the duration and expiration of options
 * @param _vaultParams set vaultParam struct
 */
struct InitParams {
    address _owner;
    address _manager;
    address _feeRecipient;
    address _oracle;
    address _whitelist;
    uint256 _managementFee;
    uint256 _performanceFee;
    address _pauser;
    uint256[] _collateralRatios;
    Collateral[] _collaterals;
    RoundConfig _roundConfig;
}

struct Collateral {
    // Grappa asset Id
    uint8 id;
    // ERC20 token address for the required collateral
    address addr;
    // the amount of decimals or token
    uint8 decimals;
}

struct VaultState {
    // 32 byte slot 1
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Amount that is currently locked for selling options
    uint96 lockedAmount;
    // Amount that was locked for selling options in the previous round
    // used for calculating performance fee deduction
    uint96 lastLockedAmount;
    // 32 byte slot 2
    // Stores the total tally of how much of `asset` there is
    // to be used to mint vault tokens
    uint96 totalPending;
    // store the number of shares queued for withdraw this round
    // zero'ed out at the start of each round, pauser withdraws all queued shares.
    uint128 queuedWithdrawShares;
}

struct DepositReceipt {
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Deposit amount, max 79,228,162,514 or 79 Billion ETH deposit
    uint96 amount;
    // Unredeemed shares balance
    uint128 unredeemedShares;
}

struct RoundConfig {
    // the duration of the option
    uint32 duration;
    // day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
    uint8 dayOfWeek;
    // hour of the day the option should expire. 0 is midnight
    uint8 hourOfDay;
}

// Used for fee calculations at the end of a round
struct VaultDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] roundStartingBalances;
    // current balances
    uint256[] currentBalances;
    // Total pending primary asset
    uint256 totalPending;
}

// Used when rolling funds into a new round
struct NAVDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] startingBalances;
    // Current collateral balances
    uint256[] currentBalances;
    // Used to calculate NAV
    address oracleAddr;
    // Expiry of the round
    uint256 expiry;
    // Pending deposits
    uint256 totalPending;
}

/**
 * @dev Position struct
 * @param tokenId option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}