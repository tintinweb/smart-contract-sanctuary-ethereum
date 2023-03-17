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

UpFront Transparent Upgradeable Proxy

*/

pragma solidity >=0.8.18 <0.9.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library StorageSlot {
  function getAddressSlot(bytes32 _slot) internal view returns (address addr) {
    assembly {
      addr := sload(_slot)
    }

    return addr;
  }

  function setAddressSlot(bytes32 _slot, address _addr) internal {
    assembly {
      sstore(_slot, _addr)
    }
  }
}

contract UpFrontTransparentUpgradeableProxy {
  bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
  bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

  struct tokenInterfaceDataStruct {
    bool exists;
    IERC20 token;
  }

  mapping(address => tokenInterfaceDataStruct) private tokenInterfaceData;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ImplementationUpgraded(address indexed implementation);
  event Withdrawn(address indexed to, uint256 amount, address executor);

  modifier isOwner() {
    if (msg.sender == _getOwner()) {
      _;
    } else {
      _fallback();
    }
  }

  modifier isTokenInterface(address token) {
    if (!tokenInterfaceData[token].exists) {
      require(Address.isContract(token), "Not a token contract.");

      tokenInterfaceData[token].exists = true;
      tokenInterfaceData[token].token = IERC20(token);
    }

    _;
  }

  constructor() payable {
    _setOwner(msg.sender);
  }

  receive() external payable virtual { _fallback(); }
  fallback() external payable virtual { _fallback(); }

  function getOwner() external isOwner returns (address) {
    return _getOwner();
  }

  function setOwner(address _owner) external isOwner {
    require(_owner != address(0));

    _setOwner(_owner);
  }

  function getImplementation() external isOwner returns (address) {
    return _getImplementation();
  }

  function setImplementation(address payable _implementation) external payable isOwner {
    _setImplementation(_implementation);
  }

  function callImplementation(address payable _implementation, bytes memory _data) external payable isOwner returns (bytes memory) {
    return _callImplementation(_implementation, _data);
  }

  function _getOwner() internal view returns (address) {
    return StorageSlot.getAddressSlot(ADMIN_SLOT);
  }

  function _setOwner(address _owner) internal {
    require(_owner != address(0));

    address oldOwner = _getOwner();

    StorageSlot.setAddressSlot(ADMIN_SLOT, _owner);

    emit OwnershipTransferred(oldOwner, _owner);
  }

  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT);
  }

  function _setImplementation(address _implementation) internal {
    require(Address.isContract(_implementation), "Not a contract.");

    StorageSlot.setAddressSlot(IMPLEMENTATION_SLOT, _implementation);

    emit ImplementationUpgraded(_implementation);
  }

  function _callImplementation(address _implementation, bytes memory _data) internal returns (bytes memory) {
    (bool success, bytes memory response) = _implementation.delegatecall(_data);

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

  function _delegate(address _implementation) internal virtual returns (bytes memory) {
    assembly {
      let csize := calldatasize()

      calldatacopy(0, 0, csize)

      let result := delegatecall(gas(), _implementation, 0, csize, 0, 0)
      let rsize := returndatasize()

      returndatacopy(0, 0, rsize)

      switch result
        case 0 { revert(0, rsize) }
        default { return(0, rsize) }
    }
  }

  function _fallback() internal virtual {
    _delegate(_getImplementation());
  }
}