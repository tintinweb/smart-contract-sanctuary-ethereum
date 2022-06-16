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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Governor
 * @dev The Governor holds the rights to stage and execute contract calls i.e. changing Livepeer protocol parameters.
 */
contract Governor {
    using SafeMath for uint256;

    address public owner;

    /// @dev mapping of updateHash (keccak256(update) => executeBlock (block.number + delay)
    mapping(bytes32 => uint256) public updates;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event UpdateStaged(Update update, uint256 delay);

    event UpdateExecuted(Update update);

    event UpdateCancelled(Update update);

    struct Update {
        address[] target;
        uint256[] value;
        bytes[] data;
        uint256 nonce;
    }

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized: msg.sender not owner");
        _;
    }

    /// @notice Throws if called by any account other than this contract.
    /// @dev Forces the `stage/execute` path to be used to call functions with this modifier instead of directly.
    modifier onlyThis() {
        require(msg.sender == address(this), "unauthorized: msg.sender not Governor");
        _;
    }

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Allows the current owner to transfer control of the contract to a newOwner.
    /// @dev Can only be called through stage/execute, will revert if the caller is not this contract's address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public onlyThis {
        require(newOwner != address(0), "newOwner is a null address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Stage a batch of updates to be executed.
    /// @dev Reverts if the 'msg.sender' is not the 'owner'
    /// @dev Reverts if an update is already staged
    /// @param _update Update to be staged.
    /// @param _delay (uint256) Delay (in number of blocks) for the update.
    function stage(Update memory _update, uint256 _delay) public onlyOwner {
        bytes32 updateHash = keccak256(abi.encode(_update));

        require(updates[updateHash] == 0, "update already staged");

        updates[updateHash] = block.number.add(_delay);

        emit UpdateStaged(_update, _delay);
    }

    /// @notice Execute a staged update.
    /// @dev Updates are authorized during staging.
    /// @dev Reverts if a transaction can not be executed.
    /// @param _update  Update to be staged.
    function execute(Update memory _update) public payable {
        bytes32 updateHash = keccak256(abi.encode(_update));
        uint256 executeBlock = updates[updateHash];

        require(executeBlock != 0, "update is not staged");
        require(block.number >= executeBlock, "delay for update not expired");

        // prevent re-entry and replay
        delete updates[updateHash];
        for (uint256 i = 0; i < _update.target.length; i++) {
            /* solium-disable-next-line */
            (bool success, bytes memory returnData) = _update.target[i].call{ value: _update.value[i] }(
                _update.data[i]
            );
            require(success, string(returnData));
        }

        emit UpdateExecuted(_update);
    }

    /// @notice Cancel a staged update.
    /// @dev Reverts if an update does not exist.
    /// @dev Reverts if the 'msg.sender' is not the 'owner'
    /// @param _update Update to be cancelled.
    function cancel(Update memory _update) public onlyOwner {
        bytes32 updateHash = keccak256(abi.encode(_update));
        uint256 executeBlock = updates[updateHash];

        require(executeBlock != 0, "update is not staged");
        delete updates[updateHash];

        emit UpdateCancelled(_update);
    }
}