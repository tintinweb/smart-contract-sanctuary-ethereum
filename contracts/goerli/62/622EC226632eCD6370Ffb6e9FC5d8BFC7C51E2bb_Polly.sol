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
import "./PollyConfigurator.sol";

/// @title Polly
/// @author polly.tools
/// @dev Stores and enables deployment of registered Polly module smart contracts
/// @notice Polly allows anyone to deploy registered modules as proxy contracts onchain

/**
 *
 * Polly is a modular smart contract framework that allows anyone to deploy registered modules as proxy contracts onchain.
 * The framework is built and designed by continuousengagement.xyz and is open source.
 */

contract Polly is Ownable {


    enum ModuleType {
        READONLY, CLONE
    }

    enum ParamType {
      UINT, INT, BOOL, STRING, ADDRESS
    }

    /// @dev struct for an uninstantiated module
    struct Module {
      string name;
      uint version;
      string info;
      address implementation;
      bool clone;
    }

    /// @dev struct for an instantiated module
    struct ModuleInstance {
      string name;
      uint version;
      address location;
    }

    /// @dev struct for a module configuration
    struct Config {
      string name;
      string module;
      Param[] params;
    }

    struct Param {
      uint _uint;
      int _int;
      bool _bool;
      string _string;
      address _address;
    }


    /// PROPERTIES ///

    string[] private _module_names; // names of registered modules
    mapping(string => mapping(uint => address)) private _modules; // mapping of registered modules and their versions - name => (id => implementation)
    uint private _module_count; // the total number of registered modules
    mapping(string => uint) private _module_versions; // mapping of registered modules and their latest version - name => version
    mapping(address => mapping(uint => Config)) private _configs; // mapping of module configs - owner => (id => config)
    mapping(address => uint) private _configs_count; // mapping of owner module configs

    //////////////////



    /// EVENTS ///

    event moduleUpdated(
      string indexed indexedName, string name, uint version, address indexed implementation
    );

    event moduleCloned(
      string indexed indexedName, string name, uint version, address location
    );

    event moduleConfigured(
      string indexedName, string name, uint version, Polly.Param[] params
    );


    /// MODULES ///

    /// @dev adds or updates a given module implemenation
    /// @param implementation_ address of the module implementation
    function updateModule(address implementation_) public onlyOwner {

      string memory name_ = PollyModule(implementation_).PMNAME();
      uint version_ = PollyModule(implementation_).PMVERSION();

      require(_modules[name_][version_] == address(0), "MODULE_VERSION_EXISTS");
      require(version_ == _module_versions[name_]+1, "MODULE_VERSION_INVALID");

      _modules[name_][version_] = implementation_; // add module implementation address
      _module_versions[name_] = version_; // update module latest version

      if(version_ == 1)
        _module_names.push(name_); // This is a new module, add to module names mapping

      emit moduleUpdated(name_, name_, version_, implementation_);

    }


    /// @dev retrieves a specific module version base
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return address of the module implementation
    function getModule(string memory name_, uint version_) public view returns(Module memory){

      if(version_ < 1)
        version_ = _module_versions[name_]; // version_ is 0, get latest version

      Polly.ModuleType type_ = PollyModule(_modules[name_][version_]).PMTYPE(); // get module info from stored implementation
      string memory info_ = PollyModule(_modules[name_][version_]).PMINFO(); // get module info from stored implementation
      bool clone_ = type_ == Polly.ModuleType.CLONE;

      return Module(name_, version_, info_, _modules[name_][version_], clone_); // return module

    }


    /// @dev returns a list of modules available
    /// @param limit_ uint maximum number of modules to return
    /// @param page_ uint page of modules to return
    /// @param ascending_ bool sort modules ascending (true) or descending (false)
    /// @return Module[] array of modules
    function getModules(uint limit_, uint page_, bool ascending_) public view returns(Module[] memory){

      uint count_ = _module_names.length; // get total number of modules

      if(limit_ < 1 || limit_ > count_)
        limit_ = count_; // limit_ is 0, get all modules

      if(page_ < 1)
        page_ = 1; // page_ is 0, get first page

      uint i; // iterator
      uint index_; // index of module name in _module_names


      if(ascending_)
        index_ = page_ == 1 ? 0 : (page_-1)*limit_; // ascending, set index to last module result set
      else
        index_ = page_ == 1 ? count_ : count_ - (limit_*(page_-1)); // descending, set index to first module on result set


      if(
        (ascending_ && index_ >= count_) // ascending, index is greater than total number of modules
        || // or
        (!ascending_ && index_ == 0) // descending, index is 0
      )
        return new Module[](0); // no modules available - bail early


      Module[] memory modules_ = new Module[](limit_); // create array of modules

      if(ascending_){

        // ASCENDING
        while(index_ < limit_){
            modules_[i] = getModule(_module_names[index_], 0);
            ++i;
            ++index_;
        }

      }
      else {

        /// DESCENDING
        while(index_ > 0 && i < limit_){
            modules_[i] = getModule(_module_names[index_-1], 0);
            ++i;
            --index_;
        }

      }


      return modules_; // return modules

    }


    /// @dev retrieves the most recent version number for a module
    /// @param name_ string name of the module
    /// @return uint version number of the module
    function getLatestModuleVersion(string memory name_) public view returns(uint){
      return _module_versions[name_];
    }


    /// @dev check if a module version exists
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return exists_ bool true if module version exists
    function moduleExists(string memory name_, uint version_) public view returns(bool exists_){
      if(_modules[name_][version_] != address(0))
        exists_ = true;
      return exists_;
    }


    /// @dev clone a given module
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @return address of the cloned module implementation
    function cloneModule(string memory name_, uint version_) public returns(address) {

      if(version_ == 0)
        version_ = getLatestModuleVersion(name_); // version_ is 0, get latest version

      require(moduleExists(name_, version_), string(abi.encodePacked('INVALID_MODULE_OR_VERSION: ', name_, '@', Strings.toString(version_))));
      require(PollyModule(_modules[name_][version_]).PMTYPE() == Polly.ModuleType.CLONE, 'MODULE_NOT_CLONABLE'); // module is not clonable

      address implementation_ = _modules[name_][version_]; // get module implementation address

      PollyModule module_ = PollyModule(Clones.clone(implementation_)); // clone module implementation
      module_.init(msg.sender); // initialize module

      emit moduleCloned(name_, name_, version_, address(module_)); // emit module cloned event
      return address(module_); // return cloned module address

    }


    /// @dev if a module is configurable run the configurator
    /// @param name_ string name of the module
    /// @param version_ uint version of the module
    /// @param params_ Polly.Param[] array of configuration input parameters
    /// @return rparams_ Polly.Param[] array of configuration return parameters
    function configureModule(string memory name_, uint version_, Polly.Param[] memory params_, bool store_, string memory config_name_) public returns(Polly.Param[] memory rparams_) {

      if(version_ == 0)
        version_ = getLatestModuleVersion(name_); // version_ is 0, get latest version

      require(moduleExists(name_, version_), string(abi.encodePacked('INVALID_MODULE_OR_VERSION: ', name_, '@', Strings.toString(version_))));

      Module memory module_ = getModule(name_, version_); // get module
      address configurator_ = PollyModule(module_.implementation).configurator(); // get module configurator address
      require(configurator_ != address(0), 'NO_MODULE_CONFIGURATOR'); // module is not configurable - revert

      PollyConfigurator config_ = PollyConfigurator(configurator_); // get configurator instance
      rparams_ = config_.run(this, msg.sender, params_); // run configurator with params

      uint new_count_ = _configs_count[msg.sender] + 1; // get new config count for storing
      if(store_){

        _configs[msg.sender][new_count_].name = config_name_; // store config name
        _configs[msg.sender][new_count_].module = name_; // store module name

        for (uint i = 0; i < rparams_.length; i++){ // store each config params
          _configs[msg.sender][new_count_].params.push(rparams_[i]);
        }

        _configs_count[msg.sender] = new_count_; // update config count

      }


      emit moduleConfigured(name_, name_, version_, rparams_); // emit module configured event
      return rparams_;  // return configuration params

    }

    /// @dev retrieves the stored configurations for a given address
    /// @param address_ address of the user
    /// @param limit_ maximum number of configurations to return
    /// @param page_ page of configurations to return
    /// @param ascending_ bool sort configurations ascending (true) or descending (false)
    /// @return PollyConfigurator.Config[] array of configurations
    function getConfigsForAddress(address address_, uint limit_, uint page_, bool ascending_) public view returns(Config[] memory){

      uint count_ = _configs_count[address_]; // get total number of configs for address

      if(limit_ < 1 || limit_ > count_)
        limit_ = count_;  // limit is 0 or greater than total number of configs, set limit to total number of configs

      if(page_ < 1)
        page_ = 1; // page is less than 1, set page to 1

      uint i; // counter
      uint id_; // config id

      if(ascending_)
        id_ = page_ == 1 ? 1 : ((page_-1)*limit_)+1; // calculate ascending start id
      else
        id_ = page_ == 1 ? count_ : count_ - (limit_*(page_-1)); // calculate descending start id


      if(
        (ascending_ && id_ >= count_) // ascending and id is greater than total number of configs
        ||
        (!ascending_ && id_ == 0) // descending and id is 0
      )
        return new Config[](0); // no modules available - bail early


      Config[] memory configs_ = new Config[](limit_);  // create array of configs


      if(ascending_){

        // ASCENDING
        while(id_ <= count_ && i < limit_){
            configs_[i] = _configs[address_][id_];
            ++i;
            ++id_;
        }

      }
      else {

        /// DESCENDING
        while(id_ > 0 && i < limit_){
            configs_[i] = _configs[address_][id_];
            ++i;
            --id_;
        }

      }

      return configs_;

    }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Polly.sol";

interface PollyModule {

  function PMTYPE() external view returns(Polly.ModuleType);
  function PMNAME() external view returns(string memory);
  function PMVERSION() external view returns(uint);
  function PMINFO() external view returns(string memory);

  // Clonable
  function init(address for_) external;
  function didInit() external view returns(bool);
  function configurator() external view returns(address);
  function isManager(address address_) external view returns(bool);

  // Keystore
  function lockKey(string memory key_) external;
  function isLockedKey(string memory key_) external view returns(bool);
  function set(Polly.ParamType type_, string memory key_, Polly.Param memory value_) external;
  function get(string memory key_) external view returns(Polly.Param memory value_);

}


abstract contract PMBase {

  function PMTYPE() external view virtual returns(Polly.ModuleType);
  function PMNAME() external view virtual returns(string memory);
  function PMVERSION() external view virtual returns(uint);
  function PMINFO() external view virtual returns(string memory);

}


abstract contract PMReadOnly is PMBase {

  Polly.ModuleType public constant override PMTYPE = Polly.ModuleType.READONLY;

}


abstract contract PMClone is AccessControl, PMBase {

  Polly.ModuleType public constant override PMTYPE = Polly.ModuleType.CLONE;

  address private _configurator;
  bytes32 public constant MANAGER = keccak256("MANAGER");
  bool private _did_init = false;

  constructor(){
    init(msg.sender);
  }

  function init(address for_) public virtual {
    require(!_did_init, 'CAN_NOT_INIT');
    _did_init = true;
    _grantRole(DEFAULT_ADMIN_ROLE, for_);
    _grantRole(MANAGER, for_);
  }

  function didInit() public view returns(bool){
    return _did_init;
  }


  function _setConfigurator(address configurator_) internal {
    _configurator = configurator_;
  }

  function configurator() public view returns(address){
    return _configurator;
  }


  function isManager(address address_) public view returns(bool){
    return hasRole(MANAGER, address_);
  }

}


abstract contract PMCloneKeystore is PMClone {

  /// @dev arbitrary key-value parameters
  struct Param {
    uint _uint;
    int _int;
    bool _bool;
    string _string;
    address _address;
  }

  /// @dev locked keys
  mapping(string => bool) private _locked_keys;
  /// @dev parameters
  mapping(string => Polly.Param) private _params;

  /// @dev Locks a given key so that it can not be changed
  /// @param key_ The key to lock
  function lockKey(string memory key_) public onlyRole(DEFAULT_ADMIN_ROLE){
    _locked_keys[key_] = true;
  }

  /// @dev Check if key is locked
  /// @param key_ Key to check
  /// @return bool true if key is locked, false otherwise
  function isLockedKey(string memory key_) public view returns(bool) {
    return _locked_keys[key_];
  }

  /// @dev set param for key
  /// @param key_ key
  /// @param value_ value
  function set(Polly.ParamType type_, string memory key_, Polly.Param memory value_) public onlyRole(MANAGER){
    require(!isLockedKey(key_), 'LOCKED_KEY');
    if(type_ == Polly.ParamType.UINT){
      _params[key_]._uint = value_._uint;
    } else if(type_ == Polly.ParamType.INT){
      _params[key_]._int = value_._int;
    } else if(type_ == Polly.ParamType.BOOL){
      _params[key_]._bool = value_._bool;
    } else if(type_ == Polly.ParamType.STRING){
      _params[key_]._string = value_._string;
    } else if(type_ == Polly.ParamType.ADDRESS){
      _params[key_]._address = value_._address;
    }
  }

  /// @dev get param for key
  /// @param key_ key
  /// @return value
  function get(string memory key_) public view returns(Polly.Param memory){
    return _params[key_];
  }


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './Polly.sol';
import './PollyModule.sol';

interface PollyConfigurator {

  function FOR_PMNAME() external pure returns (string memory);
  function FOR_PMVERSION() external pure returns (uint);

  function inputs() external pure returns (string[] memory);
  function outputs() external pure returns (string[] memory);
  function run(Polly polly_, address for_, Polly.Param[] memory params_) external returns(Polly.Param[] memory);

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