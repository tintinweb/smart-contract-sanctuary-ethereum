//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// import {console} from "forge-std/console.sol";

import {ISpaceManager} from "./interfaces/ISpaceManager.sol";
import {IEntitlementModule} from "./interfaces/IEntitlementModule.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Constants} from "./libraries/Constants.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {CreationLogic} from "./libraries/CreationLogic.sol";
import {PermissionTypes} from "./libraries/PermissionTypes.sol";
import {IPermissionRegistry} from "./interfaces/IPermissionRegistry.sol";
import {ISpace} from "./interfaces/ISpace.sol";
import {IRoleManager} from "./interfaces/IRoleManager.sol";
import {ZionSpaceManagerStorage} from "./storage/ZionSpaceManagerStorage.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Utils} from "./libraries/Utils.sol";

/// @title ZionSpaceManager
/// @author HNT Labs
/// @notice This contract manages the spaces and entitlements in the Zion ecosystem.
contract ZionSpaceManager is Ownable, ZionSpaceManagerStorage, ISpaceManager {
  address internal immutable ROLE_MANAGER;
  address internal immutable PERMISSION_REGISTRY;

  address internal DEFAULT_USER_ENTITLEMENT_MODULE;
  address internal DEFAULT_TOKEN_ENTITLEMENT_MODULE;
  address internal SPACE_NFT;

  IRoleManager internal roleManager;

  constructor(address _permissionRegistry, address _roleManager) {
    if (_permissionRegistry == address(0)) revert Errors.InvalidParameters();
    if (_roleManager == address(0)) revert Errors.InvalidParameters();

    PERMISSION_REGISTRY = _permissionRegistry;
    ROLE_MANAGER = _roleManager;
    roleManager = IRoleManager(_roleManager);
  }

  /// *********************************
  /// *****SPACE OWNER FUNCTIONS*****
  /// *********************************

  /// @inheritdoc ISpaceManager
  function createSpace(
    DataTypes.CreateSpaceData calldata info,
    DataTypes.CreateSpaceEntitlementData calldata entitlementData,
    DataTypes.Permission[] calldata everyonePermissions
  ) external returns (uint256) {
    _validateSpaceDefaults();

    Utils.validateName(info.spaceName);

    //create the space with the metadata passed in
    uint256 spaceId = _createSpace(info);

    // mint space nft
    ISpace(SPACE_NFT).mintBySpaceId(spaceId, _msgSender(), info.spaceMetadata);

    // whitespace default entitlement module
    _whitelistEntitlementModule(spaceId, DEFAULT_USER_ENTITLEMENT_MODULE, true);

    // whitespace token entitlement module
    _whitelistEntitlementModule(
      spaceId,
      DEFAULT_TOKEN_ENTITLEMENT_MODULE,
      true
    );

    // Create owner role with all permissions
    uint256 ownerRoleId = _createOwnerRoleEntitlement(spaceId);

    //save this for convenience to use when creating a channel
    _spaceById[spaceId].ownerRoleId = ownerRoleId;

    // Create everyone role with the permissions passed in
    _createEveryoneRoleEntitlement(spaceId, everyonePermissions);

    uint256 permissionLen = entitlementData.permissions.length;

    // If there is another role to create then create it
    if (permissionLen > 0) {
      // create the additional role being gated by the token or for specified users
      uint256 additionalRoleId = roleManager.createRole(
        spaceId,
        entitlementData.roleName
      );

      //Add all the permissions for this role to it
      for (uint256 i = 0; i < permissionLen; ) {
        roleManager.addPermissionToRole(
          spaceId,
          additionalRoleId,
          entitlementData.permissions[i]
        );
        unchecked {
          ++i;
        }
      }
      //Iterate through the external tokens for this role and add them all to the token entitlement module
      if (entitlementData.externalTokenEntitlements.length > 0) {
        for (
          uint256 i = 0;
          i < entitlementData.externalTokenEntitlements.length;

        ) {
          DataTypes.ExternalTokenEntitlement
            memory externalTokenEntitlement = entitlementData
              .externalTokenEntitlements[i];

          // add additional role to the token entitlement module
          _addRoleToEntitlementModule(
            spaceId,
            DEFAULT_TOKEN_ENTITLEMENT_MODULE,
            additionalRoleId,
            abi.encode(externalTokenEntitlement)
          );
          unchecked {
            ++i;
          }
        }
      }

      //Iterate through the specified users for this role and add them all to the user entitlement module
      if (entitlementData.users.length > 0) {
        for (uint256 i = 0; i < entitlementData.users.length; ) {
          // add additional role to the user entitlement module
          _addRoleToEntitlementModule(
            spaceId,
            DEFAULT_USER_ENTITLEMENT_MODULE,
            additionalRoleId,
            abi.encode(address(entitlementData.users[i]))
          );
          unchecked {
            ++i;
          }
        }
      }
    }

    emit Events.CreateSpace(info.spaceNetworkId, _msgSender());

    return spaceId;
  }

  /// @inheritdoc ISpaceManager
  function createChannel(
    DataTypes.CreateChannelData calldata data
  ) external returns (uint256 channelId) {
    _validateIsAllowed(
      data.spaceNetworkId,
      "",
      PermissionTypes.AddRemoveChannels
    );
    _validateSpaceExists(data.spaceNetworkId);
    Utils.validateName(data.channelName);

    uint256 spaceId = _getSpaceIdByNetworkId(data.spaceNetworkId);
    channelId = _createChannel(spaceId, data);

    //Get all the entitlement modules for this space
    uint256 entitlementModulesLen = _spaceById[spaceId]
      .entitlementModules
      .length;

    //Iterate through them all to tell them about the association of a role to a channel
    for (uint256 i = 0; i < entitlementModulesLen; i++) {
      address entitlement = _spaceById[spaceId].entitlementModules[i];

      if (entitlement == address(0)) continue;

      IEntitlementModule(entitlement).addRoleIdToChannel(
        spaceId,
        channelId,
        _spaceById[spaceId].ownerRoleId
      );

      for (uint256 j = 0; j < data.roleIds.length; j++) {
        if (data.roleIds[j] == _spaceById[spaceId].ownerRoleId) continue;

        try
          IEntitlementModule(entitlement).addRoleIdToChannel(
            spaceId,
            channelId,
            data.roleIds[j]
          )
        {
          emit Events.CreateChannel(
            data.spaceNetworkId,
            data.channelNetworkId,
            _msgSender()
          );
        } catch {
          revert Errors.AddRoleFailed();
        }
      }
    }

    return channelId;
  }

  /// *********************************
  /// *****EXTERNAL FUNCTIONS**********
  /// *********************************
  function setSpaceAccess(
    string memory spaceNetworkId,
    bool disabled
  ) external {
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifySpacePermissions
    );

    uint256 spaceId = _getSpaceIdByNetworkId(spaceNetworkId);
    if (spaceId == 0) revert Errors.SpaceDoesNotExist();

    _spaceById[spaceId].disabled = disabled;

    emit Events.SetSpaceAccess(spaceNetworkId, _msgSender(), disabled);
  }

  function setChannelAccess(
    string calldata spaceNetworkId,
    string calldata channelNetworkId,
    bool disabled
  ) external {
    _validateIsAllowed(
      spaceNetworkId,
      channelNetworkId,
      PermissionTypes.ModifyChannelPermissions
    );

    _validateSpaceExists(spaceNetworkId);
    _validateChannelExists(spaceNetworkId, channelNetworkId);

    uint256 spaceId = _getSpaceIdByNetworkId(spaceNetworkId);
    uint256 channelId = _getChannelIdByNetworkId(
      spaceNetworkId,
      channelNetworkId
    );

    _channelBySpaceIdByChannelId[spaceId][channelId].disabled = disabled;

    emit Events.SetChannelAccess(
      spaceNetworkId,
      channelNetworkId,
      _msgSender(),
      disabled
    );
  }

  /// @inheritdoc ISpaceManager
  function setDefaultUserEntitlementModule(
    address entitlementModule
  ) external onlyOwner {
    DEFAULT_USER_ENTITLEMENT_MODULE = entitlementModule;
    emit Events.DefaultEntitlementSet(entitlementModule);
  }

  /// @inheritdoc ISpaceManager
  function setDefaultTokenEntitlementModule(
    address entitlementModule
  ) external onlyOwner {
    DEFAULT_TOKEN_ENTITLEMENT_MODULE = entitlementModule;
    emit Events.DefaultEntitlementSet(entitlementModule);
  }

  /// @inheritdoc ISpaceManager
  function setSpaceNFT(address spaceNFTAddress) external onlyOwner {
    SPACE_NFT = spaceNFTAddress;
    emit Events.SpaceNFTAddressSet(spaceNFTAddress);
  }

  /// @inheritdoc ISpaceManager
  function whitelistEntitlementModule(
    string calldata spaceNetworkId,
    address entitlementAddress,
    bool whitelist
  ) external {
    _validateEntitlementInterface(entitlementAddress);
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifySpacePermissions
    );

    if (
      entitlementAddress == DEFAULT_TOKEN_ENTITLEMENT_MODULE ||
      entitlementAddress == DEFAULT_USER_ENTITLEMENT_MODULE
    ) {
      revert Errors.NotAllowed();
    }

    _whitelistEntitlementModule(
      _getSpaceIdByNetworkId(spaceNetworkId),
      entitlementAddress,
      whitelist
    );

    emit Events.WhitelistEntitlementModule(
      spaceNetworkId,
      entitlementAddress,
      whitelist
    );
  }

  /// @inheritdoc ISpaceManager
  function addRoleIdsToChannel(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata roleId
  ) external {
    _validateIsAllowed(
      spaceId,
      channelId,
      PermissionTypes.ModifyChannelPermissions
    );

    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = _getChannelIdByNetworkId(spaceId, channelId);

    for (uint256 i = 0; i < roleId.length; i++) {
      _addRoleIdToChannel(_spaceId, _channelId, roleId[i]);
    }
  }

  /// @inheritdoc ISpaceManager
  function removeRoleIdsFromChannel(
    string calldata spaceId,
    string calldata channelId,
    uint256[] calldata roleId
  ) external {
    _validateIsAllowed(
      spaceId,
      channelId,
      PermissionTypes.ModifyChannelPermissions
    );

    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = _getChannelIdByNetworkId(spaceId, channelId);

    for (uint256 i = 0; i < roleId.length; i++) {
      _removeRoleIdFromChannel(_spaceId, _channelId, roleId[i]);
    }
  }

  /// @inheritdoc ISpaceManager
  function createRole(
    string calldata spaceNetworkId,
    string calldata name
  ) external returns (uint256 roleId) {
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifySpacePermissions
    );

    roleId = roleManager.createRole(
      _getSpaceIdByNetworkId(spaceNetworkId),
      name
    );

    emit Events.CreateRole(spaceNetworkId, roleId, name, _msgSender());

    return roleId;
  }

  /// @inheritdoc ISpaceManager

  function removeRole(string calldata spaceNetworkId, uint256 roleId) external {
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifySpacePermissions
    );

    if (
      roleId == _spaceById[_getSpaceIdByNetworkId(spaceNetworkId)].ownerRoleId
    ) revert Errors.InvalidParameters();

    roleManager.removeRole(_getSpaceIdByNetworkId(spaceNetworkId), roleId);

    emit Events.RemoveRole(spaceNetworkId, roleId, _msgSender());
  }

  /// @inheritdoc ISpaceManager
  function addPermissionToRole(
    string calldata spaceId,
    uint256 roleId,
    DataTypes.Permission calldata permission
  ) external {
    _validateIsAllowed(spaceId, "", PermissionTypes.ModifySpacePermissions);

    roleManager.addPermissionToRole(
      _getSpaceIdByNetworkId(spaceId),
      roleId,
      permission
    );

    emit Events.UpdateRole(spaceId, roleId, _msgSender());
  }

  /// @inheritdoc ISpaceManager
  function removePermissionFromRole(
    string calldata spaceNetworkId,
    uint256 roleId,
    DataTypes.Permission calldata permission
  ) external {
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifySpacePermissions
    );

    roleManager.removePermissionFromRole(
      _getSpaceIdByNetworkId(spaceNetworkId),
      roleId,
      permission
    );

    emit Events.UpdateRole(spaceNetworkId, roleId, _msgSender());
  }

  /// @inheritdoc ISpaceManager
  function addRoleToEntitlementModule(
    string calldata spaceNetworkId,
    address entitlementModuleAddress,
    uint256 roleId,
    bytes calldata entitlementData
  ) external {
    _validateSpaceExists(spaceNetworkId);
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifyChannelPermissions
    );
    _validateEntitlementInterface(entitlementModuleAddress);

    uint256 _spaceId = _getSpaceIdByNetworkId(spaceNetworkId);

    _validateNotOwnerRoleId(_spaceId, roleId);

    _addRoleToEntitlementModule(
      _spaceId,
      entitlementModuleAddress,
      roleId,
      entitlementData
    );

    emit Events.EntitlementModuleAdded(
      spaceNetworkId,
      entitlementModuleAddress
    );
  }

  /// @inheritdoc ISpaceManager
  function removeEntitlement(
    string calldata spaceNetworkId,
    address entitlementModuleAddress,
    uint256 roleId,
    bytes calldata data
  ) external {
    _validateSpaceExists(spaceNetworkId);
    _validateIsAllowed(
      spaceNetworkId,
      "",
      PermissionTypes.ModifyChannelPermissions
    );

    uint256 _spaceId = _getSpaceIdByNetworkId(spaceNetworkId);

    _validateNotOwnerRoleId(_spaceId, roleId);

    _validateEntitlementInterface(entitlementModuleAddress);

    _removeEntitlementRole(_spaceId, entitlementModuleAddress, roleId, data);

    emit Events.EntitlementModuleRemoved(
      spaceNetworkId,
      entitlementModuleAddress
    );
  }

  /// *********************************
  /// *****EXTERNAL VIEW FUNCTIONS*****
  /// *********************************

  /// @inheritdoc ISpaceManager
  function isEntitled(
    string calldata spaceId,
    string calldata channelId,
    address user,
    DataTypes.Permission calldata permission
  ) external view returns (bool) {
    if (_isSpaceAccessDisabled(spaceId)) {
      return false;
    }

    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = _getChannelIdByNetworkId(spaceId, channelId);
    return _isEntitled(_spaceId, _channelId, user, permission);
  }

  /// @inheritdoc ISpaceManager
  function getSpaceInfoBySpaceId(
    string calldata spaceId
  ) external view returns (DataTypes.SpaceInfo memory) {
    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);

    return
      DataTypes.SpaceInfo(
        _spaceById[_spaceId].spaceId,
        _spaceById[_spaceId].networkId,
        _spaceById[_spaceId].createdAt,
        _spaceById[_spaceId].name,
        _spaceById[_spaceId].creator,
        _spaceById[_spaceId].owner,
        _spaceById[_spaceId].disabled
      );
  }

  /// @inheritdoc ISpaceManager
  function getChannelInfoByChannelId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (DataTypes.ChannelInfo memory) {
    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);
    uint256 _channelId = _getChannelIdByNetworkId(spaceId, channelId);

    return
      DataTypes.ChannelInfo(
        _channelBySpaceIdByChannelId[_spaceId][_channelId].channelId,
        _channelBySpaceIdByChannelId[_spaceId][_channelId].networkId,
        _channelBySpaceIdByChannelId[_spaceId][_channelId].createdAt,
        _channelBySpaceIdByChannelId[_spaceId][_channelId].name,
        _channelBySpaceIdByChannelId[_spaceId][_channelId].creator,
        _channelBySpaceIdByChannelId[_spaceId][_channelId].disabled
      );
  }

  /// @inheritdoc ISpaceManager
  function getSpaces() external view returns (DataTypes.SpaceInfo[] memory) {
    DataTypes.SpaceInfo[] memory spaces = new DataTypes.SpaceInfo[](
      _spacesCounter
    );

    for (uint256 i = 0; i < _spacesCounter; ) {
      DataTypes.Space storage space = _spaceById[i + 1];
      spaces[i] = DataTypes.SpaceInfo(
        space.spaceId,
        space.networkId,
        space.createdAt,
        space.name,
        space.creator,
        space.owner,
        space.disabled
      );
      unchecked {
        ++i;
      }
    }
    return spaces;
  }

  /// @inheritdoc ISpaceManager
  function getChannelsBySpaceId(
    string memory spaceId
  ) external view returns (DataTypes.Channels memory) {
    return _channelsBySpaceId[_getSpaceIdByNetworkId(spaceId)];
  }

  /// @inheritdoc ISpaceManager
  function getEntitlementModulesBySpaceId(
    string calldata spaceId
  ) public view returns (address[] memory) {
    return _spaceById[_getSpaceIdByNetworkId(spaceId)].entitlementModules;
  }

  /// @inheritdoc ISpaceManager
  function isEntitlementModuleWhitelisted(
    string calldata spaceId,
    address entitlementModuleAddress
  ) public view returns (bool) {
    return
      _spaceById[_getSpaceIdByNetworkId(spaceId)].hasEntitlement[
        entitlementModuleAddress
      ];
  }

  /// @inheritdoc ISpaceManager
  function getEntitlementsInfoBySpaceId(
    string calldata spaceId
  ) public view returns (DataTypes.EntitlementModuleInfo[] memory) {
    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);

    DataTypes.EntitlementModuleInfo[]
      memory entitlementsInfo = new DataTypes.EntitlementModuleInfo[](
        _spaceById[_spaceId].entitlementModules.length
      );

    uint256 entitlementModulesLen = _spaceById[_spaceId]
      .entitlementModules
      .length;

    for (uint256 i = 0; i < entitlementModulesLen; i++) {
      address entitlement = _spaceById[_spaceId].entitlementModules[i];

      if (entitlement == address(0)) continue;

      DataTypes.EntitlementModuleInfo memory info = DataTypes
        .EntitlementModuleInfo(
          entitlement,
          IEntitlementModule(entitlement).name(),
          IEntitlementModule(entitlement).moduleType(),
          IEntitlementModule(entitlement).description()
        );

      entitlementsInfo[i] = info;
    }

    return entitlementsInfo;
  }

  /// @inheritdoc ISpaceManager
  function getSpaceOwnerBySpaceId(
    string calldata spaceId
  ) external view returns (address) {
    return ISpace(SPACE_NFT).getOwnerBySpaceId(_getSpaceIdByNetworkId(spaceId));
  }

  /// @inheritdoc ISpaceManager
  function getSpaceIdByNetworkId(
    string calldata networkId
  ) external view returns (uint256) {
    return _getSpaceIdByNetworkId(networkId);
  }

  /// @inheritdoc ISpaceManager
  function getChannelIdByNetworkId(
    string calldata spaceId,
    string calldata channelId
  ) external view returns (uint256) {
    return _getChannelIdByNetworkId(spaceId, channelId);
  }

  /// ****************************
  /// *****INTERNAL FUNCTIONS*****
  /// ****************************
  function _getSpaceIdByNetworkId(
    string memory networkId
  ) internal view returns (uint256) {
    return _spaceIdByHash[keccak256(bytes(networkId))];
  }

  function _getChannelIdByNetworkId(
    string memory spaceId,
    string memory channelId
  ) internal view returns (uint256) {
    return
      _channelIdBySpaceIdByHash[_getSpaceIdByNetworkId(spaceId)][
        keccak256(bytes(channelId))
      ];
  }

  function _isEntitled(
    uint256 spaceId,
    uint256 channelId,
    address user,
    DataTypes.Permission memory permission
  ) internal view returns (bool entitled) {
    entitled = false;

    uint256 entitlementModulesLen = _spaceById[spaceId]
      .entitlementModules
      .length;

    for (uint256 i = 0; i < entitlementModulesLen; i++) {
      address entitlement = _spaceById[spaceId].entitlementModules[i];

      if (entitlement == address(0)) continue;

      if (
        IEntitlementModule(entitlement).isEntitled(
          spaceId,
          channelId,
          user,
          permission
        )
      ) {
        entitled = true;
        break;
      }
    }

    return entitled;
  }

  function _createSpace(
    DataTypes.CreateSpaceData calldata info
  ) internal returns (uint256 spaceId) {
    unchecked {
      // create space Id
      spaceId = ++_spacesCounter;

      // create space
      CreationLogic.createSpace(
        info,
        spaceId,
        _msgSender(),
        _spaceIdByHash,
        _spaceById
      );

      return spaceId;
    }
  }

  function _createChannel(
    uint256 spaceId,
    DataTypes.CreateChannelData memory data
  ) internal returns (uint256 channelId) {
    unchecked {
      // create channel Id
      channelId = ++_channelsBySpaceId[spaceId].idCounter;

      // create channel
      CreationLogic.createChannel(
        data,
        spaceId,
        channelId,
        _msgSender(),
        _channelsBySpaceId,
        _channelIdBySpaceIdByHash,
        _channelBySpaceIdByChannelId
      );

      return channelId;
    }
  }

  function _createOwnerRoleEntitlement(
    uint256 spaceId
  ) internal returns (uint256 ownerRoleId) {
    DataTypes.ExternalToken memory spaceNFTInfo = _getOwnerNFTInformation(
      spaceId
    );

    DataTypes.ExternalToken[]
      memory externalTokens = new DataTypes.ExternalToken[](1);
    externalTokens[0] = spaceNFTInfo;
    DataTypes.ExternalTokenEntitlement
      memory externalTokenEntitlement = DataTypes.ExternalTokenEntitlement(
        externalTokens
      );

    uint256 newOwnerRoleId = roleManager.createOwnerRole(spaceId);
    _addRoleToEntitlementModule(
      spaceId,
      DEFAULT_TOKEN_ENTITLEMENT_MODULE,
      ownerRoleId,
      abi.encode(externalTokenEntitlement)
    );

    return newOwnerRoleId;
  }

  function _createEveryoneRoleEntitlement(
    uint256 spaceId,
    DataTypes.Permission[] calldata permissions
  ) internal returns (uint256 everyoneRoleId) {
    everyoneRoleId = roleManager.createRole(spaceId, "Everyone");

    for (uint256 i = 0; i < permissions.length; ) {
      roleManager.addPermissionToRole(spaceId, everyoneRoleId, permissions[i]);
      unchecked {
        ++i;
      }
    }

    _addRoleToEntitlementModule(
      spaceId,
      DEFAULT_USER_ENTITLEMENT_MODULE,
      everyoneRoleId,
      abi.encode(Constants.EVERYONE_ADDRESS)
    );
    return everyoneRoleId;
  }

  function _addRoleIdToChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) internal {
    //Get all the entitlement modules for this space
    uint256 entitlementModulesLen = _spaceById[spaceId]
      .entitlementModules
      .length;

    //Iterate through them all to tell them about the association of a role to a channel
    for (uint256 i = 0; i < entitlementModulesLen; i++) {
      address entitlement = _spaceById[spaceId].entitlementModules[i];

      if (entitlement == address(0)) continue;

      IEntitlementModule(entitlement).addRoleIdToChannel(
        spaceId,
        channelId,
        roleId
      );
    }
  }

  function _removeRoleIdFromChannel(
    uint256 spaceId,
    uint256 channelId,
    uint256 roleId
  ) internal {
    //Get all the entitlement modules for this space
    uint256 entitlementModulesLen = _spaceById[spaceId]
      .entitlementModules
      .length;

    //Iterate through them all to tell them about the association of a role to a channel
    for (uint256 i = 0; i < entitlementModulesLen; i++) {
      address entitlement = _spaceById[spaceId].entitlementModules[i];

      if (entitlement == address(0)) continue;

      IEntitlementModule(entitlement).removeRoleIdFromChannel(
        spaceId,
        channelId,
        roleId
      );
    }
  }

  function _whitelistEntitlementModule(
    uint256 spaceId,
    address entitlementAddress,
    bool whitelist
  ) internal {
    if (whitelist && _spaceById[spaceId].hasEntitlement[entitlementAddress]) {
      revert Errors.EntitlementAlreadyWhitelisted();
    }

    CreationLogic.setEntitlement(
      spaceId,
      entitlementAddress,
      whitelist,
      _spaceById
    );
  }

  function _removeEntitlementRole(
    uint256 spaceId,
    address entitlementAddress,
    uint256 roleId,
    bytes memory entitlementData
  ) internal {
    // make sure entitlement module is whitelisted
    if (!_spaceById[spaceId].hasEntitlement[entitlementAddress])
      revert Errors.EntitlementNotWhitelisted();

    // remove the entitlement from the entitlement module
    IEntitlementModule(entitlementAddress).removeSpaceEntitlement(
      spaceId,
      roleId,
      entitlementData
    );
  }

  function _addRoleToEntitlementModule(
    uint256 spaceId,
    address entitlementAddress,
    uint256 roleId,
    bytes memory entitlementData
  ) internal {
    // make sure entitlement module is whitelisted
    if (!_spaceById[spaceId].hasEntitlement[entitlementAddress])
      revert Errors.EntitlementNotWhitelisted();

    // add the entitlement to the entitlement module
    IEntitlementModule(entitlementAddress).setSpaceEntitlement(
      spaceId,
      roleId,
      entitlementData
    );
  }

  function _getOwnerNFTInformation(
    uint256 spaceId
  ) internal view returns (DataTypes.ExternalToken memory) {
    DataTypes.ExternalToken memory tokenInfo = DataTypes.ExternalToken(
      SPACE_NFT,
      1,
      true,
      spaceId
    );
    return tokenInfo;
  }

  /// ****************************
  /// ****VALIDATION FUNCTIONS****
  /// ****************************
  function _validateSpaceExists(string memory spaceId) internal view {
    uint256 _spaceId = _getSpaceIdByNetworkId(spaceId);
    if (_spaceId == 0) revert Errors.SpaceDoesNotExist();
    if (_spaceById[_spaceId].disabled) revert Errors.SpaceDoesNotExist();
  }

  function _isSpaceAccessDisabled(
    string memory spaceNetworkId
  ) internal view returns (bool isDisabled) {
    uint256 _spaceId = _getSpaceIdByNetworkId(spaceNetworkId);
    return _spaceId == 0 || _spaceById[_spaceId].disabled;
  }

  function _validateChannelExists(
    string memory spaceId,
    string memory channelId
  ) internal view {
    uint256 _channelId = _getChannelIdByNetworkId(spaceId, channelId);
    if (_channelId == 0) revert Errors.ChannelDoesNotExist();
  }

  function _validateNotOwnerRoleId(
    uint256 spaceId,
    uint256 roleId
  ) internal view {
    if (roleId == _spaceById[spaceId].ownerRoleId) revert Errors.NotAllowed();
  }

  function _validateIsAllowed(
    string memory spaceNetworkId,
    string memory channelNetworkId,
    bytes32 permission
  ) internal view {
    uint256 spaceId = _getSpaceIdByNetworkId(spaceNetworkId);
    uint256 channelId = _getChannelIdByNetworkId(
      spaceNetworkId,
      channelNetworkId
    );
    if (
      // check if the caller is the space manager contract itself, was getting erros when calling internal functions
      _isEntitled(
        spaceId,
        channelId,
        _msgSender(),
        IPermissionRegistry(PERMISSION_REGISTRY).getPermissionByPermissionType(
          permission
        )
      )
    ) {
      return;
    } else {
      revert Errors.NotAllowed();
    }
  }

  function _validateSpaceDefaults() internal view {
    if (PERMISSION_REGISTRY == address(0))
      revert Errors.DefaultPermissionsManagerNotSet();
    if (DEFAULT_USER_ENTITLEMENT_MODULE == address(0))
      revert Errors.DefaultEntitlementModuleNotSet();
    if (DEFAULT_TOKEN_ENTITLEMENT_MODULE == address(0))
      revert Errors.DefaultEntitlementModuleNotSet();
    if (SPACE_NFT == address(0)) revert Errors.SpaceNFTNotSet();
  }

  /// @notice validates that the entitlement module implements the correct interface
  /// @param entitlementAddress the address of the entitlement module
  function _validateEntitlementInterface(
    address entitlementAddress
  ) internal view {
    if (
      IERC165(entitlementAddress).supportsInterface(
        type(IEntitlementModule).interfaceId
      ) == false
    ) revert Errors.EntitlementModuleNotSupported();
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

interface ISpace {
  /// @notice Mints a space nft by space id
  function mintBySpaceId(
    uint256 spaceId,
    address spaceOwner,
    string calldata tokenURI
  ) external;

  /// @notice Returns the owner of the space by space id
  function getOwnerBySpaceId(uint256 spaceId) external view returns (address);
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

import "./../libraries/DataTypes.sol";

abstract contract ZionSpaceManagerStorage {
  /// @notice variable representing the current total amount of spaces in the contract
  uint256 internal _spacesCounter;

  /// @notice Mapping representing the space id by network hash
  mapping(bytes32 => uint256) internal _spaceIdByHash;

  /// @notice Mapping representing the channel id by space id by network hash
  mapping(uint256 => mapping(bytes32 => uint256))
    internal _channelIdBySpaceIdByHash;

  /// @notice Mapping representing the channel data by spaceId by channel hash
  mapping(uint256 => mapping(uint256 => DataTypes.Channel))
    internal _channelBySpaceIdByChannelId;

  /// @notice mapping representing the space data by id
  mapping(uint256 => DataTypes.Space) internal _spaceById;

  /// @notice mapping representing the channel data by space id
  mapping(uint256 => DataTypes.Channels) internal _channelsBySpaceId;

  /// @notice mapping representing the entitlements modules by space id
  mapping(uint256 => address[]) internal _entitlementModulesBySpaceId;
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