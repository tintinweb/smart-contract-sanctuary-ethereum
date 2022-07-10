//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    address public manager;
    uint256 public minimumContribution;
    mapping(uint256 => uint256) public raisedAmount;
    mapping(uint256 => uint256) public noOfContributors;
    mapping(uint256 => mapping(address => uint256))
        public askerIdxToContributorToAmount;
    // mapping(uint256=>uint256) public askerToProfitAmount;
    mapping(uint256 => uint256) public askerToAmountSent;
    mapping(uint256 => uint256) public askerToAmountReceived;
    address public dummyAccount;
    uint256 public profitAmount;
    uint256 public amountFunded;
    uint256 public factorProfit;
    uint256 public profitToSend;
    uint256 public totalProfitSent;
    uint256 public profitToAsker;
    address _dummyAccount = 0x06Cc8EBc6Ba95d1Fcf1DE8a4Dc00b26177b1D665;

    function sendToSomeone(uint256 _index) public payable onlyAsker(_index) {
        askerToAmountSent[_index] = msg.value;
    }

    function receiveFromSomeone(uint256 _index) public payable {
        require(
            msg.sender == dummyAccount,
            "You are not allowed to send money!"
        );
        askerToAmountReceived[_index] = msg.value;
    }

    function sendProfitToContributor() public payable onlyManager {
        for (uint256 j = 0; j < noOfAskers; j++) {
            profitAmount = askerToAmountReceived[j] - askerToAmountSent[j];
            // askerToProfitAmount[_index]=profitAmount;
            if (profitAmount > 0) {
                for (
                    uint256 i = 0;
                    i < askers[j].contributorsAddress.length;
                    i++
                ) {
                    amountFunded = askerIdxToContributorToAmount[j][
                        askers[j].contributorsAddress[i]
                    ];
                    factorProfit = (amountFunded * 1e10) / raisedAmount[j];
                    profitToSend =
                        (factorProfit * askers[j].percent * profitAmount) /
                        (100 * 1e10);
                    payable(askers[j].contributorsAddress[i]).transfer(
                        profitToSend
                    );
                    totalProfitSent += profitToSend;
                }
                profitToAsker = profitAmount - totalProfitSent;
                (askers[j].recipient).transfer(profitToAsker);
            }
        }
    }

    modifier onlyAsker(uint256 _index) {
        require(
            msg.sender == askers[_index].recipient,
            "Only asker can call this function"
        );
        _;
    }
    struct Request {
        address payable recipientNew;
        uint256 value;
        uint256 totalRaisedAmount;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Request) public requests;

    struct Asker {
        string description;
        address payable recipient;
        uint256 target;
        uint256 deadline;
        bool acceptIfLessThanTarget;
        address[] contributorsAddress;
        uint256 percent;
    }
    mapping(uint256 => Asker) public askers;
    Asker[] public arrayOfAsker;
    uint256 public noOfAskers;

    function createFundRequest(
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        uint256 _percent,
        bool _acceptIfLessThanTarget
    ) public {
        Asker storage newAsker = askers[noOfAskers];
        noOfAskers++;
        newAsker.description = _description;
        newAsker.recipient = payable(msg.sender);
        newAsker.target = _target;
        newAsker.percent = _percent;
        newAsker.deadline = _deadline + block.timestamp;
        newAsker.acceptIfLessThanTarget = _acceptIfLessThanTarget;
        newAsker.contributorsAddress = new address[](0);
        // fundRequests.push(newAsker);
        arrayOfAsker.push(newAsker);
    }

    function getFundRequest() public view returns (Asker[] memory) {
        return arrayOfAsker;
    }

    constructor() {
        minimumContribution = 100;
        manager = msg.sender;
        dummyAccount = payable(_dummyAccount);
    }

    function sendEth(uint256 _index) public payable {
        require(_index <= noOfAskers, "No requests created!");
        require(
            block.timestamp < askers[_index].deadline,
            "Deadline has passed"
        );
        require(
            msg.value >= minimumContribution,
            "Minimum Contribution is not met"
        );

        (askers[_index].contributorsAddress).push(msg.sender);
        mapping(address => uint256)
            storage contributorToAmount = askerIdxToContributorToAmount[_index];
        if (contributorToAmount[msg.sender] == 0) {
            noOfContributors[_index]++;
        }
        contributorToAmount[msg.sender] += msg.value;
        raisedAmount[_index] += msg.value;
    }

    function getContributors(uint256 _index)
        public
        view
        returns (address[] memory)
    {
        return (askers[_index]).contributorsAddress;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund(uint256 _index) public {
        mapping(address => uint256)
            storage temp = askerIdxToContributorToAmount[_index];
        address[] memory contributorsList = getContributors(_index);
        for (uint256 i = 0; i < contributorsList.length; i++) {
            if (temp[contributorsList[i]] > 0) {
                address payable user = payable(contributorsList[i]);
                user.transfer(temp[contributorsList[i]]);
                temp[contributorsList[i]] = 0;
            }
        }
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
    uint256 numRequests;
    mapping(uint256 => bool) indexToCheck;
    mapping(uint256 => uint256) indexToNumRequests;

    function createRequests(uint256 _index) public onlyManager {
        // require(block.timestamp >= askers[_index].deadline,"Time left!!");
        require(!indexToCheck[_index], "Already created a request!");
        indexToNumRequests[_index] = numRequests;
        Request storage newRequest = requests[numRequests];
        numRequests++;
        indexToCheck[_index] = true;
        newRequest.recipientNew = askers[_index].recipient;
        newRequest.totalRaisedAmount = raisedAmount[_index];
        newRequest.value = askers[_index].target;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _index) public {
        mapping(address => uint256)
            storage temp = askerIdxToContributorToAmount[_index];
        require(temp[msg.sender] > 0, "You must be contributor");
        Request storage thisRequest = requests[indexToNumRequests[_index]];
        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _index) public onlyManager {
        Request storage thisRequest = requests[indexToNumRequests[_index]];
        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            block.timestamp > askers[_index].deadline,
            "Abhi time baki hai! Ruko thoda! "
        );
        if (raisedAmount[_index] >= askers[_index].target) {
            thisRequest.recipientNew.transfer(thisRequest.totalRaisedAmount);
            thisRequest.completed = true;
        } else {
            if (askers[_index].acceptIfLessThanTarget) {
                if (thisRequest.noOfVoters > noOfContributors[_index] / 2) {
                    thisRequest.recipientNew.transfer(
                        thisRequest.totalRaisedAmount
                    );
                    thisRequest.completed = true;
                } else {
                    refund(_index);
                    thisRequest.completed = true;
                }
            } else {
                refund(_index);
                thisRequest.completed = true;
            }
        }
    }
}