/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity ^0.8.0;

contract QuickStart {
    enum Status { Started, Completed }
    //enum claimStatus {Claimed, Unclaimed};
    event Launch(uint id, address indexed creator, uint goal, uint startAt, uint endAt);
    event Cancel(uint id);
    event Pledge(uint id, address indexed caller, uint amount);
    event Unpledge(uint id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address caller, uint amount);

    struct Campaign {
        address creator; 
        string name;
        uint goal; 
        uint deposit; 
        uint pledged; 
        uint startAt; 
        uint endAt; 
        Status status; 
        bool claimed;
    }

    uint public count;
    uint public immutable MINDEPOSIT;
    uint public immutable MINDIVIDEND;
    uint public immutable MINPLEDGEAMT;
    uint public immutable MINDURATION;
    mapping(uint => Campaign) public campaigns;
    mapping(address => Campaign) public creators;
    mapping(address => uint) public creatorsDeposit;
    mapping(address => bool) public creatorExists;//used to ensure creator can only have one launch at a time
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(uint _minDeposit, uint _minDividend, uint _minPledgeAmt , uint _minDuration) {
        MINDEPOSIT = _minDeposit;
        MINDIVIDEND = _minDividend;
        MINPLEDGEAMT = _minPledgeAmt;
        MINDURATION= _minDuration;
    }
    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function launch( string memory _name,  uint _goal, uint _startAt, uint _endAt) external payable {
        require(!creatorExists[msg.sender], "One can only have one active campaign at a time");
        require(_startAt >= block.timestamp, "Starting time must be later than the current time");
        require(_endAt >= _startAt, "Ending time must be later than the starting time");
        require(_endAt <= _startAt + 180 days, "Ending time is later than the max duration");
        require(msg.value >= MINDEPOSIT, "Insufficient deposit");
        require( _endAt - _startAt >= MINDURATION, "Campaign has to last at least x amount of time");
        
        count ++;
        campaigns[count-1] = Campaign({  
            creator: msg.sender,
            name: _name,
            goal: _goal,
            deposit: msg.value,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            status: Status.Started,
            claimed: false
        });
        creators[msg.sender] = Campaign({
            name: _name,
            creator: msg.sender,
            goal: _goal,
            deposit: msg.value,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            status: Status.Started,
            claimed: false
        });

        creatorExists[msg.sender] = true;

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
        creatorsDeposit[msg.sender] = msg.value;
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp < campaign.startAt, "This crowdfund has started");
        require(msg.sender == campaign.creator, "Function only accessible to creator");

        delete campaigns[_id];
        creators[msg.sender].status = Status.Completed;
        creatorExists[msg.sender] = false;
        uint _toReturn = creatorsDeposit[msg.sender] * 97/100;
        creatorsDeposit[msg.sender] = 0;
        (bool sent,) = address(this).call{value: _toReturn}("");
        if (sent == false) {
            creatorsDeposit[msg.sender] = _toReturn;
        }
        emit Cancel(_id);
    }

    function pledge(uint _id) external payable {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Crowdfund has not started");
        require(block.timestamp <= campaign.endAt, "Crowdfund has ended");
        require(msg.value >= MINPLEDGEAMT, "Too little pledge");

        campaign.pledged += msg.value;
        pledgedAmount[_id][msg.sender] += msg.value;
        emit Pledge(_id, msg.sender, msg.value);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "The crowdfund has ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        (bool sent,) = address(this).call{value: _amount * 97 / 100}("");
        if (sent == false) {
            pledgedAmount[_id][msg.sender] += _amount* 97 / 100;
        }
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Function accessible to creator only");
        require(block.timestamp >= campaign.endAt, "Crowdfund is still yet to end");
        require(campaign.pledged >= campaign.goal, "Total pledge has not reached the goal");
        require(!campaign.claimed, "Crowdfund has been claimed already");

        campaign.claimed = true;
        address(this).call{value: campaign.pledged};
        emit Claim(_id);
        creatorExists[msg.sender] = false;
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        creatorExists[campaign.creator] = false;
        require(block.timestamp >= campaign.endAt, "Crowdfund has not ended");
        require(campaign.pledged < campaign.goal, "Total pledge has reached the goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        address(this).call{value: bal};
        emit Refund(_id, msg.sender, bal);
    }
}