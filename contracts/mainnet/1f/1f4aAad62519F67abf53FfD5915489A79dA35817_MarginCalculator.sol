// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/** Library for sharing constants between contracts */
library Constants {
    uint8 public constant MAX_COLLATERAL_ASSETS = 6;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { OracleInterface } from "../interfaces/OracleInterface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { FPI } from "../libs/FixedPointInt256.sol";
import { MarginVault } from "../libs/MarginVault.sol";
import { ArrayAddressUtils } from "../libs/ArrayAddressUtils.sol";
import { Constants } from "./Constants.sol";

/**
 * @title MarginCalculator
 * @notice Calculator module that checks if a given vault is valid, calculates margin requirements, and settlement proceeds
 */
contract MarginCalculator is Ownable {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;
    using ArrayAddressUtils for address[];

    /// @dev decimals used by strike price and oracle price, onToken
    uint256 internal constant BASE = 8;

    /// @dev struct to store all needed vault details
    struct VaultDetails {
        uint256 shortAmount;
        uint256 longAmount;
        uint256 usedLongAmount;
        uint256 shortStrikePrice;
        uint256 longStrikePrice;
        uint256 expiryTimestamp;
        address shortONtoken;
        bool isPut;
        bool hasLong;
        address longONtoken;
        address underlyingAsset;
        address strikeAsset;
        address[] collateralAssets;
        uint256[] collateralAmounts;
        uint256[] reservedCollateralAmounts;
        uint256[] availableCollateralAmounts;
        uint256[] collateralsDecimals;
        uint256[] usedCollateralValues;
    }

    struct ONTokenDetails {
        address[] collaterals;
        uint256[] collateralsAmounts;
        uint256[] collateralsValues;
        uint256[] collateralsDecimals;
        address underlying;
        address strikeAsset;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
        uint256 collaterizedTotalAmount;
    }

    /// @dev FixedPoint 0
    FPI.FixedPointInt internal ZERO = FPI.fromScaledUint(0, BASE);

    /// @dev oracle module
    OracleInterface public oracle;

    /**
     * @notice constructor
     * @param _oracle oracle module address
     */
    constructor(address _oracle, address _owner) {
        require(_oracle != address(0), "MarginCalculator: invalid oracle address");
        oracle = OracleInterface(_oracle);
        transferOwnership(_owner);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice get an onToken's payout/cash value after expiry, in the collateral asset
     * @param _onToken onToken address
     * @param _amount amount of the onToken to calculate the payout for, always represented in 1e8
     * @return amount of collateral to pay out for provided amount rate
     */
    function getPayout(address _onToken, uint256 _amount) public view returns (uint256[] memory) {
        // payoutsRaw is amounts of each of collateral asset in collateral asset decimals to be paid out for 1e8 of the onToken
        uint256[] memory payoutsRaw = getExpiredPayoutRate(_onToken);
        uint256[] memory payouts = new uint256[](payoutsRaw.length);

        for (uint256 i = 0; i < payoutsRaw.length; i++) {
            payouts[i] = payoutsRaw[i].mul(_amount).div(10**BASE);
        }

        return payouts;
    }

    /**
     * @notice return the cash value of an expired onToken, denominated in collateral
     * @param _onToken onToken address
     * @return collateralsPayoutRate - how much collateral can be taken out by 1 onToken unit, scaled by 1e8,
     * or how much collateral can be taken out for 1 (1e8) onToken
     */
    function getExpiredPayoutRate(address _onToken) public view returns (uint256[] memory collateralsPayoutRate) {
        require(_onToken != address(0), "MarginCalculator: Invalid token address");

        ONTokenDetails memory onTokenDetails = _getONtokenDetailsStruct(_onToken);

        require(block.timestamp >= onTokenDetails.expiry, "MarginCalculator: ONtoken not expired yet");

        // Strike - current price USDC
        FPI.FixedPointInt memory cashValueInStrike = _getExpiredCashValue(
            onTokenDetails.underlying,
            onTokenDetails.strikeAsset,
            onTokenDetails.expiry,
            onTokenDetails.strikePrice,
            onTokenDetails.isPut
        );
        uint256 onTokenTotalCollateralValue = uint256ArraySum(onTokenDetails.collateralsValues);

        // FPI.FixedPointInt memory strikePriceFpi = FPI.fromScaledUint(oToenDetails.strikePrice, BASE);
        // Amounts of collateral to transfer for 1 onToken
        collateralsPayoutRate = new uint256[](onTokenDetails.collaterals.length);

        // In case of all onToken amount was burnt
        if (onTokenTotalCollateralValue == 0) {
            return collateralsPayoutRate;
        }

        FPI.FixedPointInt memory collateraizedTotalAmount = FPI.fromScaledUint(
            onTokenDetails.collaterizedTotalAmount,
            BASE
        );
        for (uint256 i = 0; i < onTokenDetails.collaterals.length; i++) {
            // the exchangeRate was scaled by 1e8, if 1e8 onToken can take out 1 USDC, the exchangeRate is currently 1e8
            // we want to return: how much USDC units can be taken out by 1 (1e8 units) onToken

            uint256 collateralDecimals = onTokenDetails.collateralsDecimals[i];
            // Collateral value is calculated in strike asset, used BASE decimals only for convinience
            FPI.FixedPointInt memory collateralValue = FPI.fromScaledUint(onTokenDetails.collateralsValues[i], BASE);
            FPI.FixedPointInt memory collateralPayoutValueInStrike = collateralValue.mul(cashValueInStrike).div(
                FPI.fromScaledUint(onTokenTotalCollateralValue, BASE)
            );

            // Compute maximal collateral payout rate as onToken.collateralsAmounts[i] / collaterizedTotalAmount
            FPI.FixedPointInt memory maxCollateralPayoutRate = FPI
                .fromScaledUint(onTokenDetails.collateralsAmounts[i], collateralDecimals)
                .div(collateraizedTotalAmount);
            // Compute collateralPayoutRate for normal conditions
            FPI.FixedPointInt memory collateralPayoutRate = _convertAmountOnExpiryPrice(
                collateralPayoutValueInStrike,
                onTokenDetails.strikeAsset,
                onTokenDetails.collaterals[i],
                onTokenDetails.expiry
            );
            collateralsPayoutRate[i] = FPI.min(maxCollateralPayoutRate, collateralPayoutRate).toScaledUint(
                collateralDecimals,
                false
            );
        }
        return collateralsPayoutRate;
    }

    /**
     * @notice returns the amount of collateral that can be removed from an actual or a theoretical vault
     * @dev return amount is denominated in the collateral asset for the onToken in the vault, or the collateral asset in the vault
     * @param _vault theoretical vault that needs to be checked
     * @return excessCollateral - the amount by which the margin is above or below the required amount
     */
    function getExcessCollateral(MarginVault.Vault memory _vault) external view returns (uint256[] memory) {
        bool hasExpiredShort = ONtokenInterface(_vault.shortONtoken).expiryTimestamp() <= block.timestamp;

        // if the vault contains no onTokens, return the amount of collateral
        if (!hasExpiredShort) {
            return _vault.availableCollateralAmounts;
        }

        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        // This payout represents how much redeemer will get for each 1e8 of onToken. But from the vault side we should also calculate ratio
        // of amounts of each collateral provided by vault to same total amount used for mint total number of onTokens
        // For example: one vault provided [200 USDC, 0 DAI], and another vault [0 USDC, 200 DAI] for the onToken mint
        // and get payout returns [100 USDC, 100 DAI] first vault pays all the 100 USDC and the second one all the 100 DAI
        // uint256[] memory payoutsRaw = getExpiredPayoutRate(vaultDetails.shortONtoken);
        uint256[] memory onTokenCollateralsValues = ONtokenInterface(vaultDetails.shortONtoken).getCollateralsValues();
        uint256 onTokenCollaterizedTotalAmount = ONtokenInterface(vaultDetails.shortONtoken).collaterizedTotalAmount();
        uint256[] memory shortPayoutsRaw = getExpiredPayoutRate(vaultDetails.shortONtoken);

        return
            _getExcessCollateral(
                vaultDetails,
                shortPayoutsRaw,
                onTokenCollateralsValues,
                onTokenCollaterizedTotalAmount
            );
    }

    function _getExcessCollateral(
        VaultDetails memory vaultDetails,
        uint256[] memory shortPayoutsRaw,
        uint256[] memory onTokenCollateralsValues,
        uint256 onTokenCollaterizedTotalAmount
    ) internal view returns (uint256[] memory) {
        uint256[] memory longPayouts = vaultDetails.hasLong && vaultDetails.longAmount != 0
            ? getPayout(vaultDetails.longONtoken, vaultDetails.longAmount)
            : new uint256[](vaultDetails.collateralAssets.length);

        FPI.FixedPointInt memory _onTokenCollaterizedTotalAmount = FPI.fromScaledUint(
            onTokenCollaterizedTotalAmount,
            BASE
        );
        uint256[] memory _excessCollaterals = vaultDetails.collateralAmounts;
        for (uint256 i = 0; i < vaultDetails.collateralAssets.length; i++) {
            uint256 collateralValueProvidedByVault = vaultDetails.usedCollateralValues[i];
            if (collateralValueProvidedByVault == 0) {
                continue;
            }

            uint256 collateralDecimals = vaultDetails.collateralsDecimals[i];

            FPI.FixedPointInt memory totalCollateralValue = FPI
                .fromScaledUint(shortPayoutsRaw[i], collateralDecimals)
                .mul(_onTokenCollaterizedTotalAmount);

            // This ratio represents for specific collateral what part does this vault cover total collaterization of onToken by this collateral
            FPI.FixedPointInt memory vaultCollateralRatio = FPI
                .fromScaledUint(collateralValueProvidedByVault, BASE)
                .div(FPI.fromScaledUint(onTokenCollateralsValues[i], BASE));

            uint256 shortRedeemableCollateral = totalCollateralValue.mul(vaultCollateralRatio).toScaledUint(
                collateralDecimals,
                // Round down shoud be false here cause we subsctruct this value and true can lead to overflow
                false
            );
            _excessCollaterals[i] = _excessCollaterals[i].add(longPayouts[i]).sub(shortRedeemableCollateral);
        }

        return _excessCollaterals;
    }

    /**
     * @notice calculates sum of uint256 array
     * @param _array uint256[] memory
     * @return uint256 sum of all elements in _array
     */
    function uint256ArraySum(uint256[] memory _array) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            sum = sum.add(_array[i]);
        }
        return sum;
    }

    /**
     * @notice return the cash value of an expired onToken, denominated in strike asset
     * @dev for a call, return Max (0, underlyingPriceInStrike - onToken.strikePrice)
     * @dev for a put, return Max(0, onToken.strikePrice - underlyingPriceInStrike)
     * @param _underlying onToken underlying asset
     * @param _strike onToken strike asset
     * @param _expiryTimestamp onToken expiry timestamp
     * @param _strikePrice onToken strike price
     * @param _strikePrice true if onToken is put otherwise false
     * @return cash value of an expired onToken, denominated in the strike asset, as FPI.FixedPointInt
     */
    function _getExpiredCashValue(
        address _underlying, // WETH
        address _strike, // USDC
        uint256 _expiryTimestamp, // onToken expire
        uint256 _strikePrice, // 4000
        bool _isPut // true
    ) internal view returns (FPI.FixedPointInt memory) {
        // strike price is denominated in strike asset
        FPI.FixedPointInt memory strikePrice = FPI.fromScaledUint(_strikePrice, BASE);
        FPI.FixedPointInt memory one = FPI.fromScaledUint(1, 0);

        // calculate the value of the underlying asset in terms of the strike asset
        FPI.FixedPointInt memory underlyingPriceInStrike = _convertAmountOnExpiryPrice(
            one, // underlying price is 1 (1e27) in term of underlying
            _underlying,
            _strike,
            _expiryTimestamp
        );
        return _getCashValue(strikePrice, underlyingPriceInStrike, _isPut);
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on a live price
     * @dev function includes the amount and applies .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on an expiry price
     * @dev function includes the amount and apply .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnExpiryPrice(
        FPI.FixedPointInt memory _amount, // Strike - current price USDC
        address _assetA, // strikeAsset USDC
        address _assetB, // yvUSDC
        uint256 _expiry // onToken expiry
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        (uint256 priceA, bool priceAFinalized) = oracle.getExpiryPrice(_assetA, _expiry);
        (uint256 priceB, bool priceBFinalized) = oracle.getExpiryPrice(_assetB, _expiry);
        require(priceAFinalized && priceBFinalized, "MarginCalculator: price at expiry not finalized yet");
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice get vault details to save us from making multiple external calls
     * @param _vault vault struct
     * @return vault details in VaultDetails struct
     */
    function _getVaultDetails(MarginVault.Vault memory _vault) internal view returns (VaultDetails memory) {
        VaultDetails memory vaultDetails = VaultDetails(
            0, // uint256 shortAmount;
            0, // uint256 longAmount;
            0, // uint256 usedLongAmount;
            0, // uint256 shortStrikePrice;
            0, // uint256 longStrikePrice;
            0, // uint256 expiryTimestamp;
            address(0), // address shortONtoken
            false, // bool isPut;
            false, // bool hasLong;
            address(0), // address longONtoken;
            address(0), // address underlyingAsset;
            address(0), // address strikeAsset;
            new address[](0), // address[] collateralAssets;
            new uint256[](0), // uint256[] collateralAmounts;
            new uint256[](0), // uint256[] reservedCollateralAmounts;
            new uint256[](0), // uint256[] availableCollateralAmounts;
            new uint256[](0), // uint256[] collateralsDecimals;
            new uint256[](0) // uint256[] usedCollateralValues;
        );

        // check if vault has long, short onToken and collateral asset
        vaultDetails.longONtoken = _vault.longONtoken;
        vaultDetails.hasLong = _vault.longONtoken != address(0) && _vault.longAmount != 0;
        vaultDetails.shortONtoken = _vault.shortONtoken;
        vaultDetails.shortAmount = _vault.shortAmount;
        vaultDetails.longAmount = _vault.longAmount;
        vaultDetails.usedLongAmount = _vault.usedLongAmount;
        vaultDetails.collateralAmounts = _vault.collateralAmounts;
        vaultDetails.reservedCollateralAmounts = _vault.reservedCollateralAmounts;
        vaultDetails.availableCollateralAmounts = _vault.availableCollateralAmounts;
        vaultDetails.usedCollateralValues = _vault.usedCollateralValues;

        // get vault long onToken if available
        if (vaultDetails.hasLong) {
            ONtokenInterface long = ONtokenInterface(_vault.longONtoken);
            vaultDetails.longStrikePrice = long.strikePrice();
        }

        // get vault short onToken if available
        ONtokenInterface short = ONtokenInterface(_vault.shortONtoken);
        (
            vaultDetails.collateralAssets,
            ,
            ,
            vaultDetails.collateralsDecimals,
            vaultDetails.underlyingAsset,
            vaultDetails.strikeAsset,
            vaultDetails.shortStrikePrice,
            vaultDetails.expiryTimestamp,
            vaultDetails.isPut,

        ) = _getONtokenDetails(address(short));

        return vaultDetails;
    }

    /**
     * @notice if there is a short option and a long option in the vault,
     * ensure that the long option is able to be used as collateral for the short option
     * @param _vault the vault to check
     * @return true if long is marginable or false if not
     */
    function isMarginableLong(address longONtokenAddress, MarginVault.Vault memory _vault)
        external
        view
        returns (bool)
    {
        // if vault is missing a long or a short, return True
        if (_vault.longONtoken != address(0)) return true;

        // check if longCollateralAssets is same as shortCollateralAssets
        ONTokenDetails memory long = _getONtokenDetailsStruct(longONtokenAddress);
        ONTokenDetails memory short = _getONtokenDetailsStruct(_vault.shortONtoken);

        bool isSameLongCollaterals = keccak256(abi.encode(long.collaterals)) ==
            keccak256(abi.encode(short.collaterals));

        return
            block.timestamp < long.expiry &&
            _vault.longONtoken != _vault.shortONtoken &&
            isSameLongCollaterals &&
            long.underlying == short.underlying &&
            long.strikeAsset == short.strikeAsset &&
            long.expiry == short.expiry &&
            long.strikePrice != short.strikePrice &&
            long.isPut == short.isPut;
    }

    /**
     * @notice get option cash value
     * @dev this assume that the underlying price is denominated in strike asset
     * cash value = max(underlying price - strike price, 0)
     * @param _strikePrice option strike price
     * @param _underlyingPrice option underlying price
     * @param _isPut option type, true for put and false for call option
     */
    function _getCashValue(
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_isPut) return _strikePrice.isGreaterThan(_underlyingPrice) ? _strikePrice.sub(_underlyingPrice) : ZERO;

        return _underlyingPrice.isGreaterThan(_strikePrice) ? _underlyingPrice.sub(_strikePrice) : ZERO;
    }

    /**
     * @dev get onToken detail
     */
    function _getONtokenDetails(address _onToken)
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        ONtokenInterface onToken = ONtokenInterface(_onToken);
        return onToken.getONtokenDetails();
    }

    /**
     * @dev same as _getONtokenDetails but returns struct, usefull to avoid stack too deep
     */
    function _getONtokenDetailsStruct(address _onToken) internal view returns (ONTokenDetails memory) {
        ONTokenDetails memory onTokenDetails;
        (
            address[] memory collaterals,
            uint256[] memory collateralsAmounts,
            uint256[] memory collateralsValues,
            uint256[] memory collateralsDecimals,
            address underlying,
            address strikeAsset,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut,
            uint256 collaterizedTotalAmount
        ) = _getONtokenDetails(_onToken);

        onTokenDetails.collaterals = collaterals;
        onTokenDetails.collateralsAmounts = collateralsAmounts;
        onTokenDetails.collateralsValues = collateralsValues;
        onTokenDetails.collateralsDecimals = collateralsDecimals;
        onTokenDetails.underlying = underlying;
        onTokenDetails.strikeAsset = strikeAsset;
        onTokenDetails.strikePrice = strikePrice;
        onTokenDetails.expiry = expiry;
        onTokenDetails.isPut = isPut;
        onTokenDetails.collaterizedTotalAmount = collaterizedTotalAmount;

        return onTokenDetails;
    }

    /**
     * @dev return ratio which represends how much of already used collateral will be used after burn
     * @param _vault the vault to use
     * @param _shortBurnAmount amount of shorts to burn
     */
    function getAfterBurnCollateralRatio(MarginVault.Vault memory _vault, uint256 _shortBurnAmount)
        external
        view
        returns (FPI.FixedPointInt memory, uint256)
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        return _getAfterBurnCollateralRatio(vaultDetails, _shortBurnAmount);
    }

    function _getAfterBurnCollateralRatio(VaultDetails memory _vaultDetails, uint256 _shortBurnAmount)
        internal
        view
        returns (FPI.FixedPointInt memory, uint256)
    {
        uint256 newShortAmount = _vaultDetails.shortAmount.sub(_shortBurnAmount);

        (FPI.FixedPointInt memory prevValueRequired, ) = _getValueRequired(
            _vaultDetails,
            _vaultDetails.shortAmount,
            _vaultDetails.longAmount
        );

        (FPI.FixedPointInt memory newValueRequired, FPI.FixedPointInt memory newToUseLongAmount) = _getValueRequired(
            _vaultDetails,
            newShortAmount,
            _vaultDetails.longAmount
        );

        return (
            prevValueRequired.isEqual(ZERO) ? ZERO : newValueRequired.div(prevValueRequired),
            newToUseLongAmount.toScaledUint(BASE, true)
        );
    }

    /**
     * @notice calculates maximal short amount can be minted for collateral and long in a given vault
     * @param _vault the vault to check
     */
    function getMaxShortAmount(MarginVault.Vault memory _vault) external view returns (uint256) {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);
        uint256 unusedLongAmount = vaultDetails.longAmount.sub(vaultDetails.usedLongAmount);
        uint256 one = 10**BASE;
        (FPI.FixedPointInt memory valueRequiredRate, ) = _getValueRequired(vaultDetails, one, unusedLongAmount);

        (, , FPI.FixedPointInt memory availableCollateralTotalValue) = _calculateVaultAvailableCollateralsValues(
            vaultDetails
        );
        return availableCollateralTotalValue.div(valueRequiredRate).toScaledUint(BASE, true);
    }

    /**
     * @notice calculates collateral required to mint amount of onToken for a given vault
     * @param _vault the vault to check
     * @param _shortAmount amount of short onToken to be covered by collateral
     */
    function getCollateralsToCoverShort(MarginVault.Vault memory _vault, uint256 _shortAmount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        return _getCollateralsToCoverShort(vaultDetails, _shortAmount);
    }

    /**
     * @notice calculates how much value of collaterals denominated in strike asset
     * required to mint short amount with for provided vault and long amounts available
     * @param _vaultDetails details of the vault to calculate for
     * @param _shortAmount short onToken amount to be covered
     * @param _longAmount long onToken amount that can be used to cover short
     */
    function _getValueRequired(
        VaultDetails memory _vaultDetails,
        uint256 _shortAmount,
        uint256 _longAmount
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        bool isPut = _vaultDetails.isPut;
        (FPI.FixedPointInt memory valueRequired, FPI.FixedPointInt memory toUseLongAmount) = isPut
            ? _getPutSpreadMarginRequired(
                _shortAmount,
                _longAmount,
                _vaultDetails.shortStrikePrice,
                _vaultDetails.longStrikePrice
            )
            : _getCallSpreadMarginRequired(
                _shortAmount,
                _longAmount,
                _vaultDetails.shortStrikePrice,
                _vaultDetails.longStrikePrice
            );

        // Convert value to strike asset for calls
        valueRequired = isPut
            ? valueRequired
            : _convertAmountOnLivePrice(valueRequired, _vaultDetails.underlyingAsset, _vaultDetails.strikeAsset);
        return (valueRequired, toUseLongAmount);
    }

    /**
     * @notice calculates collateral amounts, values required and used (including long)
     * required to mint amount of onToken for a given vault
     * @param _vaultDetails details of the vault to calculate for
     * @param _shortAmount short onToken amount to be covered
     * @return collateralsAmountsRequired collaterals amounts required to be available in vault to cover short amount
     * @return collateralsValuesRequired collaterals values (in strike asset) required to be available in vault to cover short amount
     * @return collateralsAmountsUsed collaterals amounts used in vault to cover short amount, combining  collateralsAmountsRequired and collaterals amounts used from long
     * @return collateralsValuesUsed  collaterals values (in strike asset) used to cover short amount, combining  collateralsValuesRequired and collaterals values used from long
     */
    function _getCollateralsToCoverShort(VaultDetails memory _vaultDetails, uint256 _shortAmount)
        internal
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        require(_shortAmount > 0, "amount must be greater than 0");

        uint256 unusedLongAmount = _vaultDetails.longAmount.sub(_vaultDetails.usedLongAmount);
        (FPI.FixedPointInt memory valueRequired, FPI.FixedPointInt memory toUseLongAmount) = _getValueRequired(
            _vaultDetails,
            _shortAmount,
            unusedLongAmount
        );

        (
            uint256[] memory collateralsAmountsRequired,
            ,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed
        ) = _getCollateralsToCoverValue(_vaultDetails, valueRequired, toUseLongAmount);

        return (
            collateralsAmountsRequired,
            collateralsAmountsUsed,
            collateralsValuesUsed,
            toUseLongAmount.toScaledUint(BASE, true)
        );
    }

    /**
     * @notice calculates vault's deposited collateral amounts and values
     * required to cover provided value (denominated in strike asset) for a given vault
     * @param _vaultDetails details of the vault to calculate for
     * @param _valueRequired value required to cover, denominated in strike asset
     * @param _toUseLongAmount long amounts that can be used to fully or partly cover the value
     * @return collateralsAmountsRequired collaterals amounts required to be available in vault to cover value required
     * @return collateralsValuesRequired collaterals values (in strike asset) required to be available in vault to cover value required
     * @return collateralsAmountsUsed collaterals amounts used in vault to cover value required, combining  collateralsAmountsRequired and collaterals amounts used from long
     * @return collateralsValuesUsed  collaterals values (in strike asset) used to cover value required, combining  collateralsValuesRequired and collaterals values used from long
     */
    function _getCollateralsToCoverValue(
        VaultDetails memory _vaultDetails,
        FPI.FixedPointInt memory _valueRequired,
        FPI.FixedPointInt memory _toUseLongAmount
    )
        internal
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        // Create "higher" variable in stack same as function argument to prevent stack too deep error
        // when accessing _valueRequired, same for _vaultDetails.collateralsDecimals
        FPI.FixedPointInt memory valueRequired = _valueRequired;

        uint256[] memory collateralsDecimals = _vaultDetails.collateralsDecimals;
        // availableCollateralsValues is how much worth each available collateral in strike asset
        // availableCollateralTotalValue - how much value totally available in vault in strike asset
        (
            FPI.FixedPointInt[] memory availableCollateralsAmounts,
            FPI.FixedPointInt[] memory availableCollateralsValues,
            FPI.FixedPointInt memory availableCollateralTotalValue
        ) = _calculateVaultAvailableCollateralsValues(_vaultDetails);
        require(
            availableCollateralTotalValue.isGreaterThanOrEqual(valueRequired),
            "Vault value is not enough to collaterize the amount"
        );

        uint256 collateralsLength = _vaultDetails.collateralAssets.length;

        // collateralsAmountsUsed - is amounts of each collateral
        // used to cover short, including collateral from long
        uint256[] memory collateralsAmountsUsed = new uint256[](collateralsLength);
        // collateralsValuesUsed - is value (in strike asset)
        // of each collateral used to cover short, including collateral from long
        uint256[] memory collateralsValuesUsed = new uint256[](collateralsLength);
        if (_vaultDetails.longONtoken != address(0)) {
            (collateralsAmountsUsed, collateralsValuesUsed) = _calculateONtokenCollaterizationsOfAmount(
                _vaultDetails.longONtoken,
                _toUseLongAmount
            );
        }

        // collateralsAmountsRequired - is amounts of each collateral
        // used to cover short which will be taken from vaults deposited collateral
        uint256[] memory collateralsAmountsRequired = new uint256[](collateralsLength);
        // collateralsValuesRequired - is values (in strike asset)
        // of each collateral used to cover short which will be taken from vaults deposited collateral
        uint256[] memory collateralsValuesRequired = new uint256[](collateralsLength);

        // collaterizationRatio reporesents how much of vaults deposited collateral will be locked for covering short
        FPI.FixedPointInt memory collaterizationRatio = valueRequired.isGreaterThan(ZERO)
            ? valueRequired.div(availableCollateralTotalValue)
            : ZERO;

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (availableCollateralsValues[i].isGreaterThan(ZERO)) {
                collateralsValuesRequired[i] = availableCollateralsValues[i].mul(collaterizationRatio).toScaledUint(
                    BASE,
                    true
                );
                collateralsAmountsRequired[i] = availableCollateralsAmounts[i].mul(collaterizationRatio).toScaledUint(
                    collateralsDecimals[i],
                    true
                );
            }
            collateralsAmountsUsed[i] = collateralsAmountsUsed[i].add(collateralsAmountsRequired[i]);
            collateralsValuesUsed[i] = collateralsValuesUsed[i].add(collateralsValuesRequired[i]);
        }

        return (collateralsAmountsRequired, collateralsValuesRequired, collateralsAmountsUsed, collateralsValuesUsed);
    }

    /**
     * @notice calculates vault's available collateral amounts value and total value of all collateral
     * not including value and amounts from vault's long, values are denominated in strike asset
     * @param _vaultDetails details of the vault to calculate for
     * @return availableCollateralsAmounts - amounts of collaterals available in vault
     * @return availableCollateralsValues - how much worth available vaults collateral in strike asset
     * @return availableCollateralTotalValue - how much value totally available in vault in valueAsset
     */
    function _calculateVaultAvailableCollateralsValues(VaultDetails memory _vaultDetails)
        internal
        view
        returns (
            FPI.FixedPointInt[] memory,
            FPI.FixedPointInt[] memory,
            FPI.FixedPointInt memory
        )
    {
        address _strikeAsset = _vaultDetails.strikeAsset;
        address[] memory _collateralAssets = _vaultDetails.collateralAssets;
        uint256[] memory _unusedCollateralAmounts = _vaultDetails.availableCollateralAmounts;
        uint256[] memory _collateralsDecimals = _vaultDetails.collateralsDecimals;

        uint256 collateralsLength = _collateralAssets.length;
        // then we need arrays to use short onToken collateral constraints
        ONtokenInterface short = ONtokenInterface(_vaultDetails.shortONtoken);
        // collateral constraints - is absolute amounts of collateral that can be used to cover corresponding short
        // used to restrict high collaterization with risky assets
        uint256[] memory _shortCollateralConstraints = short.getCollateralConstraints();
        // _shortCollateralsAmounts - amounts of existing collaterization of onToken by every collateral
        uint256[] memory _shortCollateralsAmounts = short.getCollateralsAmounts();
        FPI.FixedPointInt[] memory availableCollateralsValues = new FPI.FixedPointInt[](collateralsLength);
        FPI.FixedPointInt memory availableCollateralTotalValue;

        FPI.FixedPointInt[] memory availableCollateralsAmounts = new FPI.FixedPointInt[](collateralsLength);

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (_unusedCollateralAmounts[i] == 0) {
                availableCollateralsValues[i] = ZERO;
                continue;
            }
            availableCollateralsAmounts[i] = FPI.fromScaledUint(_unusedCollateralAmounts[i], _collateralsDecimals[i]);

            // if this collateral token has constraint
            if (_shortCollateralConstraints[i] > 0) {
                FPI.FixedPointInt memory maxAmount = FPI.fromScaledUint(
                    _shortCollateralConstraints[i].sub(_shortCollateralsAmounts[i]),
                    _collateralsDecimals[i]
                );
                // take min from constraint or this collateral avaialable
                availableCollateralsAmounts[i] = FPI.min(maxAmount, availableCollateralsAmounts[i]);
            }

            // convert amounts to value in strike asset by current price
            availableCollateralsValues[i] = _convertAmountOnLivePrice(
                availableCollateralsAmounts[i],
                _collateralAssets[i],
                _strikeAsset
            );

            availableCollateralTotalValue = availableCollateralTotalValue.add(availableCollateralsValues[i]);
        }

        return (availableCollateralsAmounts, availableCollateralsValues, availableCollateralTotalValue);
    }

    /**
     * @dev returns the strike asset amount of margin required for a put or put spread with the given short onTokens, long onTokens and amounts
     *
     * marginRequired = max( (short amount * short strike) - (long strike * min (short amount, long amount)) , 0 )
     *
     * @return margin requirement denominated in the strike asset
     * @return long amount used to cover short
     */
    function _getPutSpreadMarginRequired(
        uint256 _shortAmount,
        uint256 _longAmount,
        uint256 _shortStrike,
        uint256 _longStrike
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        FPI.FixedPointInt memory shortStrikeFPI = FPI.fromScaledUint(_shortStrike, BASE);
        FPI.FixedPointInt memory longStrikeFPI = FPI.fromScaledUint(_longStrike, BASE);
        FPI.FixedPointInt memory shortAmountFPI = FPI.fromScaledUint(_shortAmount, BASE);
        FPI.FixedPointInt memory longAmountFPI = _longAmount != 0 ? FPI.fromScaledUint(_longAmount, BASE) : ZERO;

        FPI.FixedPointInt memory longAmountUsed = longStrikeFPI.isEqual(ZERO)
            ? ZERO
            : FPI.min(shortAmountFPI, longAmountFPI);

        return (
            FPI.max(shortAmountFPI.mul(shortStrikeFPI).sub(longStrikeFPI.mul(longAmountUsed)), ZERO),
            longAmountUsed
        );
    }

    /**
     * @dev returns the underlying asset amount required for a call or call spread with the given short onTokens, long onTokens, and amounts
     *
     *                           (long strike - short strike) * short amount
     * marginRequired =  max( ------------------------------------------------- , max (short amount - long amount, 0) )
     *                                           long strike
     *
     * @dev if long strike = 0, return max( short amount - long amount, 0)
     * @return margin requirement denominated in the underlying asset
     * @return long amount used to cover short
     */
    function _getCallSpreadMarginRequired(
        uint256 _shortAmount,
        uint256 _longAmount,
        uint256 _shortStrike,
        uint256 _longStrike
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        FPI.FixedPointInt memory shortStrikeFPI = FPI.fromScaledUint(_shortStrike, BASE);
        FPI.FixedPointInt memory longStrikeFPI = FPI.fromScaledUint(_longStrike, BASE);
        FPI.FixedPointInt memory shortAmountFPI = FPI.fromScaledUint(_shortAmount, BASE);
        FPI.FixedPointInt memory longAmountFPI = FPI.fromScaledUint(_longAmount, BASE);

        // max (short amount - long amount , 0)
        if (_longStrike == 0 || _longAmount == 0) {
            return (shortAmountFPI, ZERO);
        }

        /**
         *             (long strike - short strike) * short amount
         * calculate  ----------------------------------------------
         *                             long strike
         */
        FPI.FixedPointInt memory firstPart = longStrikeFPI.sub(shortStrikeFPI).mul(shortAmountFPI).div(longStrikeFPI);

        /**
         * calculate max ( short amount - long amount , 0)
         */
        FPI.FixedPointInt memory secondPart = FPI.max(shortAmountFPI.sub(longAmountFPI), ZERO);

        FPI.FixedPointInt memory longAmountUsed = longStrikeFPI.isEqual(ZERO)
            ? ZERO
            : FPI.min(shortAmountFPI, longAmountFPI);

        return (FPI.max(firstPart, secondPart), longAmountUsed);
    }

    /**
     * @dev calculates current onToken's amount collaterization with it's collaterals
     * @return collateralsAmountsUsed - is amounts of each collateral used to cover onToken
     * @return collateralsValuesUsed - is value (in strike asset) of each collateral used to cover onToken
     */
    function _calculateONtokenCollaterizationsOfAmount(address _onToken, FPI.FixedPointInt memory _amount)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ONTokenDetails memory onTokenDetails = ONTokenDetails(
            new address[](0), // [yvUSDC, cUSDC, ...etc]
            new uint256[](0), // [0, 200, ...etc]
            new uint256[](0), // [0, 200, ...etc]
            new uint256[](0), // [18, 8, 10]
            address(0), // WETH
            address(0), // USDC
            0,
            0,
            false,
            0
        );
        (
            onTokenDetails.collaterals, // yvUSDC
            onTokenDetails.collateralsAmounts,
            onTokenDetails.collateralsValues, // WETH // USDC
            onTokenDetails.collateralsDecimals,
            ,
            ,
            ,
            ,
            ,

        ) = _getONtokenDetails(_onToken);

        // Create "higher" variable in stack same as function argument to prevent stack too deep error when accessing amount
        FPI.FixedPointInt memory amount = _amount;
        uint256[] memory collateralsAmounts = new uint256[](onTokenDetails.collaterals.length);
        uint256[] memory collateralsValues = new uint256[](onTokenDetails.collaterals.length);

        if (amount.isEqual(ZERO)) {
            return (collateralsAmounts, collateralsValues);
        }

        FPI.FixedPointInt memory onTokenTotalCollateralValue = FPI.fromScaledUint(
            uint256ArraySum(onTokenDetails.collateralsValues),
            BASE
        );

        for (uint256 i = 0; i < onTokenDetails.collaterals.length; i++) {
            uint256 collateralDecimals = onTokenDetails.collateralsDecimals[i];
            FPI.FixedPointInt memory collateralValue = FPI.fromScaledUint(onTokenDetails.collateralsValues[i], BASE);
            FPI.FixedPointInt memory collateralRatio = collateralValue.div(onTokenTotalCollateralValue);

            collateralsAmounts[i] = amount
                .mul(FPI.fromScaledUint(onTokenDetails.collateralsAmounts[i], collateralDecimals))
                .mul(collateralRatio)
                .toScaledUint(collateralDecimals, true);

            collateralsValues[i] = collateralValue.mul(collateralRatio).toScaledUint(BASE, true);
        }

        return (collateralsAmounts, collateralsValues);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ONtokenInterface {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnONtoken(address account, uint256 amount) external;

    function reduceCollaterization(
        uint256[] calldata collateralsAmountsForReduce,
        uint256[] calldata collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external;

    function getCollateralAssets() external view returns (address[] memory);

    function getCollateralsAmounts() external view returns (uint256[] memory);

    function getCollateralConstraints() external view returns (uint256[] memory);

    function collateralsValues(uint256) external view returns (uint256);

    function getCollateralsValues() external view returns (uint256[] memory);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function collaterizedTotalAmount() external view returns (uint256);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function expiryTimestamp() external view returns (uint256);

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external;

    function isPut() external view returns (bool);

    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] memory collateralsAmountsForMint,
        uint256[] memory collateralsValuesForMint
    ) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function strikeAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * Utils library for comparing arrays of addresses
 */
library ArrayAddressUtils {
    /**
     * @dev uses hashes of array to compare, therefore arrays with different order of same elements wont be equal
     * @param arr1 address[]
     * @param arr2 address[]
     * @return bool
     */
    function isEqual(address[] memory arr1, address[] memory arr2) external pure returns (bool) {
        return keccak256(abi.encodePacked(arr1)) == keccak256(abi.encodePacked(arr2));
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