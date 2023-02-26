// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19.0;

contract KYCContract {
    // banks(organisation)
    struct Bank {
        string name; // name of the bank
        address ethAddress; // unique ethereum address of the bank
        uint256 complaintsReported; // number of complains against this bank done by the other banks in the network
        uint256 kycCount; // number of KYC request initiated by the bank/organization
        bool isAllowedToVote; // to hold the status of the bank
        string regNumber; // registrationnumber of the bank
    }

    // customer details
    // customerAddress string
    // bankAddress address
    struct Customer {
        string name;
        address customerAddress; // unique customerAddress for the customer
        string customerData; // customer data or identity documents provided by the customer
        bool kycStatus; //status of the kyc request. if the number of upvotes/downvotes meet the required conditions, then it's true otherwise its false
        uint256 downvotes; // number of downvotes recieved from other banks over the customer data
        uint256 upvotes; // number of upvotes recieved from other banks over the customer data
        address bank; // unique address of the bank which has validated the kyc
    }

    struct KYCRequest {
        address customerAddress; // unique customerAddress for the customer
        address bank; // unique address of the bank which has validated the kyc
        string data; //  customer data or identity documents provided by the customer
    }

    address private admin;

    constructor() {
        admin = msg.sender;
    }

    // mapping to store list of address with customer details
    mapping(address => Customer) public customers;

    // mapping to store the list of address with bank details
    mapping(address => Bank) public banks;

    // number of banks added
    uint256 public numberOfBanks = 0;

    // mapping to store the KYC requests
    mapping(address => KYCRequest) private requests;

    // admin interface  ==> rbi
    modifier isAdminOnly() {
        require(admin == msg.sender, "Unauthorized Access");
        _;
    }

    // Add bank
    function addBank(
        string memory _bankName,
        address _ethAddress,
        string memory _regNumber
    ) public isAdminOnly {
        // check if admin
        // require(admin == msg.sender, "Unauthorized Access");

        // check if bank already added
        require(
            banks[_ethAddress].ethAddress == address(0),
            "Bank already present"
        );

        // add the bank
        banks[_ethAddress].name = _bankName;
        banks[_ethAddress].ethAddress = _ethAddress;
        banks[_ethAddress].regNumber = _regNumber;
        banks[_ethAddress].complaintsReported = 0;
        banks[_ethAddress].kycCount = 0;
        banks[_ethAddress].isAllowedToVote = true;
        banks[_ethAddress].complaintsReported = 0;

        // increasing bank count
        numberOfBanks = numberOfBanks + 1;
    }
    // remove bank
    function removeBank(address _ethAddress) public isAdminOnly {
        require(
            banks[_ethAddress].ethAddress != address(0),
            "Bank not present"
        );
        delete banks[_ethAddress];
        numberOfBanks = numberOfBanks - 1;
    }
    // modify isAllowedToVote
    function modifyIsAllowedToVote(address _ethAddress, bool _isAllowedToVote) public isAdminOnly {
        banks[_ethAddress].isAllowedToVote = _isAllowedToVote;
    }

    // bank interface

    // add Request: to add KYC request to the request list
    function addRequest(address _customerAddress, string memory _dataHash) public validBank isCustomerPresent(_customerAddress) {
        requests[_customerAddress].customerAddress = _customerAddress;
        requests[_customerAddress].bank = msg.sender;
        requests[_customerAddress].data = _dataHash;

        // to increase the KYC
        banks[msg.sender].kycCount = banks[msg.sender].kycCount + 1;
    }
    // remove Request: to remove KYC request to the request list
    function removeRequest(address _customerAddress) public {
        
        // To check if the customer requests with the same bank
        require(requests[_customerAddress].bank != address(0), "No KYC found for the user");
        
        // To check if same bank can remove or add the 
        require(requests[_customerAddress].bank == msg.sender, "Not allowed to remove the request");
       delete requests[_customerAddress];
    
        // to increase the KYC
        banks[msg.sender].kycCount = banks[msg.sender].kycCount - 1;
    }

    
    // To check if bank is allowed to vote or not
    modifier validBank() {
        require(banks[msg.sender].isAllowedToVote, "Bank is not allowed to vote");
        _;
    }

    modifier isCustomerPresent(address _customerAddress) {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not found in the Database");
        _;
    }

    modifier isBankPresent(address _bankAddress) {
        require(banks[_bankAddress].ethAddress != address(0), "Bank not found in the Database");
        _;
    }



    // add Customer: add a customer to a customer list
    function addCustomer(string memory _name, address _customerAddress, string memory _customerData) public validBank  {
        require(customers[_customerAddress].bank == address(0), "Customer is already present, please update the customerdata");
        customers[_customerAddress].name = _name;
        customers[_customerAddress].customerAddress = _customerAddress;
        customers[_customerAddress].customerData = _customerData;
        customers[_customerAddress].bank = msg.sender;
        customers[_customerAddress].upvotes = 0;
        customers[_customerAddress].downvotes = 0;
        customers[_customerAddress].kycStatus = false;
    }

    // view Customer: allows the details of a customer

    function viewCustomer(address _customerAddress) public view returns(string memory name, string memory datahash, bool kycStatus, uint upvotes,uint downvotes, address bank)  {
        require(customers[_customerAddress].bank != address(0), "Customer not present in the database");
        return (customers[_customerAddress].name, customers[_customerAddress].customerData,customers[_customerAddress].kycStatus, customers[_customerAddress].upvotes, customers[_customerAddress].downvotes, customers[_customerAddress].bank);
    }
    // upvote Customer: allows banks to upvote the customer. It means that it accepts the customer details as well as acknowledge the KYC process done by some bank of the customer

    function upvoteCustomer(address customerAddress) public validBank isCustomerPresent(customerAddress) {
        require(requests[customerAddress].bank != address(0), "No Kyc found in the kyc request" );
        customers[customerAddress].upvotes = customers[customerAddress].upvotes + 1;
        address kycBank = requests[customerAddress].bank;

        if(customers[customerAddress].upvotes > customers[customerAddress].downvotes) {
            if(customers[customerAddress].downvotes*100 < (numberOfBanks*100)/3) {
                customers[customerAddress].kycStatus = true;
            }
        } else {
            customers[customerAddress].kycStatus = false;
            banks[kycBank].isAllowedToVote = false; 
        }
    }


    function downvoteCustomer(address customerAddress) public validBank isCustomerPresent(customerAddress) {
        require(requests[customerAddress].bank != address(0), "No Kyc found in the kyc request" );
        customers[customerAddress].downvotes = customers[customerAddress].downvotes + 1;
        address kycBank = requests[customerAddress].bank;

        if(customers[customerAddress].downvotes > customers[customerAddress].upvotes) {
            banks[kycBank].isAllowedToVote = false;
            customers[customerAddress].kycStatus = false;
        } else if((customers[customerAddress].downvotes*100 > numberOfBanks*100/3)) {
            customers[customerAddress].kycStatus = false;
            banks[kycBank].isAllowedToVote = false; 
        } else {
            banks[kycBank].isAllowedToVote = true;
            customers[kycBank].kycStatus = true;
        }
    }
    //  modify Customer: to allow a bank to modify a customer's data. which means it will remove the customer from the KYC request list & set the number of downvotes & upvotes to zero


    // getBankComplaints: fetch bank complaints from the smart contract
    function getBankComplaints(address _ethAddress) public view isBankPresent(_ethAddress) returns(uint) {
        return banks[_ethAddress].complaintsReported;
    }

    // viewBankDetails: fetch details of the bank
    function viewBankDetails(address _bankAddress) public view isBankPresent(_bankAddress) returns(Bank memory) {
        return banks[_bankAddress];
    }
    // reportBank: to report any bank in the network. Also update modify the isAllowedToVote status of the bank according to the conditions mentioned in the problem statement
    function reportBank(address tobeReported) public validBank isBankPresent(tobeReported) {
        require(banks[tobeReported].ethAddress != msg.sender, "Cannot report to self");
        banks[tobeReported].complaintsReported = banks[tobeReported].complaintsReported  + 1;
        if(banks[tobeReported].complaintsReported * 100 > (numberOfBanks * 100)/3) {
            banks[tobeReported].isAllowedToVote = false;
        }
    }
}