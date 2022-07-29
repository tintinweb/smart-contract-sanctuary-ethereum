// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run in production, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the currentTime variable set in the Timer.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

/**
 * @title Library to construct admin identifiers.
 */
library AdminIdentifierLib {
    // Returns a UTF-8 identifier representing a particular admin proposal.
    // The identifier is of the form "Admin n", where n is the proposal id provided.
    function _constructIdentifier(uint256 id) internal pure returns (bytes32) {
        bytes32 bytesId = _uintToUtf8(id);
        return _addPrefix(bytesId, "Admin ", 6);
    }

    // This method converts the integer `v` into a base-10, UTF-8 representation stored in a `bytes32` type.
    // If the input cannot be represented by 32 base-10 digits, it returns only the highest 32 digits.
    // This method is based off of this code: https://ethereum.stackexchange.com/a/6613/47801.
    function _uintToUtf8(uint256 v) internal pure returns (bytes32) {
        bytes32 ret;
        if (v == 0) {
            // Handle 0 case explicitly.
            ret = "0";
        } else {
            // Constants.
            uint256 bitsPerByte = 8;
            uint256 base = 10; // Note: the output should be base-10. The below implementation will not work for bases > 10.
            uint256 utf8NumberOffset = 48;
            while (v > 0) {
                // Downshift the entire bytes32 to allow the new digit to be added at the "front" of the bytes32, which
                // translates to the beginning of the UTF-8 representation.
                ret = ret >> bitsPerByte;

                // Separate the last digit that remains in v by modding by the base of desired output representation.
                uint256 leastSignificantDigit = v % base;

                // Digits 0-9 are represented by 48-57 in UTF-8, so an offset must be added to create the character.
                bytes32 utf8Digit = bytes32(leastSignificantDigit + utf8NumberOffset);

                // The top byte of ret has already been cleared to make room for the new digit.
                // Upshift by 31 bytes to put it in position, and OR it with ret to leave the other characters untouched.
                ret |= utf8Digit << (31 * bitsPerByte);

                // Divide v by the base to remove the digit that was just added.
                v /= base;
            }
        }
        return ret;
    }

    // This method takes two UTF-8 strings represented as bytes32 and outputs one as a prefixed by the other.
    // `input` is the UTF-8 that should have the prefix prepended.
    // `prefix` is the UTF-8 that should be prepended onto input.
    // `prefixLength` is number of UTF-8 characters represented by `prefix`.
    // Notes:
    // 1. If the resulting UTF-8 is larger than 32 characters, then only the first 32 characters will be represented
    //    by the bytes32 output.
    // 2. If `prefix` has more characters than `prefixLength`, the function will produce an invalid result.
    function _addPrefix(
        bytes32 input,
        bytes32 prefix,
        uint256 prefixLength
    ) internal pure returns (bytes32) {
        // Downshift `input` to open space at the "front" of the bytes32
        bytes32 shiftedInput = input >> (prefixLength * 8);
        return shiftedInput | prefix;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/OracleGovernanceInterface.sol";
import "./Constants.sol";
import "./AdminIdentifierLib.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Takes proposals for certain governance actions and allows UMA token holders to vote on them.
 */
contract GovernorV2 is MultiRole, Testable {
    using SafeMath for uint256;
    using Address for address;

    /****************************************
     *     INTERNAL VARIABLES AND STORAGE   *
     ****************************************/

    enum Roles {
        Owner, // Can set the proposer.
        Proposer // Address that can make proposals.
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposal {
        Transaction[] transactions;
        uint256 requestTime;
        bytes ancillaryData;
    }

    FinderInterface private finder;
    Proposal[] public proposals;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewProposal(uint256 indexed id, Transaction[] transactions);

    event ProposalExecuted(uint256 indexed id, uint256 transactionIndex);

    /**
     * @notice Construct the Governor contract.
     * @param _finderAddress keeps track of all contracts within the system based on their interfaceName.
     * @param _startingId the initial proposal id that the contract will begin incrementing from.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _finderAddress,
        uint256 _startingId,
        address _timerAddress
    ) Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createExclusiveRole(uint256(Roles.Proposer), uint256(Roles.Owner), msg.sender);

        // Ensure the startingId is not set unreasonably high to avoid it being set such that new proposals overwrite
        // other storage slots in the contract.
        uint256 maxStartingId = 10**18;
        require(_startingId <= maxStartingId, "Cannot set startingId larger than 10^18");

        // Sets the initial length of the array to the startingId. Modifying length directly has been disallowed in solidity 0.6.
        assembly {
            sstore(proposals.slot, _startingId)
        }
    }

    /****************************************
     *          PROPOSAL ACTIONS            *
     ****************************************/

    /**
     * @notice Proposes a new governance action. Can only be called by the holder of the Proposer role.
     * @param transactions list of transactions that are being proposed.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     */
    function propose(Transaction[] memory transactions, bytes memory ancillaryData)
        public
        onlyRoleHolder(uint256(Roles.Proposer))
    {
        uint256 id = proposals.length;
        uint256 time = getCurrentTime();

        // Note: doing all of this array manipulation manually is necessary because directly setting an array of
        // structs in storage to an an array of structs in memory is currently not implemented in solidity :/.

        // Add a zero-initialized element to the proposals array.
        proposals.push();

        // Initialize the new proposal.
        Proposal storage proposal = proposals[id];
        proposal.requestTime = time;
        proposal.ancillaryData = ancillaryData;

        // Initialize the transaction array.
        for (uint256 i = 0; i < transactions.length; i++) {
            require(transactions[i].to != address(0), "The `to` address cannot be 0x0");
            // If the transaction has any data with it the recipient must be a contract, not an EOA.
            if (transactions[i].data.length > 0) {
                require(transactions[i].to.isContract(), "EOA can't accept tx with data");
            }
            proposal.transactions.push(transactions[i]);
        }

        bytes32 identifier = AdminIdentifierLib._constructIdentifier(id);

        // Request a vote on this proposal in the DVM.
        _getOracle().requestGovernanceAction(identifier, time, ancillaryData);

        emit NewProposal(id, transactions);
    }

    /**
     * @notice Executes a proposed governance action that has been approved by voters.
     * @dev This can be called by any address. Caller is expected to send enough ETH to execute payable transactions.
     * @param id unique id for the executed proposal.
     * @param transactionIndex unique transaction index for the executed proposal.
     */
    function executeProposal(uint256 id, uint256 transactionIndex) external payable {
        Proposal storage proposal = proposals[id];
        int256 price =
            _getOracle().getPrice(
                AdminIdentifierLib._constructIdentifier(id),
                proposal.requestTime,
                proposal.ancillaryData
            );

        Transaction memory transaction = proposal.transactions[transactionIndex];

        require(
            transactionIndex == 0 || proposal.transactions[transactionIndex.sub(1)].to == address(0),
            "Previous tx not yet executed"
        );
        require(transaction.to != address(0), "Tx already executed");
        require(price != 0, "Proposal was rejected");
        require(msg.value == transaction.value, "Must send exact amount of ETH");

        // Delete the transaction before execution to avoid any potential re-entrancy issues.
        delete proposal.transactions[transactionIndex];

        require(_executeCall(transaction.to, transaction.value, transaction.data), "Tx execution failed");

        emit ProposalExecuted(id, transactionIndex);
    }

    /****************************************
     *       GOVERNOR STATE GETTERS         *
     ****************************************/

    /**
     * @notice Gets the total number of proposals (includes executed and non-executed).
     * @return uint256 representing the current number of proposals.
     */
    function numProposals() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Gets the proposal data for a particular id.
     * @dev after a proposal is executed, its data will be zeroed out, except for the request time.
     * @param id uniquely identify the identity of the proposal.
     * @return proposal struct containing transactions[] and requestTime.
     */
    function getProposal(uint256 id) external view returns (Proposal memory) {
        return proposals[id];
    }

    /****************************************
     *      PRIVATE GETTERS AND FUNCTIONS   *
     ****************************************/

    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        // Mostly copied from:
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly

        bool success;
        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
        }
        return success;
    }

    function _getOracle() private view returns (OracleGovernanceInterface) {
        return OracleGovernanceInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./OracleAncillaryInterface.sol";

/**
 * @title Financial contract facing extending the Oracle interface with governance actions.
 * @dev Interface used by financial contracts to interact with the Oracle extending governance actions. Voters will use a different interface.
 */
abstract contract OracleGovernanceInterface is OracleInterface, OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */
    function requestGovernanceAction(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}