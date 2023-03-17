/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT

/*

   __  __      ______                 __ 
  / / / /___  / ____/________  ____  / /_
 / / / / __ \/ /_  / ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ / /  / /_/ / / / / /_  
\____/ .___/_/   /_/   \____/_/ /_/\__/  
    /_/                                  

UpFront Proxy Admin

*/

pragma solidity >=0.8.18 <0.9.0;

interface IERC20 {
  function setProxyOwner(address _owner) external;
  function setProxyImplementation(address _implementation) external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() external view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() {
    require(_owner == _msgSender(), "Caller must be the owner.");

    _;
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract UpFrontProxyAdmin is Ownable {
  struct proxyInterfaceDataStruct {
    bool exists;
    IERC20 proxy;
  }

  mapping(address => proxyInterfaceDataStruct) private proxyInterfaceData;

  modifier isProxy(address payable _proxy) {
    if (!proxyInterfaceData[_proxy].exists) {
      proxyInterfaceData[_proxy].exists = true;
      proxyInterfaceData[_proxy].proxy = IERC20(_proxy);
    }

    _;
  }

  function getProxyOwner(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getProxyOwner()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyOwner(address payable _proxy, address _owner) external isOwner isProxy(_proxy) {
    proxyInterfaceData[_proxy].proxy.setProxyOwner(_owner);
  }

  function getProxyImplementation(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getProxyImplementation()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyImplementation(address payable _proxy, address _implementation) external isOwner isProxy(_proxy) {
    proxyInterfaceData[_proxy].proxy.setProxyImplementation(_implementation);
  }
}