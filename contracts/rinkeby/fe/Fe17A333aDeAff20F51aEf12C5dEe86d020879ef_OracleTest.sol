//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./OracleTokens.sol";
import "./IOracle.sol";

contract OracleTest is IOracle, OracleTokens {
    using SafeMath for uint256;
    using FractionMath for FractionMath.Fraction;

    mapping(address => uint256) private _prices;
    uint256 private _priceDecimals;
    FractionMath.Fraction private _threshold;

    constructor(
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_,
        uint256 priceDecimals_
    ) {
        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
        _priceDecimals = priceDecimals_;
    }

    function priceDecimals() external view returns (uint256) {
        return _priceDecimals;
    }

    function threshold() external view returns (uint256, uint256) {
        return _threshold.export();
    }

    function setPrice(address token_, uint256 price_) external onlySupported(token_) {
        _prices[token_] = price_;
    }

    function _price(address token_, uint256 amount_) internal view onlySupported(token_) returns (uint256) {
        uint256 manipulated = _prices[token_].mul(amount_).div(10**decimals(token_));
        if (manipulated > 0) return manipulated;

        AggregatorV3Interface feed = priceFeed(token_);
        (, int256 result, , , ) = feed.latestRoundData();
        uint256 _decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (, result, , , ) = feed.latestRoundData();
            _decimals = feed.decimals();
        }
        if (result <= 0) return 0;

        return uint256(result).mul(10**_priceDecimals).mul(amount_).div(10**_decimals).div(10**decimals(token_));
    }

    function priceMin(address token_, uint256 amount_) public view override returns (uint256) {
        FractionMath.Fraction memory complement = FractionMath.create(1, 1).sub(_threshold);
        return _price(token_, amount_).mul(complement.numerator).div(complement.denominator);
    }

    function priceMax(address token_, uint256 amount_) public view override returns (uint256) {
        FractionMath.Fraction memory multiplier = FractionMath.create(1, 1).add(_threshold);
        return _price(token_, amount_).mul(multiplier.numerator).div(multiplier.denominator);
    }

    function amountMin(address token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMax(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }

    function amountMax(address token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMin(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library FractionMath {
    using FractionMath for Fraction;
    using SafeMathUpgradeable for uint256;

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    modifier onlyValid(Fraction memory fraction) {
        require(fraction.denominator != 0, "FractionMath: Denominator of fraction cannot equal 0");
        _;
    }

    function create(uint256 a, uint256 b) internal pure returns (Fraction memory fraction) {
        require(b != 0, "FractionMath: Denominator cannot equal o");
        return Fraction({numerator: a, denominator: b});
    }

    function export(Fraction memory a) internal pure onlyValid(a) returns (uint256, uint256) {
        return (a.numerator, a.denominator);
    }

    function add(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).add(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function sub(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).sub(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function mul(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.numerator);
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function div(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        require(b.numerator != 0, "FractionMath: Divisior fraction cannot equal 0");
        fraction.numerator = a.numerator.mul(b.denominator);
        fraction.denominator = a.denominator.mul(b.numerator);
    }

    function eq(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) == b.numerator.mul(a.denominator);
    }

    function gt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) > b.numerator.mul(a.denominator);
    }

    function gte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) >= b.numerator.mul(a.denominator);
    }

    function lt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) < b.numerator.mul(a.denominator);
    }

    function lte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) <= b.numerator.mul(a.denominator);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract OracleTokens is Ownable {
    struct Token {
        AggregatorV3Interface priceFeed;
        AggregatorV3Interface reservePriceFeed;
        uint256 decimals;
        bool supported;
    }
    mapping(address => Token) private _tokens;

    modifier onlySupported(address token_) {
        require(isSupported(token_), "OracleTokens: Only supported tokens may be used");
        _;
    }

    // Set the price feed for a given asset along with the decimals
    function setPriceFeed(
        address[] memory token_,
        AggregatorV3Interface[] memory priceFeed_,
        AggregatorV3Interface[] memory reservePriceFeed_,
        uint256[] memory correctDecimals_,
        bool[] memory supported_
    ) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            Token storage token = _tokens[token_[i]];

            token.priceFeed = priceFeed_[i];
            token.reservePriceFeed = reservePriceFeed_[i];
            token.decimals = correctDecimals_[i];
            token.supported = supported_[i];
        }
    }

    // Check if an asset is supported by the oracle
    function isSupported(address token_) public view returns (bool) {
        return _tokens[token_].supported;
    }

    // Get the price feed for a given asset
    function priceFeed(address token_) public view returns (AggregatorV3Interface) {
        return _tokens[token_].priceFeed;
    }

    // Get the reserve price feed for a given asset
    function reservePriceFeed(address token_) public view returns (AggregatorV3Interface) {
        return _tokens[token_].reservePriceFeed;
    }

    // Get the correct decimals for a given asset
    function decimals(address token_) public view returns (uint256) {
        return _tokens[token_].decimals;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function priceMin(address token_, uint256 amount_) external view returns (uint256);

    function priceMax(address token_, uint256 amount_) external view returns (uint256);

    function amountMin(address token_, uint256 price_) external view returns (uint256);

    function amountMax(address token_, uint256 price_) external view returns (uint256);
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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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