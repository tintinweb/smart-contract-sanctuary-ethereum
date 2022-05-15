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

contract CvxCrvStakingHelper is IRewardStakingImitator {
    address public immutable allocator;
    IRewardStaking public immutable staking;
    IERC20 public immutable cc;
    IERC20 public immutable crv;
    IERC20 public immutable tricrv;
    IERC20 public immutable cvx;

    constructor() {
        allocator = 0x2d643Df5De4e9Ba063760d475BEAa62821c71681;
        staking = IRewardStaking(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
        cc = IERC20(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
        crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
        tricrv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
        cvx = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    }

    function getReward(address, bool _claimExtras) external {
        if (staking.earned(address(this)) > 0)
            staking.getReward(address(this), _claimExtras);

        if (staking.earned(allocator) > 0)
            staking.getReward(allocator, _claimExtras);

        _returnAll();
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

        if (amount == 1)
            staking.withdraw(staking.balanceOf(address(this)), true);
        else staking.withdraw(amount, true);

        _returnAll();
    }

    function earned(address) external view returns (uint256) {
        return staking.earned(address(this));
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function _returnAll() internal {
        uint256 bal = crv.balanceOf(address(this));
        if (bal > 0) crv.transfer(allocator, bal);
        bal = cc.balanceOf(address(this));
        if (bal > 0) cc.transfer(allocator, bal);
        bal = tricrv.balanceOf(address(this));
        if (bal > 0) tricrv.transfer(allocator, bal);
        bal = cvx.balanceOf(address(this));
        if (bal > 0) cvx.transfer(allocator, bal);
    }
}