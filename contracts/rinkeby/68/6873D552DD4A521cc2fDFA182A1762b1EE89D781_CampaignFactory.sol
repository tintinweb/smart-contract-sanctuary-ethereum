// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract CampaignFactory {
    address[] public deployedCampaigners;

    function createCampaigner(uint minimum) external {
        deployedCampaigners.push(address(new Campaign(minimum, msg.sender)));
    }

    function getDeployedCampaigners() external view returns (address[] memory) {
        return deployedCampaigners;
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
    mapping(address => uint) public contributors;
    uint public contributorsCount;
    Request[] public requests;

    modifier onlyManager{
        require(msg.sender == manager, "This can only be called by the manager!");
        _;
    }

    modifier onlyContributors{
        require(contributors[msg.sender] != 0, "This can only be called by contributors!");
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
        require(contributors[msg.sender] == 0, "You cannot contribute twice!");
        require(msg.value > minimumContribution--, "You must give Eth greater or equal to the minimum requirement");
        contributors[msg.sender] = msg.value;
        contributorsCount++;
    }

    function increaseContributution() external payable onlyContributors {
        contributors[msg.sender] = contributors[msg.sender] + msg.value;
    }

    function createRequest(string calldata description, uint value, address recipient) external onlyManager {
        Request storage newRequest = requests.push();
 
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete= false;
        newRequest.approvalCount= 0;
    }

    function updateRequest(uint requestNo, string calldata description, uint value, address recipient) external onlyManager noCompleted(requests[requestNo]) {
        Request storage request = requests[requestNo];
        request.description = description;   
        request.value = value;
        request.recipient = recipient;
    }

    function approveRequest(uint requestNo) external onlyContributors noCompleted(requests[requestNo]){
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

    function rejectRequest(uint requestNo) external onlyContributors noCompleted(requests[requestNo]){
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
        require(totalCount > (contributorsCount / 2), "Total votes should be more than 50% of total contributors");

        payable(request.recipient).transfer(request.value);
        request.complete = true;
    }

    function transferOwnership(address _newManager) external onlyManager{
        manager = _newManager;
    }
}