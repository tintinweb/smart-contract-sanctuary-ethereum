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

interface IRoleManager {
  function setSpaceManager(address spaceManager) external;

  function createRole(
    uint256 spaceId,
    string memory name
  ) external returns (uint256);

  function createOwnerRole(uint256 spaceId) external returns (uint256);

  function addPermissionToRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external;

  function removePermissionFromRole(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) external;

  function removeRole(uint256 spaceId, uint256 roleId) external;

  function modifyRoleName(
    uint256 spaceId,
    uint256 roleId,
    string calldata newRoleName
  ) external;

  /// @notice Returns the permissions for a role in a space
  function getPermissionsBySpaceIdByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view returns (DataTypes.Permission[] memory);

  /// @notice Returns the roles of a space
  function getRolesBySpaceId(
    uint256 spaceId
  ) external view returns (DataTypes.Role[] memory);

  /// @notice Returns the role of a space by id
  function getRoleBySpaceIdByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view returns (DataTypes.Role memory);
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Errors} from "../libraries/Errors.sol";
import {IEntitlementModule} from "../interfaces/IEntitlementModule.sol";

abstract contract EntitlementModuleBase is ERC165, IEntitlementModule {
  address public immutable _spaceManager;
  address public immutable _roleManager;
  address public immutable _permisionRegistry;

  string public name;
  string public description;
  string public moduleType;

  modifier onlySpaceManager() {
    if (msg.sender != _spaceManager) revert Errors.NotSpaceManager();
    _;
  }

  constructor(
    string memory name_,
    string memory description_,
    string memory moduleType_,
    address spaceManager_,
    address roleManager_,
    address permissionRegistry_
  ) {
    _verifyParameters(spaceManager_);

    name = name_;
    description = description_;
    moduleType = moduleType_;
    _spaceManager = spaceManager_;
    _roleManager = roleManager_;
    _permisionRegistry = permissionRegistry_;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165) returns (bool) {
    return
      interfaceId == type(IEntitlementModule).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function _verifyParameters(address value) internal pure {
    if (value == address(0)) {
      revert Errors.InvalidParameters();
    }
  }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ISpaceManager} from "../../interfaces/ISpaceManager.sol";
import {IRoleManager} from "../../interfaces/IRoleManager.sol";

import {DataTypes} from "../../libraries/DataTypes.sol";
import {Constants} from "../../libraries/Constants.sol";
import {PermissionTypes} from "../../libraries/PermissionTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

import {EntitlementModuleBase} from "../EntitlementModuleBase.sol";
import {Utils} from "../../libraries/Utils.sol";

contract UserGrantedEntitlementModule is EntitlementModuleBase {
  struct Entitlement {
    address grantedBy;
    uint256 grantedTime;
    uint256 roleId;
  }

  // spaceId => user => entitlement
  mapping(uint256 => mapping(address => Entitlement[]))
    internal _entitlementsByUserBySpaceId;

  // spaceId => roleId => user[]
  mapping(uint256 => mapping(uint256 => address[]))
    internal _usersByRoleIdBySpaceId;

  //spaceId => channelId => roleId[]
  mapping(uint256 => mapping(uint256 => uint256[]))
    internal _rolesByChannelIdBySpaceId;

  // spaceId => roleId => entitlementData[]
  mapping(uint256 => mapping(uint256 => bytes[]))
    internal _entitlementDataBySpaceIdByRoleId;

  constructor(
    string memory name_,
    string memory description_,
    string memory moduleType_,
    address spaceManager_,
    address roleManager_,
    address permissionRegistry_
  )
    EntitlementModuleBase(
      name_,
      description_,
      moduleType_,
      spaceManager_,
      roleManager_,
      permissionRegistry_
    )
  {}

  function getEntitlementDataByRoleId(
    uint256 spaceId,
    uint256 roleId
  ) external view override returns (bytes[] memory) {
    return _entitlementDataBySpaceIdByRoleId[spaceId][roleId];
  }

  function setSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external override onlySpaceManager {
    address user = abi.decode(entitlementData, (address));

    _usersByRoleIdBySpaceId[spaceId][roleId].push(user);
    _entitlementsByUserBySpaceId[spaceId][user].push(
      Entitlement(user, block.timestamp, roleId)
    );
    _entitlementDataBySpaceIdByRoleId[spaceId][roleId].push(entitlementData);
  }

  function addRoleIdToChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external override onlySpaceManager {
    // check for duplicate role ids
    uint256[] memory roles = _rolesByChannelIdBySpaceId[spaceId][channelId];

    for (uint256 i = 0; i < roles.length; i++) {
      if (roles[i] == roleId) {
        revert Errors.RoleAlreadyExists();
      }
    }

    //add the roleId to the mapping for the channel
    _rolesByChannelIdBySpaceId[spaceId][channelId].push(roleId);
  }

  function isEntitled(
    uint256 spaceId,
    uint256 channelId,
    address user,
    DataTypes.Permission memory permission
  ) public view override returns (bool) {
    //If we are checking for a channel
    if (channelId > 0) {
      //Get all the allowed roles for that channel
      uint256[] memory roleIdsForChannel = _rolesByChannelIdBySpaceId[spaceId][
        channelId
      ];

      //For each role, check if the user has that role
      for (uint256 i = 0; i < roleIdsForChannel.length; i++) {
        uint256 roleId = roleIdsForChannel[i];

        //Iterate through all the entitlements for that user and see if it matches the roleId,
        //if so, add it to the validEntitlementsForUserForChannel array

        //Get all the entitlements for that user
        Entitlement[] memory entitlementsForUser = _entitlementsByUserBySpaceId[
          spaceId
        ][user];

        //Plus the everyone entitlement
        Entitlement[]
          memory everyoneEntitlements = _entitlementsByUserBySpaceId[spaceId][
            Constants.EVERYONE_ADDRESS
          ];

        //Combine them both for all valid entitlements we want to check against
        Entitlement[] memory validEntitlementsForUserForChannel = concatArrays(
          everyoneEntitlements,
          entitlementsForUser
        );

        if (validEntitlementsForUserForChannel.length > 0) {
          for (
            uint256 j = 0;
            j < validEntitlementsForUserForChannel.length;
            j++
          ) {
            //If the roleId matches, check if that role has the permission we are looking for
            if (validEntitlementsForUserForChannel[j].roleId == roleId) {
              if (
                _checkEntitlementHasPermission(
                  spaceId,
                  validEntitlementsForUserForChannel[j],
                  permission
                )
              ) {
                return true;
              }
            }
          }
        }
      }
    } else {
      //Get everyone entitlement for the space
      Entitlement[] memory everyoneEntitlements = _entitlementsByUserBySpaceId[
        spaceId
      ][Constants.EVERYONE_ADDRESS];

      //Get all the entitlements for this specific user
      Entitlement[] memory userEntitlements = _entitlementsByUserBySpaceId[
        spaceId
      ][user];

      //Combine them both for all valid entitlements we want to check against
      Entitlement[] memory validEntitlementsForUserForSpace = concatArrays(
        everyoneEntitlements,
        userEntitlements
      );

      //Check if any of the entitlements' roles have the permission we are checking for
      for (uint256 i = 0; i < validEntitlementsForUserForSpace.length; i++) {
        if (
          _checkEntitlementHasPermission(
            spaceId,
            validEntitlementsForUserForSpace[i],
            permission
          )
        ) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if any of the entitlements contain the permission we are checking for
  function _checkEntitlementHasPermission(
    uint256 spaceId,
    Entitlement memory entitlement,
    DataTypes.Permission memory permission
  ) internal view returns (bool) {
    uint256 roleId = entitlement.roleId;

    DataTypes.Permission[] memory permissions = IRoleManager(_roleManager)
      .getPermissionsBySpaceIdByRoleId(spaceId, roleId);
    for (uint256 p = 0; p < permissions.length; p++) {
      if (
        keccak256(abi.encodePacked(permissions[p].name)) ==
        keccak256(abi.encodePacked(permission.name))
      ) {
        return true;
      }
    }

    return false;
  }

  function removeSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external override onlySpaceManager {
    address user = abi.decode(entitlementData, (address));

    uint256 entitlementLen = _entitlementsByUserBySpaceId[spaceId][user].length;
    //Iterate through all the entitlements for that user and see if it matches the roleId,
    //if so
    for (uint256 j = 0; j < entitlementLen; j++) {
      if (_entitlementsByUserBySpaceId[spaceId][user][j].roleId == roleId) {
        _entitlementsByUserBySpaceId[spaceId][user][
          j
        ] = _entitlementsByUserBySpaceId[spaceId][user][entitlementLen - 1];

        _entitlementsByUserBySpaceId[spaceId][user].pop();
      }
    }

    uint256 usersLen = _usersByRoleIdBySpaceId[spaceId][roleId].length;

    for (uint256 k = 0; k < usersLen; k++) {
      if (_usersByRoleIdBySpaceId[spaceId][roleId][k] == user) {
        _usersByRoleIdBySpaceId[spaceId][roleId][k] = _usersByRoleIdBySpaceId[
          spaceId
        ][roleId][usersLen - 1];

        _usersByRoleIdBySpaceId[spaceId][roleId].pop();
      }
    }

    uint256 entitlementDataLen = _entitlementDataBySpaceIdByRoleId[spaceId][roleId].length;
    for (uint256 i = 0; i < entitlementDataLen; i++) {
      if (Utils.bytesEquals(_entitlementDataBySpaceIdByRoleId[spaceId][roleId][i], entitlementData)) {
        _entitlementDataBySpaceIdByRoleId[spaceId][roleId][
          i
        ] = _entitlementDataBySpaceIdByRoleId[spaceId][roleId][entitlementDataLen - 1];
        _entitlementDataBySpaceIdByRoleId[spaceId][roleId].pop();
        break;
      }
    }
    if (_entitlementDataBySpaceIdByRoleId[spaceId][roleId].length == 0) {
      delete _entitlementDataBySpaceIdByRoleId[spaceId][roleId];
    }
  }

  function removeRoleIdFromChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external override onlySpaceManager {
    //Look through all the roles assigned to that channel, if it matches the role
    //we are removing, remove it
    uint256 roleLen = _rolesByChannelIdBySpaceId[spaceId][channelId].length;
    for (uint256 i = 0; i < roleLen; i++) {
      if (_rolesByChannelIdBySpaceId[spaceId][channelId][i] == roleId) {
        _rolesByChannelIdBySpaceId[spaceId][channelId][
          i
        ] = _rolesByChannelIdBySpaceId[spaceId][channelId][roleLen - 1];
        _rolesByChannelIdBySpaceId[spaceId][channelId].pop();
      }
    }
  }

  function getUserRoles(
    uint256 spaceId,
    address user
  ) external view override returns (DataTypes.Role[] memory) {
    IRoleManager roleManager = IRoleManager(_roleManager);

    // Create an array the size of the total possible roles for this user
    DataTypes.Role[] memory roles = new DataTypes.Role[](
      _entitlementsByUserBySpaceId[spaceId][user].length
    );

    Entitlement[] memory userEntitlements = _entitlementsByUserBySpaceId[
      spaceId
    ][user];

    for (uint256 i = 0; i < userEntitlements.length; i++) {
      roles[i] = roleManager.getRoleBySpaceIdByRoleId(
        spaceId,
        userEntitlements[i].roleId
      );
    }

    return roles;
  }

  function concatArrays(
    Entitlement[] memory a,
    Entitlement[] memory b
  ) internal pure returns (Entitlement[] memory) {
    Entitlement[] memory c = new Entitlement[](a.length + b.length);
    uint256 i = 0;
    for (; i < a.length; i++) {
      c[i] = a[i];
    }
    uint256 j = 0;
    while (j < b.length) {
      c[i++] = b[j++];
    }
    return c;
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