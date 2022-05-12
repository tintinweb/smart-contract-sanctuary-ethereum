// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/**
 * @notice Interface used to interact with a token created by us
 */
interface SynthetixTokenInterface {
    function mint(address account, uint256 _amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @author Softbinator Technologies
 * @notice This Contract is build after Synthetix Staking Contract
 * @dev Formula is: R * k * ( ∑( 1 / L(t)) < with t = 0, t -> b >  -  ∑( 1 / L(t)) < with t = 0, t -> a-1 > )
 * @dev Where R = reward rate; k = staked amount (constant); L(t) = total supply at the moment t;
 * @dev a = the moment from we start calculating the reward; b = the moment when we stop calculating the reward
 * @dev ∑( 1 / L(t)) < with t = 0, t -> b > is represented by rewardPerTokenStored
 * @dev ∑( 1 / L(t)) < with t = 0, t -> a-1 > is represented by userRewardPerTokenPaid and is specific for each address
 */
contract SynthetixContractStaking {
    /// @notice Interface address used for interaction with a token
    SynthetixTokenInterface public token;

    /// @notice Store the reward for a token stored in the contract
    uint256 public rewardPerTokenStored;

    /// @notice Last time when the somebody made a stake, withdraw or getReward
    uint256 public lastUpdateTime;

    /// @notice The reward that an address will get on a period of time
    /// @notice In this specific contract the user gets the reward at 1 sec
    uint256 public rewardRate = 10;

    /// @notice Total supply of the contract
    uint256 private _totalSupply;

    /// @notice Mapping to know the balance of each address
    mapping(address => uint256) private _balances;

    /// @notice Mapping to know the rewards of each address
    mapping(address => uint256) public rewards;

    /// @notice Mapping to know how much to substract from rewardPerTokenStored for each address before
    /// @notice calculating the reward for each address before calculating the reward
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice Event triggered when the address of the token is changed
    event SetTokenAddress(SynthetixTokenInterface _newAddress);

    /// @notice Event triggered when an address is staking
    event Stake(uint256 amount);

    /// @notice Event triggered when an address is withdrawing
    event Withdraw(uint256 amount);

    /// @notice Event triggered when an address is getting the reward
    event GetReward(uint256 reward);

    /// @notice Error for announcing that the address requesting withdraw doesn't have the requested amount
    error InsufficientFunds();

    /// @notice Error for announcing that the contract doesn't have the requested amount in totalSupply
    error InsufficientFundsInContract();

    /// @notice Error for announcing that the given token address is Address Zero
    error InvalidAddressForToken();

    /// @notice Error for announcing that the given address is Address Zero
    error InvalidAddress();

    constructor(SynthetixTokenInterface _synthetix) {
        if (_synthetix == SynthetixTokenInterface(address(0))) {
            revert InvalidAddressForToken();
        }
        token = _synthetix;
    }

    /**
     * @notice Change the address of the token contract
     * @param _token represents the new token address
     */
    function setToken(SynthetixTokenInterface _token) external {
        if (_token == SynthetixTokenInterface(address(0))) {
            revert InvalidAddressForToken();
        }
        token = _token;
        emit SetTokenAddress(_token);
    }

    /**
     * @notice Calculating the reward for a token
     * @dev Represents the first termen of the difference between the 2 sums from the formula
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return 0;
        }

        return rewardPerTokenStored + ((rewardRate * (block.timestamp - lastUpdateTime) * 1e18) / _totalSupply);
    }

    /**
     * @notice Calculating the reward for an address
     * @param _account represents the address on which the reward is calculated
     */
    function earned(address _account) public view returns (uint256) {
        if (_account == address(0)) {
            revert InvalidAddress();
        }
        uint256 rewardPerTokenValue = rewardPerToken();
        if (rewardPerTokenValue == 0) {
            return rewards[_account];
        }

        return
            ((_balances[_account] * (rewardPerTokenValue - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    /**
     * @notice Modifier that update the state of the contract
     * @param _account represents the address on which the reward is saved
     */
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[_account] = earned(_account);
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        _;
    }

    /**
     * @notice Staking an amount of tokens inside the contract
     * @param _amount represents amount of tokens
     * @dev To not revert, the contract should have allowance from the msg.sender >= then the _amount
     */
    function stake(uint256 _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        emit Stake(_amount);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdrawing an amount of tokens from the contract
     * @param _amount represents the amount of tokens
     */
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        if (_amount > _balances[msg.sender]) {
            revert InsufficientFunds();
        }
        if (_amount > _totalSupply) {
            revert InsufficientFundsInContract();
        }
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        emit Withdraw(_amount);
        token.transfer(msg.sender, _amount);
    }

    /**
     * @notice Getting the earned reward from contract
     */
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        emit GetReward(reward);
        token.mint(msg.sender, reward);
    }
}