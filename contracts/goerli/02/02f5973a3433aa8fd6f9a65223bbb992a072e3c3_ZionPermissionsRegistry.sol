// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "./libraries/DataTypes.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {PermissionTypes} from "./libraries/PermissionTypes.sol";
import {Errors} from "./libraries/Errors.sol";

contract ZionPermissionsRegistry is Ownable {
  /// @notice Mapping for convenience for finding the string from a defined enum of Zion specific permissions
  mapping(bytes32 => DataTypes.Permission) internal _permissionByPermissionHash;
  DataTypes.Permission[] internal _permissions;

  constructor() {
    setInitialPermissions();
  }

  function setInitialPermissions() internal {
    _setPermission(PermissionTypes.Read, DataTypes.Permission({name: "Read"}));
    _setPermission(
      PermissionTypes.Write,
      DataTypes.Permission({name: "Write"})
    );
    _setPermission(
      PermissionTypes.Invite,
      DataTypes.Permission({name: "Invite"})
    );
    _setPermission(
      PermissionTypes.Redact,
      DataTypes.Permission({name: "Redact"})
    );
    _setPermission(PermissionTypes.Ban, DataTypes.Permission({name: "Ban"}));
    _setPermission(PermissionTypes.Ping, DataTypes.Permission({name: "Ping"}));
    _setPermission(
      PermissionTypes.PinMessage,
      DataTypes.Permission({name: "PinMessage"})
    );
    _setPermission(
      PermissionTypes.ModifyChannelPermissions,
      DataTypes.Permission({name: "ModifyChannelPermissions"})
    );
    _setPermission(
      PermissionTypes.ModifyProfile,
      DataTypes.Permission({name: "ModifyProfile"})
    );
    _setPermission(
      PermissionTypes.AddRemoveChannels,
      DataTypes.Permission({name: "AddRemoveChannels"})
    );
    _setPermission(
      PermissionTypes.ModifySpacePermissions,
      DataTypes.Permission({name: "ModifySpacePermissions"})
    );
    _setPermission(
      PermissionTypes.ModifyChannelDefaults,
      DataTypes.Permission({name: "ModifyChannelDefaults"})
    );
    _setPermission(
      PermissionTypes.Owner,
      DataTypes.Permission({name: "Owner"})
    );
  }

  function addPermission(
    bytes32 permissionHash,
    DataTypes.Permission memory permission
  ) external onlyOwner {
    if (
      keccak256(
        abi.encodePacked(_permissionByPermissionHash[permissionHash].name)
      ) != keccak256(abi.encodePacked(""))
    ) revert Errors.PermissionAlreadyExists();
    _setPermission(permissionHash, permission);
  }

  function getAllPermissions()
    external
    view
    returns (DataTypes.Permission[] memory)
  {
    return _permissions;
  }

  function getPermissionByPermissionType(
    bytes32 permissionType
  ) external view returns (DataTypes.Permission memory) {
    return _permissionByPermissionHash[permissionType];
  }

  function _setPermission(
    bytes32 permissionType,
    DataTypes.Permission memory permission
  ) internal {
    _permissions.push(permission);
    _permissionByPermissionHash[permissionType] = permission;
  }
}

//SPDX-License-Identifier: Apache-20
pragma solidity ^0.8.0;

/**
 * @title DataTypes
 * @author HNT Labs
 *
 * @notice A standard library of data types used throughout the Zion Space Manager
 */
library DataTypes {
  /// @notice A struct representing a space
  /// @param spaceId The unique identifier of the space
  /// @param createdAt The timestamp of when the space was created
  /// @param networkSpaceId The unique identifier of the space on the matrix network
  /// @param name The name of the space
  /// @param creator The address of the creator of the space
  /// @param owner The address of the owner of the space
  /// @param rooms An array of rooms in the space
  /// @param entitlement An array of space entitlements
  /// @param entitlementTags An array of space entitlement tags
  struct Space {
    uint256 spaceId;
    uint256 createdAt;
    string networkId;
    string name;
    address creator;
    address owner;
    uint256 ownerRoleId;
    bool disabled;
    mapping(address => bool) hasEntitlement;
    address[] entitlementModules;
    Role[] roles;
  }

  struct Channel {
    uint256 channelId;
    uint256 createdAt;
    string networkId;
    string name;
    address creator;
    bool disabled;
  }

  struct Channels {
    uint256 idCounter;
    Channel[] channels;
  }

  /// @notice A struct representing minimal info for a space
  /// @param spaceId The unique identifier of the space
  /// @param createdAt The timestamp of when the space was created
  /// @param name The name of the space
  /// @param creator The address of the creator of the space
  /// @param owner The address of the owner of the space
  struct SpaceInfo {
    uint256 spaceId;
    string networkId;
    uint256 createdAt;
    string name;
    address creator;
    address owner;
    bool disabled;
  }

  struct ChannelInfo {
    uint256 channelId;
    string networkId;
    uint256 createdAt;
    string name;
    address creator;
    bool disabled;
  }

  struct Roles {
    uint256 idCounter;
    Role[] roles;
  }

  struct Role {
    uint256 roleId;
    string name;
  }

  struct Permission {
    string name;
  }

  /// @notice A struct representing minimal info for an entitlement module
  struct EntitlementModuleInfo {
    address addr;
    string name;
    string moduleType;
    string description;
  }

  struct ExternalToken {
    address contractAddress;
    uint256 quantity;
    bool isSingleToken;
    uint256 tokenId;
  }

  struct ExternalTokenEntitlement {
    ExternalToken[] tokens;
  }
  /// *********************************
  /// **************DTO****************
  /// *********************************

  /// @notice A struct containing the parameters for setting an existing role id to an entitlement module
  struct CreateRoleEntitlementData {
    uint256 roleId;
    address entitlementModule;
    bytes entitlementData;
  }

  /// @notice A struct containing the parameters for creating a role
  struct CreateRoleData {
    string name;
    string metadata;
    Permission[] permissions;
  }

  /// @notice A struct containing the parameters for creating a channel
  struct CreateChannelData {
    string spaceNetworkId;
    string channelName;
    string channelNetworkId;
    uint256[] roleIds;
  }

  /// @notice A struct containing the parameters required for creating a space
  /// @param spaceName The name of the space
  /// @param networkId The network id of the space
  struct CreateSpaceData {
    string spaceName;
    string spaceNetworkId;
    string spaceMetadata;
  }

  /// @notice A struct containing the parameters required for creating a space with a  token entitlement
  struct CreateSpaceEntitlementData {
    //The role and permissions to create for the associated users or token entitlements
    string roleName;
    Permission[] permissions;
    ExternalTokenEntitlement[] externalTokenEntitlements;
    address[] users;
  }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library Errors {
  error InvalidParameters();
  error NameLengthInvalid();
  error NameContainsInvalidCharacters();
  error SpaceAlreadyRegistered();
  error ChannelAlreadyRegistered();
  error NotSpaceOwner();
  error NotSpaceManager();
  error EntitlementAlreadyWhitelisted();
  error EntitlementModuleNotSupported();
  error EntitlementNotWhitelisted();
  error DefaultEntitlementModuleNotSet();
  error SpaceNFTNotSet();
  error DefaultPermissionsManagerNotSet();
  error SpaceDoesNotExist();
  error ChannelDoesNotExist();
  error PermissionAlreadyExists();
  error NotAllowed();
  error RoleDoesNotExist();
  error RoleAlreadyExists();
  error AddRoleFailed();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library PermissionTypes {
  bytes32 public constant Read = keccak256("Read");
  bytes32 public constant Write = keccak256("Write");
  bytes32 public constant Invite = keccak256("Invite");
  bytes32 public constant Redact = keccak256("Redact");
  bytes32 public constant Ban = keccak256("Ban");
  bytes32 public constant Ping = keccak256("Ping");
  bytes32 public constant PinMessage = keccak256("PinMessage");
  bytes32 public constant ModifyChannelPermissions =
    keccak256("ModifyChannelPermissions");
  bytes32 public constant ModifyProfile = keccak256("ModifyProfile");
  bytes32 public constant Owner = keccak256("Owner");
  bytes32 public constant AddRemoveChannels = keccak256("AddRemoveChannels");
  bytes32 public constant ModifySpacePermissions =
    keccak256("ModifySpacePermissions");
  bytes32 public constant ModifyChannelDefaults =
    keccak256("ModifyChannelDefaults");
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