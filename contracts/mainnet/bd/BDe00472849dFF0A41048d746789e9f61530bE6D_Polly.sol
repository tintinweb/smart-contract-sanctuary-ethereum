/*

       -*%%+++*#+:              .+     --
        [email protected]*     *@*           -#@-  .=#%
        %@.      @@:          [email protected]*    :@:
       [email protected]*       @@.          [email protected]    #*  :=     --
       #@.      [email protected]#  +*+#:    @=    [email protected]: *=%*    *@
      [email protected]*      :@#.-%-  [email protected]   +%    [email protected]*.+  [email protected]    =#
      *@.    .+%= =%.   [email protected] :@-    *@     [email protected]:   *-
     :@#---===-  [email protected]    #@  %%    :@-     [email protected]  .#
     #@:        [email protected]*    [email protected]+ [email protected]:    ##      [email protected]  #.
    :@%         *@.    *% [email protected]+    :@.      [email protected] =:
    #@-         @*    [email protected] +%  =. %+ .=    [email protected]::=
   :@#          @=   [email protected] [email protected]==  [email protected]+-     [email protected]*
   *@-          #*  *#.  #@*.  :@@+       [email protected]+
.:=++=:.         ===:    +:    :=.        +=
                                         +-
                                       =+.
                                  +*-=+.

v1

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PollyModule.sol";

interface IPolly {


  struct ModuleBase {
    string name;
    uint version;
    address implementation;
  }

  struct ModuleInstance {
    string name;
    uint version;
    address location;
  }

  struct Config {
    string name;
    address owner;
    ModuleInstance[] modules;
  }


  function updateModule(string memory name_, address implementation_) external;
  function getModule(string memory name_, uint version_) external view returns(IPolly.ModuleBase memory);
  function moduleExists(string memory name_, uint version_) external view returns(bool exists_);
  function useModule(uint config_id_, IPolly.ModuleInstance memory mod_) external;
  function useModules(uint config_id_, IPolly.ModuleInstance[] memory mods_) external;
  function createConfig(string memory name_, IPolly.ModuleInstance[] memory mod_) external;
  function getConfigsForOwner(address owner_, uint page_) external view returns(uint[] memory);
  function getConfig(uint config_id_) external view returns(IPolly.Config memory);
  function isConfigOwner(uint config_id_, address check_) external view returns(bool);
  function transferConfig(uint config_id_, address to_) external;


}


contract Polly is Ownable {


    /// PROPERTIES ///

    mapping(string => mapping(uint => address)) private _modules;
    mapping(string => uint) private _module_versions;

    uint private _config_id;
    mapping(uint => IPolly.Config) private _configs;
    mapping(uint => address) private _config_owners;
    mapping(address => uint) private _owner_configs;
    mapping(address => uint[]) private _configs_for_owner;

    //////////////////




    /// EVENTS ///

    event moduleUpdated(
      string indexed name, uint version, address implementation
    );

    event configCreated(
      uint id, string name, address indexed by
    );

    event configUpdated(
      uint indexed id, string indexed module_name, uint indexed module_version
    );

    event configTransferred(
      uint indexed id, address indexed from, address indexed to
    );

    //////////////


    /// @dev restricts access to owner of config
    modifier onlyConfigOwner(uint config_id_) {
      require(isConfigOwner(config_id_, msg.sender), 'NOT_CONFIG_OWNER');
      _;
    }

    /// @dev used when passing multiple modules
    modifier onlyValidModules(IPolly.ModuleInstance[] memory mods_) {
      for(uint i = 0; i < mods_.length; i++){
        require(moduleExists(mods_[i].name, mods_[i].version), string(abi.encodePacked('MODULE_DOES_NOT_EXIST: ', mods_[i].name)));
      }
      _;
    }


    /// MODULES ///

    /// @dev adds or updates a given module implemenation
    function updateModule(string memory name_, address implementation_) public onlyOwner {

      uint version_ = _module_versions[name_]+1;

      IPolly.ModuleBase memory module_ = IPolly.ModuleBase(
        name_, version_, implementation_
      );

      _modules[module_.name][module_.version] = module_.implementation;
      _module_versions[module_.name] = module_.version;

      emit moduleUpdated(module_.name, module_.version, module_.implementation);

    }


    /// @dev retrieves a specific module version base
    function getModule(string memory name_, uint version_) public view returns(IPolly.ModuleBase memory){

      if(version_ < 1)
        version_ = _module_versions[name_];

      return IPolly.ModuleBase(name_, version_, _modules[name_][version_]);

    }

    /// @dev check if a module version exists
    function moduleExists(string memory name_, uint version_) public view returns(bool exists_){
      if(_modules[name_][version_] != address(0))
        exists_ = true;
      return exists_;
    }


    /// @dev check if a module version exists
    function _cloneAndAttachModule(uint config_id_, string memory name_, uint version_) private {

      address implementation_ = _modules[name_][version_];

      IPollyModule module_ = IPollyModule(Clones.clone(implementation_));
      module_.init(msg.sender);

      _attachModule(config_id_, name_, version_, address(module_));

    }

    function _attachModule(uint config_id_, string memory name_, uint version_, address location_) private {
      _configs[config_id_].modules.push(IPolly.ModuleInstance(name_, version_, location_));
      emit configUpdated(config_id_, name_, version_);
    }

    function _useModule(uint config_id_, IPolly.ModuleInstance memory mod_) private {

      IPolly.ModuleBase memory base_ = getModule(mod_.name, mod_.version);
      IPollyModule.ModuleInfo memory base_info_ = IPollyModule(_modules[mod_.name][mod_.version]).getModuleInfo();

      // Location is 0 - proceed to attach or clone
      if(mod_.location == address(0x00)){
        if(base_info_.clone)
          _cloneAndAttachModule(config_id_, base_.name, base_.version);
        else
          _attachModule(config_id_, base_.name, base_.version, base_.implementation);
      }
      else {
        // Reuse - attach module
        _attachModule(config_id_, mod_.name, mod_.version, mod_.location);
      }

    }

    /// @dev add one module to a configuration
    function useModule(uint config_id_, IPolly.ModuleInstance memory mod_) public onlyConfigOwner(config_id_) {

      require(moduleExists(mod_.name, mod_.version), string(abi.encodePacked('MODULE_DOES_NOT_EXIST: ', mod_.name)));

      _useModule(config_id_, mod_);

    }

    /// @dev add multiple modules to a configuration
    function useModules(uint config_id_, IPolly.ModuleInstance[] memory mods_) public onlyConfigOwner(config_id_) onlyValidModules(mods_) {

      for(uint256 i = 0; i < mods_.length; i++) {
        _useModule(config_id_, mods_[i]);
      }

    }



    /// CONFIGS

    /// @dev create a config with a name
    function createConfig(string memory name_, IPolly.ModuleInstance[] memory mod_) public returns(uint) {

      _config_id++;
      _configs[_config_id].name = name_;
      _configs[_config_id].owner = msg.sender;
      _configs_for_owner[msg.sender].push(_config_id);

      useModules(_config_id, mod_);

      emit configCreated(_config_id, name_, msg.sender);

      return _config_id;

    }

    /// @dev retrieve configs for owner
    function getConfigsForOwner(address owner_, uint limit_, uint page_) public view returns(uint[] memory){

      if(limit_ < 1 && page_ < 1){
        return _configs_for_owner[owner_];
      }

      uint[] memory configs_ = new uint[](limit_);
      uint i = 0;
      uint index;
      uint offset = (page_-1)*limit_;
      while(i < limit_ && i < _configs_for_owner[owner_].length){
        index = i+(offset);
        if(_configs_for_owner[owner_].length > index){
          configs_[i] = _configs_for_owner[owner_][index];
        }
        i++;
      }

      return configs_;

    }

    /// @dev get a specific config
    function getConfig(uint config_id_) public view returns(IPolly.Config memory){
      return _configs[config_id_];
    }

    /// @dev check if address is config owner
    function isConfigOwner(uint config_id_, address check_) public view returns(bool){
      IPolly.Config memory config_ = getConfig(config_id_);
      return (config_.owner == check_);
    }

    /// @dev transfer config to another address
    function transferConfig(uint config_id_, address to_) public onlyConfigOwner(config_id_) {

      _configs[config_id_].owner = to_;

      uint[] memory configs_ = getConfigsForOwner(msg.sender, 0, 0);
      uint[] memory new_configs_ = new uint[](configs_.length -1);
      uint ii = 0;
      for (uint i = 0; i < configs_.length; i++) {
        if(configs_[i] == config_id_){
          _configs_for_owner[to_].push(config_id_);
        }
        else {
          new_configs_[ii] = config_id_;
          ii++;
        }
      }

      _configs_for_owner[msg.sender] = new_configs_;

      emit configTransferred(config_id_, msg.sender, to_);

    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPollyModule {

  struct ModuleInfo {
    string name;
    address implementation;
    bool clone;
  }

  function init(address for_) external;
  function didInit() external view returns(bool);
  function getModuleInfo() external returns(IPollyModule.ModuleInfo memory module_);
  function setString(string memory key_, string memory value_) external;
  function setUint(string memory key_, uint value_) external;
  function setAddress(string memory key_, address value_) external;
  function setBytes(string memory key_, bytes memory value_) external;
  function getString(string memory key_) external view returns(string memory);
  function getUint(string memory key_) external view returns(uint);
  function getAddress(string memory key_) external view returns(address);
  function getBytes(string memory key_) external view returns(bytes memory);

}


contract PollyModule is AccessControl {

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bool private _did_init = false;
  mapping(string => string) private _keyStoreStrings;
  mapping(string => uint) private _keyStoreUints;
  mapping(string => bytes) private _keyStoreBytes;
  mapping(string => address) private _keyStoreAddresses;

  constructor(){
    init(msg.sender);
  }

  function init(address for_) public virtual {
    require(!_did_init, 'CAN_NOT_INIT');
    _did_init = true;
    _grantRole(DEFAULT_ADMIN_ROLE, for_);
    _grantRole(MANAGER_ROLE, for_);
  }

  function didInit() public view returns(bool){
    return _did_init;
  }

  function setString(string memory key_, string memory value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreStrings[key_] = value_;
  }
  function setUint(string memory key_, uint value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreUints[key_] = value_;
  }
  function setAddress(string memory key_, address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreAddresses[key_] = value_;
  }
  function setBytes(string memory key_, bytes memory value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreBytes[key_] = value_;
  }
  function getString(string memory key_) public view returns(string memory) {
    return _keyStoreStrings[key_];
  }
  function getUint(string memory key_) public view returns(uint) {
    return _keyStoreUints[key_];
  }
  function getAddress(string memory key_) public view returns(address) {
    return _keyStoreAddresses[key_];
  }
  function getBytes(string memory key_) public view returns(bytes memory) {
    return _keyStoreBytes[key_];
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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