// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IHoprNetworkRegistryRequirement.sol';

/**
 * @title HoprNetworkRegistry
 * @dev Smart contract that maintains a list of hopr node address (peer id) that are allowed
 * to enter HOPR network. Each peer id is linked with an Ethereum account. Only Ethereum
 * accounts that are eligible according to `IHoprNetworkRegistryRequirement` can register one
 * or multiple HOPR node address(es).
 *
 * When reaching its limits, accounts can remove registered node addresses (`deregister`)
 * before adding more.
 *
 * A peer id can only be registered if it's not registered by another account.
 *
 * Note that HOPR node address refers to `PeerId.toString()`
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
  mapping(address => uint256) public countRegisterdNodesPerAccount; // counter for registered nodes per account
  mapping(string => address) public nodePeerIdToAccount; // mapping the hopr node peer id in bytes to account
  bool public enabled;

  error InvalidPeerId(string peerId);

  event EnabledNetworkRegistry(bool indexed isEnabled); // Global toggle of the network registry
  event RequirementUpdated(address indexed requirementImplementation); // Emit when the network registry proxy is updated
  event Registered(address indexed account, string hoprPeerId); // Emit when an account register a node peer id for itself
  event Deregistered(address indexed account, string hoprPeerId); // Emit when an account deregister a node peer id for itself
  event RegisteredByOwner(address indexed account, string hoprPeerId); // Emit when the contract owner register a node peer id for an account
  event DeregisteredByOwner(address indexed account, string hoprPeerId); // Emit when the contract owner deregister a node peer id for an account
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
   * @dev Register a new node's peer id associated with the caller.
   * @notice Transaction will fail, if
   * 1) the peer ID is registered to an address, including the caller.
   * 2) the caller will become ineligible after adding a new node
   *
   * Performs a minimum validation of node IDs. Full validation should be done off-chain.
   * hopr node peer id should always start with '16Uiu2HA' (0x3136556975324841) and be of length 53
   *
   * Function can only be called when the registry is enabled.
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function selfRegister(string[] calldata hoprPeerIds) external mustBeEnabled {
    // update the counter
    countRegisterdNodesPerAccount[msg.sender] += hoprPeerIds.length;

    // check sender eligibility
    require(
      _checkEligibility(msg.sender),
      'HoprNetworkRegistry: selfRegister reaches limit, cannot register requested nodes.'
    );
    emit EligibilityUpdated(msg.sender, true);

    for (uint256 i = 0; i < hoprPeerIds.length; i++) {
      string memory hoprPeerId = hoprPeerIds[i];
      if (bytes(hoprPeerId).length != 53 || bytes32(bytes(hoprPeerIds[i])[0:8]) != '16Uiu2HA') {
        revert InvalidPeerId({peerId: hoprPeerId});
      }
      // get account associated with the given hopr node peer id, if any
      address registeredAccount = nodePeerIdToAccount[hoprPeerId];
      if (registeredAccount == msg.sender) {
        // when registering the registerd account, skip
        continue;
      } else {
        // if the hopr node peer id was linked to a different account, revert.
        // To change a nodes' linked account, it must be deregistered by the previously linked account
        // first before registering by the new account, to prevent hostile takeover of others' node peer id
        require(registeredAccount == address(0), 'HoprNetworkRegistry: Cannot link a registered node.');
        nodePeerIdToAccount[hoprPeerId] = msg.sender;
        emit Registered(msg.sender, hoprPeerId);
      }
    }
  }

  /**
   * @dev Allows account to deregister a registered peer ID
   * Function can only be called when the registry is enabled.
   *
   * Performs a minimum validation of node IDs. Full validation should be done off-chain.
   * hopr node peer id should always start with '16Uiu2HA' (0x3136556975324841) and be of length 53
   *
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function selfDeregister(string[] calldata hoprPeerIds) external mustBeEnabled {
    // update the counter
    countRegisterdNodesPerAccount[msg.sender] -= hoprPeerIds.length;

    // check sender eligibility
    if (_checkEligibility(msg.sender)) {
      // account becomes eligible
      emit EligibilityUpdated(msg.sender, true);
    } else {
      emit EligibilityUpdated(msg.sender, false);
    }

    for (uint256 i = 0; i < hoprPeerIds.length; i++) {
      string memory hoprPeerId = hoprPeerIds[i];
      require(
        nodePeerIdToAccount[hoprPeerId] == msg.sender,
        'HoprNetworkRegistry: Cannot delete an entry not associated with the caller.'
      );
      delete nodePeerIdToAccount[hoprPeerId];
      emit Deregistered(msg.sender, hoprPeerId);
    }
  }

  /**
   * @dev Owner adds Ethereum addresses and HOPR node ids to the registration.
   * Function can be called at any time.
   * Allows owner to register arbitrary HOPR peer ids even if accounts do not fulfill registration requirements.
   * HOPR node peer id validation should be done off-chain.
   * @notice It allows owner to overwrite exisitng entries.
   * @param accounts Array of Ethereum accounts, e.g. [0xf6A8b267f43998B890857f8d1C9AabC68F8556ee]
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function ownerRegister(address[] calldata accounts, string[] calldata hoprPeerIds) external onlyOwner {
    require(hoprPeerIds.length == accounts.length, 'HoprNetworkRegistry: hoprPeerIdes and accounts lengths mismatch');
    for (uint256 i = 0; i < accounts.length; i++) {
      // validate peer the length and prefix of peer Ids. If invalid, skip.
      if (bytes(hoprPeerIds[i]).length == 53 && bytes32(bytes(hoprPeerIds[i])[0:8]) == '16Uiu2HA') {
        string memory hoprPeerId = hoprPeerIds[i];
        address account = accounts[i];
        // link the account with peer id.
        nodePeerIdToAccount[hoprPeerId] = account;
        // update the counter
        countRegisterdNodesPerAccount[account] += 1;
        emit RegisteredByOwner(account, hoprPeerId);
      }
    }
  }

  /**
   * @dev Owner removes previously owner-added Ethereum addresses and HOPR node ids from the registration.
   * Function can be called at any time.
   * @notice Owner can even remove self-declared entries.
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function ownerDeregister(string[] calldata hoprPeerIds) external onlyOwner {
    for (uint256 i = 0; i < hoprPeerIds.length; i++) {
      string memory hoprPeerId = hoprPeerIds[i];
      address account = nodePeerIdToAccount[hoprPeerId];
      if (account != address(0)) {
        delete nodePeerIdToAccount[hoprPeerId];
        countRegisterdNodesPerAccount[account] -= 1;
        // Eligibility update should have a logindex strictly smaller
        // than the deregister event to make sure it always gets processed
        // before the deregister event
        emit DeregisteredByOwner(account, hoprPeerId);
      }
    }
  }

  /**
   * @dev Force emit eligibility update by the owner.
   * @notice This does not change the result returned from the proxy, so if `sync` is called on those accounts,
   * it may return a different result.
   * @param accounts Array of Ethereum accounts, e.g. [0xf6A8b267f43998B890857f8d1C9AabC68F8556ee]
   * @param eligibility Array of account eligibility, e.g. [true]
   */
  function ownerForceEligibility(address[] calldata accounts, bool[] calldata eligibility) external onlyOwner {
    require(accounts.length == eligibility.length, 'HoprNetworkRegistry: accounts and eligibility lengths mismatch');
    for (uint256 i = 0; i < accounts.length; i++) {
      emit EligibilityUpdated(accounts[i], eligibility[i]);
    }
  }

  /**
   * @dev Owner syncs a list of peer Ids with based on the latest criteria.
   * Function can only be called when the registry is enabled.
   * @notice If a peer id hasn't been registered, its eligibility is not going to be updated
   * @param hoprPeerIds Array of hopr nodes id. e.g. [16Uiu2HAmHsB2c2puugVuuErRzLm9NZfceainZpkxqJMR6qGsf1x1]
   */
  function sync(string[] calldata hoprPeerIds) external onlyOwner mustBeEnabled {
    for (uint256 i = 0; i < hoprPeerIds.length; i++) {
      string memory hoprPeerId = hoprPeerIds[i];
      address account = nodePeerIdToAccount[hoprPeerId];

      if (account == address(0)) {
        // if the account does not have any registered address
        continue;
      }
      if (_checkEligibility(account)) {
        emit EligibilityUpdated(account, true);
      } else {
        // if the account is no longer eligible
        emit EligibilityUpdated(account, false);
      }
    }
  }

  /**
   * @dev Returns if a hopr address is registered and its associated account is eligible or not.
   * @param hoprPeerId hopr node peer id
   */
  function isNodeRegisteredAndEligible(string calldata hoprPeerId) public view returns (bool) {
    // check if peer id is registered
    address account = nodePeerIdToAccount[hoprPeerId];
    if (account == address(0)) {
      // this address has never been registered
      return false;
    }
    return _checkEligibility(account);
  }

  /**
   * @dev Returns if an account address is eligible according to the criteria defined in the proxy implementation
   * It also checks if a node peer id is associated with the account.
   * @param account account address that runs hopr node
   */
  function isAccountRegisteredAndEligible(address account) public view returns (bool) {
    return countRegisterdNodesPerAccount[account] > 0 && _checkEligibility(account);
  }

  /**
   * @dev given the current registry, check if an account has the number of registered nodes within the limit,
   * which is the eligibility of an account.
   * @notice If an account has registerd more peers than it's currently allowed, the account become ineligible
   * @param account address to check its eligibility
   */
  function _checkEligibility(address account) private view returns (bool) {
    uint256 maxAllowedRegistration = requirementImplementation.maxAllowedRegistrations(account);
    if (countRegisterdNodesPerAccount[account] <= maxAllowedRegistration) {
      return true;
    } else {
      return false;
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface for HoprNetworkRegistryProxy
 * @dev Network Registry contract (NR) delegates its eligibility check to Network
 * Registry Proxy (NR Proxy) contract. This interface must be implemented by the
 * NR Proxy contract.
 */
interface IHoprNetworkRegistryRequirement {
  /**
   * @dev Get the maximum number of nodes' peer ids that an account can register.
   * This check is only performed when registering new nodes, i.e. if the number gets
   * reduced later, it does not affect registered nodes.
   *
   * @param account Address that can register other nodes
   */
  function maxAllowedRegistrations(address account) external view returns (uint256);
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