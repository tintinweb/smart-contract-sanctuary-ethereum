// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PunkForbiddenTlds is Ownable {
  // The purpose of this contract is to hold a registry TLD names that are either forbidden or have been already created/used.
  // There may be multiple Punk TLD Factory contracts and they need a joint registry of used or forbidden TLDs.

  mapping (string => bool) public forbidden; // forbidden TLDs
  mapping (address => bool) public factoryAddresses; // list of TLD factories that are allowed to add forbidden TLDs

  event ForbiddenTldAdded(address indexed sender, string indexed tldName);
  event ForbiddenTldRemoved(address indexed sender, string indexed tldName);

  event FactoryAddressAdded(address indexed sender, address indexed fAddress);
  event FactoryAddressRemoved(address indexed sender, address indexed fAddress);

  modifier onlyFactory {
      require(factoryAddresses[msg.sender] == true, "Caller is not a factory address.");
      _;
   }

  constructor() {
    forbidden[".eth"] = true;
    forbidden[".com"] = true;
    forbidden[".org"] = true;
    forbidden[".net"] = true;
  }

  // PUBLIC
  function isTldForbidden(string memory _name) public view returns (bool) {
    return forbidden[_name];
  }

  // FACTORY
  function addForbiddenTld(string memory _name) external onlyFactory {
    forbidden[_name] = true;
    emit ForbiddenTldAdded(msg.sender, _name);
  }

  // OWNER
  function ownerAddForbiddenTld(string memory _name) external onlyOwner {
    forbidden[_name] = true;
    emit ForbiddenTldAdded(msg.sender, _name);
  }

  function removeForbiddenTld(string memory _name) external onlyOwner {
    forbidden[_name] = false;
    emit ForbiddenTldRemoved(msg.sender, _name);
  }

  function addFactoryAddress(address _fAddr) external onlyOwner {
    factoryAddresses[_fAddr] = true;
    emit FactoryAddressAdded(msg.sender, _fAddr);
  }

  function removeFactoryAddress(address _fAddr) external onlyOwner {
    factoryAddresses[_fAddr] = false;
    emit FactoryAddressRemoved(msg.sender, _fAddr);
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