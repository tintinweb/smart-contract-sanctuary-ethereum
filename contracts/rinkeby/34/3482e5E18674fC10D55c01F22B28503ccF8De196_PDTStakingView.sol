pragma solidity ^0.8.7;

import "./interface/IPDTStaking.sol";

/// @title   PDT Staking View
/// @author  JeffX
contract PDTStakingView {
    IPDTStaking public immutable pdtStaking;

    constructor (address _pdtStaking) {
        pdtStaking = IPDTStaking(_pdtStaking);
    }

    function newWeights(address _user, uint256 _amount) external view returns (uint256 newUserWeight_, uint256 newContractWeight_) {
        IPDTStaking.Stake memory stakeDetail = pdtStaking.stakeDetails(_user);

        /// USER ADJUSTED TIME ///

        uint256 _previousStakeAmount = stakeDetail.amountStaked;
        uint256 _userNewTotalStaked = _previousStakeAmount + _amount;
        uint256 _newUserAdjustedTime_;
        if (_previousStakeAmount > 0) {
            uint256 _previousUserTimeStaked = stakeDetail.adjustedTimeStaked;
            uint256 _userTimePassed = block.timestamp - _previousUserTimeStaked;
            uint256 _percentStakeIncreased = (1e18 * _amount) / (_userNewTotalStaked);
            _newUserAdjustedTime_ = _previousUserTimeStaked + ((_percentStakeIncreased * _userTimePassed) / 1e18);
        } else {
            _newUserAdjustedTime_ = block.timestamp;
        }

        /// USER MULTI ///

        uint256 _userAdjustedTimePassed = block.timestamp - _newUserAdjustedTime_;
        uint256 _newUserMulti = pdtStaking.multiplierStart() + ((pdtStaking.multiplierStart() * _userAdjustedTimePassed) / pdtStaking.timeToDouble());

        newUserWeight_ = _userNewTotalStaked * _newUserMulti;

        /// CONTRACT ADJUSTED TIME ///
        uint256 _previousTotalStaked = pdtStaking.totalStaked();
        uint256 _contractNewTotalStaked = _previousTotalStaked + _amount;
        uint256 _newContractAdjustedTime;

        if (_previousTotalStaked > 0) {
            uint256 _previousTimeStaked = pdtStaking.adjustedTime();
            uint256 _timePassed = block.timestamp - _previousTimeStaked;
            uint256 _percent = (1e18 * _amount) / (_contractNewTotalStaked);
            _newContractAdjustedTime = _previousTimeStaked + (_timePassed * _percent) / 1e18;
        } else {
            _newContractAdjustedTime = block.timestamp;
        }

        /// CONTRACT MULTI ///

        uint256 _contractAdjustedTimePassed = block.timestamp - _newContractAdjustedTime;
        uint256 _newContractMulti = pdtStaking.multiplierStart() + ((pdtStaking.multiplierStart() * _contractAdjustedTimePassed) / pdtStaking.timeToDouble());

        newContractWeight_ = _contractNewTotalStaked * _newContractMulti;
    }

}

pragma solidity ^0.8.0;

interface IPDTStaking {
    struct Stake {
        uint256 amountStaked;
        uint256 adjustedTimeStaked;
    }

    function stakeDetails(address _user) external view returns (Stake memory);
    function totalStaked() external view returns (uint256);
    function adjustedTime() external view returns (uint256);
    function timeToDouble() external view returns (uint256);
    function multiplierStart() external view returns (uint256);
}