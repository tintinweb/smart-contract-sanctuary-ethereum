// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "../interfaces/IIERC20Snapshot.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/ITokenDividendPool.sol";
import "../libraries/LibTokenDividendPool.sol";

import "../common/AccessibleCommon.sol";
import "./TokenDividendPoolStorage.sol";

//import "hardhat/console.sol";

contract TokenDividendPool is
    TokenDividendPoolStorage,
    AccessibleCommon,
    ITokenDividendPool
{
    event Claim(address indexed token, uint256 amount, uint256 snapshotId);
    event Distribute(address indexed token, uint256 amount, uint256 snapshotId);

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

    /// @inheritdoc ITokenDividendPool
    function claimBatch(address[] calldata _tokens) external override {
        for (uint i = 0; i < _tokens.length; ++i) {
            claim(_tokens[i]);
        }
    }

    /// @inheritdoc ITokenDividendPool
    function claim(address _token) public override {
        _claimUpTo(
            _token,
            msg.sender,
            distributions[_token].snapshots.length
        );
    }

    /// @inheritdoc ITokenDividendPool
    function claimUpTo(address _token, uint256 _endSnapshotId) public override {
        require(claimableUpTo(_token, msg.sender, _endSnapshotId) > 0, "Amount to be claimed is zero");

        (bool found, uint256 snapshotIndex) = _getSnapshotIndexForId(_token, _endSnapshotId);
        require(found, "No such snapshot ID is found");
        uint256 endSnapshotIndex = snapshotIndex + 1;
        _claimUpTo(_token, msg.sender, endSnapshotIndex);
    }

    /// @inheritdoc ITokenDividendPool
    function distribute(address _token, uint256 _amount)
        external
        override
        ifFree
    {
        require(
            IIERC20Snapshot(erc20DividendAddress).totalSupply() > 0,
            "Total Supply is zero"
        );

        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        IIERC20Snapshot(_token).transferFrom(msg.sender, address(this), _amount);
        if (distr.exists == false) {
            distributedTokens.push(_token);
        }

        uint256 newBalance = IIERC20Snapshot(_token).balanceOf(address(this));
        uint256 increment = newBalance - distr.lastBalance;
        distr.exists = true;
        distr.lastBalance = newBalance;
        distr.totalDistribution = distr.totalDistribution + increment;

        uint256 snapshotId = IIERC20Snapshot(erc20DividendAddress).snapshot();
        distr.snapshots.push(
            LibTokenDividendPool.SnapshotInfo(snapshotId, increment, block.timestamp)
        );
        emit Distribute(_token, _amount, snapshotId);
    }

    /// @inheritdoc ITokenDividendPool
    function getAvailableClaims(address _account) public view override returns (address[] memory claimableTokens, uint256[] memory claimableAmounts) {
        uint256[] memory amounts = new uint256[](distributedTokens.length);
        uint256 claimableCount = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            amounts[i] = claimable(distributedTokens[i], _account);
            if (amounts[i] > 0) {
                claimableCount += 1;
            }
        }

        claimableAmounts = new uint256[](claimableCount);
        claimableTokens = new address[](claimableCount);
        uint256 j = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            if (amounts[i] > 0) {
                claimableAmounts[j] = amounts[i];
                claimableTokens[j] = distributedTokens[i];
                j++;
            }
        }
    }

    /// @inheritdoc ITokenDividendPool
    function claimable(address _token, address _account) public view override returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        uint256 endSnapshotIndex = distr.snapshots.length;
        return _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            endSnapshotIndex
        );
    }

    /// @inheritdoc ITokenDividendPool
    function claimableUpTo(
        address _token,
        address _account,
        uint256 _endSnapshotId
    ) public view override returns (uint256) {
        (bool found, uint256 snapshotIndex) = _getSnapshotIndexForId(_token, _endSnapshotId);
        require(found, "No such snapshot ID is found");
        uint256 endSnapshotIndex = snapshotIndex + 1;

        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        return _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            endSnapshotIndex
        );
    }


    /// @inheritdoc ITokenDividendPool
    function totalDistribution(address _token) public view override returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        return distr.totalDistribution;
    }

    /// @dev Get the snapshot index for given `_snapshotId`
    function _getSnapshotIndexForId(address _token, uint256 _snapshotId) view internal returns (bool found, uint256 index) {
        LibTokenDividendPool.SnapshotInfo[] storage snapshots = distributions[_token].snapshots;
        if (snapshots.length == 0) {
            return (false, 0);
        }

        index = snapshots.length - 1;
        while (true) {
            if (snapshots[index].id == _snapshotId) {
                return (true, index);
            }

            if (index == 0) break;
            index --;
        }
        return (false, 0);
    }

    /// @dev Claim rewards
    function _claimUpTo(address _token, address _account, uint256 _endSnapshotIndex) internal ifFree {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        uint256 amountToClaim = _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            _endSnapshotIndex
        );

        require(amountToClaim > 0, "Amount to be claimed is zero");
        IIERC20Snapshot(_token).transfer(msg.sender, amountToClaim);

        distr.nonClaimedSnapshotIndex[_account] = _endSnapshotIndex;
        distr.lastBalance -= amountToClaim;
        emit Claim(_token, amountToClaim, _endSnapshotIndex);
    }

    /// @dev Amount claimable
    function _calculateClaim(
        address _token,
        address _account,
        uint256 _startSnapshotIndex,
        uint256 _endSnapshotIndex
    ) internal view returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];

        uint256 accumulated = 0;
        for (
            uint256 snapshotIndex = _startSnapshotIndex;
            snapshotIndex < _endSnapshotIndex;
            snapshotIndex = snapshotIndex + 1
        ) {
            uint256 snapshotId = distr.snapshots[snapshotIndex].id;
            uint256 totalDividendAmount = distr.snapshots[snapshotIndex].totalDividendAmount;
            accumulated +=  _calculateClaimPerSnapshot(
                                _account,
                                snapshotId,
                                totalDividendAmount
                            );
        }
        return accumulated;
    }

    /// @dev Calculates claim portion
    function _calculateClaimPerSnapshot(
        address _account,
        uint256 _snapshotId,
        uint256 _totalDividendAmount
    ) internal view returns (uint256) {
        uint256 balance = IIERC20Snapshot(erc20DividendAddress).balanceOfAt(_account, _snapshotId);
        if (balance == 0) {
            return 0;
        }

        uint256 supply = IIERC20Snapshot(erc20DividendAddress).totalSupplyAt(_snapshotId);
        if (supply == 0) {
            return 0;
        }
        //console.log("Balance: %d, Total: %d, Dividend Amount: %d", balance, supply, _totalDividendAmount);
        return _totalDividendAmount * balance / supply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIERC20Snapshot {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);


    /**
    onlyRole(SNAPSHOT_ROLE)
     */
    function snapshot() external returns (uint256) ;

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256) ;

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256) ;
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

     /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface ITokenDividendPool {
    /// @dev Claim batch
    function claimBatch(address[] calldata _tokens) external;

    /// @dev Claim
    function claim(address _token) external;

    /// @dev Claim up to `_timestamp`
    function claimUpTo(address _token, uint256 _endSnapshotIndex) external;

    /// @dev Distribute
    function distribute(address _token, uint256 _amount) external;
    
    /// @dev getAvailableClaims
    function getAvailableClaims(address _account) external view returns (address[] memory claimableTokens, uint256[] memory claimableAmounts);

    /// @dev Returns claimable amount
    function claimable(address _token, address _account) external view returns (uint256);
    
    /// @dev Returns claimable amount from `_timeStart` to `_timeEnd`
    function claimableUpTo(address _token, address _account, uint256 _endSnapshotIndex) external view returns (uint256);

    /// @dev Returns the total distribution amount for `_token`
    function totalDistribution(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


library LibTokenDividendPool {
    struct SnapshotInfo {
        uint256 id;
        uint256 totalDividendAmount;
        uint256 timestamp;
    }

    struct Distribution {
        bool exists;
        uint256 totalDistribution;
        uint256 lastBalance;
        mapping (uint256 => uint256) tokensPerWeek;
        mapping (address => uint256) nonClaimedSnapshotIndex;
        SnapshotInfo[] snapshots;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/LibTokenDividendPool.sol";

contract TokenDividendPoolStorage {

    bool public pauseProxy;
    bool public migratedL2;

    address public erc20DividendAddress;
    mapping(address => LibTokenDividendPool.Distribution) public distributions;
    address[] public distributedTokens;
    uint256 internal free = 1;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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