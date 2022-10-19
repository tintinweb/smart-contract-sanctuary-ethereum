/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IKnightsOfTheRoundTable {
    /**
     * @notice Notifies the number of anima transferred to
     * Knights of the Round Table as a reward for generating an egg.
     * @param _addressValidator the address of the validator
     * tied with the matrix generated an egg.
     * @param _transferedAnimaRewardAmount amount of Anima token.
     */
    function distributeRewards(
        address _addressValidator,
        uint256 _transferedAnimaRewardAmount
    ) external;

    /**
     * @notice Check if the address is in the validator's list?
     * @param _address the address to test
     * @return true: _address is in the validator's list.
     * false: _address is not in the validator's list.
     */
    function isValidator(address _address) external returns (bool);
}

contract TestKnightsOfTheRoundTable is IKnightsOfTheRoundTable {
    struct RewardInfo {
        address validator;
        uint256 rewardAmount;
    }
    RewardInfo[] public rewardHistory;
    bool private _validator = true;

    function distributeRewards(address _addressValidator, uint256 _reward)
        external
        override(IKnightsOfTheRoundTable)
    {
        rewardHistory.push(RewardInfo(_addressValidator, _reward));
    }

    function getRewardHistory(uint256 index)
        external
        view
        returns (RewardInfo memory)
    {
        return rewardHistory[index];
    }

    function getLastRewardHistory() external view returns (RewardInfo memory) {
        return rewardHistory[rewardHistory.length - 1];
    }

    function getRewardHistorySize() external view returns (uint256) {
        return rewardHistory.length;
    }

    function validator(bool _bool) external {
        _validator = _bool;
    }

    function isValidator(address _address)
        external
        view
        override
        returns (bool)
    {
        if (_address != address(0)) {
            return _validator;
        }
        return false;
    }
}