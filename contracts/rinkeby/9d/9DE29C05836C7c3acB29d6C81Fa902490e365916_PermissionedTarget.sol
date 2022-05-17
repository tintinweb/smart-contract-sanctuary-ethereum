/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: UNLICENSED
// File: @connext/nxtp-contracts/contracts/interfaces/IExecutor.sol


pragma solidity 0.8.11;

interface IExecutor {
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address assetId,
    uint256 amount,
    bytes _properties,
    bytes callData,
    bytes returnData,
    bool success
  );

  function getConnext() external returns (address);

  function originSender() external returns (address);

  function origin() external returns (uint32);

  function amount() external returns (uint256);

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable returns (bool success, bytes memory returnData);
}

// File: contracts/PermissionedTarget.sol


pragma solidity 0.8.11;


contract PermissionedTarget {
    
    uint256 public value;

    event UpdateCompleted(
        address sender,
        uint256 newValue
    );

    function updateValue(uint256 newValue) external {
        if (value > 10) {
            IExecutor(msg.sender).origin();
        }
        value = newValue;
        emit UpdateCompleted(msg.sender, newValue);
    }
}