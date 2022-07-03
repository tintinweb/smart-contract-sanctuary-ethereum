// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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



contract Investable is Ownable, ReentrancyGuard  {
    using SafeMath for uint256;

    bool isPaused;

    string constant public TERMS = "We will never contact you first"

"Given the proliferation of fake accounts usurping project and their members identities in order to"
"defraud you, we will never contact you by private message first."

"We cannot be held responsible for any correspondence you have with any of our potential usurpers."

"Be sure to identify team members with their respective badges before contacting them."
"We are not financial advisers"

"Your decision to invest and its results are entirely your responsibility, we cannot be held responsible"
"for any loss."
"The Road Map is likely to evolve"

"The roadmap brings together most of our ideas, plans and strategies but these are likely to change"
"as the project progresses. All modifications and changes will be announced in advance, so our"
"investors will not be surprised.";

    mapping(address => bool) public userAgreed;

    address busdAddress;
    address alfAddress;
    
    uint public totalBusdLocked;
    uint public totalAlfLocked;
    uint public totalActiveInvestments;
    uint256 public activeInvestor;

    uint refundPerTenThousand = 7_000; //70%
    uint burnPerTenThousand = 1_000; //10%

    struct InvestPlan {
        string name;
        string desc;
        uint256 alfToLock;
        uint256 minimumBusdToInvest;
        uint256 maximumBusdToInvest;
    }

    struct Duration {
        string name;
        uint256 apyPerTenThousand;
        uint256 duration;
    }

    mapping(address => bool) public influencerReferral;

    uint public referralPercentagePerTenThousand = 200; //2.00%
    
    struct Referral {
        address reffered;
        uint busdAmount;
        Status status;


    }

    enum Status {
        INPROGRESS,
        COLLECTED,
        REFUNDED
    }

    struct Refferant{
        address refferant;
        Referral[] referrals;
        uint totalBusdRewardSended;
        uint totalBusdRewardPending;

    }

    struct Investor{
        address investor;
        Investment[] investments;
        uint referralPosition;
        address refferant;
        uint activeInvestment;
        
    }

    Refferant[] internal refferants;
    Investor[] internal investors;

    struct Investment {
        InvestPlan investPlan;
        Duration duration;
        uint busdInvested;
        uint since;
        bool refundAsked;
        Status status;
    }

    mapping(address => uint256) internal investments;
    mapping(address => uint256) internal referrals;

    uint public refundThreshold = 1;

    InvestPlan[] public investPlans;
    Duration[] public durations;

    event RefundAsking(address indexed investor, uint investmentIndex, uint busdToSend, string email);
    event NewInvestment(address indexed investor, uint investmentIndex, uint busdInvested, uint apy, uint referralAmount, uint end);
    event EndInvestment(address indexed investor, uint investmentIndex);
    event RefundInvestment(address indexed investor, uint investmentIndex);


    constructor(address alf, address busd) {
        
        activeInvestor = 0;

        alfAddress = alf;
        busdAddress = busd;

        isPaused = false;

        totalBusdLocked = 0;
        totalAlfLocked = 0;
        totalActiveInvestments = 0;

        durations.push(
            Duration({
                name: "1 month",
                duration: 1 ,
                apyPerTenThousand: 1000 // 10%
            })
        );
        durations.push(
            Duration({
                name: "3 month",
                duration: 1 minutes,
                apyPerTenThousand: 3300 // 33%
            })
        );
        durations.push(
            Duration({
                name: "6 month",
                duration: 1 days,
                apyPerTenThousand: 7700 // 77%
            })
        );
        durations.push(
            Duration({
                name: "1 year",
                duration: 4 minutes,
                apyPerTenThousand: 31_300 // 313%
            })
        );
        investPlans.push(
            InvestPlan({
                name: "Fox Vault 1",
                desc: "A desc",
                alfToLock: 100 * 10 ** ERC20(busdAddress).decimals(), // TODO à définir
                minimumBusdToInvest: 100 * 10 ** ERC20(busdAddress).decimals(),
                maximumBusdToInvest: 500 * 10 ** ERC20(busdAddress).decimals()
        }));

        investPlans.push(
            InvestPlan({
                name: "Fox Vault 2",
                desc: "A desc",
                alfToLock: 500 * 10 ** ERC20(alfAddress).decimals(), // TODO à définir
                minimumBusdToInvest: 500 * 10 ** ERC20(busdAddress).decimals(), // TODO à définir
                maximumBusdToInvest: 1000 * 10 ** ERC20(busdAddress).decimals()
        }));

        investPlans.push(
            InvestPlan({
                name: "Fox Vault 3",
                desc: "A desc",
                alfToLock: 1000 * 10 ** ERC20(alfAddress).decimals(), // TODO à définir
                minimumBusdToInvest: 1000 * 10 ** ERC20(busdAddress).decimals(), // TODO à définir
                maximumBusdToInvest: 5000 * 10 ** ERC20(busdAddress).decimals()
        }));

        investPlans.push(
            InvestPlan({
                name: "Fox Vault 4",
                desc: "A desc",
                alfToLock: 5000 * 10 ** ERC20(alfAddress).decimals(), // TODO à définir
                minimumBusdToInvest: 5000 * 10 ** ERC20(busdAddress).decimals(), // TODO à définir
                maximumBusdToInvest: 10000 * 10 ** ERC20(busdAddress).decimals()
        }));
        
    }

    

    function setRefundThreshold(uint _seconds) external onlyOwner {
        require(refundThreshold != _seconds, "refund threshold already has this value !");
        refundThreshold = _seconds;
    }

    function setInflencerReferral(address _address, bool _isInfluencerReferral) external onlyOwner {
        require( influencerReferral[_address] != _isInfluencerReferral, "This address already has this value !");
        require (investments[_address]==0, "Influencer mustn't be an investor");
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


    function _addInvestor(address _investor, address _refferant) internal returns(uint) {
        // Push a empty item to the Array to make space for our new stakeholder
        investors.push();

        uint256 investorPosition = investors.length;
        
        investors[investorPosition - 1].investor = _investor;
        investors[investorPosition - 1].refferant = _refferant;
        investors[investorPosition - 1].activeInvestment = 0;
        // Add position to the stakeHolders
        investments[_investor] = investorPosition;
        return investorPosition;
    }

    function _addRefferant(address _refferant) internal returns(uint) {
        // Push a empty item to the Array to make space for our new stakeholder
       
        refferants.push();

        
        
        uint256 refferantPosition = refferants.length;
        
        refferants[refferantPosition - 1].refferant = _refferant;
        refferants[refferantPosition - 1].totalBusdRewardPending = 0;
        refferants[refferantPosition - 1].totalBusdRewardSended = 0;
        
        // Add position to the stakeHolders
        referrals[_refferant] = refferantPosition;
        return refferantPosition;
    }

    function canReffer(address _address) public view returns(bool) {
        if(influencerReferral[_address]) return true;
        uint256 position = investments[_address];
        if(position == 0) return false;
        else if(investors[position - 1].activeInvestment > 0) return true;
        else return false;
    }

    function invest(uint256 _busdAmount, uint _investPlan, uint _duration, address _refferant) external {
        require(!isPaused, "New investments are paused !");
        require(userAgreed[msg.sender], "User doesn't agreed terms !");
        require(_investPlan < investPlans.length, "Invest plan does not exist !");
        require(_duration < durations.length, "Duration does not exist !");
        require(!influencerReferral[msg.sender], "You'r an influencer, you need to create another wallet to invest !");
        InvestPlan memory chosenInvestPlan = investPlans[_investPlan]; 
        Duration memory chosenDuration = durations[_duration];
               
        require(_busdAmount >= chosenInvestPlan.minimumBusdToInvest, "Cannot invest less than minimum amount required by chosen invest plan");
        require(_busdAmount < chosenInvestPlan.maximumBusdToInvest, "Cannot invest more than maximum amount permitted by chosen invest plan");
        
        require(ERC20(alfAddress).balanceOf(msg.sender) >= chosenInvestPlan.alfToLock, "Not enough ALF to lock !");
        require(ERC20(busdAddress).balanceOf(msg.sender) >= _busdAmount, "Not enough Busd to invest !");

        require(ERC20(alfAddress).allowance(msg.sender, address(this)) >= chosenInvestPlan.alfToLock, "Not allowed to withdraw this amount of alf!");
        require(ERC20(busdAddress).allowance(msg.sender, address(this)) >= _busdAmount, "Not allowed to withdraw this amount of busd!");


        uint256 investorPosition = investments[msg.sender];
    
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(investorPosition == 0){
            if(_refferant != address(0)){
            
                require(canReffer(_refferant), "Referral address is not valid !");
            }
           
            investorPosition = _addInvestor(msg.sender, _refferant);
            uint256 investorRefferantPosition = referrals[msg.sender];
            if(investorRefferantPosition == 0){
                _addRefferant(msg.sender);
            }
            
        }

        

        

        ERC20(busdAddress).transferFrom(msg.sender, address(this), _busdAmount);
        ERC20(alfAddress).transferFrom(msg.sender, address(this), chosenInvestPlan.alfToLock); // TODO TestFail / A exclure des fees
        

        
        uint referralBusdAmount = 0;
        
        if(_refferant != address(0) && investors[investorPosition - 1].investments.length == 0){
            
            require(canReffer(_refferant), "Referral address is not valid !");
            
            uint refferantPosition = referrals[_refferant];
            refferants[refferantPosition - 1].referrals.push();
            uint referralPosition = refferants[refferantPosition - 1].referrals.length;
            referralBusdAmount = _busdAmount.mul(referralPercentagePerTenThousand).div(10_000);
            refferants[refferantPosition - 1].referrals[referralPosition - 1].reffered = msg.sender;
            refferants[refferantPosition - 1].referrals[referralPosition - 1].busdAmount = referralBusdAmount;
            refferants[refferantPosition - 1].referrals[referralPosition - 1].status = Status.INPROGRESS;

            investors[investorPosition - 1].refferant = _refferant;
            investors[investorPosition - 1].referralPosition = referralPosition;
            refferants[refferantPosition-1].totalBusdRewardPending += referralBusdAmount;

        }
        
        // Use the position to push a new investment
        // push a newly created investment with the current block timestamp.
        investors[investorPosition - 1].investments.push(Investment({
            investPlan: chosenInvestPlan,
            duration: chosenDuration,
            busdInvested: _busdAmount,
            since: timestamp,
            refundAsked: false,
            status: Status.INPROGRESS
        }));
        

        

        
        
        if(investors[investorPosition - 1].activeInvestment == 0){
            activeInvestor += 1;
        }
        investors[investorPosition - 1].activeInvestment += 1;

        totalActiveInvestments += 1;
        totalBusdLocked += _busdAmount;
        totalAlfLocked += chosenInvestPlan.alfToLock;

        emit NewInvestment(msg.sender, investors[investorPosition - 1].investments.length - 1, _busdAmount, chosenDuration.apyPerTenThousand, referralBusdAmount, timestamp + chosenDuration.duration);

    }

    

    function claim(uint _investmentIndex) external nonReentrant {
        uint investorPosition = investments[msg.sender];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");
        
        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        InvestPlan storage investPlan = investment.investPlan;

        Duration storage duration = investment.duration;

        uint currentTimeStamp = block.timestamp;

        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded");
        require(currentTimeStamp >= investment.since + duration.duration, "Investment not ended");

        uint busdToSend = investment.busdInvested.add(investment.busdInvested.mul(duration.apyPerTenThousand).div(10_000)); // a diviser par 1000

        uint alfToBurn = investPlan.alfToLock.mul(burnPerTenThousand).div(10_000);
        uint alfToSend = investPlan.alfToLock.sub(alfToBurn);
        
        uint referralBusdAmount = 0;
        if(investors[investorPosition - 1].refferant != address(0) && _investmentIndex == 0){
            uint refferantPosition = referrals[investors[investorPosition - 1].refferant];
            uint referralPosition = investors[investorPosition - 1].referralPosition;
            Referral storage referral = refferants[refferantPosition-1].referrals[referralPosition - 1];
            referralBusdAmount = referral.busdAmount;

            referral.status = Status.COLLECTED;

            refferants[refferantPosition-1].totalBusdRewardSended += referralBusdAmount;
            refferants[refferantPosition-1].totalBusdRewardPending -= referralBusdAmount;
        }
        require(ERC20(busdAddress).balanceOf(address(this)) >= busdToSend + referralBusdAmount, "Not enough busd on contract, please contact admin");
        require(ERC20(alfAddress).balanceOf(address(this)) >= investPlan.alfToLock, "Not enough alf on contract, please contact admin");


        ERC20(busdAddress).transfer(msg.sender, busdToSend);
        ERC20(alfAddress).transfer(msg.sender, alfToSend); 
        ERC20Burnable(alfAddress).burn(alfToBurn); 
        if(referralBusdAmount > 0){
            ERC20(busdAddress).transfer(investors[investorPosition - 1].refferant, referralBusdAmount);
        }
        
        

        investment.status = Status.COLLECTED;
        //remove investment
        //for (uint i = _investmentIndex; i<investors[position - 1].investments.length-1; i++){
        //    investors[position - 1].investments[i] = investors[position - 1].investments[i+1];
        //}
        //investors[position - 1].investments.pop();    
        investors[investorPosition - 1].activeInvestment -= 1;

        
        if(investors[investorPosition - 1].activeInvestment == 0){
            activeInvestor -= 1;
        }

        totalActiveInvestments -= 1;
        totalBusdLocked -= investment.busdInvested;
        totalAlfLocked -= investPlan.alfToLock;

        emit EndInvestment(msg.sender, _investmentIndex);
       
    }

    function isInvestorActive(uint256 _investorIndex) internal view returns(bool){

        if(investors[_investorIndex].activeInvestment > 0) return true;
        else return false;
        
    }

    function withdraw(uint amount) external onlyOwner { //OnlyOwner
        require(ERC20(busdAddress).balanceOf(address(this)) >= amount, "Not enough busd on the smart contract");
        ERC20(busdAddress).transfer(msg.sender, amount);

    }

    function deposit(uint amount) external onlyOwner { //OnlyOwner
        uint walletBalance = ERC20(busdAddress).balanceOf(msg.sender);
        require(walletBalance >= amount, "Not enough busd on the wallet");
        require(ERC20(busdAddress).allowance(msg.sender, address(this)) >= amount, "Not allowed to withdraw this amount of busd from wallet!");

        ERC20(busdAddress).transferFrom(msg.sender, address(this), amount);

    }

    function askRefund(uint _investmentIndex, string calldata email) external {
        uint investorPosition = investments[msg.sender];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");

        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded !");
        require(block.timestamp - investment.since >= refundThreshold, "This investment cannot be refunded yet !");

        investment.refundAsked = true;

        emit RefundAsking(msg.sender, _investmentIndex, investment.busdInvested.mul(refundPerTenThousand).div(10_000), email);


    }

    function refund(address _investor, uint _investmentIndex) external onlyOwner{ // onlyOwner


        uint investorPosition = investments[_investor];
        require(investorPosition > 0, "This address don't have any investments");
        require(investors[investorPosition - 1].investments.length - 1 >= _investmentIndex, "Specified investment don't exist for this address");
        
        Investment storage investment = investors[investorPosition - 1].investments[_investmentIndex];

        InvestPlan storage investPlan = investment.investPlan;

        Duration storage duration = investment.duration;

        uint currentTimeStamp = block.timestamp;
        require(investment.status == Status.INPROGRESS, "Investment already claimed or refunded !");
        require(investment.refundAsked, "Investor dosen't ask refund for this investment");
        require(currentTimeStamp < investment.since + duration.duration, "Investment has ended. You must claim");

        uint busdToSend = investment.busdInvested.mul(refundPerTenThousand).div(10_000); 

        uint alfToBurn = investPlan.alfToLock.mul(burnPerTenThousand).div(10_000);
        uint alfToSend = investPlan.alfToLock.sub(alfToBurn);
        

        if(investors[investorPosition - 1].refferant != address(0) && _investmentIndex == 0){
            uint refferantPosition = referrals[investors[investorPosition - 1].refferant];
            uint referralPosition = investors[investorPosition - 1].referralPosition;
            Referral storage referral = refferants[refferantPosition-1].referrals[referralPosition - 1];
            uint referralBusdAmount = referral.busdAmount;

            referral.status = Status.REFUNDED;

            
            refferants[refferantPosition-1].totalBusdRewardPending -= referralBusdAmount;
        }

        require(ERC20(busdAddress).balanceOf(address(this)) >= busdToSend, "Not enough busd on contract, please contact admin");
        require(ERC20(alfAddress).balanceOf(address(this)) >= investPlan.alfToLock, "Not enough alf on contract, please contact admin");


        ERC20(busdAddress).transfer(_investor, busdToSend);
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
        totalBusdLocked -= investment.busdInvested;
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
        uint _minimumBusdToInvest,
        uint _maximumBusdToInvest
    ) external onlyOwner {
        require(investPlans.length - 1 >= _investPlanIndex, "Specified investPlan doesn't exist");
        require(_minimumBusdToInvest < _maximumBusdToInvest, "Maximum amount of busd to invest must be greater than minimum amount of busd to invest");

        InvestPlan storage investPlan = investPlans[_investPlanIndex];

        investPlan.name = _name;
        investPlan.desc = _desc;
        investPlan.alfToLock = _alfToLock;
        investPlan.minimumBusdToInvest = _minimumBusdToInvest;
        investPlan.maximumBusdToInvest = _maximumBusdToInvest;
    }

    function addInvestPlan(
        string calldata _name,
        string calldata _desc,
        uint _alfToLock,
        uint _minimumBusdToInvest,
        uint _maximumBusdToInvest
    ) external onlyOwner {
        investPlans.push(
            InvestPlan({
                name: _name,
                desc: _desc,
                alfToLock: _alfToLock, // TODO à définir
                minimumBusdToInvest: _minimumBusdToInvest, // TODO à définir
                maximumBusdToInvest: _maximumBusdToInvest
        }));
    }

    function removeDuration(uint _durationIndex) external onlyOwner {
        require(durations.length - 1 >= _durationIndex, "Specified duration doesn't exist");
        for (uint i = _durationIndex; i<durations.length-1; i++){
            durations[i] = durations[i+1];
        }
        durations.pop();
    }

    function updateDuration(
        uint _durationIndex,
        string calldata _name,
        uint _duration, 
        uint _apyPerTenThousand 
    ) external onlyOwner {
        require(durations.length - 1 >= _durationIndex, "Specified duration doesn't exist");

        Duration storage duration = durations[_durationIndex];

        duration.name = _name;
        duration.duration = _duration;
        duration.apyPerTenThousand = _apyPerTenThousand;

    }


    function addDuration(
        string calldata _name,
        uint _duration, // in seconds
        uint _apyPerTenThousand 
    ) external onlyOwner {
        durations.push(
            Duration({
                name: _name,
                duration: _duration,
                apyPerTenThousand: _apyPerTenThousand 
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

    function getReferrals(address _refferant) external view returns (Referral[] memory) {
        uint position = referrals[_refferant];
        require(position > 0, "This address is not a refferant");
        
        Referral[] memory refferantReferrals = refferants[position - 1].referrals;
        return refferantReferrals;

    }

    function getReferrantInfo(address _refferant) external view returns (Refferant memory) {
        uint position = referrals[_refferant];
        require(position > 0, "This address is not a refferant");
        
        Refferant memory refferant = refferants[position - 1];
        return refferant;

    }

    function hasInvestments(address _investor) external view returns (bool) {
        uint position = investments[_investor];
        if(position == 0) return false;
        else if(investors[position - 1].investments.length == 0) return false;
        else return true;

    }
    
    function hasReferrals(address _refferant) external view returns (bool) {
        uint position = referrals[_refferant];
        if(position == 0) return false;
        else if(refferants[position - 1].referrals.length == 0) return false;
        else return true;

    }

    function getInvestPlans() external view returns(InvestPlan[] memory){
        return investPlans;
    }

    function getDurations() external view returns(Duration[] memory){
        return durations;
    }


    struct InvestmentSummary {
        uint busdLocked;
        uint alfLocked;
        uint investmentsAmount;
        uint investorsAmount;
    }

    function getInvestmentSummary() external view returns(InvestmentSummary memory) {
        InvestmentSummary memory summary = InvestmentSummary({
            busdLocked: totalBusdLocked,
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