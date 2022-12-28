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

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/interfaces/IERC721.sol";

import {ISpaceManager} from "../../interfaces/ISpaceManager.sol";
import {IRoleManager} from "../../interfaces/IRoleManager.sol";

import {DataTypes} from "../../libraries/DataTypes.sol";
import {PermissionTypes} from "../../libraries/PermissionTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

import {EntitlementModuleBase} from "../EntitlementModuleBase.sol";
import {Utils} from "../../libraries/Utils.sol";

contract TokenEntitlementModule is EntitlementModuleBase {
  struct TokenEntitlement {
    bytes32 entitlementId;
    uint256 roleId;
    address grantedBy;
    uint256 grantedTime;
    DataTypes.ExternalToken[] tokens;
  }
  
  struct SpaceTokenEntitlements {
    mapping(bytes32 => TokenEntitlement) entitlementsById;
    bytes32[] entitlementIds;
    mapping(uint256 => uint256[]) roleIdsByChannelId;
    mapping(uint256 => bytes32[]) entitlementIdsByRoleId;
    mapping(uint256 => bytes[]) entitlementDataByRoleId;
  }

  mapping(uint256 => SpaceTokenEntitlements) internal entitlementsBySpaceId;

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
    return entitlementsBySpaceId[spaceId].entitlementDataByRoleId[roleId];
  }

  function setSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external override onlySpaceManager {
    // get the length of the total Ids to get our next Id
    bytes32 entitlementId = keccak256(abi.encode(roleId, entitlementData));    

    // and add it to the array for iteration
    entitlementsBySpaceId[spaceId].entitlementIds.push(entitlementId);

    //Get and save the main entitlement object
    TokenEntitlement storage tokenEntitlement = entitlementsBySpaceId[spaceId]
      .entitlementsById[entitlementId];
    _addNewTokenEntitlement(
      tokenEntitlement,
      entitlementData,
      roleId,
      entitlementId
    );

    //Set so we can look up all entitlements by role when creating a new channel with a roleId
    entitlementsBySpaceId[spaceId].entitlementIdsByRoleId[roleId].push(
      entitlementId
    );

    //Set so we can look up all entitlements by role
    entitlementsBySpaceId[spaceId].entitlementDataByRoleId[roleId].push(
      entitlementData
    );
  }

  function addRoleIdToChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external override onlySpaceManager {
    // check for duplicate role ids
    uint256[] memory roleIds = entitlementsBySpaceId[spaceId]
      .roleIdsByChannelId[channelId];

    for (uint256 i = 0; i < roleIds.length; i++) {
      if (roleIds[i] == roleId) {
        revert Errors.RoleAlreadyExists();
      }
    }

    //Add the roleId to the mapping for the channel
    entitlementsBySpaceId[spaceId].roleIdsByChannelId[channelId].push(roleId);
  }

  function _addNewTokenEntitlement(
    TokenEntitlement storage tokenEntitlement,
    bytes calldata entitlementData,
    uint256 roleId,
    bytes32 entitlementId
  ) internal {
    DataTypes.ExternalTokenEntitlement memory externalTokenEntitlement = abi
      .decode(entitlementData, (DataTypes.ExternalTokenEntitlement));

    //Adds all the tokens passed in to gate this role with an AND
    if (externalTokenEntitlement.tokens.length == 0) {
      revert("No tokens set");
    }

    DataTypes.ExternalToken[] memory externalTokens = externalTokenEntitlement
      .tokens;
    for (uint256 i = 0; i < externalTokens.length; i++) {
      if (externalTokens[i].contractAddress == address(0)) {
        revert("No tokens provided");
      }

      if (externalTokens[i].quantity == 0) {
        revert("No quantities provided");
      }
      DataTypes.ExternalToken memory token = externalTokens[i];
      tokenEntitlement.tokens.push(token);
    }

    tokenEntitlement.grantedBy = msg.sender;
    tokenEntitlement.grantedTime = block.timestamp;
    tokenEntitlement.roleId = roleId;
    tokenEntitlement.entitlementId = entitlementId;
  }

  function removeSpaceEntitlement(
    uint256 spaceId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external override onlySpaceManager {
    bytes32 entitlementId = keccak256(abi.encode(roleId, entitlementData));

    //When removing, remove it from the main map and the roleId map but NOT from the array
    //of all EntitlementIds since we use that as a counter

    //Remove the association of this entitlementId to this roleId
    bytes32[] memory entitlementIdsFromRoleIds = entitlementsBySpaceId[spaceId]
      .entitlementIdsByRoleId[roleId];
    for (uint256 i = 0; i < entitlementIdsFromRoleIds.length; i++) {
      if (entitlementIdsFromRoleIds[i] == entitlementId) {
        delete entitlementsBySpaceId[spaceId].entitlementIdsByRoleId[i];
      }
    }

    //delete the main object
    delete entitlementsBySpaceId[spaceId].entitlementsById[entitlementId];

    // delete the entitlement data
    bytes[] memory entitlementDataFromRoleId = entitlementsBySpaceId[spaceId]
      .entitlementDataByRoleId[roleId];
    for (uint256 i = 0; i < entitlementDataFromRoleId.length; ) {
      if (Utils.bytesEquals(entitlementDataFromRoleId[i], entitlementData)) {
        entitlementsBySpaceId[spaceId].entitlementDataByRoleId[i] = 
          entitlementsBySpaceId[spaceId].entitlementDataByRoleId[
            entitlementDataFromRoleId.length - 1
          ];
        entitlementsBySpaceId[spaceId].entitlementDataByRoleId[roleId].pop();
        break;
      }
      unchecked {
        ++i;
      }
    }
    if (entitlementsBySpaceId[spaceId].entitlementDataByRoleId[roleId].length == 0) {
      delete entitlementsBySpaceId[spaceId].entitlementDataByRoleId[roleId];
    }
  }

  function removeRoleIdFromChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) external override onlySpaceManager {
    //Remove the association of this roleId to this channelId
    uint256[] memory roleIdsFromChannelIds = entitlementsBySpaceId[spaceId]
      .roleIdsByChannelId[channelId];
    for (uint256 i = 0; i < roleIdsFromChannelIds.length; i++) {
      if (roleIdsFromChannelIds[i] == roleId) {
        delete entitlementsBySpaceId[spaceId].roleIdsByChannelId[channelId][i];
      }
    }
  }

  function isEntitled(
    uint256 spaceId,
    uint256 channelId,
    address user,
    DataTypes.Permission memory permission
  ) public view override returns (bool) {
    if (channelId > 0) {
      return isEntitledToChannel(spaceId, channelId, user, permission);
    } else {
      return isEntitledToSpace(spaceId, user, permission);
    }
  }

  function isEntitledToSpace(
    uint256 spaceId,
    address user,
    DataTypes.Permission memory permission
  ) internal view returns (bool) {
    //Get all the entitlement ids
    bytes32[] memory entitlementIds = entitlementsBySpaceId[spaceId]
      .entitlementIds;

    //For each, check if the role in it has the permission we are looking for,
    //if so add it to the array of validRoleIds
    uint256[] memory validRoleIds = new uint256[](entitlementIds.length);
    for (uint256 i = 0; i < entitlementIds.length; i++) {
      bytes32 entitlementId = entitlementIds[i];
      TokenEntitlement memory entitlement = entitlementsBySpaceId[spaceId]
        .entitlementsById[entitlementId];
      uint256 roleId = entitlement.roleId;
      if (_checkRoleHasPermission(spaceId, roleId, permission)) {
        validRoleIds[i] = roleId;
      }
    }

    //for each of those roles, get all the entitlements associated with that role
    for (uint256 i = 0; i < validRoleIds.length; i++) {
      uint256 roleId = validRoleIds[i];
      bytes32[] memory entitlementIdsFromRoleIds = entitlementsBySpaceId[
        spaceId
      ].entitlementIdsByRoleId[roleId];
      //And check if that entitlement allows the user access, if so return true
      for (uint256 j = 0; j < entitlementIdsFromRoleIds.length; j++) {
        if (isTokenEntitled(spaceId, user, entitlementIdsFromRoleIds[j])) {
          return true;
        }
      }
    }
    //otherwise if none do, return false
    return false;
  }

  function isEntitledToChannel(
    uint256 spaceId,
    uint256 channelId,
    address user,
    DataTypes.Permission memory permission
  ) internal view returns (bool) {
    // First get all the roles for that channel
    uint256[] memory channelRoleIds = entitlementsBySpaceId[spaceId]
      .roleIdsByChannelId[channelId];

    // Then get strip that down to only the roles that have the permission we care about
    uint256[] memory validRoleIds = new uint256[](channelRoleIds.length);
    for (uint256 i = 0; i < channelRoleIds.length; i++) {
      uint256 roleId = channelRoleIds[i];
      if (_checkRoleHasPermission(spaceId, roleId, permission)) {
        validRoleIds[i] = roleId;
      }
    }

    //for each of those roles, get all the entitlements associated with that role
    for (uint256 i = 0; i < validRoleIds.length; i++) {
      bytes32[] memory entitlementIdsFromRoleIds = entitlementsBySpaceId[
        spaceId
      ].entitlementIdsByRoleId[validRoleIds[i]];

      //And check if that entitlement allows the user access, if so return true
      for (uint256 j = 0; j < entitlementIdsFromRoleIds.length; j++) {
        if (isTokenEntitled(spaceId, user, entitlementIdsFromRoleIds[j])) {
          return true;
        }
      }
    }

    //if none of them do, return false
    return false;
  }

  function isTokenEntitled(
    uint256 spaceId,
    address user,
    bytes32 entitlementId
  ) public view returns (bool) {
    DataTypes.ExternalToken[] memory tokens = entitlementsBySpaceId[spaceId]
      .entitlementsById[entitlementId]
      .tokens;

    bool entitled = false;
    //Check each token for a given entitlement, if any are false, the whole thing is false
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 quantity = tokens[i].quantity;
      uint256 tokenId = tokens[i].tokenId;
      bool isSingleToken = tokens[i].isSingleToken;

      address contractAddress = tokens[i].contractAddress;

      if (
        _isERC721Entitled(
          contractAddress,
          user,
          quantity,
          isSingleToken,
          tokenId
        ) || _isERC20Entitled(contractAddress, user, quantity)
      ) {
        entitled = true;
      } else {
        entitled = false;
        break;
      }
    }

    return entitled;
  }

  function _isERC721Entitled(
    address contractAddress,
    address user,
    uint256 quantity,
    bool isSingleToken,
    uint256 tokenId
  ) internal view returns (bool) {
    if (isSingleToken) {
      try IERC721(contractAddress).ownerOf(tokenId) returns (address owner) {
        if (owner == user) {
          return true;
        }
      } catch {}
    } else {
      try IERC721(contractAddress).balanceOf(user) returns (uint256 balance) {
        if (balance >= quantity) {
          return true;
        }
      } catch {}
    }
    return false;
  }  

  function _isERC20Entitled(
    address contractAddress,
    address user,
    uint256 quantity
  ) internal view returns (bool) {
    try IERC20(contractAddress).balanceOf(user) returns (uint256 balance) {
      if (balance >= quantity) {
        return true;
      }
    } catch {}
    return false;
  }

  /// Check if any of the entitlements contain the permission we are checking for
  function _checkRoleHasPermission(
    uint256 spaceId,
    uint256 roleId,
    DataTypes.Permission memory permission
  ) internal view returns (bool) {
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

  function getUserRoles(
    uint256 spaceId,
    address user
  ) public view returns (DataTypes.Role[] memory) {
    //Get all the entitlements for this space
    bytes32[] memory entitlementIds = entitlementsBySpaceId[spaceId]
      .entitlementIds;

    //Create an empty array of the max size of all entitlements
    DataTypes.Role[] memory roles = new DataTypes.Role[](entitlementIds.length);
    //Iterate through all the entitlements
    for (uint256 i = 0; i < entitlementIds.length; i++) {
      bytes32 entitlementId = entitlementIds[i];
      //If the user is entitled to a token entitlement
      //Get all the roles for that token entitlement, and add them to the array for this user
      if (isTokenEntitled(spaceId, user, entitlementId)) {
        uint256 roleId = entitlementsBySpaceId[spaceId]
          .entitlementsById[entitlementId]
          .roleId;

        roles[i] = IRoleManager(_roleManager).getRoleBySpaceIdByRoleId(
          spaceId,
          roleId
        );
      }
    }
    return roles;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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