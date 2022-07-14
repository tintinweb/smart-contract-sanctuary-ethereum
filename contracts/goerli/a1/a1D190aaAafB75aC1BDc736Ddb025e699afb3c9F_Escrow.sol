// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Escrow {
    //variables
    enum State{ PENDING_DAMAGE_ASSESSMENT, PENDING_CAPITAL_QUOTATION, APPROVED, REJECTED }

    address public damageAssessor; //approver 1
    address public capitalQuoter; //approver 2

    address[] private userIndex;

    struct UserDetail {
        string firstName;
        string lastName;
        uint256 premium; //amount in wei
        uint256 riskLevel; //scale 1-5, 1 = worst, 5 = best
        bool isExist;
    }

    struct ClaimRequestDetails {
        uint256 id;
        string description;
        bool isExist;
        bool damageFlag;
        bool quotationFlag;
        State claimState;
    }

    mapping(State => string) public states;
    mapping(address => ClaimRequestDetails[]) clientRequests;
    mapping(address => UserDetail) private userDetails;

    //events
    event RequestId(uint256);

    //modifiers
    modifier onlyClient() {
        require(userDetails[msg.sender].isExist == true, "Only client can call this function");
        _;
    }

    modifier onlyDamageAssessor() {
        require(msg.sender == damageAssessor, "Only damage assessor can call this function");
        _;
    }

    modifier onlyCapitalQuoter() {
        require(msg.sender == capitalQuoter, "Only capital quoter can call this function");
        _;
    }
    
    //functions
    constructor(address _damageAssessor, address _capitalQuoter) {
        damageAssessor = _damageAssessor;
        capitalQuoter = _capitalQuoter;

        states[State.PENDING_DAMAGE_ASSESSMENT] = "Pending damage assessment";
        states[State.PENDING_CAPITAL_QUOTATION] = "Pending capital quotation";
        states[State.APPROVED] = "Approved";
        states[State.REJECTED] = "Rejected";
    }

    function payPremium() onlyClient payable public {
        //require premium paid = valid amount
        require(msg.value >= (userDetails[msg.sender].premium * (1 wei)), "Invalid amount");
    }

    function initiateClaimRequest(string memory _description) onlyClient public returns (uint256 _requestId) {
        uint256 requestId = clientRequests[msg.sender].length + 1;
        ClaimRequestDetails memory newClaimRequest = ClaimRequestDetails(
            requestId,
            _description,
            true,
            false,
            false,
            State.PENDING_DAMAGE_ASSESSMENT
        );
        clientRequests[msg.sender].push(newClaimRequest);
        emit RequestId(requestId);
        return requestId;
    }

    function approveRequestDamage(address _clientAddress, uint256 _requestId) onlyDamageAssessor public {
        //require client exists
        
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        //require request state is pending damage assessment
        require(claimRequestDetails.claimState == State.PENDING_DAMAGE_ASSESSMENT, "Claim request has either cleared damage assessment, been approved or rejected");

        claimRequestDetails.claimState = State.PENDING_CAPITAL_QUOTATION;
        claimRequestDetails.damageFlag = true;
    }

    function approveRequestQuotation(address payable _clientAddress, uint256 _requestId, uint256 _payoutPrice) onlyCapitalQuoter public {
        //require client exists
        
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        //require request state is pending quotation
        require(claimRequestDetails.damageFlag, "Yet to clear damage assessment");

        claimRequestDetails.claimState = State.APPROVED;
        claimRequestDetails.quotationFlag = true;

        if (claimRequestDetails.damageFlag && claimRequestDetails.quotationFlag) {
            _clientAddress.transfer(_payoutPrice * (1 wei));
        }
    }

    function rejectRequestDamage(address _clientAddress, uint256 _requestId) onlyDamageAssessor public {
        //require client exists
        //require request state is pending
        
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        claimRequestDetails.claimState = State.REJECTED;
        claimRequestDetails.damageFlag = false;
    }

     function rejectRequestQuotation(address _clientAddress, uint256 _requestId) onlyCapitalQuoter public {
        //require client exists
        //require request state is pending
        
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        claimRequestDetails.claimState = State.REJECTED;
        claimRequestDetails.quotationFlag = false;
    }

    function getRequestStatus(address _clientAddress, uint256 _requestId) onlyClient external view returns (string memory) {
        require(clientRequests[_clientAddress][_requestId - 1].isExist == true, "Request does not exist");
        State requestEnumNum = clientRequests[_clientAddress][_requestId - 1].claimState;
        return states[requestEnumNum];
    }

    function insertUser(
        string memory _firstName,
        string memory _lastName,
        address _userAddress,
        uint256 _premium,
        uint256 _riskLevel
    ) external returns (bool success) {
        userDetails[_userAddress].firstName = _firstName;
        userDetails[_userAddress].lastName = _lastName;
        userDetails[_userAddress].premium = _premium;
        userDetails[_userAddress].riskLevel = _riskLevel;
        userDetails[_userAddress].isExist = true;
        userIndex.push(_userAddress);
        return true;
    }

    function getUserDetails(address _userAddress) public view returns (string memory firstName, string memory lastName, uint256 premium, uint256 riskLevel) {
        return (
            userDetails[_userAddress].firstName,
            userDetails[_userAddress].lastName,
            userDetails[_userAddress].premium,
            userDetails[_userAddress].riskLevel
        );
    }

    function updateUserPremium(address _userAddress, uint256 _newPremium) external returns (bool success) {
        userDetails[_userAddress].premium = _newPremium;
        return true;
    }

    function updateUserRiskLevel(address _userAddress, uint256 _newRiskLevel) public returns (bool success) {
        userDetails[_userAddress].riskLevel = _newRiskLevel;
        return true;
    }
}