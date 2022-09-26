// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "usingtellor/contracts/UsingTellor.sol";

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ERC20Burnable {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    function burn(uint256 amount) external;
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



contract Investable is Ownable, ReentrancyGuard, UsingTellor  {
    using SafeMath for uint256;

    bool isPaused;

    string constant public TERMS = "We will never contact you first "

"of fake accounts usurping project and their members identities in order to "
"defraud you, we will never contact you by private message first. "

"We cannot be held responsible for any correspondence you have with any of our potential usurpers. "

"Be sure to identify team members with their respective badges before contacting them. "
"We are not financial advisers "

"Your decision to invest and its results are entirely your responsibility, we cannot be held responsible "
"for any loss. "
"The Road Map is likely to evolve "

"The roadmap brings together most of our ideas, plans and strategies but these are likely to change "
"as the project progresses. All modifications and changes will be announced in advance, so our "
"investors will not be surprised.";

    mapping(address => bool) public userAgreed;

    address usdtAddress;
    address alfAddress;
    
    uint public totalUsdtLocked;
    uint public totalAlfLocked;
    uint public totalActiveInvestments;
    uint256 public activeInvestor;

    //Quantity of usdt returned for a refund
    uint public refundPerTenThousand = 7_000; //70%

    //Quantity of alfcoin burned whane claimed
    uint public burnPerTenThousand = 500; //5%

    

    //An investor can as a refund if his invest plan is active since refundThreshold seconds
    uint public refundThreshold = 1;

    struct InvestPlan {
        string name;
        string desc;
        uint256 alfToLock;
        uint256 minimumUsdtToInvest;
        uint256 maximumUsdtToInvest;
        Duration[] durations;
    }

    struct Duration {
        string name;
        uint256 apyPerTenThousand;
        uint256 duration;
        uint256 referralReturnPerTenThousand;
    }

    mapping(address => bool) public influencerReferral;

    
    
    struct Referral {
        address referred;
        uint usdtAmount;
        Status status;


    }

    enum Status {
        INPROGRESS,
        COLLECTED,
        REFUNDED
    }

    struct Refferant{
        address referrant;
        Referral[] referrals;
        uint totalUsdtRewardSended;
        uint totalUsdtRewardPending;

    }

    struct Investor{
        address investor;
        Investment[] investments;
        uint referralPosition;
        address referrant;
        uint activeInvestment;
        
    }

    Refferant[] internal referrants;
    Investor[] internal investors;

    struct Investment {
        InvestPlan investPlan;
        uint durationIndex;
        uint usdtInvested;
        uint since;
        bool refundAsked;
        Status status;
    }

    mapping(address => uint256) internal investments;
    mapping(address => uint256) internal referrals;

    InvestPlan[] internal investPlans;
    

    event RefundAsking(address indexed investor, uint investmentIndex, uint usdtToSend);
    event NewInvestment(address indexed investor, uint investmentIndex, uint usdtInvested, uint apy, uint referralAmount, uint end);
    event EndInvestment(address indexed investor, uint investmentIndex);
    event RefundInvestment(address indexed investor, uint investmentIndex);


    constructor(address alf, address usdt, address payable tellorAddress) UsingTellor(tellorAddress) {
        
        activeInvestor = 0;

        alfAddress = alf;
        usdtAddress = usdt;

        isPaused = false;

        totalUsdtLocked = 0;
        totalAlfLocked = 0;
        totalActiveInvestments = 0;

        
        investPlans.push();
        investPlans[0].name = "Rookie";
        investPlans[0].desc = "A desc";
        investPlans[0].alfToLock = 100 * 10 ** ERC20(alfAddress).decimals(); // TODO à définir
        investPlans[0].minimumUsdtToInvest = 100 * 10 ** ERC20(usdtAddress).decimals();
        investPlans[0].maximumUsdtToInvest = 500 * 10 ** ERC20(usdtAddress).decimals();
        investPlans[0].durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 300, // 3%
                referralReturnPerTenThousand: 100
            })
        );
        investPlans[0].durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 1_300, // 13%
                referralReturnPerTenThousand: 200
            })
        );
        investPlans[0].durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 4_000, // 40%
                referralReturnPerTenThousand: 300
            })
        );
        investPlans[0].durations.push(
            Duration({
                name: "1 year",
                duration: 7 days,
                apyPerTenThousand: 15_000, // 150%
                referralReturnPerTenThousand: 600
            })
        );
        
        investPlans.push();
        investPlans[1].name = "Sophomore";
        investPlans[1].desc = "A desc";
        investPlans[1].alfToLock = 500 * 10 ** ERC20(alfAddress).decimals(); // TODO à définir
        investPlans[1].minimumUsdtToInvest = 500 * 10 ** ERC20(usdtAddress).decimals(); // TODO à définir
        investPlans[1].maximumUsdtToInvest = 1000 * 10 ** ERC20(usdtAddress).decimals();
        investPlans[1].durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 200, // 2%
                referralReturnPerTenThousand: 100
            })
        );
        investPlans[1].durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 1_300, // 13%
                referralReturnPerTenThousand: 200
            })
        );
        investPlans[1].durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 3_900, // 39%
                referralReturnPerTenThousand: 300
            })
        );
        investPlans[1].durations.push(
            Duration({
                name: "1 year",
                duration: 7 days,
                apyPerTenThousand: 14_900, // 149%
                referralReturnPerTenThousand: 600
            })
        );

        investPlans.push();
        investPlans[2].name = "Professional";
        investPlans[2].desc = "A desc";
        investPlans[2].alfToLock = 1000 * 10 ** ERC20(alfAddress).decimals(); // TODO à définir
        investPlans[2].minimumUsdtToInvest = 1000 * 10 ** ERC20(usdtAddress).decimals(); // TODO à définir
        investPlans[2].maximumUsdtToInvest = 5000 * 10 ** ERC20(usdtAddress).decimals();
        investPlans[2].durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 225, // 2.25%
                referralReturnPerTenThousand: 100
            })
        );
        investPlans[2].durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 1_325, // 13.25%
                referralReturnPerTenThousand: 200
            })
        );
        investPlans[2].durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 3_925, // 39.25%
                referralReturnPerTenThousand: 300
            })
        );
        investPlans[2].durations.push(
            Duration({
                name: "1 year",
                duration: 7 days,
                apyPerTenThousand: 14_925, // 149.25%
                referralReturnPerTenThousand: 600
            })
        );

        investPlans.push();
        investPlans[3].name = "All-Star";
        investPlans[3].desc = "A desc";
        investPlans[3].alfToLock = 5000 * 10 ** ERC20(alfAddress).decimals(); // TODO à définir
        investPlans[3].minimumUsdtToInvest = 5000 * 10 ** ERC20(usdtAddress).decimals(); // TODO à définir
        investPlans[3].maximumUsdtToInvest = 10000 * 10 ** ERC20(usdtAddress).decimals();
        investPlans[3].durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 250, // 2.50%
                referralReturnPerTenThousand: 100
            })
        );
        investPlans[3].durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 1_350, // 13.50%
                referralReturnPerTenThousand: 200
            })
        );
        investPlans[3].durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 3_950, // 39.50%
                referralReturnPerTenThousand: 300
            })
        );
        investPlans[3].durations.push(
            Duration({
                name: "1 year",
                duration: 7 days,
                apyPerTenThousand: 14_950, // 149.50%
                referralReturnPerTenThousand: 600
            })
        );

        investPlans.push();
        investPlans[4].name = "Legend";
        investPlans[4].desc = "A desc";
        investPlans[4].alfToLock = 5000 * 10 ** ERC20(alfAddress).decimals(); // TODO à définir
        investPlans[4].minimumUsdtToInvest = 10000 * 10 ** ERC20(usdtAddress).decimals(); // TODO à définir
        investPlans[4].maximumUsdtToInvest = 0;
        investPlans[4].durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 275, // 2.75%
                referralReturnPerTenThousand: 100
            })
        );
        investPlans[4].durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 1_375, // 13.75%
                referralReturnPerTenThousand: 200
            })
        );
        investPlans[4].durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 3_975, // 39.75%
                referralReturnPerTenThousand: 300
            })
        );
        investPlans[4].durations.push(
            Duration({
                name: "1 year",
                duration: 7 days,
                apyPerTenThousand: 14_975, // 149.75%
                referralReturnPerTenThousand: 600
            })
        );
    }

    

    function setRefundThreshold(uint _seconds) external onlyOwner {
        require(refundThreshold != _seconds, "refund threshold already has this value !");
        refundThreshold = _seconds;
    }

    function setInflencerReferral(address _address, bool _isInfluencerReferral) external onlyOwner {
        require(influencerReferral[_address] != _isInfluencerReferral, "This address already has this value !");
        require(investments[_address]==0, "Influencer mustn't be an investor");
        influencerReferral[_address] = _isInfluencerReferral;
        uint256 position = referrals[_address];
       
        if(position == 0){
            _addRefferant(_address);
        }
    }

    function agreed() external {
        require(!userAgreed[msg.sender], "User has already agreed terms");
        userAgreed[msg.sender] = true;
    }

    function pauseInvest(bool _pause) external onlyOwner {
        isPaused = _pause;
    }


    function _addInvestor(address _investor, address _referrant) internal returns(uint) {
        // Push a empty item to the Array to make space for our new stakeholder
        investors.push();

        uint256 investorPosition = investors.length;
        
        investors[investorPosition - 1].investor = _investor;
        investors[investorPosition - 1].referrant = _referrant;
        investors[investorPosition - 1].activeInvestment = 0;
        // Add position to the stakeHolders
        investments[_investor] = investorPosition;
        return investorPosition;
    }

    function getPrice() external view returns(uint256) {
        
    // _tellorAddress is the address of the Tellor oracle

      bytes memory _queryData = abi.encode("SpotPrice", abi.encode("alf", "usd"));
      bytes32 _queryId = keccak256(_queryData);
      (bool ifRetrieve, bytes memory _value, ) =
          getCurrentValue(_queryId);
      if (!ifRetrieve) return 0;
      return abi.decode(_value, (uint256));
   
    }

    function _addRefferant(address _referrant) internal returns(uint) {
        // Push a empty item to the Array to make space for our new stakeholder
       
        referrants.push();

        
        
        uint256 referrantPosition = referrants.length;
        
        referrants[referrantPosition - 1].referrant = _referrant;
        referrants[referrantPosition - 1].totalUsdtRewardPending = 0;
        referrants[referrantPosition - 1].totalUsdtRewardSended = 0;
        
        // Add position to the stakeRefferants
        referrals[_referrant] = referrantPosition;
        return referrantPosition;
    }

    function canReffer(address _address) public view returns(bool) {
        if(influencerReferral[_address]) return true;
        uint256 position = investments[_address];
        if(position == 0) return false;
        else if(investors[position - 1].activeInvestment > 0) return true;
        else return false;
    }

    

    function claim(uint _investmentIndex) external nonReentrant {
        uint investorPosition = investments[msg.sender];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");
        
        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        InvestPlan storage investPlan = investment.investPlan;

        Duration storage duration = investPlan.durations[investment.durationIndex];

        uint currentTimeStamp = block.timestamp;

        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded");
        require(currentTimeStamp >= investment.since + duration.duration, "Investment not ended");

        uint usdtToSend = investment.usdtInvested.add(investment.usdtInvested.mul(duration.apyPerTenThousand).div(10_000)); // a diviser par 1000

        uint alfToBurn = investPlan.alfToLock.mul(burnPerTenThousand).div(10_000);
        uint alfToSend = investPlan.alfToLock.sub(alfToBurn);
        
        uint referralUsdtAmount = 0;
        if(investors[investorPosition - 1].referrant != address(0) && _investmentIndex == 0){
            uint referrantPosition = referrals[investors[investorPosition - 1].referrant];
            uint referralPosition = investors[investorPosition - 1].referralPosition;
            Referral storage referral = referrants[referrantPosition-1].referrals[referralPosition - 1];
            referralUsdtAmount = referral.usdtAmount;

            referral.status = Status.COLLECTED;

            referrants[referrantPosition-1].totalUsdtRewardSended += referralUsdtAmount;
            referrants[referrantPosition-1].totalUsdtRewardPending -= referralUsdtAmount;
        }
        require(ERC20(usdtAddress).balanceOf(address(this)) >= usdtToSend + referralUsdtAmount, "Not enough usdt on contract, please contact admin");
        require(ERC20(alfAddress).balanceOf(address(this)) >= investPlan.alfToLock, "Not enough alf on contract, please contact admin");


        ERC20(usdtAddress).transfer(msg.sender, usdtToSend);
        ERC20(alfAddress).transfer(msg.sender, alfToSend); 
        ERC20Burnable(alfAddress).burn(alfToBurn); 
        if(referralUsdtAmount > 0){
            ERC20(usdtAddress).transfer(investors[investorPosition - 1].referrant, referralUsdtAmount);
        }
        
        

        investment.status = Status.COLLECTED;
        investors[investorPosition - 1].activeInvestment -= 1;

        
        if(investors[investorPosition - 1].activeInvestment == 0){
            activeInvestor -= 1;
        }

        totalActiveInvestments -= 1;
        totalUsdtLocked -= investment.usdtInvested;
        totalAlfLocked -= investPlan.alfToLock;

        emit EndInvestment(msg.sender, _investmentIndex);
       
    }

    function isInvestorActive(uint256 _investorIndex) internal view returns(bool){

        if(investors[_investorIndex].activeInvestment > 0) return true;
        else return false;
        
    }

    function withdraw(uint amount) external onlyOwner { //OnlyOwner
        require(ERC20(usdtAddress).balanceOf(address(this)) >= amount, "Not enough usdt on the smart contract");
        ERC20(usdtAddress).transfer(msg.sender, amount);

    }

    function deposit(uint amount) external onlyOwner { //OnlyOwner
        uint walletBalance = ERC20(usdtAddress).balanceOf(msg.sender);
        require(walletBalance >= amount, "Not enough usdt on the wallet");
        require(ERC20(usdtAddress).allowance(msg.sender, address(this)) >= amount, "Not allowed to withdraw this amount of usdt from wallet!");

        ERC20(usdtAddress).transferFrom(msg.sender, address(this), amount);

    }

    function askRefund(uint _investmentIndex) external {
        uint investorPosition = investments[msg.sender];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");

        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded !");
        require(block.timestamp - investment.since >= refundThreshold, "This investment cannot be refunded yet !");

        investment.refundAsked = true;

        emit RefundAsking(msg.sender, _investmentIndex, investment.usdtInvested.mul(refundPerTenThousand).div(10_000));


    }

    function refund(address _investor, uint _investmentIndex) external onlyOwner{ // onlyOwner


        uint investorPosition = investments[_investor];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");
        
        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        InvestPlan storage investPlan = investment.investPlan;

        Duration storage duration = investPlan.durations[investment.durationIndex];

        uint currentTimeStamp = block.timestamp;
        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded !");
        require(investment.refundAsked, "Investor dosen't ask refund for this investment");
        require(currentTimeStamp < investment.since + duration.duration, "Investment has ended. You must claim");

        uint usdtToSend = investment.usdtInvested.mul(refundPerTenThousand).div(10_000); 

        uint alfToBurn = investPlan.alfToLock.mul(burnPerTenThousand).div(10_000);
        uint alfToSend = investPlan.alfToLock.sub(alfToBurn);
        

        if(investors[investorPosition - 1].referrant != address(0) && _investmentIndex == 0){
            uint referrantPosition = referrals[investors[investorPosition - 1].referrant];
            uint referralPosition = investors[investorPosition - 1].referralPosition;
            Referral storage referral = referrants[referrantPosition-1].referrals[referralPosition - 1];
            uint referralUsdtAmount = referral.usdtAmount;

            referral.status = Status.REFUNDED;

            
            referrants[referrantPosition-1].totalUsdtRewardPending -= referralUsdtAmount;
        }

        require(ERC20(usdtAddress).balanceOf(address(this)) >= usdtToSend, "Not enough usdt on contract, please contact admin");
        require(ERC20(alfAddress).balanceOf(address(this)) >= investPlan.alfToLock, "Not enough alf on contract, please contact admin");


        ERC20(usdtAddress).transfer(_investor, usdtToSend);
        ERC20(alfAddress).transfer(_investor, alfToSend); 
        ERC20Burnable(alfAddress).burn(alfToBurn); 
        


        //remove investment
        //for (uint i = _investmentIndex; i<investors[position - 1].investments.length-1; i++){
        //    investors[position - 1].investments[i] = investors[position - 1].investments[i+1];
        //}
        //investors[position - 1].investments.pop();    
        
        investment.status = Status.REFUNDED;

        investors[investorPosition - 1].activeInvestment -= 1;

        
        if(investors[investorPosition - 1].activeInvestment == 0){
            activeInvestor -= 1;
        }

        totalActiveInvestments -= 1;
        totalUsdtLocked -= investment.usdtInvested;
        totalAlfLocked -= investPlan.alfToLock;

        emit RefundInvestment(_investor, _investmentIndex);

    }

    function removeInvestPlan(uint _investPlanIndex) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        for (uint i = _investPlanIndex; i<investPlans.length-1; i++){
            investPlans[i] = investPlans[i+1];
        }
        investPlans.pop();
    }

    function updateInvestPlan(
        uint _investPlanIndex,
        string calldata _name,
        string calldata _desc,
        uint _alfToLock,
        uint _minimumUsdtToInvest,
        uint _maximumUsdtToInvest
    ) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        require(_minimumUsdtToInvest < _maximumUsdtToInvest, "Maximum amount of usdt to invest must be greater than minimum amount of usdt to invest");

        InvestPlan storage investPlan = investPlans[_investPlanIndex];

        investPlan.name = _name;
        investPlan.desc = _desc;
        investPlan.alfToLock = _alfToLock;
        investPlan.minimumUsdtToInvest = _minimumUsdtToInvest;
        investPlan.maximumUsdtToInvest = _maximumUsdtToInvest;
    }

    function addInvestPlan(
        string calldata _name,
        string calldata _desc,
        uint _alfToLock,
        uint _minimumUsdtToInvest,
        uint _maximumUsdtToInvest
    ) external onlyOwner {
        investPlans.push();
        uint index = investPlans.length - 1;
        investPlans[index].name = _name;
        investPlans[index].desc = _desc;
        investPlans[index].alfToLock = _alfToLock; // TODO à définir
        investPlans[index].minimumUsdtToInvest = _minimumUsdtToInvest; // TODO à définir
        investPlans[index].maximumUsdtToInvest = _maximumUsdtToInvest;
    }

    function removeDuration(uint _investPlanIndex, uint _durationIndex) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        require(investPlans[_investPlanIndex].durations.length - 1 >= _durationIndex, "Specified duration doesn't exist");
        for (uint i = _durationIndex; i<investPlans[_investPlanIndex].durations.length-1; i++){
            investPlans[_investPlanIndex].durations[i] = investPlans[_investPlanIndex].durations[i+1];
        }
        investPlans[_investPlanIndex].durations.pop();
    }

    function updateDuration(
        uint _investPlanIndex,
        uint _durationIndex,
        string calldata _name,
        uint _duration, 
        uint _apyPerTenThousand,
        uint _referralReturnPerTenThousand
    ) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        require(investPlans[_investPlanIndex].durations.length - 1 >= _durationIndex, "Specified duration doesn't exist");

        Duration storage duration = investPlans[_investPlanIndex].durations[_durationIndex];

        duration.name = _name;
        duration.duration = _duration;
        duration.apyPerTenThousand = _apyPerTenThousand;
        duration.referralReturnPerTenThousand = _referralReturnPerTenThousand;

    }


    function addDuration(
        uint _investPlanIndex,
        string calldata _name,
        uint _duration, // in seconds
        uint _apyPerTenThousand,
        uint _referralReturnPerTenThousand
    ) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        investPlans[_investPlanIndex].durations.push(
            Duration({
                name: _name,
                duration: _duration,
                apyPerTenThousand: _apyPerTenThousand,
                referralReturnPerTenThousand: _referralReturnPerTenThousand
            })
        );
    }

    function getInvestment(address _investor, uint _investmentIndex) external view returns (Investment memory) {
        uint position = investments[_investor];
        require(position > 0, "This address is not an investor");
        require(investors[position - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");

        
        Investment memory investment = investors[position - 1].investments[_investmentIndex];
        return investment;

    }

    function getInvestments(address _investor) external view returns (Investment[] memory) {
        uint position = investments[_investor];
        require(position > 0, "This address is not an investor");
        
        Investment[] memory investorInvestments = investors[position - 1].investments;
        return investorInvestments;

    }

    function getInvestorInfo(address _investor) external view returns (Investor memory) {
        uint position = investments[_investor];
        require(position > 0, "This address is not an investor");
        
        Investor memory investor = investors[position - 1];
        return investor;

    }

    function getReferrals(address _referrant) external view returns (Referral[] memory) {
        uint position = referrals[_referrant];
        require(position > 0, "This address is not a referrant");
        
        Referral[] memory referrantReferrals = referrants[position - 1].referrals;
        return referrantReferrals;

    }

    function getReferrantInfo(address _referrant) external view returns (Refferant memory) {
        uint position = referrals[_referrant];
        require(position > 0, "This address is not a referrant");
        
        Refferant memory referrant = referrants[position - 1];
        return referrant;

    }

    function hasInvestments(address _investor) external view returns (bool) {
        uint position = investments[_investor];
        if(position == 0) return false;
        else if(investors[position - 1].investments.length == 0) return false;
        else return true;

    }
    
    function hasReferrals(address _referrant) external view returns (bool) {
        uint position = referrals[_referrant];
        if(position == 0) return false;
        else if(referrants[position - 1].referrals.length == 0) return false;
        else return true;

    }

    function getInvestPlans() external view returns(InvestPlan[] memory){
        return investPlans;
    }

    function getInvestors() external view returns(Investor[] memory)  {
        return investors;
    }

    struct InvestmentSummary {
        uint usdtLocked;
        uint alfLocked;
        uint investmentsAmount;
        uint investorsAmount;
    }

    function getInvestmentSummary() external view returns(InvestmentSummary memory) {
        InvestmentSummary memory summary = InvestmentSummary({
            usdtLocked: totalUsdtLocked,
            alfLocked: totalAlfLocked,
            investmentsAmount: totalActiveInvestments,
            investorsAmount: activeInvestor
        });

        return summary;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);

        if (_count == 0) {
            return (false, bytes(""), 0);
        }
        uint256 _time = getTimestampbyQueryIdandIndex(_queryId, _count - 1);
        _value = retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        uint256 _time = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);

        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get immediate next value
                    uint256 _nextTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't find a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getTimestampCountById(_queryId);
        } else {
            return tellor.getNewValueCountbyQueryId(_queryId);
        }
    }

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getReportTimestampByIndex(_queryId, _index);
        } else {
            return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        }
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        ITellor _governance;
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            ITellor _newTellor = ITellor(
                0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0
            );
            _governance = ITellor(
                _newTellor.addresses(
                    0xefa19baa864049f50491093580c5433e97e8d5e41f8db1a61108b4fa44cacd93
                )
            );
        } else {
            _governance = ITellor(tellor.governance());
        }
        return
            _governance
                .getVoteRounds(
                    keccak256(abi.encodePacked(_queryId, _timestamp))
                )
                .length > 0;
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getValueByTimestamp(_queryId, _timestamp);
        } else {
            return tellor.retrieveData(_queryId, _timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor{
    //Controller
    function addresses(bytes32) external view returns(address);
    function uints(bytes32) external view returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getAllDisputeVars(uint256 _disputeId) external view returns (bytes32,bool,bool,bool,address,address,address,uint256[9] memory,int256);
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns(uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function isMigrated(address _addy) external view returns (bool);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function governance() external view returns (address);
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function isApprovedGovernanceContract(address _contract) external returns (bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteCount() external view returns(uint256);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(bytes32 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReportingLock() external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _maxAmount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256,uint256,bool);
    function getTreasuryCount() external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;
    function migrateFor(address _destination,uint256 _amount) external;
    function rescue51PercentAttack(address _tokenHolder) external;
    function rescueBrokenDataReporting() external;
    function rescueFailedUpdate() external;

    //Tellor 360
    function addStakingRewards(uint256 _amount) external;
}