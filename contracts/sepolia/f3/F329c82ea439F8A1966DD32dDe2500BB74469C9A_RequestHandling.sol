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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ConnectContract.sol";
import "./CheckRights.sol";
import "./RequestCreation.sol";
import "./TypeLibrary.sol";

/// @title Vountain – ApproveRequest
/// @notice Contract for the approval of requests.

contract ApproveRequest is RequestCreation {
  constructor(
    address configurationContract,
    address connectContract
  ) RequestCreation(configurationContract, connectContract) {}

  event ApprovedRequest(uint256 violinId_);

  /// @dev Function [approveRequest]
  /// Function reads the request in storage, because it has to modify the request count.
  /// Several checks are performed to check if the approver is elligible.
  /// @param violinId_ a violin id for which the request should be approved
  function approveRequest(uint256 violinId_) external {
    RCLib.Request storage request = requestByViolinId[violinId_];

    require(request.canBeApproved, "there is nothing to approve!");
    require(request.requestValidUntil > block.timestamp, "request expired.");
    // require(request.creator != msg.sender, "you can't approve yourself...");

    bool alreadyApproved = false;
    for (uint256 i = 0; i < approvedAddress[violinId_].length; i++) {
      if (msg.sender == approvedAddress[violinId_][i]) {
        alreadyApproved = true;
        break;
      }
    }
    require(!alreadyApproved, "you already approved!");

    require(
      checkRole(
        request.approvalType,
        violinId_,
        RCLib.PROCESS_TYPE.IS_APPROVE_PROCESS,
        request.targetAccount,
        request.requesterRole
      ),
      "sorry you have insufficient rights to approve!"
    );

    request.approvalCount = request.approvalCount + 1;
    approvedAddress[violinId_].push(msg.sender);
    emit ApprovedRequest(violinId_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ConnectContract.sol";
import "./TypeLibrary.sol";
import "./MoveRoleOwnership.sol";

/// @title Vountain – CheckRights
/// @notice Contract for checking the rights for the request and approval logic.
///         Reads the config and applies the rules.

contract CheckRights is Ownable, MoveRoleOwnership {
  constructor(
    address configurationContract,
    address connectContract
  ) MoveRoleOwnership(configurationContract, connectContract) {}

  function checkRole(
    RCLib.Tasks requestType_,
    uint256 violinId_,
    RCLib.PROCESS_TYPE approve,
    address targetAccount,
    RCLib.Role requesterRole_
  ) public view returns (bool) {
    IAccessControl accessControl = IAccessControl(
      connectContract.getAccessControlContract(violinId_)
    );
    IViolineMetadata violinMetadata = IViolineMetadata(
      connectContract.getMetadataContract(violinId_)
    );
    IViolines violin = IViolines(connectContract.violinAddress());

    RCLib.Role[] memory _role;
    bool allowed = false;

    //if its an approval process, we save the corresponding roles to the role object.
    if (approve == RCLib.PROCESS_TYPE.IS_APPROVE_PROCESS) {
      _role = configurationContract.returnRoleConfig(violinId_, requestType_).canApprove; //TODO VERSION!
    } else {
      //else it is a creation process we save the roles from the initiate field to the role object.
      _role = configurationContract.returnRoleConfig(violinId_, requestType_).canInitiate;

      //when delegation the violin the accounts who hold the violin can delegate (+ owner and manager)
      if (
        RCLib.TaskCluster.DELEGATING == configurationContract.checkTasks(requestType_)
      ) {
        allowed = (msg.sender == violinMetadata.readLocation(violinId_));
        if (allowed) {
          return allowed;
        }
      }
    }

    //If it is an approval process and an account creation or mint the account to approve the transaction is the target account, because no role exists, yet.
    if (
      (approve == RCLib.PROCESS_TYPE.IS_APPROVE_PROCESS) &&
      (RCLib.TaskCluster.CREATION == configurationContract.checkTasks(requestType_) ||
        RCLib.TaskCluster.MINTING == configurationContract.checkTasks(requestType_))
    ) {
      allowed = (msg.sender == targetAccount);
    } else {
      bool skip;
      //looping through the roles to check
      for (uint256 i = 0; i < _role.length; i++) {
        if (approve == RCLib.PROCESS_TYPE.IS_APPROVE_PROCESS) {
          if (_role[i] == requesterRole_) {
            skip = true;
          }
        } else {
          if (_role[i] != requesterRole_) skip = true;
        }

        if (!skip) {
          //----special cases start----
          if (_role[i] == RCLib.Role.CUSTODIAL) {
            allowed = (violin.ownerOf(violinId_) == msg.sender);

            //if the desired role is VOUNTAIN, then it will be checked if the sender is the owner of the current contract.
          } else if (_role[i] == RCLib.Role.VOUNTAIN) {
            allowed = (msg.sender == owner());

            //----special cases end----

            //check the tole in the access control contract
          } else {
            allowed = accessControl.checkIfAddressHasAccess(
              msg.sender,
              _role[i],
              violinId_
            );
          }

          if (allowed) {
            return allowed;
          }
        }
        skip = false;
      }
    }
    return allowed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TypeLibrary.sol";
import "./ConnectContract.sol";

/// @title Vountain – Configuration
/// @notice Base Configuration for all contracts

contract Configuration is Ownable {
  mapping(uint256 => mapping(RCLib.Tasks => RCLib.RequestConfig)) config; //version -> config
  mapping(uint256 => uint256) public violinToVersion;
  mapping(uint256 => bool) public versionLive;
  mapping(uint256 => bool) public configFrozen;

  IConnectContract connectContract;

  constructor(address connectContract_) {
    connectContract = IConnectContract(connectContract_);
    /**
     * CREATE OWNER_ROLE
     */
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].canInitiate = [RCLib.Role.CUSTODIAL];
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].validity = 24;

    /**
     * CREATE INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * CREATE MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].canApprove = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].validity = 24;

    /**
     * CREATE VIOLIN MAKER
     */

    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * CREATE EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].canApprove = [RCLib.Role.EXHIBITOR_ROLE];
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].validity = 24;

    /**
     * CHANGE DURATION MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].affectedRole = RCLib
      .Role
      .MUSICIAN_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].validity = 24;

    /**
     * CHANGE DURATION INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * CHANGE DURATION VIOLIN MAKER
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * CHANGE DURATION EXHIBITOR
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].affectedRole = RCLib
      .Role
      .EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].validity = 24;

    /**
     * DELIST INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE,
      RCLib.Role.VOUNTAIN
    ];
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * DELIST MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].validity = 24;

    /**
     * DELIST VIOLIN MAKER
     */

    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * DELIST EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].validity = 24;

    /**
     * DELEGATE INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * DELEGATE MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].canApprove = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].validity = 24;

    /**
     * DELEGATE VIOLIN MAKER
     */

    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * DELEGATE EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].affectedRole = RCLib
      .Role
      .EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].validity = 24;

    /**
     * ADD CONCERT
     */

    config[0][RCLib.Tasks.ADD_CONCERT].canInitiate = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.ADD_CONCERT].canApprove = [RCLib.Role.INSTRUMENT_MANAGER_ROLE];
    config[0][RCLib.Tasks.ADD_CONCERT].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_CONCERT].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.ADD_CONCERT].validity = 24;

    /**
     * ADD EXHIBITION
     */

    config[0][RCLib.Tasks.ADD_EXHIBITION].canInitiate = [RCLib.Role.EXHIBITOR_ROLE];
    config[0][RCLib.Tasks.ADD_EXHIBITION].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.ADD_EXHIBITION].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_EXHIBITION].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.ADD_EXHIBITION].validity = 24;

    /**
     * ADD REPAIR
     */

    config[0][RCLib.Tasks.ADD_REPAIR].canInitiate = [RCLib.Role.VIOLIN_MAKER_ROLE];
    config[0][RCLib.Tasks.ADD_REPAIR].canApprove = [RCLib.Role.INSTRUMENT_MANAGER_ROLE];
    config[0][RCLib.Tasks.ADD_REPAIR].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_REPAIR].affectedRole = RCLib.Role.VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.ADD_REPAIR].validity = 24;

    /**
     * ADD PROVENANCE
     */

    config[0][RCLib.Tasks.ADD_PROVENANCE].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_PROVENANCE].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_PROVENANCE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_PROVENANCE].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_PROVENANCE].validity = 24;

    /**
     * ADD DOCUMENT
     */

    config[0][RCLib.Tasks.ADD_DOCUMENT].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_DOCUMENT].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_DOCUMENT].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_DOCUMENT].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_DOCUMENT].validity = 24;

    /**
     * ADD SALES
     */

    config[0][RCLib.Tasks.ADD_SALES].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_SALES].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_SALES].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_SALES].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_SALES].validity = 24;

    /**
     * CHANGE METADATA
     */

    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].validity = 24;

    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].canInitiate = [
      RCLib.Role.VOUNTAIN
    ];
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].canApprove = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].validity = 24;

    /**
     * ADD MINT NEW VIOLIN
     */

    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].approvalsNeeded = 1;
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].validity = 24;
  }

  /**
   * @dev function for returning the configuration in a readable manner
   * @param violinID_ the violin to be checked
   * @param configID_ the task to check e.g. DELIST_MUSICIAN_ROLE
   */
  function returnRoleConfig(
    uint256 violinID_,
    RCLib.Tasks configID_
  ) public view returns (RCLib.RequestConfig memory) {
    return (config[violinToVersion[violinID_]][configID_]);
  }

  /**
   * @dev function to set for all tasks at once
   * @param configs_ configuration with type RequestConfig containing all tasks
   * @param version_ the version number of the new configuration
   */
  function setConfigForTasks(
    RCLib.RequestConfig[] memory configs_,
    uint256 version_
  ) public onlyOwner {
    require(!configFrozen[version_], "you can't change live configs");
    require(
      configs_.length == uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL) + 1,
      "Invalid number of configs"
    );
    for (uint256 i = 0; i <= uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL); i++) {
      config[version_][RCLib.Tasks(i)] = configs_[i];
    }
  }

  /**
   * @dev query the configuration for a specific version
   * @param version_ the version to query
   */
  function getConfigForVersion(
    uint256 version_
  ) public view returns (RCLib.RequestConfig[] memory) {
    RCLib.RequestConfig[] memory configs = new RCLib.RequestConfig[](
      uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL) + 1
    );
    for (uint256 i = 0; i <= uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL); i++) {
      configs[i] = config[version_][RCLib.Tasks(i)];
    }
    return configs;
  }

  /**
   * @dev there are different task cluster. Means, that all creation tasks belong to the CREATION Cluster
   * @dev this is needed for handling the requests.
   */
  function checkTasks(RCLib.Tasks task_) public pure returns (RCLib.TaskCluster cluster) {
    if (
      task_ == RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.CREATE_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.CREATE_OWNER_ROLE ||
      task_ == RCLib.Tasks.CREATE_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.CREATION;
    } else if (
      task_ == RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_OWNER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.CHANGE_DURATION;
    } else if (
      task_ == RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.DELIST_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.DELIST_OWNER_ROLE ||
      task_ == RCLib.Tasks.DELIST_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.DELISTING;
    } else if (
      task_ == RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.DELEGATING;
    } else if (
      task_ == RCLib.Tasks.ADD_CONCERT ||
      task_ == RCLib.Tasks.ADD_EXHIBITION ||
      task_ == RCLib.Tasks.ADD_REPAIR
    ) {
      cluster = RCLib.TaskCluster.EVENTS;
    } else if (
      task_ == RCLib.Tasks.ADD_PROVENANCE ||
      task_ == RCLib.Tasks.ADD_DOCUMENT ||
      task_ == RCLib.Tasks.ADD_SALES
    ) {
      cluster = RCLib.TaskCluster.DOCUMENTS;
    } else if (
      task_ == RCLib.Tasks.CHANGE_METADATA_VIOLIN ||
      task_ == RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL
    ) {
      cluster = RCLib.TaskCluster.METADATA;
    } else {
      cluster = RCLib.TaskCluster.MINTING;
    }

    return cluster;
  }

  /**
   * @dev function to activate a new version (users can only set active versions)
   * @param version_ the version to activate
   */
  function setVersionLive(uint256 version_) public onlyOwner {
    versionLive[version_] = true;
    configFrozen[version_] = true;
  }

  /**
   * @dev function to deactivate a version
   * @param version_ the version to deactivate
   */
  function setVersionIncative(uint256 version_) public onlyOwner {
    versionLive[version_] = false;
  }

  /**
   * @dev An owner of a violin can set the version for his violin.
   * @dev The configuration immeadiatly takes place for the violin.
   * @dev It is not possible to downgrade to an older version
   * @dev It is not possible to switch to an inactive version
   * @param violinID_ the violin to manage
   * @param version_ the version to upgrade to
   */
  function setVersionForViolin(uint256 violinID_, uint256 version_) public {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinID_);
    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);

    require(
      accessControl.checkIfAddressHasAccess(msg.sender, RCLib.Role.OWNER_ROLE, violinID_),
      "account is not the owner"
    );

    require(version_ > violinToVersion[violinID_], "downgrade not possible");
    require(versionLive[version_], "version not live");

    violinToVersion[violinID_] = version_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TypeLibrary.sol";

/// @title Vountain – ConnectContract
/// @notice Connecting violin, metadata, access controls and

contract ConnectContract is Ownable {
  address public violinAddress;

  mapping(uint => RCLib.ContractCombination) public versionToContractCombination;
  mapping(uint => uint) public violinToContractVersion;
  mapping(uint => bool) public versionIsActive;
  mapping(uint => bool) public freezeConfigVersion;

  RCLib.LatestMintableVersion public latest;

  constructor() {}

  /**
   * @dev after deployment the ConnectContract and the violin contract are tied together forever
   * @param violinAddress_ the address of the violin contract
   */
  function setViolinAddress(address violinAddress_) public onlyOwner {
    //once and forever
    require(violinAddress == address(0), "already initialized");
    violinAddress = violinAddress_;
  }

  /**
   * @dev Vountain can add a contract combination for the application. Itś not possible to change a contract combination once the version was set to active
   * @param id_ the version of the contract combination
   * @param controllerContract_  the request handling logic contract
   * @param accessControlContract_  the role token contract
   * @param metadataContract_  the metadata contract
   */
  function setContractConfig(
    uint id_,
    address controllerContract_,
    address accessControlContract_,
    address metadataContract_
  ) public onlyOwner {
    require(!freezeConfigVersion[id_], "don't change active versions");
    versionToContractCombination[id_].controllerContract = controllerContract_;
    versionToContractCombination[id_].accessControlContract = accessControlContract_;
    versionToContractCombination[id_].metadataContract = metadataContract_;
  }

  /**
   * @dev Vountain can set a version to active. All contracts has to be initialized.
   * @dev The version is frozen and can not be changed later
   * @dev The latest version is set if the config has a higher number than the last latest version
   * @param version_ the version to set active
   */
  function setVersionActive(uint256 version_) public onlyOwner {
    RCLib.ContractCombination memory contracts = versionToContractCombination[version_];

    require(
      contracts.controllerContract != address(0) &&
        contracts.accessControlContract != address(0) &&
        contracts.metadataContract != address(0),
      "initialize contracts first"
    );
    versionIsActive[version_] = true;
    freezeConfigVersion[version_] = true;
    if (version_ >= latest.versionNumber) {
      latest.versionNumber = version_;
      latest.controllerContract = versionToContractCombination[version_]
        .controllerContract;
    }
  }

  /**
   * @dev function to set a version inactive
   * @param version_ the version to set inactive
   */
  function setVersionIncative(uint256 version_) public onlyOwner {
    versionIsActive[version_] = false;
  }

  /**
   * @dev an owner of the violin can set a version to active.
   * @dev it is not possible to choose an inactive version
   * @dev a downgrade is not possible
   * @param violinID_ the violin to change the combination
   * @param version_ the version to activate
   */
  function setViolinToContractVersion(uint violinID_, uint version_) public {
    IAccessControl accessControl = IAccessControl(getAccessControlContract(violinID_));
    require(
      accessControl.checkIfAddressHasAccess(
        msg.sender,
        RCLib.Role.OWNER_ROLE,
        violinID_
      ) || msg.sender == violinAddress,
      "account is not the owner"
    );
    require(versionIsActive[version_], "version not active");
    require(version_ >= violinToContractVersion[violinID_], "no downgrade possible");
    violinToContractVersion[violinID_] = version_;
  }

  /**
   * @dev returns the contract combination for a version
   * @param violinID_ the violin to check
   */
  function getContractsForVersion(
    uint violinID_
  ) public view returns (RCLib.ContractCombination memory cc) {
    return versionToContractCombination[violinToContractVersion[violinID_]];
  }

  /**
   * @dev returns the controller contract for the violin
   * @param violinID_ the violin to check
   */
  function getControllerContract(
    uint violinID_
  ) public view returns (address controllerContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.controllerContract;
  }

  /**
   * @dev returns the access control contract for the violin
   * @param violinID_ the violin to check
   */
  function getAccessControlContract(
    uint violinID_
  ) public view returns (address accessControlContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.accessControlContract;
  }

  /**
   * @dev returns the metadata contract for the violin
   * @param violinID_ the violin to check
   */
  function getMetadataContract(
    uint violinID_
  ) public view returns (address metadataContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.metadataContract;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ConnectContract.sol";
import "./Configuration.sol";
import "./TypeLibrary.sol";

/// @title Vountain – MoveRoleOwnership
/// @notice It should be possible, that in an emergency the access tokens can be moved by Vountain.
///         The owner token should be moveable by Vountain and by the asset owner.

contract MoveRoleOwnership is Ownable {
  IConfigurationContract configurationContract;
  IConnectContract connectContract;

  constructor(address configurationContract_, address connectContract_) {
    configurationContract = IConfigurationContract(configurationContract_);
    connectContract = IConnectContract(connectContract_);
  }

  /// @dev the owner role gets checked and
  /// @param to_ address of the receiver
  /// @param violinID_ token ID to check
  function sendOwnerToken(address to_, uint256 violinID_) public {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinID_);
    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);
    IViolineMetadata metadata = IViolineMetadata(readContracts.metadataContract);

    require(
      accessControl.checkIfAddressHasAccess(msg.sender, RCLib.Role.OWNER_ROLE, violinID_),
      "account has no owner role"
    );

    // Get ID for specific token
    uint256 roleTokenID = accessControl.returnCorrespondingTokenID(
      msg.sender,
      RCLib.Role.OWNER_ROLE,
      violinID_
    );
    metadata.setTokenOwner(violinID_, to_);

    // if token was found then move the token
    accessControl.administrativeMove(msg.sender, to_, violinID_, roleTokenID);
  }

  /// @dev Owner can move his token
  /// @param from_ address of the owner
  /// @param to_ address of the receiver
  /// @param violinID_ which token to move
  function claimOwnerToken(address from_, address to_, uint256 violinID_) public {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinID_);

    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);
    IViolines violin = IViolines(connectContract.violinAddress());
    IViolineMetadata metadata = IViolineMetadata(readContracts.metadataContract);

    require(
      accessControl.checkIfAddressHasAccess(from_, RCLib.Role.OWNER_ROLE, violinID_),
      "account has no owner role"
    );

    require(msg.sender == violin.ownerOf(violinID_), "you can only move your violins");

    uint256 roleTokenID = accessControl.returnCorrespondingTokenID(
      from_,
      RCLib.Role.OWNER_ROLE,
      violinID_
    );
    metadata.setTokenOwner(violinID_, to_);

    accessControl.administrativeMove(from_, to_, violinID_, roleTokenID);
  }

  /// @dev move a role token
  /// @param from_ address of the owner
  /// @param role_ which role token to move
  /// @param to_ address of the receiver
  /// @param violinID_ which token to moves
  function moveRoleToken(
    address from_,
    RCLib.Role role_,
    address to_,
    uint256 violinID_
  ) public {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinID_);
    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);
    IViolineMetadata metadata = IViolineMetadata(readContracts.metadataContract);

    require(msg.sender == owner(), "you can't move that token");

    uint256 roleTokenID = accessControl.returnCorrespondingTokenID(
      from_,
      role_,
      violinID_
    );

    if (role_ == RCLib.Role.MUSICIAN_ROLE) {
      metadata.setTokenArtist(violinID_, to_);
    } else if (role_ == RCLib.Role.INSTRUMENT_MANAGER_ROLE) {
      metadata.setTokenManager(violinID_, to_);
    } else if (role_ == RCLib.Role.VIOLIN_MAKER_ROLE) {
      metadata.setTokenViolinMaker(violinID_, to_);
    } else if (role_ == RCLib.Role.EXHIBITOR_ROLE) {
      metadata.setExhibitor(violinID_, to_);
    } else if (role_ == RCLib.Role.OWNER_ROLE) {
      metadata.setTokenOwner(violinID_, to_);
    }

    accessControl.administrativeMove(from_, to_, violinID_, roleTokenID);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ConnectContract.sol";
import "./CheckRights.sol";
import "./TypeLibrary.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Vountain – RequestCreation
/// @notice For different purposes different requests can be created.
///         The request types differ in the fields filled, but not in the structure.

contract RequestCreation is CheckRights {
  mapping(uint256 => address[]) internal approvedAddress;
  mapping(uint256 => RCLib.Request) internal requestByViolinId;

  event NewRequestCreated(uint256 violinId_);

  constructor(
    address configurationContract,
    address connectContract
  ) CheckRights(configurationContract, connectContract) {}

  using Strings for uint256;

  /// @dev create new request
  /// @param violinId_ ID of violin
  /// @param contractValidUntil_ date for the ending of the contract
  /// @param targetAccount_ Affected Target Account
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  function createNewRequest(
    uint256 violinId_,
    uint256 contractValidUntil_,
    address targetAccount_,
    RCLib.Tasks requestType_,
    RCLib.Role requesterRole_
  ) public {
    require(
      RCLib.TaskCluster.CHANGE_DURATION ==
        configurationContract.checkTasks(requestType_) ||
        RCLib.TaskCluster.DELISTING == configurationContract.checkTasks(requestType_) ||
        RCLib.TaskCluster.DELEGATING == configurationContract.checkTasks(requestType_),
      "wrong request type"
    );
    createRequest(
      violinId_,
      contractValidUntil_,
      targetAccount_,
      requestType_,
      requesterRole_
    );
  }

  /// @dev create new request
  /// @param violinId_ ID of violin
  /// @param contractValidUntil_ date for the ending of the contract
  /// @param targetAccount_ Affected Target Account
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  function createRequest(
    uint256 violinId_,
    uint256 contractValidUntil_,
    address targetAccount_,
    RCLib.Tasks requestType_,
    RCLib.Role requesterRole_
  ) internal {
    require(
      checkRole(
        requestType_,
        violinId_,
        RCLib.PROCESS_TYPE.IS_CREATE_PROCESS,
        targetAccount_,
        requesterRole_
      ),
      "you have the wrong role..."
    );

    require(
      requestByViolinId[violinId_].requestValidUntil <= block.timestamp,
      "already a pending request."
    );

    requestByViolinId[violinId_].violinId = violinId_;
    requestByViolinId[violinId_].approvalType = requestType_;
    requestByViolinId[violinId_].creator = msg.sender;
    requestByViolinId[violinId_].targetAccount = targetAccount_;
    requestByViolinId[violinId_].canBeApproved = true;
    requestByViolinId[violinId_].affectedRole = configurationContract
      .returnRoleConfig(violinId_, requestType_)
      .affectedRole;
    requestByViolinId[violinId_].canApprove = configurationContract
      .returnRoleConfig(violinId_, requestType_)
      .canApprove;
    requestByViolinId[violinId_].approvalsNeeded = configurationContract
      .returnRoleConfig(violinId_, requestType_)
      .approvalsNeeded;
    requestByViolinId[violinId_].approvalCount = 0;
    requestByViolinId[violinId_].requestValidUntil =
      block.timestamp +
      (configurationContract.returnRoleConfig(violinId_, requestType_).validity *
        1 hours);
    requestByViolinId[violinId_].contractValidUntil = contractValidUntil_;
    requestByViolinId[violinId_].requesterRole = requesterRole_;
    delete (approvedAddress[violinId_]);
    emit NewRequestCreated(violinId_);
  }

  /// @dev create new request
  /// @param violinId_ ID of violin
  /// @param requestValidUntil_ check valdity of contract with date
  /// @param targetAccount_ Affected Target Account
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  /// @param mintTarget_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  /// @param metadata_ request metadata (specified in TypeLibrary.sol)
  ///                  string name;
  ///                  string description;
  ///                  string longdescription;
  ///                  string image;
  ///                  string model3d;
  ///                  string[] attributes;
  ///                  string[] metadataValues;
  function createNewMintOrRoleRequest(
    uint256 violinId_,
    uint256 requestValidUntil_,
    address targetAccount_,
    RCLib.Tasks requestType_,
    address mintTarget_,
    RCLib.Metadata memory metadata_,
    RCLib.Role requesterRole_
  ) public {
    require(
      RCLib.TaskCluster.CREATION == configurationContract.checkTasks(requestType_) ||
        RCLib.TaskCluster.MINTING == configurationContract.checkTasks(requestType_),
      "only for new roles"
    );
    require(
      metadata_.attributeNames.length == metadata_.attributeValues.length,
      "attributes length differ"
    );
    if (
      RCLib.TaskCluster.MINTING == configurationContract.checkTasks(requestType_) &&
      mintTarget_ == address(0)
    ) {
      revert("target is null address");
    }
    if (RCLib.TaskCluster.MINTING == configurationContract.checkTasks(requestType_)) {
      requestValidUntil_ = 32472144000;
    }

    createRequest(
      violinId_,
      requestValidUntil_,
      targetAccount_,
      requestType_,
      requesterRole_
    );
    requestByViolinId[violinId_].newMetadata.name = metadata_.name;
    requestByViolinId[violinId_].newMetadata.description = metadata_.description;
    requestByViolinId[violinId_].newMetadata.longDescription = metadata_.longDescription;
    requestByViolinId[violinId_].newMetadata.image = metadata_.image;
    requestByViolinId[violinId_].newMetadata.media = metadata_.media;
    requestByViolinId[violinId_].newMetadata.model3d = metadata_.model3d;
    requestByViolinId[violinId_].newMetadata.attributeNames = metadata_.attributeNames;
    requestByViolinId[violinId_].newMetadata.attributeValues = metadata_.attributeValues;
    requestByViolinId[violinId_].mintTarget = mintTarget_;
  }

  /// @param violinId_ ID of violin
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  /// @param metadata_ request metadata (specified in TypeLibrary.sol)
  ///                  string name;
  ///                  string description;
  ///                  string longdescription;
  ///                  string image;
  ///                  string model3d;
  ///                  string[] attributes;
  ///                  string[] metadataValues;
  function createMetadataRequest(
    uint256 violinId_,
    RCLib.Tasks requestType_,
    RCLib.Metadata memory metadata_,
    RCLib.Role requesterRole_
  ) public {
    require(
      RCLib.TaskCluster.METADATA == configurationContract.checkTasks(requestType_),
      "only for changing metadata."
    );
    require(
      metadata_.attributeNames.length == metadata_.attributeValues.length,
      "attributes length differ"
    );
    createRequest(violinId_, 0, msg.sender, requestType_, requesterRole_);
    requestByViolinId[violinId_].newMetadata.name = metadata_.name;
    requestByViolinId[violinId_].newMetadata.description = metadata_.description;
    requestByViolinId[violinId_].newMetadata.longDescription = metadata_.longDescription;
    requestByViolinId[violinId_].newMetadata.image = metadata_.image;
    requestByViolinId[violinId_].newMetadata.media = metadata_.media;
    requestByViolinId[violinId_].newMetadata.model3d = metadata_.model3d;
    requestByViolinId[violinId_].newMetadata.attributeNames = metadata_.attributeNames;
    requestByViolinId[violinId_].newMetadata.attributeValues = metadata_.attributeValues;
  }

  /// @param violinId_ ID of violin
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  /// @param name_ name of the event
  /// @param description_ description of the event
  /// @param eventStartTimestamp_ when did the event happen
  /// @param eventStartTimestamp_ how long did it last
  function createNewEventRequest(
    uint256 violinId_,
    RCLib.Tasks requestType_,
    string memory name_,
    string memory description_,
    uint256 eventStartTimestamp_,
    uint256 eventEndTimestamp_,
    RCLib.Role requesterRole_
  ) public {
    require(
      RCLib.TaskCluster.EVENTS == configurationContract.checkTasks(requestType_),
      "only for adding events."
    );

    createRequest(
      violinId_,
      eventStartTimestamp_,
      msg.sender,
      requestType_,
      requesterRole_
    ); //request will be created

    requestByViolinId[violinId_].newEvent.name = name_;
    requestByViolinId[violinId_].newEvent.description = description_;
    requestByViolinId[violinId_].newEvent.role = configurationContract
      .returnRoleConfig(violinId_, requestType_)
      .affectedRole;
    requestByViolinId[violinId_].newEvent.attendee = msg.sender;
    requestByViolinId[violinId_].newEvent.eventStartTimestamp = eventStartTimestamp_;
    requestByViolinId[violinId_].newEvent.eventEndTimestamp = eventEndTimestamp_;
  }

  /// @param violinId_ ID of violin
  /// @param requestType_ specify a type e.g CREATE_MANAGER
  ///                     see Configuration.sol Contract for Details of roles
  /// @param eventStartTimestamp_ timestamp of the event
  /// @param document the document object
  function createNewDocumentRequest(
    uint256 violinId_,
    RCLib.Tasks requestType_,
    RCLib.Role requesterRole_,
    uint256 eventStartTimestamp_,
    RCLib.Documents memory document
  ) public {
    require(
      RCLib.TaskCluster.DOCUMENTS == configurationContract.checkTasks(requestType_),
      "only for adding documents."
    );

    createRequest(
      violinId_,
      eventStartTimestamp_,
      msg.sender,
      requestType_,
      requesterRole_
    ); //request will be created

    {
      requestByViolinId[violinId_].newDocument = document;
    }
  }

  function returnRequestByViolinId(
    uint256 request_
  ) public view returns (RCLib.Request memory) {
    return (requestByViolinId[request_]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ApproveRequest.sol";
import "./MoveRoleOwnership.sol";
import "./TypeLibrary.sol";

/// @title Vountain – RequestHandling
/// @notice Managing different requests

contract RequestHandling is ApproveRequest {
  constructor(
    address configurationContract,
    address connectContract
  ) ApproveRequest(configurationContract, connectContract) {}

  /// @dev managing the states which the violin can have
  /// @param affectedRole available roles OWNER_ROLE, VOUNTAIN, INSTRUMENT_MANAGER_ROLE, MUSICIAN_ROLE, VIOLIN_MAKER_ROLE
  /// @param metadata passing the instanciated ViolineMetadata
  /// @param violinId_ id of the violin
  /// @param targetAccount_ receiver account
  function setViolinState(
    RCLib.Role affectedRole,
    IViolineMetadata metadata,
    uint256 violinId_,
    address targetAccount_
  ) internal {
    if ((affectedRole) == (RCLib.Role.MUSICIAN_ROLE)) {
      metadata.setTokenArtist(violinId_, targetAccount_);
    } else if ((affectedRole == RCLib.Role.INSTRUMENT_MANAGER_ROLE)) {
      metadata.setTokenManager(violinId_, targetAccount_);
    } else if ((affectedRole == (RCLib.Role.VIOLIN_MAKER_ROLE))) {
      metadata.setTokenViolinMaker(violinId_, targetAccount_);
    } else if ((affectedRole == (RCLib.Role.OWNER_ROLE))) {
      metadata.setTokenOwner(violinId_, targetAccount_);
    }
  }

  /// @dev executing the request from requestByViolinId mapping (RequestCreation.sol)
  /// @param violinId_ id of the violin
  function executeRequest(uint256 violinId_) external {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinId_);

    // Inherited Contracts
    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);
    IViolines violin = IViolines(connectContract.violinAddress());
    IViolineMetadata metadata = IViolineMetadata(readContracts.metadataContract);

    // requestByViolinId is created in RequestCreation.sol
    RCLib.Request storage request = requestByViolinId[violinId_];
    require(request.canBeApproved, "there is nothing to execute!"); //wenn der request auf executed steht, dann gibt es nichts zu approven...
    require(request.approvalCount >= request.approvalsNeeded, "you need more approvals!"); //wenn noch nicht genug approvals existieren, dann kann nicht approved werden

    request.canBeApproved = false;
    request.requestValidUntil = block.timestamp;
    delete (approvedAddress[violinId_]);

    if (
      RCLib.TaskCluster.MINTING == configurationContract.checkTasks(request.approvalType)
    ) {
      violin.mintViolin(request.violinId, request.mintTarget);
    }
    if (
      RCLib.TaskCluster.METADATA ==
      configurationContract.checkTasks(request.approvalType) ||
      RCLib.TaskCluster.MINTING == configurationContract.checkTasks(request.approvalType)
    ) {
      metadata.changeMetadata(
        request.newMetadata.name,
        request.newMetadata.description,
        request.newMetadata.longDescription,
        request.newMetadata.image,
        request.newMetadata.media,
        request.newMetadata.model3d,
        request.newMetadata.attributeNames,
        request.newMetadata.attributeValues,
        request.violinId
      );
    }

    if (request.approvalType == RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL) {
      accessControl.changeMetadata(
        request.violinId,
        request.newMetadata.description,
        request.newMetadata.image
      );
    }

    if (
      RCLib.TaskCluster.CREATION ==
      configurationContract.checkTasks(request.approvalType) ||
      RCLib.TaskCluster.MINTING == configurationContract.checkTasks(request.approvalType)
    ) {
      require(
        !accessControl.checkIfAddressHasAccess(
          request.targetAccount,
          request.affectedRole,
          request.violinId
        ),
        "you already have that role!"
      );

      accessControl.mintRole(
        request.targetAccount,
        request.affectedRole,
        request.contractValidUntil,
        violinId_,
        request.newMetadata.image,
        request.newMetadata.description
      );

      setViolinState(request.affectedRole, metadata, violinId_, request.targetAccount);
    } else if (
      RCLib.TaskCluster.CHANGE_DURATION ==
      configurationContract.checkTasks(request.approvalType)
    ) //Ändern der Gültigkeit im AccessControl Contract
    {
      accessControl.setTimestamp(
        request.violinId,
        request.contractValidUntil,
        request.targetAccount,
        request.affectedRole
      );
    } else if (
      RCLib.TaskCluster.DELISTING ==
      configurationContract.checkTasks(request.approvalType)
    ) {
      accessControl.burnTokens(
        request.targetAccount,
        request.affectedRole,
        request.violinId
      );

      setViolinState(request.affectedRole, metadata, violinId_, address(0));
    } else if (
      RCLib.TaskCluster.DELEGATING ==
      configurationContract.checkTasks(request.approvalType)
    ) {
      metadata.setViolinLocation(violinId_, request.targetAccount);
    } else if (
      RCLib.TaskCluster.EVENTS == configurationContract.checkTasks(request.approvalType)
    ) {
      metadata.createNewEvent(
        request.newEvent.name,
        request.newEvent.description,
        request.newEvent.role,
        request.newEvent.attendee,
        request.newEvent.eventStartTimestamp,
        request.newEvent.eventEndTimestamp,
        request.approvalType,
        request.violinId
      );
    } else if (
      RCLib.TaskCluster.DOCUMENTS ==
      configurationContract.checkTasks(request.approvalType)
    ) {
      metadata.createNewDocument(
        request.newDocument.docType,
        request.newDocument.date,
        request.newDocument.cid,
        request.newDocument.title,
        request.newDocument.description,
        request.newDocument.source,
        request.newDocument.value,
        request.newDocument.valueOriginalCurrency,
        request.newDocument.originalCurrency,
        request.violinId
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract IConnectContract {
  function getContractsForVersion(
    uint violinID_
  ) public view virtual returns (RCLib.ContractCombination memory cc);

  function violinAddress() public view virtual returns (address violinAddress);

  function getControllerContract(
    uint violinID_
  ) public view virtual returns (address controllerContract);

  function getAccessControlContract(
    uint violinID_
  ) public view virtual returns (address accessControlContract);

  function getMetadataContract(
    uint violinID_
  ) public view virtual returns (address metadataContract);

  function versionIsActive(uint version) external view virtual returns (bool);
}

abstract contract IController {
  function returnRequestByViolinId(
    uint256 request_
  ) public view virtual returns (RCLib.Request memory);

  function roleName(RCLib.Role) public view virtual returns (string memory);

  function requestByViolinId(
    uint256 id_
  ) public view virtual returns (RCLib.Request memory);
}

abstract contract IConfigurationContract {
  function getConfigForVersion(
    uint256 version_
  ) public view virtual returns (RCLib.RequestConfig[] memory);

  function checkTasks(
    RCLib.Tasks task_
  ) public pure virtual returns (RCLib.TaskCluster cluster);

  function returnRoleConfig(
    uint256 version_,
    RCLib.Tasks configId_
  ) public view virtual returns (RCLib.RequestConfig memory);

  function violinToVersion(uint256 tokenId) external view virtual returns (uint256);
}

abstract contract IViolines {
  function mintViolin(uint256 id_, address addr_) external virtual;

  function ownerOf(uint256 tokenId) public view virtual returns (address);

  function balanceOf(address owner) public view virtual returns (uint256);
}

abstract contract IViolineMetadata {
  struct EventType {
    string name;
    string description;
    string role;
    address attendee;
    uint256 eventTimestamp;
  }

  function createNewConcert(
    string memory name_,
    string memory description_,
    string memory role_,
    address attendee_,
    uint256 eventTimestamp_,
    uint256 tokenID_
  ) external virtual;

  /// @param docType_ specify the document type: PROVENANCE, DOCUMENT, SALES
  /// @param date_ timestamp of the event
  /// @param cid_ file attachments
  /// @param title_ title of the Document
  /// @param description_ description of the doc
  /// @param source_ source of the doc
  /// @param value_ amount of the object
  /// @param value_original_currency_ amount of the object
  /// @param currency_ in which currency it was sold
  /// @param tokenID_ token ID
  function createNewDocument(
    string memory docType_,
    uint256 date_,
    string memory cid_,
    string memory title_,
    string memory description_,
    string memory source_,
    uint value_,
    uint value_original_currency_,
    string memory currency_,
    uint256 tokenID_
  ) external virtual;

  function changeMetadata(
    string memory name_,
    string memory description_,
    string memory longDescription_,
    string memory image_,
    string[] memory media_,
    string[] memory model3d_,
    string[] memory attributeNames_,
    string[] memory attributeValues_,
    uint256 tokenId_
  ) external virtual;

  function readManager(uint256 tokenID_) public view virtual returns (address);

  function readLocation(uint256 tokenID_) public view virtual returns (address);

  function setTokenManager(uint256 tokenID_, address manager_) external virtual;

  function setTokenArtist(uint256 tokenID_, address artist_) external virtual;

  function setTokenOwner(uint256 tokenID_, address owner_) external virtual;

  function setExhibitor(uint256 tokenID_, address exhibitor_) external virtual;

  function setTokenViolinMaker(uint256 tokenID_, address violinMaker_) external virtual;

  function setViolinLocation(uint256 tokenID_, address violinLocation_) external virtual;

  function createNewEvent(
    string memory name_,
    string memory description_,
    RCLib.Role role_,
    address attendee_,
    uint256 eventStartTimestamp_,
    uint256 eventEndTimestamp_,
    RCLib.Tasks eventType_,
    uint256 tokenID_
  ) external virtual;
}

abstract contract IAccessControl {
  function mintRole(
    address assignee_,
    RCLib.Role role_,
    uint256 contractValidUntil_,
    uint256 violinID_,
    string memory image,
    string memory description
  ) external virtual;

  function changeMetadata(
    uint256 tokenId_,
    string memory description_,
    string memory image_
  ) public virtual;

  function checkIfAddressHasAccess(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (bool);

  function setTimestamp(
    uint256 violinID_,
    uint256 timestamp_,
    address targetAccount_,
    RCLib.Role role_
  ) external virtual;

  function burnTokens(
    address targetAccount,
    RCLib.Role affectedRole,
    uint256 violinId
  ) external virtual;

  function returnCorrespondingTokenID(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (uint256);

  function administrativeMove(
    address from,
    address to,
    uint256 violinId,
    uint256 tokenId
  ) public virtual;
}

library RCLib {
  enum Role {
    OWNER_ROLE,
    VOUNTAIN,
    INSTRUMENT_MANAGER_ROLE,
    MUSICIAN_ROLE,
    VIOLIN_MAKER_ROLE,
    CUSTODIAL,
    EXHIBITOR_ROLE
  }

  enum TaskCluster {
    CREATION,
    CHANGE_DURATION,
    DELISTING,
    DELEGATING,
    EVENTS,
    DOCUMENTS,
    METADATA,
    MINTING
  }

  enum Tasks {
    CREATE_INSTRUMENT_MANAGER_ROLE,
    CREATE_MUSICIAN_ROLE,
    CREATE_VIOLIN_MAKER_ROLE,
    CREATE_OWNER_ROLE,
    CREATE_EXHIBITOR_ROLE,
    CHANGE_DURATION_MUSICIAN_ROLE,
    CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE,
    CHANGE_DURATION_VIOLIN_MAKER_ROLE,
    CHANGE_DURATION_OWNER_ROLE,
    CHANGE_DURATION_EXHIBITOR_ROLE,
    DELIST_INSTRUMENT_MANAGER_ROLE,
    DELIST_MUSICIAN_ROLE,
    DELIST_VIOLIN_MAKER_ROLE,
    DELIST_OWNER_ROLE,
    DELIST_EXHIBITOR_ROLE,
    DELEGATE_INSTRUMENT_MANAGER_ROLE,
    DELEGATE_MUSICIAN_ROLE,
    DELEGATE_VIOLIN_MAKER_ROLE,
    DELEGATE_EXHIBITOR_ROLE,
    ADD_CONCERT,
    ADD_EXHIBITION,
    ADD_REPAIR,
    ADD_PROVENANCE,
    ADD_DOCUMENT,
    ADD_SALES,
    MINT_NEW_VIOLIN,
    CHANGE_METADATA_VIOLIN,
    CHANGE_METADATA_ACCESSCONTROL
  }

  struct TokenAttributes {
    address owner;
    address manager;
    address artist;
    address violinMaker;
    address violinLocation;
    address exhibitor;
    RCLib.Event[] concert;
    RCLib.Event[] exhibition;
    RCLib.Event[] repair;
    RCLib.Documents[] document;
    RCLib.Metadata metadata;
  }

  struct RequestConfig {
    uint256 approvalsNeeded; //Amount of Approver
    RCLib.Role affectedRole; //z.B. MUSICIAN_ROLE
    RCLib.Role[] canApprove;
    RCLib.Role[] canInitiate;
    uint256 validity; //has to be in hours!!!
  }

  struct RoleNames {
    Role role;
    string[] names;
  }

  enum PROCESS_TYPE {
    IS_APPROVE_PROCESS,
    IS_CREATE_PROCESS
  }

  struct Request {
    uint256 violinId;
    uint256 contractValidUntil; //Timestamp
    address creator; //Initiator
    address targetAccount; //Get Role
    bool canBeApproved; //Wurde der Approval bereits ausgeführt
    RCLib.Role affectedRole; //Rolle im AccessControl Contract
    Role[] canApprove; //Rollen, die Approven können
    RCLib.Tasks approvalType; //z.B. CREATE_INSTRUMENT_MANAGER_ROLE
    uint256 approvalsNeeded; //Amount of approval needed
    uint256 approvalCount; //current approvals
    uint256 requestValidUntil; //Wie lange ist der Request gültig?
    address mintTarget; //optional
    RCLib.Event newEvent;
    RCLib.Documents newDocument;
    RCLib.Metadata newMetadata;
    RCLib.Role requesterRole;
  }

  struct AccessToken {
    string image;
    RCLib.Role role;
    uint256 violinID;
    uint256 contractValidUntil;
    string name;
    string description;
  }

  struct Event {
    string name;
    string description;
    RCLib.Role role;
    address attendee;
    uint256 eventStartTimestamp;
    uint256 eventEndTimestamp;
  }

  struct Documents {
    string docType;
    uint256 date;
    string cid;
    string title;
    string description;
    string source;
    uint value;
    uint valueOriginalCurrency;
    string originalCurrency;
  }

  struct Metadata {
    string name;
    string description;
    string longDescription;
    string image;
    string[] media;
    string[] model3d;
    string[] attributeNames;
    string[] attributeValues;
  }

  struct ContractCombination {
    address controllerContract;
    address accessControlContract;
    address metadataContract;
  }

  struct LatestMintableVersion {
    uint versionNumber;
    address controllerContract;
  }
}