// SPDX-License-Identifier: MIT 

pragma solidity 0.8.15;

import "./AddressUpgradeable.sol";
import "./IProxyCall.sol";

/**
 * @title A library which forwards arbitrary calls to an external contract to be processed.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 */
library ProxyCall {
  using AddressUpgradeable for address payable;
  function proxyCallAndReturnContractAddress(
    IProxyCall proxyCall,
    address externalContract,
    bytes memory callData
  ) external returns (address payable result) {
    result = proxyCall.proxyCallAndReturnAddress(externalContract, callData);
    require(result.isContract(), "ProxyCall: address returned is not a contract");
  }
}