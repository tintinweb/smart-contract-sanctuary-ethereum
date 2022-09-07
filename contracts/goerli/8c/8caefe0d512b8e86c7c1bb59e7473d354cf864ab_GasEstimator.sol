// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract GasEstimator {
  function estimate(
    address _to,
    bytes calldata _data
  ) external returns (bool success, bytes memory result, uint256 gas) {
    // solhint-disable
    uint256 initialGas = gasleft();
    (success, result) = _to.call(_data);
    gas = initialGas - gasleft();
    // solhint-enable
  }
}