pragma solidity ^0.8.0;

contract Camapign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
       // mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    constructor(uint minimum){
        manager = msg.sender;
        minimumContribution = minimum;
    }

    modifier onlyOwner{
        require(manager == msg.sender);
        _;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(string memory description, uint value, address recipient) public onlyOwner {
        
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete:false,
            approvalCount:0

        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        // require(!request.approvals[msg.sender]);

        // request.approvals[msg.sender] = true;
        request.approvalCount++;

    }

    function finalizeRequest(uint index) public onlyOwner {
        Request storage request = requests[index];
        require(request.approvalCount > (approversCount/2));
        require(!requests[index].complete);
        payable(request.recipient).transfer(request.value);
        requests[index].complete = true;
    }


}