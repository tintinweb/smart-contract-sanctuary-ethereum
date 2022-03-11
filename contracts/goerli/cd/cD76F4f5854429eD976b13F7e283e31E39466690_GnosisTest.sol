// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGnosis {
  // enum Operation {Call, DelegateCall}
  function execTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external;
}

contract GnosisTest {
  address public gnosisSafe = 0xC748873f7FAFF298ce1970dc391963B482599F16;
  function callExecTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external {
    IGnosis(gnosisSafe).execTransaction(
      to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures
    );
  }
}