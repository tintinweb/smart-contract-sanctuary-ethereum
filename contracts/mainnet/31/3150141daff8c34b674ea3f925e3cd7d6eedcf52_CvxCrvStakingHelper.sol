pragma solidity ^0.8.13;

interface IRewardStaking {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function withdraw(uint256 amount, bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address _account) external view returns (uint256);
}

interface IRewardStakingImitator {
    function stake(uint256) external;

    function withdraw(uint256 amount, bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function earned(address account) external view returns (uint256);

    function getReward(address _account, bool _claimExtras) external;

    function balanceOf(address _account) external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/// @notice Was made due to the convex contract having borked logic
contract CvxCrvStakingHelper is IRewardStakingImitator {
    address public allocator;
    IRewardStaking public staking;
    IERC20 public cc;
    IERC20 public crv;

    constructor(
        address allocator_,
        address staking_,
        address cvxcrv_,
        address crv_
    ) {
        allocator = allocator_;
        staking = IRewardStaking(staking_);
        cc = IERC20(cvxcrv_);
        crv = IERC20(crv_);
    }

    function getReward(address, bool _claimExtras) external {
        if (staking.earned(address(this)) > 0)
            staking.getReward(address(this), _claimExtras);

        if (staking.earned(allocator) > 0)
            staking.getReward(allocator, _claimExtras);

        uint256 bal = crv.balanceOf(address(this));

        if (bal > 0) crv.transfer(allocator, bal);
    }

    function stake(uint256) external {
        if (msg.sender == allocator) return;

        uint256 bal = cc.balanceOf(address(this));

        if (bal > 0) {
            cc.approve(address(staking), bal);
            staking.stake(bal);
        }
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) external {
        withdraw(amount, claim);
    }

    function withdraw(uint256 amount, bool) public {
        require(msg.sender == allocator);

        if (amount == type(uint256).max)
            staking.withdraw(staking.balanceOf(address(this)), true);
        else staking.withdraw(amount, true);

        cc.transfer(allocator, cc.balanceOf(address(this)));
        crv.transfer(allocator, crv.balanceOf(address(this)));
    }

    function earned(address) external view returns (uint256) {
        return staking.earned(address(this));
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }
}