// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract StakingWarmup {
    address public immutable staking;
    address public immutable sOHM;

    constructor(address _staking, address _sOHM) {
        require(_staking != address(0));
        staking = _staking;
        require(_sOHM != address(0));
        sOHM = _sOHM;
    }

    function retrieve(address _staker, uint256 _amount) external {
        require(msg.sender == staking);
        IERC20(sOHM).transfer(_staker, _amount);
    }
}