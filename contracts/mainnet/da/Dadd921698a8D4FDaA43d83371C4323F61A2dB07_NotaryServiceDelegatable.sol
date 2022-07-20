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

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT
import "./TypesAndDecoders.sol";
import "./caveat-enforcers/CaveatEnforcer.sol";

abstract contract Delegatable is EIP712Decoder {
  event DelegationTriggered(address principal, address indexed agent);

  bytes32 public immutable domainHash;

  constructor(string memory contractName, string memory version) {
    domainHash = getEIP712DomainHash(contractName, version, block.chainid, address(this));
  }

  // Allows external signers to submit batches of signed invocations for processing.
  function invoke(SignedInvocation[] calldata signedInvocations) public returns (bool success) {
    for (uint256 i = 0; i < signedInvocations.length; i++) {
      SignedInvocation calldata signedInvocation = signedInvocations[i];
      address invocationSigner = verifyInvocationSignature(signedInvocation);
      enforceReplayProtection(invocationSigner, signedInvocations[i].invocations.replayProtection);
      _invoke(signedInvocation.invocations.batch, invocationSigner);
    }
  }

  // Allows external contracts to submit batches of invocations for processing.
  function contractInvoke(Invocation[] calldata batch) public returns (bool) {
    return _invoke(batch, msg.sender);
  }

  function _invoke(Invocation[] calldata batch, address sender) private returns (bool success) {
    for (uint256 x = 0; x < batch.length; x++) {
      Invocation memory invocation = batch[x];
      address intendedSender;
      address canGrant;

      // If there are no delegations, this invocation comes from the signer
      if (invocation.authority.length == 0) {
        intendedSender = sender;
        canGrant = intendedSender;
      }

      bytes32 authHash = 0x0;

      for (uint256 d = 0; d < invocation.authority.length; d++) {
        SignedDelegation memory signedDelegation = invocation.authority[d];
        address delegationSigner = verifyDelegationSignature(signedDelegation);

        // The following statement was add by Kames. Without it won't enforce the first invocation?
        // TODO: Needs more unit tests
        require(
          sender == delegationSigner || intendedSender == delegationSigner,
          "invalid-signature"
        );

        // Implied sending account is the signer of the first delegation
        if (d == 0) {
          intendedSender = delegationSigner;
          canGrant = intendedSender;
        }

        require(delegationSigner == canGrant, "Delegation signer does not match required signer");

        Delegation memory delegation = signedDelegation.delegation;
        require(
          delegation.authority == authHash,
          "Delegation authority does not match previous delegation"
        );

        // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
        // otherwise once it's revoked, you can't give the exact same permission again.
        bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(signedDelegation);

        // Each delegation can include any number of caveats.
        // A caveat is any condition that may reject a proposed transaction.
        // The caveats specify an external contract that is passed the proposed tx,
        // As well as some extra terms that are used to parameterize the enforcer.
        for (uint16 y = 0; y < delegation.caveats.length; y++) {
          CaveatEnforcer enforcer = CaveatEnforcer(delegation.caveats[y].enforcer);
          bool caveatSuccess = enforcer.enforceCaveat(
            delegation.caveats[y].terms,
            invocation.transaction,
            delegationHash
          );
          require(caveatSuccess, "Caveat rejected");
        }

        // Store the hash of this delegation in `authHash`
        // That way the next delegation can be verified against it.
        authHash = delegationHash;
        canGrant = delegation.delegate;
      }

      // Here we perform the requested invocation.
      Transaction memory transaction = invocation.transaction;

      require(transaction.to == address(this), "Invocation target does not match");
      emit DelegationTriggered(intendedSender, sender);
      success = execute(transaction.to, transaction.data, transaction.gasLimit, intendedSender);
      require(success, "Delegator execution failed");
    }
  }

  mapping(address => mapping(uint256 => uint256)) public multiNonce;

  function enforceReplayProtection(address intendedSender, ReplayProtection memory protection)
    private
  {
    uint256 queue = protection.queue;
    uint256 nonce = protection.nonce;
    require(
      nonce == (multiNonce[intendedSender][queue] + 1),
      "One-at-a-time order enforced. Nonce2 is too small"
    );
    multiNonce[intendedSender][queue] = nonce;
  }

  function execute(
    address to,
    bytes memory data,
    uint256 gasLimit,
    address sender
  ) internal returns (bool success) {
    bytes memory full = abi.encodePacked(data, sender);
    assembly {
      success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
    }
  }

  function verifyInvocationSignature(SignedInvocation memory signedInvocation)
    public
    view
    returns (address)
  {
    bytes32 sigHash = getInvocationsTypedDataHash(signedInvocation.invocations);
    address recoveredSignatureSigner = recover(sigHash, signedInvocation.signature);
    return recoveredSignatureSigner;
  }

  function verifyDelegationSignature(SignedDelegation memory signedDelegation)
    public
    view
    returns (address)
  {
    Delegation memory delegation = signedDelegation.delegation;
    bytes32 sigHash = getDelegationTypedDataHash(delegation);
    address recoveredSignatureSigner = recover(sigHash, signedDelegation.signature);
    return recoveredSignatureSigner;
  }

  function getDelegationTypedDataHash(Delegation memory delegation) public view returns (bytes32) {
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainHash, GET_DELEGATION_PACKETHASH(delegation))
    );
    return digest;
  }

  function getInvocationsTypedDataHash(Invocations memory invocations)
    public
    view
    returns (bytes32)
  {
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainHash, GET_INVOCATIONS_PACKETHASH(invocations))
    );
    return digest;
  }

  function getEIP712DomainHash(
    string memory contractName,
    string memory version,
    uint256 chainId,
    address verifyingContract
  ) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(contractName)),
      keccak256(bytes(version)),
      chainId,
      verifyingContract
    );
    return keccak256(encoded);
  }

  function _msgSender() internal view virtual returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT

contract ECRecovery {
  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT
import "./ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
  string name;
  string version;
  uint256 chainId;
  address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
  "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Invocation {
  Transaction transaction;
  SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256(
  "Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Invocations {
  Invocation[] batch;
  ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256(
  "Invocations(Invocation[] batch,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct SignedInvocation {
  Invocations invocations;
  bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256(
  "SignedInvocation(Invocations invocations,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Transaction {
  address to;
  uint256 gasLimit;
  bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256(
  "Transaction(address to,uint256 gasLimit,bytes data)"
);

struct ReplayProtection {
  uint256 nonce;
  uint256 queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256("ReplayProtection(uint nonce,uint queue)");

struct Delegation {
  address delegate;
  bytes32 authority;
  Caveat[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256(
  "Delegation(address delegate,bytes32 authority,Caveat[] caveats)Caveat(address enforcer,bytes terms)"
);

struct Caveat {
  address enforcer;
  bytes terms;
}

bytes32 constant CAVEAT_TYPEHASH = keccak256("Caveat(address enforcer,bytes terms)");

struct SignedDelegation {
  Delegation delegation;
  bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256(
  "SignedDelegation(Delegation delegation,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)"
);

struct IntentionToRevoke {
  bytes32 delegationHash;
}

bytes32 constant INTENTIONTOREVOKE_TYPEHASH = keccak256(
  "IntentionToRevoke(bytes32 delegationHash)"
);

struct SignedIntentionToRevoke {
  bytes signature;
  IntentionToRevoke intentionToRevoke;
}

bytes32 constant SIGNEDINTENTIONTOREVOKE_TYPEHASH = keccak256(
  "SignedIntentionToRevoke(bytes signature,IntentionToRevoke intentionToRevoke)IntentionToRevoke(bytes32 delegationHash)"
);

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {
  // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

  function GET_EIP712DOMAIN_PACKETHASH(EIP712Domain memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      EIP712DOMAIN_TYPEHASH,
      _input.name,
      _input.version,
      _input.chainId,
      _input.verifyingContract
    );

    return keccak256(encoded);
  }

  function GET_INVOCATION_PACKETHASH(Invocation memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      INVOCATION_TYPEHASH,
      GET_TRANSACTION_PACKETHASH(_input.transaction),
      GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
    );

    return keccak256(encoded);
  }

  function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(SignedDelegation[] memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded;
    for (uint256 i = 0; i < _input.length; i++) {
      encoded = bytes.concat(encoded, GET_SIGNEDDELEGATION_PACKETHASH(_input[i]));
    }

    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_INVOCATIONS_PACKETHASH(Invocations memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      INVOCATIONS_TYPEHASH,
      GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
      GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
    );

    return keccak256(encoded);
  }

  function GET_INVOCATION_ARRAY_PACKETHASH(Invocation[] memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded;
    for (uint256 i = 0; i < _input.length; i++) {
      encoded = bytes.concat(encoded, GET_INVOCATION_PACKETHASH(_input[i]));
    }

    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_SIGNEDINVOCATION_PACKETHASH(SignedInvocation memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded = abi.encode(
      SIGNEDINVOCATION_TYPEHASH,
      GET_INVOCATIONS_PACKETHASH(_input.invocations),
      keccak256(_input.signature)
    );

    return keccak256(encoded);
  }

  function GET_TRANSACTION_PACKETHASH(Transaction memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      TRANSACTION_TYPEHASH,
      _input.to,
      _input.gasLimit,
      keccak256(_input.data)
    );

    return keccak256(encoded);
  }

  function GET_REPLAYPROTECTION_PACKETHASH(ReplayProtection memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded = abi.encode(REPLAYPROTECTION_TYPEHASH, _input.nonce, _input.queue);

    return keccak256(encoded);
  }

  function GET_DELEGATION_PACKETHASH(Delegation memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      DELEGATION_TYPEHASH,
      _input.delegate,
      _input.authority,
      GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
    );

    return keccak256(encoded);
  }

  function GET_CAVEAT_ARRAY_PACKETHASH(Caveat[] memory _input) public pure returns (bytes32) {
    bytes memory encoded;
    for (uint256 i = 0; i < _input.length; i++) {
      encoded = bytes.concat(encoded, GET_CAVEAT_PACKETHASH(_input[i]));
    }

    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_CAVEAT_PACKETHASH(Caveat memory _input) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(CAVEAT_TYPEHASH, _input.enforcer, keccak256(_input.terms));

    return keccak256(encoded);
  }

  function GET_SIGNEDDELEGATION_PACKETHASH(SignedDelegation memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded = abi.encode(
      SIGNEDDELEGATION_TYPEHASH,
      GET_DELEGATION_PACKETHASH(_input.delegation),
      keccak256(_input.signature)
    );

    return keccak256(encoded);
  }

  function GET_INTENTIONTOREVOKE_PACKETHASH(IntentionToRevoke memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded = abi.encode(INTENTIONTOREVOKE_TYPEHASH, _input.delegationHash);

    return keccak256(encoded);
  }

  function GET_SIGNEDINTENTIONTOREVOKE_PACKETHASH(SignedIntentionToRevoke memory _input)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded = abi.encode(
      SIGNEDINTENTIONTOREVOKE_TYPEHASH,
      keccak256(_input.signature),
      GET_INTENTIONTOREVOKE_PACKETHASH(_input.intentionToRevoke)
    );

    return keccak256(encoded);
  }
  // END EIP712 AUTOGENERATED BODY
}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "../TypesAndDecoders.sol";

abstract contract CaveatEnforcer {
  function enforceCaveat(
    bytes calldata terms,
    Transaction calldata tx,
    bytes32 delegationHash
  ) public virtual returns (bool);
}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CaveatEnforcer.sol";
import "../Delegatable.sol";

abstract contract RevokableOwnableDelegatable is Ownable, CaveatEnforcer, Delegatable {
  constructor(string memory name) Delegatable(name, "1") {}

  mapping(bytes32 => bool) isRevoked;

  function enforceCaveat(
    bytes calldata terms,
    Transaction calldata transaction,
    bytes32 delegationHash
  ) public view virtual override returns (bool) {
    require(!isRevoked[delegationHash], "Delegation has been revoked");

    // Owner methods are not delegatable in this contract:
    bytes4 targetSig = bytes4(transaction.data[0:4]);

    // transferOwnership(address newOwner)
    require(targetSig != 0xf2fde38b, "transferOwnership is not delegatable");

    // renounceOwnership()
    require(targetSig != 0x79ba79d8, "renounceOwnership is not delegatable");

    return true;
  }

  function revokeDelegation(
    SignedDelegation calldata signedDelegation,
    SignedIntentionToRevoke calldata signedIntentionToRevoke
  ) public {
    address signer = verifyDelegationSignature(signedDelegation);
    address revocationSigner = verifyIntentionToRevokeSignature(signedIntentionToRevoke);
    require(signer == revocationSigner, "Only the signer can revoke a delegation");

    bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(signedDelegation);
    isRevoked[delegationHash] = true;
  }

  function verifyIntentionToRevokeSignature(SignedIntentionToRevoke memory signedIntentionToRevoke)
    public
    view
    returns (address)
  {
    IntentionToRevoke memory intentionToRevoke = signedIntentionToRevoke.intentionToRevoke;
    bytes32 sigHash = getIntentionToRevokeTypedDataHash(intentionToRevoke);
    address recoveredSignatureSigner = recover(sigHash, signedIntentionToRevoke.signature);
    return recoveredSignatureSigner;
  }

  function getIntentionToRevokeTypedDataHash(IntentionToRevoke memory intentionToRevoke)
    public
    view
    returns (bytes32)
  {
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainHash, GET_INTENTIONTOREVOKE_PACKETHASH(intentionToRevoke))
    );
    return digest;
  }

  /**
   * This is boilerplate that must be added to any Delegatable contract if it also inherits
   * from another class that also implements _msgSender().
   */
  function _msgSender()
    internal
    view
    virtual
    override(Delegatable, Context)
    returns (address sender)
  {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICitizenAlpha } from "../interfaces/ICitizenAlpha.sol";

/**
 * @title Notary
 * @author Kames Geraghty
 * @notice Notary is a minimal AccessControl layer for Citizen issuance.
 */
contract Notary is AccessControl {
  /// @notice CitizenAlpha instance
  address private _citizenAlpha;

  /// @notice Notary Role
  bytes32 private constant NOTARY = keccak256("NOTARY");

  /**
   * @notice Notary Constructor
   * @dev Set CitizenAlpha instance and set start Notaries.
   * @param _citizenAlpha_ CitizenAlpha instance
   * @param _notaries Array of Notaries
   */
  constructor(address _citizenAlpha_, address[] memory _notaries) {
    _citizenAlpha = _citizenAlpha_;
    _setupRole(NOTARY, address(this));
    for (uint256 i = 0; i < _notaries.length; i++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _notaries[i]);
      _setupRole(NOTARY, _notaries[i]);
    }
    _setRoleAdmin(NOTARY, DEFAULT_ADMIN_ROLE);
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function getCitizenAlpha() external view returns (address) {
    return _citizenAlpha;
  }

  /**
   * @notice Check Notary status
   * @param citizen address
   * @return status bool
   */
  function isNotary(address citizen) external view returns (bool status) {
    return hasRole(NOTARY, citizen);
  }

  /**
   * @notice Issue Citizenship
   * @param to address
   */
  function issue(address to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _issue(to);
  }

  /**
   * @notice Batch issue Citizenships
   * @param to address
   */
  function issueBatch(address[] calldata to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < to.length; i++) {
      _issue(to[i]);
    }
  }

  /**
   * @notice Revoke Citizenship
   * @param from address
   */
  function revoke(address from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _revoke(from);
  }

  /**
   * @notice Batch Revoke Citizenships
   * @param from address
   */
  function revokeBatch(address[] calldata from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < from.length; i++) {
      _revoke(from[i]);
    }
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _issue(address _to) internal {
    ICitizenAlpha(_citizenAlpha).issue(_to);
  }

  function _revoke(address _from) internal {
    ICitizenAlpha(_citizenAlpha).revoke(_from);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Notary } from "../Notary/Notary.sol";
import { RevokableOwnableDelegatable } from "../Delegatable/caveat-enforcers/RevokableOwnableDelegatable.sol";

/**
 * @title NotaryServiceDelegatable
 * @author Kames Geraghty
 * @notice Delegatable off-chain Citizenship issuance permissions.
 */
contract NotaryServiceDelegatable is RevokableOwnableDelegatable {
  /// @notice CitizenAlpha instance
  address private immutable _citizenAlpha;

  constructor(address _citizenAlpha_) RevokableOwnableDelegatable("NotaryServiceDelegatable") {
    _citizenAlpha = _citizenAlpha_;
  }

  /**
   * @notice Get Notary instance
   * @return notary address
   */
  function getNotary() external view returns (address notary) {
    return _citizenAlpha;
  }

  /**
   * @notice Issue Citizenship via Notary exeuction
   * @dev Inteneded to be used with Delegatable.eth invoke for third-party execution.
   * @param newCitizen address
   */
  function issue(address newCitizen) external {
    require(owner() == _msgSender(), "NotaryServiceDelegatable:not-authorized");
    Notary(_citizenAlpha).issue(newCitizen);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICitizenAlpha {
  function ownerOf(uint256 _id) external view returns (address owner);

  function issue(address _citizen) external;

  function revoke(address _citizen) external;

  function getId(address citizen) external view returns (uint256);

  function getLink(address citizen) external view returns (address issuer);

  function hasRole(bytes32 role, address citizen) external view returns (bool);
}