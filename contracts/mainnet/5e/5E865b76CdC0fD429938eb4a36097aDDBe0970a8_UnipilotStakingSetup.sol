// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IUnipilotStaking {
    function stake(address _to, uint256 _amount) external;

    function setGovernance(address _newGovernance) external;

    function updateRewards(uint256 _reward, uint256 _rewardDurationInBlocks) external;
}

interface IPilot {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract UnipilotStakingSetup {
    IUnipilotStaking public unipilotStaking;
    IPilot public pilotToken;

    constructor(IPilot _pilotToken) {
        pilotToken = _pilotToken;
    }

    function setStakingAddress(IUnipilotStaking _unipilotStaking) external {
        unipilotStaking = _unipilotStaking;
    }

    function doSetup(
        address _stakeAddr,
        address _governance,
        uint256 _amount,
        uint256 _rewardToDistribute,
        uint256 _rewardDuration
    ) external {
        // approve pilot
        pilotToken.approve(address(unipilotStaking), type(uint256).max);

        // update rewards
        unipilotStaking.updateRewards(_rewardToDistribute, _rewardDuration);

        // stake pilot
        unipilotStaking.stake(_stakeAddr, _amount);

        // set governance
        unipilotStaking.setGovernance(_governance);
    }
}