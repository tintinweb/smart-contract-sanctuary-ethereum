//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IEntitlementModule} from "./interfaces/IEntitlementModule.sol";
import {ZionRoleStorage} from "./storage/ZionRoleStorage.sol";
import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Events} from "./libraries/Events.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Constants} from "./libraries/Constants.sol";
import {PermissionTypes} from "./libraries/PermissionTypes.sol";
import {CreationLogic} from "./libraries/CreationLogic.sol";
import {Utils} from "./libraries/Utils.sol";
import {ISpaceManager} from "./interfaces/ISpaceManager.sol";
import {IPermissionRegistry} from "./interfaces/IPermissionRegistry.sol";

contract ZionRoleManager is Ownable, ZionRoleStorage {
  address internal immutable PERMISSION_REGISTRY;
  address internal SPACE_MANAGER;

  modifier onlySpaceManager() {
    if (msg.sender != SPACE_MANAGER) revert Errors.NotSpaceManager();
    _;
  }

  constructor(address permissionRegistry) {
    if (permissionRegistry == address(0)) revert Errors.InvalidParameters();
    PERMISSION_REGISTRY = permissionRegistry;
  }

  function setSpaceManager(address spaceManager) external onlyOwner {
    SPACE_MANAGER = spaceManager;
  }

  function createRole(
    uint256 spaceId,
    string memory name
  ) external onlySpaceManager returns (uint256) {
    return CreationLogic.createRole(spaceId, name, _rolesBySpaceId);
  }

  function createOwnerRole(
    uint256 spaceId
  ) external onlySpaceManager returns (uint256) {
    uint256 ownerRoleId = CreationLogic.createRole(
      spaceId,
      Constants.OWNER_ROLE_NAME,
      _rolesBySpaceId
    );

    DataTypes.Permission[] memory allPermissions = IPermissionRegistry(
      PERMISSION_REGISTRY
    ).getAllPermissions();
    uint256 permissionLen = allPermissions.length;

    for (uint256 i = 0; i < permissionLen; ) {
      _addPermissionToRole(spaceId, ownerRoleId, allPermissions[i]);
      unchecked {
        ++i;
      }
    }

    return ownerRoleId;
  }

  function addPermissionToRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external onlySpaceManager {
    _validateNotModifyOwner(permission);
    _addPermissionToRole(spaceId, roleId, permission);
  }

  function removePermissionFromRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external onlySpaceManager {
    _validateNotModifyOwner(permission);
    _removePermissionFromRole(spaceId, roleId, permission);
  }

  function modifyRoleName(
    uint256 spaceId,
    uint256 roleId,
    string calldata newRoleName
  ) external onlySpaceManager {
    // Owner role name cannot be modified
    if (Utils.stringEquals(newRoleName, Constants.OWNER_ROLE_NAME)) {
      revert Errors.InvalidParameters();
    }

    DataTypes.Role[] memory roles = _rolesBySpaceId[spaceId].roles;
    uint256 roleLen = roles.length;
    for (uint256 i = 0; i < roleLen; ) {
      if (roleId == roles[i].roleId) {
        if (!Utils.stringEquals(roles[i].name, newRoleName)) {
          _rolesBySpaceId[spaceId].roles[i].name = newRoleName;
        }
        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  function removeRole(
    uint256 spaceId,
    uint256 roleId
  ) external onlySpaceManager {
    DataTypes.Role[] storage roles = _rolesBySpaceId[spaceId].roles;

    uint256 roleLen = roles.length;

    for (uint256 i = 0; i < roleLen; ) {
      if (roleId == roles[i].roleId) {
        DataTypes.Permission[]
          memory permissions = _permissionsBySpaceIdByRoleId[spaceId][roleId];

        uint256 permissionLen = permissions.length;

        for (uint256 j = 0; j < permissionLen; ) {
          _removePermissionFromRole(spaceId, roleId, permissions[j]);
          unchecked {
            ++j;
          }
        }

        roles[i] = roles[roleLen - 1];
        roles.pop();
        break;
      }

      unchecked {
        ++i;
      }
    }
  }

  function getPermissionsBySpaceIdByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view returns (DataTypes.Permission[] memory) {
    return _permissionsBySpaceIdByRoleId[spaceId][roleId];
  }

  function getRolesBySpaceId(
    uint256 spaceId
  ) external view returns (DataTypes.Role[] memory) {
    return _rolesBySpaceId[spaceId].roles;
  }

  function getRoleBySpaceIdByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view returns (DataTypes.Role memory role) {
    DataTypes.Role[] memory roles = _rolesBySpaceId[spaceId].roles;
    uint256 roleLen = roles.length;

    for (uint256 i = 0; i < roleLen; ) {
      if (roleId == roles[i].roleId) {
        return roles[i];
      }

      unchecked {
        ++i;
      }
    }
  }

  function _addPermissionToRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) internal {
    CreationLogic.setPermission(
      spaceId,
      roleId,
      permission,
      _permissionsBySpaceIdByRoleId
    );
  }

  function _removePermissionFromRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) internal {
    DataTypes.Permission[] storage permissions = _permissionsBySpaceIdByRoleId[
      spaceId
    ][roleId];

    uint256 permissionLen = permissions.length;

    for (uint256 i = 0; i < permissionLen; ) {
      if (Utils.stringEquals(permission.name, permissions[i].name)) {
        permissions[i] = permissions[permissionLen - 1];
        permissions.pop();
        break;
      }

      unchecked {
        ++i;
      }
    }
  }

  function _validateNotModifyOwner(
    DataTypes.Permission memory permission
  ) internal view {
    if (
      keccak256(abi.encode(permission)) ==
      keccak256(
        abi.encode(
          IPermissionRegistry(PERMISSION_REGISTRY)
            .getPermissionByPermissionType(PermissionTypes.Owner)
        )
      )
    ) {
      revert Errors.InvalidParameters();
    }
  }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IEntitlementModule {
  /// @notice The name of the entitlement module
  function name() external view returns (string memory);

  /// @notice The type of the entitlement module
  function moduleType() external view returns (string memory);

  /// @notice The description of the entitlement module
  function description() external view returns (string memory);

  /// @notice Checks if a user has access to space or channel based on the entitlements it holds
  /// @param spaceId The id of the space
  /// @param channelId The id of the channel
  /// @param userAddress The address of the user
  /// @param permission The type of permission to check
  /// @return bool representing if the user has access or not
  function isEntitled(
    uint256 spaceId,
    uint256 channelId,
    address userAddress,
    DataTypes.Permission memory permission
  ) external view returns (bool);

  /// @notice Gets the list of entitlement data for a role
  function getEntitlementDataByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view returns (bytes[] memory);

  /// @notice Sets a new entitlement for a space
  function setSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external;

  /// @notice Adds a roleId to a channel
  function addRoleIdToChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external;

  /// @notice Removes an entitlement from a space
  function removeSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external;

  /// @notice Removes  a roleId from a channel
  function removeRoleIdFromChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external;

  function getUserRoles(
    uint256 spaceId,
    address user
  ) external view returns (DataTypes.Role[] memory);
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IPermissionRegistry {
  /// @notice Get the permission of a space
  /// @param permissionType The type of permission
  function getPermissionByPermissionType(
    bytes32 permissionType
  ) external view returns (DataTypes.Permission memory);

  /// @notice Get all permisions on the registry
  function getAllPermissions()
    external
    view
    returns (DataTypes.Permission[] memory);
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ISpaceManager {
  /// @notice Create a new space
  /// @param info The metadata for the space, name etc
  /// @param entitlementData Data to create additional role gated by tokens or specific users
  /// @param everyonePermissions The permissions to grant to the Everyone role
  function createSpace(
    DataTypes.CreateSpaceData calldata info,
    DataTypes.CreateSpaceEntitlementData calldata entitlementData,
    DataTypes.Permission[] calldata everyonePermissions
  ) external returns (uint256);

  /// @notice Create a channel within a space
  function createChannel(
    DataTypes.CreateChannelData memory data
  ) external returns (uint256);

  /// @notice Sets the default entitlement for a newly created space
  /// @param entitlementModuleAddress The address of the entitlement module
  function setDefaultUserEntitlementModule(
    address entitlementModuleAddress
  ) external;

  /// @notice Sets the default token entitlement for a newly created space
  /// @param entitlementModuleAddress The address of the entitlement module
  function setDefaultTokenEntitlementModule(
    address entitlementModuleAddress
  ) external;

  /// @notice Sets the address for the space nft
  /// @param spaceNFTAddress The address of the zion space nft
  function setSpaceNFT(address spaceNFTAddress) external;

  // @notice Adds or removes an entitlement module from the whitelist and from the space entitlements
  function whitelistEntitlementModule(
    string calldata spaceId,
    address entitlementModuleAddress,
    bool whitelist
  ) external;

  /// @notice add an entitlement to an entitlement module
  function addRoleToEntitlementModule(
    string calldata spaceId,
    address entitlementAddress,
    uint256 roleId,
    bytes memory data
  ) external;

  /// @notice Removes an entitlement from an entitlement module
  function removeEntitlement(
    string calldata spaceId,
    address entitlementModuleAddress,
    uint256 roleId,
    bytes memory data
  ) external;

  /// @notice adds an array of roleIds to a channel for a space
  function addRoleIdsToChannel(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata roleId
  ) external;

  function removeRoleIdsFromChannel(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata roleId
  ) external;

   /// @notice Create a new role on a space Id
  function createRole(
    string calldata spaceId,
    string calldata name
  ) external returns (uint256);

  /// @notice Create a new role with entitlement data
  function createRoleWithEntitlementData(
    string calldata spaceId,
    string calldata roleName,
    DataTypes.Permission[] calldata permissions,
    DataTypes.ExternalTokenEntitlement[] calldata tokenEntitlements, // For Token Entitlements
    address[] calldata users // For User Entitlements
  ) external returns (uint256);

  /// @notice Modify role with entitlement data
  function modifyRoleWithEntitlementData(
    string calldata spaceId,
    uint256 roleId,
    string calldata roleName,
    DataTypes.Permission[] calldata permissions,
    DataTypes.ExternalTokenEntitlement[] calldata tokenEntitlements, // For Token Entitlements
    address[] calldata users // For User Entitlements
  ) external returns (bool);

  /// @notice Adds a permission to a role
  function addPermissionToRole(
    string calldata spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external;

  /// @notice Removes a permission from a role
  function removePermissionFromRole(
    string calldata spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external;

  /// @notice Removes a role from a space, along with the permissions
  function removeRole(string calldata spaceId, uint256 roleId) external;

  /// @notice Checks if a user has access to space or channel based on the entitlements it holds
  /// @param spaceId The id of the space
  /// @param channelId The id of the channel
  /// @param user The address of the user
  /// @param permission The type of permission to check
  /// @return bool representing if the user has access or not
  function isEntitled(
    string calldata spaceId,
    string calldata channelId,
    address user,
    DataTypes.Permission memory permission
  ) external view returns (bool);

  /// @notice Get the space information by id.
  /// @param spaceId The id of the space
  /// @return SpaceInfo a struct representing the space info
  function getSpaceInfoBySpaceId(
    string calldata spaceId
  ) external view returns (DataTypes.SpaceInfo memory);

  /// @notice Get the channel info by channel id
  function getChannelInfoByChannelId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (DataTypes.ChannelInfo memory);

  /// @notice Returns an array of multiple space information objects
  /// @return SpaceInfo[] an array containing the space info
  function getSpaces() external view returns (DataTypes.SpaceInfo[] memory);

  /// @notice Returns an array of channels by space id
  function getChannelsBySpaceId(
    string memory spaceId
  ) external view returns (DataTypes.Channels memory);

  /// @notice Returns entitlements for a space
  /// @param spaceId The id of the space
  /// @return entitlementModules an array of entitlements
  function getEntitlementModulesBySpaceId(
    string calldata spaceId
  ) external view returns (address[] memory entitlementModules);

  /// @notice Returns if an entitlement module is whitelisted for a space
  function isEntitlementModuleWhitelisted(
    string calldata spaceId,
    address entitlementModuleAddress
  ) external view returns (bool);

  /// @notice Returns the entitlement info for a space
  function getEntitlementsInfoBySpaceId(
    string calldata spaceId
  ) external view returns (DataTypes.EntitlementModuleInfo[] memory);

  /// @notice Returns the space id by network id
  function getSpaceIdByNetworkId(
    string calldata networkId
  ) external view returns (uint256);

  /// @notice Returns the channel id by network id
  function getChannelIdByNetworkId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (uint256);

  /// @notice Returns the owner of the space by space id
  /// @param spaceId The space id
  /// @return ownerAddress The address of the owner of the space
  function getSpaceOwnerBySpaceId(
    string calldata spaceId
  ) external returns (address ownerAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
  uint8 internal constant MIN_NAME_LENGTH = 2;
  string internal constant DEFAULT_TOKEN_ENTITLEMENT_TAG =
    "zion-default-token-entitlement";
  uint8 internal constant MAX_NAME_LENGTH = 32;
  address internal constant EVERYONE_ADDRESS =
    0x0000000000000000000000000000000000000001;
  string internal constant OWNER_ROLE_NAME = "Owner";
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

library CreationLogic {
  function createSpace(
    DataTypes.CreateSpaceData calldata info,
    uint256 spaceId,
    address creator,
    mapping(bytes32 => uint256) storage _spaceIdByHash,
    mapping(uint256 => DataTypes.Space) storage _spaceById
  ) external {
    bytes32 networkHash = keccak256(bytes(info.spaceNetworkId));

    if (_spaceIdByHash[networkHash] != 0)
      revert Errors.SpaceAlreadyRegistered();

    _spaceIdByHash[networkHash] = spaceId;
    _spaceById[spaceId].spaceId = spaceId;
    _spaceById[spaceId].createdAt = block.timestamp;
    _spaceById[spaceId].name = info.spaceName;
    _spaceById[spaceId].networkId = info.spaceNetworkId;
    _spaceById[spaceId].creator = creator;
    _spaceById[spaceId].owner = creator;
  }

  function createChannel(
    DataTypes.CreateChannelData calldata info,
    uint256 spaceId,
    uint256 channelId,
    address creator,
    mapping(uint256 => DataTypes.Channels) storage _channelsBySpaceId,
    mapping(uint256 => mapping(bytes32 => uint256))
      storage _channelIdBySpaceIdByHash,
    mapping(uint256 => mapping(uint256 => DataTypes.Channel))
      storage _channelBySpaceIdByChannelId
  ) external {
    bytes32 networkHash = keccak256(bytes(info.channelNetworkId));

    if (_channelIdBySpaceIdByHash[spaceId][networkHash] != 0) {
      revert Errors.SpaceAlreadyRegistered();
    }

    _channelIdBySpaceIdByHash[spaceId][networkHash] = channelId;

    _channelBySpaceIdByChannelId[spaceId][channelId].channelId = channelId;
    _channelBySpaceIdByChannelId[spaceId][channelId].createdAt = block
      .timestamp;
    _channelBySpaceIdByChannelId[spaceId][channelId].networkId = info
      .channelNetworkId;
    _channelBySpaceIdByChannelId[spaceId][channelId].name = info.channelName;
    _channelBySpaceIdByChannelId[spaceId][channelId].creator = creator;

    _channelsBySpaceId[spaceId].channels.push(
      _channelBySpaceIdByChannelId[spaceId][channelId]
    );
  }

  function setPermission(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission,
    mapping(uint256 => mapping(uint256 => DataTypes.Permission[]))
      storage _permissionsBySpaceIdByRoleId
  ) internal {
    _permissionsBySpaceIdByRoleId[spaceId][roleId].push(permission);
  }

  function createRole(
    uint256 spaceId,
    string memory name,
    mapping(uint256 => DataTypes.Roles) storage _rolesBySpaceId
  ) internal returns (uint256) {
    uint256 roleId = _rolesBySpaceId[spaceId].idCounter++;
    _rolesBySpaceId[spaceId].roles.push(DataTypes.Role(roleId, name));
    return roleId;
  }

  function setEntitlement(
    uint spaceId,
    address entitlementModule,
    bool whitelist,
    mapping(uint256 => DataTypes.Space) storage _spaceById
  ) external {
    // set entitlement tag to space entitlement tags
    _spaceById[spaceId].hasEntitlement[entitlementModule] = whitelist;

    // set entitlement address to space entitlements
    if (whitelist) {
      _spaceById[spaceId].entitlementModules.push(entitlementModule);
    } else {
      uint256 len = _spaceById[spaceId].entitlementModules.length;
      for (uint256 i = 0; i < len; ) {
        if (_spaceById[spaceId].entitlementModules[i] == entitlementModule) {
          // Remove the entitlement address from the space entitlements
          _spaceById[spaceId].entitlementModules[i] = _spaceById[spaceId]
            .entitlementModules[len - 1];
          _spaceById[spaceId].entitlementModules.pop();
        }

        unchecked {
          ++i;
        }
      }
    }
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library Events {
  /**
   * @dev Emitted when a space is created
   * @param owner The address of the owner of the space
   * @param spaceNetworkId The id of the space
   */
  event CreateSpace(string indexed spaceNetworkId, address indexed owner);

  /**
   * @dev Emitted when a channel is created
   * @param spaceNetworkId The id of the space
   * @param channelNetworkId The id of the channel
   * @param owner The address of the creator of the channel
   */
  event CreateChannel(
    string indexed spaceNetworkId,
    string indexed channelNetworkId,
    address indexed owner
  );

  /**
   * @dev Emitted when a space access is updated
   * @param spaceNetworkId The id of the space
   * @param user The address of the user
   * @param disabled The disabled status
   */
  event SetSpaceAccess(
    string indexed spaceNetworkId,
    address indexed user,
    bool disabled
  );

  /**
   * @dev Emitted when a channel access is updated
   * @param spaceNetworkId The id of the space
   * @param channelNetworkId The id of the channel
   * @param user The address of the user
   * @param disabled The disabled status
   */
  event SetChannelAccess(
    string indexed spaceNetworkId,
    string indexed channelNetworkId,
    address indexed user,
    bool disabled
  );

  /**
   * @dev Emitted when the default entitlement module is set on the contract
   * @param entitlementAddress The address of the entitlement module
   */
  event DefaultEntitlementSet(address indexed entitlementAddress);

  /**
   * @dev Emitted when the space nft address is set on the contract
   * @param spaceNFTAddress The address of the space nft
   */
  event SpaceNFTAddressSet(address indexed spaceNFTAddress);

  /**
   * @dev Emitted when an entitlement module is white listed on a space
   * @param spaceNetworkId The id of the space
   * @param entitlementAddress The address of the entitlement module
   */
  event WhitelistEntitlementModule(
    string indexed spaceNetworkId,
    address indexed entitlementAddress,
    bool whitelist
  );

  /**
   * @dev Emitted when a role is created
   * @param spaceId The id of the space
   * @param roleId The id of the role
   * @param roleName The name of the role
   */
  event CreateRole(
    string indexed spaceId,
    uint256 indexed roleId,
    string indexed roleName,
    address creator
  );

  /**
   * @dev Emitted when a role is created
   * @param spaceId The id of the space
   * @param roleId The id of the role
   * @param roleName The name of the role
   */
  event CreateRoleWithEntitlementData(
    string indexed spaceId,
    uint256 indexed roleId,
    string indexed roleName,
    address creator
  );

  /**
   * @dev Emitted when a role is modified
   * @param spaceId The id of the space
   * @param roleId The id of the role
   */
  event ModifyRoleWithEntitlementData(
    string indexed spaceId,
    uint256 indexed roleId,
    address updater
  );

  /**
   * @dev Emitted when a role is updated
   * @param spaceId The id of the space
   * @param roleId The id of the role
   */
  event RemoveRole(
    string indexed spaceId,
    uint256 indexed roleId,
    address updater
  );

  /**
   * @dev Emitted when a role is updated
   * @param spaceId The id of the space
   * @param roleId The id of the role
   */
  event UpdateRole(
    string indexed spaceId,
    uint256 indexed roleId,
    address updater
  );

  /**
   * @dev Emitted when an entitlement module is added to a space
   * @param spaceId The id of the space
   * @param entitlementAddress The address of the entitlement module
   */
  event EntitlementModuleAdded(
    string indexed spaceId,
    address indexed entitlementAddress
  );

  /**
   * @dev Emitted when an entitlement module is removed from a space
   * @param spaceId The id of the space
   * @param entitlementAddress The address of the entitlement module
   */
  event EntitlementModuleRemoved(
    string indexed spaceId,
    address indexed entitlementAddress
  );
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Constants} from "../libraries/Constants.sol";
import {Errors} from "../libraries/Errors.sol";

library Utils {
  function stringEquals(
    string memory s1,
    string memory s2
  ) internal pure returns (bool) {
    bytes memory b1 = bytes(s1);
    bytes memory b2 = bytes(s2);
    uint256 l1 = b1.length;
    if (l1 != b2.length) return false;
    for (uint256 i = 0; i < l1; ) {
      if (b1[i] != b2[i]) return false;
      unchecked {
        ++i;
      }
    }
    return true;
  }

  function bytesEquals(bytes memory b1, bytes memory b2)
    internal pure returns (bool) {
    return keccak256(abi.encodePacked(b1)) == keccak256(abi.encodePacked(b2));
  }

  /// @notice validates the name of the space
  /// @param name The name of the space
  function validateName(string calldata name) internal pure {
    bytes memory byteName = bytes(name);

    if (
      byteName.length < Constants.MIN_NAME_LENGTH ||
      byteName.length > Constants.MAX_NAME_LENGTH
    ) revert Errors.NameLengthInvalid();

    uint256 byteNameLength = byteName.length;
    for (uint256 i = 0; i < byteNameLength; ) {
      if (
        (byteName[i] < "0" ||
          byteName[i] > "z" ||
          (byteName[i] > "9" && byteName[i] < "a")) &&
        byteName[i] != "." &&
        byteName[i] != "-" &&
        byteName[i] != "_" &&
        byteName[i] != " "
      ) revert Errors.NameContainsInvalidCharacters();
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "./../libraries/DataTypes.sol";

contract ZionRoleStorage {
  /// @notice mapping representing the role data by space id
  mapping(uint256 => DataTypes.Roles) internal _rolesBySpaceId;

  /// @notice mapping representing the permission data by space id by role id
  mapping(uint256 => mapping(uint256 => DataTypes.Permission[]))
    internal _permissionsBySpaceIdByRoleId;
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