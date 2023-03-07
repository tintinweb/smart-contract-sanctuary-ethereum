// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

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

    modifier updateSender(address sender) {
        userRewards[sender] = earned(sender);
        perTokenPaid[sender] = perTokenStored;
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
        uint256 rewardRate,
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
        if (_newOwner == ZERO_ADDRESS) {
            revert("SimpleFarm: WRONG_ADDRESS");
        }

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
        if (_newManager == ZERO_ADDRESS) {
            revert("SimpleFarm: WRONG_ADDRESS");
        }

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
     * and invokes initial distribution to be started right away,
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
            _newRewardRate,
            newRewardAmount
        );
    }

    /**
     * @dev Allows to transfer receipt tokens
     */
    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        updateFarm()
        updateUser()
        updateSender(_recipient)
        returns (bool)
    {
        _transfer(
            msg.sender,
            _recipient,
            _amount
        );

        return true;
    }

    /**
     * @dev Allows to transfer receipt tokens on owner's behalf
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        updateFarm()
        updateSender(_sender)
        updateSender(_recipient)
        returns (bool)
    {
        if (_allowances[_sender][msg.sender] != type(uint256).max) {
            _allowances[_sender][msg.sender] -= _amount;
        }

        _transfer(
            _sender,
            _recipient,
            _amount
        );

        return true;
    }
}

// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

import "./SafeERC20.sol";

contract TokenWrapper is SafeERC20 {

    string public constant name = "VerseFarm";
    string public constant symbol = "VFARM";

    uint8 public constant decimals = 18;

    uint256 _totalStaked;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    address constant ZERO_ADDRESS = address(0x0);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns total amount of staked tokens
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalStaked;
    }

    /**
     * @dev Returns staked amount by wallet address
     */
    function balanceOf(
        address _walletAddress
    )
        external
        view
        returns (uint256)
    {
        return _balances[_walletAddress];
    }

    /**
     * @dev Increases staked amount by wallet address
     */
    function _stake(
        uint256 _amount,
        address _address
    )
        internal
    {
        _totalStaked =
        _totalStaked + _amount;

        unchecked {
            _balances[_address] =
            _balances[_address] + _amount;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _address,
            _amount
        );
    }

    /**
     * @dev Decreases total staked amount
     */
    function _withdraw(
        uint256 _amount,
        address _address
    )
        internal
    {
        unchecked {
            _totalStaked =
            _totalStaked - _amount;
        }

        _balances[_address] =
        _balances[_address] - _amount;

        emit Transfer(
            _address,
            ZERO_ADDRESS,
            _amount
        );
    }

    /**
     * @dev Updates balances during transfer
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
    {
        _balances[_sender] =
        _balances[_sender] - _amount;

        unchecked {
            _balances[_recipient] =
            _balances[_recipient] + _amount;
        }

        emit Transfer(
            _sender,
            _recipient,
            _amount
        );
    }

    /**
     * @dev Grants permission for receipt tokens transfer on owner's behalf
     */
    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _amount
        );

        return true;
    }

    /**
     * @dev Checks value for receipt tokens transfer on owner's behalf
     */
    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev Allowance update for receipt tokens transfer on owner's behalf
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }

    /**
     * @dev Increases value for receipt tokens transfer on owner's behalf
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender] + _addedValue
        );

        return true;
    }

    /**
     * @dev Decreases value for receipt tokens transfer on owner's behalf
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender] - _subtractedValue
        );

        return true;
    }
}

// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

import "./IERC20.sol";

contract SafeERC20 {

    /**
     * @dev Allows to execute transfer for a token
     */
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _value
    )
        internal
    {
        callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                _token.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev Allows to execute transferFrom for a token
     */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                _token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    function callOptionalReturn(
        IERC20 _token,
        bytes memory _data
    )
        private
    {
        (
            bool success,
            bytes memory returndata
        ) = address(_token).call(_data);

        require(
            success,
            "SafeERC20: CALL_FAILED"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(
                    returndata,
                    (bool)
                ),
                "SafeERC20: OPERATION_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

interface IERC20 {

    /**
     * @dev Interface fo transfer function
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Interface for transferFrom function
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);
}