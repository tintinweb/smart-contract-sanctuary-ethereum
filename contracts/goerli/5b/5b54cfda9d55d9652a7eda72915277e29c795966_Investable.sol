// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

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

interface ALFApproval {
    function getLastInvestApproval(address investor) external view returns(uint, uint, uint);
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

    string constant public TERMS = "We will never contact you first "



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


    constructor(address alf, address usdt) {
        
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
        investPlans[0].alfToLock = 2_500; // TODO à définir
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
        investPlans[1].alfToLock = 2_000; // TODO à définir
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
        investPlans[2].alfToLock = 1_500; // TODO à définir
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
        investPlans[3].alfToLock = 1_000; // TODO à définir
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
        investPlans[4].alfToLock = 500; // TODO à définir
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

    function getAlfToLock(address investor, uint percentage, uint amount) internal view returns(uint256) {
         //getAlfToLockAmount
        (
            uint timestampApproval,
            uint priceApproval,
            uint decimalsApproval
        ) = ALFApproval(alfAddress).getLastInvestApproval(investor);

        require(block.timestamp - timestampApproval <= 1800, "Last invest approval was made more than 30 minutes ago");
        return amount.mul(priceApproval).mul(ERC20(alfAddress).decimals()).div(10**decimalsApproval).mul(percentage).div(10_000);
     
    }

    function invest(uint256 _usdtAmount, uint _investPlan, uint _duration, address _referrant) external {
        require(!isPaused, "New investments are paused !");
        require(userAgreed[msg.sender], "User doesn't agreed terms !");
        require(_investPlan < investPlans.length, "Invest plan does not exist !");
        require(!influencerReferral[msg.sender], "You'r an influencer, you need to create another wallet to invest !");
        InvestPlan memory chosenInvestPlan = investPlans[_investPlan]; 
        require(chosenInvestPlan.durations.length > 0, "Invest plan doesn't have durations");
        Duration memory chosenDuration = chosenInvestPlan.durations[_duration];
               
        require(_usdtAmount >= chosenInvestPlan.minimumUsdtToInvest, "Cannot invest less than minimum amount required by chosen invest plan");
        require(_usdtAmount < chosenInvestPlan.maximumUsdtToInvest && chosenInvestPlan.maximumUsdtToInvest != 0, "Cannot invest more than maximum amount permitted by chosen invest plan");
        
        require(ERC20(alfAddress).balanceOf(msg.sender) >= chosenInvestPlan.alfToLock, "Not enough ALF to lock !");
        require(ERC20(usdtAddress).balanceOf(msg.sender) >= _usdtAmount, "Not enough Usdt to invest !");

        require(ERC20(alfAddress).allowance(msg.sender, address(this)) >= chosenInvestPlan.alfToLock, "Not allowed to withdraw this amount of alf!");
        require(ERC20(usdtAddress).allowance(msg.sender, address(this)) >= _usdtAmount, "Not allowed to withdraw this amount of usdt!");


        uint256 investorPosition = investments[msg.sender];
    
        // block.timestamp = timestamp of the current block in seconds since the epoch
       
        uint alfToLock = getAlfToLock(msg.sender, chosenInvestPlan.alfToLock, _usdtAmount.div(10**ERC20(usdtAddress).decimals()));
       



        // See if the staker already has a staked index or if its the first time
        if(investorPosition == 0){
            if(_referrant != address(0)){
            
                require(canReffer(_referrant), "Referral address is not valid !");
            }
           
            investorPosition = _addInvestor(msg.sender, _referrant);
            if(referrals[msg.sender] == 0){
                _addRefferant(msg.sender);
            }
            
        }

        

        

        ERC20(usdtAddress).transferFrom(msg.sender, address(this), _usdtAmount);
        ERC20(alfAddress).transferFrom(msg.sender, address(this), alfToLock); // TODO TestFail / A exclure des fees
        

        
        uint referralUsdtAmount = 0;
        
        if(_referrant != address(0) && investors[investorPosition - 1].investments.length == 0){
            
            require(canReffer(_referrant), "Referral address is not valid !");
            
            uint referrantPosition = referrals[_referrant];
            referrants[referrantPosition - 1].referrals.push();
            uint referralPosition = referrants[referrantPosition - 1].referrals.length;
            referralUsdtAmount = _usdtAmount.mul(chosenDuration.referralReturnPerTenThousand).div(10_000);
            referrants[referrantPosition - 1].referrals[referralPosition - 1].referred = msg.sender;
            referrants[referrantPosition - 1].referrals[referralPosition - 1].usdtAmount = referralUsdtAmount;
            referrants[referrantPosition - 1].referrals[referralPosition - 1].status = Status.INPROGRESS;

            investors[investorPosition - 1].referrant = _referrant;
            investors[investorPosition - 1].referralPosition = referralPosition;
            referrants[referrantPosition-1].totalUsdtRewardPending += referralUsdtAmount;

        }
        
        // Use the position to push a new investment
        // push a newly created investment with the current block timestamp.

       
        investors[investorPosition - 1].investments.push();
        uint lastInvest = investors[investorPosition - 1].investments.length - 1;

        investors[investorPosition - 1].investments[lastInvest].investPlan.name = chosenInvestPlan.name;
        investors[investorPosition - 1].investments[lastInvest].investPlan.desc = chosenInvestPlan.desc;
        investors[investorPosition - 1].investments[lastInvest].investPlan.alfToLock = chosenInvestPlan.alfToLock;
        investors[investorPosition - 1].investments[lastInvest].investPlan.minimumUsdtToInvest = chosenInvestPlan.minimumUsdtToInvest;
        investors[investorPosition - 1].investments[lastInvest].investPlan.maximumUsdtToInvest = chosenInvestPlan.maximumUsdtToInvest;
    
        for (uint i = 0; i<chosenInvestPlan.durations.length-1; i++){
            investors[investorPosition - 1].investments[lastInvest].investPlan.durations.push();
            investors[investorPosition - 1].investments[lastInvest].investPlan.durations[i] = chosenInvestPlan.durations[i];
        }

        investors[investorPosition - 1].investments[lastInvest].durationIndex = _duration;
        investors[investorPosition - 1].investments[lastInvest].usdtInvested = _usdtAmount;
        investors[investorPosition - 1].investments[lastInvest].since = block.timestamp;
        investors[investorPosition - 1].investments[lastInvest].refundAsked = false;
        investors[investorPosition - 1].investments[lastInvest].status = Status.INPROGRESS;
        

        

        
        
        if(investors[investorPosition - 1].activeInvestment == 0){
            activeInvestor += 1;
        }
        investors[investorPosition - 1].activeInvestment += 1;

        totalActiveInvestments += 1;
        totalUsdtLocked += _usdtAmount;
        totalAlfLocked += chosenInvestPlan.alfToLock;

        emit NewInvestment(msg.sender, investors[investorPosition - 1].investments.length - 1, _usdtAmount, chosenDuration.apyPerTenThousand, referralUsdtAmount, block.timestamp + chosenDuration.duration);

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