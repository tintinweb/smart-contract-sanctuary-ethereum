// SPDX-License-Identifier: GPL-3.0

import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Module } from "src/module/Module.sol";
import { ModuleConfig } from "src/module/governance-pool/ModuleConfig.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { Clones } from "openzeppelin/proxy/Clones.sol";

pragma solidity ^0.8.19;

contract NounsFactory is Ownable {
  /// The name of this contract
  string public constant name = "Federation Governance Pool Factory v0.1";

  /// Emitted when a new clone is created
  event Created(address addr);

  /// Emitted when dependency addresses are updated
  event AddressesUpdated(
    address impl, address reliquary, address delegateCash, address factValidator
  );

  /// Emitted when the max base fee refund is updated for pools
  event MaxBaseFeeRefundUpdated();

  /// Emitted when fee config is updated
  event FeeConfigUpdated();

  /// Emitted when useStartBlockFromPropId is updated
  event StartBlockSnapshotFromPropId(uint256 pId);

  /// PoolConfig is the structure of cfg for a Nouns Governance Pool
  struct PoolConfig {
    /// The base wallet address for this module
    address base;
    /// The address of the DAO we are casting votes against
    address dao;
    /// The address of the token used for voting in the external DAO
    address token;
    /// The minimum bid accepted to cast a vote
    uint256 reservePrice;
    /// The minimum percent difference between the last bid placed for a
    /// proposal vote and the current one
    uint256 minBidIncrementPercentage;
  }

  /// The address of the implementation contract
  address public impl;

  /// The address of the relic reliquary
  address public reliquary;

  /// The address of the delegate cash registry
  address public dcash;

  /// The address of the module fact validator
  address public factValidator;

  /// The address that receives any configured protocol fee
  address public feeRecipient;

  /// bps as parts per 10_000, i.e. 10% = 1000
  uint256 public feeBPS;

  /// max base fee to refund callers who cast votes
  uint256 public maxBaseFeeRefund;

  /// whether to use startBlock or creationBlock for voting power snapshots
  uint256 useStartBlockFromPropId;

  constructor(
    address _impl,
    address _reliquary,
    address _dcash,
    address _factValidator,
    address _feeRecipient,
    uint256 _feeBPS,
    uint256 _maxBaseFeeRefund,
    uint256 _useStartBlockFromPropId
  ) {
    impl = _impl;
    reliquary = _reliquary;
    dcash = _dcash;
    factValidator = _factValidator;
    feeRecipient = _feeRecipient;
    feeBPS = _feeBPS;
    maxBaseFeeRefund = _maxBaseFeeRefund;
    useStartBlockFromPropId = _useStartBlockFromPropId;
  }

  /// Deploy a new Nouns Governance Pool
  /// @param _cfg Factory pool config
  /// @param _castWindow The number of blocks before a proposal voting period ends that a governance pool vote can be cast. @default _castWindow 150 (~30 minutes)
  /// @param _tip The amount of ETH to tip the relayer for casting a vote. @default _tip 0.0025 ethe
  /// @param _reason The reason used when voting on proposals
  function clone(PoolConfig memory _cfg, uint256 _castWindow, uint256 _tip, string calldata _reason)
    external
    payable
    returns (address)
  {
    address inst = Clones.clone(impl);

    // default values
    if (_castWindow == 0) {
      _castWindow = 150;
    }

    if (_tip == 0) {
      _tip = 0.0025 ether;
    }

    ModuleConfig.Config memory cfg = ModuleConfig.Config(
      _cfg.base,
      _cfg.dao,
      _cfg.token,
      feeRecipient,
      _cfg.reservePrice,
      1, // castWaitBlocks
      _cfg.minBidIncrementPercentage,
      _castWindow,
      _tip,
      feeBPS,
      maxBaseFeeRefund,
      0, // maxProver version
      reliquary,
      dcash,
      factValidator,
      useStartBlockFromPropId,
      _reason
    );

    Module(inst).init{ value: msg.value }(abi.encode(cfg));
    emit Created(inst);

    return inst;
  }

  /// Management function to update dependency addresses
  function setAddresses(
    address _impl,
    address _reliquary,
    address _delegateCash,
    address _factValidator
  ) external onlyOwner {
    require(_impl != address(0), "invalid implementation addr");
    require(_reliquary != address(0), "invalid reliquary addr");
    require(_delegateCash != address(0), "invalid delegate cash registry addr");
    require(_factValidator != address(0), "invalid fact validator addr");

    impl = _impl;
    reliquary = _reliquary;
    dcash = _delegateCash;
    factValidator = _factValidator;
    emit AddressesUpdated(_impl, _reliquary, _delegateCash, _factValidator);
  }

  function setMaxBaseFeeRefund(uint256 _maxBaseFeeRefund) external onlyOwner {
    maxBaseFeeRefund = _maxBaseFeeRefund;
    emit MaxBaseFeeRefundUpdated();
  }

  function setFeeConfig(address _feeRecipient, uint256 _feeBPS) external onlyOwner {
    feeRecipient = _feeRecipient;
    feeBPS = _feeBPS;
    emit FeeConfigUpdated();
  }

  function setUseStartBlockFromPropId(uint256 _useStartBlockFromPropId) external onlyOwner {
    useStartBlockFromPropId = _useStartBlockFromPropId;
    emit StartBlockSnapshotFromPropId(_useStartBlockFromPropId);
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// SPDX-License-Identifier: MIT
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.0;

/**
 * @title IBatchProver
 * @author Theori, Inc.
 * @notice IBatchProver is a standard interface implemented by some Relic provers.
 *         Supports proving multiple facts ephemerally or proving and storing
 *         them in the Reliquary.
 */
interface IBatchProver {
    /**
     * @notice prove multiple facts ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return facts the proven facts' information
     */
    function proveBatch(bytes calldata proof, bool store)
        external
        payable
        returns (Fact[] memory facts);
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../lib/Facts.sol";

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
interface IReliquary is IAccessControl {
    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    /**
     * @notice activates a pending prover once the delay has passed. Callable by anyone.
     * @param prover the address of the pending prover
     */
    function activateProver(address prover) external;

    /**
     * @notice Add credits to an account. Requires the CREDITS_ROLE.
     * @param user The account to which more credits should be granted
     * @param amount The number of credits to be added
     */
    function addCredits(address user, uint192 amount) external;

    /**
     * @notice Add/propose a new prover to prove facts. Requires the ADD_PROVER_ROLE.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external;

    /**
     * @notice Add/update a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     * @param ts The new block timestamp at which the subscription expires
     */
    function addSubscriber(address user, uint64 ts) external;

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    /**
     * @notice Asserts that a particular block had a particular hash. Callable only from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    /**
     * @notice Require that an appropriate fee is paid for proving a fact
     * @param sender The account wanting to prove a fact
     * @dev The fee is derived from the prover which calls this  function
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be called by a prover
     */
    function checkProveFactFee(address sender) external payable;

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) external pure;

    /**
     * @notice Check how many credits a given account possesses
     * @param user The account in question
     * @return The number of credits
     */
    function credits(address user) external view returns (uint192);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable by address(0),
               for debug
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Query for associated information for a fact. Only callable by address(0), for debug
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8) external view returns (FeeInfo memory);

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    /**
     * @notice Query for associated information for a fact. Only callable from provers.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Determine the appropriate ETH fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getProveFactNativeFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getProveFactTokenFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate ETH fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function initialized() external view returns (bool);

    /**
     * @notice Check if an account has an active subscription
     * @param user The account in question
     * @return True if the account is active, otherwise false
     */
    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address)
        external
        view
        returns (ProverInfo memory);

    /**
     * @notice Remove credits from an account. Requires the CREDITS_ROLE.
     * @param user The account from which credits should be removed
     * @param amount The number of credits to be removed
     */
    function removeCredits(address user, uint192 amount) external;

    /**
     * @notice Remove a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     */
    function removeSubscriber(address user) external;

    /**
     * @notice Deletes the fact from the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external;

    /**
     * @notice Stop accepting proofs from this prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external;

    function setCredits(address user, uint192 amount) external;

    /**
     * @notice Adds the given information to the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    /**
     * @notice Sets the FeeInfo for a particular fee class. Requires the GOVERNANCE_ROLE.
     * @param cls The fee class
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers. Requires the
               ADD_PROVER_ROLE.
     */
    function setInitialized() external;

    /**
     * @notice Sets the FeeInfo for a particular prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover in question
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Sets the FeeInfo for block verification. Requires the GOVERNANCE_ROLE.
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice FeeInfo struct for block hash queries
     */
    function verifyBlockFeeInfo() external view returns (FeeInfo memory);

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev A fee may be required based on the factSig
     */
    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for associated information for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for the prover version for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev A fee may be required based on the factSig
     */
    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    /**
     * @notice Query for the prover version for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    /**
     * @notice Reverse mapping of version information to the unique prover able
     *         to issue statements with that version
     */
    function versions(uint64) external view returns (address);

    /**
     * @notice Extract accumulated fees. Requires the GOVERNANCE_ROLE.
     * @param token The ERC20 token from which to extract fees. Or the 0 address for
     *        native ETH
     * @param dest The address to which fees should be transferred
     */
    function withdrawFees(address token, address dest) external;
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

/**
 * @title Facts
 * @author Theori, Inc.
 * @notice Helper functions for fact classes (part of fact signature that determines fee).
 */
library Facts {
    uint8 internal constant NO_FEE = 0;

    /**
     * @notice construct a fact signature from a fact class and some unique data
     * @param cls the fact class (determines the fee)
     * @param data the unique data for the signature
     */
    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    /**
     * @notice extracts the fact class from a fact signature
     * @param factSig the input fact signature
     */
    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps Federation module functionality
interface Module {
  /// init is called when a new module is enabled from a base wallet
  function init(bytes calldata) external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import { Module } from "src/module/Module.sol";
import { ModuleConfig } from "src/module/governance-pool/ModuleConfig.sol";

/// GovernancePool Wraps governance pool module functionality
interface GovernancePool is Module {
  error InitExternalDAONotSet();
  error InitExternalTokenNotSet();
  error InitFeeRecipientNotSet();
  error InitCastWindowNotSet();
  error InitBaseWalletNotSet();

  error BidTooLow();
  error BidAuctionEnded();
  error BidInvalidSupport();
  error BidReserveNotMet();
  error BidProposalNotActive();
  error BidVoteAlreadyCast();
  error BidMaxBidExceeded();
  error BidModulePaused();

  error CastVoteBidDoesNotExist();
  error CastVoteNotInWindow();
  error CastVoteNoDelegations();
  error CastVoteMustWait();
  error CastVoteAlreadyCast();

  error ClaimOnlyBidder();
  error ClaimAlreadyRefunded();
  error ClaimNotRefundable();

  error WithdrawDelegateOrOwnerOnly();
  error WithdrawBidNotOffered();
  error WithdrawBidRefunded();
  error WithdrawVoteNotCast();
  error WithdrawPropIsActive();
  error WithdrawAlreadyClaimed();
  error WithdrawInvalidProof(string);
  error WithdrawNoBalanceAtPropStart();
  error WithdrawNoTokensDelegated();
  error WithdrawMaxProverVersion();

  /// Bid is the structure of an offer to cast a vote on a proposal
  struct Bid {
    /// The amount of ETH bid
    uint256 amount;
    /// The remaining amount of ETH left to be withdrawn
    uint256 remainingAmount;
    /// The remaining amount of votes left to withdraw proceeds from the pool
    uint256 remainingVotes;
    /// The block number the external proposal was created
    uint256 creationBlock;
    /// The block number the external proposal voting period started
    uint256 startBlock;
    /// The block number the external proposal voting period ends
    uint256 endBlock;
    /// the block number the bid was made
    uint256 bidBlock;
    /// The support value to cast if this bid wins
    uint256 support;
    /// The address of the bidder
    address bidder;
    /// Whether the vote was cast for this bid
    bool executed;
    /// Whether the bid was refunded
    bool refunded;
  }

  /// Emitted when a vote has been cast against an external proposal
  event VoteCast(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a bid has been placed
  event BidPlaced(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a refund has been claimed
  event RefundClaimed(
    address indexed dao, uint256 indexed propId, uint256 amount, address receiver
  );

  /// Emitted when proceeds have been withdrawn for a proposal
  event Withdraw(address indexed dao, address indexed receiver, uint256[] propId, uint256 amount);

  /// Emitted when a protocol fee has been applied when casting votes
  event ProtocolFeeApplied(address indexed recipient, uint256 amount);

  /// Bid on a proposal
  function bid(uint256, uint256) external payable;

  /// Cast a vote from the contract to external proposal
  function castVote(uint256) external;

  /// Claim a refund for a bid where the vote was not cast
  function claimRefund(uint256) external;

  /// Withdraw proceeds in proportion of delegation from a bid where the vote was cast
  /// A max of 5 props can be withdrawn from at once
  function withdraw(
    address _prover,
    address _delegator,
    uint256[] calldata _pId,
    uint256[] calldata _fee,
    bytes[] calldata _proof
  ) external payable returns (uint256);

  /// Get the bid for a proposal
  function getBid(uint256 _pId) external view returns (Bid memory);

  /// Returns whether an account has made a withdrawal for a proposal
  function withdrawn(uint256 _pId, address _account) external view returns (bool);

  /// Returns the next minimum bid amount for a proposal
  function minBidAmount(uint256 _pid) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

import { OwnableUpgradeable } from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { IDelegationRegistry } from "delegate-cash/IDelegationRegistry.sol";
import { IBatchProver } from "relic-sdk/packages/contracts/interfaces/IBatchProver.sol";
import { IReliquary } from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Wallet } from "src/wallet/Wallet.sol";

pragma solidity ^0.8.19;

// The storage slot index of the mapping containing Nouns token balance
bytes32 constant SLOT_INDEX_TOKEN_BALANCE = bytes32(uint256(4));

// The storage slot index of the mapping containing Nouns delegate addresses
bytes32 constant SLOT_INDEX_DELEGATE = bytes32(uint256(11));

abstract contract ModuleConfig is OwnableUpgradeable {
  /// Emitted when storage slots are updated
  event SlotsUpdated(bytes32 balanceSlot, bytes32 delegateSlot);

  /// Emitted when the config is updated
  event ConfigChanged();

  /// Returns if a lock is active for this module
  error ConfigModuleHasActiveLock();

  /// Config is the structure of cfg for a Governance Pool module
  struct Config {
    /// The base wallet address for this module
    address base;
    /// The address of the DAO we are casting votes against
    address externalDAO;
    /// The address of the token used for voting in the external DAO
    address externalToken;
    /// feeRecipient is the address that receives any configured protocol fee
    address feeRecipient;
    /// The minimum bid accepted to cast a vote
    uint256 reservePrice;
    /// castWaitBlocks prevents any votes from being cast until this time in blocks has passed
    uint256 castWaitBlocks;
    /// The minimum percent difference between the last bid placed for a
    /// proposal vote and the current one
    uint256 minBidIncrementPercentage;
    /// The window in blocks when a vote can be cast
    uint256 castWindow;
    /// The default tip configured for casting a vote
    uint256 tip;
    /// feeBPS as parts per 10_000, i.e. 10% = 1000
    uint256 feeBPS;
    /// The maximum amount of base fee that can be refunded when casting a vote
    uint256 maxBaseFeeRefund;
    /// max relic batch prover version; if 0 any prover version is accepted
    uint256 maxProverVersion;
    /// relic reliquary address
    address reliquary;
    /// delegate cash registry address
    address dcash;
    /// fact validator address
    address factValidator;
    /// in preparation for Nouns governance v2->v3 we need to know
    /// handle switching vote snapshots to a proposal's start block
    uint256 useStartBlockFromPropId;
    /// configurable vote reason
    string reason;
  }

  /// The storage slot index containing nouns token balance mappings
  bytes32 public balanceSlotIdx = SLOT_INDEX_TOKEN_BALANCE;

  /// The storage slot index containing nouns delegate mappings
  bytes32 public delegateSlotIdx = SLOT_INDEX_DELEGATE;

  /// The config of this module
  Config internal _cfg;

  modifier isNotLocked() {
    _isNotLocked();
    _;
  }

  /// Reverts if the module has an open lock
  function _isNotLocked() internal view virtual {
    if (Wallet(_cfg.base).hasActiveLock()) {
      revert ConfigModuleHasActiveLock();
    }
  }

  /// Management function to get this contracts config
  function getConfig() external view returns (Config memory) {
    return _cfg;
  }

  /// Management function to update the config post initialization
  function setConfig(Config memory _config) external onlyOwner isNotLocked {
    // fees cannot be updated after initialization
    _config.feeBPS = _cfg.feeBPS;
    _config.feeRecipient = _cfg.feeRecipient;

    _cfg = _validateConfig(_config);
    emit ConfigChanged();
  }

  function setTipAndRefund(uint256 _tip, uint256 _maxBaseFeeRefund) external onlyOwner isNotLocked {
    _cfg.tip = _tip;
    _cfg.maxBaseFeeRefund = _maxBaseFeeRefund;
    emit ConfigChanged();
  }

  /// Management function to set token storage slots for proof verification
  function setSlots(uint256 balanceSlot, uint256 delegateSlot) external onlyOwner isNotLocked {
    balanceSlotIdx = bytes32(balanceSlot);
    delegateSlotIdx = bytes32(delegateSlot);
    emit SlotsUpdated(balanceSlotIdx, delegateSlotIdx);
  }

  /// Management function to update dependency addresses
  function setAddresses(address _reliquary, address _delegateCash, address _factValidator)
    external
    onlyOwner
    isNotLocked
  {
    require(_reliquary != address(0), "invalid reliquary addr");
    require(_delegateCash != address(0), "invalid delegate cash registry addr");
    require(_factValidator != address(0), "invalid fact validator addr");

    _cfg.reliquary = _reliquary;
    _cfg.dcash = _delegateCash;
    _cfg.factValidator = _factValidator;
    emit ConfigChanged();
  }

  /// Management function to set a max required prover version
  /// Protects the pool in the event that relic is compromised
  function setMaxProverVersion(uint256 _version) external onlyOwner {
    _cfg.maxProverVersion = _version;
    emit ConfigChanged();
  }

  /// Management function to set the prop id for when we should start using
  /// proposal start blocks for voting snapshots
  function setUseStartBlockFromPropId(uint256 _pId) external onlyOwner {
    _cfg.useStartBlockFromPropId = _pId;
    emit ConfigChanged();
  }

  /// Management function to set vote reason
  function setReason(string calldata _reason) external onlyOwner {
    _cfg.reason = _reason;
    emit ConfigChanged();
  }

  /// Management function to reduce fees
  function setFeeBPS(uint256 _feeBPS) external onlyOwner {
    require(_feeBPS < _cfg.feeBPS, "fee cannot be increased");
    _cfg.feeBPS = _feeBPS;
    emit ConfigChanged();
  }

  /// Management function to update auction reserve price
  function setReservePrice(uint256 _reservePrice) external onlyOwner {
    require(_reservePrice > 0, "reserve cannot be 0");
    _cfg.reservePrice = _reservePrice;
    emit ConfigChanged();
  }

  /// Management function to update castWindow
  function setCastWindow(uint256 _castWindow) external onlyOwner {
    require(_castWindow > 0, "cast window 0");
    _cfg.castWindow = _castWindow;
    emit ConfigChanged();
  }

  /// Validates that the config is set properly and sets default values if necessary
  function _validateConfig(Config memory _config) internal pure returns (Config memory) {
    if (_config.castWindow == 0) {
      revert GovernancePool.InitCastWindowNotSet();
    }

    if (_config.externalDAO == address(0)) {
      revert GovernancePool.InitExternalDAONotSet();
    }

    if (_config.externalToken == address(0)) {
      revert GovernancePool.InitExternalTokenNotSet();
    }

    if (_config.feeBPS > 0 && _config.feeRecipient == address(0)) {
      revert GovernancePool.InitFeeRecipientNotSet();
    }

    if (_config.base == address(0)) {
      revert GovernancePool.InitBaseWalletNotSet();
    }

    // default reserve price
    if (_config.reservePrice == 0) {
      _config.reservePrice = 1 wei;
    }

    // default cast wait blocks 5 ~= 1 minute
    if (_config.castWaitBlocks == 0) {
      _config.castWaitBlocks = 5;
    }

    return _config;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps the functionality of a Federation base wallet
interface Wallet {
  error NotEnabled();
  error ModuleAlreadyInitialized();
  error TransactionReverted();
  error LockDurationRequestTooLong();
  error LockActive();

  event SetModule(address indexed module, bool enabled);

  event ExecuteTransaction(address indexed caller, address indexed target, uint256 value);

  event Received(uint256 indexed value, address indexed sender, bytes data);

  event RequestLock(address indexed module, uint256 duration);

  event ReleaseLock(address indexed module);

  event MaxLockDurationBlocksChanged(uint256 blocks);

  function initialize(address) external;

  function execute(address, uint256, bytes calldata) external returns (bytes memory);

  function setModule(address, bool) external;

  function moduleEnabled(address) external view returns (bool);

  function requestLock(uint256) external returns (uint256);

  function releaseLock() external;

  function hasActiveLock() external view returns (bool);

  function setMaxLockDurationBlocks(uint256 _blocks) external;

  function maxLockDurationBlocks() external view returns (uint256);
}