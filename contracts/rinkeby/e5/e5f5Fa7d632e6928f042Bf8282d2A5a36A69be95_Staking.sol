//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    struct userInfo{
        uint256 amountofStakedLPTokens;
        uint256 timeOfStake;
        uint256 rewardDebt;
    }

    mapping (address => userInfo) public user;
    address ownerAddress;
    address lpToken;
    address rewardToken;
    uint256 freezingTimeForLP;
    uint256 rewardTime;
    uint8 percent;

    constructor(address _lpToken, address _rewardToken, uint256 _freezingTimeForLP, uint256 _rewardTime, uint8 _percent) {
        ownerAddress = msg.sender;
        lpToken = _lpToken;
        rewardToken = _rewardToken;
        freezingTimeForLP = _freezingTimeForLP;
        rewardTime = _rewardTime;
        percent = _percent;
    }

    modifier onlyOwner(){
        require(msg.sender == ownerAddress, "Sender is not an owner");
        _;
    }

    function stake(uint256 amount) external{
        if (user[msg.sender].amountofStakedLPTokens > 0){
            user[msg.sender].rewardDebt+=countReward(msg.sender);
        }
        user[msg.sender].amountofStakedLPTokens+=amount;
        user[msg.sender].timeOfStake = block.timestamp;
        IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
    }

    function claim() external{
        IERC20(rewardToken).transfer(msg.sender, countReward(msg.sender)+user[msg.sender].rewardDebt);
        user[msg.sender].rewardDebt=0;
    }

    function unstake() external{
        require(block.timestamp - user[msg.sender].timeOfStake >= freezingTimeForLP, "It's too soon to unstake");
        IERC20(lpToken).transfer(msg.sender, user[msg.sender].amountofStakedLPTokens);
        user[msg.sender].amountofStakedLPTokens = 0;
    }
    
    function countReward(address _user) public view returns(uint256) {
        return (block.timestamp - user[_user].timeOfStake)/rewardTime * user[_user].amountofStakedLPTokens/100*percent;
    }

    function setRewardTime(uint256 newRewardTime) public onlyOwner{
        rewardTime = newRewardTime;
    }

    function setRewardPercent(uint8 newRewardPercent) public onlyOwner{
        percent = newRewardPercent;
    }

    function setFreezingTimeForLP(uint256 newFreezingTime) public onlyOwner{
        freezingTimeForLP = newFreezingTime;
    }

    function getRewardDebt(address _user) public view returns(uint256) {
        return user[_user].rewardDebt;
    }

    function getAmountofStakedTokens(address _user) public view returns(uint256) {
        return user[_user].amountofStakedLPTokens;
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