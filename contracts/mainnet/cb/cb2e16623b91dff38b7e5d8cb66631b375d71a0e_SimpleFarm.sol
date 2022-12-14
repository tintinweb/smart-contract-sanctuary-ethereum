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

    modifier updatePool() {
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

    constructor(
        IERC20 _stakeToken,
        IERC20 _rewardToken
    ) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;

        ownerAddress = msg.sender;
        managerAddress = msg.sender;
    }

    function lastTimeRewardApplicable()
        public
        view
        returns (uint256 res)
    {
        res = block.timestamp < periodFinished
            ? block.timestamp
            : periodFinished;
    }

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

    function poolDeposit(
        uint256 _stakeAmount
    )
        external
        updatePool()
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

    function poolWithdraw(
        uint256 _withdrawAmount
    )
        public
        updatePool()
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

    function exitPool()
        external
    {
        uint256 withdrawAmount = _balances[
            msg.sender
        ];

        poolWithdraw(
            withdrawAmount
        );

        getReward();
    }

    function getReward()
        public
        updatePool()
        updateUser()
        returns (uint256 rewardAmount)
    {
        address senderAddress = msg.sender;

        rewardAmount = earned(
            senderAddress
        );

        if (rewardAmount == 0) {
            return 0;
        }

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

    function changeOwner(
        address _newOwner
    )
        external
        onlyOwner
    {
        ownerAddress = _newOwner;
    }

    function changeManager(
        address _newManager
    )
        external
        onlyOwner
    {
        managerAddress = _newManager;
    }

    function recoverToken(
        IERC20 tokenAddress,
        uint256 tokenAmount
    )
        external
        onlyOwner
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

    function setRewardRate(
        uint256 _newRewardRate
    )
        external
        onlyManager
        updatePool()
    {
        require(
            _totalStaked > 0,
            "SimpleFarm: NO_STAKERS"
        );

        require(
            _newRewardRate > 0,
            "SimpleFarm: INVALID_RATE"
        );

        require(
            rewardDuration > 0,
            "SimpleFarm: INVALID_DURATION"
        );

        if (block.timestamp < periodFinished) {

            require(
                _newRewardRate >= rewardRate,
                "SimpleFarm: RATE_CANT_DECREASE"
            );

            uint256 remainingTime = periodFinished
                - block.timestamp;

            uint256 rewardRemains = remainingTime
                * rewardRate;

            safeTransfer(
                rewardToken,
                managerAddress,
                rewardRemains
            );
        }

        uint256 newRewardAmount = rewardDuration
            * _newRewardRate;

        safeTransferFrom(
            rewardToken,
            managerAddress,
            address(this),
            newRewardAmount
        );

        rewardRate = _newRewardRate;

        lastUpdateTime = block.timestamp;
        periodFinished = block.timestamp
            + rewardDuration;

        emit RewardAdded(
            newRewardAmount
        );
    }
}