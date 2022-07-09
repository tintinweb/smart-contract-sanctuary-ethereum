// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract CampaignFactory {
    struct Campaigns {
        string title;
        string description;
        address campaignAddress;
    }

    Campaigns[] public deployedCampaigns;

    function createCampaign(string calldata title, string calldata description, uint minimumContribution) external {
        address campaignAddress = address(new Campaign(minimumContribution, msg.sender));
        Campaigns memory campaign = Campaigns({
            title: title,
            description: description,
            campaignAddress: campaignAddress
        });

        deployedCampaigns.push(campaign);
    }

    function getDeployedCampaigns() external view returns (Campaigns[] memory) {
        return deployedCampaigns;
    }
}
     
contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        uint rejectedCount;
        mapping(address => string) approvals;
    }

    address public manager;
    uint public minimumContribution;
    mapping(address => uint) public approvers;
    uint public approversCount;
    Request[] public requests;
    uint public pendingRequests;

    modifier onlyManager{
        require(msg.sender == manager, "This can only be called by the manager!");
        _;
    }

    modifier onlyApprovers{
        require(approvers[msg.sender] != 0, "This can only be called by approvers!");
        _;
    }

    modifier noCompleted(Request storage request){
        require(!request.complete, "You cannot change a completed request!");
        _;
    }

    constructor(uint _minimumContribution, address _manager) {
        manager = _manager;
        minimumContribution = _minimumContribution;
    }

    function stringEqual(string memory a, string memory b) internal pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function stringNotEqual(string memory a, string memory b) internal pure returns (bool){
        return (keccak256(abi.encodePacked((a))) != keccak256(abi.encodePacked((b))));
    }

    function contribute() external payable{
        require(approvers[msg.sender] == 0, "You cannot contribute twice!");
        require(msg.value > minimumContribution - 1, "You must give Eth greater or equal to the minimum requirement");
        approvers[msg.sender] = msg.value;
        approversCount++;
    }

    function increaseContributution() external payable onlyApprovers {
        approvers[msg.sender] = approvers[msg.sender] + msg.value;
    }

    function createRequest(string calldata description, uint value, address recipient) external onlyManager {
        Request storage newRequest = requests.push();
 
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete= false;
        newRequest.approvalCount= 0;

        pendingRequests++;
    }

    function updateRequest(uint requestNo, string calldata description, uint value, address recipient) external onlyManager noCompleted(requests[requestNo]) {
        Request storage request = requests[requestNo];
        request.description = description;   
        request.value = value;
        request.recipient = recipient;
    }

    function approveRequest(uint requestNo) external onlyApprovers noCompleted(requests[requestNo]){
        Request storage request = requests[requestNo];
        require(stringNotEqual(request.approvals[msg.sender], "approve"), "You cannot approve a request twice!");

        if(stringEqual(request.approvals[msg.sender], "reject")){
            request.rejectedCount--;
            request.approvalCount++;
        } else {
            request.approvalCount++;
        }

        request.approvals[msg.sender] = "approve";
    }

    function rejectRequest(uint requestNo) external onlyApprovers noCompleted(requests[requestNo]){
        Request storage request = requests[requestNo];
        require(stringNotEqual(request.approvals[msg.sender], "reject"), "You cannot reject a request twice!");

        if(stringEqual(request.approvals[msg.sender], "approve")) {
            request.approvalCount--;
            request.rejectedCount++;
        } else {
            request.rejectedCount++;
        }

        request.approvals[msg.sender] = "reject";
    }

    function finalizeRequest(uint requestNo) external onlyManager noCompleted(requests[requestNo]){
        Request storage request = requests[requestNo];
        require(address(this).balance > request.value, "Contract does not have enough balance");
        require(request.approvalCount > request.rejectedCount, "You cannot finalize requests that has more rejections than approvals");
        uint totalCount = request.approvalCount + request.rejectedCount;
        require(totalCount > (approversCount / 2), "Total votes should be more than 50% of total approvers");

        payable(request.recipient).transfer(request.value);
        request.complete = true;
        pendingRequests--;
    }

    function getSummary() public view returns (
        uint,
        uint,
        uint,
        uint,
        uint,
        address
    ) {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            pendingRequests,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }

    function transferOwnership(address _newManager) external onlyManager{
        manager = _newManager;
    }
}