// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Funding } from "Funding.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Synthetic } from "Synthetic.sol";
import { Token } from "Token.sol";
import { Trade } from "Trade.sol";
import { Transfer } from "Transfer.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Exchange
 *  @notice Contract for Paradex Derivatives Exchange
 *  @dev All integers are using `uint` until we get more information regarding the decimals
 *  we will need for these fields, also taking into account the addional decimals that
 *  we need due to the lack of floating point numbers.
 */
contract Exchange is Trade, Transfer {
    constructor(Types.DexAccounts memory _dexAccounts) {
        Storage.dexAccounts = _dexAccounts;
    }

    /**
     *  @notice Transfers tokens from a user to the Exchange
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to deposit
     */
    function deposit(address tokenAddress, uint amount) external {
        Transfer._deposit(msg.sender, tokenAddress, amount);
    }

    /**
     *  @notice Transfer amount from the Exchange to a user
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to withdraw
     */
    function withdraw(address tokenAddress, uint amount) external {
        Transfer._withdraw(msg.sender, tokenAddress, amount);
    }

    /**
     *  @notice Creates a new synthetic asset representation within the Exchange
     *  @param newAsset Details of the synthetic asset representation
     */
    function createSyntheticAsset(Types.SyntheticAsset calldata newAsset) external {
        Synthetic._createAsset(newAsset);
    }

    /**
     *  @notice Gets the synthetic asset representation for a market
     *  @param market ID of the synethetic asset
     */
    function getSyntheticAsset(
        string calldata market
    ) external view returns(Types.SyntheticAsset memory) {
        return Synthetic._getAsset(market);
    }

    /**
     *  @notice Gets the synthetic asset balance for a user account
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function getSyntheticAssetBalance(
        address account, string calldata market
    ) external view returns(Types.SyntheticAssetBalance memory) {
        return Synthetic._getAssetBalance(account, market);
    }

    /**
     *  @notice Creates a new token asset representation within the Exchange
     *  @param newAsset Details of the token asset representation
     */
    function createTokenAsset(Types.TokenAsset calldata newAsset) external {
        Token._createAsset(newAsset);
    }

    /**
     *  @notice Gets token asset representation for a address
     *  @param tokenAddress Address of the token asset contract
     */
    function getTokenAsset(address tokenAddress) external view returns(Types.TokenAsset memory) {
        return Token._getAsset(tokenAddress);
    }

    /**
     *  @notice Gets token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function getTokenAssetBalance(
        address account, address tokenAddress
    ) external view returns(Math.Number memory) {
        return Token._getAssetBalance(account, tokenAddress);
    }

    /**
     *  @notice Settles the trade and updates synthetic asset balance
     *  @param trade Trade request containing matching maker/taker orders
     */
    function settleTrade(Types.TradeRequest calldata trade) external {
        Trade._settle(trade);
    }

    /**
     *  @notice Returns total funding accrued on the Exchange contract
     */
    function getFunding() public view returns(Math.Number memory, Math.Number memory) {
        return Funding._getFunding();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Funding
 *  @notice Keeps track of all funding paid and received across the Exchange
 */
contract Funding {
    Math.Number fundingPaid;
    Math.Number fundingReceived;

    /**
     *  @notice Increments funding paid
     *  @param change Amount to increment "funding paid" by
     */
    function _incrementFundingPaid(Math.Number memory change) internal {
        fundingPaid = Math.add(fundingPaid, change);
    }

    /**
     *  @notice Increments funding recieved
     *  @param change Amount to increment "funding recieved" by
     */
    function _incrementFundingReceived(Math.Number memory change) internal {
        fundingReceived = Math.add(fundingReceived, change);
    }

    /**
     *  @notice Returns total funding accrued on the Exchange
     */
    function _getFunding() internal view returns(Math.Number memory, Math.Number memory) {
        return (fundingPaid, fundingReceived);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Decimals } from "Decimals.sol";
import { SafeMath } from "SafeMath.sol";

/**
 *  @author Paradex
 *  @title Math
 *  @notice Library for unsigned Math
 */
library Math {
    using SafeMath for uint;

    struct Number {
        uint value;
        bool sign; // true = positive, false = negative
    }

    struct Float {
        uint value;
        uint8 decimals;
    }

    /**
     *  @notice Creates a signed number for this library
     *  @param value Unsigned value of the created number
     *  @param sign Flag to denote if the number is positive or negative
     */
    function create(uint value, bool sign) internal pure returns (Number memory) {
        return Number({ value: value, sign: sign });
    }

    /**
     *  @notice Creates a positive number for this library
     *  @param value Unsigned value of the created number
     */
    function create(uint value) internal pure returns (Number memory) {
        return Number({ value: value, sign: true });
    }

    /**
     *  @notice Creates a float representation for this library
     *  @param value Unsigned value of the created float
     */
    function createFloat(uint value) internal pure returns (Float memory) {
        return Float({ value: value, decimals: Decimals.INTERNAL_DECIMALS });
    }

    /**
     *  @notice Creates a number with zero value for this library
     */
    function zero() internal pure returns (Number memory) {
        return Number({ value: 0, sign: true });
    }

    /**
     *  @notice Adds two signed integers
     *  @param a Unsigned integer
     *  @param b Unsigned integer
     */
    function add(uint a, uint b) internal pure returns (uint) {
        return SafeMath.add(a, b);
    }

    /**
     *  @notice Adds two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function add(Number memory a, Number memory b) internal pure returns (Number memory) {
        Number memory result = zero();

        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }

        return result;
    }

    /**
     *  @notice Adds two numbers
     *  @param a Float number
     *  @param b Float number
     */
    function add(Float memory a, Float memory b) internal pure returns (Float memory) {
        Float memory result;
        if (a.decimals == b.decimals) {
            result.decimals = a.decimals;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.decimals < b.decimals) {
                uint8 decimalsDiff = b.decimals - a.decimals;
                uint aValue = a.value * (10 ** decimalsDiff);
                result.value = SafeMath.add(aValue, b.value);
                result.decimals = b.decimals;
            } else {
                uint8 decimalsDiff = a.decimals - b.decimals;
                uint bValue = b.value * (10 ** decimalsDiff);
                result.value = SafeMath.add(a.value, bValue);
                result.decimals = a.decimals;
            }
        }

        return result;
    }

    /**
     *  @notice Subtracts two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function sub(Number memory a, Number memory b) internal pure returns (Number memory) {
        Number memory result = zero();

        if (a.sign == b.sign) {
            if (a.value >= b.value) {
                result.value = SafeMath.sub(a.value, b.value);
                result.sign = a.sign;
            } else {
                result.value = SafeMath.sub(b.value, a.value);
                result.sign = !b.sign;
            }
        } else {
            result.value = SafeMath.add(a.value, b.value);
            result.sign = a.sign ? a.sign : !b.sign;
        }

        return result;
    }

    /**
     *  @notice Adds two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function sub(Float memory a, Float memory b) internal pure returns (Float memory) {
        require(a.decimals <= b.decimals, "Math: Float subtraction cannot be negative");

        Float memory result;

        if (a.decimals == b.decimals) {
            require(a.value >= b.value, "Math: Float subtraction cannot be negative");
            result.decimals = a.decimals;
            result.value = SafeMath.sub(a.value, b.value);
        } else if (a.decimals < b.decimals) {
            uint8 decimalsDiff = b.decimals - a.decimals;
            uint aValue = a.value * (10 ** decimalsDiff);
            require(aValue >= b.value, "Math: Float subtraction cannot be negative");
            result.value = SafeMath.sub(aValue, b.value);
            result.decimals = b.decimals;
        }

        // Reset decimals if value is zero
        if (result.value == 0) result.decimals = 0;

        return result;
    }

    /**
     *  @notice Divides two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function div(Number memory a, Number memory b) internal pure returns (Number memory) {
        Number memory result = zero();

        // TODO: Remove rounding decimals due to int conversion
        result.value = SafeMath.div(a.value, b.value);

        if (a.sign == b.sign) {
            result.sign = a.sign ? a.sign : !a.sign;
        } else {
            result.sign = a.sign && b.sign;
        }

        return result;
    }

    /**
     *  @notice Divides two numbers
     *  @param a Unsigned number
     *  @param b Float number
     */
    function div(uint a, Float memory b) internal pure returns (uint) {
        require(b.value != 0, "Math: Float division cannot be zero");

        // TODO: Remove rounding decimals due to int conversion
        uint result = SafeMath.mul(
            SafeMath.div(a, b.value),
            (10 ** b.decimals)
        );

        return result;
    }

    /**
     *  @notice Multiplies two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function _mul(Number memory a, Number memory b) internal pure returns (Number memory) {
        Number memory result = zero();

        result.value = SafeMath.mul(a.value, b.value);
        if (a.sign == b.sign) {
            result.sign = a.sign ? a.sign : !a.sign;
        } else {
            result.sign = a.sign && b.sign;
        }

        return result;
    }

    /**
     *  @notice Multiplies two numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function mul(Number memory a, Number memory b) internal pure returns (Number memory) {
        return _mul(a, b);
    }

    /**
     *  @notice Multiplies one signed number and one unsigned number
     *  @param a Signed number
     *  @param multiplier Unsigned multiplier for the value
     */
    function mul(Number memory a, uint multiplier) internal pure returns (Number memory) {
        return create(SafeMath.mul(a.value, multiplier), a.sign);
    }

    /**
     *  @notice Multiplies one float number and one unsigned number
     *  @param a Unsigned integer
     *  @param b Float number
     */
    function mul(uint a, Float memory b) internal pure returns (uint) {
        uint value = SafeMath.mul(a, b.value);
        value = SafeMath.div(value, (10 ** b.decimals));
        return value;
    }

    /**
     *  @notice Multiplies one float number and one unsigned number
     *  @param a Signed number
     *  @param b Float number
     */
    function mul(Number memory a, Float memory b) internal pure returns (Number memory) {
        uint value = SafeMath.mul(a.value, b.value);
        value = SafeMath.div(value, (10 ** b.decimals));
        return Number({ value: value, sign: a.sign });
    }

    /**
     *  @notice Multiplies one float number and one unsigned number
     *  @param a Float number
     *  @param multiplier Unsigned multiplier for the value
     */
    function mul(Float memory a, uint multiplier) internal pure returns (Float memory) {
        return Float({ value: SafeMath.mul(a.value, multiplier), decimals: a.decimals });
    }

    /**
     *  @notice Multiplies one float number and one unsigned number
     *  @param a Float number
     *  @param b Float number
     */
    function mul(Float memory a, Float memory b) internal pure returns (Float memory) {
        return Float({
            value: SafeMath.mul(a.value, b.value),
            decimals: a.decimals + b.decimals
        });
    }

    /**
     *  @notice Gets absolute value of a number
     *  @param num Signed number
     */
    function abs(Number memory num) internal pure returns (Number memory) {
        return create(num.value);
    }

    /**
     *  @notice Gets max number between two signed numbers
     *  @param a Signed number
     *  @param b Signed number
     */
    function max(Number memory a, Number memory b) internal pure returns (Number memory) {
        Number memory result = zero();

        if (a.sign == b.sign) {
            result = a.value >= b.value ? a : b;
        } else {
            if (a.sign) result = a;
            if (b.sign) result = b;
        }

        return result;
    }

    /**
     *  @notice Gets max number between two signed numbers
     *  @param a Unsigned integer
     *  @param b Unsigned integer
     */
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     *  @notice Gets max number between floats
     *  @param a Float number
     *  @param b Float number
     */
    function max(Float memory a, Float memory b) internal pure returns (Float memory) {
        if (a.decimals == b.decimals) {
            return a.value >= b.value ? a : b;
        } else {
            if (a.decimals < b.decimals) {
                uint8 decimalsDiff = b.decimals - a.decimals;
                uint aValue = a.value * (10 ** decimalsDiff);
                return aValue >= b.value ? a : b;
            } else {
                uint8 decimalsDiff = a.decimals - b.decimals;
                uint bValue = b.value * (10 ** decimalsDiff);
                return a.value >= bValue ? a : b;
            }
        }
    }

    /**
     *  @notice Calculates square root of a given number
     *  @param x Signed number
     */
    function sqrt(Number memory x) internal pure returns (Number memory) {
        if (x.value == 0) return x;
        Number memory result = create(x.value, x.sign);

        uint z = (x.value + 1) / 2;
        while (z < result.value) {
            result.value = z;
            z = (x.value / z + z) / 2;
        }

        return result;
    }

    /**
     *  @notice Calculates x percentage of y, parts per z
     *  @param x Percentage
     *  @param y Signed number
     *  @param z Parts per
     */
    function pct(uint x, Number memory y, uint z) internal pure returns (Number memory) {
        if (x == 0) return Math.zero();

        return Math.div(
            Math.mul(create(x), y),
            Math.create(z)
        );
    }

    /**
     *  @notice Calculates x percentage of y, parts per hundred
     *  @param x Percentage
     *  @param y Signed number
     */
    function pct(uint x, Number memory y) internal pure returns (Number memory) {
        // default: parts per hundred
        return pct(x, y, 100);
    }

    /**
     *  @notice Checks if given number is positive
     *  @param num Signed number
     */
    function isPositive(Number memory num) internal pure returns (bool) {
        return num.sign && num.value > 0;
    }

    /**
     *  @notice Checks if float number is less than another
     *  @param a Float number
     *  @param b Float number
     */
    function isLessThan(Float memory a, Float memory b) internal pure returns (bool) {
        if (a.decimals == b.decimals) {
            return a.value < b.value;
        }
        else {
            if (a.decimals < b.decimals) {
                uint8 decimalsDiff = b.decimals - a.decimals;
                uint aValue = a.value * (10 ** decimalsDiff);
                return aValue < b.value;
            } else {
                uint8 decimalsDiff = a.decimals - b.decimals;
                uint bValue = b.value * (10 ** decimalsDiff);
                return a.value < bValue;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/**
 *  @author Paradex
 *  @title Decimals
 *  @notice Library for conversion decimals
 */
library Decimals {
    uint8 constant INTERNAL_DECIMALS = 8;
    uint constant INTERNAL_DECIMALS_POWER = 1e8;

    /**
     *  @notice Converts decimals of given amount
     *  @param value Value of the integer
     *  @param from Convert from decimals (input decimals)
     *  @param to Convert to decimals (output decimals)
     */
    function convert(uint value, uint8 from, uint8 to) internal pure returns (uint) {
        uint convertedValue;
        if (from == to) {
            convertedValue = value;
        } else if (from > to) {
            convertedValue = value / (10 ** (from - to));
        } else {
            convertedValue = value * (10 ** (to - from));
        }
        return convertedValue;
    }

    /**
     *  @notice Converts to internal decimals representation
     *  @dev Converts from `decimals` to `INTERNAL_DECIMALS`
     *  @param value Value of the integer
     *  @param decimals Convert from decimals
     */
    function convertToInternal(uint value, uint8 decimals) internal pure returns (uint) {
        return convert(value, decimals, INTERNAL_DECIMALS);
    }

    /**
     *  @notice Converts from internal decimals representation
     *  @dev Converts from `INTERNAL_DECIMALS` to `decimals`
     *  @param value Value of the integer
     *  @param decimals Convert to decimals
     */
    function convertFromInternal(uint value, uint8 decimals) internal pure returns (uint) {
        return convert(value, INTERNAL_DECIMALS, decimals);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Storage
 *  @notice Storage for all the accounts, token & synthetic assets
 *  @dev Verify at execution time whether it is cheaper to have a single AssetBalances
 *  mappings list for each user with a fat struct or two mappings with more lean structs.
 */
contract Storage {
    Types.DexAccounts dexAccounts;

    // mapping(tokenAddress => TokenAsset)
    mapping(address => Types.TokenAsset) tokenAssets;
    // mapping(account => mapping(tokenAddress => ArrIndex))
    mapping(address => mapping(address => Types.ArrIndex)) tokenAssetBalanceIndex;
    // mapping(account => TokenAssetBalance[])
    mapping(address => Types.TokenAssetBalance[]) tokenAssetBalances;

    // mapping(market => SyntheticAsset)
    mapping(string => Types.SyntheticAsset) syntheticAssets;
    // mapping(account => mapping(market => ArrIndex))
    mapping(address => mapping(string => Types.ArrIndex)) syntheticAssetBalanceIndex;
    // mapping(account => SyntheticAssetBalance[])
    mapping(address => Types.SyntheticAssetBalance[]) syntheticAssetBalances;

    // TODO: Partially Filled Orders
    // We need a way to keep track of partially executed orders
    // Also how do we handle cleaning this up,
    // else it will just keep growing as orders are filled/canceled.
    // mapping(address => Types.PartiallyFilledOrder[]) partiallyFilledOrders;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Types
 */
contract Types {
    ///// Accounts /////

    struct DexAccounts {
        address feeAccount;
    }

    ///// Token Asset /////

    struct TokenAsset {
        uint initialWeight;
        uint maintenanceWeight;
        uint conversionWeight;
        uint tickSize;
        address tokenAddress; // Uniquely identifies all token assets
        address priceOracleAddress;
    }

    // Created on deposit, deleted on full withdrawal, updated on deposit/withdral/trade
    struct TokenAssetBalance {
        address tokenAddress;
        Math.Number amount;
    }

    ///// Synthetic Asset /////

    struct SyntheticAsset {
        uint tickSize;
        string market; // Uniquely identifies all synthetic assets.
        string baseAsset;
        string quoteAsset;
        address settlementAsset;
        address priceOracleAddress;
        MarginParams marginParams;
    }

    struct SyntheticAssetBalance {
        string market;
        bool sign; // true = positive, false = negative
        uint cost; // entry notional
        Math.Float amount; // size
        Math.Number cachedFunding;
    }

    ///// Order /////

    enum OrderSide {
        Invalid,
        Buy,
        Sell
    }

    enum OrderType {
        Invalid,
        Limit,
        Market
    }

    struct Order {
        address account;
        string market;
        Types.OrderSide side;
        Types.OrderType orderType;
        uint size;
        uint price;
        bytes signature;
    }

    struct PartiallyFilledOrder {
        string signature;
        uint remainingSize;
    }

    ///// Trade /////

    struct TradeRequest {
        uint id;
        uint marketPrice;
        uint matchPrice;
        uint matchSize;
        Order makerOrder;
        Order takerOrder;
    }

    ///// Margin /////

    enum MarginCheckType {
        Invalid,
        Initial,
        Maintenance,
        Conversion,
        NoRequirement
    }

    struct MarginParams {
        Math.Float imfBase;    // Initial Margin Fraction - Base
        Math.Float imfFactor;  // Initial Margin Fraction - Factor
        Math.Float mmfFactor;  // Maintenance Margin Fraction - Factor
        uint imfShift;         // Initial Margin Fraction - Shift
    }

    ///// Funding /////

    enum Direction {
        Negative,
        Positive
    }

    struct FundingIndex {
        uint index;
        Direction direction;
    }

    ///// Miscellaneous /////

    // Used to map array index to item
    struct ArrIndex {
        uint index;
        bool exists;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Codec } from "Codec.sol";
import { Decimals } from "Decimals.sol";
import { Events } from "Events.sol";
import { Fees } from "Fees.sol";
import { IPriceOracle } from "IPriceOracle.sol";
import { ISyntheticPriceOracle } from "SyntheticPriceOracle.sol";
import { Math } from "Math.sol";
import { SafeMath } from "SafeMath.sol";
import { Storage } from "Storage.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Synthetic
 */
contract Synthetic is Fees, Storage, Token {
    /**
     *  @notice Check if a synthetic asset is supported
     *  @param market ID of the synethetic asset
     */
    function _isAssetSupported(string memory market) internal view returns(bool) {
        return Codec.hash(_getAsset(market).market) != Codec.hash("");
    }

    /**
     *  @notice Creates a new synthetic asset representation within the Exchange
     *  @param newAsset Details of the synthetic asset representation
     */
    function _createAsset(Types.SyntheticAsset calldata newAsset) internal {
        // Validate that there is no existing SyntheticAsset with the same tokeAddress by
        // comparing against an unset address.
        require(
            !_isAssetSupported(newAsset.market),
            "Synthetic: Can't create multiple assets with the same market"
        );
        Storage.syntheticAssets[newAsset.market] = newAsset;
    }

    /**
     *  @notice Gets the synthetic asset representation for a market
     *  @param market ID of the synethetic asset
     */
    function _getAsset(
        string memory market
    ) internal view returns (Types.SyntheticAsset memory) {
        return Storage.syntheticAssets[market];
    }

    /**
     *  @notice Gets funding from price oracle
     *  @param market ID of the synethetic asset
     */
    function _getAssetFundingFeed(string memory market) internal view returns (Math.Number memory) {
        ISyntheticPriceOracle oracleFeed = ISyntheticPriceOracle(_getAsset(market).priceOracleAddress);
        Math.Number memory funding = oracleFeed.getFunding();
        return funding;
    }

    /**
     *  @notice Gets latest price from price oracle
     *  @param market ID of the synethetic asset
     */
    function _getAssetPriceFeed(string memory market) internal view returns (Math.Number memory) {
        ISyntheticPriceOracle oracleFeed = ISyntheticPriceOracle(_getAsset(market).priceOracleAddress);
        IPriceOracle.PriceData memory priceData = oracleFeed.getLatestPrice();
        return Math.create(priceData.answer, priceData.sign);
    }

    function getAssetSettlementAsset(string memory market) internal view returns(address) {
        return _getAsset(market).settlementAsset;
    }

    /**
     *  @notice Gets the synthetic asset balance for a user account
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _getAssetBalance(
        address account,
        string calldata market
    ) internal view returns(Types.SyntheticAssetBalance memory) {
        Types.ArrIndex memory balanceIndex = Storage.syntheticAssetBalanceIndex[account][market];
        require(
            balanceIndex.exists == true,
            "Synthetic: Can't get balance that does not exist"
        );
        return Storage.syntheticAssetBalances[account][balanceIndex.index];
    }

    /**
     *  @notice Deletes the asset balance record if no balance
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _deleteAssetBalance(address account, string calldata market) internal {
        Types.ArrIndex memory balanceIndex = Storage.syntheticAssetBalanceIndex[account][market];
        require(
            balanceIndex.exists == true,
            "Synthetic: Can't delete balance that has not been initialized before"
        );
        require(
            Storage.syntheticAssetBalances[account][balanceIndex.index].amount.value == 0,
            "Synthetic: Can't delete balance that has a valid amount"
        );
        delete Storage.syntheticAssetBalances[account][balanceIndex.index];
        delete Storage.syntheticAssetBalanceIndex[account][market];
    }

    /**
     *  @notice Creates the asset balance index for mapping
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _createAssetBalanceIndex(
        address account,
        string memory market
    ) internal returns (Types.ArrIndex memory) {
        Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
        // Only if unset continue.
        require(
            !balanceIndex.exists,
            "Synthetic: Can't create multiple indexes of same market"
        );

        uint index = Storage.syntheticAssetBalances[account].length;
        Types.ArrIndex memory newBalanceIndex = Types.ArrIndex({
            index: index, exists: true
        });
        Storage.syntheticAssetBalanceIndex[account][market] = newBalanceIndex;

        return newBalanceIndex;
    }

    /**
     *  @notice Gets the asset balance index for mapping
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _getAssetBalanceIndex(
        address account,
        string memory market
    ) internal view returns (Types.ArrIndex memory) {
        return Storage.syntheticAssetBalanceIndex[account][market];
    }

    /**
     *  @notice Gets asset balance by index
     *  @param account Address of the user account
     *  @param index Index for mapping
     */
    function _getAssetBalanceByIndex(
        address account, uint index
    ) internal view returns (Types.SyntheticAssetBalance memory) {
        return Storage.syntheticAssetBalances[account][index];
    }

    /**
     *  @notice Calculates cost price from settlement asset oracle price
     *  @param market ID of the synethetic asset
     *  @param matchPrice Price at which the order's matched and are being traded at
     */
    function _getCostPrice(string memory market, uint matchPrice) internal view returns (uint) {
        Types.SyntheticAsset memory asset = _getAsset(market);
        Math.Number memory oraclePrice = Token._getOraclePriceByAsset(asset.settlementAsset);
        return Math.div(matchPrice, Math.createFloat(oraclePrice.value));
    }

    /**
     *  @notice Calculates funding to be applied
     *  @param assetBalance Balance of the synthetic asset
     *  @param currentFunding Current funding
     */
    function _calculateFunding(
        Types.SyntheticAssetBalance memory assetBalance,
        Math.Number memory currentFunding
    ) internal pure returns (Math.Number memory) {
        Math.Number memory funding = Math.sub(currentFunding, assetBalance.cachedFunding);

        // Convert to asset balance reprenstation
        uint fundingValue = Math.mul(
            Math.create(Decimals.INTERNAL_DECIMALS_POWER, assetBalance.sign),
            Math.mul(assetBalance.amount, Math.createFloat(funding.value)
        )).value;

        Math.Number memory balanceChange;
        if (funding.sign == true) {
            if (assetBalance.sign == true) {
                balanceChange = Math.create(fundingValue, false);
            } else {
                balanceChange = Math.create(fundingValue, true);
            }
        } else {
            if (assetBalance.sign == true) {
                balanceChange = Math.create(fundingValue, true);
            } else {
                balanceChange = Math.create(fundingValue, false);
            }
        }
        return balanceChange;
    }

    /**
     *  @notice Pushes new synthetic asset balance
     *  @param account Address of the user account
     *  @param updatedBalance Updated synthetic asset balance
     */
    function _updateAssetBalance(
        address account,
        Types.SyntheticAssetBalance memory updatedBalance
    ) internal {
        Storage.syntheticAssetBalances[account].push(updatedBalance);
    }

    /**
     *  @notice Updates synthetic asset balance at given index
     *  @param account Address of the user account
     *  @param balanceIndex Array index of the balance
     *  @param updatedBalance Updated synthetic asset balance
     */
    function _updateAssetBalance(
        address account,
        Types.ArrIndex memory balanceIndex,
        Types.SyntheticAssetBalance memory updatedBalance
    ) internal {
        Storage.syntheticAssetBalances[account][balanceIndex.index] = updatedBalance;
    }

    /**
     *  @notice Updates synthetic asset balance, calculate pnl and funding
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     *  @param orderSide Whether the user is BUY or SELL the asset
     *  @param matchSizeFloat Size which is being traded, it is not necesarily the same as the order's size
     *  @param matchPrice Price at which the order's matched and are being traded at
     */
    function _updateAssetBalance(
        address account,
        string memory market,
        Types.OrderSide orderSide,
        Math.Float memory matchSizeFloat,
        uint matchPrice
    ) internal returns (Types.SyntheticAssetBalance memory, Math.Number memory, Math.Number memory) {
        Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
        Math.Number memory currentFunding = _getAssetFundingFeed(market);

        Math.Number memory fundingBalance = Math.zero();
        Math.Number memory unrealizedPnl = Math.zero();

        uint costPrice = _getCostPrice(market, matchPrice);

        Types.SyntheticAssetBalance memory updatedBalance = Types.SyntheticAssetBalance({
            market: market,
            sign: orderSide == Types.OrderSide.Buy,
            cost: 0,
            amount: matchSizeFloat,
            cachedFunding: currentFunding
        });
        // Create balance
        if (balanceIndex.exists == false) {
            updatedBalance.cost = Math.mul(costPrice, matchSizeFloat);
            balanceIndex = _createAssetBalanceIndex(account, market);

            // Persist balance update
            _updateAssetBalance(account, updatedBalance);
        } else {
            Types.SyntheticAssetBalance memory previousBalance = _getAssetBalanceByIndex(
                account, balanceIndex.index
            );
            // Realize Funding
            fundingBalance = _calculateFunding(previousBalance, currentFunding);
            // Increase balance
            if (previousBalance.sign == updatedBalance.sign) {
                updatedBalance.amount = Math.add(previousBalance.amount, updatedBalance.amount);
                updatedBalance.cost = Math.add(
                    previousBalance.cost,
                    Math.mul(costPrice, matchSizeFloat)
                );
            } else {
                // Decrease balance
                if (Math.isLessThan(updatedBalance.amount, previousBalance.amount)) {
                    updatedBalance.sign = previousBalance.sign;
                    updatedBalance.amount = Math.sub(previousBalance.amount, updatedBalance.amount);
                    updatedBalance.cost = Math.mul(
                        previousBalance.cost,
                        Math.add(previousBalance.amount, matchSizeFloat)
                    );
                    updatedBalance.cost = Math.div(
                        updatedBalance.cost,
                        previousBalance.amount
                    );
                // Flip balance
                } else {
                    updatedBalance.amount = Math.sub(updatedBalance.amount, previousBalance.amount);
                    updatedBalance.cost = Math.mul(costPrice, updatedBalance.amount);
                }

                unrealizedPnl = _calculateUnrealizedPnl(
                    previousBalance,
                    updatedBalance,
                    matchSizeFloat,
                    matchPrice
                );
            }

            // Persist balance update
            _updateAssetBalance(account, balanceIndex, updatedBalance);
        }

        return (updatedBalance, fundingBalance, unrealizedPnl);
    }

    /**
     *  @notice Calculates the margin fraction for a margin check
     *  @param marginParams Details about the synthetic asset margin params
     *  @param abValue Absolute value of the synthetic asset balance
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _marginFraction(
        Types.MarginParams memory marginParams,
        Math.Number memory abValue,
        Types.MarginCheckType checkType
    ) pure internal returns (Math.Float memory) {
        Math.Number memory imfShiftMax = Math.sqrt(
            Math.max(
                Math.zero(),
                Math.sub(abValue, Math.create(marginParams.imfShift))
            )
        );
        Math.Float memory initialMarginFraction = Math.max(
            marginParams.imfBase,
            Math.mul(marginParams.imfFactor, imfShiftMax.value)
        );

        if (checkType == Types.MarginCheckType.Initial) {
            return initialMarginFraction;
        } else {
            return Math.mul(
                initialMarginFraction,
                marginParams.mmfFactor
            );
        }
    }

    /**
     *  @notice Calculates margin requirement
     *  @param assetBalance Balance of the synthetic asset
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _calculateMarginRequirement(
        Types.SyntheticAssetBalance memory assetBalance, Types.MarginCheckType checkType
    ) internal view returns (Math.Number memory) {
        if (checkType == Types.MarginCheckType.NoRequirement) {
            return Math.zero();
        }
        Types.SyntheticAsset memory asset = Storage.syntheticAssets[assetBalance.market];

        Math.Number memory oraclePrice = _getAssetPriceFeed(assetBalance.market);
        Math.Number memory absBalanceValue = Math.mul(oraclePrice, assetBalance.amount);

        Math.Float memory positionFraction;
        if (checkType == Types.MarginCheckType.Initial) {
            // Initial margin fraction
            positionFraction = _marginFraction(
                asset.marginParams, absBalanceValue, Types.MarginCheckType.Initial
            );
        } else {
            // Maintenance margin fraction
            positionFraction = _marginFraction(
                asset.marginParams, absBalanceValue, Types.MarginCheckType.Maintenance
            );
        }

        Math.Number memory positionMargin = Math.mul(absBalanceValue, positionFraction);

        Math.Number memory feeProvision = Fees._getFeePct(
            Math.max(Fees.MAKER_FEE, Fees.TAKER_FEE),
            absBalanceValue
        );

        Math.Number memory netMargin = Math.add(positionMargin, feeProvision);
        return netMargin;
    }

    /**
     *  @notice Gets margin requirement for all synthetic assets
     *  @param account Address of the user account
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _getTotalMarginRequirement(
        address account, Types.MarginCheckType checkType
    ) internal view returns (Math.Number memory) {
        Types.SyntheticAssetBalance[] memory balances = Storage.syntheticAssetBalances[account];
        Math.Number memory totalMargin = Math.zero();

        for (uint i = 0; i < balances.length; i++) {
            Math.Number memory margin = _calculateMarginRequirement(balances[i], checkType);
            totalMargin = Math.add(totalMargin, margin);
        }

        return totalMargin;
    }
   /**
     *  @notice Calculates realized PnL
     *  @param previousBalance Previous synthetic asset balance
     *  @param updatedBalance Updated synthetic asset balance
     *  @param matchSizeFloat Size of the matched orders in trade
     *  @param matchPrice Price of the matched orders in trade
     */
    function _calculateUnrealizedPnl(
        Types.SyntheticAssetBalance memory previousBalance,
        Types.SyntheticAssetBalance memory updatedBalance,
        Math.Float memory matchSizeFloat,
        uint matchPrice
    ) pure internal returns(Math.Number memory) {
        // -previous_cost
        Math.Number memory previousBalanceNegNum = Math.create(previousBalance.cost, false);

        // asset_balance.cost
        Math.Number memory updatedBalanceNum = Math.create(updatedBalance.cost,true);

        // -previous_asset_balance.cost + asset_balance.cost
        Math.Number memory balanceDiff = Math.sub(previousBalanceNegNum, updatedBalanceNum);

        // trade_amount * fill_price
        uint tradeAmount = Math.mul(matchPrice, matchSizeFloat);

        // unrealized_pnl = -previous_asset_balance.cost + asset_balance.cost - (trade_amount * fill_price)
        Math.Number memory unrealizedPnl = Math.sub(balanceDiff, Math.create(tradeAmount));

        return unrealizedPnl;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/**
 *  @author Paradex
 *  @title Codec
 *  @notice Library for hash functions
 */
library Codec {
    /**
     *  @notice Computes the Keccak-256 hash of the input
     *  @param txt Input that needs to hashed
     */
    function hash(string memory txt) internal pure returns (bytes32) {
        return keccak256(abi.encode(txt));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Types } from "Types.sol";
import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Events
 */
contract Events {
    event Deposit(address indexed account, address indexed tokenAddress, uint amount);
    event FundingAccrued(
        uint indexed tradeId, address indexed account, Math.Number amount, Math.Number fundingRate
    );
    event Withdraw(address indexed account, address indexed tokenAddress, uint amount);
    event SyntheticBalanceUpdate(
        uint indexed tradeId,
        address indexed account,
        string indexed market,
        bool sign,
        uint cost,
        Math.Float amount
    );

    /**
     *  @notice Emits deposit event with transfer details
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user has deposited
     */
    function _emitDeposit(address account, address tokenAddress, uint amount) internal {
        emit Deposit(account, tokenAddress, amount);
    }

    /**
     *  @notice Emits withdraw event with transfer details
     *  @param tradeId ID of the trade that caused the update.
     *  @param account Address of the user account.
     *  @param fundingAccrued Tuple of value and sign, with total funding amount accrued by the position.
     *  @param fundingRate Total funding accrued.
     */
    function _emitFundingAccrued(
        uint tradeId, address account, Math.Number memory fundingAccrued, Math.Number memory fundingRate
    ) internal {
        emit FundingAccrued(tradeId, account, fundingAccrued, fundingRate);
    }

    /**
     *  @notice Emits withdraw event with transfer details
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user has withdrawn
     */
    function _emitWithdraw(address account, address tokenAddress, uint amount) internal {
        emit Withdraw(account, tokenAddress, amount);
    }

    /**
     *  @notice Emits synthetic balance update event
     *  @param tradeId ID of the trade that caused the update
     *  @param account Address of the user account
     *  @param assetBalance Updated synthetic asset balance
     */
    function _emitSyntheticBalanceUpdate(
        uint tradeId,
        address account,
        Types.SyntheticAssetBalance memory assetBalance
    ) internal {
        emit SyntheticBalanceUpdate(
            tradeId,
            account,
            assetBalance.market,
            assetBalance.sign,
            assetBalance.cost,
            assetBalance.amount
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Fees
 */
contract Fees {
    // Default maker/taker fees
    uint constant MAKER_FEE = 1;  // 0.01%
    uint constant TAKER_FEE = 4;  // 0.04%

    // Default is 2 decimal places
    uint constant FEE_PARTS_PER = 10000;

    /**
     *  @notice Calculates fee percentage for a given value
     *  @param fee Fee is either MAKER_FEE or TAKER_FEE
     *  @param value Amount for which fee percentage is calculated
     */
    function _getFeePct(
        uint fee, Math.Number memory value
    ) internal pure returns (Math.Number memory) {
        return Math.pct(fee, value, FEE_PARTS_PER);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IPriceOracle {
    struct PriceDataInput {
        bool sign;
        uint answer;
        uint timestamp;
    }

    struct PriceData {
        uint80 roundId;
        bool sign;
        uint answer;
        uint timestamp;
    }

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint);

    // getLatestPrice should raise "no data present" if it do not
    // have data to report, instead of returning unset values which
    // could be misinterpreted as actual reported values.
    function getLatestPrice() external view returns (PriceData memory);

    function setLatestPrice(PriceDataInput memory _latestPrice) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IERC20 } from "IERC20.sol";
import { ISyntheticPriceOracle } from "ISyntheticPriceOracle.sol";
import { Math } from "Math.sol";
import { PriceOracle } from "PriceOracle.sol";

/**
 *  @author Paradex
 *  @title SyntheticPriceOracle
 */
contract SyntheticPriceOracle is PriceOracle, ISyntheticPriceOracle {
    Math.Number funding;

    constructor(uint8 _decimals, string memory _description)
        PriceOracle(_decimals, _description) {}

    /**
     *  @notice Retrieves the latest funding value
     */
    function getFunding() public view returns (Math.Number memory) {
        return funding;
    }

    /**
     *  @notice Saves the latest funding value
     *  @param _funding Funding value to be saved
     */
    function setFunding(Math.Number memory _funding) public onlyOwner {
        funding = _funding;
    }

    /**
     *  @notice Retrieves the latest oracle price and funding value
     */
    function getLatestPriceAndFunding() public view returns (
        PriceData memory, Math.Number memory
    ) {
        return (latestPriceData, funding);
    }

    /**
     *  @notice Saves the latest oracle price and funding value
     *  @param _latestPrice Latest price data input value
     *  @param _funding Funding value to be saved
     */
    function setLatestPriceAndFunding(
        PriceDataInput memory _latestPrice, Math.Number memory _funding
    ) external onlyOwner {
        PriceOracle.setLatestPrice(_latestPrice);
        setFunding(_funding);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IPriceOracle } from "IPriceOracle.sol";
import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title ISyntheticPriceOracle
 */
interface ISyntheticPriceOracle is IPriceOracle {
    function getFunding() external view returns (Math.Number memory);
    function setFunding(Math.Number memory _funding) external;
    function getLatestPriceAndFunding() external view returns (
        PriceData memory, Math.Number memory
    );
    function setLatestPriceAndFunding(
        PriceDataInput memory _latestPrice, Math.Number memory _funding
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IPriceOracle } from "IPriceOracle.sol";
import { Ownable } from "Ownable.sol";

/**
 *  @author Paradex
 *  @title PriceOracle
 */
contract PriceOracle is IPriceOracle, Ownable {
    uint8 public immutable decimals;
    string public description;
    uint public constant version = 1;

    PriceData latestPriceData;

    constructor(uint8 _decimals, string memory _description) {
        decimals = _decimals;
        description = _description;
    }

    /**
     *  @notice Retrieves the latest oracle price
     */
    function getLatestPrice() public view returns (PriceData memory) {
        require(latestPriceData.roundId > 0, "PriceOracle: No data present");
        return latestPriceData;
    }

    /**
     *  @notice Saves the latest oracle price
     *  @param _latestPrice Latest price data input value
     */
    function setLatestPrice(PriceDataInput memory _latestPrice) public onlyOwner {
        require(
            latestPriceData.timestamp < _latestPrice.timestamp,
            "PriceOracle: Current data has a more recent timestamp"
        );
        latestPriceData.roundId += 1;
        latestPriceData.sign = _latestPrice.sign;
        latestPriceData.answer = _latestPrice.answer;
        latestPriceData.timestamp = _latestPrice.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Decimals } from "Decimals.sol";
import { IERC20Metadata } from "IERC20Metadata.sol";
import { IPriceOracle } from "IPriceOracle.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Token
 */
contract Token is Storage {
    /**
     *  @notice Check if a token asset exists
     *  @param tokenAddress Address of the token asset contract
     */
    function _isExistingAsset(address tokenAddress) internal view returns (bool) {
        // Validate that there is an existing TokenAsset with the same tokeAddress
        return Storage.tokenAssets[tokenAddress].tokenAddress != address(0);
    }

    /**
     *  @notice Creates a new token asset representation within the Exchange
     *  @param newTokenAsset Details of the token asset representation
     */
    function _createAsset(Types.TokenAsset calldata newTokenAsset) internal {
        // Validate that there is no existing TokenAsset with the same tokeAddress by
        // comparing against an unset address.
        require(
            Storage.tokenAssets[newTokenAsset.tokenAddress].tokenAddress == address(0),
            "Token: Can't create multiple assets with the same token address"
        );

        Storage.tokenAssets[newTokenAsset.tokenAddress] = newTokenAsset;
    }

    /**
     *  @notice Gets token asset representation for a address
     *  @param tokenAddress Address of the token asset contract
     */
    function _getAsset(
        address tokenAddress
    ) internal view returns (Types.TokenAsset memory token) {
        return Storage.tokenAssets[tokenAddress];
    }

    /**
     *  @notice Creates token asset balance for a user
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount added to the user's balance
     */
    function _createAssetBalance(
        address account, address tokenAddress, Math.Number memory amount
    ) internal returns (Types.TokenAssetBalance memory) {
        require(
            Storage.tokenAssetBalanceIndex[account][tokenAddress].exists == false,
            "Token: Can't create multiple balances of same token address"
        );

        Types.TokenAssetBalance memory newBalance = Types.TokenAssetBalance({
            tokenAddress: tokenAddress,
            amount: amount
        });

        Storage.tokenAssetBalances[account].push(newBalance);
        uint index = Storage.tokenAssetBalances[account].length - 1;
        Types.ArrIndex memory newBalanceIndex = Types.ArrIndex({
            index: index, exists: true
        });
        Storage.tokenAssetBalanceIndex[account][tokenAddress] = newBalanceIndex;

        return Storage.tokenAssetBalances[account][index];
    }

    /**
     *  @notice Gets token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function _getAssetBalance(
        address account, address tokenAddress
    ) internal view returns (Math.Number memory) {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        require(
            balanceIndex.exists == true,
            "Token: Can't get balance that has not been initialized before"
        );

        Types.TokenAssetBalance memory currentBalance = Storage.tokenAssetBalances[account][balanceIndex.index];

        // Get decimals representation from token asset
        IERC20Metadata token = IERC20Metadata(currentBalance.tokenAddress);
        uint8 decimals = token.decimals();

        // Value with token asset decimals representation
        uint value = Decimals.convertFromInternal(currentBalance.amount.value, decimals);

        return Math.create(value, currentBalance.amount.sign);
    }

    /**
     *  @notice Updates token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param balanceChange Adds or removes specified balance change
     */
    function _updateAssetBalance(
        address account, address tokenAddress, Math.Number memory balanceChange
    )
        internal returns (Types.TokenAssetBalance memory) {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        Types.TokenAssetBalance memory newBalance;
        if (balanceIndex.exists == false) {
            newBalance = _createAssetBalance(account, tokenAddress, balanceChange);
        } else {
            Types.TokenAssetBalance memory currentBalance = Storage.tokenAssetBalances[account][balanceIndex.index];
            newBalance = Types.TokenAssetBalance({
                tokenAddress: tokenAddress,
                amount: Math.add(currentBalance.amount, balanceChange)
            });
        }

        Storage.tokenAssetBalances[account][balanceIndex.index] = newBalance;

        return newBalance;
    }

    /**
     *  @notice Transfers fee from user account to fee account
     *  @param from Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Fee amount transferred from balance
     */
    function _transferToFeeAccount(address from, address tokenAddress, uint amount) internal {
        // Decrease `from` account token balance
        Math.Number memory amountToDec = Math.Number({ value: amount, sign: false });
        _updateAssetBalance(from, tokenAddress, amountToDec);

        // Increase fee account token balance
        address feeAccount = Storage.dexAccounts.feeAccount;
        Math.Number memory amountToInc = Math.Number({ value: amount, sign: true });
        _updateAssetBalance(feeAccount, tokenAddress, amountToInc);
    }

    /**
     *  @notice Deletes token asset balance
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function _deleteAssetBalance(address account, address tokenAddress) internal {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        require(
            balanceIndex.exists == true,
            "Token: Can't delete balance that has not been initialized before"
        );
        require(
            Math.isPositive(tokenAssetBalances[account][balanceIndex.index].amount),
            "Token: Can't delete balance that has a valid amount"
        );
        delete Storage.tokenAssetBalances[account][balanceIndex.index];
        delete Storage.tokenAssetBalanceIndex[account][tokenAddress];
    }

    /**
     *  @notice Gets pracle price of a token asset
     *  @param priceOracleAddress Address of the price oracle
     */
    function _getOraclePriceByAddress(address priceOracleAddress) internal view returns (Math.Number memory) {
        IPriceOracle priceFeed = IPriceOracle(priceOracleAddress);
        IPriceOracle.PriceData memory oracleData = priceFeed.getLatestPrice();

        Math.Number memory oraclePrice = Math.Number({
            value: oracleData.answer,
            sign: oracleData.sign
        });

        return oraclePrice;
    }

    /**
     *  @notice Gets pracle price of a token asset
     *  @param tokenAddress Address of the token asset contract
     */
    function _getOraclePriceByAsset(address tokenAddress) internal view returns (Math.Number memory) {
        Types.TokenAsset memory asset = Storage.tokenAssets[tokenAddress];
        Math.Number memory oraclePrice = _getOraclePriceByAddress(asset.priceOracleAddress);
        return oraclePrice;
    }

    /**
     *  @notice Gets balance value for all token assets
     *  @param account Address of the user account
     */
    function _getAllAssetBalanceValue(address account) internal view returns (Math.Number memory) {
        Types.TokenAssetBalance[] memory balances = Storage.tokenAssetBalances[account];
        Math.Number memory totalValue = Math.zero();

        for (uint i = 0; i < balances.length; i++) {
            Types.TokenAsset memory asset = Storage.tokenAssets[balances[i].tokenAddress];
            Math.Number memory oraclePrice = _getOraclePriceByAddress(asset.priceOracleAddress);
            Math.Number memory assetValue = Math.mul(balances[i].amount, oraclePrice);
            totalValue = Math.add(totalValue, assetValue);
        }

        return totalValue;
    }
    /**
     *  @notice Updates token asset balance with unrealized Funding
     *  @param account Address of the user account
     *  @param funding Unrealized funding value to realize on the user's collateral.
     *  @param tokenAddress Address of the token asset contract
     */
    function _realizeFunding(
        address account,
        Math.Number memory funding,
        address tokenAddress
    ) internal {
        _updateAssetBalance(account, tokenAddress, funding);
    }

    /**
     *  @notice Updates token asset balance with unrealized PnL
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param pnlAmount Unrealized PnL amount added to balance
     */
    function _realizePnl(
        address account,
        address tokenAddress,
        Math.Number memory pnlAmount
    ) internal {
        Math.Number memory tokenAssetOraclePrice = _getOraclePriceByAsset(tokenAddress);
        Math.Number memory amount = Math.div(pnlAmount, tokenAssetOraclePrice);

        _updateAssetBalance(account, tokenAddress, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Codec } from "Codec.sol";
import { Events } from "Events.sol";
import { Fees } from "Fees.sol";
import { Funding } from "Funding.sol";
import { Math } from "Math.sol";
import { SafeMath } from "SafeMath.sol";
import { Storage } from "Storage.sol";
import { Synthetic } from "Synthetic.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";
import { VerifyOrderSignature } from "VerifyOrderSignature.sol";

/**
 *  @author Paradex
 *  @title Trade
 */
contract Trade is Funding, Events, Synthetic, VerifyOrderSignature {
    /**
     *  @notice Checks if order risk is acceptable
     *  @param account Address of the user account
     */
    function _isOrderRiskAcceptable(address account) internal view returns (bool) {
        Math.Number memory tokenAssetsValue = Token._getAllAssetBalanceValue(account);
        Math.Number memory syntheticAssetsMarginRequirement = Synthetic._getTotalMarginRequirement(
            account, Types.MarginCheckType.Initial
        );
        Math.Number memory freeBalance = Math.sub(tokenAssetsValue, syntheticAssetsMarginRequirement);
        return Math.isPositive(freeBalance) || freeBalance.value == 0;
    }

    /**
     *  @notice Transfers fee from maker/taker accounts to fee account
     *  @param market ID of the synethetic asset
     *  @param makerAccount Account of the maker order
     *  @param takerAccount Account of the taker order
     *  @param matchSizeFloat Size of the matched orders in trade
     *  @param matchPrice Price of the matched orders in trade
     */
    function _transferFees(
        string memory market,
        address makerAccount,
        address takerAccount,
        Math.Float memory matchSizeFloat,
        uint matchPrice
    ) internal {
        Types.SyntheticAsset memory syntheticAsset = Synthetic._getAsset(market);
        address tokenAddress = syntheticAsset.settlementAsset;

        // Caculate value
        Math.Number memory oraclePrice = Token._getOraclePriceByAsset(tokenAddress);
        Math.Number memory notionalValue = Math.div(
            Math.mul(Math.create(matchPrice), matchSizeFloat),
            oraclePrice
        );

        // Calculate fees
        Math.Number memory makerFee = Fees._getFeePct(Fees.MAKER_FEE, notionalValue);
        Math.Number memory takerFee = Fees._getFeePct(Fees.TAKER_FEE, notionalValue);

        // Deduct fees from token asset balances
        Token._transferToFeeAccount(makerAccount, tokenAddress, makerFee.value);
        Token._transferToFeeAccount(takerAccount, tokenAddress, takerFee.value);
    }

    /**
     *  @notice Settles trade request for matching maker and taker orders
     *  @param trade Trade request containing matching maker/taker orders
     */
    function _settle(Types.TradeRequest calldata trade) internal {
        require(trade.matchSize != 0, "Trade: Match size must be different than 0");
        require(trade.makerOrder.size != 0, "Trade: Maker Order size must be different than 0");
        require(trade.takerOrder.size != 0, "Trade: Maker Order size must be different than 0");

        VerifyOrderSignature._verify(trade.makerOrder);
        VerifyOrderSignature._verify(trade.takerOrder);

        require(
            Codec.hash(trade.makerOrder.market) == Codec.hash(trade.takerOrder.market),
            "Trade: Orders must be for the same synthetic asset"
        );

        bool isSyntheticSupported = Synthetic._isAssetSupported(trade.makerOrder.market);
        require(
            isSyntheticSupported,
            "Trade: Synthetic asset is not supported"
        );

        require(
            trade.makerOrder.side != trade.takerOrder.side,
            "Trade: Orders must have opposing sides"
        );

        // Convert trade match size to float representation
        Math.Float memory tradeMatchSizeFloat = Math.createFloat(trade.matchSize);

        (
            Types.SyntheticAssetBalance memory makerBalance,
            Math.Number memory makerFunding,
            Math.Number memory makerUnrealizedPnl
        ) = Synthetic._updateAssetBalance(
            trade.makerOrder.account,
            trade.makerOrder.market,
            trade.makerOrder.side,
            tradeMatchSizeFloat,
            trade.matchPrice
        );
        Token._realizeFunding(
            trade.makerOrder.account,
            makerFunding,
            Synthetic.getAssetSettlementAsset(trade.makerOrder.market)
        );
        Token._realizePnl(
            trade.makerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.makerOrder.market),
            makerUnrealizedPnl
        );
        Math.Number memory fundingRate = Synthetic._getAssetFundingFeed(trade.makerOrder.market);
        // Log funding
        Events._emitFundingAccrued(trade.id, trade.makerOrder.account, makerFunding, fundingRate);
        // Log balance update
        Events._emitSyntheticBalanceUpdate(trade.id, trade.makerOrder.account, makerBalance);

       (
            Types.SyntheticAssetBalance memory takerBalance,
            Math.Number memory takerFunding,
            Math.Number memory takerUnrealizedPnl
        ) = Synthetic._updateAssetBalance(
            trade.takerOrder.account,
            trade.takerOrder.market,
            trade.takerOrder.side,
            tradeMatchSizeFloat,
            trade.matchPrice
        );
        Token._realizeFunding(
            trade.takerOrder.account,
            takerFunding,
            Synthetic.getAssetSettlementAsset(trade.takerOrder.market)
        );
        Token._realizePnl(
            trade.takerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.takerOrder.market),
            takerUnrealizedPnl
        );

        // Track Funding
        if (makerFunding.sign == true) {
            Funding._incrementFundingReceived(makerFunding);
            Funding._incrementFundingPaid(takerFunding);
        } else {
            Funding._incrementFundingReceived(takerFunding);
            Funding._incrementFundingPaid(makerFunding);
        }

        // TODO: Flatten trade events to single event per user
        Events._emitFundingAccrued(trade.id, trade.takerOrder.account, takerFunding, fundingRate);
        Events._emitSyntheticBalanceUpdate(trade.id, trade.takerOrder.account, takerBalance);

        // Pay trading fees
        _transferFees(
            trade.makerOrder.market,
            trade.makerOrder.account,
            trade.takerOrder.account,
            tradeMatchSizeFloat,
            trade.matchPrice
        );

        require(
            _isOrderRiskAcceptable(trade.makerOrder.account),
            "Trade: Order is too risky for the maker account"
        );
        require(
            _isOrderRiskAcceptable(trade.takerOrder.account),
            "Trade: Order is too risky for the taker account"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Trade } from "Trade.sol";
import { Types } from "Types.sol";
import { VerifySignature } from "VerifySignature.sol";

/**
 *  @author Paradex
 *  @title VerifyOrderSignature
 *  @notice Library for order signature verification
 */
contract VerifyOrderSignature is VerifySignature {
    bytes32 ORDER_TYPEHASH = keccak256(
        "Order(string market,uint8 side,uint8 orderType,uint256 size,uint256 price)"
    );

    /**
     *  @notice Builds the order hash required for verification
     *  @param order Maker or Taker order received as part of a trade
     */
    function _buildOrderHash(Types.Order memory order) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                keccak256(bytes(order.market)), order.side, order.orderType, order.size, order.price
            )
        );
    }

    /**
     *  @notice Fetch the hash for a given order
     *  @param order Maker or Taker order received as part of a trade
     */
    function _getOrderHash(Types.Order memory order) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            // From the message signing process, it gets prepended with the byte \x19 and joined with the version
            // of value (byte) \x01.
            // https://github.com/ApeWorX/eip712/blob/68f5ebbf8603dcd137251eed93ace2caaed09e2d/eip712/messages.py#L61
            // https://github.com/ApeWorX/eip712/blob/68f5ebbf8603dcd137251eed93ace2caaed09e2d/eip712/messages.py#L157
            "\x19\x01",
            VerifySignature.buildDomainSeparator(),
            _buildOrderHash(order)
        ));
    }

    /**
     *  @notice Verify that the account in order matches signer
     *  @param order Maker or Taker order received as part of a trade
     */
    function _verify(Types.Order memory order) internal view {
        require(
            VerifySignature.recoverSigner(_getOrderHash(order), order.signature) == order.account,
            "VerifyOrderSignature: Account doesn't match signer"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Trade } from "Trade.sol";

/**
 *  @author Paradex
 *  @title VerifySignature
 *  @notice Library for signature verification
 */
contract VerifySignature {
    bytes32 constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId)"
    );

    /**
     *  @notice The domain separator prevents collision of otherwise identical structures
     */
    function buildDomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256("Paradex");
        bytes32 hashedVersion = keccak256("1");
        return keccak256(abi.encode(DOMAIN_TYPEHASH, hashedName, hashedVersion, block.chainid));
    }

    /**
     *  @notice Recover signer by splitting the signature
     *  @param messageHash Message hash that contains the signer
     *  @param signature Signature of the signed message
     */
    function recoverSigner(
        bytes32 messageHash, bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    /**
     *  @notice Split the signature to get details
     *  @param signature A signature to split
     */
    function _splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "VerifySignature: Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Decimals } from "Decimals.sol";
import { Events } from "Events.sol";
import { IERC20Metadata } from "IERC20Metadata.sol";
import { Math } from "Math.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Transfer
 */
contract Transfer is Events, Token {
    /**
     *  @notice Transfers tokens from a user to the Exchange
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to deposit
     */
    function _deposit(address account, address tokenAddress, uint amount) internal {
        require(amount > 0, "Transfer: You need to deposit at least some tokens");
        require(Token._isExistingAsset(tokenAddress), "Transfer: Token address is invalid");

        IERC20Metadata token = IERC20Metadata(tokenAddress);

        // Check token allowance
        uint allowance = token.allowance(account, address(this));
        require(allowance >= amount, "Transfer: Check the token allowance");

        // Transfer the amount to our contract
        token.transferFrom(account, address(this), amount);

        // Value with internal decimals representation
        uint8 tokenDecimals = token.decimals();
        uint value = Decimals.convertToInternal(amount, tokenDecimals);

        // Increase token asset balance
        Math.Number memory balanceChange = Math.Number({ value: value, sign: true });
        Token._updateAssetBalance(account, tokenAddress, balanceChange);

        Events._emitDeposit(account, tokenAddress, amount);
    }

    /**
     *  @notice Transfer amount from the Exchange to a user
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to withdraw
     */
    function _withdraw(address account, address tokenAddress, uint amount) internal {
        require(amount > 0, "Transfer: You need to withdraw at least some tokens");
        require(Token._isExistingAsset(tokenAddress), "Transfer: Token address is invalid");

        Math.Number memory tokenAssetBalance = Token._getAssetBalance(account, tokenAddress);
        require(
            tokenAssetBalance.value >= amount && tokenAssetBalance.sign == true,
            "Transfer: Requested amount is more than available balance"
        );

        IERC20Metadata token = IERC20Metadata(tokenAddress);

        // Check token balance
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= amount, "Transfer: Check the token balance");

        // Transfer the amount to user
        token.transfer(account, amount);

        // Value with internal decimals representation
        uint8 tokenDecimals = token.decimals();
        uint value = Decimals.convertToInternal(amount, tokenDecimals);

        // Decrease token asset balance
        Math.Number memory balanceChange = Math.Number({ value: value, sign: false });
        Token._updateAssetBalance(account, tokenAddress, balanceChange);

        Events._emitWithdraw(account, tokenAddress, amount);
    }
}