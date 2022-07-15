/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: GPL-3.0
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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/IHoprNetworkRegistryRequirement.sol

pragma solidity ^0.8.0;

interface IHoprNetworkRegistryRequirement {
  function isRequirementFulfilled(address account) external view returns (bool);
}


// File contracts/HoprNetworkRegistry.sol

pragma solidity ^0.8.0;


/**
 * @title HoprNetworkRegistry
 * @dev Smart contract that maintains a list of hopr node address (peer id) that are allowed
 * to enter HOPR network. Each peer id is linked with an Ethereum account. Only Ethereum
 * accounts that are eligible according to `IHoprNetworkRegistryRequirement` can register a
 * HOPR node address. If an account wants to change its registerd HOPR node address, it must
 * firstly deregister itself before registering new node.
 *
 * Note that HOPR node address refers to `PeerId.toB58String()`
 *
 * This network registry can be globally enabled/disabled by the owner
 *
 * Implementation of `IHoprNetworkRegistryRequirement` can also be dynamically updated by the
 * owner. Some sample implementations can be found under../proxy/ folder
 *
 * Owner has the power to overwrite the registration
 */
contract HoprNetworkRegistry is Ownable {
  IHoprNetworkRegistryRequirement public requirementImplementation; // Implementation of network registry proxy
  mapping(address => string) public accountToNodePeerId; // mapping the account to the hopr node peer id in bytes
  mapping(string => address) public nodePeerIdToAccount; // mapping the hopr node peer id in bytes to account
  bool public enabled;

  event EnabledNetworkRegistry(bool indexed isEnabled); // Global toggle of the network registry
  event RequirementUpdated(address indexed requirementImplementation); // Emit when the network registry proxy is updated
  event Registered(address indexed account, string hoprPeerId); // Emit when an account register a node peer id for itself
  event Deregistered(address indexed account); // Emit when an account deregister a node peer id for itself
  event RegisteredByOwner(address indexed account, string hoprPeerId); // Emit when the contract owner register a node peer id for an account
  event DeregisteredByOwner(address indexed account); // Emit when the contract owner deregister a node peer id for an account
  event EligibilityUpdated(address indexed account, bool indexed eligibility); // Emit when the eligibility of an account is updated

  /**
   * @dev Network registry can be globally toggled. If `enabled === true`, only nodes registered
   * in this contract with an eligible account associated can join HOPR network; If `!enabled`,
   * all the nodes can join HOPR network regardless the eligibility of the associated account.
   */
  modifier mustBeEnabled() {
    require(enabled, 'HoprNetworkRegistry: Registry is disabled');
    _;
  }

  /**
   * Specify NetworkRegistry logic implementation and transfer the ownership
   * enable the network registry on deployment.
   * @param _requirementImplementation address of the network registry logic implementation
   * @param _newOwner address of the contract owner
   */
  constructor(address _requirementImplementation, address _newOwner) {
    requirementImplementation = IHoprNetworkRegistryRequirement(_requirementImplementation);
    enabled = true;
    _transferOwnership(_newOwner);
    emit RequirementUpdated(_requirementImplementation);
    emit EnabledNetworkRegistry(true);
  }

  /**
   * Specify NetworkRegistry logic implementation
   * @param _requirementImplementation address of the network registry logic implementation
   */
  function updateRequirementImplementation(address _requirementImplementation) external onlyOwner {
    requirementImplementation = IHoprNetworkRegistryRequirement(_requirementImplementation);
    emit RequirementUpdated(_requirementImplementation);
  }

  /**
   * Enable globally the network registry by the owner
   */
  function enableRegistry() external onlyOwner {
    require(!enabled, 'HoprNetworkRegistry: Registry is enabled');
    enabled = true;
    emit EnabledNetworkRegistry(true);
  }

  /**
   * Disanable globally the network registry by the owner
   */
  function disableRegistry() external onlyOwner mustBeEnabled {
    enabled = false;
    emit EnabledNetworkRegistry(false);
  }

  /**
   * @dev Checks if the msg.sender fulfills registration requirement at the calling time, if so,
   * register the EOA with HOPR node peer id. Account can also update its registration status
   * with this function.
   * @notice It allows msg.sender to update registered node peer id.
   * @param hoprPeerId Hopr nodes peer id in bytes. e.g. 16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1
   * hopr node peer id should always start with '16Uiu2HA' (0x3136556975324841) and be of length 53
   */
  function selfRegister(string calldata hoprPeerId) external mustBeEnabled returns (bool) {
    require(
      bytes(hoprPeerId).length == 53 && bytes32(bytes(hoprPeerId)[0:8]) == '16Uiu2HA',
      'HoprNetworkRegistry: HOPR node peer id must be valid'
    );
    // get account associated with the given hopr node peer id, if any
    address registeredAccount = nodePeerIdToAccount[hoprPeerId];
    // if the hopr node peer id was linked to a different account, revert.
    // To change a nodes' linked account, it must be deregistered by the previously linked account
    // first before registering by the new account, to prevent hostile takeover of others' node peer id
    require(
      registeredAccount == msg.sender || registeredAccount == address(0),
      'HoprNetworkRegistry: Cannot link a registered node to a different account'
    );

    // get multi address associated with the caller, if any
    bytes memory registeredNodeMultiaddrInBytes = bytes(accountToNodePeerId[msg.sender]);
    require(
      registeredNodeMultiaddrInBytes.length == 0 ||
        keccak256(registeredNodeMultiaddrInBytes) == keccak256(bytes(hoprPeerId)),
      'HoprNetworkRegistry: Cannot link an account to a different node. Please remove the registered node'
    );

    if (requirementImplementation.isRequirementFulfilled(msg.sender)) {
      // only update the list when no record previously exists
      if (registeredNodeMultiaddrInBytes.length == 0) {
        accountToNodePeerId[msg.sender] = hoprPeerId;
        nodePeerIdToAccount[hoprPeerId] = msg.sender;
        emit Registered(msg.sender, hoprPeerId);
      }
      emit EligibilityUpdated(msg.sender, true);
      return true;
    }

    emit EligibilityUpdated(msg.sender, false);
    return false;
  }

  /**
   * @dev Allows when there's already a multi address associated with the caller account, remove the link by deregistering
   */
  function selfDeregister() external mustBeEnabled returns (bool) {
    string memory registeredNodeMultiaddr = accountToNodePeerId[msg.sender];
    require(bytes(registeredNodeMultiaddr).length > 0, 'HoprNetworkRegistry: Cannot delete an empty entry');
    delete accountToNodePeerId[msg.sender];
    delete nodePeerIdToAccount[registeredNodeMultiaddr];
    emit Deregistered(msg.sender);
    return true;
  }

  /**
   * @dev Owner adds Ethereum addresses and HOPR node ids to the registration.
   * Allows owner to register arbitrary HOPR Addresses even if accounts do not fulfill registration requirements.
   * HOPR node peer id validation should be done off-chain.
   * @notice It allows owner to overwrite exisitng entries.
   * @param accounts Array of Ethereum accounts, e.g. [0xf6A8b267f43998B890857f8d1C9AabC68F8556ee]
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function ownerRegister(address[] calldata accounts, string[] calldata hoprPeerIds) external onlyOwner mustBeEnabled {
    require(hoprPeerIds.length == accounts.length, 'HoprNetworkRegistry: hoprPeerIdes and accounts lengths mismatch');
    for (uint256 i = 0; i < accounts.length; i++) {
      // validate peer the length and prefix of peer Ids. If invalid, skip.
      if (bytes(hoprPeerIds[i]).length == 53 && bytes32(bytes(hoprPeerIds[i])[0:8]) == '16Uiu2HA') {
        string memory hoprPeerId = hoprPeerIds[i];
        address account = accounts[i];
        accountToNodePeerId[account] = hoprPeerId;
        nodePeerIdToAccount[hoprPeerId] = account;
        emit RegisteredByOwner(account, hoprPeerId);
        emit EligibilityUpdated(account, true);
      }
    }
  }

  /**
   * @dev Owner removes previously owner-added Ethereum addresses and HOPR node ids from the registration.
   * @notice Owner can even remove self-declared entries.
   * @param accounts Array of Ethereum accounts, e.g. 0xf6A8b267f43998B890857f8d1C9AabC68F8556ee
   */
  function ownerDeregister(address[] calldata accounts) external onlyOwner mustBeEnabled {
    for (uint256 i = 0; i < accounts.length; i++) {
      address account = accounts[i];
      string memory hoprPeerId = accountToNodePeerId[account];
      delete accountToNodePeerId[account];
      delete nodePeerIdToAccount[hoprPeerId];
      // Eligibility update should have a logindex strictly smaller
      // than the deregister event to make sure it always gets processed
      // before the deregister event
      emit EligibilityUpdated(account, false);
      emit DeregisteredByOwner(account);
    }
  }

  /**
   * @dev Owner syncs a list of addresses with based on the latest criteria.
   * @notice If an account hasn't been registered, its eligibility is not going to be updated
   * @param accounts Array of Ethereum accounts, e.g. [0xf6A8b267f43998B890857f8d1C9AabC68F8556ee]
   */
  function sync(address[] calldata accounts) external onlyOwner mustBeEnabled {
    for (uint256 i = 0; i < accounts.length; i++) {
      address account = accounts[i];
      if (bytes(accountToNodePeerId[account]).length == 0) {
        // if the account does not have any registered address
        continue;
      }
      if (!requirementImplementation.isRequirementFulfilled(account)) {
        // if the account is no longer eligible
        emit EligibilityUpdated(account, false);
      } else {
        emit EligibilityUpdated(account, true);
      }
    }
  }

  /**
   * @dev Returns if a hopr address is registered and its associated account is eligible or not.
   * @param hoprPeerId hopr node peer id
   */
  function isNodeRegisteredAndEligible(string calldata hoprPeerId) public view returns (bool) {
    address account = nodePeerIdToAccount[hoprPeerId];
    if (account == address(0)) {
      // this address has never been registered
      return false;
    }
    return requirementImplementation.isRequirementFulfilled(account);
  }

  /**
   * @dev Returns if an account address is eligible according to the criteria defined in the implementation
   * It also checks if a node peer id is associated with the account.
   * @param account account address that runs hopr node
   */
  function isAccountRegisteredAndEligible(address account) public view returns (bool) {
    return bytes(accountToNodePeerId[account]).length != 0 && requirementImplementation.isRequirementFulfilled(account);
  }
}