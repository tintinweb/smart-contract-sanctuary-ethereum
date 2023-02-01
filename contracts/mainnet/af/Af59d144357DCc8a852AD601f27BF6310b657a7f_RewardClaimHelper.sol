// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable func-name-mixedcase

interface IVeFeeDistributor {
  function claim(address _addr) external returns (uint256);
}

interface IGauge {
  function claim_rewards(address _addr, address _receiver) external returns (uint256);
}

contract RewardClaimHelper {
  /// @notice claim pending ve rewards from many distributors.
  /// @param _user The address of _user to claim.
  /// @param _distributors The list of addresses for distributors.
  function claimVeRewards(address _user, address[] memory _distributors) external {
    for (uint256 i = 0; i < _distributors.length; i++) {
      IVeFeeDistributor(_distributors[i]).claim(_user);
    }
  }

  /// @notice claim pending ve rewards from many gauges.
  /// @param _user The address of _user to claim.
  /// @param _gauges The list of guages to claim.
  function claimGaugeRewards(address _user, address[] memory _gauges) external {
    for (uint256 i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).claim_rewards(_user, _user);
    }
  }
}