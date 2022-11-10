/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract KYC{
    address admin;

    // Defining the Customer Struct.
    struct Customer{
        string username;
        string customerData;
        bool kycStatus;
        uint256 downvotes;
        uint256 upvotes;
        address bank;
    }
    // Mapping for customer data types
    mapping(string => Customer) customers;
    
    // Defining the Banks/Organisation Struct.
    struct Banks{
        string name;
        address ethAddress;
        uint256 complaintsReported;
        uint256 KYC_count;
        bool isAllowedToVote;
        string regNumber;
    }
    // Mapping for bank data types
    mapping(address=> Banks) banks;
    address[] public banklist;
    
    // Defining KYC request struct.
    struct KYC_Requests{
        string username;
        address Bank;
        string customerData;
    }
    // Mapping KYC request data type
    mapping(string => KYC_Requests) kycRequests;
    // Constructor
    constructor(){
        admin=msg.sender;
    }
    //Checks whether the requestor is admin
    modifier isAdmin {
        require(
            admin == msg.sender,
            "Only admin is allowed to operate this functionality"
        );
        _;
    }
    // Checks whether bank has been validated and added by admin
    modifier isBankValid {
        require(
            banks[msg.sender].ethAddress == msg.sender,
            "Unauthenticated requestor! Bank not been added by admin."
        );
        _;
    }

    // Admin Interface
    function addBank(string memory _bankName,address _bankAddress,string memory _regNumber) public isAdmin returns (uint8) {
        require(banks[_bankAddress].ethAddress != _bankAddress,"Bank with same address already exists");
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].KYC_count = 0;
        banks[_bankAddress].isAllowedToVote = true;
        banks[_bankAddress].regNumber = _regNumber;
        banklist.push(_bankAddress);
        return 1;
    }

    function isAllowedToVote(address _bankAddress,bool _isAllowed) public isAdmin returns (uint8) {
        require(banks[_bankAddress].ethAddress == _bankAddress,"Add Bank First");
        banks[_bankAddress].isAllowedToVote=_isAllowed;
        return 1;
    }

    function removeBank(address _bankAddress) public isAdmin returns (uint8) {
        require(banks[_bankAddress].ethAddress == _bankAddress,"Add Bank First");
        delete banks[_bankAddress];
        return 1;
    }

    // Bank Interface

    // Adding KYC requests to request list
    function addKYCRequest(string memory _userName,string memory _dataHash) public isBankValid returns (uint8) {
        // Checking if the KYC request is already present
        require (keccak256(abi.encodePacked(kycRequests[_userName].customerData)) != keccak256(abi.encodePacked(_dataHash)),"KYC Request already in process");
        // Checking if the customer is already present
        require (keccak256(abi.encodePacked(customers[_userName].customerData)) != keccak256(abi.encodePacked(_dataHash)),"Customer is already present");
        kycRequests[_userName].username=_userName;
        kycRequests[_userName].Bank=msg.sender;
        kycRequests[_userName].customerData=_dataHash;
        banks[msg.sender].KYC_count+=1;
        return 1;
    }

    // Removing KYC requests from requests list
    function removeKycRequest(string memory _userName) public isBankValid returns (uint8) {
        // Checking wether KYC request is present before removing
        require (keccak256(abi.encodePacked(kycRequests[_userName].username)) == keccak256(abi.encodePacked(_userName)),"Please do a KYC request before");
        delete kycRequests[_userName];
        return 1;
    }

    // Adding Customers to the customers mapping
    function addCustomer(string memory _userName,string memory _data) public isBankValid returns (uint8) {
        // Checking if the customer already exists.
        require (keccak256(abi.encodePacked(customers[_userName].customerData)) != keccak256(abi.encodePacked(_data)),"Customer is already present");
        // Checking wether KYC request is present before adding the customer
        require (keccak256(abi.encodePacked(kycRequests[_userName].customerData)) == keccak256(abi.encodePacked(_data)),"Please do a KYC request before");
        customers[_userName].username=_userName;
        customers[_userName].customerData=_data;
        customers[_userName].downvotes=0;
        customers[_userName].upvotes=0;
        customers[_userName].bank=msg.sender;
        return 1;
    }

    // View all the customers
    function viewCustomer(string memory _userName) public view isBankValid returns (Customer memory){
        // Checking if the customer is present
        require (keccak256(abi.encodePacked(customers[_userName].username)) == keccak256(abi.encodePacked(_userName)),"Customer not present in the list");
        return customers[_userName];
    }

    // Upvote the customers
    function upvoteCustomer(string memory _userName) public isBankValid returns (uint8) {
        // Checking if the customer is present
        require (keccak256(abi.encodePacked(customers[_userName].username)) == keccak256(abi.encodePacked(_userName)),"Customer not present in the list");
        // Checking if the bank can upvote or downvote i.e. faulty
        require(banks[msg.sender].isAllowedToVote==true,"Faulty Bank");
        customers[_userName].upvotes+=1;
        if(customers[_userName].upvotes>customers[_userName].downvotes){
            customers[_userName].kycStatus=true;
        }
        return 1;
    }

    // Downvote the customers
    function downvoteCustomer(string memory _userName) public isBankValid  returns (uint8) {
        // Checking if the customer is present
        require (keccak256(abi.encodePacked(customers[_userName].username)) == keccak256(abi.encodePacked(_userName)),"Customer not present in the list");
        // Checking if the bank can upvote or downvote i.e. faulty
        require(banks[msg.sender].isAllowedToVote==true,"Faulty Bank");
        customers[_userName].downvotes+=1;
        if(customers[_userName].downvotes>(banklist.length/3)){
            customers[_userName].kycStatus=false;
        }
        return 1;
    }

    // Modify customers data
    function modifyCustomer(string memory _userName, string memory _data) public isBankValid returns (uint8) {
        // Checking if the customer is present
        require (keccak256(abi.encodePacked(customers[_userName].username)) == keccak256(abi.encodePacked(_userName)),"Customer not present in the list");
        customers[_userName].customerData=_data;
        customers[_userName].downvotes=0;
        customers[_userName].upvotes=0;
        customers[_userName].bank=msg.sender;
        removeKycRequest(_userName);
        return 1;
    }

    // Report Bank
    function reportBank(address _bankAddress,string memory _bankName) public isBankValid returns (uint8) {
        // Checking if the bank is already present
        require(banks[_bankAddress].ethAddress == _bankAddress,"Bank does not exist");
        banks[_bankAddress].complaintsReported +=1;
        // Adding condition if the number of complaints is greater than 1/3 of total banks present
        if(banks[_bankAddress].complaintsReported>(banklist.length/3)){
            banks[_bankAddress].isAllowedToVote = false;
        }
        return 1;
    }

    // Get Bank Complaints
    function getBankComplaints(address _bankAddress) public view isBankValid returns (uint256) {
        // Checking if the bank is already present
        require(banks[_bankAddress].ethAddress == _bankAddress,"Bank does not exist");
        return (banks[_bankAddress].complaintsReported);
    }

    // View Bank Details
    function viewBankDetails(address _bankAddress) public view isBankValid returns (Banks memory) {
        // Checking if the bank is already present
        require(banks[_bankAddress].ethAddress == _bankAddress,"Bank does not exist");
        return (banks[_bankAddress]);
    }
}