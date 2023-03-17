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

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ImplementationUpgraded(address indexed implementation);

  modifier isOwner() {
    if (msg.sender == _getOwner()) {
      _;
    } else {
      _fallback();
    }
  }

  constructor() payable {
    _setOwner(msg.sender);
  }

  receive() external payable virtual { _fallback(); }
  fallback() external payable virtual { _fallback(); }

  function getProxyOwner() external isOwner returns (address) {
    return _getOwner();
  }

  function getProxyImplementation() external isOwner returns (address) {
    return _getImplementation();
  }

  function setProxyOwner(address _owner) external isOwner {
    require(_owner != address(0));

    _setOwner(_owner);
  }

  function setProxyImplementation(address _implementation, bytes memory _data) external payable isOwner {
    _setImplementation(_implementation, _data);
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

  function _setImplementation(address _implementation, bytes memory _data) internal {
    require(Address.isContract(_implementation), "Not a contract.");

    StorageSlot.setAddressSlot(IMPLEMENTATION_SLOT, _implementation);

    if (_data.length > 0) {
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
    }

    emit ImplementationUpgraded(_implementation);
  }

  function _delegate(address _implementation) internal virtual {
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