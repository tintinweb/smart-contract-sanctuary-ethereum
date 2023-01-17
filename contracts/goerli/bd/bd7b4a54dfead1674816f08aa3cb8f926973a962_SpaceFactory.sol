// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {Utils} from "./libraries/Utils.sol";

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract MultiCaller {
  function multicall(
    bytes[] calldata data
  ) external returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        Utils.revertFromReturnedData(result);
      }

      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

//interfaces
import {ISpace} from "./interfaces/ISpace.sol";
import {IEntitlement} from "./interfaces/IEntitlement.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

//libraries
import {DataTypes} from "./libraries/DataTypes.sol";
import {Utils} from "./libraries/Utils.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {Permissions} from "./libraries/Permissions.sol";

//contracts
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MultiCaller} from "./MultiCaller.sol";

contract Space is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  MultiCaller,
  ISpace
{
  string public name;
  string public networkId;
  bool public disabled;
  uint256 public ownerRoleId;

  mapping(address => bool) public hasEntitlement;
  mapping(address => bool) public defaultEntitlements;
  mapping(uint256 => bytes32[]) internal entitlementIdsByRoleId;
  address[] public entitlements;

  uint256 public roleCount;
  mapping(uint256 => DataTypes.Role) public rolesById;
  mapping(uint256 => bytes32[]) internal permissionsByRoleId;
  mapping(uint256 => bool) internal roleAssigned;

  mapping(bytes32 => DataTypes.Channel) public channelsByHash;
  bytes32[] public channels;

  modifier onlySpaceOwner() {
    _isAllowed("", Permissions.Owner);
    _;
  }

  /// ***** Space Management *****

  /// @inheritdoc ISpace
  function initialize(
    string memory _name,
    string memory _networkId,
    address[] memory _entitlements
  ) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();

    name = _name;
    networkId = _networkId;

    // whitelist modules
    for (uint256 i = 0; i < _entitlements.length; i++) {
      _setEntitlement(_entitlements[i], true);
      defaultEntitlements[_entitlements[i]] = true;
    }
  }

  /// @inheritdoc ISpace
  function setSpaceAccess(bool _disabled) external {
    _isAllowed("", Permissions.Owner);
    disabled = _disabled;
  }

  /// @inheritdoc ISpace
  function setOwnerRoleId(uint256 _roleId) external {
    _isAllowed("", Permissions.Owner);

    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    // check if new role id has the owner permission
    bool hasOwnerPermission = false;
    for (uint256 i = 0; i < permissionsByRoleId[_roleId].length; i++) {
      if (
        permissionsByRoleId[_roleId][i] ==
        bytes32(abi.encodePacked(Permissions.Owner))
      ) {
        hasOwnerPermission = true;
        break;
      }
    }

    if (!hasOwnerPermission) {
      revert Errors.MissingOwnerPermission();
    }

    ownerRoleId = _roleId;
  }

  /// ***** Channel Management *****

  /// @inheritdoc ISpace
  function getChannelByHash(
    bytes32 _channelHash
  ) external view returns (DataTypes.Channel memory) {
    return channelsByHash[_channelHash];
  }

  /// @inheritdoc ISpace
  function setChannelAccess(
    string calldata _channelId,
    bool _disabled
  ) external {
    _isAllowed("", Permissions.AddRemoveChannels);

    bytes32 channelId = keccak256(abi.encodePacked(_channelId));

    if (channelsByHash[channelId].channelId == 0) {
      revert Errors.ChannelDoesNotExist();
    }

    channelsByHash[channelId].disabled = _disabled;
  }

  function updateChannel(
    string calldata _channelId,
    string memory _channelName
  ) external {
    _isAllowed("", Permissions.AddRemoveChannels);

    bytes32 channelId = keccak256(abi.encodePacked(_channelId));

    if (channelsByHash[channelId].channelId == 0) {
      revert Errors.ChannelDoesNotExist();
    }

    // verify channelName is not empty
    if (bytes(_channelName).length == 0) {
      revert Errors.NotAllowed();
    }

    channelsByHash[channelId].name = _channelName;
  }

  /// @inheritdoc ISpace
  function createChannel(
    string memory channelName,
    string memory channelNetworkId,
    uint256[] memory roleIds
  ) external returns (bytes32) {
    _isAllowed("", Permissions.AddRemoveChannels);

    bytes32 channelId = keccak256(abi.encodePacked(channelNetworkId));

    if (channelsByHash[channelId].channelId != 0) {
      revert Errors.ChannelAlreadyRegistered();
    }

    // save channel info
    channelsByHash[channelId] = DataTypes.Channel({
      name: channelName,
      channelId: channelId,
      createdAt: block.timestamp,
      disabled: false
    });

    // keep track of channels
    channels.push(channelId);

    // Add the owner role to the channel's entitlements
    for (uint256 i = 0; i < entitlements.length; i++) {
      address entitlement = entitlements[i];

      IEntitlement(entitlement).addRoleIdToChannel(
        channelNetworkId,
        ownerRoleId
      );

      // Add extra roles to the channel's entitlements
      for (uint256 j = 0; j < roleIds.length; j++) {
        if (roleIds[j] == ownerRoleId) continue;

        // make sure the role exists
        if (rolesById[roleIds[j]].roleId == 0) {
          revert Errors.RoleDoesNotExist();
        }

        try
          IEntitlement(entitlement).addRoleIdToChannel(
            channelNetworkId,
            roleIds[j]
          )
        {} catch {
          revert Errors.AddRoleFailed();
        }
      }
    }

    return channelId;
  }

  /// ***** Role Management *****

  /// @inheritdoc ISpace
  function getRoles() external view returns (DataTypes.Role[] memory) {
    DataTypes.Role[] memory roles = new DataTypes.Role[](roleCount);
    for (uint256 i = 0; i < roleCount; i++) {
      roles[i] = rolesById[i + 1];
    }
    return roles;
  }

  /// @inheritdoc ISpace
  function createRole(
    string memory _roleName,
    string[] memory _permissions,
    DataTypes.Entitlement[] memory _entitlements
  ) external returns (uint256) {
    _isAllowed("", Permissions.ModifySpacePermissions);

    uint256 newRoleId = ++roleCount;

    DataTypes.Role memory role = DataTypes.Role(newRoleId, _roleName);
    rolesById[newRoleId] = role;

    for (uint256 i = 0; i < _permissions.length; i++) {
      // only allow contract owner to add permission owner to role
      if (
        _msgSender() != owner() &&
        Utils.isEqual(_permissions[i], Permissions.Owner)
      ) {
        revert Errors.OwnerPermissionNotAllowed();
      }

      bytes32 _permission = bytes32(abi.encodePacked(_permissions[i]));
      permissionsByRoleId[newRoleId].push(_permission);
    }

    // loop through entitlements and set entitlement data for role
    for (uint256 i = 0; i < _entitlements.length; i++) {
      address _entitlement = _entitlements[i].module;
      bytes memory _entitlementData = _entitlements[i].data;

      // check for empty address or data
      if (_entitlement == address(0) || _entitlementData.length == 0) {
        continue;
      }

      // check if entitlement is valid
      if (hasEntitlement[_entitlement] == false) {
        revert Errors.EntitlementNotWhitelisted();
      }

      // set entitlement data for role
      _addRoleToEntitlement(newRoleId, _entitlement, _entitlementData);
    }

    emit Events.RoleCreated(_msgSender(), newRoleId, _roleName, networkId);

    return newRoleId;
  }

  /// @inheritdoc ISpace
  function updateRole(uint256 _roleId, string memory _roleName) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    // check not renaming owner role
    if (_roleId == ownerRoleId) {
      revert Errors.NotAllowed();
    }

    // check if role exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    if (bytes(_roleName).length == 0) {
      revert Errors.InvalidParameters();
    }

    rolesById[_roleId].name = _roleName;

    emit Events.RoleUpdated(_msgSender(), _roleId, _roleName, networkId);
  }

  /// @inheritdoc ISpace
  function removeRole(uint256 _roleId) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    // check not removing owner role
    if (_roleId == ownerRoleId) {
      revert Errors.NotAllowed();
    }

    // check if role exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    // check if role is used in entitlements
    if (entitlementIdsByRoleId[_roleId].length > 0) {
      revert Errors.RoleIsAssignedToEntitlement();
    }

    // delete role
    delete rolesById[_roleId];

    // delete permissions of role
    delete permissionsByRoleId[_roleId];

    emit Events.RoleRemoved(_msgSender(), _roleId, networkId);
  }

  /// @inheritdoc ISpace
  function getRoleById(
    uint256 _roleId
  ) external view returns (DataTypes.Role memory) {
    return rolesById[_roleId];
  }

  /// @inheritdoc ISpace
  function addPermissionToRole(
    uint256 _roleId,
    string memory _permission
  ) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    // cannot add owner permission to role
    if (Utils.isEqual(_permission, Permissions.Owner)) {
      revert Errors.NotAllowed();
    }

    // check if role exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    bytes32 _permissionHash = bytes32(abi.encodePacked(_permission));

    // check if permission already exists
    for (uint256 i = 0; i < permissionsByRoleId[_roleId].length; i++) {
      if (permissionsByRoleId[_roleId][i] == _permissionHash) {
        revert Errors.PermissionAlreadyExists();
      }
    }

    // add permission to role
    permissionsByRoleId[_roleId].push(_permissionHash);
  }

  /// @inheritdoc ISpace
  function getPermissionsByRoleId(
    uint256 _roleId
  ) external view override returns (bytes32[] memory) {
    return permissionsByRoleId[_roleId];
  }

  /// @inheritdoc ISpace
  function removePermissionFromRole(
    uint256 _roleId,
    string memory _permission
  ) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    if (Utils.isEqual(_permission, Permissions.Owner)) {
      revert Errors.NotAllowed();
    }

    // check if role exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    bytes32 _permissionHash = bytes32(abi.encodePacked(_permission));

    // check if permission exists
    for (uint256 i = 0; i < permissionsByRoleId[_roleId].length; i++) {
      if (permissionsByRoleId[_roleId][i] != _permissionHash) continue;

      // remove permission from role
      permissionsByRoleId[_roleId][i] = permissionsByRoleId[_roleId][
        permissionsByRoleId[_roleId].length - 1
      ];
      permissionsByRoleId[_roleId].pop();
      return;
    }
  }

  /// ***** Entitlement Management *****

  /// @inheritdoc ISpace
  function getEntitlementIdsByRoleId(
    uint256 _roleId
  ) external view returns (bytes32[] memory) {
    return entitlementIdsByRoleId[_roleId];
  }

  /// @inheritdoc ISpace
  function isEntitledToChannel(
    string calldata _channelId,
    address _user,
    string calldata _permission
  ) external view returns (bool _entitled) {
    for (uint256 i = 0; i < entitlements.length; i++) {
      if (
        _isEntitled(_channelId, _user, bytes32(abi.encodePacked(_permission)))
      ) {
        _entitled = true;
      }
    }
  }

  /// @inheritdoc ISpace
  function isEntitledToSpace(
    address _user,
    string calldata _permission
  ) external view returns (bool _entitled) {
    for (uint256 i = 0; i < entitlements.length; i++) {
      if (_isEntitled("", _user, bytes32(abi.encodePacked(_permission)))) {
        _entitled = true;
      }
    }
  }

  /// @inheritdoc ISpace
  function getEntitlements() external view returns (address[] memory) {
    return entitlements;
  }

  /// @inheritdoc ISpace
  function setEntitlement(address _entitlement, bool _whitelist) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    // validate entitlement interface
    _validateEntitlementInterface(_entitlement);

    // check if entitlement already exists
    if (_whitelist && hasEntitlement[_entitlement]) {
      revert Errors.EntitlementAlreadyWhitelisted();
    }

    // check if removing a default entitlement
    if (!_whitelist && defaultEntitlements[_entitlement]) {
      revert Errors.NotAllowed();
    }

    _setEntitlement(_entitlement, _whitelist);
  }

  /// @inheritdoc ISpace
  function removeRoleFromEntitlement(
    uint256 _roleId,
    DataTypes.Entitlement calldata _entitlement
  ) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    // check not removing owner role
    if (_roleId == ownerRoleId) {
      revert Errors.NotAllowed();
    }

    // check if entitlement is whitelisted
    if (!hasEntitlement[_entitlement.module]) {
      revert Errors.EntitlementNotWhitelisted();
    }

    // check roleid exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    // create entitlement id
    bytes32 entitlementId = keccak256(
      abi.encodePacked(_roleId, _entitlement.data)
    );

    // remove entitlementId from entitlementIdsByRoleId
    bytes32[] storage entitlementIds = entitlementIdsByRoleId[_roleId];
    for (uint256 i = 0; i < entitlementIds.length; i++) {
      if (entitlementId != entitlementIds[i]) continue;

      entitlementIds[i] = entitlementIds[entitlementIds.length - 1];
      entitlementIds.pop();
      break;
    }

    IEntitlement(_entitlement.module).removeEntitlement(
      _roleId,
      _entitlement.data
    );
  }

  /// @inheritdoc ISpace
  function addRoleToEntitlement(
    uint256 _roleId,
    DataTypes.Entitlement memory _entitlement
  ) external {
    _isAllowed("", Permissions.ModifySpacePermissions);

    if (!hasEntitlement[_entitlement.module]) {
      revert Errors.EntitlementNotWhitelisted();
    }

    // check that role id exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    _addRoleToEntitlement(_roleId, _entitlement.module, _entitlement.data);
  }

  /// @inheritdoc ISpace
  function addRoleToChannel(
    string calldata _channelId,
    address _entitlement,
    uint256 _roleId
  ) external {
    _isAllowed(_channelId, Permissions.ModifySpacePermissions);

    if (!hasEntitlement[_entitlement]) {
      revert Errors.EntitlementNotWhitelisted();
    }

    // check that role id exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    IEntitlement(_entitlement).addRoleIdToChannel(_channelId, _roleId);
  }

  /// @inheritdoc ISpace
  function removeRoleFromChannel(
    string calldata _channelId,
    address _entitlement,
    uint256 _roleId
  ) external {
    _isAllowed(_channelId, Permissions.ModifySpacePermissions);

    if (!hasEntitlement[_entitlement]) {
      revert Errors.EntitlementNotWhitelisted();
    }

    // check that role id exists
    if (rolesById[_roleId].roleId == 0) {
      revert Errors.RoleDoesNotExist();
    }

    IEntitlement(_entitlement).removeRoleIdFromChannel(_channelId, _roleId);
  }

  /// ***** Internal *****
  function _addRoleToEntitlement(
    uint256 _roleId,
    address _entitlement,
    bytes memory _entitlementData
  ) internal {
    bytes32 entitlementId = keccak256(
      abi.encodePacked(_roleId, _entitlementData)
    );

    // check that entitlementId does not already exist
    // this is to prevent duplicate entries
    // but could lead to wanting to use the same entitlement data and role id
    // on different entitlement contracts
    bytes32[] memory entitlementIds = entitlementIdsByRoleId[_roleId];
    for (uint256 i = 0; i < entitlementIds.length; i++) {
      if (entitlementIds[i] == entitlementId) {
        revert Errors.EntitlementAlreadyExists();
      }
    }

    // keep track of which entitlements are associated with a role
    entitlementIdsByRoleId[_roleId].push(entitlementId);

    IEntitlement(_entitlement).setEntitlement(_roleId, _entitlementData);
  }

  function _isAllowed(
    string memory _channelId,
    string memory _permission
  ) internal view {
    if (
      _msgSender() == owner() ||
      (!disabled &&
        _isEntitled(
          _channelId,
          _msgSender(),
          bytes32(abi.encodePacked(_permission))
        ))
    ) {
      return;
    } else {
      revert Errors.NotAllowed();
    }
  }

  function _setEntitlement(address _entitlement, bool _whitelist) internal {
    // set entitlement on mapping
    hasEntitlement[_entitlement] = _whitelist;

    // if user wants to whitelist, add to entitlements array
    if (_whitelist) {
      entitlements.push(_entitlement);
    } else {
      // remove from entitlements array
      for (uint256 i = 0; i < entitlements.length; i++) {
        if (_entitlement != entitlements[i]) continue;
        entitlements[i] = entitlements[entitlements.length - 1];
        entitlements.pop();
        break;
      }
    }
  }

  function _isEntitled(
    string memory _channelId,
    address _user,
    bytes32 _permission
  ) internal view returns (bool _entitled) {
    for (uint256 i = 0; i < entitlements.length; i++) {
      if (
        IEntitlement(entitlements[i]).isEntitled(_channelId, _user, _permission)
      ) {
        _entitled = true;
      }
    }
  }

  function _validateEntitlementInterface(
    address entitlementAddress
  ) internal view {
    if (
      IERC165(entitlementAddress).supportsInterface(
        type(IEntitlement).interfaceId
      ) == false
    ) revert Errors.EntitlementModuleNotSupported();
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlySpaceOwner {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/** Interfaces */
import {ISpaceFactory} from "./interfaces/ISpaceFactory.sol";
import {ISpaceOwner} from "./interfaces/ISpaceOwner.sol";
import {IEntitlement} from "./interfaces/IEntitlement.sol";

/** Libraries */
import {Permissions} from "./libraries/Permissions.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";
import {Utils} from "./libraries/Utils.sol";

/** Contracts */
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {TokenEntitlement} from "./entitlements/TokenEntitlement.sol";
import {UserEntitlement} from "./entitlements/UserEntitlement.sol";
import {Space} from "./Space.sol";

contract SpaceFactory is
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  UUPSUpgradeable,
  ISpaceFactory
{
  string internal constant everyoneRoleName = "Everyone";
  string internal constant ownerRoleName = "Owner";

  address public SPACE_IMPLEMENTATION_ADDRESS;
  address public TOKEN_IMPLEMENTATION_ADDRESS;
  address public USER_IMPLEMENTATION_ADDRESS;
  address public SPACE_TOKEN_ADDRESS;

  string[] public ownerPermissions;
  mapping(bytes32 => address) public spaceByHash;
  mapping(bytes32 => uint256) public tokenByHash;

  function initialize(
    address _space,
    address _tokenEntitlement,
    address _userEntitlement,
    address _spaceToken,
    string[] memory _permissions
  ) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ReentrancyGuard_init();

    SPACE_IMPLEMENTATION_ADDRESS = _space;
    TOKEN_IMPLEMENTATION_ADDRESS = _tokenEntitlement;
    USER_IMPLEMENTATION_ADDRESS = _userEntitlement;
    SPACE_TOKEN_ADDRESS = _spaceToken;

    for (uint256 i = 0; i < _permissions.length; i++) {
      ownerPermissions.push(_permissions[i]);
    }
  }

  /// @inheritdoc ISpaceFactory
  function updateImplementations(
    address _space,
    address _tokenEntitlement,
    address _userEntitlement
  ) external onlyOwner {
    if (_space != address(0)) SPACE_IMPLEMENTATION_ADDRESS = _space;
    if (_tokenEntitlement != address(0))
      TOKEN_IMPLEMENTATION_ADDRESS = _tokenEntitlement;
    if (_userEntitlement != address(0))
      USER_IMPLEMENTATION_ADDRESS = _userEntitlement;
  }

  /// @inheritdoc ISpaceFactory
  function createSpace(
    string calldata spaceName,
    string calldata spaceNetworkId,
    string calldata spaceMetadata,
    string[] calldata _everyonePermissions,
    DataTypes.CreateSpaceExtraEntitlements calldata _extraEntitlements
  ) external nonReentrant returns (address _spaceAddress) {
    // validate space name
    Utils.validateName(spaceName);

    // validate space network id
    if (bytes(spaceNetworkId).length == 0) {
      revert Errors.InvalidParameters();
    }

    // hash the network id
    bytes32 _networkHash = keccak256(bytes(spaceNetworkId));

    // validate that the network id hasn't been used before
    if (spaceByHash[_networkHash] != address(0)) {
      revert Errors.SpaceAlreadyRegistered();
    }

    // mint space nft to owner
    uint256 _tokenId = ISpaceOwner(SPACE_TOKEN_ADDRESS).mintTo(
      _msgSender(),
      spaceMetadata
    );

    // save token id to mapping
    tokenByHash[_networkHash] = _tokenId;

    // deploy token entitlement module
    address _tokenEntitlement = address(
      new ERC1967Proxy(
        TOKEN_IMPLEMENTATION_ADDRESS,
        abi.encodeCall(TokenEntitlement.initialize, ())
      )
    );

    // deploy user entitlement module
    address _userEntitlement = address(
      new ERC1967Proxy(
        USER_IMPLEMENTATION_ADDRESS,
        abi.encodeCall(UserEntitlement.initialize, ())
      )
    );

    address[] memory _entitlements = new address[](2);
    _entitlements[0] = _tokenEntitlement;
    _entitlements[1] = _userEntitlement;

    // deploy the space contract
    _spaceAddress = address(
      new ERC1967Proxy(
        SPACE_IMPLEMENTATION_ADDRESS,
        abi.encodeCall(
          Space.initialize,
          (spaceName, spaceNetworkId, _entitlements)
        )
      )
    );

    // save space address to mapping
    spaceByHash[_networkHash] = _spaceAddress;

    // set space on entitlement modules
    for (uint256 i = 0; i < _entitlements.length; i++) {
      IEntitlement(_entitlements[i]).setSpace(_spaceAddress);
    }

    _createOwnerEntitlement(_spaceAddress, _tokenEntitlement, _tokenId);
    _createEveryoneEntitlement(
      _spaceAddress,
      _userEntitlement,
      _everyonePermissions
    );
    _createExtraEntitlements(
      _spaceAddress,
      _tokenEntitlement,
      _userEntitlement,
      _extraEntitlements
    );

    Space(_spaceAddress).transferOwnership(_msgSender());

    emit Events.SpaceCreated(_spaceAddress, _msgSender(), spaceNetworkId);
  }

  function addOwnerPermissions(
    string[] calldata _permissions
  ) external onlyOwner {
    // check permission doesn't already exist
    for (uint256 i = 0; i < _permissions.length; i++) {
      for (uint256 j = 0; j < ownerPermissions.length; j++) {
        if (Utils.isEqual(_permissions[i], ownerPermissions[j])) {
          revert Errors.PermissionAlreadyExists();
        }
      }

      // add permission to initial permissions
      ownerPermissions.push(_permissions[i]);
    }
  }

  function getTokenIdByNetworkId(
    string calldata spaceNetworkId
  ) external view returns (uint256) {
    bytes32 _networkHash = keccak256(bytes(spaceNetworkId));
    return tokenByHash[_networkHash];
  }

  function getOwnerPermissions() external view returns (string[] memory) {
    return ownerPermissions;
  }

  /// ****************************
  /// Internal functions
  /// ****************************
  function _createExtraEntitlements(
    address spaceAddress,
    address tokenAddress,
    address userAddress,
    DataTypes.CreateSpaceExtraEntitlements memory _extraEntitlements
  ) internal {
    if (_extraEntitlements.permissions.length == 0) return;

    DataTypes.Entitlement[] memory _entitlements = new DataTypes.Entitlement[](
      1
    );
    _entitlements[0] = DataTypes.Entitlement(address(0), "");

    uint256 additionalRoleId = Space(spaceAddress).createRole(
      _extraEntitlements.roleName,
      _extraEntitlements.permissions,
      _entitlements
    );

    // check entitlementdata has users
    if (_extraEntitlements.users.length > 0) {
      Space(spaceAddress).addRoleToEntitlement(
        additionalRoleId,
        DataTypes.Entitlement(userAddress, abi.encode(_extraEntitlements.users))
      );
    }

    // check entitlementdata has tokens
    if (_extraEntitlements.tokens.length == 0) return;

    Space(spaceAddress).addRoleToEntitlement(
      additionalRoleId,
      DataTypes.Entitlement(tokenAddress, abi.encode(_extraEntitlements.tokens))
    );
  }

  function _createOwnerEntitlement(
    address spaceAddress,
    address tokenAddress,
    uint256 tokenId
  ) internal {
    // create external token struct
    DataTypes.ExternalToken[] memory tokens = new DataTypes.ExternalToken[](1);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;

    // assign token data to struct
    tokens[0] = DataTypes.ExternalToken({
      contractAddress: SPACE_TOKEN_ADDRESS,
      quantity: 1,
      isSingleToken: true,
      tokenIds: tokenIds
    });

    DataTypes.Entitlement[] memory _entitlements = new DataTypes.Entitlement[](
      1
    );
    _entitlements[0] = DataTypes.Entitlement({
      module: tokenAddress,
      data: abi.encode(tokens)
    });

    // create owner role with all permissions
    uint256 ownerRoleId = Space(spaceAddress).createRole(
      ownerRoleName,
      ownerPermissions,
      _entitlements
    );

    Space(spaceAddress).setOwnerRoleId(ownerRoleId);
  }

  function _createEveryoneEntitlement(
    address spaceAddress,
    address userAddress,
    string[] memory _permissions
  ) internal {
    DataTypes.Entitlement[] memory _entitlements = new DataTypes.Entitlement[](
      1
    );

    address[] memory users = new address[](1);
    users[0] = Utils.EVERYONE_ADDRESS;

    _entitlements[0] = DataTypes.Entitlement({
      module: userAddress,
      data: abi.encode(users)
    });

    Space(spaceAddress).createRole(
      everyoneRoleName,
      _permissions,
      _entitlements
    );
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {ISpace} from "../interfaces/ISpace.sol";
import {IEntitlement} from "../interfaces/IEntitlement.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TokenEntitlement is
  Initializable,
  ERC165Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IEntitlement
{
  struct Entitlement {
    uint256 roleId;
    address grantedBy;
    uint256 grantedTime;
    DataTypes.ExternalToken[] tokens;
  }

  string public constant name = "Token Entitlement";
  string public constant description = "Entitlement for tokens";
  string public constant moduleType = "TokenEntitlement";

  address public SPACE_ADDRESS;

  mapping(bytes32 => Entitlement) public entitlementsById;
  mapping(bytes32 => uint256[]) roleIdsByChannelId;
  mapping(uint256 => bytes32[]) entitlementIdsByRoleId;
  bytes32[] public allEntitlementIds;

  modifier onlySpace() {
    require(
      _msgSender() == owner() || _msgSender() == SPACE_ADDRESS,
      "Space: only space"
    );
    _;
  }

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __ERC165_init();
    __Ownable_init();
  }

  function setSpace(address _space) external onlyOwner {
    SPACE_ADDRESS = _space;
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return
      interfaceId == type(IEntitlement).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function isEntitled(
    string calldata channelId,
    address user,
    bytes32 permission
  ) external view returns (bool) {
    if (bytes(channelId).length > 0) {
      return
        _isEntitledToChannel(
          keccak256(abi.encodePacked(channelId)),
          user,
          permission
        );
    } else {
      return _isEntitledToSpace(user, permission);
    }
  }

  function setEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external onlySpace returns (bytes32 entitlementId) {
    entitlementId = keccak256(abi.encodePacked(roleId, entitlementData));

    DataTypes.ExternalToken[] memory externalTokens = abi.decode(
      entitlementData,
      (DataTypes.ExternalToken[])
    );

    //Adds all the tokens passed in to gate this role with an AND
    if (externalTokens.length == 0) {
      revert Errors.EntitlementNotFound();
    }

    for (uint256 i = 0; i < externalTokens.length; i++) {
      if (externalTokens[i].contractAddress == address(0)) {
        revert Errors.AddressNotFound();
      }

      if (externalTokens[i].quantity == 0) {
        revert Errors.QuantityNotFound();
      }

      entitlementsById[entitlementId].tokens.push(externalTokens[i]);
    }

    entitlementsById[entitlementId].roleId = roleId;
    entitlementsById[entitlementId].grantedBy = _msgSender();
    entitlementsById[entitlementId].grantedTime = block.timestamp;

    // set so we can look up all entitlements by role id
    entitlementIdsByRoleId[roleId].push(entitlementId);
    allEntitlementIds.push(entitlementId);
  }

  // @inheritdoc IEntitlement
  function removeEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external onlySpace returns (bytes32 entitlementId) {
    entitlementId = keccak256(abi.encodePacked(roleId, entitlementData));

    // remove from roleIdsByChannelId
    bytes32[] storage entitlementIdsFromRoleIds = entitlementIdsByRoleId[
      roleId
    ];

    _removeFromArray(entitlementIdsFromRoleIds, entitlementId);

    // remove from allEntitlementIds
    _removeFromArray(allEntitlementIds, entitlementId);

    // remove from entitlementsById
    delete entitlementsById[entitlementId];
  }

  // @inheritdoc IEntitlement
  function getEntitlementDataByRoleId(
    uint256 roleId
  ) external view returns (bytes[] memory) {
    bytes32[] memory entitlementIds = entitlementIdsByRoleId[roleId];

    bytes[] memory entitlements = new bytes[](entitlementIds.length);

    for (uint256 i = 0; i < entitlementIds.length; i++) {
      entitlements[i] = abi.encode(entitlementsById[entitlementIds[i]].tokens);
    }

    return entitlements;
  }

  function getUserRoles(
    address user
  ) external view returns (DataTypes.Role[] memory) {
    DataTypes.Role[] memory roles = new DataTypes.Role[](
      allEntitlementIds.length
    );

    for (uint256 i = 0; i < allEntitlementIds.length; i++) {
      if (!_isTokenEntitled(user, allEntitlementIds[i])) continue;
      uint256 roleId = entitlementsById[allEntitlementIds[i]].roleId;
      roles[i] = ISpace(SPACE_ADDRESS).getRoleById(roleId);
    }

    return roles;
  }

  function addRoleIdToChannel(
    string calldata channelId,
    uint256 roleId
  ) external onlySpace {
    bytes32 _channelId = keccak256(abi.encodePacked(channelId));

    uint256[] memory roleIds = roleIdsByChannelId[_channelId];

    for (uint256 i = 0; i < roleIds.length; i++) {
      if (roleIds[i] == roleId) {
        revert Errors.RoleAlreadyExists();
      }
    }

    roleIdsByChannelId[_channelId].push(roleId);
  }

  function removeRoleIdFromChannel(
    string calldata channelId,
    uint256 roleId
  ) external onlySpace {
    bytes32 _channelId = keccak256(abi.encodePacked(channelId));
    uint256[] storage roleIds = roleIdsByChannelId[_channelId];

    for (uint256 i = 0; i < roleIds.length; i++) {
      if (roleIds[i] != roleId) continue;
      roleIds[i] = roleIds[roleIds.length - 1];
      roleIds.pop();
      break;
    }
  }

  // A convenience function to generate types for the client to encode the token struct. No implementation needed.
  function encodeExternalTokens(
    DataTypes.ExternalToken[] calldata tokens
  ) public pure {}

  function _isEntitledToChannel(
    bytes32 channelId,
    address user,
    bytes32 permission
  ) internal view returns (bool _entitled) {
    uint256[] memory channelRoleIds = roleIdsByChannelId[channelId];

    for (uint256 i = 0; i < channelRoleIds.length; i++) {
      uint256 roleId = channelRoleIds[i];

      if (_validateRolePermission(roleId, permission)) {
        bytes32[] memory entitlementIdsFromRoleIds = entitlementIdsByRoleId[
          roleId
        ];

        for (uint256 j = 0; j < entitlementIdsFromRoleIds.length; j++) {
          if (_isTokenEntitled(user, entitlementIdsFromRoleIds[j])) {
            _entitled = true;
          }
        }
      }
    }
  }

  function _removeFromArray(bytes32[] storage array, bytes32 value) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] != value) continue;
      array[i] = array[array.length - 1];
      array.pop();
      break;
    }
  }

  function _isEntitledToSpace(
    address user,
    bytes32 permission
  ) internal view returns (bool _entitled) {
    // get valid role ids from all entitlement ids
    for (uint256 i = 0; i < allEntitlementIds.length; i++) {
      bytes32 entitlementId = allEntitlementIds[i];
      Entitlement memory entitlement = entitlementsById[entitlementId];
      uint256 roleId = entitlement.roleId;

      if (_validateRolePermission(roleId, permission)) {
        bytes32[] memory entitlementIdsFromRoleId = entitlementIdsByRoleId[
          roleId
        ];

        for (uint256 j = 0; j < entitlementIdsFromRoleId.length; j++) {
          if (_isTokenEntitled(user, entitlementIdsFromRoleId[j])) {
            _entitled = true;
          }
        }
      }
    }
  }

  function _isTokenEntitled(
    address user,
    bytes32 entitlementId
  ) internal view returns (bool) {
    DataTypes.ExternalToken[] memory tokens = entitlementsById[entitlementId]
      .tokens;

    bool entitled = false;

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 quantity = tokens[i].quantity;
      address contractAddress = tokens[i].contractAddress;
      uint256[] memory tokenIds = tokens[i].tokenIds;
      bool isSingleToken = tokens[i].isSingleToken;

      if (
        _isERC721Entitled(
          contractAddress,
          user,
          quantity,
          isSingleToken,
          tokenIds
        ) ||
        _isERC20Entitled(contractAddress, user, quantity) ||
        _isERC1155Entitled(
          contractAddress,
          user,
          quantity,
          isSingleToken,
          tokenIds
        )
      ) {
        entitled = true;
      } else {
        entitled = false;
        break;
      }
    }

    return entitled;
  }

  function _isERC1155Entitled(
    address contractAddress,
    address user,
    uint256 quantity,
    bool isSingleToken,
    uint256[] memory tokenTypes
  ) internal view returns (bool) {
    for (uint256 i = 0; i < tokenTypes.length; i++) {
      try IERC1155(contractAddress).balanceOf(user, tokenTypes[i]) returns (
        uint256 balance
      ) {
        if (isSingleToken && balance > 0) {
          return true;
        } else if (!isSingleToken && balance >= quantity) {
          return true;
        }
      } catch {}
    }

    return false;
  }

  function _isERC721Entitled(
    address contractAddress,
    address user,
    uint256 quantity,
    bool isSingleToken,
    uint256[] memory tokenIds
  ) internal view returns (bool) {
    if (isSingleToken) {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        try IERC721(contractAddress).ownerOf(tokenIds[i]) returns (
          address owner
        ) {
          if (owner == user) {
            return true;
          }
        } catch {}
      }
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

  function _validateRolePermission(
    uint256 roleId,
    bytes32 permission
  ) internal view returns (bool) {
    ISpace space = ISpace(SPACE_ADDRESS);

    bytes32[] memory permissions = space.getPermissionsByRoleId(roleId);

    for (uint256 i = 0; i < permissions.length; i++) {
      if (permissions[i] == permission) {
        return true;
      }
    }

    return false;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {ISpace} from "../interfaces/ISpace.sol";
import {IEntitlement} from "../interfaces/IEntitlement.sol";

import {Errors} from "../libraries/Errors.sol";
import {Utils} from "../libraries/Utils.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UserEntitlement is
  Initializable,
  ERC165Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IEntitlement
{
  string public constant name = "User Entitlement";
  string public constant description = "Entitlement for users";
  string public constant moduleType = "UserEntitlement";

  address public SPACE_ADDRESS;

  uint256 entitlementCount;

  struct Entitlement {
    uint256 roleId;
    address grantedBy;
    uint256 grantedTime;
    address[] users;
  }

  mapping(bytes32 => Entitlement) public entitlementsById;
  mapping(bytes32 => uint256[]) roleIdsByChannelId;
  mapping(uint256 => bytes32[]) entitlementIdsByRoleId;
  mapping(address => bytes32[]) entitlementIdsByUser;

  modifier onlySpace() {
    require(
      _msgSender() == owner() || _msgSender() == SPACE_ADDRESS,
      "Space: only space"
    );
    _;
  }

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __ERC165_init();
    __Ownable_init();
  }

  function setSpace(address _space) external onlyOwner {
    SPACE_ADDRESS = _space;
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return
      interfaceId == type(IEntitlement).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @inheritdoc IEntitlement
  function isEntitled(
    string calldata channelId,
    address user,
    bytes32 permission
  ) external view returns (bool) {
    if (bytes(channelId).length > 0) {
      return
        _isEntitledToChannel(
          keccak256(abi.encodePacked(channelId)),
          user,
          permission
        );
    } else {
      return _isEntitledToSpace(user, permission);
    }
  }

  function setEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external onlySpace returns (bytes32 entitlementId) {
    entitlementId = keccak256(abi.encodePacked(roleId, entitlementData));

    address[] memory users = abi.decode(entitlementData, (address[]));

    if (users.length == 0) {
      revert Errors.EntitlementNotFound();
    }

    for (uint256 i = 0; i < users.length; i++) {
      address user = users[i];
      if (user == address(0)) {
        revert Errors.AddressNotFound();
      }

      entitlementIdsByUser[user].push(entitlementId);
    }

    entitlementsById[entitlementId] = Entitlement({
      grantedBy: _msgSender(),
      grantedTime: block.timestamp,
      roleId: roleId,
      users: users
    });

    entitlementIdsByRoleId[roleId].push(entitlementId);
  }

  function removeEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external onlySpace returns (bytes32 entitlementId) {
    entitlementId = keccak256(abi.encodePacked(roleId, entitlementData));

    Entitlement memory entitlement = entitlementsById[entitlementId];

    if (entitlement.users.length == 0 || entitlement.roleId == 0) {
      revert Errors.EntitlementNotFound();
    }

    bytes32[] storage entitlementIds = entitlementIdsByRoleId[
      entitlement.roleId
    ];

    _removeFromArray(entitlementIds, entitlementId);

    for (uint256 i = 0; i < entitlement.users.length; i++) {
      address user = entitlement.users[i];
      bytes32[] storage _entitlementIdsByUser = entitlementIdsByUser[user];
      _removeFromArray(_entitlementIdsByUser, entitlementId);
    }

    delete entitlementsById[entitlementId];
  }

  // @inheritdoc IEntitlement
  function getEntitlementDataByRoleId(
    uint256 roleId
  ) external view returns (bytes[] memory) {
    bytes32[] memory entitlementIds = entitlementIdsByRoleId[roleId];

    bytes[] memory entitlements = new bytes[](entitlementIds.length);

    for (uint256 i = 0; i < entitlementIds.length; i++) {
      entitlements[i] = abi.encode(entitlementsById[entitlementIds[i]].users);
    }

    return entitlements;
  }

  function getUserRoles(
    address user
  ) external view returns (DataTypes.Role[] memory) {
    bytes32[] memory entitlementIds = entitlementIdsByUser[user];

    DataTypes.Role[] memory roles = new DataTypes.Role[](entitlementIds.length);

    for (uint256 i = 0; i < entitlementIds.length; i++) {
      Entitlement memory entitlement = entitlementsById[entitlementIds[i]];
      roles[i] = ISpace(SPACE_ADDRESS).getRoleById(entitlement.roleId);
    }

    return roles;
  }

  function addRoleIdToChannel(
    string calldata channelId,
    uint256 roleId
  ) external onlySpace {
    bytes32 _channelId = keccak256(abi.encodePacked(channelId));

    uint256[] memory roles = roleIdsByChannelId[_channelId];

    for (uint256 i = 0; i < roles.length; i++) {
      if (roles[i] == roleId) {
        revert Errors.RoleAlreadyExists();
      }
    }

    roleIdsByChannelId[_channelId].push(roleId);
  }

  function removeRoleIdFromChannel(
    string calldata channelId,
    uint256 roleId
  ) external onlySpace {
    bytes32 _channelId = keccak256(abi.encodePacked(channelId));

    uint256[] storage roleIds = roleIdsByChannelId[_channelId];

    for (uint256 i = 0; i < roleIds.length; i++) {
      if (roleIds[i] != roleId) continue;
      roleIds[i] = roleIds[roleIds.length - 1];
      roleIds.pop();
      break;
    }
  }

  function _removeFromArray(bytes32[] storage array, bytes32 value) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] != value) continue;
      array[i] = array[array.length - 1];
      array.pop();
      break;
    }
  }

  function _isEntitledToChannel(
    bytes32 channelId,
    address user,
    bytes32 permission
  ) internal view returns (bool _entitled) {
    // get role ids mapped to channel
    uint256[] memory channelRoleIds = roleIdsByChannelId[channelId];

    // get all entitlements for a everyone address
    Entitlement[] memory everyone = _getEntitlementByUser(
      Utils.EVERYONE_ADDRESS
    );

    // get all entitlement for a single address
    Entitlement[] memory single = _getEntitlementByUser(user);

    // combine everyone and single entitlements
    Entitlement[] memory validEntitlements = concatArrays(everyone, single);

    // loop over all role ids in a channel
    for (uint256 i = 0; i < channelRoleIds.length; i++) {
      // get each role id
      uint256 roleId = channelRoleIds[i];

      // loop over all the valid entitlements
      for (uint256 j = 0; j < validEntitlements.length; j++) {
        // check if the role id for that channel matches the entitlement role id
        // and if the permission matches the role permission
        if (
          validEntitlements[j].roleId == roleId &&
          _validateRolePermission(validEntitlements[j].roleId, permission)
        ) {
          _entitled = true;
        }
      }
    }
  }

  function _getEntitlementByUser(
    address user
  ) internal view returns (Entitlement[] memory) {
    bytes32[] memory _entitlementIds = entitlementIdsByUser[user];
    Entitlement[] memory _entitlements = new Entitlement[](
      _entitlementIds.length
    );

    for (uint256 i = 0; i < _entitlementIds.length; i++) {
      _entitlements[i] = entitlementsById[_entitlementIds[i]];
    }

    return _entitlements;
  }

  function _isEntitledToSpace(
    address user,
    bytes32 permission
  ) internal view returns (bool) {
    Entitlement[] memory everyone = _getEntitlementByUser(
      Utils.EVERYONE_ADDRESS
    );

    Entitlement[] memory single = _getEntitlementByUser(user);

    Entitlement[] memory validEntitlements = concatArrays(everyone, single);

    for (uint256 i = 0; i < validEntitlements.length; i++) {
      if (_validateRolePermission(validEntitlements[i].roleId, permission)) {
        return true;
      }
    }

    return false;
  }

  function _validateRolePermission(
    uint256 roleId,
    bytes32 permission
  ) internal view returns (bool) {
    ISpace space = ISpace(SPACE_ADDRESS);

    bytes32[] memory permissions = space.getPermissionsByRoleId(roleId);

    for (uint256 i = 0; i < permissions.length; i++) {
      if (permissions[i] == permission) {
        return true;
      }
    }

    return false;
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IEntitlement {
  /// @notice The name of the entitlement module
  function name() external view returns (string memory);

  /// @notice The type of the entitlement module
  function moduleType() external view returns (string memory);

  /// @notice The description of the entitlement module
  function description() external view returns (string memory);

  function setSpace(address _space) external;

  function setEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external returns (bytes32);

  function removeEntitlement(
    uint256 roleId,
    bytes calldata entitlementData
  ) external returns (bytes32);

  function addRoleIdToChannel(
    string calldata channelId,
    uint256 roleId
  ) external;

  function removeRoleIdFromChannel(
    string calldata channelId,
    uint256 roleId
  ) external;

  function isEntitled(
    string calldata channelId,
    address user,
    bytes32 permission
  ) external view returns (bool);

  function getEntitlementDataByRoleId(
    uint256 roleId
  ) external view returns (bytes[] memory);

  function getUserRoles(
    address user
  ) external view returns (DataTypes.Role[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ISpace {
  /// ***** Space Management *****
  function initialize(
    string memory name,
    string memory networkId,
    address[] memory modules
  ) external;

  function setSpaceAccess(bool disabled) external;

  function setOwnerRoleId(uint256 roleId) external;

  /// ***** Channel Management *****
  function getChannelByHash(
    bytes32 channelHash
  ) external view returns (DataTypes.Channel memory);

  function setChannelAccess(string calldata channelId, bool disabled) external;

  function createChannel(
    string memory channelName,
    string memory channelNetworkId,
    uint256[] memory roleIds
  ) external returns (bytes32);

  /// ***** Role Management *****
  function getRoles() external view returns (DataTypes.Role[] memory);

  function createRole(
    string memory roleName,
    string[] memory permissions,
    DataTypes.Entitlement[] memory entitlements
  ) external returns (uint256);

  function updateRole(uint256 roleId, string memory roleName) external;

  function removeRole(uint256 roleId) external;

  function getRoleById(
    uint256 roleId
  ) external view returns (DataTypes.Role memory);

  /// ***** Permission Management *****
  function addPermissionToRole(
    uint256 roleId,
    string memory permission
  ) external;

  function getPermissionsByRoleId(
    uint256 roleId
  ) external view returns (bytes32[] memory);

  function removePermissionFromRole(
    uint256 roleId,
    string memory permission
  ) external;

  /// ***** Entitlement Management *****
  function getEntitlementIdsByRoleId(
    uint256 roleId
  ) external view returns (bytes32[] memory);

  function isEntitledToChannel(
    string calldata channelId,
    address user,
    string calldata permission
  ) external view returns (bool);

  function isEntitledToSpace(
    address user,
    string calldata permission
  ) external view returns (bool);

  function getEntitlements() external view returns (address[] memory);

  function setEntitlement(address entitlement, bool whitelist) external;

  function removeRoleFromEntitlement(
    uint256 roleId,
    DataTypes.Entitlement memory entitlement
  ) external;

  function addRoleToChannel(
    string calldata channelId,
    address entitlement,
    uint256 roleId
  ) external;

  function addRoleToEntitlement(
    uint256 roleId,
    DataTypes.Entitlement memory entitlement
  ) external;

  function removeRoleFromChannel(
    string calldata channelId,
    address entitlement,
    uint256 roleId
  ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ISpaceFactory {
  function updateImplementations(
    address space,
    address tokenEntitlement,
    address userEntitlement
  ) external;

  function createSpace(
    string calldata spaceName,
    string calldata spaceNetworkId,
    string calldata spaceMetadata,
    string[] calldata _everyonePermissions,
    DataTypes.CreateSpaceExtraEntitlements calldata _extraEntitlements
  ) external returns (address);
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ISpaceOwner {
  /// @notice Mints a space nft to a given address
  /// @dev This function is called by the space factory only
  /// @param to The address to mint the nft to
  /// @param tokenURI The token URI of the nft
  /// @return tokenId The id of the minted nft
  function mintTo(
    address to,
    string calldata tokenURI
  ) external returns (uint256);
}

//SPDX-License-Identifier: Apache-20
pragma solidity 0.8.17;

/**
 * @title DataTypes
 * @author HNT Labs
 *
 * @notice A standard library of data types used throughout the Zion Space Manager
 */
library DataTypes {
  struct Channel {
    string name;
    bytes32 channelId;
    uint256 createdAt;
    bool disabled;
  }

  struct Role {
    uint256 roleId;
    string name;
  }

  struct Entitlement {
    address module;
    bytes data;
  }

  struct ExternalToken {
    address contractAddress;
    uint256 quantity;
    bool isSingleToken;
    uint256[] tokenIds;
  }

  /// *********************************
  /// **************DTO****************
  /// *********************************
  /// @notice A struct containing the parameters required for creating a space
  /// @param spaceName The name of the space
  /// @param networkId The network id of the space
  struct CreateSpaceData {
    string spaceName;
    string spaceNetworkId;
    string spaceMetadata;
  }

  /// @notice A struct containing the parameters required for creating a space with a  token entitlement
  struct CreateSpaceExtraEntitlements {
    //The role and permissions to create for the associated users or token entitlements
    string roleName;
    string[] permissions;
    ExternalToken[] tokens;
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
  error EntitlementNotFound();
  error AddressNotFound();
  error QuantityNotFound();
  error EntitlementAlreadyWhitelisted();
  error EntitlementModuleNotSupported();
  error EntitlementNotWhitelisted();
  error EntitlementAlreadyExists();
  error DefaultEntitlementModuleNotSet();
  error SpaceNFTNotSet();
  error RoleIsAssignedToEntitlement();
  error DefaultPermissionsManagerNotSet();
  error SpaceDoesNotExist();
  error ChannelDoesNotExist();
  error PermissionAlreadyExists();
  error NotAllowed();
  error OwnerPermissionNotAllowed();
  error MissingOwnerPermission();
  error RoleDoesNotExist();
  error RoleAlreadyExists();
  error AddRoleFailed();
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library Events {
  event SpaceCreated(
    address indexed spaceAddress,
    address indexed ownerAddress,
    string networkId
  );

  event RoleCreated(
    address indexed caller,
    uint256 indexed roleId,
    string roleName,
    string networkId
  );

  event RoleUpdated(
    address indexed caller,
    uint256 indexed roleId,
    string roleName,
    string networkId
  );

  event RoleRemoved(
    address indexed caller,
    uint256 indexed roleId,
    string networkId
  );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Permissions {
  string public constant Read = "Read";
  string public constant Write = "Write";
  string public constant Invite = "Invite";
  string public constant Redact = "Redact";
  string public constant Ban = "Ban";
  string public constant Ping = "Ping";
  string public constant PinMessage = "PinMessage";
  string public constant ModifyChannelPermissions = "ModifyChannelPermissions";
  string public constant ModifyProfile = "ModifyProfile";
  string public constant Owner = "Owner";
  string public constant AddRemoveChannels = "AddRemoveChannels";
  string public constant ModifySpacePermissions = "ModifySpacePermissions";
  string public constant ModifyChannelDefaults = "ModifyChannelDefaults";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Errors} from "./Errors.sol";

library Utils {
  uint8 internal constant MIN_NAME_LENGTH = 2;
  uint8 internal constant MAX_NAME_LENGTH = 32;
  address public constant EVERYONE_ADDRESS =
    0x0000000000000000000000000000000000000001;

  function isEqual(
    string memory s1,
    string memory s2
  ) internal pure returns (bool) {
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
  }

  /// @notice validates the name of the space
  /// @param name The name of the space
  function validateName(string calldata name) internal pure {
    bytes memory byteName = bytes(name);

    if (byteName.length < MIN_NAME_LENGTH || byteName.length > MAX_NAME_LENGTH)
      revert Errors.NameLengthInvalid();

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

  /// Courtesy of: https://ethereum.stackexchange.com/a/123588/114815
  /// @dev Bubble up the revert from the returnedData (supports Panic, Error & Custom Errors)
  /// @notice This is needed in order to provide some human-readable revert message from a call
  /// @param returnedData Response of the call
  function revertFromReturnedData(bytes memory returnedData) internal pure {
    if (returnedData.length < 4) {
      // case 1: catch all
      revert("unhandled revert");
    } else {
      bytes4 errorSelector;
      assembly {
          errorSelector := mload(add(returnedData, 0x20))
      }
      if (errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */) {
        // case 2: Panic(uint256) (Defined since 0.8.0)
        // solhint-disable-next-line max-line-length
        // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
        string memory reason = "panicked: 0x__";
        uint errorCode;
        assembly {
          errorCode := mload(add(returnedData, 0x24))
          let reasonWord := mload(add(reason, 0x20))
          // [0..9] is converted to ['0'..'9']
          // [0xa..0xf] is not correctly converted to ['a'..'f']
          // but since panic code doesn't have those cases, we will ignore them for now!
          let e1 := add(and(errorCode, 0xf), 0x30)
          let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
          reasonWord := or(
            and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
            or(e2, e1))
          mstore(add(reason, 0x20), reasonWord)
        }
        revert(reason);
      } else {
        // case 3: Error(string) (Defined at least since 0.7.0)
        // case 4: Custom errors (Defined since 0.8.0)
        uint len = returnedData.length;
        assembly {
          revert(add(returnedData, 32), len)
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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