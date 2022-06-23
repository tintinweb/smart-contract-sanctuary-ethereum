// SPDX-License-Identifier: MIT 

pragma solidity 0.8.15;

import "./AddressUpgradeable.sol";
import "./IProxyCall.sol";

/**
 * @title Forwards arbitrary calls to an external contract.
 * @notice DO NOT approve this contract to transfer any ERC-20 or ERC-721,
 * or grant any other permissions for another contract.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 * Other return types and call structures may be added in the future.
 */
contract ExternalProxyCall is IProxyCall {
  using AddressUpgradeable for address;

  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    override
    returns (address payable result)
  {
    bytes memory returnData = externalContract.functionCall(callData);

    // Skip the length at the start of the bytes array and return the data, casted to an address
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(add(returnData, 32))
    }
  }
}