//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingContract {
    IERC20 private _rewardsToken;
    IERC20 private _stakingToken;
    mapping(address => uint256) private _stakingAmounts;
    mapping(address => uint256) private _stakingTimestamps;
    uint256 private _rewardTimeoutSeconds = 600;
    uint256 private _unstakeTimeoutSeconds = 1200;
    uint256 private _rewardPercentage = 5;
    address private _owner;

    modifier restricted() {
        require(
            msg.sender == _owner,
            "Only the owner of the contract can perform this operation"
        );
        _;
    }

    constructor(address rewardsToken, address stakingToken) {
        _owner = msg.sender;
        _rewardsToken = IERC20(rewardsToken);
        _stakingToken = IERC20(stakingToken);
    }

    function claimTimeout() public view returns (uint256) {
        return _rewardTimeoutSeconds;
    }

    function unstakeTimeout() public view returns (uint256) {
        return _unstakeTimeoutSeconds;
    }

    function rewardPercentage() public view returns (uint256) {
        return _rewardPercentage;
    }

    function changeSettings(
        uint256 rewardTimeoutSeconds,
        uint256 unstakeTimeoutSeconds,
        uint256 rewardPercentage
    ) external restricted {
        _rewardTimeoutSeconds = rewardTimeoutSeconds;
        _unstakeTimeoutSeconds = unstakeTimeoutSeconds;
        _rewardPercentage = rewardPercentage;
    }

    function stake(uint256 amount) external {
        require(
            _stakingToken.transferFrom(msg.sender, address(this), amount),
            "Couldn't stake LP tokens"
        );

        _stakingAmounts[msg.sender] += amount;
        _stakingTimestamps[msg.sender] = block.timestamp;
    }

    function getStakingAmount(address addrs) public view returns (uint256) {
        return _stakingAmounts[addrs];
    }

    function getStakingTimestamp(address addrs) public view returns (uint256) {
        return _stakingTimestamps[addrs];
    }

    function claim() external {
        uint256 stakingTimestamp = _stakingTimestamps[msg.sender];
        uint256 amount = _stakingAmounts[msg.sender];
        require(stakingTimestamp > 0 && amount > 0, "Nothing to claim");
        uint256 now = block.timestamp;
        require(
            stakingTimestamp + (_rewardTimeoutSeconds) <= now,
            "Reward timeout has not expired yet"
        );
        uint256 diffTime = now - stakingTimestamp;
        uint256 timeRate = _rewardTimeoutSeconds == 0
            ? diffTime
            : diffTime / _rewardTimeoutSeconds;
        uint256 reward = (timeRate * amount * _rewardPercentage) / 100;

        _rewardsToken.transfer(msg.sender, reward);
        _stakingTimestamps[msg.sender] = now;
    }

    function unstake() external {
        require(_stakingAmounts[msg.sender] > 0, "Nothing to unstake");
        require(
            _stakingTimestamps[msg.sender] + (_unstakeTimeoutSeconds) <=
                block.timestamp,
            "Unstake timeout has not expired yet"
        );
        require(
            _stakingToken.transfer(msg.sender, _stakingAmounts[msg.sender]),
            "Couldn't unstake LP tokens"
        );
        _stakingAmounts[msg.sender] = 0;
        _stakingTimestamps[msg.sender] = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}