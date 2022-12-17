// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Staking{

    event StakeLimitUpdated(Stake);
    event AmountStaked(address userAddress, uint256 level, uint256 amount);
    event Withdraw(address userAddress, uint256 withdrawAmount);
    event OwnershipTransferred(address owner, address newOwner);
    event Paused(address ownerAddress);
    event Unpaused(address ownerAddress);
    event TokenRecovered(address tokenAddress, address walletAddress);

    address public owner;
    IERC20 public token;
    bool private _paused;
    uint256 public reserveAmount;

    struct UserDetail {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool status;
    }

    struct Stake {
        uint256 rewardFeePermile;
        uint256 stakeLimit;
        uint256 penaltyFeePermile;
    }

    mapping(address =>mapping(uint256 => UserDetail)) internal users;
    mapping(uint256 => Stake) internal stakingDetails;

    modifier onlyOwner() {
        require(owner == msg.sender,"Ownable: Caller is not owner");
        _;
    }

    constructor (IERC20 _token) {
        token = _token;

        stakingDetails[1] = Stake(30, 90 days, 35);
        stakingDetails[2] = Stake(65, 180 days, 65);
        stakingDetails[3] = Stake(140, 365 days, 140);

        owner = msg.sender;
    }

    function stake(uint256 amount, uint256 level)
        external
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(!(users[msg.sender][level].status),"user already exist");
        require(_paused == false, "Function Paused");

        users[msg.sender][level].amount = amount;
        users[msg.sender][level].level = level;
        users[msg.sender][level].endTime = block.timestamp + stakingDetails[level].stakeLimit;        
        users[msg.sender][level].initialTime = block.timestamp;
        users[msg.sender][level].status = true;
        token.transferFrom(msg.sender, address(this), amount);
        addReserve(level);
       emit AmountStaked(msg.sender, level, amount);
        return true;
    }

    function getRewards(address account, uint256 level)
        internal
        view
        returns(uint256)
    {
        if(users[account][level].endTime <= block.timestamp) {
            uint256 stakeAmount = users[account][level].amount;
            uint256 rewardRate = stakingDetails[users[account][level].level].rewardFeePermile;
            uint256 rewardAmount = (stakeAmount * rewardRate / 1000);
            return rewardAmount;
        }
        else {
            return 0;
        }
    }

    function withdraw(uint256 level)
        external
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        require(users[msg.sender][level].endTime <= block.timestamp, "staking end time is not reached");
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + users[msg.sender][level].amount;
        token.transfer(msg.sender, amount);

        uint256 rAmount = rewardAmount + users[msg.sender][level].rewardAmount;
        uint256 wAmount = amount + users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rAmount, wAmount, false);
        emit Withdraw(msg.sender, amount);
        return true;
    }

    function emergencyWithdraw(uint256 level)
        external
        returns(uint256)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        uint256 stakedAmount = users[msg.sender][level].amount;
        uint256 penalty = stakedAmount * stakingDetails[level].penaltyFeePermile / 1000;
        token.transfer(msg.sender, stakedAmount - penalty);
        token.transfer(address(this), penalty);
        uint256 rewardAmount = users[msg.sender][level].rewardAmount;
        uint256 withdrawAmount = users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rewardAmount, withdrawAmount, false);

        emit Withdraw(msg.sender, stakedAmount);
        return stakedAmount;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
    {
        require(newOwner != address(0), "Invalid Address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, owner);
    }

    function getUserDetails(address account, uint256 level)
        external
        view
        returns(UserDetail memory, uint256 rewardAmount)
    {
        uint256 reward = getRewards(account, level);
        return (users[account][level], reward);
    }

    function getstakingDetails(uint256 level) external view returns(Stake memory){
        return (stakingDetails[level]);
    }

    function setStakeDetails(uint256 level, Stake memory _stakeDetails)
        external
        onlyOwner
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        stakingDetails[level] = _stakeDetails;
        emit StakeLimitUpdated(stakingDetails[level]);
        return true;
    }

    function paused() external view returns(bool) {
        return _paused;
    }

    function pause() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function addReserve(uint256 level) internal {
        uint256 amount = (users[msg.sender][level].amount * stakingDetails[users[msg.sender][level].level].rewardFeePermile)/1000;
        reserveAmount += (users[msg.sender][level].amount + amount);
    }

    function removeReserve(uint256 level) internal {
        uint256 amount = (users[msg.sender][level].amount * stakingDetails[users[msg.sender][level].level].rewardFeePermile)/1000;
        reserveAmount -= (users[msg.sender][level].amount + amount);
    }

    function recoverToken(address _tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(walletAddress != address(0), "Null address");
        require(IERC20(_tokenAddress).balanceOf(address(this)) > reserveAmount, "Insufficient amount");
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this)) - reserveAmount;
        bool success = IERC20(_tokenAddress).transfer(
            walletAddress,
            amount
        );
        require(success, "tx failed");
        emit TokenRecovered(_tokenAddress, walletAddress);
    }

}