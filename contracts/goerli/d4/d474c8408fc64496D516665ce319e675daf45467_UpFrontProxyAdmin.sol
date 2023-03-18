/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT

/*

   __  __      ______                 __ 
  / / / /___  / ____/________  ____  / /_
 / / / / __ \/ /_  / ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ / /  / /_/ / / / / /_  
\____/ .___/_/   /_/   \____/_/ /_/\__/  
    /_/                                  

UpFront
Multi-Proxy Admin

  Author: dotfx
  Date: 2023/03/18
  Version: 1.0.0

*/

pragma solidity >=0.8.18 <0.9.0;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
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

  function renounceOwnership() external virtual isOwner {
    _setOwner(address(0));
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

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");

    locked = true;
    _;
    locked = false;
  }
}

interface IProxy {
  function setOwner(address _owner) external;
  function setImplementation(address _implementation) external;
}

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UpFrontProxyAdmin is ReentrancyGuard {
  struct proxyInterfaceDataStruct {
    bool exists;
    IProxy proxy;
  }

  mapping(address => proxyInterfaceDataStruct) private proxyInterfaceData;

  modifier isProxyInterface(address payable _proxy) {
    require(_proxy != address(this));

    if (!proxyInterfaceData[_proxy].exists) {
      require(Address.isContract(_proxy), "Not a contract.");

      proxyInterfaceData[_proxy].exists = true;
      proxyInterfaceData[_proxy].proxy = IProxy(_proxy);
    }

    _;
  }

  function getProxyOwner(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getOwner()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyOwner(address payable _proxy, address _owner) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].proxy.setOwner(_owner);
  }

  function getProxyImplementation(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getImplementation()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyImplementation(address payable _proxy, address _implementation) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].proxy.setImplementation(_implementation);
  }

  function callProxy(address payable _proxy, bytes memory _data) external payable isOwner nonReEntrant returns (bytes memory) {
    (bool success, bytes memory result) = _proxy.call{ value: 0 }(_data);

    if (!success) {
      if (result.length > 0) {
        assembly {
          let size := mload(result)

          revert(add(32, result), size)
        }
      } else {
        revert("Function call reverted.");
      }
    }

    return result;
  }
}