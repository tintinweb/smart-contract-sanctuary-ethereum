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
  function setProxyOwner(address _owner) external;
  function setProxyImplementation(address _implementation, bytes memory _data) external;
  function proxyWithdraw(address payable _to, uint256 _amount) external;
  function proxyWithdrawToken(address _token, address _to, uint256 _amount) external;
  function getProxyBalance() external view returns (uint256);
  function getProxyTokenBalance(address _token) external returns (uint256);
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

  function resetLocked() public isOwner {
    locked = false;
  }
}

contract UpFrontProxyAdmin is ReentrancyGuard {
  struct proxyInterfaceDataStruct {
    bool exists;
    IProxy proxy;
  }

  struct tokenInterfaceDataStruct {
    bool exists;
    IERC20 token;
  }

  mapping(address => proxyInterfaceDataStruct) private proxyInterfaceData;
  mapping(address => tokenInterfaceDataStruct) private tokenInterfaceData;

  event Withdrawn(address indexed to, uint256 amount, address executor);

  modifier isProxyInterface(address payable _proxy) {
    if (!proxyInterfaceData[_proxy].exists) {
      require(Address.isContract(_proxy), "Not a contract.");

      proxyInterfaceData[_proxy].exists = true;
      proxyInterfaceData[_proxy].proxy = IProxy(_proxy);
    }

    _;
  }

  modifier isTokenInterface(address token) {
    if (!tokenInterfaceData[token].exists) {
      require(Address.isContract(token), "Not a token contract.");

      tokenInterfaceData[token].exists = true;
      tokenInterfaceData[token].token = IERC20(token);
    }

    _;
  }

  function getProxyOwner(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getProxyOwner()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyOwner(address payable _proxy, address _owner) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].proxy.setProxyOwner(_owner);
  }

  function getProxyImplementation(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getProxyImplementation()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyImplementation(address payable _proxy, address _implementation, bytes memory _data) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].proxy.setProxyImplementation(_implementation, _data);
  }

  function proxyWithdraw(address payable _to, uint256 _amount) external payable isOwner nonReEntrant {
    require(_getProxyBalance() >= _amount, "Insufficient balance.");

    (bool success, bytes memory response) = _to.call{ value: _amount }("");

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

    emit Withdrawn(_to, _amount, msg.sender);
  }

  function proxyWithdrawToken(address _token, address _to, uint256 _amount) external isOwner isTokenInterface(_token) nonReEntrant {
    require(_getProxyTokenBalance(_token) >= _amount, "Insufficient balance.");

    bool success = tokenInterfaceData[_token].token.transfer(_to, _amount);

    require(success, "Transfer error.");

    emit Withdrawn(_to, _amount, msg.sender);
  }

  function getProxyBalance() external view returns (uint256) {
    return _getProxyBalance();
  }

  function _getProxyBalance() internal view returns (uint256) {
    return address(this).balance;
  }

  function getProxyTokenBalance(address _token) external isTokenInterface(_token) returns (uint256) {
    return _getProxyTokenBalance(_token);
  }

  function _getProxyTokenBalance(address _token) internal view returns (uint256) {
    return tokenInterfaceData[_token].token.balanceOf(address(this));
  }
}