// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAddrMapper} from "../interfaces/IAddrMapper.sol";

contract MockAddrMapper is IAddrMapper, Ownable {
  // provider name => key address => returned address
  // (e.g. Compound_V2 => public erc20 => protocol Token)
  mapping(string => mapping(address => address)) private _addrMapping;
  // provider name => key1 address => key2 address => returned address
  // (e.g. Compound_V3 => collateral erc20 => borrow erc20 => Protocol market)
  mapping(string => mapping(address => mapping(address => address))) private _addrNestedMapping;

  string[] private _providerNames;

  mapping(string => bool) private _isProviderNameAdded;

  function getProviders() public view returns (string[] memory) {
    return _providerNames;
  }

  function getAddressMapping(string memory providerName, address inputAddr)
    external
    view
    override
    returns (address)
  {
    return _addrMapping[providerName][inputAddr];
  }

  function getAddressNestedMapping(
    string memory providerName,
    address inputAddr1,
    address inputAddr2
  )
    external
    view
    override
    returns (address)
  {
    return _addrNestedMapping[providerName][inputAddr1][inputAddr2];
  }

  /**
   * @dev Adds an address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setMapping(string memory providerName, address keyAddr, address returnedAddr)
    public
    override
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
    }
    _addrMapping[providerName][keyAddr] = returnedAddr;
    address[] memory inputAddrs = new address[](1);
    inputAddrs[0] = keyAddr;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  /**
   * @dev Adds a nested address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    public
    override
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
    }
    _addrNestedMapping[providerName][keyAddr1][keyAddr2] = returnedAddr;
    address[] memory inputAddrs = new address[](2);
    inputAddrs[0] = keyAddr1;
    inputAddrs[1] = keyAddr2;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  function prepareToRedeploythisAddress() public onlyOwner {
    selfdestruct(payable(owner()));
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAddrMapper {
  /**
   * @dev Log a change in address mapping
   */
  event MappingChanged(address[] keyAddress, address mappedAddress);

  function getAddressMapping(string memory providerName, address keyAddr)
    external
    view
    returns (address returnedAddr);

  function getAddressNestedMapping(string memory providerName, address keyAddr1, address keyAddr2)
    external
    view
    returns (address returnedAddr);

  function setMapping(string memory providerName, address keyAddr, address returnedAddr) external;

  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    external;
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