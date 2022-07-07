// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFTSpaceXMulticall {
  function multicall(address[] memory addrs, uint256[] memory values, uint256[] memory calldataLengths, bytes memory calldatas) public {
    require(addrs.length == values.length && addrs.length == calldataLengths.length);

    uint256 j = 0;
    for (uint256 i = 0; i < addrs.length; i++) {
      bytes memory callData = new bytes(calldataLengths[i]);
      for (uint256 k = 0; k < calldataLengths[i]; k++) {
        callData[k] = calldatas[j];
        j++;
      }
      (bool sucess, ) = addrs[i].call{value: values[i]}(callData);
      require(sucess);
    }
  }
}