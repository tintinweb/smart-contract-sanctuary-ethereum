// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./StakingPool.sol";

contract StakingPoolFactory {
    /// The address supposed to get the protocol fee
    address public feeTo;

    /// address that can set the address
    address public feeToSetter;

    ///  mapping from Token => Pool address
    mapping(address => address) public getPool;
    address[] public allPools;

    event PoolCreated(address indexed token, address pool, uint256 timeStamp);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address stoken, address rtoken)
        external
        returns (address)
    {
        require(stoken != address(0), "ZERO_ADDRESS");
        require(getPool[stoken] == address(0), "PAIR_EXISTS");

        StakingPool _pool = new StakingPool(stoken, rtoken);

        getPool[stoken] = address(_pool);
        allPools.push(address(_pool));
        emit PoolCreated(stoken, address(_pool), block.timestamp);
        return address(_pool);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Other/interfaces/IERC20.sol";

// - Rewards user for staking their tokens
// - User can withdraw and deposit
// - Earns token while withdrawing

/// rewards are calculated with reward rate and time period staked for

contract StakingPool {
    // tokens intialized
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    // 100 wei per second , calculated for per anum
    uint256 public rewardRate = 100;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // mapping for the rewards for an address
    mapping(address => uint256) public rewards;

    // mapping for the rewards per token paid
    mapping(address => uint256) public rewardsPerTokenPaid;

    // mapping for staked amount by an address
    mapping(address => uint256) public staked;

    // total supply for the staked token in the contract
    uint256 public _totalSupply;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    /// @dev - to calculate the amount of rewards per token staked at current instance
    /// @return uint - the amount of rewardspertoken
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) /
                _totalSupply);
    }

    /// @dev - to calculate the earned rewards for the token staked
    /// @param account - for which it is to be calculated
    /// @return uint -  amount of earned rewards
    function earned(address account) public view returns (uint256) {
        /// amount will be the earned amount according to the staked + the rewards the user earned earlier
        return
            ((staked[account] *
                (rewardPerToken() - rewardsPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    /// modifier that will calculate the amount every time the user calls , and update them in the rewards array
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        /// updating the total rewards owned by the user
        rewards[account] = earned(account);
        /// updatig per token reward amount in the mapping
        rewardsPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    /// @dev to stake some amount of token
    /// @param _amount -  amount to be staked
    function stake(uint256 _amount, address user) external updateReward(user) {
        _totalSupply += _amount;
        staked[user] += _amount;

        ///  need approval
        stakingToken.transferFrom(user, address(this), _amount);
    }

    /// @dev to withdraw the staked amount
    /// @param _amount - amount to be withdrawn
    function withdraw(uint256 _amount, address user)
        external
        updateReward(user)
    {
        _totalSupply -= _amount;
        staked[user] -= _amount;
        stakingToken.transfer(user, _amount);
    }

    /// @dev to withdraw the reward token
    function reedemReward(address user) external updateReward(msg.sender) {
        uint256 reward = rewards[user];
        rewards[user] = 0;
        rewardsToken.transfer(user, reward);
    }
}