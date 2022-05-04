/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

library LS1Types {
  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }
}

contract TestImplementation {
    uint256 blackoutWindow;
    LS1Types.EpochParameters epochParameters;
    uint256 emissionPerSecond;

    event BlackoutWindowChanged(
        uint256 blackoutWindow
    );

    event EpochParametersChanged(
        LS1Types.EpochParameters epochParameters
    );

    event RewardsPerSecondUpdated(
        uint256 emissionPerSecond
    );

    function emitBlackoutWindow() external {
        emit BlackoutWindowChanged(blackoutWindow);
    }

    function emitEpochParametersChanged() external {
        emit EpochParametersChanged(epochParameters);
    }

    function emitRewardsPerSecondUpdated() external {
        emit RewardsPerSecondUpdated(emissionPerSecond);
    }
}