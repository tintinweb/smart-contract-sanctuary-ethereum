// contact [email protected] for fund recovery (funds may not be recoverable in all circumstances)
pragma solidity ^0.8.11;
import "./IERC20.sol";

contract CampaignV0 {
  //~~~~~~~~~Constants~~~~~~~~~

  /*
    TODO: remember to replace this value with the correct version for the network
    it is being deployed to!!! current network: Ropsten
  */
  address constant public daiAddress = 0x5608a683D2fDc731b5fC0111d1F964C91E635e1c;

  /*
    A peripheral contract that transferrers DAI to the campaign contracts
    Transfers are sent through the transferrer so users don't need to give
    spending permissions to every campaign contract they want to donate to.
  */
  address constant public transferrer = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

  /*
    A coinraise admin account that can claim forgotten/incorrectly sent funds.
    Admin can only claim funds if they have not been claimed from completed campaigns
      ~six months after the deadline (24 weeks precisely). 
    Funds sent without correctly using the donate() function will also be claimable 
      by the admin ~six months after the deadline.
    Email [email protected] if you have incorrectly sent funds, we may
      be able to recover them for you.
  */
  address constant public admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

  /*
    The fee percentage that goes to coinraise, scaled up by 100
    100 = 1% fee
    25 = 0.25% fee
  */
  uint256 constant public fee = 25;

  /*
    The account that recieves fees
  */
  address constant public feeBenefactor = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;


  //~~~~~~~~Campaign Params~~~~~~~~

  /*
    The account with administrative priviledges over this campaign,
    also the account that will recieve funds fromthis campaign
  */
  address public owner;

  /*
    The title of this campaign, limited to 128 characters
  */
  string public title;

  /*
    The campaign description, limited to 2000 characters
  */
  string public description;

  /*
    The Unix timestamp (in seconds) of this cmpaign's deadline,
      after this time donations are no longer accepted. 
    If the fundingGoal is reached, the owner can withdraw funds at this time. 
    If the fundingGoal is not reached, donors can reclaim their funds at this time. 
    If the fundingGoal is reached, but funds are not claimed by the owner four weeks 
      after the deadline, donors will be able to reclaim those funds.
    If there are unclaimed funds in the contract 24 weeks (~6 months) after the deadline, those funds
      will be considered forgotten and become claimable by a CoinRaise admin
  */
  uint64 public deadline;

  /*
    The funding goal in atomic units of DAI. 
    If the goal is reached by the deadline, the owner will be able to claim raised funds.
    If the goal is not reached, donors will be able to reclaim funds
  */
  uint256 public fundingGoal;

  /*
    The max funding this campaign can receive in atomic units of DAI
    Donations that cause the campaign to exceed this maximum will be rejected.
    Sending funds directly to this campaign contract without using the donate() function will have 
      no effect on donation tracking and the funds will not be claimable by the owner. 
      A CoinRaise admin may be able to reclaim those funds ~6 months after the deadline.
  */
  uint256 public fundingMax;


  //~~~~~~~~~Dev Params~~~~~~~~~

  /*
    A varaible tracking if this campaign has been initialized, it can only be initialized once.
    init() is like a constructor, we use it because we cannot call a regular constructor when
    spawning new campaign contracts with a CloneFactory.
  */
  bool private initialized = false;


  //~~~~~~~~~~~State Data~~~~~~~~~~~

  /*
    A mapping tracking each individual's donations to this campaign
  */
  mapping (address=>uint256) public donations;

  /*
    The total donations to this campaign (does not decrease with claims)
  */
  uint256 public totalDonations;

  /*
    The actual amount of funds available in this contract (after claims)
  */
  uint256 public availableFunds;

  //~~~~~~~~~~Safety~~~~~~~~~~

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  modifier onlyTransferrer() {
    require(msg.sender == transferrer, "Only the transferrer can call this function");
    _;
  }

  //~~~~~~~~~Events~~~~~~~~~

  event donation(address donor, uint256 amount);

  //~~~~~~~~~~~Core~~~~~~~~~~~~

  function init(address _owner, uint64 _deadline, uint256 _fundingGoal, uint256 _fundingMax, string calldata _title, string calldata _description) public {
    // safety checks
    require(initialized == false, "Campaign has already been initialized");
    require(_deadline > block.timestamp + 1 weeks, "Deadline must be at least 1 week from current time");
    require(_deadline < block.timestamp + 156 weeks, "Deadline must be within 3 years of the current time");
    require(_fundingMax >= _fundingGoal, "FundingMax cannot exceed fundingGoal");
    require(bytes(_title).length != 0, "Cannot have empty string for title");
    require(bytes(_description).length != 0, "Cannot have empty string for description");
    
    //set parameters
    initialized = true;
    title = _title;
    description = _description;
    owner = _owner;
    deadline = _deadline;
    //we have to adjust our funding targets for the admin fee, 
    //so the campaign owner receives the actual amount they input
    //target = goal / (1 - feeRate) (0.9975)
    fundingGoal = (_fundingGoal * 10000) / 9975;
    fundingMax = (_fundingMax * 10000) / 9975;
  }

  /*

  */
  function donate(address _donor, uint256 _amount) public onlyTransferrer {
    require(block.timestamp < deadline, "Cannot donate, campaign is already finished");
    require(_amount + totalDonations <= fundingMax, "Donation would exceed the funding maximum");

    donations[_donor] += _amount;
    totalDonations += _amount;
    availableFunds += _amount;
    //sanity check that dai balance is >= donations 
    require(IERC20(daiAddress).balanceOf(address(this)) >= totalDonations, "Sanity check failed, plz investigate");
    emit donation(_donor, _amount);
  }

  function transfer(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  function withdrawOwner() public onlyOwner {
    require(block.timestamp > deadline, "Cannot withdraw, this campaign is not finished yet");
    require(totalDonations >= fundingGoal, "Cannot withdraw, this campaign did not reach it's goal");
    
    //transfer fee to feeBenefactor
    uint256 feeAmount = (availableFunds * fee) / 10000;
    IERC20(daiAddress).transfer(feeBenefactor, feeAmount);

    //transfer DAI to owner
    uint256 transferAmount = availableFunds - feeAmount;
    availableFunds = 0;
    IERC20(daiAddress).transfer(owner, transferAmount);
  }

  function withdrawDonor() public {
    require(block.timestamp > deadline, "Cannot withdraw, this campaign isn't over yet");
    // if the funding goal was reached, require a 4 week wait period for owner to claim funds
    if(totalDonations >= fundingGoal) {
      require(block.timestamp > deadline + 4 weeks, "Cannot withdraw, campaign reached it's goal and 4 week waiting period has not passed");
    }

    //all checks passed
    uint256 transferAmount = donations[msg.sender];
    availableFunds -= transferAmount;
    donations[msg.sender] = 0;

    //transfer dai to msg.sender
    IERC20(daiAddress).transfer(msg.sender, transferAmount);
  }

  function withdrawAdmin(address _token, uint256 _amount) public {
    require(msg.sender == admin, "Only CoinRaise admin can call this function");
    require(block.timestamp > deadline + 24 weeks, "Admin cannot claim forgotten funds before 6 months past the deadline");

    IERC20(_token).transfer(admin, _amount);
  }
}