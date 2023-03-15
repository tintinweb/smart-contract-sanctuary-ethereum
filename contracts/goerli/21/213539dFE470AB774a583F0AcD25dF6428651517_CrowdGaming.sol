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
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdGaming {
  // Events
      event Launch(uint id, address indexed owner, string title, uint goal, string description, uint32 startAt, uint32 endAt);
      event Cancel(uint id);
      event Pledge(uint indexed id, address indexed pledger, uint amount);
      event Revoke(uint indexed id, address indexed pledger, uint amount);
      event Withdraw(uint id);
      event Refund(uint indexed id, address indexed pledger, uint amount);

  // Struct for Campaign
    struct Campaign {
      address owner;
      string title;
      string description;
      uint pledged;
      uint goal;
      uint32 startAt;
      uint32 endAt;
      bool claimed;
    }

  // State variables
    IERC20 public immutable token;
    uint public totalCampaigns;
    mapping (uint => Campaign) public campaigns;
    mapping (uint => mapping(address => uint)) public pledgedAmount;

  // Allow user to decide the token they want to earn
    constructor(address _token) {
      token = IERC20(_token);
    }

  // Function to launch a campaign - public return the campaign ID
    function launchCampaign(string memory _title, string memory _description, uint _goal, uint32 _startAt, uint32 _endAt) external {
    // Require campaign length to be a future date
    require(_startAt >= block.timestamp, "invaild date");
    require(_endAt >= _startAt, "invaild date");
    require(_endAt <= block.timestamp + 14 days, "end at is greater than max duration");
    // Add to totalCampaign variable
    totalCampaigns++;
    // Set new variables for campaign
    campaigns[totalCampaigns] = Campaign({
      owner: msg.sender,
      title: _title,
      goal: _goal,
      pledged: 0,
      description: _description,
      startAt: _startAt,
      endAt: _endAt,
      claimed: false
    });
    // Emit Launch
    emit Launch(totalCampaigns, msg.sender, _title, _goal, _description, _startAt, _endAt);
    
    }
  // Function to cancel a campaign
    function cancelCampaign(uint _id) external {
      Campaign memory campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "not owner");
      require(block.timestamp < campaign.startAt, "already started");
      delete campaigns[_id];
      emit Cancel(_id);
    }


  // Function to pledge to a campaign 
    function pledgeTo(uint _id, uint _amount) external {
    Campaign storage campaign = campaigns[_id];
    require(block.timestamp >= campaign.startAt, "not started");
    require(block.timestamp <= campaign.endAt, "ended");
    campaign.pledged += _amount;
    pledgedAmount[_id][msg.sender] += _amount;
    token.transferFrom(msg.sender, address(this), _amount);

    emit Pledge(_id, msg.sender, _amount);
    }


  // Function to revoke pledge to a campaign - external
    function revokePledge(uint _id, uint _amount) external {
      Campaign storage campaign = campaigns[_id];
      require(block.timestamp <= campaign.endAt, "ended");
      campaign.pledged -= _amount;
      pledgedAmount[_id][msg.sender] -= _amount;
      token.transfer(msg.sender, _amount);

      emit Revoke(_id, msg.sender, _amount);
    }


  // Function to widthraw funds from a campaign 
    //prevent reentracy 
    function withdrawFrom(uint _id) external {
      Campaign storage campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "Not owner");
      require(block.timestamp > campaign.endAt, "Not ended");
      require(campaign.pledged >= campaign.goal, "Didn't meet goal");
      require(!campaign.claimed, "alreayd claimed");

      campaign.claimed = true;
      token.transfer(msg.sender, campaign.pledged);

      emit Withdraw(_id);
    }


  // Function to refund funds if less than half of the campaign goal isn't met 
    function refund(uint _id) external {
      Campaign storage campaign = campaigns[_id];
      require(block.timestamp > campaign.endAt, "Not ended");
      require(campaign.pledged < campaign.goal, "pledged less than goal");

      uint balance = pledgedAmount[_id][msg.sender];
      pledgedAmount[_id][msg.sender] = 0;
      // prevents re-entracy attacks
      token.transfer(msg.sender, balance);

      emit Refund(_id, msg.sender, balance);
    }

 }