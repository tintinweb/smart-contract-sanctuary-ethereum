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