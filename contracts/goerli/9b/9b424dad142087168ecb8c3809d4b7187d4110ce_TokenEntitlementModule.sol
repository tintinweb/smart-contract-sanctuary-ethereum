//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IEntitlementModule {
  /// @notice The name of the entitlement module
  function name() external view returns (string memory);

  /// @notice The description of the entitlement module
  function description() external view returns (string memory);

  /// @notice Checks if a user has access to space or channel based on the entitlements it holds
  /// @param spaceId The id of the space
  /// @param channelId The id of the channel
  /// @param userAddress The address of the user
  /// @param permission The type of permission to check
  /// @return bool representing if the user has access or not
  function isEntitled(
    string calldata spaceId,
    string calldata channelId,
    address userAddress,
    DataTypes.Permission memory permission
  ) external view returns (bool);

  /// @notice Sets the entitlements for a space
  function setEntitlement(
    string calldata spaceId,
    string calldata channelId,
    uint256 roleId,
    bytes calldata entitlementData
  ) external;

  /// @notice Removes the entitlements for a space
  function removeEntitlement(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata _roleIds,
    bytes calldata entitlementData
  ) external;

  function getUserRoles(
    string calldata spaceId,
    string calldata channelId,
    address user
  ) external view returns (DataTypes.Role[] memory);

  // function isBanned()
  // function ban();
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IRoleManager {
  function setSpaceManager(address spaceManager) external;

  function createRole(uint256 spaceId, string memory name)
    external
    returns (uint256);

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

  /// @notice Returns the permissions for a role in a space
  function getPermissionsBySpaceIdByRoleId(uint256 spaceId, uint256 roleId)
    external
    view
    returns (DataTypes.Permission[] memory);

  /// @notice Returns the roles of a space
  function getRolesBySpaceId(uint256 spaceId)
    external
    view
    returns (DataTypes.Role[] memory);

  /// @notice Returns the role of a space by id
  function getRoleBySpaceIdByRoleId(uint256 spaceId, uint256 roleId)
    external
    view
    returns (DataTypes.Role memory);
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
  function createChannel(DataTypes.CreateChannelData memory data)
    external
    returns (uint256);

  /// @notice Sets the default entitlement for a newly created space
  /// @param entitlementModuleAddress The address of the entitlement module
  function setDefaultUserEntitlementModule(address entitlementModuleAddress)
    external;

  /// @notice Sets the default token entitlement for a newly created space
  /// @param entitlementModuleAddress The address of the entitlement module
  function setDefaultTokenEntitlementModule(address entitlementModuleAddress)
    external;

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
    string calldata channelId,
    address entitlementAddress,
    uint256 roleId,
    bytes memory data
  ) external;

  /// @notice Removes an entitlement from an entitlement module
  function removeEntitlement(
    string calldata spaceId,
    string calldata channelId,
    address entitlementModuleAddress,
    uint256[] memory roleIds,
    bytes memory data
  ) external;

  /// @notice Create a role on a new space Id
  function createRole(string calldata spaceId, string calldata name)
    external
    returns (uint256);

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
  function getSpaceInfoBySpaceId(string calldata spaceId)
    external
    view
    returns (DataTypes.SpaceInfo memory);

  /// @notice Get the channel info by channel id
  function getChannelInfoByChannelId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (DataTypes.ChannelInfo memory);

  /// @notice Returns an array of multiple space information objects
  /// @return SpaceInfo[] an array containing the space info
  function getSpaces() external view returns (DataTypes.SpaceInfo[] memory);

  /// @notice Returns an array of channels by space id
  function getChannelsBySpaceId(string memory spaceId)
    external
    view
    returns (DataTypes.Channels memory);

  /// @notice Returns entitlements for a space
  /// @param spaceId The id of the space
  /// @return entitlementModules an array of entitlements
  function getEntitlementModulesBySpaceId(string calldata spaceId)
    external
    view
    returns (address[] memory entitlementModules);

  /// @notice Returns if an entitlement module is whitelisted for a space
  function isEntitlementModuleWhitelisted(
    string calldata spaceId,
    address entitlementModuleAddress
  ) external view returns (bool);

  /// @notice Returns the entitlement info for a space
  function getEntitlementsInfoBySpaceId(string calldata spaceId)
    external
    view
    returns (DataTypes.EntitlementModuleInfo[] memory);

  /// @notice Returns the space id by network id
  function getSpaceIdByNetworkId(string calldata networkId)
    external
    view
    returns (uint256);

  /// @notice Returns the channel id by network id
  function getChannelIdByNetworkId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (uint256);

  /// @notice Returns the owner of the space by space id
  /// @param spaceId The space id
  /// @return ownerAddress The address of the owner of the space
  function getSpaceOwnerBySpaceId(string calldata spaceId)
    external
    returns (address ownerAddress);

  /// @notice Returns the permission from the registry
  function getPermissionFromMap(bytes32 permissionType)
    external
    view
    returns (DataTypes.Permission memory permission);
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
    string description;
  }

  struct ExternalToken {
    address contractAddress;
    uint256 quantity;
    bool isSingleToken;
    uint256 tokenId;
  }

  struct ExternalTokenEntitlement {
    string tag;
    ExternalToken[] tokens;
  }
  /// *********************************
  /// **************DTO****************
  /// *********************************

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
  }

  /// @notice A struct containing the parameters required for creating a space
  /// @param spaceName The name of the space
  /// @param networkId The network id of the space
  struct CreateSpaceData {
    string spaceName;
    string spaceNetworkId;
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Errors} from "../libraries/Errors.sol";
import {IEntitlementModule} from "../interfaces/IEntitlementModule.sol";
import {ISpaceManager} from "../interfaces/ISpaceManager.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {PermissionTypes} from "../libraries/PermissionTypes.sol";

abstract contract EntitlementModuleBase is ERC165, IEntitlementModule {
  address public immutable _spaceManager;
  address public immutable _roleManager;
  string private _name;
  string private _description;

  modifier onlySpaceManager() {
    if (msg.sender != _spaceManager) revert Errors.NotSpaceManager();
    _;
  }

  constructor(
    string memory name_,
    string memory description_,
    address spaceManager_,
    address roleManager_
  ) {
    if (spaceManager_ == address(0)) {
      revert Errors.InvalidParameters();
    }

    _name = name_;
    _description = description_;
    _spaceManager = spaceManager_;
    _roleManager = roleManager_;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function description() external view returns (string memory) {
    return _description;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165)
    returns (bool)
  {
    return
      interfaceId == type(IEntitlementModule).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ISpaceManager} from "../../interfaces/ISpaceManager.sol";
import {IRoleManager} from "../../interfaces/IRoleManager.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {EntitlementModuleBase} from "../EntitlementModuleBase.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

contract TokenEntitlementModule is EntitlementModuleBase {
  struct TokenEntitlement {
    string tag;
    uint256 roleId;
    address grantedBy;
    uint256 grantedTime;
    DataTypes.ExternalToken[] tokens;
  }

  struct RoomTokenEntitlements {
    mapping(string => TokenEntitlement) entitlementsByTag;
    string[] entitlementTags;
  }

  struct SpaceTokenEntitlements {
    mapping(string => TokenEntitlement) entitlementsByTag;
    string[] entitlementTags;
    mapping(uint256 => RoomTokenEntitlements) roomEntitlementsByRoomId;
    mapping(string => string[]) tagsByPermission;
    mapping(uint256 => string[]) tagsByRoleId;
  }

  mapping(uint256 => SpaceTokenEntitlements) internal entitlementsBySpaceId;

  constructor(
    string memory name_,
    string memory description_,
    address spaceManager_,
    address roleManager_
  ) EntitlementModuleBase(name_, description_, spaceManager_, roleManager_) {}

  function setEntitlement(
    string memory spaceId,
    string memory channelId,
    uint256 roleId,
    bytes calldata entitlementData
  ) public override onlySpaceManager {
    ISpaceManager spaceManager = ISpaceManager(_spaceManager);

    uint256 _spaceId = spaceManager.getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = spaceManager.getChannelIdByNetworkId(
      spaceId,
      channelId
    );
    address ownerAddress = spaceManager.getSpaceOwnerBySpaceId(spaceId);

    require(
      ownerAddress == msg.sender || msg.sender == _spaceManager,
      "Only the owner can update entitlements"
    );

    DataTypes.ExternalTokenEntitlement memory externalTokenEntitlement = abi
      .decode(entitlementData, (DataTypes.ExternalTokenEntitlement));
    string memory tag = externalTokenEntitlement.tag;

    if (bytes(channelId).length > 0) {
      TokenEntitlement storage tokenEntitlement = entitlementsBySpaceId[
        _spaceId
      ].roomEntitlementsByRoomId[_channelId].entitlementsByTag[tag];

      _addNewTokenEntitlement(tokenEntitlement, entitlementData, roleId);

      // so we can iterate through all the token entitlements for a space
      entitlementsBySpaceId[_spaceId]
        .roomEntitlementsByRoomId[_channelId]
        .entitlementTags
        .push(tag);
      //So we can look up all potential token entitlements for a permission
      setAllDescByPermissionNames(spaceId, roleId, tag);
    } else {
      TokenEntitlement storage tokenEntitlement = entitlementsBySpaceId[
        _spaceId
      ].entitlementsByTag[tag];
      _addNewTokenEntitlement(tokenEntitlement, entitlementData, roleId);
      entitlementsBySpaceId[_spaceId].entitlementTags.push(tag);

      setAllDescByPermissionNames(spaceId, roleId, tag);
    }
  }

  function _addNewTokenEntitlement(
    TokenEntitlement storage tokenEntitlement,
    bytes calldata entitlementData,
    uint256 roleId
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
    tokenEntitlement.tag = externalTokenEntitlement.tag;
  }

  function setAllDescByPermissionNames(
    string memory spaceId,
    uint256 roleId,
    string memory desc
  ) internal {
    uint256 _spaceId = ISpaceManager(_spaceManager).getSpaceIdByNetworkId(
      spaceId
    );

    DataTypes.Permission[] memory permissions = IRoleManager(_roleManager)
      .getPermissionsBySpaceIdByRoleId(_spaceId, roleId);

    for (uint256 j = 0; j < permissions.length; j++) {
      DataTypes.Permission memory permission = permissions[j];
      string memory permissionName = permission.name;
      entitlementsBySpaceId[_spaceId].tagsByPermission[permissionName].push(
        desc
      );
      entitlementsBySpaceId[_spaceId].tagsByRoleId[roleId].push(desc);
      //todo Add All Permission for every one
    }
  }

  function removeEntitlement(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata,
    bytes calldata entitlementData
  ) external override onlySpaceManager {
    ISpaceManager spaceManager = ISpaceManager(_spaceManager);

    uint256 _spaceId = spaceManager.getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = spaceManager.getChannelIdByNetworkId(
      spaceId,
      channelId
    );
    address ownerAddress = spaceManager.getSpaceOwnerBySpaceId(spaceId);

    if (ownerAddress != msg.sender || msg.sender != _spaceManager) {
      revert("Only the owner can update entitlements");
    }

    string memory tag = abi.decode(entitlementData, (string));

    if (bytes(channelId).length > 0) {
      delete entitlementsBySpaceId[_spaceId]
        .roomEntitlementsByRoomId[_channelId]
        .entitlementsByTag[tag];
    } else {
      delete entitlementsBySpaceId[_spaceId].entitlementsByTag[tag];
    }

    DataTypes.Role[] memory roles = IRoleManager(_roleManager)
      .getRolesBySpaceId(_spaceId);

    for (uint256 i = 0; i < roles.length; i++) {
      delete entitlementsBySpaceId[_spaceId].tagsByRoleId[roles[i].roleId];
    }
  }

  function isEntitled(
    string calldata spaceId,
    string calldata channelId,
    address user,
    DataTypes.Permission memory permission
  ) public view override returns (bool) {
    ISpaceManager spaceManager = ISpaceManager(_spaceManager);

    uint256 _spaceId = spaceManager.getSpaceIdByNetworkId(spaceId);

    string[] memory tags = entitlementsBySpaceId[_spaceId].tagsByPermission[
      permission.name
    ];

    for (uint256 i = 0; i < tags.length; i++) {
      if (isTokenEntitled(spaceId, channelId, user, tags[i])) {
        return true;
      }
    }

    return false;
  }

  function isTokenEntitled(
    string calldata spaceId,
    string calldata,
    address user,
    string memory tag
  ) public view returns (bool) {
    ISpaceManager spaceManager = ISpaceManager(_spaceManager);

    uint256 _spaceId = spaceManager.getSpaceIdByNetworkId(spaceId);

    DataTypes.ExternalToken[] memory tokens = entitlementsBySpaceId[_spaceId]
      .entitlementsByTag[tag]
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

  function getUserRoles(
    string calldata spaceId,
    string calldata channelId,
    address user
  ) public view returns (DataTypes.Role[] memory) {
    ISpaceManager spaceManager = ISpaceManager(_spaceManager);

    uint256 _spaceId = spaceManager.getSpaceIdByNetworkId(spaceId);

    //Get all the entitlements for this space
    string[] memory entitlementTags = entitlementsBySpaceId[_spaceId]
      .entitlementTags;

    //Create an empty array of the max size of all entitlements
    DataTypes.Role[] memory roles = new DataTypes.Role[](
      entitlementTags.length
    );
    //Iterate through all the entitlements
    for (uint256 i = 0; i < entitlementTags.length; i++) {
      string memory tag = entitlementTags[i];
      //If the user is entitled to a token entitlement
      if (isTokenEntitled(spaceId, channelId, user, tag)) {
        uint256 roleId = entitlementsBySpaceId[_spaceId]
          .entitlementsByTag[tag]
          .roleId;
        //Get all the roles for that token entitlement, and add them to the array for this user
        roles[i] = IRoleManager(_roleManager).getRoleBySpaceIdByRoleId(
          _spaceId,
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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