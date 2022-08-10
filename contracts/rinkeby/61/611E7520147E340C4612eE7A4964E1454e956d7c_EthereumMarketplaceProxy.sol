/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/library/Context.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal pure returns (bytes memory) {
    return msg.data;
  }

  function _msgValue() internal view returns (uint256) {
    return msg.value;
  }
}


// File contracts/registry/OwnedUpgradeabilityStorage.sol


pragma solidity ^0.8.0;

contract OwnedUpgradeabilityStorage {

  /* 현재 storage로 사용하는 contract address */
  address internal _storage;
  /* 현재 구현체 address */
  address internal _implementation;
  /* 현재 해당 contract의 소유자 */
  address private _upgradeabilityOwner;
  /* pausable */
  bool internal _paused = false;

  function paused() public view returns (bool) {
    return _paused;
  }

  /* 현재 해당 contract의 소유자를 return */
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

  /* 해당 contract의 소유자 변경 */
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }

  /* 현재 구현체의 address return */
  function implementation() public view returns (address) {
    return _implementation;
  }

  function storageAddress() public view returns (address) {
    return _storage;
  }

  /**
   * proxy type return
   * EIP 897 Interface에 따른 proxy type
   * 1: Forwarding proxy, 2: Upgradeable proxy
  */
  function proxyType() public pure returns (uint256 proxyTypeId) {
    return 2;
  }
}


// File contracts/registry/OwnedUpgradeabilityProxy.sol


pragma solidity ^0.8.0;


contract OwnedUpgradeabilityProxy is Context, OwnedUpgradeabilityStorage {
  /**
   * 소유권 이전 이벤트
   * @param previousOwner 이전 소유자
   * @param newOwner 변경된 소유자
   */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  /**
   * implementation의 upgrade에 대한 event
   * @param implementation upgrade된 contract의 address
   */
  event Upgraded(address indexed implementation);

  modifier whenNotPaused {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused {
    require(paused(), "Pausable: not paused");
    _;
  }

  function pause() public whenNotPaused onlyProxyOwner {
    _paused = true;
  }

  function unpause() public whenPaused onlyProxyOwner {
    _paused = false;
  }

  /**
   * implementation contract upgrade
   * @param implementation upgrade할 contract의 address
   */
  function _upgradeTo(address implementation) internal {
    require(_implementation != implementation, "OwnedUpgradeabilityProxy: same implementation");
    _implementation = implementation;
    emit Upgraded(implementation);
  }

  function _replaceStorage(address storageAddress) internal {
    require(_storage != storageAddress, "already used storage");
    _storage = storageAddress;
  }

  /* owner인지 check */
  modifier onlyProxyOwner() {
    require(_msgSender() == proxyOwner(), "OwnedUpgradeabilityProxy: message sender must be equal proxyOwner");
    _;
  }

  /* proxy에 대해 upgrade가 가능한 owner인지 check */
  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

  /* proxy owner 변경 */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0), "OwnedUpgradeabilityProxy: same owner");
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /* implementation upgrade */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  function replaceStorage(address storageAddress) public onlyProxyOwner {
    _replaceStorage(storageAddress);
  }
}


// File contracts/registry/OwnableDelegateProxy.sol


pragma solidity ^0.8.0;

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
  constructor(address owner, address initialImplementation, address storageAddress) {
    setUpgradeabilityOwner(owner);
    _upgradeTo(initialImplementation);
    _replaceStorage(storageAddress);
  }
}


// File contracts/marketplace/ethereum/EthereumMarketplaceProxy.sol


pragma solidity ^0.8.0;


contract EthereumMarketplaceProxy is Context, OwnableDelegateProxy {
  constructor (address implementation, address storageAddress_)
    OwnableDelegateProxy(_msgSender(), implementation, storageAddress_) {}

  function proxy(bytes memory callData) payable public whenNotPaused returns (bytes memory) {
    (bool success, bytes memory data) = _implementation.delegatecall(callData);

    require(success, "delegatecall failed");
    return data;
  }
}