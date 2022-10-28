// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IRoyaltyOverseer.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoyaltyOverseer is IRoyaltyOverseer, AccessControl {
  // Royalty share split
  mapping(address => RoyaltySplit) public royaltyShares;

  // Mock access control using Openzeppelin standards. Should reflect roles from the gameItem contract.
  bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // gameItem => user => split address
  mapping(address => mapping(address => address)) public override userSplits;

  // gameItem => tokenId => split address
  mapping(address => mapping(uint256 => address)) public override tokenSplits;

  // wallet to receive platform fees
  address public override platformFeeWallet;

  // gameItem => registered
  // Boolean to flag if gameItem is registered
  mapping(address => bool) public registeredGameItem;

  // IMMUTABLES----------------------------------------------------------------
  // OxSplits contract
  ISplitMain public immutable splitFactory;

  /// @notice constant to scale uints into percentages (1e6 == 100%)
  uint32 public constant PERCENTAGE_SCALE = 1e6;

  // check if the caller is an admin
  modifier onlyAdministrator() {
    if (!(hasRole(ADMINISTRATOR_ROLE, msg.sender))) {
      revert Unauthorized(msg.sender);
    }
    _;
  }

  modifier gameItemIsRegistered(address _gameItem) {
    if (registeredGameItem[_gameItem] == false) {
      revert UnregisteredGameItem(_gameItem);
    }
    _;
  }

  constructor(
    address _splitFactory,
    address _platformFeeWallet,
    address _adminAddress
  ) {
    if (_splitFactory == address(0) || _platformFeeWallet == address(0)) {
      revert InvalidAddress();
    }

    // Set roles
    _setupRole(ADMINISTRATOR_ROLE, _adminAddress);
    _setRoleAdmin(ADMINISTRATOR_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, ADMINISTRATOR_ROLE);

    splitFactory = ISplitMain(payable(_splitFactory));
    platformFeeWallet = _platformFeeWallet;
  }

  // Mint an NFT. Creates a split if it doesn't exist. Reuse else.
  // Note here that _royaltyDestinations cannot have duplicate addresses because of 0xSplit's check.
  function mintToken(
    IGameItem.MintParams memory _mintParams,
    address[] memory _royaltyDestinations,
    uint32 _distributorFee,
    address _creator
  ) external override gameItemIsRegistered(_mintParams._gameItem) {
    IGameItem gameItem = IGameItem(_mintParams._gameItem);
    if (
      !(hasRole(MINTER_ROLE, msg.sender) ||
        hasRole(ADMINISTRATOR_ROLE, msg.sender))
    ) {
      revert Unauthorized(msg.sender);
    }
    // ensure recipients are inclusive of platform fee wallet
    _checkWalletExists(_royaltyDestinations, platformFeeWallet);
    // ensure recipients are inclusive of the creator address regardless of creator share allocation
    _checkWalletExists(_royaltyDestinations, _creator);

    // validate percentage allocations add up to 1e6(100%). 0xSplit has a check regardless but it is better to short circuit here.
    RoyaltySplit memory royaltySplit = royaltyShares[address(gameItem)];
    _validatePercentageAllocations(royaltySplit);

    // mint token
    uint256 tokenId = gameItem.mint(
      _mintParams._to,
      _mintParams._origin,
      _mintParams._id
    );

    address split = userSplits[address(gameItem)][msg.sender];
    if (split == address(0)) {
      (
        uint32 platformShare,
        uint32 baseCreatorShare,
        uint32 eachInvestorShare
      ) = _calculatePercentageAllocations(_royaltyDestinations, royaltySplit);

      uint256 numAccounts = _royaltyDestinations.length;
      uint32[] memory percentageAllocated = new uint32[](numAccounts);

      for (uint256 i; i < numAccounts; ++i) {
        if (_royaltyDestinations[i] == platformFeeWallet) {
          percentageAllocated[i] = platformShare;
        } else if (
          _royaltyDestinations[i] == _creator &&
          royaltySplit.baseCreatorShare > 0
        ) {
          percentageAllocated[i] = baseCreatorShare;
        } else {
          percentageAllocated[i] = eachInvestorShare;
        }
      }

      split = splitFactory.createSplit(
        _royaltyDestinations,
        percentageAllocated,
        _distributorFee,
        address(this)
      );

      userSplits[address(gameItem)][msg.sender] = split;
      tokenSplits[address(gameItem)][tokenId] = split;

      emit SplitCreated(
        split,
        _royaltyDestinations,
        percentageAllocated,
        _distributorFee
      );
    } else {
      tokenSplits[address(gameItem)][tokenId] = split;
    }
  }

  // Allows the user to collect payments from their splits
  function collectRoyalties(PaymentCollection[] memory _payments)
    external
    override
  {
    for (uint256 i; i < _payments.length; ++i) {
      PaymentCollection memory payment = _payments[i];
      address split = payment.split;

      if (split == address(0)) {
        revert InvalidAddress();
      }

      _checkWalletExists(payment.accounts, platformFeeWallet);

      // Sweep first
      ISplitMain(splitFactory).distributeETH(
        address(split),
        payment.accounts,
        payment.percentAllocations,
        payment.distributorFee,
        payment.distributorAddress
      );

      // Withdraw
      ISplitMain(splitFactory).withdraw(
        payment.recipient,
        1 ether, // Can be any non-zero value to withdraw all ETH
        payment.tokens
      );
    }
  }

  // Allow the user to change the fund destination in a split.
  function swapUserWallet(WalletUpdate[] memory _updates, address _newAddress)
    external
    override
  {
    for (uint256 i; i < _updates.length; ++i) {
      WalletUpdate memory update = _updates[i];

      address split = tokenSplits[update.gameItem][update.tokenId];
      if (split == address(0)) {
        revert InvalidAddress();
      }

      // check if params provided generate valid hash of split, revert otherwise
      // since this means that the input params are wrong
      _validateHash(
        split,
        update.accounts,
        update.percentAllocations,
        update.distributorFee
      );

      // check if platform fee wallet exist
      _checkWalletExists(update.accounts, platformFeeWallet);

      // check if msg.sender is a recipient, and retrieve index if true
      uint256 indexToReplace = _checkWalletExists(update.accounts, msg.sender);
      update.accounts[indexToReplace] = _newAddress;

      // sort accounts including the newly inserted `_newAddress`
      address[] memory accounts = new address[](update.accounts.length);
      accounts = _sortAddresses(update.accounts);

      // generate percentage allocations
      RoyaltySplit memory royaltySplit = royaltyShares[update.gameItem];
      (
        uint32 platformShare,
        uint32 baseCreatorShare,
        uint32 eachInvestorShare
      ) = _calculatePercentageAllocations(accounts, royaltySplit);

      uint256 numAccounts = accounts.length;
      uint32[] memory percentageAllocated = new uint32[](numAccounts);

      for (uint256 j; j < numAccounts; ++j) {
        if (accounts[j] == platformFeeWallet) {
          percentageAllocated[j] = platformShare;
        } else if (
          accounts[j] == _newAddress && royaltySplit.baseCreatorShare > 0
        ) {
          percentageAllocated[j] = baseCreatorShare;
        } else {
          percentageAllocated[j] = eachInvestorShare;
        }
      }

      // Update split with new params
      ISplitMain(splitFactory).updateAndDistributeETH(
        split,
        accounts,
        percentageAllocated,
        update.distributorFee,
        update.distributorAddress
      );

      // update mappings
      delete userSplits[update.gameItem][msg.sender];
      userSplits[update.gameItem][_newAddress] = split;

      emit SplitUpdated(
        split,
        accounts,
        percentageAllocated,
        update.distributorFee
      );

      ISplitMain(splitFactory).withdraw(
        _newAddress,
        1 ether, // Can be any non-zero value to withdraw all ETH
        update.tokens
      );
    }
  }

  // -----------------------------Getters----------------------------------

  function getRoyaltyAddress(uint256 _tokenId, address _gameItem)
    external
    view
    override
    returns (address wallet)
  {
    wallet = tokenSplits[_gameItem][_tokenId];
    if (wallet == address(0)) {
      return platformFeeWallet;
    }
  }

  function getRoyaltyShareAllocation(address _gameItem)
    external
    view
    override
    returns (RoyaltySplit memory _royaltyShares)
  {
    _royaltyShares = royaltyShares[_gameItem];
  }

  // -----------------------------Setters---------------------------------
  function setPlatformFeeWallet(address _wallet)
    external
    override
    onlyAdministrator
  {
    if (_wallet == address(0)) {
      revert InvalidAddress();
    }
    platformFeeWallet = _wallet;
  }

  function setRoyaltyShares(RoyaltySplit memory _shares, address _gameItem)
    external
    override
    onlyAdministrator
    gameItemIsRegistered(_gameItem)
  {
    _validatePercentageAllocations(_shares);
    royaltyShares[_gameItem] = _shares;
  }

  function registerGameItem(address _gameItem)
    external
    override
    onlyAdministrator
  {
    if (_gameItem == address(0)) {
      revert InvalidAddress();
    }
    registeredGameItem[_gameItem] = true;
  }

  // ------------------------Internal Helper Functions----------------------------
  // properly orders royalty share percentage
  function _calculatePercentageAllocations(
    address[] memory _accounts,
    RoyaltySplit memory _royaltySplit
  )
    internal
    pure
    returns (
      uint32 platformShare,
      uint32 baseCreatorShare,
      uint32 eachInvestorShare
    )
  {
    platformShare = _royaltySplit.platformShare;
    baseCreatorShare = _royaltySplit.baseCreatorShare;
    uint32 investableShare = _royaltySplit.investableShare;

    // cache length to save gas
    uint32 numAccounts = uint32(_accounts.length);
    if (baseCreatorShare == 0 && investableShare != 0) {
      eachInvestorShare = investableShare / (numAccounts - 1);
    } else if (investableShare != 0) {
      eachInvestorShare = investableShare / (numAccounts - 2);
    }
  }

  // Get sum of percentage allocations
  function _validatePercentageAllocations(RoyaltySplit memory _royaltySplit)
    internal
    pure
  {
    if (
      _getSum(
        _getPercentageArray(
          [
            _royaltySplit.platformShare,
            _royaltySplit.baseCreatorShare,
            _royaltySplit.investableShare
          ]
        )
      ) != PERCENTAGE_SCALE
    ) {
      revert InvalidSharePercentageSum();
    }
  }

  // get sum of array of numbers
  function _getSum(uint32[3] memory _numbers)
    internal
    pure
    returns (uint32 sum)
  {
    uint256 numbersLength = _numbers.length;
    for (uint256 i; i < numbersLength; ) {
      sum += _numbers[i];
      unchecked {
        ++i;
      }
    }
  }

  // Return percentage array that can be passed into splitMain's calldata params.
  function _getPercentageArray(uint32[3] memory _percentages)
    internal
    pure
    returns (uint32[3] memory returnPercentage)
  {
    for (uint256 i; i < _percentages.length; ) {
      returnPercentage[i] = _percentages[i];
      unchecked {
        ++i;
      }
    }
  }

  // Validates whether the platform wallet is specified in the array of accounts
  function _checkWalletExists(
    address[] memory _addresses,
    address _walletToFind
  ) internal pure returns (uint256 index) {
    index = _findUpperBound(_addresses, _walletToFind);
    if (_addresses[index] != _walletToFind) {
      revert MissingAddress(_walletToFind);
    }
  }

  /**
   * @dev Binary searches a sorted `array` and returns the first index that contains
   * a value greater or equal to `element`. If no such index exists (i.e. all
   * values in the array are strictly less than `element`), the array length is
   * returned. Time complexity O(log n).
   *
   * `array` is expected to be sorted in ascending order, and to contain no
   * repeated elements.
   *
   * Inspired by Openzeppelin's Array implementation
   */
  function _findUpperBound(address[] memory _array, address _element)
    internal
    pure
    returns (uint256)
  {
    if (_array.length == 0) {
      return 0;
    }

    uint256 low;
    uint256 high = _array.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (_array[mid] > _element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
    if (low > 0 && _array[low - 1] == _element) {
      return low - 1;
    } else {
      return low;
    }
  }

  /**
   * @dev Binary sorts array of addresses using Binary Search
   * Expected time complexity O(log n).
   */
  function _sortAddresses(address[] memory _unsortedAddresses)
    internal
    pure
    returns (address[] memory _sortedAddresses)
  {
    uint256 n = _unsortedAddresses.length;
    uint256 j;
    address selected;
    uint256 loc;
    for (uint256 i = 1; i < n; ++i) {
      j = i - 1;
      selected = _unsortedAddresses[i];

      // find location where selected should be inserted
      loc = _findUpperBound(_unsortedAddresses, selected);

      while (j >= loc) {
        _unsortedAddresses[j + 1] = _unsortedAddresses[j];
        j--;
      }
      _unsortedAddresses[j + 1] = selected;
    }
    _sortedAddresses = _unsortedAddresses;
  }

  function _validateHash(
    address split,
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
  ) internal view {
    bytes32 splitHash = splitFactory.getHash(split);
    bytes32 inputHash = _hashSplit(
      accounts,
      percentAllocations,
      distributorFee
    );
    if (splitHash != inputHash) {
      revert InvalidHash();
    }
  }

  /** @notice Hashes a split
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @return computedHash Hash of the split.
   *
   * Implemented from 0xSplit's SplitMain.sol
   */
  function _hashSplit(
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
  ) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(accounts, percentAllocations, distributorFee));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGameItem {
  /// @notice The item states
  enum Status {
    ACTIVE,
    IN_REVIEW,
    INACTIVE,
    DISALLOWED
  }

  /// @notice The game item attributes mapped to the token id
  struct GameItemStorage {
    address creator;
    address origin;
    string id;
    uint256 mintDate;
  }

  struct MintParams {
    address _to;
    address _origin;
    string _id;
    address _gameItem;
  }

  /// @notice Struct used to pass constructor parameters
  struct GameItemConstructorParams {
    string _name;
    string _symbol;
    string _tokenURI;
    string _type;
    string _license;
    string _licenseURI;
    string _resourceURI;
    string _usageConstraintsURI;
    uint256 _maxSupply;
    bool _remixable;
    address _ownerAddress;
    address _adminAddress;
  }

  // event emitted when status is updated
  event TokenStatusUpdated(uint256 _tokenId, Status _status);

  // Ownership transferred event
  event OwnershipTransferred(address oldOwner, address newOwner);

  ///@notice error when msg.sender does not have the admin or platfrom admin role
  error Unauthorized(address _initiator);

  ///@notice error when token id does not exist
  error TokenDoesNotExist();

  ///@notice error when supply reached max supply
  error SupplyExhausted();

  ///@notice error when address is a 0 address
  error InvalidAddress();

  /// @notice mint game item token
  /// @notice method can only be called by owner or admin or minter of the contract
  /// @param _to address to mint
  /// @param _origin origin address
  /// @param _id unique item id
  // _mintParams parameters containing _to, _origin and _id params
  function mint(
    address _to,
    address _origin,
    string calldata _id
  ) external returns (uint256 _tokenId);

  // function mint(MintParams calldata _mintParams) external;

  /// @notice update token uri
  /// @notice method can only be called by owner or admin of the contract

  /// @param _tokenURI new tokenURI
  function updateTokenURI(string calldata _tokenURI) external;

  /// @notice update type of item
  /// @notice method can only be called by owner or admin of the contract
  /// @param _type new type
  function setType(string calldata _type) external;

  /// @notice update token status
  /// @notice method can only be called by owner or admin of the contract
  /// @param _tokenId token id to update
  /// @param _status new status of the token
  function updateTokenStatus(uint256 _tokenId, Status _status) external;

  /// @notice update the name of the license
  /// @notice method can only be called by owner or admin of the contract
  /// @param _license new name of the license
  function updateLicense(string calldata _license) external;

  /// @notice update the uri pointing to the terms of use of the license
  /// @notice method can only be called by owner or admin of the contract
  /// @param _licenseURI new license uri
  function updateLicenseURI(string calldata _licenseURI) external;

  /// @notice flag indicating if item is remixable
  /// @notice method can only be called by owner or admin of the contract
  /// @param _flag true or false
  function updateRemixable(bool _flag) external;

  /// @notice update uri linked to resource uri
  /// @notice method can only be called by owner or admin of the contract
  /// @param _resourceUri new uri pointing to the resource json
  function updateResourceURI(string calldata _resourceUri) external;

  /// @notice update uri linked to usage constraints
  /// @notice method can only be called by owner or admin of the contract
  /// @param _usageConstraintsURI new uri pointing to the usage constraints json
  function updateUsageConstraintsURI(string calldata _usageConstraintsURI)
    external;

  /// @notice update the royalty overseer contract
  /// @notice method can only be called by owner or admin of the contract
  /// @param _royaltyOverseer royalty overseer contract address
  function updateRoyaltyOverseer(address _royaltyOverseer) external;

  /// @notice calculates the base URI + the token id
  /// @param _tokenId the token id
  function tokenURI(uint256 _tokenId) external view returns (string memory);

  /// @notice transfer ownership to a new owner
  /// @notice method can only be called by owner
  /// @param _newOwner new owner address
  function transferOwnership(address _newOwner) external;

  /// @notice retrieve the token state of a specific token
  /// @param _tokenId the token id
  function getTokenStatus(uint256 _tokenId)
    external
    view
    returns (Status _status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IGameItem.sol";
import "../vendor/0xSplits/interfaces/ISplitMain.sol";

interface IRoyaltyOverseer {
  // the sum of these 3 must add up to 1e6
  struct RoyaltySplit {
    // the platform's cut
    uint32 platformShare;
    // the amount guaranteed to the creator
    // if base creatorshare is 0, the creator becomes an investor, and receives the same share as the investors in the token (investable share/ number investors)
    uint32 baseCreatorShare;
    // the amount that gets split among investors
    uint32 investableShare;
  }

  struct PaymentCollection {
    address split;
    // distributeETH and withdraw params
    address[] accounts;
    uint32[] percentAllocations;
    uint32 distributorFee;
    address distributorAddress; // distributor address to be reimbursed for gas
    // withdraw params
    address recipient; // recipient of royalty withdrawal
    ERC20[] tokens;
  }

  struct WalletUpdate {
    uint256 tokenId;
    address gameItem;
    // distributeETH params
    address[] accounts;
    uint32[] percentAllocations;
    uint32 distributorFee;
    address distributorAddress;
    // withdraw params
    ERC20[] tokens;
  }

  struct BaseSplit {
    address split;
    address[] accounts;
    uint32[] percentAllocations;
    uint32 distributorFee;
  }

  // event emitted when a split is created
  event SplitCreated(
    address indexed split,
    address[] accounts,
    uint32[] percentAllocations,
    uint32 distributorFee
  );

  // event emitted when a split is updated
  event SplitUpdated(
    address indexed split,
    address[] accounts,
    uint32[] percentAllocations,
    uint32 distributorFee
  );

  ///@notice error when address is a 0 address
  error InvalidAddress();

  ///@notice error when the sum of royalty share doesn't equal to 1e6
  error InvalidSharePercentageSum();

  ///@notice error when address is missing
  error MissingAddress(address _walletAddress);

  ///@notice error when user is unauthorized
  error Unauthorized(address _user);

  ///@notice error when GameItem is not registered
  error UnregisteredGameItem(address _gameItem);

  ///@notice error when params entered is invalid split hash
  error InvalidHash();

  /// @notice mint tokens via function call to the GameItem contract
  /// @param _mintParams mint token data passed to GameItem's mint function
  /// @param _royaltyDestinations array of royalty recipients
  /// @param _distributorFee specified for the creation of split
  /// @param _creator user specified creator
  function mintToken(
    IGameItem.MintParams memory _mintParams,
    address[] memory _royaltyDestinations,
    uint32 _distributorFee,
    address _creator
  ) external;

  /// @notice collect royalties provided the specified parameters
  /// @param payments information required to withdraw from split
  function collectRoyalties(PaymentCollection[] memory payments) external;

  /// @notice allow user to change the fund destination in a split
  /// @param _updates information required to swap split wallet recipients
  /// @param _newAddress address to receive funds out of the split from previous split
  function swapUserWallet(WalletUpdate[] memory _updates, address _newAddress)
    external;

  // ------------Setters--------------------------------
  // @notice set platform fee
  function setPlatformFeeWallet(address _wallet) external;

  // @notice update royalty shares
  function setRoyaltyShares(RoyaltySplit memory _shares, address _gameItem)
    external;

  // @notice register GameItem contract address
  function registerGameItem(address _gameItem) external;

  // ------------ Getters --------------------------------
  // returns the split address or if not found the platform fee wallet
  function getRoyaltyAddress(uint256 _tokenId, address _gameItem)
    external
    view
    returns (address _wallet);

  /// @notice get user's split address
  function userSplits(address _gameItem, address _user)
    external
    view
    returns (address _split);

  /// @notice get token's split address
  function tokenSplits(address _gameItem, uint256 _tokenId)
    external
    view
    returns (address _split);

  /// @notice get platform fee wallet
  function platformFeeWallet() external view returns (address _wallet);

  /// @notice get royalty share allocation dedicated to a  game item
  function getRoyaltyShareAllocation(address _gameItem)
    external
    view
    returns (RoyaltySplit memory _royaltyShares);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// @author https://github.com/0xSplits/splits-contracts/blob/main/contracts/interfaces/ISplitMain.sol
pragma solidity 0.8.4;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  function getHash(address split) external view returns (bytes32);

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}