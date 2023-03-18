/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// File: interfaces/IFeeManager.sol


pragma solidity ^0.8.17;

interface IFeeManager {
    function setCollectionFee(address collection, uint16 fee) external;

    function removeCollectionFee(address collection) external;

    function setDefaultFee(uint16 fee) external;

    function getRoyaltiesEnabled() external returns (bool);

    function setRoyaltiesEnabled(bool enabled) external;

    function setBidIncrement(uint16 increment) external;

    function setFeeReceiver(address receiver) external;

    function getReceiver() external view returns (address);

    function getFee(address collection) external view returns (uint16);

    function bidIncrement() external view returns (uint16);

    function divider() external view returns (uint16);

    function getFeeAmount(address collection, uint256 amount) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: FeeManager.sol


pragma solidity ^0.8.17;




/**
 * @author Jonatã Oliveira
 * @title FeeManager
 * @notice It handles the logic to manage platform fees.
 */
contract FeeManager is IFeeManager, Ownable {
    using SafeMath for uint256;

    struct CustomFee {
        uint16 fee;
        bool enabled;
    }

    uint16 private constant _DIVIDER = 10000;
    mapping(address => CustomFee) private customFees;
    uint16 public defaultFee = 200;
    uint16 private _bidIncrement = 500;
    address private feeReceiver;
    bool private royaltiesEnabled;

    /**
     * @notice Constructor
     * @param _defaultFee default platform fee
     * @param _feeReceiver address to receive fees
     */
    constructor(uint16 _defaultFee, address _feeReceiver) {
        defaultFee = _defaultFee;
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice Add a custom fee to target collection
     * @param collection address of the collection (ERC-721 or ERC-1155)
     * @param fee fee percentage
     */
    function setCollectionFee(address collection, uint16 fee) external override onlyOwner {
        customFees[collection].fee = fee;
        customFees[collection].enabled = true;
    }

    /**
     * @notice Remove the custom fee from collection
     * @param collection address of the collection (ERC-721 or ERC-1155)
     */
    function removeCollectionFee(address collection) external override onlyOwner {
        customFees[collection].fee = 0;
        customFees[collection].enabled = false;
    }

    /**
     * @notice Change the default fee
     * @param fee fee percentage
     */
    function setDefaultFee(uint16 fee) external override onlyOwner {
        defaultFee = fee;
    }

    /**
     * @notice Get royalties enabled
     */
    function getRoyaltiesEnabled() external view override returns (bool) {
        return royaltiesEnabled;
    }

    /**
     * @notice Enable/Disable royalties
     * @param enabled boolean
     */
    function setRoyaltiesEnabled(bool enabled) external override onlyOwner {
        royaltiesEnabled = enabled;
    }

    /**
     * @notice Change the bid increment percentage
     * @param increment increment percentage
     */
    function setBidIncrement(uint16 increment) external override onlyOwner {
        _bidIncrement = increment;
    }

    /**
     * @notice Change the fee receiver address
     * @param receiver address to receive fees
     */
    function setFeeReceiver(address receiver) external override onlyOwner {
        feeReceiver = receiver;
    }

    /**
     * @notice Returns the fee receiver address
     */
    function getReceiver() public view override returns (address) {
        return feeReceiver;
    }

    /**
     * @notice Returns the collection fee
     * @param collection address of the collection
     */
    function getFee(address collection) public view override returns (uint16) {
        CustomFee memory custom = customFees[collection];
        if (custom.enabled) {
            return custom.fee;
        }
        return defaultFee;
    }

    /**
     * @notice Returns the bid increment percentage
     */
    function bidIncrement() public view override returns (uint16) {
        return _bidIncrement;
    }

    /**
     * @notice Returns the percentage divider
     */
    function divider() public pure override returns (uint16) {
        return _DIVIDER;
    }

    /**
     * @notice Returns the calculated fee amount
     * @param collection address of the collection
     * @param amount amount to calc
     */
    function getFeeAmount(address collection, uint256 amount) external view override returns (uint256) {
        return amount.mul(getFee(collection)).div(_DIVIDER);
    }
}