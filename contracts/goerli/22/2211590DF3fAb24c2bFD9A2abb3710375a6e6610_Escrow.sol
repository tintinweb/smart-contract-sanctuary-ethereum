/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Escrow {
    //variables
    enum State { 
        PENDING_DAMAGE_ASSESSMENT, // 0
        PENDING_CAPITAL_QUOTATION, // 1
        APPROVED, // 2
        REJECTED // 3
    }

    address public damageAssessor; //approver 1
    address public capitalQuoter; //approver 2

    address[] private userIndex; // Keeps an index of the users

    struct UserDetail {
        string firstName;
        string lastName;
        // ??????????????????
        uint256 premium; // amount in wei
        uint256 riskLevel; // scale 1-5, 1 = worst, 5 = best
        bool isExist;
    }

    struct ClaimRequestDetails {
        uint256 id;
        string description;
        bool isExist;
        bool damageFlag; // True when assessed
        bool quotationFlag; // True when assessed
        State claimState; // The claim state is an enum that highlights the current state of the claim
    }

    mapping(State => string) public states; // Map from State to String to simplify output.
    mapping(address => ClaimRequestDetails[]) clientRequests; // Map from address to claim requests
    mapping(address => UserDetail) private userDetails; // Mapping from address to user details

    // Events
    event RequestId(uint256);

    // Modifiers
    // Checks if sender is a user
    modifier onlyClient() {
        // Check if the mapping exist in UserDetail (ie: The address is a client)
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
    
    //// Functions
    // Constructor
    constructor(address _damageAssessor, address _capitalQuoter) {
        // Store addresses
        damageAssessor = _damageAssessor;
        capitalQuoter = _capitalQuoter;

        // For user accessibility, map enum to a string
        states[State.PENDING_DAMAGE_ASSESSMENT] = "Pending damage assessment";
        states[State.PENDING_CAPITAL_QUOTATION] = "Pending capital quotation";
        states[State.APPROVED] = "Approved";
        states[State.REJECTED] = "Rejected";
    }

    // Function for client to pay premium
    // Prequisite: Sender must be a client
    function payPremium() onlyClient payable public {
        // Require premium paid = valid amount
        require(msg.value >= (userDetails[msg.sender].premium * (1 wei)), "Invalid amount");
    }

    // Function for client to initiate a claim request
    // Prequisite: Sender must be a client
    // Returns: Request ID
    function initiateClaimRequest(string memory _description) onlyClient public returns (uint256 _requestId) {
        // Request ID NO: increment length of array by 1
        uint256 requestId = clientRequests[msg.sender].length + 1;
        ClaimRequestDetails memory newClaimRequest = ClaimRequestDetails(
            requestId, // id
            _description, // description
            true, // is exist
            false, // damage flag
            false, // quotation flag
            State.PENDING_DAMAGE_ASSESSMENT // claim state
        );
        clientRequests[msg.sender].push(newClaimRequest); // Push new request to array
        emit RequestId(requestId); // To log the request ID
        return requestId;
    }

    // Function for damage assessor to approve the damage request
    // Prequisite: Sender must be registered damage assessor, Client address must be a client
    function approveRequestDamage(address _clientAddress, uint256 _requestId) onlyDamageAssessor public {
        // require client exists ?
        
        // Retrieve the claim details 
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        // Require request state is pending damage assessment
        require(claimRequestDetails.claimState == State.PENDING_DAMAGE_ASSESSMENT, "Claim request has either cleared damage assessment, been approved or rejected");

        // Set claim state from pending damage assessment to pending capital quotation
        claimRequestDetails.claimState = State.PENDING_CAPITAL_QUOTATION;
        claimRequestDetails.damageFlag = true;
    }

    // Function for request quotation assessor to approve the request quotation
    // Prequisite: Sender must be registered quotation assessor, Client address must be a client
    function approveRequestQuotation(address payable _clientAddress, uint256 _requestId, uint256 _payoutPrice) onlyCapitalQuoter public {
        //require client exists ?
        
        // Retrieve the claim details 
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];
        // Require request state is pending quotation
        require(claimRequestDetails.damageFlag, "Yet to clear damage assessment");

        // Set state to approved
        claimRequestDetails.claimState = State.APPROVED;
        claimRequestDetails.quotationFlag = true;

        // 
        if (claimRequestDetails.damageFlag && claimRequestDetails.quotationFlag) {
            _clientAddress.transfer(_payoutPrice * (1 wei));
        }
    }

    // Function for damage assessor to reject the damage request
    // Prequisite: Sender must be registered quotation assessor, Client address must be a client
    function rejectRequestDamage(address _clientAddress, uint256 _requestId) onlyDamageAssessor public {
        //require client exists ?
        //require request state is pending ?
        
        // Get claim details
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];

        // Set state to rejected
        claimRequestDetails.claimState = State.REJECTED;
        claimRequestDetails.damageFlag = false;
    }

    // Function for request quotation assessor to reject the request quotation
    // Prequisite: Sender must be registered quotation assessor, Client address must be a client
     function rejectRequestQuotation(address _clientAddress, uint256 _requestId) onlyCapitalQuoter public {
        //require client exists ?
        //require request state is pending ?
        
        // Get claim details
        ClaimRequestDetails storage claimRequestDetails = clientRequests[_clientAddress][_requestId - 1];

        // Set state to rejected
        claimRequestDetails.claimState = State.REJECTED;
        claimRequestDetails.quotationFlag = false;
    }

    // Function for request status to be retrieved
    function getRequestStatus(address _clientAddress, uint256 _requestId) onlyClient external view returns (string memory) {
        // Check if request exists
        require(clientRequests[_clientAddress][_requestId - 1].isExist == true, "Request does not exist");

        // Find the claim state 
        State requestEnumNum = clientRequests[_clientAddress][_requestId - 1].claimState;

        return states[requestEnumNum];
    }

    // Function to create a user
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