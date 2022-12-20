// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract HsPay is AccessControl {
    struct Member {
        string name;
        uint index;
        uint multiplier;
        uint lastTimestamp;
        int debt;
    }

    event MemberAdded(address indexed _address, uint indexed multiplier);
    event MemberRemoved(address indexed _address);
    event MemberMultiplierChanged(address indexed _address, uint indexed oldMultiplier, uint indexed newMultiplier);
    event MemberAddressChanged(address indexed oldAddress, address indexed newAddress);
    event ServicePaymentWithdrawn(uint indexed amount);
    event ServicePaymentForMember(address indexed _address, uint indexed amount);

    error MemberNotFound(address _address);
    error MemberAlreadyExists(address _address);
    error InvalidAddressIndex(uint index);
    error InvalidRecipientAddress(address _address);
    error ZeroWithdrawBalance();

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint private constant ONE_DAY_SECONDS = 24 * 60 * 60;

    IERC20Metadata private _token;
    uint public baseCompensation;

    address[] private _memberIndex;
    mapping(address => Member) private _members;

    constructor(address _tokenAddress, uint baseFiatCompensation) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _token = IERC20Metadata(_tokenAddress);
        baseCompensation = baseFiatCompensation * 10 ** 18;
    }

    modifier validMember(address _address) {
        if (!_isMember(_address)) revert MemberNotFound(_address);
        _;
    }

    modifier validMembers(address[] calldata _addresses) {
        uint addressLength = _addresses.length;
        for (uint i = 0; i < addressLength; i++) {
            if (!_isMember(_addresses[i])) revert MemberNotFound(_addresses[i]);
        }
        _;
    }

    modifier nonExistingMember(address _address) {
        if (_isMember(_address)) revert MemberAlreadyExists(_address);
        _;
    }

    function tokenAddress() public view returns (address) {
        return address(_token);
    }

    function updateTokenAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
        _token = IERC20Metadata(_address);
    }

    function updateBaseFiatCompensation(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint memberLength = _memberIndex.length;
        for (uint i = 0; i < memberLength; i++) {
            address _address = _memberIndex[i];
            _withdrawOnParameterChange(_address);
        }

        baseCompensation = amount * 10 ** 18;
    }

    function addMember(address _address, uint multiplier, string memory name) public onlyRole(MODERATOR_ROLE) nonExistingMember(_address) {
        Member storage member = _members[_address];
        member.name = name;
        member.index = _memberIndex.length;
        member.multiplier = multiplier;
        member.lastTimestamp = block.timestamp;
        member.debt = 0;
        _memberIndex.push(_address);

        emit MemberAdded(_address, multiplier);
    }

    function removeMember(address _address) public onlyRole(MODERATOR_ROLE) validMember(_address) {
        Member storage member = _members[_address];

        int _balance = _calculateBalance(member.multiplier, _calculateDayCount(member.lastTimestamp), member.debt);
        if (_balance > 0) {
            _token.transfer(_address, _convert(uint(_balance), 18, _token.decimals()));
        }

        uint indexToDelete = member.index;
        address addressToMove = _memberIndex[_memberIndex.length - 1];
        _memberIndex[indexToDelete] = addressToMove;
        _members[addressToMove].index = indexToDelete;
        _memberIndex.pop();

        emit MemberRemoved(_address);
    }

    function updateMemberAddress(address oldAddress, address newAddress) public onlyRole(MODERATOR_ROLE) validMember(oldAddress) nonExistingMember(newAddress) {
        Member storage oldMember = _members[oldAddress];
        Member storage newMember = _members[newAddress];

        newMember.index = oldMember.index;
        newMember.multiplier = oldMember.multiplier;
        newMember.debt = oldMember.debt;
        newMember.lastTimestamp = oldMember.lastTimestamp;
        newMember.name = oldMember.name;
        _memberIndex[oldMember.index] = newAddress;

        emit MemberAddressChanged(oldAddress, newAddress);
    }

    function updateMultiplier(address _address, uint multiplier) public onlyRole(MODERATOR_ROLE) validMember(_address) {
        _withdrawOnParameterChange(_address);

        uint oldMultiplier = _members[_address].multiplier;
        _members[_address].multiplier = multiplier;

        emit MemberMultiplierChanged(_address, oldMultiplier, multiplier);
    }

    function memberCount() public view returns (uint) {
        return _memberIndex.length;
    }

    function getName(address _address) public view validMember(_address) returns (string memory) {
        return _members[_address].name;
    }

    function memberAddress(uint index) public view returns (address) {
        if (index >= _memberIndex.length) revert InvalidAddressIndex(index);
        return _memberIndex[index];
    }

    function memberMultiplier(address _address) public view validMember(_address) returns (uint) {
        return _members[_address].multiplier;
    }

    function stateInfo(address _address) public view returns (address, uint, bool, bool) {
        return (address(_token), baseCompensation, hasRole(MODERATOR_ROLE, _address), hasRole(DEFAULT_ADMIN_ROLE, _address));
    }

    function memberInfo(address _address) public view returns (bool, uint, uint, int, int) {
        if (!_isMember(_address)) {
            return (false, 0, 0, 0, 0);
        }

        Member memory member = _members[_address];
        uint _dayCount = _calculateDayCount(member.lastTimestamp);

        return (true, member.multiplier, _dayCount, _calculateBalance(member.multiplier, _dayCount, member.debt), member.debt);
    }

    function memberInfoByIndex(uint index) public view returns (address, string memory, uint, uint, int) {
        if (index >= _memberIndex.length) revert InvalidAddressIndex(index);

        address _address = _memberIndex[index];
        Member memory member = _members[_address];

        return (_address, member.name, member.multiplier, _calculateDayCount(member.lastTimestamp), member.debt);
    }

    function addDayOffs(address _address, uint _count) public onlyRole(MODERATOR_ROLE) validMember(_address) {
        _addDayOffs(_address, _count);
    }

    function addBulkDayOffs(address[] calldata _addresses, uint[] calldata _counts) public onlyRole(MODERATOR_ROLE) validMembers(_addresses) {
        uint addressLength = _addresses.length;
        for (uint i = 0; i < addressLength; i++) {
            _addDayOffs(_addresses[i], _counts[i]);
        }
    }

    function subtractDayOffs(address _address, uint count) public onlyRole(MODERATOR_ROLE) validMember(_address) {
        uint amount = _dayOffCost(_members[_address].multiplier) * count;
        _members[_address].debt = _members[_address].debt - int(amount);
    }

    function addBonus(address _address, uint amount) public onlyRole(MODERATOR_ROLE) validMember(_address) {
        _members[_address].debt = _members[_address].debt - int(amount);
    }

    function withdrawServicePayment(address[] calldata _addresses, uint[] calldata amounts) public onlyRole(MODERATOR_ROLE) validMembers(_addresses) {
        uint totalPayment;
        uint addressLength = _addresses.length;

        for (uint i = 0; i < addressLength; i++) {
            address _address = _addresses[i];
            uint amount = amounts[i];

            _members[_address].debt = _members[_address].debt + int(amount);
            totalPayment = totalPayment + amount;

            emit ServicePaymentForMember(_address, amount);
        }

        _token.transfer(msg.sender, _convert(totalPayment, 18, _token.decimals()));

        emit ServicePaymentWithdrawn(totalPayment);
    }

    function getDebt(address _address) public view validMember(_address) returns (int) {
        return _members[_address].debt;
    }

    function dayCount(address _address) public view validMember(_address) returns (uint) {
        return _calculateDayCount(_members[_address].lastTimestamp);
    }

    function balance(address _address) public view validMember(_address) returns (int) {
        Member memory member = _members[_address];
        return _calculateBalance(member.multiplier, _calculateDayCount(member.lastTimestamp), member.debt);
    }

    function withdraw(address recipient) public validMember(msg.sender) {
        if (recipient == address(0)) revert InvalidRecipientAddress(recipient);

        Member storage member = _members[msg.sender];

        uint _dayCount = _calculateDayCount(member.lastTimestamp);
        int _balance = _calculateBalance(member.multiplier, _dayCount, member.debt);

        if (_balance <= 0) revert ZeroWithdrawBalance();

        _token.transfer(recipient, _convert(uint(_balance), 18, _token.decimals()));

        member.lastTimestamp = member.lastTimestamp + _dayCount * ONE_DAY_SECONDS;
        member.debt = 0;
    }

    function isMember(address _address) public view returns (bool) {
        return _isMember(_address);
    }

    function _isMember(address _address) private view returns (bool) {
        if (_memberIndex.length == 0) return false;
        return (_memberIndex[_members[_address].index] == _address);
    }

    function _calculateDayCount(uint lastTimestamp) private view returns (uint) {
        return (block.timestamp - lastTimestamp) / ONE_DAY_SECONDS;
    }

    function _calculateBalance(uint multiplier, uint _dayCount, int debt) private view returns (int) {
        int compensation = int(_calculateCompensation(multiplier, _dayCount));
        return compensation - debt;
    }

    function _convert(uint amount, uint8 fromDecimals, uint8 toDecimals) private pure returns (uint) {
        if (fromDecimals > toDecimals) {
            return amount / 10 ** (fromDecimals - toDecimals);
        } else if (fromDecimals < toDecimals) {
            return amount * 10 ** (toDecimals - fromDecimals);
        } else {
            return amount;
        }
    }

    function _addDayOffs(address _address, uint _count) private {
        Member storage member = _members[_address];
        uint dayOffCost = _dayOffCost(member.multiplier);
        uint amount = dayOffCost * _count;
        member.debt = member.debt + int(amount);
    }

    function _dayOffCost(uint multiplier) private view returns (uint) {
        uint memberCompensation = baseCompensation * multiplier / 100;
        return memberCompensation / 20;
    }

    function _withdrawOnParameterChange(address _address) private {
        Member storage member = _members[_address];

        uint _dayCount = _calculateDayCount(member.lastTimestamp);
        int compensation = int(_calculateCompensation(member.multiplier, _dayCount));
        int debt = member.debt;

        if (compensation <= debt) {
            member.debt = debt - compensation;
        } else {
            uint transferAmount = uint(compensation - debt);
            _token.transfer(_address, _convert(transferAmount, 18, _token.decimals()));
            member.debt = 0;
        }

        member.lastTimestamp = member.lastTimestamp + _dayCount * ONE_DAY_SECONDS;
    }

    function _calculateCompensation(uint multiplier, uint _dayCount) public view returns (uint) {
        uint compensation = baseCompensation * multiplier / 100;
        uint oneDayCompensation = compensation / 28;
        return oneDayCompensation * _dayCount;
    }

}