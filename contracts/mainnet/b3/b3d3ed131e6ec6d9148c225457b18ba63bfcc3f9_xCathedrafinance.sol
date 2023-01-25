/**
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ISwapRouter.sol";


contract xCathedrafinance is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint24 public poolFee;
    address public yieldDistributor;
    ISwapRouter public swapRouter;
    uint256 private _totalSupply;

    /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    /*///////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error ZeroRewards();
    error FeeNotSet();
    error NotYield();
    error TRANSFER_FAILED();

    /*///////////////////////////////////////////////////////////////
                              Events
    //////////////////////////////////////////////////////////////*/

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event YieldDistributorSet(
        address indexed caller,
        address indexed _yieldDistributor
    );
    event Compounded(
        address indexed _caller,
        uint256 _wethClaimed,
        uint256 _mgnCompounded
    );
    event FeeSet(address indexed _caller, uint24 _fee);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _swapRouter
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /*///////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice contract which will be able to deposit rewards
     * @param _yield address of the yield controller contract
     */

    function setYield(address _yield) external onlyOwner {
        yieldDistributor = _yield;
        emit YieldDistributorSet(msg.sender, _yield);
    }

    ///@notice sets the fee of the uniswap pool for compounding
    function setFee(uint24 _fee) external onlyOwner {
        poolFee = _fee;
        emit FeeSet(msg.sender, _fee);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                        Reward Logic
    //////////////////////////////////////////////////////////////*/

    ///@param _rewards amount of yield generated to deposit

    function issuanceRate(uint256 _rewards)
        public
        nonReentrant
        updateReward(address(0))
    {
        if (msg.sender != yieldDistributor) {
            revert NotYield();
        }
        require(_rewards > 0, "Zero rewards");
        require(_totalSupply != 0, "xMGN:UVS:ZERO_SUPPLY");
        if (block.timestamp >= periodFinish) {
            rewardRate = _rewards / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_rewards + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        IERC20(rewardsToken).safeTransferFrom(
            msg.sender,
            address(this),
            _rewards
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(_rewards);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /*///////////////////////////////////////////////////////////////
                        User Functions 
    //////////////////////////////////////////////////////////////*/

    function stake(uint256 amount)
        public
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    ///@notice claims fees, swaps them for Cathedrafinance, and stakes that Cathedrafinance
    ///@param amountOutMin the minimum Cathedrafinance back you want to get for your rewards.

    function compound(uint256 amountOutMin) external updateReward(msg.sender) {
        if (poolFee == 0) revert FeeNotSet();
        uint256 claimed = compoundClaim(msg.sender);
        if (claimed < 0) revert ZeroRewards();
        IERC20(rewardsToken).safeIncreaseAllowance(
            address(swapRouter),
            claimed
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(rewardsToken),
                tokenOut: address(stakingToken),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: claimed,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
        compoundedStake(amountOut, msg.sender);
        emit Compounded(msg.sender, claimed, amountOut);
    }

    function compoundedStake(uint256 _amount, address _account)
        internal
        nonReentrant
    {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply += _amount;
        _balances[_account] = _balances[_account] + _amount;
        emit Staked(_account, _amount);
    }

    function compoundClaim(address account)
        internal
        nonReentrant
        returns (uint256)
    {
        uint256 reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            emit RewardPaid(account, reward);
        }
        return reward;
    }

    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
        returns (uint256)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        return reward;
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /*///////////////////////////////////////////////////////////////
                        View Functions 
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /*///////////////////////////////////////////////////////////////
                        Modifier Functions 
    //////////////////////////////////////////////////////////////*/
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}