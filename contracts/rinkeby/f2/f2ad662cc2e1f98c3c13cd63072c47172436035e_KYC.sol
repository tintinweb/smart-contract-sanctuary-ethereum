/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KYC {
    address admin;
    uint256 totalNumberOfBanks;
    
    // A STRUCT TO HOLD THE DETAILS OF A CUSTOMER 
    struct customer {
        string name;       // UNIQUE IDENTIFIER TO TRACK AND RETRIVE CUSTOMER DETAILS 
        string data;       // KYC DOCUMENTS PROVIDED BY THE CUSTOMER
        address bank;       // ADDRESS OF THE BANK THAT VALIDATED THE CUSTOMER
        bool KYC;           // KYC STATUS OF THE CUSTOMER
        uint256 upVotes;    // NUMBER OF BANKS THAT FINDS KYC DOC'S TO BE VALID 
        uint256 downVotes;  // NUMBER OF BANKS THAT FINDS KYC DOC'S TO BE INVALID
    }

    // A STRUCT TO HOLD THE DETAILS OF A BANKS
    struct bank {
        string name;                // BANK NAME
        address ethAddress;          // UNIQUE ETHEREUM ADDRESS OF THE BANK 
        string regNumber;           // REGISTRATION NUMBER OF THE BANK 
        uint256 complaintsReported;  // NUMBER OF COMPLAINTS REGISTERED AGAINST THE BANK 
        uint256 KYC_count;           // NUMBER OF KYC REQUESTS INITIATED BY THIS BANK
        bool isAllowedToVote;        // VOTING STATUS OF THE BANK
    } 

    // A STRUCT TO HOLD THE DETAILS OF THE KYC REQUEST
    struct KYC_request {
        string name;                    // UNIQUE IDENTIFIER TO TRACK THE CUSTOMER DETAILS 
        address bankAddress;             // UNIQUE ETHEREUM ADDRESS OF THE BANK TO TRACK THE BANK
        string customerData;            // KYC DOCUMENTS PROVIDED BY THE CUSTOMER
    }

    constructor() {
        admin = msg.sender;
        totalNumberOfBanks = 0;
    }

    mapping(string  => customer) customerList;                      // MAPPING TO HOLD LIST OF CUSTOMERS
    mapping(string  => KYC_request) requestList;                    // MAPPING TO HOLD LIST OF KYC REQUESTS
    mapping(address => bank) bankList;                              // MAPPING TO HOLD LIST OF BANKS
    mapping(address => mapping(string => bool)) hasVotedList ;      // MAPPING TO HOLD LIST OF VOTES REGISTERED 

    // FUNCTIONS TO CHECK VALIDITY 
    function validBank(address bankAddress) internal view returns(bool) {
        return (bankList[bankAddress].ethAddress != address(0))? true : false ;
    }
    function validCustomer(string memory cName) internal view returns(bool) {
        return (customerList[cName].bank != address(0))? true : false ;
    }
    function validRequest(string memory cName) internal view returns(bool) {
        return (requestList[cName].bankAddress == address(0))? true : false ;
    }
    function validVotingBank(address bankAddress) internal view returns(bool) {
        return (bankList[bankAddress].isAllowedToVote)? true : false ;
    }
    function validVotingHistory(string memory cName) internal view returns(bool) {
        return(hasVotedList[msg.sender][cName]? true : false);
    }
    function isAdmin() internal view returns(bool) {
        return (msg.sender == admin)? true : false ;
    }
    // FUNCTION TO CHECK KYC STATUS ACCORDING TO UP VOTES & DOWN VOTES
    function KYC_CHECK(string memory cName) internal view returns(bool) {
        if(customerList[cName].upVotes > customerList[cName].downVotes)
        {
            if (totalNumberOfBanks >= 6)
            {
                return(customerList[cName].downVotes > (totalNumberOfBanks/3)? false : true);
            }
            else {  return true;    }
        }
        else {  return false;   }
    }

    // EVENTS 
    event addRequestEvent(string indexed cName, string cData, address bankAddress);
    event removeRequestEvent(string indexed cName);
    event addCustomerEvent(string indexed cName, string cData, address bankAddress);
    event modifyCustomerEvent(string indexed cName, string cData, address bankAddress);
    event upVoteEvent(string indexed cName, uint256 upVotes);
    event downVoteEvent(string indexed cName, uint256 downVotes);
    event reportBankEvent(address indexed bankAddress, string bName, uint256 complaintsReported);
    event addBankEvent(address indexed bankAddress, string bName, string bRegNumber);
    event removeBankEvent(address indexed bankAddress);
    event votingRightsEvent(address indexed bankAddress, bool changedVotingStatus);

    // ************************************ BANK INTERFACE ************************************
    
    // FUNCTION TO ADD A KYC REQUEST TO THE KYC REQUEST'S LIST 
    function addRequest ( string memory cName, string memory cData ) public {
        require (validBank(msg.sender), "Only Valid Banks can add KYC request");
        require (validRequest(cName), "KYC request has already been added");

        requestList[cName].name = cName;
        requestList[cName].bankAddress = msg.sender;
        requestList[cName].customerData = cData;
        bankList[msg.sender].KYC_count++;

        emit addRequestEvent(requestList[cName].name, requestList[cName].customerData, requestList[cName].bankAddress);
    }

    // FUNCTION TO REMOVE A KYC REQUEST FROM THE KYC REQUEST'S LIST 
    function removeRequest (string memory cName) public {
        require (validBank(msg.sender), "Only Valid Banks can remove a KYC request");
        require (!validRequest(cName), "KYC request not found");

        delete requestList[cName];

        emit removeRequestEvent(cName);
    }
    
    // FUNCTION TO ADD A CUSTOMER TO THE CUSTOMER LIST 
    function addCustomer ( string memory cName, string memory cData ) public {
        require (validBank(msg.sender), "Only Valid Banks can add a Customer");
        require (!validCustomer(cName), "Customer is already added");
        require (!validRequest(cName), "KYC request not found");

        customerList[cName].name = cName;
        customerList[cName].data = cData;
        customerList[cName].bank = msg.sender;
        customerList[cName].upVotes = 0;
        customerList[cName].downVotes = 0;

        emit addCustomerEvent(customerList[cName].name, customerList[cName].data, customerList[cName].bank);
    }

    // FUNCTION TO MODIFY CUSTOMER DATA 
    function modifyCustomer(string memory cName, string memory cData) public {
        require (validCustomer(cName), "Customer not found");
        require (validBank(msg.sender), "Only Valid Banks can modify Customer data");

        removeRequest(cName);
        customerList[cName].name = cName;
        customerList[cName].data = cData;
        customerList[cName].upVotes = 0;
        customerList[cName].downVotes = 0;

        emit modifyCustomerEvent(customerList[cName].name, customerList[cName].data, customerList[cName].bank);
    }

    // FUNCTION TO VIEW CUSTOMER DETAILS 
    function viewCustomer(string memory cName) public view returns (string memory){
        require (validCustomer(cName), "Customer not found");
        
        return customerList[cName].data;
    }

    // FUNCTION TO UPVOTE CUSTOMERS 
    function upVote(string memory cName) public {
        require (validBank(msg.sender), "Only Valid Banks can Vote");
        require (validVotingBank(msg.sender), "You cant Vote");
        require (validCustomer(cName), "Customer not found");
        require (!validVotingHistory(cName), "You have already Voted for this Customer");

        customerList[cName].upVotes++;
        hasVotedList[msg.sender][cName] = true;
        customerList[cName].KYC = KYC_CHECK(cName);

        emit upVoteEvent(cName, customerList[cName].upVotes);
    }

    // FUNCTION TO DOWNVOTE CUSTOMERS 
    function downVote(string memory cName) public {
        require (validBank(msg.sender), "Only Valid Banks can Vote");
        require (validVotingBank(msg.sender), "You cant Vote");
        require (validCustomer(cName), "Customer not found");
        require (!validVotingHistory(cName), "You have already Voted for this Customer");

        customerList[cName].downVotes++;
        hasVotedList[msg.sender][cName] = true;
        customerList[cName].KYC = KYC_CHECK(cName);

        emit downVoteEvent(cName, customerList[cName].downVotes);
    }

    // FUNCTION TO GET BANK COMPLAINTS DETAILS 
    function getComplaints(address bankAddress) view public returns (uint256){
        require (validBank(bankAddress), "Bank Does'nt Exist");

        return bankList[bankAddress].complaintsReported;
    }

    // FUNCTION TO VIEW BANK DETAILS 
    function viewBankDetails(address bankAddress) view public returns(bank memory ) {
        require (validBank(bankAddress), "Bank Does'nt Exist");
        return bankList[bankAddress];
    }

    // FUNCTION TO REPORT A BANK
    function reportBank(address bankAddress, string memory bName) public {
        require (validBank(bankAddress), "Bank Does'nt Exist");
        require (validBank(msg.sender), "Only Valid Banks can register a complaint");

        bankList[bankAddress].complaintsReported++;
        bankList[bankAddress].isAllowedToVote = (bankList[bankAddress].complaintsReported > (totalNumberOfBanks/3)? false : true);


        emit reportBankEvent(bankAddress, bName, bankList[bankAddress].complaintsReported);
    }


    //************************************ ADMIN INTERFACE ************************************

    // FUNCTION TO ADD BANK 
    function addBank(string memory bName, address bankAddress, string memory bRegNumber) public {
        require (isAdmin(),"ADMIN ONLY ACCESS!!");
        require (!validBank(bankAddress), "Bank Already Exists");

        bankList[bankAddress].name = bName;           
        bankList[bankAddress].ethAddress = bankAddress;          
        bankList[bankAddress].regNumber = bRegNumber;           
        bankList[bankAddress].complaintsReported = 0;  
        bankList[bankAddress].KYC_count = 0;           
        bankList[bankAddress].isAllowedToVote = true;
        totalNumberOfBanks++;

        emit addBankEvent(bankAddress, bName, bRegNumber);
    }

    // FUNCTION TO MODIFY VOTING RIGHTS
    function votingRights(address bankAddress, bool changedVotingStatus) public {
        require (isAdmin(),"ADMIN ONLY ACCESS!!");
        require (validBank(bankAddress), "Bank Does'nt Exist");

        bankList[bankAddress].isAllowedToVote = changedVotingStatus ;

        emit votingRightsEvent(bankAddress, changedVotingStatus);
    }

    //FUNCTION TO REMOVE A BANK
    function removeBank(address bankAddress) public {
        require (isAdmin(),"ADMIN ONLY ACCESS!!");
        require (validBank(bankAddress), "Bank Does'nt Exist");

        delete bankList[bankAddress];
        totalNumberOfBanks--;

        emit removeBankEvent(bankAddress);
    }
}