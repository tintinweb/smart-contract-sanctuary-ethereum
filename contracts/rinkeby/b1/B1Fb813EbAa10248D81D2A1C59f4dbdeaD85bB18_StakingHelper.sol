// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

contract StakingHelper {
    address public immutable staking;
    address public immutable MINT;

    constructor(address _staking, address _MINT) {
        require(_staking != address(0));
        staking = _staking;
        require(_MINT != address(0));
        MINT = _MINT;
    }

    function stake(uint256 _amount) external {
        IERC20(MINT).transferFrom(msg.sender, address(this), _amount);
        IERC20(MINT).approve(staking, _amount);
        IStaking(staking).stake(_amount, msg.sender);
        IStaking(staking).claim(msg.sender);
    }
}