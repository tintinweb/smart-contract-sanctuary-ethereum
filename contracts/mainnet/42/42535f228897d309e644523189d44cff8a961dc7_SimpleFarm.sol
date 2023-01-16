// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.17;

import "./TokenWrapper.sol";

contract SimpleFarm is TokenWrapper {

    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate;
    uint256 public periodFinished;
    uint256 public rewardDuration;
    uint256 public lastUpdateTime;
    uint256 public perTokenStored;

    uint256 constant PRECISION = 1E18;

    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public perTokenPaid;

    address public ownerAddress;
    address public proposedOwner;
    address public managerAddress;

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress,
            "SimpleFarm: INVALID_OWNER"
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == managerAddress,
            "SimpleFarm: INVALID_MANAGER"
        );
        _;
    }

    modifier updateFarm() {
        perTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        _;
    }

    modifier updateUser() {
        userRewards[msg.sender] = earned(msg.sender);
        perTokenPaid[msg.sender] = perTokenStored;
        _;
    }

    event Staked(
        address indexed user,
        uint256 tokenAmount
    );

    event Withdrawn(
        address indexed user,
        uint256 tokenAmount
    );

    event RewardAdded(
        uint256 tokenAmount
    );

    event RewardPaid(
        address indexed user,
        uint256 tokenAmount
    );

    event Recovered(
        IERC20 indexed token,
        uint256 tokenAmount
    );

    event RewardsDurationUpdated(
        uint256 newRewardDuration
    );

    event OwnerProposed(
        address proposedOwner
    );

    event OwnerChanged(
        address newOwner
    );

    event ManagerChanged(
        address newManager
    );

    constructor(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _defaultDuration
    ) {
        require(
            _defaultDuration > 0,
            "SimpleFarm: INVALID_DURATION"
        );

        stakeToken = _stakeToken;
        rewardToken = _rewardToken;

        ownerAddress = msg.sender;
        managerAddress = msg.sender;

        rewardDuration = _defaultDuration;
    }

    /**
     * @dev Tracks timestamp for when reward was applied last time
     */
    function lastTimeRewardApplicable()
        public
        view
        returns (uint256 res)
    {
        res = block.timestamp < periodFinished
            ? block.timestamp
            : periodFinished;
    }

    /**
     * @dev Relative value on reward for single staked token
     */
    function rewardPerToken()
        public
        view
        returns (uint256)
    {
        if (_totalStaked == 0) {
            return perTokenStored;
        }

        uint256 timeFrame = lastTimeRewardApplicable()
            - lastUpdateTime;

        uint256 extraFund = timeFrame
            * rewardRate
            * PRECISION
            / _totalStaked;

        return perTokenStored
            + extraFund;
    }

    /**
     * @dev Reports earned amount by wallet address not yet collected
     */
    function earned(
        address _walletAddress
    )
        public
        view
        returns (uint256)
    {
        uint256 difference = rewardPerToken()
            - perTokenPaid[_walletAddress];

        return _balances[_walletAddress]
            * difference
            / PRECISION
            + userRewards[_walletAddress];
    }

    /**
     * @dev Performs deposit of staked token into the farm
     */
    function farmDeposit(
        uint256 _stakeAmount
    )
        external
        updateFarm()
        updateUser()
    {
        address senderAddress = msg.sender;

        _stake(
            _stakeAmount,
            senderAddress
        );

        safeTransferFrom(
            stakeToken,
            senderAddress,
            address(this),
            _stakeAmount
        );

        emit Staked(
            senderAddress,
            _stakeAmount
        );
    }

    /**
     * @dev Performs withdrawal of staked token from the farm
     */
    function farmWithdraw(
        uint256 _withdrawAmount
    )
        public
        updateFarm()
        updateUser()
    {
        if (block.timestamp < periodFinished) {
            require(
                _totalStaked > _withdrawAmount,
                "SimpleFarm: STILL_EARNING"
            );
        }

        address senderAddress = msg.sender;

        _withdraw(
            _withdrawAmount,
            senderAddress
        );

        safeTransfer(
            stakeToken,
            senderAddress,
            _withdrawAmount
        );

        emit Withdrawn(
            senderAddress,
            _withdrawAmount
        );
    }

    /**
     * @dev Allows to withdraw staked tokens and claim rewards
     */
    function exitFarm()
        external
    {
        uint256 withdrawAmount = _balances[
            msg.sender
        ];

        farmWithdraw(
            withdrawAmount
        );

        claimReward();
    }

    /**
     * @dev Allows to claim accumulated rewards up to date
     */
    function claimReward()
        public
        updateFarm()
        updateUser()
        returns (uint256 rewardAmount)
    {
        address senderAddress = msg.sender;

        rewardAmount = earned(
            senderAddress
        );

        require(
            rewardAmount > 0,
            "SimpleFarm: NOTHING_TO_CLAIM"
        );

        userRewards[senderAddress] = 0;

        safeTransfer(
            rewardToken,
            senderAddress,
            rewardAmount
        );

        emit RewardPaid(
            senderAddress,
            rewardAmount
        );
    }

    /**
     * @dev Allows to invoke owner-change procedure
     */
    function proposeNewOwner(
        address _newOwner
    )
        external
        onlyOwner
    {
        proposedOwner = _newOwner;

        emit OwnerProposed(
            _newOwner
        );
    }

    /**
     * @dev Finalizes owner-change 2-step procedure
     */
    function claimOwnership()
        external
    {
        require(
            msg.sender == proposedOwner,
            "SimpleFarm: INVALID_CANDIDATE"
        );

        ownerAddress = proposedOwner;

        emit OwnerChanged(
            ownerAddress
        );
    }

    /**
     * @dev Allows to change manager of the farm
     */
    function changeManager(
        address _newManager
    )
        external
        onlyOwner
    {
        managerAddress = _newManager;

        emit ManagerChanged(
            _newManager
        );
    }

    /**
     * @dev Allows to recover accidentally sent tokens
     * into the farm except stake and reward tokens
     */
    function recoverToken(
        IERC20 tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        if (tokenAddress == stakeToken) {
            revert("SimpleFarm: INVALID_TOKEN");
        }

        if (tokenAddress == rewardToken) {
            revert("SimpleFarm: INVALID_TOKEN");
        }

        safeTransfer(
            tokenAddress,
            ownerAddress,
            tokenAmount
        );

        emit Recovered(
            tokenAddress,
            tokenAmount
        );
    }

    /**
     * @dev Manager sets the cycle duration for distribution
     * in seconds and can't be changed during active cycle
     */
    function setRewardDuration(
        uint256 _rewardDuration
    )
        external
        onlyManager
    {
        require(
            _rewardDuration > 0,
            "SimpleFarm: INVALID_DURATION"
        );

        require(
            block.timestamp > periodFinished,
            "SimpleFarm: ONGOING_DISTRIBUTION"
        );

        rewardDuration = _rewardDuration;

        emit RewardsDurationUpdated(
            _rewardDuration
        );
    }

    /**
     * @dev Manager sets reward per second to be distributed
     * must have some tokens already staked before executing.
     */
    function setRewardRate(
        uint256 _newRewardRate
    )
        external
        onlyManager
        updateFarm()
    {
        require(
            _totalStaked > 0,
            "SimpleFarm: NO_STAKERS"
        );

        require(
            _newRewardRate > 0,
            "SimpleFarm: INVALID_RATE"
        );

        uint256 currentPeriodFinish = periodFinished;

        lastUpdateTime = block.timestamp;
        periodFinished = block.timestamp
            + rewardDuration;

        if (block.timestamp < currentPeriodFinish) {

            require(
                _newRewardRate >= rewardRate,
                "SimpleFarm: RATE_CANT_DECREASE"
            );

            uint256 remainingTime = currentPeriodFinish
                - block.timestamp;

            uint256 rewardRemains = remainingTime
                * rewardRate;

            safeTransfer(
                rewardToken,
                managerAddress,
                rewardRemains
            );
        }

        rewardRate = _newRewardRate;

        uint256 newRewardAmount = rewardDuration
            * _newRewardRate;

        safeTransferFrom(
            rewardToken,
            managerAddress,
            address(this),
            newRewardAmount
        );

        emit RewardAdded(
            newRewardAmount
        );
    }
}