// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract PawtocolStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 poolBal;
        uint40 pool_deposit_time;
        uint256 total_deposits;
        uint256 pool_payouts;
        uint256 rewardEarned;
        uint256 penaltyGiven;
    }

    struct PoolInfo {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 poolRewardPercent;
        uint256 poolPenaltyPercent;
        uint256 poolDays;
        uint256 fullMaturityTime;
        uint256 poolLimit;
        uint256 poolStaked;
        uint256 minStake;
        uint256 maxStake;
        bool active;
    }

    uint256 public totalStaked;
    uint256 private _poolId = 0;
    address public penaltyFeeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event PrincipalClaimed(address beneficiary, uint256 amount);
    event PoolStaked(address beneficiary, uint256 amount);
    event RewardClaimed(address beneficiary, uint256 amount);

    // Pool Reward Percent APY Input : 125 = 12.5%, 120 = 12%, 55 = 5.55, 70 = 7%
    // Pool Penalty Percent Input : 125 = 12.5%, 120 = 12%, 55 = 5.5%, 70 = 7%
    constructor(
        IERC20 _stakeToken,
        uint256 _poolRewardPercentAPY,
        uint256 _poolPenaltyPercent,
        uint256 _poolDays,
        uint256 _poolLimit,
        uint256 _minStake,
        uint256 _maxStake, 
        address _penaltyFeeAddress
    ) {
        require(
            isContract(address(_stakeToken)),
            "Enter a Valid Token contract address"
        );
        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                rewardToken: _stakeToken,
                poolRewardPercent: _poolRewardPercentAPY,
                poolPenaltyPercent: _poolPenaltyPercent,
                poolDays: _poolDays,
                fullMaturityTime: _poolDays.mul(86400),
                poolLimit: _poolLimit * 10**_stakeToken.decimals(),
                poolStaked: 0,
                minStake: _minStake * 10**_stakeToken.decimals(),
                maxStake: _maxStake * 10**_stakeToken.decimals(),
                active: true
            })
        );

        penaltyFeeAddress = _penaltyFeeAddress;
    }

    /* Recieve Accidental ETH Transfers */
    receive() external payable {}

    function poolActivation(bool status) external onlyOwner {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.active = status;
    }

    function changePoolLimit(uint256 amount) external onlyOwner {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.poolLimit = amount* 10 ** (pool.stakeToken).decimals();
    }

    function changeFeeWallet(address _newAddress) external onlyOwner {
        penaltyFeeAddress = _newAddress;
    }

    /* Stake Token Function */
    function PoolStake(uint256 _amount) external nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(pool.active, "Pool not Active");
        require(
            _amount <= IERC20(pool.stakeToken).balanceOf(msg.sender),
            "Token Balance of user is less"
        );
        require(
            pool.poolLimit >= pool.poolStaked + _amount,
            "Pool Limit Exceeded"
        );
        require(
            _amount >= pool.minStake ,
            "Minimum Stake Condition should be Satisfied"
        );
        require(
            _amount <= pool.maxStake ,
            "Maximum Stake Condition should be Satisfied"
        );
        require(user.poolBal == 0, "Already Staked in this Pool");

        pool.stakeToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.poolStaked += _amount;
        totalStaked += _amount;
        user.poolBal = _amount;
        user.total_deposits += _amount;
        user.pool_deposit_time = uint40(block.timestamp);
        emit PoolStaked(msg.sender, _amount);
        return true;
    }

    /* Claims Principal Token and Rewards Collected */
    function claimPool() external nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(
            user.poolBal > 0,
            "There is no deposit for this address in Pool"
        );
        uint256 calculatedRewards = (((user.poolBal * pool.poolRewardPercent) / 1000) / 360) * pool.poolDays;
        uint256 amount = user.poolBal;
        uint256 penaltyAmount;

        if (
            block.timestamp < (user.pool_deposit_time + pool.fullMaturityTime)
        ) {
            calculatedRewards = 0;
            penaltyAmount = ((amount) * pool.poolPenaltyPercent) / 1000;
            if(penaltyAmount>0){
                pool.rewardToken.safeTransfer(penaltyFeeAddress, penaltyAmount);
                user.penaltyGiven += penaltyAmount;
            }
            amount = amount.sub(penaltyAmount);
        }
        
        user.rewardEarned += calculatedRewards;
        user.pool_payouts += amount;

        user.poolBal = 0;
        user.pool_deposit_time = 0;

        pool.stakeToken.safeTransfer(address(msg.sender), amount);
        if(calculatedRewards>0){
            pool.rewardToken.safeTransfer(address(msg.sender), calculatedRewards);
        }

        emit RewardClaimed(msg.sender, calculatedRewards);
        emit PrincipalClaimed(msg.sender, amount);
        return true;
    }

    function calculateRewards(uint256 _amount, address userAdd)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][userAdd];
        return
            (((_amount * pool.poolRewardPercent) / 1000) / 360) *
            ((block.timestamp - user.pool_deposit_time) / 1 days);
    }

    function rewardsCalculate(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 rewards;
        UserInfo storage user = userInfo[_poolId][userAddress];

        uint256 max_payout = this.maxPayoutOf(user.poolBal);
        uint256 calculatedRewards = calculateRewards(user.poolBal, userAddress);
        if (user.poolBal > 0) {
            if (calculatedRewards > max_payout) {
                rewards = max_payout;
            } else {
                rewards = calculatedRewards;
            }
        }
        return rewards;
    }

    function maxPayoutOf(uint256 _amount) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        return
            (((_amount * pool.poolRewardPercent) / 1000) / 360) * pool.poolDays;
    }

    /* Check Token Balance inside Contract */
    function tokenBalance(address tokenAddr) public view returns (uint256) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    /* Check BSC Balance inside Contract */
    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function retrieveEthStuck()
        external
        nonReentrant
        onlyOwner
        returns (bool)
    {
        payable(owner()).transfer(address(this).balance);
        return true;
    }

    function retrieveERC20TokenStuck(
        address _tokenAddr,
        uint256 amount
    ) external nonReentrant onlyOwner returns (bool) {
        IERC20(_tokenAddr).transfer(owner(), amount);
        return true;
    }

    /* Maturity Date */
    function maturityDate(address userAdd) public view returns (uint256) {
        UserInfo storage user = userInfo[_poolId][userAdd];
        PoolInfo storage pool = poolInfo[_poolId];

        return (user.pool_deposit_time + pool.fullMaturityTime);
    }

    function fullMaturityReward(address _userAdd)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_userAdd];
        uint256 fullReward = (((user.poolBal * pool.poolRewardPercent) / 1000) /
            360) * pool.poolDays;
        return fullReward;
    }



    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}