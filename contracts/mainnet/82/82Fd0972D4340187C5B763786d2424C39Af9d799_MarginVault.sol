// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
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
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
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
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
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
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { SignedConverter } from "./SignedConverter.sol";

/**
 * @title FixedPointInt256
 * @notice FixedPoint library
 */
library FPI {
    using SignedSafeMath for int256;
    using SignedConverter for int256;
    using SafeMath for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 5.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.05 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FPI } from "../libs/FixedPointInt256.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short onToken amount
 * V2: invalid short onToken index
 * V3: short onToken address mismatch
 * V4: invalid long onToken amount
 * V5: invalid long onToken index
 * V6: long onToken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 * V10: shortONtoken should be empty when performing addShort or the same as vault already have
 * V11: _collateralAssets and _amounts length mismatch
 * V12: _collateralAssets and vault.collateralAssets length mismatch
 * V13: _amount for withdrawing long is exceeding unused long amount in the vault
 * V14: amounts for withdrawing collaterals should be same length as collateral assets of vault
 */

/**
 * @title MarginVault
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    uint256 internal constant BASE = 8;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        address shortONtoken;
        // addresses of onTokens a user has shorted (i.e. written) against this vault
        // addresses of onTokens a user has bought and deposited in this vault
        // user can be long onTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long onTokens will be 'deposited' in vaults to act as collateral in order to write onTokens against (i.e. in spreads)
        address longONtoken;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of onTokens minted/written for each onToken address in onTokenAddress
        uint256 shortAmount;
        // quantity of onTokens owned and held in the vault for each onToken address in longONtokens
        uint256 longAmount;
        uint256 usedLongAmount;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // Collateral which is currently used for minting onTokens and can't be used until expiry
        uint256[] reservedCollateralAmounts;
        uint256[] usedCollateralValues;
        uint256[] availableCollateralAmounts;
    }

    /**
     * @dev increase the short onToken balance in a vault when a new onToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _amount number of _shortONtoken being minted from the user's vault
     */
    function addShort(Vault storage _vault, uint256 _amount) external {
        require(_amount > 0, "V1");
        _vault.shortAmount = _vault.shortAmount.add(_amount);
    }

    /**
     * @dev decrease the short onToken balance in a vault when an onToken is burned
     * @param _vault vault to decrease short position in
     * @param _amount number of _shortONtoken being reduced in the user's vault
     * @param _newCollateralRatio ratio represents how much of already used collateral will be used after burn
     * @param _newUsedLongAmount new used long amount
     */
    function removeShort(
        Vault storage _vault,
        uint256 _amount,
        FPI.FixedPointInt memory _newCollateralRatio,
        uint256 _newUsedLongAmount
    ) external returns (uint256[] memory freedCollateralAmounts, uint256[] memory freedCollateralValues) {
        // check that the removed short onToken exists in the vault

        uint256 newShortAmount = _vault.shortAmount.sub(_amount);
        uint256 collateralAssetsLength = _vault.collateralAssets.length;

        uint256[] memory newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
        uint256[] memory newUsedCollateralValues = new uint256[](collateralAssetsLength);
        freedCollateralAmounts = new uint256[](collateralAssetsLength);
        freedCollateralValues = new uint256[](collateralAssetsLength);
        uint256[] memory newAvailableCollateralAmounts = _vault.availableCollateralAmounts;
        // If new short amount is zero, just free all reserved collateral
        if (newShortAmount == 0) {
            newAvailableCollateralAmounts = _vault.collateralAmounts;

            newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
            newUsedCollateralValues = new uint256[](collateralAssetsLength);
            freedCollateralAmounts = _vault.reservedCollateralAmounts;
            freedCollateralValues = _vault.usedCollateralValues;
        } else {
            // _newCollateralRatio is multiplier which is used to calculate the new used collateral values and used amounts
            for (uint256 i = 0; i < collateralAssetsLength; i++) {
                uint256 collateralDecimals = uint256(IERC20Metadata(_vault.collateralAssets[i]).decimals());
                newReservedCollateralAmounts[i] = toFPImulAndBack(
                    _vault.reservedCollateralAmounts[i],
                    collateralDecimals,
                    _newCollateralRatio,
                    true
                );

                newUsedCollateralValues[i] = toFPImulAndBack(
                    _vault.usedCollateralValues[i],
                    BASE,
                    _newCollateralRatio,
                    true
                );
                freedCollateralAmounts[i] = _vault.reservedCollateralAmounts[i].sub(newReservedCollateralAmounts[i]);
                freedCollateralValues[i] = _vault.usedCollateralValues[i].sub(newUsedCollateralValues[i]);
                newAvailableCollateralAmounts[i] = newAvailableCollateralAmounts[i].add(freedCollateralAmounts[i]);
            }
        }
        _vault.shortAmount = newShortAmount;
        _vault.reservedCollateralAmounts = newReservedCollateralAmounts;
        _vault.usedCollateralValues = newUsedCollateralValues;
        _vault.availableCollateralAmounts = newAvailableCollateralAmounts;
        _vault.usedLongAmount = _newUsedLongAmount;
    }

    /**
     * @dev helper function to transform uint256 to FPI multiply by another FPI and transform back to uint256
     */
    function toFPImulAndBack(
        uint256 _value,
        uint256 _decimals,
        FPI.FixedPointInt memory _multiplicator,
        bool roundDown
    ) internal pure returns (uint256) {
        return FPI.fromScaledUint(_value, _decimals).mul(_multiplicator).toScaledUint(_decimals, roundDown);
    }

    /**
     * @dev increase the long onToken balance in a vault when an onToken is deposited
     * @param _vault vault to add a long position to
     * @param _longONtoken address of the _longONtoken being added to the user's vault
     * @param _amount number of _longONtoken the protocol is adding to the user's vault
     */
    function addLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        require(_amount > 0, "V4");
        address existingLong = _vault.longONtoken;
        require((existingLong == _longONtoken) || (existingLong == address(0)), "V6");

        _vault.longAmount = _vault.longAmount.add(_amount);
        _vault.longONtoken = _longONtoken;
    }

    /**
     * @dev decrease the long onToken balance in a vault when an onToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longONtoken address of the _longONtoken being removed from the user's vault
     * @param _amount number of _longONtoken the protocol is removing from the user's vault
     */
    function removeLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        // check that the removed long onToken exists in the vault at the specified index
        require(_vault.longONtoken == _longONtoken, "V6");

        uint256 vaultLongAmountBefore = _vault.longAmount;
        require((vaultLongAmountBefore - _vault.usedLongAmount) >= _amount, "V13");

        _vault.longAmount = vaultLongAmountBefore.sub(_amount);
    }

    /**
     * @dev increase the collaterals balances in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAssets addresses of the _collateralAssets being added to the user's vault
     * @param _amounts number of _collateralAssets being added to the user's vault
     */
    function addCollaterals(
        Vault storage _vault,
        address[] calldata _collateralAssets,
        uint256[] calldata _amounts
    ) external {
        require(_collateralAssets.length == _amounts.length, "V11");
        require(_collateralAssets.length == _vault.collateralAssets.length, "V12");
        for (uint256 i = 0; i < _collateralAssets.length; i++) {
            _vault.collateralAmounts[i] = _vault.collateralAmounts[i].add(_amounts[i]);
            _vault.availableCollateralAmounts[i] = _vault.availableCollateralAmounts[i].add(_amounts[i]);
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _amounts number of _collateralAssets being removed from the user's vault
     */
    function removeCollateral(Vault storage _vault, uint256[] memory _amounts) external {
        address[] memory collateralAssets = _vault.collateralAssets;
        require(_amounts.length == collateralAssets.length, "V14");

        uint256[] memory availableCollateralAmounts = _vault.availableCollateralAmounts;
        uint256[] memory collateralAmounts = _vault.collateralAmounts;
        for (uint256 i = 0; i < collateralAssets.length; i++) {
            collateralAmounts[i] = _vault.collateralAmounts[i].sub(_amounts[i]);
            availableCollateralAmounts[i] = availableCollateralAmounts[i].sub(_amounts[i]);
        }
        _vault.collateralAmounts = collateralAmounts;
        _vault.availableCollateralAmounts = availableCollateralAmounts;
    }

    /**
     * @dev decrease vaults avalaible collateral and long to update vaults used assets data
     * used when vaults mint option to lock provided assets
     * @param _vault vault to remove collateral from
     * @param _amounts amount of collateral assets being locked in the user's vault
     * @param _usedLongAmount amount of long onToken being locked in the user's vault
     * @param _usedCollateralValues values of collaterals amounts being locked
     */
    function useVaultsAssets(
        Vault storage _vault,
        uint256[] memory _amounts,
        uint256 _usedLongAmount,
        uint256[] memory _usedCollateralValues
    ) external {
        require(
            _amounts.length == _vault.collateralAssets.length,
            "Amounts for collateral is not same length as collateral assets"
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 newReservedCollateralAmount = _vault.reservedCollateralAmounts[i].add(_amounts[i]);

            _vault.reservedCollateralAmounts[i] = newReservedCollateralAmount;
            require(
                _vault.reservedCollateralAmounts[i] <= _vault.collateralAmounts[i],
                "Trying to use collateral which exceeds vault's balance"
            );
            _vault.availableCollateralAmounts[i] = _vault.collateralAmounts[i].sub(newReservedCollateralAmount);
            _vault.usedCollateralValues[i] = _vault.usedCollateralValues[i].add(_usedCollateralValues[i]);
        }

        _vault.usedLongAmount = _vault.usedLongAmount.add(_usedLongAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * @title SignedConverter
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
        }
    }
}