/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.14;

contract CrowdFunding {
    uint256 public constant MINIMUM_CONTRIBUTION = 0.01 ether;
    address public immutable i_owner;
    uint256 public goal;
    uint32 public deadline;
    uint256 public numberOfContributors;

    mapping(address => uint256) public contributors;

    // Spending request
    struct Request {
        address payable recipient;
        string description;
        uint256 value;
        bool completed;
        uint256 numberOfApproved;
        mapping(address => bool) approvers;
    }
    Request[] private spendingRequests;

    // Errors
    error DeadlinePassed();
    error DeadlineNotPassed();
    error NotContributor();
    error NotEnoughEth();

    // Events
    event Contribute(address indexed contributor, uint256 value);
    event CreateSpendingRequest(
        address indexed recipient,
        string description,
        uint256 value
    );
    event Refund(address indexed contributor, uint256 value);
    event Approve(uint256 reqestId, address approver);
    event Spend(
        uint256 indexed reqestId,
        address indexed recipient,
        uint256 value
    );

    // Modifiers
    modifier notPassedDeadline() {
        if (block.timestamp > deadline) revert DeadlinePassed();
        _;
    }

    modifier deadlinePassed() {
        if (block.timestamp < deadline) revert DeadlineNotPassed();
        _;
    }

    constructor(uint32 _deadline, uint256 _goal) {
        i_owner = msg.sender;
        deadline = _deadline;
        goal = _goal;
    }

    function contribute() external payable notPassedDeadline {
        // -------- gas use experiment --------
        // Min         ·  Max        ·  Avg
        // 52601  ·      69701  ·      68146
        // Try on Hardhat 69701
        if (msg.value < MINIMUM_CONTRIBUTION)
            revert("You need to spend more ETH to contribute.");

        // 52601  ·      69701  ·      68146
        // Try on Hardhat 69701
        // if (msg.value < MINIMUM_CONTRIBUTION) revert NotEnoughEth();

        // 52601  ·      69701  ·      68146
        /// Try on Hardhat 69701
        // require(msg.value >= MINIMUM_CONTRIBUTION);

        // ------------------------------------
        contributors[msg.sender] += msg.value;
        numberOfContributors += 1;

        emit Contribute(msg.sender, msg.value);
    }

    function getContributeValue(address _address)
        external
        view
        returns (uint256)
    {
        return contributors[_address];
    }

    // TODO deadline?
    // TODO lock fund?
    function createSpendingRequest(
        address payable _recipient,
        string calldata _description,
        uint256 _value
    ) external {
        if (_recipient == address(0)) revert("recipient cannot be address 0");
        if (deadline > block.timestamp)
            revert("the deadline has not reach yet");
        if (goal > address(this).balance) revert("the goal has not reach");
        if (_value > address(this).balance)
            revert("spending request amount is more than campaign balance");

        Request storage newRequest = spendingRequests.push();
        newRequest.recipient = _recipient;
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numberOfApproved = 0;

        emit CreateSpendingRequest(_recipient, _description, _value);
    }

    function getSpendingRequest(uint256 _index)
        external
        view
        returns (
            address recipient,
            string memory description,
            uint256 value,
            bool completed,
            uint256 numberOfApproved
        )
    {
        Request storage request = spendingRequests[_index];
        return (
            request.recipient,
            request.description,
            request.value,
            request.completed,
            request.numberOfApproved
        );
    }

    function getSpendingRequestCount() external view returns (uint256 count) {
        return spendingRequests.length;
    }

    function refund() external payable deadlinePassed {
        if (goal <= address(this).balance) revert("the goal has reached");
        if (contributors[msg.sender] == 0) revert("no contribution");

        uint256 contributionValue = contributors[msg.sender];
        contributors[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: contributionValue}("");
        if (!sent) revert("fail to refund");

        emit Refund(msg.sender, contributionValue);
    }

    function approve(uint256 _id) external {
        if (spendingRequests.length <= _id) revert("no spending request");
        if (contributors[msg.sender] == 0) revert("Only the contributors");

        Request storage request = spendingRequests[_id];
        if (request.approvers[msg.sender])
            revert("You have already approved the request");
        request.approvers[msg.sender] = true;
        request.numberOfApproved += 1;

        emit Approve(_id, msg.sender);
    }

    function isApproved(uint256 _requestId, address _contributor)
        external
        view
        returns (bool)
    {
        return spendingRequests[_requestId].approvers[_contributor];
    }

    function executeRequest(uint256 _requestId) external {
        if (spendingRequests.length <= _requestId)
            revert("the request does not exist");
        if (spendingRequests[_requestId].completed)
            revert("the request has already completed");
        if (i_owner != msg.sender) revert("Only owner");

        uint256 approvalPercent = (spendingRequests[_requestId]
            .numberOfApproved * 100) / numberOfContributors;

        if (approvalPercent < 50) revert("disappoved");

        spendingRequests[_requestId].completed = true;
        (bool sent, ) = spendingRequests[_requestId].recipient.call{
            value: spendingRequests[_requestId].value
        }("");
        require(sent, "Faild to sent eth");
        emit Spend(
            _requestId,
            spendingRequests[_requestId].recipient,
            spendingRequests[_requestId].value
        );
    }
}