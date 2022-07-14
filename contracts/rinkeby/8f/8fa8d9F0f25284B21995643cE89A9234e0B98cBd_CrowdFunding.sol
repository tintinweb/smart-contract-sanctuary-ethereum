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

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
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
        newAsker.deadline = _deadline * 24 * 60 * 60 + block.timestamp;
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
        manager = 0x3D634232a5663ca5a5927b25Da2fBC0c07450cA3;
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

    function makePayment(uint _index) public {
        require(
            block.timestamp > askers[_index].deadline,
            "Abhi time baki hai! Ruko thoda! "
        );
        if (raisedAmount[_index] >= askers[_index].target) {
            askers[_index].recipient.transfer(raisedAmount[_index]);
        } else {
            if (askers[_index].acceptIfLessThanTarget) {
                askers[_index].recipient.transfer(raisedAmount[_index]);
            } else {
                refund(_index);
            }
        }
    }
}