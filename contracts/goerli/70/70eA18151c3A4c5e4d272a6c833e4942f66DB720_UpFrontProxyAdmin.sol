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
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IProxy {
  function setOwner(address _owner) external;
  function setImplementation(address _implementation) external;
}

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

  function _resetLocked() internal {
    locked = false;
  }
}

contract UpFrontProxyAdmin is ReentrancyGuard {
  struct proxyInterfaceDataStruct {
    bool exists;
    IProxy proxy;
  }

  mapping(address => proxyInterfaceDataStruct) private proxyInterfaceData;

  event Withdrawn(address indexed to, uint256 amount, address executor);

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
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("geImplementation()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyImplementation(address payable _proxy, address _implementation) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].proxy.setImplementation(_implementation);
  }

  function callProxy(address payable _proxy, bytes memory _data) external payable isOwner nonReEntrant returns (bytes memory) {
    (bool success, bytes memory response) = _proxy.call{ value: 0 }(_data);

    if (!success) {
      if (response.length > 0) {
        assembly {
          let size := mload(response)

          revert(add(32, response), size)
        }
      } else {
        revert("Function call reverted.");
      }
    }

    return response;
  }

  function resetLocked() external isOwner {
    _resetLocked();
  }
}