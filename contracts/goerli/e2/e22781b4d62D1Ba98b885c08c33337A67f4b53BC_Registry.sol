// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
  function addr(bytes32 node) public view virtual returns (address);
}

/// @title Mainnet registration contract for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract Registry is Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   CONFIG                                   */
  /* -------------------------------------------------------------------------- */

  ENS public constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Indicates if an ENS name is currently required for registration
  bool public ensRequired;
  /// @notice Registered account addresses by burner account address
  mapping(address => address) public accounts;
  /// @notice Burner account addresses by registered account address
  mapping(address => address) public burnerAccounts;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  event Register(address account, address burnerAccount);
  event UpdateBurnerAccount(address account, address burnerAccount);

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */

  error BurnerAccountTaken();
  error AlreadyRegistered();
  error NotYetRegistered();
  error InvalidEnsNameHash();

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */

  constructor() {
    ensRequired = false;
  }

  /* -------------------------------------------------------------------------- */
  /*                                REGISTRATION                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Register for EthPlays.
  /// @param ensNameHash An ENS namehash that must resolve to the sender's address.
  /// @param burnerAccount The address of the burner account to be registered.
  function register(bytes32 ensNameHash, address burnerAccount) external {
    if (accounts[burnerAccount] != address(0)) {
      revert BurnerAccountTaken();
    }

    if (burnerAccounts[msg.sender] != address(0)) {
      revert AlreadyRegistered();
    }

    if (ensRequired && msg.sender != resolve(ensNameHash)) {
      revert InvalidEnsNameHash();
    }

    accounts[burnerAccount] = msg.sender;
    burnerAccounts[msg.sender] = burnerAccount;

    emit Register(msg.sender, burnerAccount);
  }

  /// @notice Update registered burner account address.
  /// @param burnerAccount The address of the new burner account to be registered.
  function updateBurnerAccount(address burnerAccount) external {
    if (accounts[burnerAccount] != address(0)) {
      revert BurnerAccountTaken();
    }

    if (burnerAccounts[msg.sender] == address(0)) {
      revert NotYetRegistered();
    }

    accounts[burnerAccount] = msg.sender;
    burnerAccounts[msg.sender] = burnerAccount;

    emit UpdateBurnerAccount(msg.sender, burnerAccount);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  function resolve(bytes32 node) internal view returns (address) {
    Resolver resolver = ens.resolver(node);
    return resolver.addr(node);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   ADMIN                                    */
  /* -------------------------------------------------------------------------- */

  function setEnsRequired(bool _ensRequired) external onlyOwner {
    ensRequired = _ensRequired;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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