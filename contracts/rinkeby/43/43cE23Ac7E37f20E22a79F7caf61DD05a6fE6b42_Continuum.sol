pragma solidity ^0.8.4;

import "./safemath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Continuum is ERC20Interface {

    /* 
    TODO:
    -1: GIVE OWNER GOD FUNCTION TO REMOVE MEMBERS, RN TERMINATED MEMBERS STILL GET SHARES AND THE RIGHT TO VOTE
    0. MAYBE REPLCE ALL DIVISION WITH SAFE MATH DIVISON? I DON'T KNOW IF THERE'S ANY REASON TO.
    1. ADD 'CHANGE STATUS' FUNC----------------------------------------------------------------------------------------------------DONE
    2. ADD 'CHANGE DEPARTMENT' FUNC------------------------------------------------------------------------------------------------DONE
    3. VOTE TO WITHDRAW FUNDS TO OWNER? SO FUNDS DON'T GET LOCKED FROM MY BAD CODE... (ideally just write better code)
    4. ADD 'REQUEST PAYOUT' FUNC (MAYBE A VOTE?)
    5. ADD 'CHANGE MINIMUN INVESTMENT' FUNC (VOTE)
    6. ADD 'CHANGE COST PER SHARE' FUNC (VOTE)
    7. ADD 'CHANGE PAYOUT PER SHARE' FUNC **MAYBE** (MAKE IT A VOTE SO OWNER CAN'T SKIMP OUT ON A PAYOUT.)
    8. ADD EMPLOYEE OF THE MONTH BONUS SHARES
    */

    using SafeMath for uint256;

    address public owner;

    uint public override totalSupply = 1000000000; // 1 billion
    uint256 public distributedShares = 0;

    uint256 public distributionEventAmount = 5 ether;
    uint256 public distributionPoolAmount = 0;

    uint256 public sharesPerMonth = 50;
    uint256 public costPerShare = 20000000 gwei; // 0.02 ETH
    uint256 public minimumInvestment = 100;
    uint256 public totalDistributedAmountPublic = 100; // for debug

    enum MemberStatus {Terminated, Approved, Employed, Invested}
    enum MemberDepartment {None, Web3, WebAR, VR}

    struct Member {
        address wallet;
        string id;
        MemberStatus status;
        MemberDepartment department;
        uint256 startDate;
        uint256 monthsAtContinuum;
        uint256 shares;
    }

    struct InvestmentRequest {
        address investor;
        string investorID;
        uint256 requestID;
        uint256 shares;
        string description;
        uint256 requestExpiration;
        uint256 numOfVoters;
        mapping(address => bool) voters;
    }

    address[] public members;

    mapping(address => Member) public memberInfo;

    mapping(address => InvestmentRequest) public investmentRequests;
    uint256 public numOfRequests = 0;

    // InvestmentRequest[] public approvedInvestmentRequests;
    mapping(address => InvestmentRequest[]) public approvedInvestmentRequests;

    AggregatorV3Interface internal ethPriceFeed;

    event ReceivedFunds(uint256 _timeStamp, address _sender, uint256 _recievedFunds);
    event DistributionEvent(uint256 _timeStamp, uint256 _distributionEventAmount, int256 _ethPriceUSD);
    event DistributionEventPriceChange(uint256 _timeStamp, uint256 _newPrice);

    event InvestmentRequestCreated(uint256 _timeStamp, address _investor, uint256 _shares, string _description);
    event InvestmentRequestApproved(uint256 _timeStamp, address _investor, uint256 _shares, string _description);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "The owner isn't allowed to call this function.");
        _;
    }

    modifier onlyMember() {
        if (msg.sender != owner) {
            require(memberInfo[msg.sender].wallet != address(0), "Only members are allowed to call this function.");
            require(memberInfo[msg.sender].status != MemberStatus.Terminated, "Terminated members do not have access to this function.");
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        /*
        * Network: ETH Main Net
        * Aggregator: ETH/USD
        * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

        * Network: Kovan
        * Aggregator: ETH/USD
        * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331

        * Network: Rinkeby
        * Aggregator: ETH/USD
        * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        */
        ethPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getLatestPrice() public view returns (int256) {
    (
        /* uint80 roundID */, 
        int256 price,
        /* uint256 startedAt */,
        /* uint256 timeStamp */,
        /* uint80 answeredInRound */
    ) = ethPriceFeed.latestRoundData();
    return price;
    }

    // <---ERC-20 Functions---> \\

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return memberInfo[tokenOwner].shares;
    }
    
    
    function transfer(address to, uint tokens) public override returns(bool success){
        require(false);
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return 0;
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(false);
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(false);
     }

    // <---NUUM COIN FUNCTIONS--> \\

	receive() external payable {
		emit ReceivedFunds(block.timestamp, msg.sender, msg.value);
	}

    function approveNewMember(address _wallet, string memory _id, bool _isEmployee, MemberDepartment _department, uint256 _monthsAtContinuum) public onlyOwner {
        require(memberInfo[_wallet].wallet == address(0), "This wallet is already a member of Continuum.");
        require(_wallet != owner, "Owner can't approve themselves.");
        uint256 monthsAtContinuum = (_isEmployee ? _monthsAtContinuum : 0);
        uint256 shares = monthsAtContinuum.mul(sharesPerMonth);
        require(shares.add(distributedShares) <= totalSupply, "Member Rejected: Allotted shares will exceed max supply."); // Handle this better...Probably don't want to reject members just because they won't get what they deserve.
        distributedShares = distributedShares.add(shares);
        MemberStatus _status = _isEmployee == true ? MemberStatus.Employed : MemberStatus.Approved;
        Member memory newMember = Member(_wallet, _id, _status, _department, block.timestamp.sub(monthsAtContinuum.mul(30 days)), monthsAtContinuum, shares);
        members.push(_wallet);
        memberInfo[_wallet] = newMember;
        updateDistributionEventAmount();
    }

    function changeMembersStatus(address _wallet, MemberStatus _status) public onlyOwner {
        require(memberInfo[_wallet].wallet == _wallet, "This address is not an approved member of Continuum. Maybe try approving them?");
        require(memberInfo[_wallet].status != MemberStatus.Terminated, "You can't change the status of a terminated member. Maybe try approving them under a new wallet?");
        memberInfo[_wallet].status = _status;
    }

    function changeMembersDepartment(address _wallet, MemberDepartment _department) public onlyOwner {
        require(memberInfo[_wallet].wallet == _wallet, "This address is not an approved member of Continuum. Maybe try approving them?");
        memberInfo[_wallet].department = _department;
    }

    function updateMonthlyShares() public onlyOwner {
        // I think that looping over the array and changing values in the mapping in storage is the best way to do this. But maybe there's a better way in memory to save gas?
        for (uint256 i = 0; i < members.length; i++) {

            address member = members[i];

            if (memberInfo[member].status == MemberStatus.Employed) {
                uint256 startDate = memberInfo[member].startDate;
                
                // As if a month passed for debugging purposes >>
                // uint256 updatedMonthsAtContinuum = (block.timestamp.sub(startDate).add(1 * 30 days)) / 60 / 60 / 24 / 30;
                uint256 updatedMonthsAtContinuum = (block.timestamp.sub(startDate)) / 60 / 60 / 24 / 30;
                uint256 previousMonthsDifference = updatedMonthsAtContinuum.sub(memberInfo[member].monthsAtContinuum);

                memberInfo[member].monthsAtContinuum = updatedMonthsAtContinuum;

                uint256 membersNewShares = previousMonthsDifference.mul(sharesPerMonth);
                require(membersNewShares.add(distributedShares) <= totalSupply, "The monthly distributed shares will exceed the max supply.");
                memberInfo[member].shares = memberInfo[member].shares.add(membersNewShares);
                distributedShares = distributedShares.add(membersNewShares);
            }

        }

        updateDistributionEventAmount();
        
    }

    function fund() public payable  { // Probably should be onlyOwner... but if people want to send us free ETH; I don't see why they shouldn't, it's a free country.
        distributionPoolAmount = distributionPoolAmount.add(msg.value);
        checkForDistributionEvent();
    }

    function requestInvestment(uint256 sharesToPurchase, string memory _description) public onlyMember notOwner { 
        require(sharesToPurchase.add(distributedShares) <= totalSupply, "The shares to be purchased exceeds the max supply.");
        require(investmentRequests[msg.sender].requestExpiration <= block.timestamp, "Your last request is still pending, you must wait for it to pass or expire before making another one.");
        
        delete(investmentRequests[msg.sender]); // Delete the old request (if there is one) before continueing to ensure fresh data. Unnecessary, and probably worth removing.
        
        // Create the new request.
        InvestmentRequest storage newRequest = investmentRequests[msg.sender];
        newRequest.investor = msg.sender;
        newRequest.investorID = memberInfo[msg.sender].id;
        newRequest.requestID = numOfRequests;
        numOfRequests = numOfRequests.add(1);
        newRequest.shares = sharesToPurchase;
        newRequest.description = _description;
        newRequest.requestExpiration = block.timestamp.add(7 days);
        newRequest.numOfVoters = 0;
        
        // Reset all of the previously recorded votes. And make sure terminated employees aren't allowed to vote.
        for (uint256 i = 0; i < members.length; i++) {
            address member = members[i];
            // Don't need to use since we're using 'onlyMember' modifier
            // bool memberIsTerminated = memberInfo[member].status == MemberStatus.Terminated;
            // newRequest.voters[member] = memberIsTerminated;
            newRequest.voters[member] = false;
        }

        emit InvestmentRequestCreated(block.timestamp, msg.sender, sharesToPurchase, _description);
    }

    function voteForInvestRequest(address _investor) public onlyMember notOwner {
        InvestmentRequest storage thisRequest = investmentRequests[_investor];
        require(thisRequest.investor == _investor, "We could not find a request for this address.");
        require(thisRequest.voters[msg.sender] == false, "You have already voted or you were not allowed to participate in this vote.");
        require(thisRequest.requestExpiration > block.timestamp, "This request has expired.");

        thisRequest.voters[msg.sender] = true; // Record the sender's vote.
        thisRequest.numOfVoters = thisRequest.numOfVoters.add(1); // Increment the number of voters.

        // If more than 50% vote, the request passes.
        if (thisRequest.numOfVoters > members.length / 2) {
            
            InvestmentRequest[] storage investorsApprovedRequests = approvedInvestmentRequests[_investor]; // Get refrence of all of this investor's approved requests.
            
            investorsApprovedRequests.push(); // Create a new approved request.
            
            InvestmentRequest storage newApprovedRequest = investorsApprovedRequests[investorsApprovedRequests.length - 1]; // Get a refrence of the newly created approved request.
            // Update the new approved request with the right valiues.
            newApprovedRequest.investor = thisRequest.investor;
            newApprovedRequest.investorID = thisRequest.investorID;
            newApprovedRequest.requestID = thisRequest.requestID;
            newApprovedRequest.shares = thisRequest.shares;
            newApprovedRequest.description = thisRequest.description;
            newApprovedRequest.requestExpiration = thisRequest.requestExpiration;
            investorsApprovedRequests[investorsApprovedRequests.length - 1].investor = _investor;

            delete(investmentRequests[_investor]); // Delete the unapproved request.
            
            emit InvestmentRequestApproved(block.timestamp, newApprovedRequest.investor, newApprovedRequest.shares, newApprovedRequest.description); // Emit that the request was approved.
        }
    }

    function invest(uint256 sharesToPurchase, uint256 investmentRequestID) public payable onlyMember notOwner {
        InvestmentRequest[] storage investorsApprovedRequests = approvedInvestmentRequests[msg.sender];

        uint256 approvedShares = 0;

        bool isValidRequest = false;

        for (uint256 i = 0; i < investorsApprovedRequests.length; i++) {
            InvestmentRequest storage approvedRequest = investorsApprovedRequests[i]; // Get a refrence of the request currently iterated on.
            // If the iterated on request ID is equal to the ID we are currently trying to complete an investment on, keep a refrence of it and break the loop.
            if (approvedRequest.requestID == investmentRequestID) {
                approvedShares = approvedRequest.shares;
                isValidRequest = true;
                delete(investorsApprovedRequests[i]);
                break;
            }
        }

        require(isValidRequest == true, "Could not find the request of the ID you entered.");
        require(sharesToPurchase == approvedShares, "The shares of the investment request you are currently trying to complete, do not match those of which you have requested to buy.");
        require(sharesToPurchase.add(distributedShares) <= totalSupply, "The shares to be purchased exceeds the max supply.");
        require(sharesToPurchase >= minimumInvestment, "Your investment did not hit the minimum requirement.");
        require(msg.value == sharesToPurchase.mul(costPerShare), "Your investment does not equal the cost of your desired shares.");

        memberInfo[msg.sender].shares = memberInfo[msg.sender].shares.add(sharesToPurchase);

        if (memberInfo[msg.sender].status == MemberStatus.Approved) {
            memberInfo[msg.sender].status = MemberStatus.Invested;
        }

        distributedShares = distributedShares.add(sharesToPurchase);
        distributionPoolAmount = distributionPoolAmount.add(msg.value);

        /*
        Right now I'm checking for the distribution event before updating the 'distributonEventAmount', as to not move the goal posts.
        But maybe I wamt to switch the order of the next two lines so the distributionEvent stays propertionally distributed to all members?
        i.e. if someone makes an absolute massive investment and now controls the majority of the shares; they will get the majority of the pool that everyone worked for.
        On the other hand, that investment would also cost a lot, meaning all members would only suffer the loss of getting a smaller piece of a bigger pie...which I don't see as a problem...
        Along with that, the alternative may mean that an investment of that size makes the pool so large that it may not get hit frequently enough as everyone hopes/expects/relies on.
        */
        checkForDistributionEvent();
        updateDistributionEventAmount();

    }

    function updateDistributionEventAmount() private {
        if (distributionEventAmount < costPerShare.mul(distributedShares)) {
            distributionEventAmount = costPerShare.mul(distributedShares);
            emit DistributionEventPriceChange(block.timestamp, distributionEventAmount);
        }
    }

    function checkForDistributionEvent() private {  
        // This is the way we talked about doing it >>>
        // if (distributionPoolAmount >= costPerShare.mul(distributedShares)) {
        //     emit DistributionEvent(block.timestamp, distributionEventAmount);
        //     distributePool();
        // }
        // This is how I set it up with all the variables >>>
        if (distributionPoolAmount >= distributionEventAmount) {
            // emit DistributionEvent(block.timestamp, distributionEventAmount, getLatestPrice()); // Will cause failure if using VM, switch to rinkeby network and construct 'ethPriceFeed' with correct newtwork address for debug.
            distributePool();
        }
    }

    function distributePool() private {

        uint256 startPoolAmount = distributionPoolAmount;

        /* 
        Probs expensive in gas for using a while loop here, BUT makes it so less ETH gets stuck in contract inbetween distribution events. 
        The only way this works is because 'distributionPoolAmount' is a dynamic var that is based off 'distributedShares'
        Therefore a distribution event will never be called where 'distributionPoolAmount' starts off less than 'distributedShares
        */
        while (distributionPoolAmount >= 100) {

            uint256 totalDistributedAmount = 0;

            for (uint256 i = 0; i < members.length; i++) {

                // Code has rounding problems that leaves ETH stuck in the contract. Need away to get that out somehow, right now I am just looping until the amount can't be proportionally distributed

                address member = members[i];

                uint256 membersShares = memberInfo[member].shares;

                uint256 distributionPercent = (membersShares.mul(100)) / distributedShares;

                // Issue here; dealing with uint256, but need a float for percentages. So distribution amount rounds down.
                uint256 distributionAmount = ((distributionPoolAmount / 10).mul(distributionPercent)) / 10;

                totalDistributedAmount = totalDistributedAmount.add(distributionAmount);

                payable(member).transfer(distributionAmount);

            }

            distributionPoolAmount = distributionPoolAmount.sub(totalDistributedAmount);

        }

        totalDistributedAmountPublic = startPoolAmount.sub(distributionPoolAmount);

        // distributionPoolAmount = distributionPoolAmount.sub(totalDistributedAmount);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "Multiplicaion overflowed");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Subtraction underflowed");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "Addition Overflowed");
    return c;
  }
}