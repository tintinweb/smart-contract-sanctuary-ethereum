/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenRewardContract  {
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public myReceivedReward;


     uint256 public REWARD_RATE = 1; // 1% daily reward rate
    uint256 public constant REWARD_Time = 1 days;
    address public owner;
    uint256 public totalReceivedReward;

    IERC20 public token;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    function claimReward() external {
        require(token.balanceOf(msg.sender) > 0, "You don't have any tokens");
        require(REWARD_Time <= block.timestamp - lastClaimTime[msg.sender] , " please try after 1 day");
        uint256 rewardToSend = calculateReward(msg.sender);
        require(rewardToSend > 0, "No rewards to claim");
        require(token.transfer(msg.sender, rewardToSend), "Reward transfer failed");
        myReceivedReward[msg.sender] = myReceivedReward[msg.sender] + rewardToSend ;
        totalReceivedReward = totalReceivedReward + rewardToSend;
        lastClaimTime[msg.sender] = block.timestamp;
    }
    
    function setReward(uint256 _reward) external onlyOwner{
         REWARD_RATE  = _reward ;
      }

       function calculateReward(address user) private   view returns (uint256) {
           uint256 reward;
        if(lastClaimTime[user]!= 0){
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[user];
        reward = (token.balanceOf(user) * REWARD_RATE * timeSinceLastClaim) / (1 days * 100);
        }else{
              reward = (token.balanceOf(user) * REWARD_RATE ) / 100 ;
        }

         return reward;
    }

     function pendingReward(address user)  public  view returns (uint256) {
           uint256 reward;
        if(lastClaimTime[user]!= 0){
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[user];
        reward = (token.balanceOf(user) * REWARD_RATE * timeSinceLastClaim) / (1 days * 100);
        }else{
            reward = (token.balanceOf(user) * REWARD_RATE ) / 100 ;
        }

         return reward;
    }
      function rewardStatus(address _user)  public  view returns(bool) {

      bool status;
      if(REWARD_Time <= block.timestamp - lastClaimTime[_user]){
          status = true;
      }else{
          status = false;
      }
      return status;
      }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
}