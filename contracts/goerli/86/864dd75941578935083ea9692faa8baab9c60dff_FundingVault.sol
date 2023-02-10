/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





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

// File: contracts/FundingVault.sol


pragma solidity ^0.8.17;


/* A Pledge represents a promised portion of the locked vault funds
* portion size factor is `severity / _pledgeSeverity`
*/
struct Pledge {
  uint32 tokenId;
  uint32 severity;
  uint64 lastClaimTime;
  uint128 perDayLimit;
  uint256 claimLimit;
}

interface IFundingVaultToken {
  function pledgeOwner(uint256 tokenId) external view returns (address);
  function pledgeUpdate(uint64 tokenId, address targetAddr) external;
}

struct PledgeTimeCache {
  uint64 cacheTime;
  uint64 totalSeverity;
  uint128 totalPledgeTime;
}

contract FundingVault is AccessControl {
  address private _vaultTokenAddr;
  uint64 private _vaultCreationTime;
  uint64 private _endOfLifeTime;
  uint32 private _pledgeIdCounter = 1;
  uint32 private _pledgeIdxCounter = 0;
  uint64 private _unused1;

  PledgeTimeCache private _pledgeTimeCache;

  uint256 private _totalDepositAmount = 0;
  uint256 private _storedVaultBalance = 0;

  mapping(uint32 => Pledge) private _pledges;
  mapping(uint32 => uint32) private _activePledges;
  

  event PledgeTimeMissmatch(uint64 cachedSeverity, uint64 calculatedSeverity, uint128 cachedPledgeTime, uint128 calculatedPledgeTime);
  event FundClaim(uint64 indexed pledgeId, address indexed to, uint256 amount, uint64 pledgeTimeUsed, uint64 pledgeTimeBurned);
  
  constructor(uint64 eol) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _endOfLifeTime = eol;

    uint64 intervalTime = _intervalTime();
    _vaultCreationTime = intervalTime;
    _pledgeTimeCache = PledgeTimeCache({
      cacheTime: intervalTime,
      totalSeverity: 0,
      totalPledgeTime: 0
    });
  }

  receive() external payable {
  }


  function setVaultToken(address vaultToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
    address oldVaultToken = _vaultTokenAddr;
    _vaultTokenAddr = vaultToken;

    uint32 pledgeCount = _pledgeIdxCounter;
    address pledgeOwner = _msgSender();
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      uint32 pledgeId = _activePledges[pledgeIdx];
      if(oldVaultToken != address(0)) {
        pledgeOwner = IFundingVaultToken(oldVaultToken).pledgeOwner(pledgeId);
        IFundingVaultToken(oldVaultToken).pledgeUpdate(pledgeId, address(0));
      }
      IFundingVaultToken(vaultToken).pledgeUpdate(pledgeId, pledgeOwner);
    }
  }

  function setEndOfLife(uint64 eol) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _endOfLifeTime = eol;
  }

  function rescueCall(address addr, uint256 amount, bytes calldata data) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint balance = address(this).balance;
    require(balance >= amount, "amount exceeds wallet balance");

    (bool sent, ) = payable(addr).call{value: amount}(data);
    require(sent, "call failed");
  }



  function getEndOfLife() public view returns (uint64) {
    return _endOfLifeTime;
  }

  function getRemainingTime() public view returns (uint64) {
    if(_endOfLifeTime > uint64(block.timestamp)) {
      return _endOfLifeTime - uint64(block.timestamp);
    }
    else {
      return 0;
    }
  }

  function getLockedBalance() public view returns (uint256) {
    (uint256 distributionBalance, ) = _getDistributionState(_intervalTime());
    return address(this).balance - distributionBalance;
  }

  function getTotalPledgeTime() public view returns (uint128) {
    (, uint128 totalPledgeTime) = _getDistributionState(_intervalTime());
    return totalPledgeTime;
  }

  function getPledges() public view returns (Pledge[] memory) {
    uint32 pledgeCount = _pledgeIdxCounter;
    Pledge[] memory pledges = new Pledge[](pledgeCount);
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      pledges[pledgeIdx] = _pledges[_activePledges[pledgeIdx]];
    }
    return pledges;
  }

  function getPledge(uint32 pledgeId) public view returns (Pledge memory) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    return _pledges[pledgeId];
  }



  function createPledge(address addr, uint32 severity, uint128 perDayLimit, uint256 claimLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(severity > 0, "severity must be bigger than 0");

    uint32 pledgeId = _pledgeIdCounter++;
    if(_vaultTokenAddr != address(0)) {
      IFundingVaultToken(_vaultTokenAddr).pledgeUpdate(pledgeId, addr);
    }

    _pledges[pledgeId] = Pledge({
      severity: severity,
      tokenId: pledgeId,
      lastClaimTime: _intervalTime(),
      perDayLimit: perDayLimit,
      claimLimit: claimLimit
    });

    _refreshPledgeTimeCache();
    _pledgeTimeCache.totalSeverity += severity;

    uint32 pledgeIdx = _pledgeIdxCounter++;
    _activePledges[pledgeIdx] = pledgeId;
  }

  function updatePledge(uint32 pledgeId, uint32 severity, uint128 perDayLimit, uint256 claimLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    require(severity > 0, "severity must be bigger than 0");

    uint32 oldSeverity = _pledges[pledgeId].severity;
    if(oldSeverity != severity) {
      
      _pledges[pledgeId].severity = severity;

      uint64 lastClaimDuration = _intervalTime() - _pledges[pledgeId].lastClaimTime;
      _refreshPledgeTimeCache();
      if(oldSeverity > severity) {
        _pledgeTimeCache.totalSeverity -= oldSeverity - severity;
        _pledgeTimeCache.totalPledgeTime -= lastClaimDuration * (oldSeverity - severity);
      }
      else {
        _pledgeTimeCache.totalSeverity += severity - oldSeverity;
        _pledgeTimeCache.totalPledgeTime += lastClaimDuration * (severity - oldSeverity);
      }
    }
    _pledges[pledgeId].perDayLimit = perDayLimit;
    _pledges[pledgeId].claimLimit = claimLimit;
  }

  function transferPledge(uint32 pledgeId, address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    IFundingVaultToken(_vaultTokenAddr).pledgeUpdate(pledgeId, addr);
  }

  function removePledge(uint32 pledgeId) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");

    if(_vaultTokenAddr != address(0)) {
      IFundingVaultToken(_vaultTokenAddr).pledgeUpdate(pledgeId, address(0));
    }

    _refreshPledgeTimeCache();
    uint64 lastClaimDuration = _intervalTime() - _pledges[pledgeId].lastClaimTime;
    uint32 pledgeSeverity = _pledges[pledgeId].severity;
    _pledgeTimeCache.totalSeverity -= pledgeSeverity;
    _pledgeTimeCache.totalPledgeTime -= lastClaimDuration * pledgeSeverity;

    delete _pledges[pledgeId];

    uint32 pledgeCount = _pledgeIdxCounter - 1;
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      if(_activePledges[pledgeIdx] == pledgeId) {
        _activePledges[pledgeIdx] = _activePledges[pledgeCount];
      }
    }
    delete _activePledges[pledgeCount];
    _pledgeIdxCounter = pledgeCount;
  }

  function resyncPledgeTimeCache() public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint64 currentTime = _intervalTime();
    _refreshPledgeTimeCache();

    uint64 totalSeverity = 0;
    uint128 totalPledgeTime = 0;
    uint32 pledgeCount = _pledgeIdxCounter;
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      uint32 pledgeId = _activePledges[pledgeIdx];
      totalSeverity += _pledges[pledgeId].severity;
      totalPledgeTime += (currentTime - _pledges[pledgeId].lastClaimTime) * _pledges[pledgeId].severity;
    }

    if(_pledgeTimeCache.totalSeverity != totalSeverity || _pledgeTimeCache.totalPledgeTime != totalPledgeTime) {
      emit PledgeTimeMissmatch(_pledgeTimeCache.totalSeverity, totalSeverity, _pledgeTimeCache.totalPledgeTime, totalPledgeTime);
      _pledgeTimeCache.totalSeverity = totalSeverity;
      _pledgeTimeCache.totalPledgeTime = totalPledgeTime;
    }
  }

  function _ownerOf(uint32 tokenId) internal view returns (address) {
    if(_vaultTokenAddr == address(0)) {
      return address(0);
    }
    return IFundingVaultToken(_vaultTokenAddr).pledgeOwner(tokenId);
  }

  function _intervalTime() internal view returns (uint64) {
    return uint64(block.timestamp);
  }

  function _trackVaultBalance() internal {
    uint256 currentBalance = address(this).balance;
    if(currentBalance > _storedVaultBalance) {
      _totalDepositAmount += currentBalance - _storedVaultBalance;
      _storedVaultBalance = currentBalance;
    }
    else if(currentBalance < _storedVaultBalance) {
      // untracked loss? :/
      _storedVaultBalance = currentBalance;
    }
  }

  function _refreshPledgeTimeCache() internal {
    uint64 currentTime = _intervalTime();
    uint64 refreshDuration = currentTime - _pledgeTimeCache.cacheTime;
    if(refreshDuration > 0) {
      _pledgeTimeCache.cacheTime = currentTime;
      _pledgeTimeCache.totalPledgeTime += _pledgeTimeCache.totalSeverity * refreshDuration;
    }
  }

  function _getDistributionState(uint64 currentTime) internal view returns (uint256, uint128) {
    // get distribution balance (amount of funds that is `unlocked` and free for distribution)
    uint256 distributionBalance = address(this).balance;
    uint256 totalDepositAmount = _totalDepositAmount;
    if(distributionBalance > totalDepositAmount) {
      totalDepositAmount = distributionBalance;
    }

    uint64 creationTime = _vaultCreationTime;
    uint64 endOfLifeTime = _endOfLifeTime;
    if(endOfLifeTime > creationTime && endOfLifeTime > currentTime) {
      uint256 lockedBalance = totalDepositAmount * (endOfLifeTime - currentTime) / (endOfLifeTime - creationTime);
      if(distributionBalance > lockedBalance) {
        distributionBalance = distributionBalance - lockedBalance;
      }
      else {
        distributionBalance = 0;
      }
    }
    
    // get total pledge time (princip of `coin-time`)
    uint64 cacheAge = currentTime - _pledgeTimeCache.cacheTime;
    uint128 totalPledgeTime = _pledgeTimeCache.totalPledgeTime + (cacheAge * _pledgeTimeCache.totalSeverity);

    return (distributionBalance, totalPledgeTime);
  }

  function _calculatePledgePledgeTime(uint256 distributionBalance, uint128 totalPledgeTime, uint64 intervalTime, uint32 pledgeId) internal view returns (uint64, uint64, uint256) {
    Pledge memory pledge = _pledges[pledgeId];
    uint64 baseClaimTime = pledge.lastClaimTime;
    if(distributionBalance == 0 || totalPledgeTime == 0) {
      return (baseClaimTime, 0, 0);
    }
    if(baseClaimTime >= intervalTime) {
      return (baseClaimTime, 0, 0);
    }

    uint64 usePledgeTime = intervalTime - baseClaimTime;
    uint256 claimBalance = distributionBalance * (usePledgeTime * pledge.severity) / totalPledgeTime;
    uint256 limitedBalance = claimBalance;

    if(pledge.claimLimit > 0 && limitedBalance > pledge.claimLimit) {
      limitedBalance = pledge.claimLimit;
    }

    if(pledge.perDayLimit > 0 && (limitedBalance * 86400 / (intervalTime - baseClaimTime)) > pledge.perDayLimit) {
      limitedBalance = pledge.perDayLimit * (intervalTime - baseClaimTime) / 86400;
    }

    if(limitedBalance < claimBalance) {
      uint64 burnPledgeTime = uint64(usePledgeTime * (claimBalance - limitedBalance) / claimBalance);
      baseClaimTime += burnPledgeTime;
      usePledgeTime -= burnPledgeTime;
    }
    return (baseClaimTime, usePledgeTime, limitedBalance);
  }


  function claim() public returns (uint256) {
    return claim(uint256(0));
  }

  function claim(uint32 pledgeId) public returns (uint256) {
    return claim(pledgeId, uint256(0));
  }

  function claim(uint256 amount) public returns (uint256) {
    uint256 claimAmount = _claimFrom(_msgSender(), amount, _msgSender());
    if(amount > 0) {
      require(claimAmount == amount, "claim failed");
    }
    else {
      require(claimAmount > 0, "claim failed");
    }
    return claimAmount;
  }

  function claim(uint32 pledgeId, uint256 amount) public returns (uint256) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    require(_ownerOf(pledgeId) == _msgSender(), "not owner of this pledge");
    uint256 claimAmount = _claim(pledgeId, amount, _msgSender());
    if(amount > 0) {
      require(claimAmount == amount, "claim failed");
    }
    else {
      require(claimAmount > 0, "claim failed");
    }
    return claimAmount;
  }

  function claimTo(address target) public returns (uint256) {
    return claimTo(uint256(0), target);
  }

  function claimTo(uint32 pledgeId, address target) public returns (uint256) {
    return claimTo(pledgeId, uint256(0), target);
  }

  function claimTo(uint256 amount, address target) public returns (uint256) {
    uint256 claimAmount = _claimFrom(_msgSender(), amount, target);
    if(amount > 0) {
      require(claimAmount == amount, "claim failed");
    }
    else {
      require(claimAmount > 0, "claim failed");
    }
    return claimAmount;
  }

  function claimTo(uint32 pledgeId, uint256 amount, address target) public returns (uint256) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    require(_ownerOf(pledgeId) == _msgSender(), "not owner of this pledge");
    uint256 claimAmount = _claim(pledgeId, amount, target);
    if(amount > 0) {
      require(claimAmount == amount, "claim failed");
    }
    else {
      require(claimAmount > 0, "claim failed");
    }
    return claimAmount;
  }


  function _claimFrom(address owner, uint256 amount, address target) internal returns (uint256) {
    uint256 claimAmount = 0;
    uint128 pledgeCount = _pledgeIdxCounter;
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      uint32 pledgeId = _activePledges[pledgeIdx];
      if(_ownerOf(pledgeId) == owner) {
        uint256 claimed = _claim(pledgeId, amount, target);
        claimAmount += claimed;
        if(amount > 0) {
          if(amount == claimed) {
            break;
          }
          else {
            amount -= claimed;
          }
        }
      }
    }
    return claimAmount;
  }

  function _claim(uint32 pledgeId, uint256 amount, address target) internal returns (uint256) {
    _trackVaultBalance();

    uint64 intervalTime = _intervalTime();
    (uint256 distributionBalance, uint128 totalPledgeTime) = _getDistributionState(intervalTime);
    (uint64 baseClaimTime, uint64 usedPledgeTime, uint256 claimBalance) = _calculatePledgePledgeTime(distributionBalance, totalPledgeTime, intervalTime, pledgeId);
    if(claimBalance == 0) {
      return 0;
    }
    
    uint256 claimAmount = claimBalance;
    if(amount > 0 && claimAmount > amount) {
      claimAmount = amount;
      usedPledgeTime = uint64(usedPledgeTime * amount / claimBalance);
    }

    usedPledgeTime++; // round up

    // set new lastClaimTime
    uint64 lastClaimTime = baseClaimTime + usedPledgeTime;
    uint64 burnedPledgeTime = baseClaimTime - _pledges[pledgeId].lastClaimTime;
    _pledges[pledgeId].lastClaimTime = lastClaimTime;

    // remove consumed pledge time from pledge time cache
    _refreshPledgeTimeCache();
    _pledgeTimeCache.totalPledgeTime -= (burnedPledgeTime + usedPledgeTime) * _pledges[pledgeId].severity;
    
    // subtract claim amount from stored vault balance
    _storedVaultBalance -= claimAmount;

    // send claim amount to target
    (bool sent, ) = payable(target).call{value: claimAmount}("");
    require(sent, "failed to send ether");

    emit FundClaim(pledgeId, target, claimAmount, usedPledgeTime, burnedPledgeTime);

    return claimAmount;
  }

  function getUnclaimedBalance() public view returns (uint256) {
    uint256 claimableAmount = 0;
    uint128 pledgeCount = _pledgeIdxCounter;
    for(uint32 pledgeIdx = 0; pledgeIdx < pledgeCount; pledgeIdx++) {
      uint32 pledgeId = _activePledges[pledgeIdx];
      if(_ownerOf(pledgeId) == _msgSender()) {
        claimableAmount += _claimableBalance(pledgeId);
      }
    }
    return claimableAmount;
  }

  function getUnclaimedBalance(uint32 pledgeId) public view returns (uint256) {
    require(_pledges[pledgeId].severity > 0, "pledge not found");
    return _claimableBalance(pledgeId);
  }

  function _claimableBalance(uint32 pledgeId) internal view returns (uint256) {
    uint64 intervalTime = _intervalTime();
    (uint256 distributionBalance, uint128 totalPledgeTime) = _getDistributionState(intervalTime);
    (, , uint256 claimBalance) = _calculatePledgePledgeTime(distributionBalance, totalPledgeTime, intervalTime, pledgeId);
    return claimBalance;
  }

}