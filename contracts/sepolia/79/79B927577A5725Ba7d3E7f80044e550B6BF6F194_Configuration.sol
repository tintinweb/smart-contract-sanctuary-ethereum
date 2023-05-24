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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TypeLibrary.sol";
import "./ConnectContract.sol";

/// @title Vountain – Configuration
/// @notice Base Configuration for all contracts

contract Configuration is Ownable {
  mapping(uint256 => mapping(RCLib.Tasks => RCLib.RequestConfig)) config; //version -> config
  mapping(uint256 => uint256) public violinToVersion;
  mapping(uint256 => bool) public versionLive;
  mapping(uint256 => bool) public configFrozen;

  IConnectContract connectContract;

  constructor(address connectContract_) {
    connectContract = IConnectContract(connectContract_);
    /**
     * CREATE OWNER_ROLE
     */
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].canInitiate = [RCLib.Role.CUSTODIAL];
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.CREATE_OWNER_ROLE].validity = 24;

    /**
     * CREATE INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * CREATE MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].canApprove = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.CREATE_MUSICIAN_ROLE].validity = 24;

    /**
     * CREATE VIOLIN MAKER
     */

    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * CREATE EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].canApprove = [RCLib.Role.EXHIBITOR_ROLE];
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.CREATE_EXHIBITOR_ROLE].validity = 24;

    /**
     * CHANGE DURATION MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].affectedRole = RCLib
      .Role
      .MUSICIAN_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE].validity = 24;

    /**
     * CHANGE DURATION INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * CHANGE DURATION VIOLIN MAKER
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * CHANGE DURATION EXHIBITOR
     */

    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].affectedRole = RCLib
      .Role
      .EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE].validity = 24;

    /**
     * DELIST INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE,
      RCLib.Role.VOUNTAIN
    ];
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * DELIST MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.MUSICIAN_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.DELIST_MUSICIAN_ROLE].validity = 24;

    /**
     * DELIST VIOLIN MAKER
     */

    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * DELIST EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.OWNER_ROLE,
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.VOUNTAIN,
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.DELIST_EXHIBITOR_ROLE].validity = 24;

    /**
     * DELEGATE INSTRUMENT_MANAGER_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].canInitiate = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE].validity = 24;

    /**
     * DELEGATE MUSICIAN_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].canApprove = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.DELEGATE_MUSICIAN_ROLE].validity = 24;

    /**
     * DELEGATE VIOLIN MAKER
     */

    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].canApprove = [
      RCLib.Role.VIOLIN_MAKER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].affectedRole = RCLib
      .Role
      .VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE].validity = 24;

    /**
     * DELEGATE EXHIBITOR_ROLE
     */

    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].canInitiate = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].canApprove = [
      RCLib.Role.EXHIBITOR_ROLE
    ];
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].affectedRole = RCLib
      .Role
      .EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE].validity = 24;

    /**
     * ADD CONCERT
     */

    config[0][RCLib.Tasks.ADD_CONCERT].canInitiate = [RCLib.Role.MUSICIAN_ROLE];
    config[0][RCLib.Tasks.ADD_CONCERT].canApprove = [RCLib.Role.INSTRUMENT_MANAGER_ROLE];
    config[0][RCLib.Tasks.ADD_CONCERT].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_CONCERT].affectedRole = RCLib.Role.MUSICIAN_ROLE;
    config[0][RCLib.Tasks.ADD_CONCERT].validity = 24;

    /**
     * ADD EXHIBITION
     */

    config[0][RCLib.Tasks.ADD_EXHIBITION].canInitiate = [RCLib.Role.EXHIBITOR_ROLE];
    config[0][RCLib.Tasks.ADD_EXHIBITION].canApprove = [
      RCLib.Role.INSTRUMENT_MANAGER_ROLE
    ];
    config[0][RCLib.Tasks.ADD_EXHIBITION].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_EXHIBITION].affectedRole = RCLib.Role.EXHIBITOR_ROLE;
    config[0][RCLib.Tasks.ADD_EXHIBITION].validity = 24;

    /**
     * ADD REPAIR
     */

    config[0][RCLib.Tasks.ADD_REPAIR].canInitiate = [RCLib.Role.VIOLIN_MAKER_ROLE];
    config[0][RCLib.Tasks.ADD_REPAIR].canApprove = [RCLib.Role.INSTRUMENT_MANAGER_ROLE];
    config[0][RCLib.Tasks.ADD_REPAIR].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_REPAIR].affectedRole = RCLib.Role.VIOLIN_MAKER_ROLE;
    config[0][RCLib.Tasks.ADD_REPAIR].validity = 24;

    /**
     * ADD PROVENANCE
     */

    config[0][RCLib.Tasks.ADD_PROVENANCE].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_PROVENANCE].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_PROVENANCE].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_PROVENANCE].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_PROVENANCE].validity = 24;

    /**
     * ADD DOCUMENT
     */

    config[0][RCLib.Tasks.ADD_DOCUMENT].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_DOCUMENT].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_DOCUMENT].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_DOCUMENT].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_DOCUMENT].validity = 24;

    /**
     * ADD SALES
     */

    config[0][RCLib.Tasks.ADD_SALES].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.ADD_SALES].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.ADD_SALES].approvalsNeeded = 1;
    config[0][RCLib.Tasks.ADD_SALES].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.ADD_SALES].validity = 24;

    /**
     * CHANGE METADATA
     */

    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_METADATA_VIOLIN].validity = 24;

    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].canInitiate = [
      RCLib.Role.VOUNTAIN
    ];
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].canApprove = [
      RCLib.Role.OWNER_ROLE
    ];
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].approvalsNeeded = 1;
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].affectedRole = RCLib
      .Role
      .INSTRUMENT_MANAGER_ROLE;
    config[0][RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL].validity = 24;

    /**
     * ADD MINT NEW VIOLIN
     */

    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].canInitiate = [RCLib.Role.VOUNTAIN];
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].canApprove = [RCLib.Role.OWNER_ROLE];
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].approvalsNeeded = 1;
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].affectedRole = RCLib.Role.OWNER_ROLE;
    config[0][RCLib.Tasks.MINT_NEW_VIOLIN].validity = 24;
  }

  /**
   * @dev function for returning the configuration in a readable manner
   * @param violinID_ the violin to be checked
   * @param configID_ the task to check e.g. DELIST_MUSICIAN_ROLE
   */
  function returnRoleConfig(
    uint256 violinID_,
    RCLib.Tasks configID_
  ) public view returns (RCLib.RequestConfig memory) {
    return (config[violinToVersion[violinID_]][configID_]);
  }

  /**
   * @dev function to set for all tasks at once
   * @param configs_ configuration with type RequestConfig containing all tasks
   * @param version_ the version number of the new configuration
   */
  function setConfigForTasks(
    RCLib.RequestConfig[] memory configs_,
    uint256 version_
  ) public onlyOwner {
    require(!configFrozen[version_], "you can't change live configs");
    require(
      configs_.length == uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL) + 1,
      "Invalid number of configs"
    );
    for (uint256 i = 0; i <= uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL); i++) {
      config[version_][RCLib.Tasks(i)] = configs_[i];
    }
  }

  /**
   * @dev query the configuration for a specific version
   * @param version_ the version to query
   */
  function getConfigForVersion(
    uint256 version_
  ) public view returns (RCLib.RequestConfig[] memory) {
    RCLib.RequestConfig[] memory configs = new RCLib.RequestConfig[](
      uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL) + 1
    );
    for (uint256 i = 0; i <= uint256(RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL); i++) {
      configs[i] = config[version_][RCLib.Tasks(i)];
    }
    return configs;
  }

  /**
   * @dev there are different task cluster. Means, that all creation tasks belong to the CREATION Cluster
   * @dev this is needed for handling the requests.
   */
  function checkTasks(RCLib.Tasks task_) public pure returns (RCLib.TaskCluster cluster) {
    if (
      task_ == RCLib.Tasks.CREATE_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.CREATE_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.CREATE_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.CREATE_OWNER_ROLE ||
      task_ == RCLib.Tasks.CREATE_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.CREATION;
    } else if (
      task_ == RCLib.Tasks.CHANGE_DURATION_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_OWNER_ROLE ||
      task_ == RCLib.Tasks.CHANGE_DURATION_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.CHANGE_DURATION;
    } else if (
      task_ == RCLib.Tasks.DELIST_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.DELIST_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.DELIST_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.DELIST_OWNER_ROLE ||
      task_ == RCLib.Tasks.DELIST_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.DELISTING;
    } else if (
      task_ == RCLib.Tasks.DELEGATE_INSTRUMENT_MANAGER_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_MUSICIAN_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_VIOLIN_MAKER_ROLE ||
      task_ == RCLib.Tasks.DELEGATE_EXHIBITOR_ROLE
    ) {
      cluster = RCLib.TaskCluster.DELEGATING;
    } else if (
      task_ == RCLib.Tasks.ADD_CONCERT ||
      task_ == RCLib.Tasks.ADD_EXHIBITION ||
      task_ == RCLib.Tasks.ADD_REPAIR
    ) {
      cluster = RCLib.TaskCluster.EVENTS;
    } else if (
      task_ == RCLib.Tasks.ADD_PROVENANCE ||
      task_ == RCLib.Tasks.ADD_DOCUMENT ||
      task_ == RCLib.Tasks.ADD_SALES
    ) {
      cluster = RCLib.TaskCluster.DOCUMENTS;
    } else if (
      task_ == RCLib.Tasks.CHANGE_METADATA_VIOLIN ||
      task_ == RCLib.Tasks.CHANGE_METADATA_ACCESSCONTROL
    ) {
      cluster = RCLib.TaskCluster.METADATA;
    } else {
      cluster = RCLib.TaskCluster.MINTING;
    }

    return cluster;
  }

  /**
   * @dev function to activate a new version (users can only set active versions)
   * @param version_ the version to activate
   */
  function setVersionLive(uint256 version_) public onlyOwner {
    versionLive[version_] = true;
    configFrozen[version_] = true;
  }

  /**
   * @dev function to deactivate a version
   * @param version_ the version to deactivate
   */
  function setVersionIncative(uint256 version_) public onlyOwner {
    versionLive[version_] = false;
  }

  /**
   * @dev An owner of a violin can set the version for his violin.
   * @dev The configuration immeadiatly takes place for the violin.
   * @dev It is not possible to downgrade to an older version
   * @dev It is not possible to switch to an inactive version
   * @param violinID_ the violin to manage
   * @param version_ the version to upgrade to
   */
  function setVersionForViolin(uint256 violinID_, uint256 version_) public {
    RCLib.ContractCombination memory readContracts = connectContract
      .getContractsForVersion(violinID_);
    IAccessControl accessControl = IAccessControl(readContracts.accessControlContract);

    require(
      accessControl.checkIfAddressHasAccess(msg.sender, RCLib.Role.OWNER_ROLE, violinID_),
      "account is not the owner"
    );

    require(version_ > violinToVersion[violinID_], "downgrade not possible");
    require(versionLive[version_], "version not live");

    violinToVersion[violinID_] = version_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TypeLibrary.sol";

/// @title Vountain – ConnectContract
/// @notice Connecting violin, metadata, access controls and

contract ConnectContract is Ownable {
  address public violinAddress;

  mapping(uint => RCLib.ContractCombination) public versionToContractCombination;
  mapping(uint => uint) public violinToContractVersion;
  mapping(uint => bool) public versionIsActive;
  mapping(uint => bool) public freezeConfigVersion;

  RCLib.LatestMintableVersion public latest;

  constructor() {}

  /**
   * @dev after deployment the ConnectContract and the violin contract are tied together forever
   * @param violinAddress_ the address of the violin contract
   */
  function setViolinAddress(address violinAddress_) public onlyOwner {
    //once and forever
    require(violinAddress == address(0), "already initialized");
    violinAddress = violinAddress_;
  }

  /**
   * @dev Vountain can add a contract combination for the application. Itś not possible to change a contract combination once the version was set to active
   * @param id_ the version of the contract combination
   * @param controllerContract_  the request handling logic contract
   * @param accessControlContract_  the role token contract
   * @param metadataContract_  the metadata contract
   */
  function setContractConfig(
    uint id_,
    address controllerContract_,
    address accessControlContract_,
    address metadataContract_
  ) public onlyOwner {
    require(!freezeConfigVersion[id_], "don't change active versions");
    versionToContractCombination[id_].controllerContract = controllerContract_;
    versionToContractCombination[id_].accessControlContract = accessControlContract_;
    versionToContractCombination[id_].metadataContract = metadataContract_;
  }

  /**
   * @dev Vountain can set a version to active. All contracts has to be initialized.
   * @dev The version is frozen and can not be changed later
   * @dev The latest version is set if the config has a higher number than the last latest version
   * @param version_ the version to set active
   */
  function setVersionActive(uint256 version_) public onlyOwner {
    RCLib.ContractCombination memory contracts = versionToContractCombination[version_];

    require(
      contracts.controllerContract != address(0) &&
        contracts.accessControlContract != address(0) &&
        contracts.metadataContract != address(0),
      "initialize contracts first"
    );
    versionIsActive[version_] = true;
    freezeConfigVersion[version_] = true;
    if (version_ >= latest.versionNumber) {
      latest.versionNumber = version_;
      latest.controllerContract = versionToContractCombination[version_]
        .controllerContract;
    }
  }

  /**
   * @dev function to set a version inactive
   * @param version_ the version to set inactive
   */
  function setVersionIncative(uint256 version_) public onlyOwner {
    versionIsActive[version_] = false;
  }

  /**
   * @dev an owner of the violin can set a version to active.
   * @dev it is not possible to choose an inactive version
   * @dev a downgrade is not possible
   * @param violinID_ the violin to change the combination
   * @param version_ the version to activate
   */
  function setViolinToContractVersion(uint violinID_, uint version_) public {
    IAccessControl accessControl = IAccessControl(getAccessControlContract(violinID_));
    require(
      accessControl.checkIfAddressHasAccess(
        msg.sender,
        RCLib.Role.OWNER_ROLE,
        violinID_
      ) || msg.sender == violinAddress,
      "account is not the owner"
    );
    require(versionIsActive[version_], "version not active");
    require(version_ >= violinToContractVersion[violinID_], "no downgrade possible");
    violinToContractVersion[violinID_] = version_;
  }

  /**
   * @dev returns the contract combination for a version
   * @param violinID_ the violin to check
   */
  function getContractsForVersion(
    uint violinID_
  ) public view returns (RCLib.ContractCombination memory cc) {
    return versionToContractCombination[violinToContractVersion[violinID_]];
  }

  /**
   * @dev returns the controller contract for the violin
   * @param violinID_ the violin to check
   */
  function getControllerContract(
    uint violinID_
  ) public view returns (address controllerContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.controllerContract;
  }

  /**
   * @dev returns the access control contract for the violin
   * @param violinID_ the violin to check
   */
  function getAccessControlContract(
    uint violinID_
  ) public view returns (address accessControlContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.accessControlContract;
  }

  /**
   * @dev returns the metadata contract for the violin
   * @param violinID_ the violin to check
   */
  function getMetadataContract(
    uint violinID_
  ) public view returns (address metadataContract) {
    RCLib.ContractCombination memory contracts = getContractsForVersion(violinID_);
    return contracts.metadataContract;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract IConnectContract {
  function getContractsForVersion(
    uint violinID_
  ) public view virtual returns (RCLib.ContractCombination memory cc);

  function violinAddress() public view virtual returns (address violinAddress);

  function getControllerContract(
    uint violinID_
  ) public view virtual returns (address controllerContract);

  function getAccessControlContract(
    uint violinID_
  ) public view virtual returns (address accessControlContract);

  function getMetadataContract(
    uint violinID_
  ) public view virtual returns (address metadataContract);

  function versionIsActive(uint version) external view virtual returns (bool);
}

abstract contract IController {
  function returnRequestByViolinId(
    uint256 request_
  ) public view virtual returns (RCLib.Request memory);

  function roleName(RCLib.Role) public view virtual returns (string memory);

  function requestByViolinId(
    uint256 id_
  ) public view virtual returns (RCLib.Request memory);
}

abstract contract IConfigurationContract {
  function getConfigForVersion(
    uint256 version_
  ) public view virtual returns (RCLib.RequestConfig[] memory);

  function checkTasks(
    RCLib.Tasks task_
  ) public pure virtual returns (RCLib.TaskCluster cluster);

  function returnRoleConfig(
    uint256 version_,
    RCLib.Tasks configId_
  ) public view virtual returns (RCLib.RequestConfig memory);

  function violinToVersion(uint256 tokenId) external view virtual returns (uint256);
}

abstract contract IViolines {
  function mintViolin(uint256 id_, address addr_) external virtual;

  function ownerOf(uint256 tokenId) public view virtual returns (address);

  function balanceOf(address owner) public view virtual returns (uint256);
}

abstract contract IViolineMetadata {
  struct EventType {
    string name;
    string description;
    string role;
    address attendee;
    uint256 eventTimestamp;
  }

  function createNewConcert(
    string memory name_,
    string memory description_,
    string memory role_,
    address attendee_,
    uint256 eventTimestamp_,
    uint256 tokenID_
  ) external virtual;

  /// @param docType_ specify the document type: PROVENANCE, DOCUMENT, SALES
  /// @param date_ timestamp of the event
  /// @param cid_ file attachments
  /// @param title_ title of the Document
  /// @param description_ description of the doc
  /// @param source_ source of the doc
  /// @param value_ amount of the object
  /// @param value_original_currency_ amount of the object
  /// @param currency_ in which currency it was sold
  /// @param tokenID_ token ID
  function createNewDocument(
    string memory docType_,
    uint256 date_,
    string memory cid_,
    string memory title_,
    string memory description_,
    string memory source_,
    uint value_,
    uint value_original_currency_,
    string memory currency_,
    uint256 tokenID_
  ) external virtual;

  function changeMetadata(
    string memory name_,
    string memory description_,
    string memory longDescription_,
    string memory image_,
    string[] memory media_,
    string[] memory model3d_,
    string[] memory attributeNames_,
    string[] memory attributeValues_,
    uint256 tokenId_
  ) external virtual;

  function readManager(uint256 tokenID_) public view virtual returns (address);

  function readLocation(uint256 tokenID_) public view virtual returns (address);

  function setTokenManager(uint256 tokenID_, address manager_) external virtual;

  function setTokenArtist(uint256 tokenID_, address artist_) external virtual;

  function setTokenOwner(uint256 tokenID_, address owner_) external virtual;

  function setExhibitor(uint256 tokenID_, address exhibitor_) external virtual;

  function setTokenViolinMaker(uint256 tokenID_, address violinMaker_) external virtual;

  function setViolinLocation(uint256 tokenID_, address violinLocation_) external virtual;

  function createNewEvent(
    string memory name_,
    string memory description_,
    RCLib.Role role_,
    address attendee_,
    uint256 eventStartTimestamp_,
    uint256 eventEndTimestamp_,
    RCLib.Tasks eventType_,
    uint256 tokenID_
  ) external virtual;
}

abstract contract IAccessControl {
  function mintRole(
    address assignee_,
    RCLib.Role role_,
    uint256 contractValidUntil_,
    uint256 violinID_,
    string memory image,
    string memory description
  ) external virtual;

  function changeMetadata(
    uint256 tokenId_,
    string memory description_,
    string memory image_
  ) public virtual;

  function checkIfAddressHasAccess(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (bool);

  function setTimestamp(
    uint256 violinID_,
    uint256 timestamp_,
    address targetAccount_,
    RCLib.Role role_
  ) external virtual;

  function burnTokens(
    address targetAccount,
    RCLib.Role affectedRole,
    uint256 violinId
  ) external virtual;

  function returnCorrespondingTokenID(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (uint256);

  function administrativeMove(
    address from,
    address to,
    uint256 violinId,
    uint256 tokenId
  ) public virtual;
}

library RCLib {
  enum Role {
    OWNER_ROLE,
    VOUNTAIN,
    INSTRUMENT_MANAGER_ROLE,
    MUSICIAN_ROLE,
    VIOLIN_MAKER_ROLE,
    CUSTODIAL,
    EXHIBITOR_ROLE
  }

  enum TaskCluster {
    CREATION,
    CHANGE_DURATION,
    DELISTING,
    DELEGATING,
    EVENTS,
    DOCUMENTS,
    METADATA,
    MINTING
  }

  enum Tasks {
    CREATE_INSTRUMENT_MANAGER_ROLE,
    CREATE_MUSICIAN_ROLE,
    CREATE_VIOLIN_MAKER_ROLE,
    CREATE_OWNER_ROLE,
    CREATE_EXHIBITOR_ROLE,
    CHANGE_DURATION_MUSICIAN_ROLE,
    CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE,
    CHANGE_DURATION_VIOLIN_MAKER_ROLE,
    CHANGE_DURATION_OWNER_ROLE,
    CHANGE_DURATION_EXHIBITOR_ROLE,
    DELIST_INSTRUMENT_MANAGER_ROLE,
    DELIST_MUSICIAN_ROLE,
    DELIST_VIOLIN_MAKER_ROLE,
    DELIST_OWNER_ROLE,
    DELIST_EXHIBITOR_ROLE,
    DELEGATE_INSTRUMENT_MANAGER_ROLE,
    DELEGATE_MUSICIAN_ROLE,
    DELEGATE_VIOLIN_MAKER_ROLE,
    DELEGATE_EXHIBITOR_ROLE,
    ADD_CONCERT,
    ADD_EXHIBITION,
    ADD_REPAIR,
    ADD_PROVENANCE,
    ADD_DOCUMENT,
    ADD_SALES,
    MINT_NEW_VIOLIN,
    CHANGE_METADATA_VIOLIN,
    CHANGE_METADATA_ACCESSCONTROL
  }

  struct TokenAttributes {
    address owner;
    address manager;
    address artist;
    address violinMaker;
    address violinLocation;
    address exhibitor;
    RCLib.Event[] concert;
    RCLib.Event[] exhibition;
    RCLib.Event[] repair;
    RCLib.Documents[] document;
    RCLib.Metadata metadata;
  }

  struct RequestConfig {
    uint256 approvalsNeeded; //Amount of Approver
    RCLib.Role affectedRole; //z.B. MUSICIAN_ROLE
    RCLib.Role[] canApprove;
    RCLib.Role[] canInitiate;
    uint256 validity; //has to be in hours!!!
  }

  struct RoleNames {
    Role role;
    string[] names;
  }

  enum PROCESS_TYPE {
    IS_APPROVE_PROCESS,
    IS_CREATE_PROCESS
  }

  struct Request {
    uint256 violinId;
    uint256 contractValidUntil; //Timestamp
    address creator; //Initiator
    address targetAccount; //Get Role
    bool canBeApproved; //Wurde der Approval bereits ausgeführt
    RCLib.Role affectedRole; //Rolle im AccessControl Contract
    Role[] canApprove; //Rollen, die Approven können
    RCLib.Tasks approvalType; //z.B. CREATE_INSTRUMENT_MANAGER_ROLE
    uint256 approvalsNeeded; //Amount of approval needed
    uint256 approvalCount; //current approvals
    uint256 requestValidUntil; //Wie lange ist der Request gültig?
    address mintTarget; //optional
    RCLib.Event newEvent;
    RCLib.Documents newDocument;
    RCLib.Metadata newMetadata;
    RCLib.Role requesterRole;
  }

  struct AccessToken {
    string image;
    RCLib.Role role;
    uint256 violinID;
    uint256 contractValidUntil;
    string name;
    string description;
  }

  struct Event {
    string name;
    string description;
    RCLib.Role role;
    address attendee;
    uint256 eventStartTimestamp;
    uint256 eventEndTimestamp;
  }

  struct Documents {
    string docType;
    uint256 date;
    string cid;
    string title;
    string description;
    string source;
    uint value;
    uint valueOriginalCurrency;
    string originalCurrency;
  }

  struct Metadata {
    string name;
    string description;
    string longDescription;
    string image;
    string[] media;
    string[] model3d;
    string[] attributeNames;
    string[] attributeValues;
  }

  struct ContractCombination {
    address controllerContract;
    address accessControlContract;
    address metadataContract;
  }

  struct LatestMintableVersion {
    uint versionNumber;
    address controllerContract;
  }
}