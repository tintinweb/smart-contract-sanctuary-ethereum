/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// define the solidity version
pragma solidity >=0.4.22 <0.6.0;

//create our contract
contract CrowdFunding {
    //set the beneficiary of the contract, this will be the company running the project
    address payable public beneficiary;

    //milestone 0 means the project has failed
    //milestone 1 is the backer phase
    //milestone >=2 is a payout phase
    uint public milestone = 1;
    uint public milestoneAmount;

    //keep track of who voted for which milestone
    mapping(address => uint) voteMilestone;
    mapping(uint => uint) public votesPerMilestone;

    //keep track of money
    mapping(address => uint) moneyPutIn;
    uint public totalMoney;
    mapping(uint => uint) public payoutPercentage;
    uint payedOutPercentage = 0;

    //set the time of the end of the backing phase
    uint public backingEndTime;

    //set the minimum value of the backing
    uint public backingValue;

    //set minimum total backing
    uint public totalBackingRequired;

    //the contructor:
    constructor(
        uint _backingTime, 
        address payable _beneficiary,
        uint _backingValue, //in wei
        uint _milestoneAmount,
        uint _totalBackingRequired
    ) public {
        //set the global variables accordingly
        beneficiary = _beneficiary;
        backingEndTime = now + _backingTime;
        backingValue = _backingValue;
        milestoneAmount = _milestoneAmount;
        totalBackingRequired = _totalBackingRequired;
    }

    //setup the payoutPercentage variable correctly
    function setPayoutPercentage(uint milestoneNum, uint percentage) external {
        require(msg.sender == beneficiary, "This function is used to define the contract, only the owner can run it.");
        require(percentage <= 100, "Percentage can never be set higher then 100.");
        require(payoutPercentage[milestoneNum] == 0, "Can not overwrite a milestone percentage.");
        require(milestoneNum != 0 && milestoneNum != 1, "The payout for failing and backing phase must be 0.");
        require(milestone == 1, "Must be defined in backing phase.");
        payoutPercentage[milestoneNum] = percentage;
    }

    //the function called to back the project
    function back() public payable {
        require(
            now <= backingEndTime,
            "Backing phase has already ended."
        );
        
        require(
            (msg.value + moneyPutIn[msg.sender]) == backingValue,
            "A specified value must put in."
        );

        require(
            milestone == 1,
            "Backing phase has already ended."
        );

        //keep track of money
        moneyPutIn[msg.sender] += msg.value;
        totalMoney += msg.value;

        //put votes on milestone 1 (backing phase), this will be ignored when counting votes
        votesPerMilestone[1] += msg.value;
    }

    //function to withdraw money if project failes
    function withdraw() public returns (bool) {
        require(
            milestone == 0,
            "Your funds are tied up backing the project."
        );

        require(
            payedOutPercentage < 100,
            "All your funds were already payed out."
        );

        uint amount = moneyPutIn[msg.sender];
        if (amount > 0) {
            moneyPutIn[msg.sender] = 0; //prevent re-entrancy attack

            if (!msg.sender.send(amount * payedOutPercentage / 100)) {
                moneyPutIn[msg.sender] = amount;
                return false;
            }
        }
        return true;

        //voting is not important as it is disabled when the project fails
    }

    function backingPhaseEnd() public {
        //check if the backing phase should end, if so, end it
        require(now >= backingEndTime, "Backing phase not yet ended.");
        require(milestone > 0, "This project has already failed.");
        require(milestone == 1, "Backing phase has already ended.");

        if(address(this).balance >= totalBackingRequired){
            milestone = 2;
        }else{
            milestone = 0; //refund backers, it failed
        }
    }
    
    
    function voteOnMilestone(uint milestoneVoted) public {
        //each backer can vote on the milestone they think is reached, the milestone with the majority vote will be payed out, 
        //it is not possible to go back to a previous milestone, voting power is based on amount money at stake
        require(milestoneVoted != 1, "Cannot go back to backing phase.");
        require(milestone != 0, "Project already failed.");
        require(milestone != 1, "In backing phase.");
        require((milestoneVoted > milestone) || (milestoneVoted == 0), "Cannot go back to previous milestones.");
        
        votesPerMilestone[milestoneVoted] += moneyPutIn[msg.sender];
        votesPerMilestone[voteMilestone[msg.sender]] -= moneyPutIn[msg.sender];
        voteMilestone[msg.sender] = milestoneVoted;
    }

    function recountMilestone() public {
        //update the current milestone depending on the votes of backers, votes that are against voting rules are ignored
        require(milestone != 1, "In backing phase.");
        require(milestone != 0, "Project already failed.");
        uint maxVotesI;
        uint maxVotesNum;
        for(uint i = 0; i < milestoneAmount; i++){
            uint votes = votesPerMilestone[i];
            if((payoutPercentage[i] >= payoutPercentage[milestone]) && (i != 1) && ((i > milestone) || (i == 0))){
                if(votes > maxVotesNum){
                    maxVotesI = i;
                    maxVotesNum = votes;
                }
            }
        }
        milestone = maxVotesI;
    }
    
    function payOutBeneficiary() public returns (bool) {
        //pay out beneficiary according to the amount that should be payed out at the current milestone
        uint moneyToBePayedOut = address(this).balance - (1 - payoutPercentage[milestone]/100) * totalMoney;
        uint payedOutPercentageBefore = payedOutPercentage; //prevent re-entrancy attack
        payedOutPercentage = payoutPercentage[milestone];
        if(!beneficiary.send(moneyToBePayedOut)){
            payedOutPercentage = payedOutPercentageBefore;
            return true;
        }
        return false;
    }
}