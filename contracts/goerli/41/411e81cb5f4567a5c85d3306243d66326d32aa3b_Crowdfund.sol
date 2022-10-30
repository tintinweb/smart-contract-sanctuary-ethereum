/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Crowdfund.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;


contract Crowdfund {
    event StartCampaign(uint id, address creator, uint goal, uint startTime, uint endTime);
    event DropCampaign(uint id);

    event Donate(uint indexed _id, address indexed caller,uint amount);
    event Withdraw(uint indexed _id,address indexed caller,uint amount);

    event PayoutOnGoalMet(uint id);
    event Reimburse(uint id, address indexed caller, uint amount);


    struct Campaign {
        address creator;
        uint minContribution; //in weis
        uint currentAmount;
        uint goal;
        uint32 startTime;
        uint32 endTime;
        bool claimed;
    }
    IERC20 public immutable token;
    uint public campaignCount;
    mapping(uint=> Campaign) public ongoingCampaigns; // map count to campaign e.g 0 => Campaign object
    mapping(uint=> mapping(address=>uint)) public potentialDonations; // map count to dict e.g 0 => {address1:100wei, ...., addressN:200wei}

        /*
    IERC20 public immutable token;
    An ERC20 token is a standard used for creating and issuing smart contracts on the Ethereum blockchain
    */
    constructor(address _token) {
        token = IERC20(_token);
    }

    // Allows entrepreuners to start a campaign
    function startCampaign(uint _goal, uint32 _startTime, uint32 _endTime) external {
        require(_startTime >= block.timestamp, "start must be after block creation");
        require(_startTime <= _endTime, "start must be before endTime");
        campaignCount++;
        ongoingCampaigns[campaignCount] = Campaign({
            creator : msg.sender,
            minContribution: 100,
            currentAmount: 0,
            goal: _goal,
            startTime: _startTime,
            endTime: _endTime,
            claimed: false
        });
        emit StartCampaign(campaignCount, msg.sender, _goal, _startTime, _endTime);

    }

    modifier isOwner(uint _id) {
        require(msg.sender == ongoingCampaigns[_id].creator, "Only creator of this campaign can call this function.");
        _;
    }

    // Allows creator to drop a campaign that has not yet started
    function dropCampaign(uint _id) public isOwner(_id) {
        Campaign memory campaign = ongoingCampaigns[_id];
        require(block.timestamp < campaign.startTime, "Campaign has already started");
        delete ongoingCampaigns[_id];
        emit DropCampaign(_id);
    
    }
    
    // Allows people to donate and support a campaign
    function donate(uint _id, uint _amount) external {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp >= campaign.startTime, "Campaign has yet to be started");
        require(block.timestamp <= campaign.endTime, "Campaign has ended and is not receiving any more donation");
        require(_amount >= campaign.minContribution, "Amount supported must be more than minimum contribution of 100 weis");
        campaign.currentAmount += _amount;
        potentialDonations[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Donate(_id, msg.sender, _amount);
    }


    // Allows donator to withdraw donation if it is still within the timeframe of the campaign
    function withdraw(uint _id, uint _amount) external {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp <= campaign.endTime, "Campaign has ended and withdraw operation can't be carried out");

        campaign.currentAmount -= _amount;
        potentialDonations[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Withdraw(_id, msg.sender, _amount);
    }      

    // Allows creator to access funds when goal's met
    function payoutOnGoalMet(uint _id)  public isOwner(_id) {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.currentAmount >= campaign.goal, "Campaign did not meet its goal and funds can't be accessed");
        require(!campaign.claimed, "Payout has already been claimed");

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.currentAmount);

        emit PayoutOnGoalMet(_id);
    }

    // Sends money back only after campaign has finished and campaign did not meet its goals
    function reimburse(uint _id) external {
        Campaign memory campaign = ongoingCampaigns[_id];
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.currentAmount < campaign.goal, "Campaign has met its goal and operation reimburse cannot be carried out");

        uint bal = potentialDonations[_id][msg.sender];
        potentialDonations[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Reimburse(_id, msg.sender, bal);
    }

}