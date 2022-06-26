// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IMerchant } from "../interfaces/IMerchant.sol";
import { IStradivarius } from "../interfaces/IStradivarius.sol";
import "../type/Types.sol";

contract Merchant is IMerchant, AccessControl, ReentrancyGuard {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER");

  // addresses
  address private _owner;
  address private _beneficiary;
  address private _targetNFT;

  uint256 public tier2WhitelistedAmount = 0;
  uint256 public tier3WhitelistedAmount = 0;
  uint256 public tier2RemainingAmount = 24;
  uint256 public tier3RemainingAmount = 86;
  uint256 public whitelistTier2Price = 0.24 ether;
  uint256 public whitelistTier3Price = 0.24 ether;
  uint256 public tier2Price = 0.3 ether;
  uint256 public tier3Price = 0.3 ether;
  uint256 public userCap = 3;
  uint256 public presaleStart;
  uint256 public publicSaleStart;
  uint256 public publicSaleEnd;

  mapping(address => uint256) private _tier2Whitelist;
  mapping(address => uint256) private _tier3Whitelist;
  mapping(address => uint256) private _purchased;

  event Purchased(
    address indexed minter,
    uint256 indexed tier,
    uint256 price,
    uint256 amount
  );

  constructor(
    address beneficiary_,
    address targetNFT_,
    uint256 presaleStart_,
    uint256 publicSaleStart_,
    uint256 publicSaleEnd_
  ) {
    require(beneficiary_ != address(0), "Merchant: invalid beneficiary address");
    require(targetNFT_ != address(0), "Merchant: invalid targetNFT address");
    require(block.timestamp <= presaleStart_, "Merchant: invalid presale start time");
    require(presaleStart_ < publicSaleStart_, "Merchant: invalid public sale start time");
    require(
      publicSaleEnd_ == 0 || publicSaleStart_ < publicSaleEnd_,
      "Merchant: invalid public sale end time"
    );

    _grantRole(OWNER_ROLE, msg.sender);

    _owner = msg.sender;
    _beneficiary = beneficiary_;
    _targetNFT = targetNFT_;
    presaleStart = presaleStart_;
    publicSaleStart = publicSaleStart_;
    publicSaleEnd = publicSaleEnd_;
  }

  // ============= QUERY

  function supportsInterface(bytes4 interfaceId_)
    public
    view
    override
    returns (bool)
  {
    return interfaceId_ == type(IMerchant).interfaceId || super.supportsInterface(interfaceId_);
  }

  function availableWhitelistCapOf(address user_, uint256 tier_)
    public
    view
    override
    returns (uint256)
  {
    require(tier_ == 2 || tier_ == 3, "Merchant: invalid tier");
    return tier_ == 2 ? _tier2Whitelist[user_] : _tier3Whitelist[user_];
  }

  function availableCapOf(address user_)
    public
    view
    override
    returns (uint256)
  {
    return userCap - _purchased[user_];
  }

  function getSalesInfo()
    public
    view
    override
    returns (SalesInfo memory)
  {
    return SalesInfo({
      tier2WhitelistedAmount: tier2WhitelistedAmount,
      tier3WhitelistedAmount: tier3WhitelistedAmount,
      tier2RemainingAmount: tier2RemainingAmount,
      tier3RemainingAmount: tier3RemainingAmount,
      whitelistTier2Price: whitelistTier2Price,
      whitelistTier3Price: whitelistTier3Price,
      tier2Price: tier2Price,
      tier3Price: tier3Price,
      userCap: userCap,
      presaleStart: presaleStart,
      publicSaleStart: publicSaleStart,
      publicSaleEnd: publicSaleEnd
    });
  }

  // ============= TX

  function setPublicSaleEnd(uint256 time_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    require(
      time_ == 0 || (time_ > block.timestamp && time_ != publicSaleEnd && time_ > publicSaleStart),
      "Merchant: invalid time"
    );
    publicSaleEnd = time_;
  }

  function destroy(address payable to_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    selfdestruct(to_);
  }

  function reserve(ReservePayload[] memory payload_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    for (uint256 i = 0; i < payload_.length; i++) {
      address account = payload_[i].account;
      uint256 amount = payload_[i].amount;
      uint256 tier = payload_[i].tier;

      require(tier == 2 || tier == 3, "Merchant: invalid tier");

      if (amount <= 0) continue;

      uint256 purchasedOrWhitelisted =
        _purchased[account] + _tier2Whitelist[account] + _tier3Whitelist[account];
      if (purchasedOrWhitelisted + amount > userCap) {
        if (userCap <= purchasedOrWhitelisted) {
          continue;
        }
        amount = userCap - purchasedOrWhitelisted;
      }

      if (tier == 2) {
        require(
          tier2WhitelistedAmount + amount <= tier2RemainingAmount,
          "Merchant: reserve exceeds the tier 2 remaining amount"
        );
        _tier2Whitelist[account] += amount;
        tier2WhitelistedAmount += amount;
      } else {
        require(
          tier3WhitelistedAmount + amount <= tier3RemainingAmount,
          "Merchant: reserve exceeds the tier 3 remaining amount"
        );
        _tier3Whitelist[account] += amount;
        tier3WhitelistedAmount += amount;
      }
    }
  }

  function purchase(uint256 amount_, uint256 tier_)
    public
    payable
    override
    nonReentrant
    returns (uint256[] memory)
  {
    // check tier
    require(tier_ == 2 || tier_ == 3, "Merchant: invalid tier");
    // check times
    uint256 blockTime = block.timestamp;
    require(presaleStart <= blockTime, "Merchant: sale is not open");
    require(
      publicSaleEnd == 0 || blockTime <= publicSaleEnd, // publicSaleEnd == 0 means it doesn't end
      "Merchant: sale is closed"
    );
    // check amount
    require(1 <= amount_ && amount_ <= userCap, "Merchant: invalid sale amount");
    require(_purchased[_msgSender()] + amount_ <= userCap, "Merchant: amount exceeded user cap");
    if (tier_ == 2) {
      require(amount_ <= tier2RemainingAmount, "Merchant: amount exceeded tier 2 sale cap");
    } else {
      require(amount_ <= tier3RemainingAmount, "Merchant: amount exceeded tier 3 sale cap");
    }

    if (presaleStart <= blockTime && blockTime < publicSaleStart) { // presale ends when public sale starts
      _processPresale(amount_, tier_, msg.value);
    } else {
      _processPublicSale(amount_, tier_, msg.value);
    }

    uint256[] memory tokenIds = new uint256[](amount_);
    for (uint256 i = 0; i < amount_; i++) {
      uint256 tokenId = IStradivarius(_targetNFT).mint(_msgSender(), tier_);
      tokenIds[i] = tokenId;
    }
    payable(_beneficiary).transfer(msg.value);

    emit Purchased(_msgSender(), tier_, msg.value, amount_);
    return tokenIds;
  }

  function _processPresale(uint256 amount_, uint256 tier_, uint256 msgValue_) internal {
    if (tier_ == 2) {
      require(amount_ <= _tier2Whitelist[_msgSender()], "Merchant: amount exceeded whitelist user cap");
      require(msgValue_ == whitelistTier2Price * amount_, "Merchant: invalid presale payment");
      _tier2Whitelist[_msgSender()] -= amount_;
      tier2RemainingAmount -= amount_;
      tier2WhitelistedAmount -= amount_;
    } else {
      require(amount_ <= _tier3Whitelist[_msgSender()], "Merchant: amount exceeded whitelist user cap");
      require(msgValue_ == whitelistTier3Price * amount_, "Merchant: invalid presale payment");
      _tier3Whitelist[_msgSender()] -= amount_;
      tier3RemainingAmount -= amount_;
      tier3WhitelistedAmount -= amount_;
    }

    _purchased[_msgSender()] += amount_;
  }

  function _processPublicSale(uint256 amount_, uint256 tier_, uint256 msgValue_) internal {
    if (tier_ == 2) {
      require(msgValue_ == tier2Price * amount_, "Merchant: invalid public sale payment");
      tier2RemainingAmount -= amount_;
    } else {
      require(msgValue_ == tier3Price * amount_, "Merchant: invalid public sale payment");
      tier3RemainingAmount -= amount_;
    }

    _purchased[_msgSender()] += amount_;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../type/Types.sol";

interface IMerchant {
  function availableWhitelistCapOf(address user_, uint256 tier_) external view returns (uint256);

  function availableCapOf(address user_) external view returns (uint256);

  function getSalesInfo() external view returns (SalesInfo memory);

  function setPublicSaleEnd(uint256 time_) external;

  function destroy(address payable to_) external;

  function reserve(ReservePayload[] memory payload_) external;

  function purchase(uint256 amount_, uint256 tier_) external payable returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IStradivarius is IERC721Enumerable {
  function tokenURI(uint256 tokenId_) external view returns (string memory);

  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) external view returns (uint256[] memory);

  function setBaseURI(string calldata baseUri_) external;

  function mint(address to_, uint256 tier_) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

struct TierInfo {
  uint256 nextTokenId;
  uint256 minTokenId;
  uint256 totalSupply;
}

struct ReservePayload {
  address account;
  uint256 amount;
  uint256 tier;
}

struct SalesInfo {
  uint256 tier2WhitelistedAmount;
  uint256 tier3WhitelistedAmount;
  uint256 tier2RemainingAmount;
  uint256 tier3RemainingAmount;
  uint256 whitelistTier2Price;
  uint256 whitelistTier3Price;
  uint256 tier2Price;
  uint256 tier3Price;
  uint256 userCap;
  uint256 presaleStart;
  uint256 publicSaleStart;
  uint256 publicSaleEnd;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}