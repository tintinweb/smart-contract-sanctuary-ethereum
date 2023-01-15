//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableStorage} from "./OwnableStorage.sol";
import {ProxyStorage} from "./ProxyStorage.sol";

contract UUPSProxyWithOwner is ProxyStorage {
  // solhint-disable-next-line no-empty-blocks
  constructor(address firstImplementation, address initialOwner) {
    _proxyStore().implementation = firstImplementation;
    OwnableStorage.load().owner = initialOwner;
  }

  fallback() external payable {
    _forward();
  }

  receive() external payable {
    _forward();
  }

  function _forward() internal {
    address implementation = _proxyStore().implementation;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library OwnableStorage {
  bytes32 private constant _SLOT_OWNABLE_STORAGE = keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

  error Unauthorized(address);

  struct Data {
    bool initialized;
    address owner;
    address nominatedOwner;
  }

  function load() internal pure returns (Data storage store) {
    bytes32 s = _SLOT_OWNABLE_STORAGE;
    assembly {
      store.slot := s
    }
  }

  function onlyOwner() internal view {
    if (msg.sender != getOwner()) {
      revert Unauthorized(msg.sender);
    }
  }

  function getOwner() internal view returns (address) {
    return OwnableStorage.load().owner;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ProxyStorage {
  bytes32 private constant _SLOT_PROXY_STORAGE = keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

  struct ProxyStore {
    address implementation;
    bool simulatingUpgrade;
  }

  function _proxyStore() internal pure returns (ProxyStore storage store) {
    bytes32 s = _SLOT_PROXY_STORAGE;
    assembly {
      store.slot := s
    }
  }
}