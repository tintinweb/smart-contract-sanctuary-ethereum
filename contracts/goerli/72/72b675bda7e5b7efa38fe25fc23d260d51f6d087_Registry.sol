//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title traceability
 * @dev Contract with abstraction for traceability in a supply chain
 */
import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {

  address[] public whitelistedAddresses;
    bool public onlyWhitelisted = true;

  /**
  * @dev Define the structure for a basic product
  */
  struct Worker {
    string Name;
    string Account;
    string location;
    string description;
    string State;
    uint256 CreationDate;
    bool exist;
  }

  /**
  * @dev Mapping that define the storage of a Worker
  */
  mapping(string  => Worker) private StorageWorker;
  mapping(address => mapping(string => bool)) private wallet;


  /**
  * @dev Declare events according the Time Record operations:
  */
  event CreateWorker(address Name, string id, uint256 CreationDate, string Account, string State);
  event GetWorker(address Name, string id, string State);
  event CreationReject(address Name, string id, string RejectMessage);
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

    function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function transferOwnership(address _newOwner) public override onlyOwner {
    _transferOwnership(_newOwner);    

  }
  /**
  * @dev Function that create the Worker:
  */
  function creationWorker(string memory Name, string memory description, string memory id,  string memory location, string memory Account, string memory State ) public {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }
        if(StorageWorker[id].exist) {
        emit CreationReject(msg.sender, id, "Worker con this id already exist");
        return;
        }
 
      StorageWorker[id] = Worker(Name, Account, location, description, State, block.timestamp, true);
      wallet[msg.sender][id] = true;
      emit CreateWorker(msg.sender, id, block.timestamp, Account, State);
    }

  /**
  * @dev Getter of the characteristic of a Worker:
  */
    function getWorker(string memory id) public view returns  (string memory, string memory, string memory, uint256, string memory) {
 
    return (StorageWorker[id].Name, StorageWorker[id].description, StorageWorker[id].location, StorageWorker[id].CreationDate, StorageWorker[id].Account);
  }

    function getWorkerState(string memory id) public view returns  (string memory, string memory, string memory, string memory) {
 
    return (StorageWorker[id].Name, StorageWorker[id].Account, StorageWorker[id].description, StorageWorker[id].State);
  }

  /**
  * @dev Funcion to check the ownership of a Worker:
  */
  function isOwner(address owner, string memory id) public view returns (bool) {
 
    if(wallet[owner][id]) {
        return true;
    }
 
    return false;
  }
}

/*
*Once Deployed, set Whitelistedaaddresses in function whitelistUsers
*Insert your WhitelistedAdresses following this structure

[
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
]

*/

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