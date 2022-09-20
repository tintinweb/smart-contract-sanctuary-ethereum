// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { Address } from "./Address.sol";
import { IERC20 } from "./IERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";
import { SyncerTrait } from "./SyncerTrait.sol";

contract TradingBot is SyncerTrait {
  using SafeERC20 for IERC20;
  using Address for address;

  constructor(address _syncer) SyncerTrait(_syncer) {}

  /// @dev Approves token for 3rd party contract. Restricted for current credit manager only
  /// @param token ERC20 token for allowance
  /// @param targetContract Swap contract address
  function approveToken(address token, address targetContract)
    external
    syncerOnly
  {
    try IERC20(token).approve(targetContract, type(uint256).max) {} catch {
      IERC20(token).approve(targetContract, 0);
      IERC20(token).approve(targetContract, type(uint256).max);
    }
  }

  /// @dev Transfers tokens from credit account to provided address. Restricted for current credit manager only
  /// @param token Token which should be transferred from credit account
  /// @param to Address of recipient
  /// @param amount Amount to be transferred
  function safeTransfer(
    address token,
    address to,
    uint256 amount
  ) external syncerOnly {
    IERC20(token).safeTransfer(to, amount);
  }

  /// @dev Executes financial order on 3rd party service. Restricted for current credit manager only
  /// @param destination Contract address which should be called
  /// @param data Call data which should be sent
  function execute(address destination, bytes memory data)
    external
    syncerOnly
    returns (bytes memory)
  {
    return destination.functionCall(data);
  }
}