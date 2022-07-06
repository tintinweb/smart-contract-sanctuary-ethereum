/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

pragma solidity ^0.5.0;

contract KYC {

    address admin;

    enum BankActions {
        AddKYC,
        RemoveKYC,
        ApproveKYC,

        AddCustomer,
        RemoveCustomer,
        ModifyCustomer,
        DeleteCustomer,
        UpVoteCustomer,
        DownVoteCustomer,
        ViewCustomer,

        ReportSuspectedBank
    }

    struct Customer {
        string name;
        string data;
        uint256 upVotes;
        uint256 downVotes;
        address validatedBank;
        bool kycStatus;
    }

    struct Bank {
        string name;
        string regNumber;
        uint256 suspiciousVotes;
        uint256 kycCount;
        address ethAddress;
        bool isAllowedToAddCustomer;
        bool kycPrivilege;
        bool votingPrivilege;
    }

    struct Request {
        string customerName;
        string customerData;
        address bankAddress;
        bool isAllowed;
    }
    event ContractInitialized();
    event CustomerRequestAdded();
    event CustomerRequestRemoved();
    event CustomerRequestApproved();

    event NewCustomerCreated();
    event CustomerRemoved();
    event CustomerInfoModified();

    event NewBankCreated();
    event BankRemoved();
    event BankBlockedFromKYC();

    constructor() public {
        emit ContractInitialized();
        admin = msg.sender;
    }


    address[] bankAddresses;    //  To keep list of bank addresses. So that we can loop through when required

    mapping(string => Customer) customersInfo;  //  Mapping a customer's username to the Customer
    mapping(address => Bank) banks; //  Mapping a bank's address to the Bank
    mapping(string => Bank) bankVsRegNoMapping; //  Mapping a bank's registration number to the Bank
    mapping(string => Request) kycRequests; //  Mapping a customer's username to KYC request
    mapping(string => mapping(address => uint256)) upvotes; //To track upVotes of all customers vs banks
    mapping(string => mapping(address => uint256)) downvotes; //To track downVotes of all customers vs banks
    mapping(address => mapping(int => uint256)) bankActionsAudit; //To track downVotes of all customers vs banks

    /********************************************************************************************************************
     *
     *  Name        :   addNewCustomerRequest
     *  Description :   This function is used to add the KYC request to the requests list. If kycPermission is set to false bank won’t be allowed to add requests for any customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer for whom KYC is to be done
     *      @param  {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/
    function addNewCustomerRequest(string memory custName, string memory custData) public payable returns(int){
        require(banks[msg.sender].kycPrivilege, "Requested Bank does'nt have KYC Privilege");
        require(kycRequests[custName].bankAddress != address(0), "A KYC Request is already pending with this Customer");

        kycRequests[custName] = Request(custName,custData, msg.sender, false);
        banks[msg.sender].kycCount++;

        emit CustomerRequestAdded();
        auditBankAction(msg.sender,BankActions.AddKYC);

        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   removeCustomerRequest
     *  Description :   This function will remove the request from the requests list.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer for whom KYC request has to be deleted
     *
     *******************************************************************************************************************/

    function removeCustomerRequest(string memory custName) public payable returns(int){
        require(kycRequests[custName].bankAddress ==msg.sender, "Requested Bank is not authorized to remove this customer as KYC is not initiated by you");
        delete kycRequests[custName];
        emit CustomerRequestRemoved();
        auditBankAction(msg.sender,BankActions.RemoveKYC);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   addCustomer
     *  Description :   This function will add a customer to the customer list. If IsAllowed is false then don't process
     *                  the request.
     *  Parameters  :
     *      param {string} custName :  The name of the customer
     *      param {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/
    function addCustomer(string memory custName,string memory custData) public payable {
        require(banks[msg.sender].isAllowedToAddCustomer, "Requested Bank does not have Voting Privilege");
        require(customersInfo[custName].validatedBank == address(0), "Requested Customer already exists");

        customersInfo[custName] = Customer(custName, custData, 0,0,msg.sender,false);

        auditBankAction(msg.sender,BankActions.AddCustomer);

        emit NewCustomerCreated();
    }

    /********************************************************************************************************************
     *
     *  Name        :   removeCustomer
     *  Description :   This function will remove the customer from the customer list. Remove the kyc requests of that customer
     *                  too. Only the bank which added the customer can remove him.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function removeCustomer(string memory custName) public payable returns(int){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        require(customersInfo[custName].validatedBank ==msg.sender, "Requested Bank is not authorized to remove this customer as KYC is not initiated by you");

        delete customersInfo[custName];
        removeCustomerRequest(custName);
        auditBankAction(msg.sender,BankActions.RemoveCustomer);
        emit CustomerRemoved();
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   modifyCustomer
     *  Description :   This function allows a bank to modify a customer's data. This will remove the customer from the kyc
     *                  request list and set the number of downvote and upvote to zero.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *      @param  {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/

    function modifyCustomer(string memory custName,string memory custData) public payable returns(int){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        removeCustomerRequest(custName);

        customersInfo[custName].data = custData;
        customersInfo[custName].upVotes = 0;
        customersInfo[custName].downVotes = 0;

        auditBankAction(msg.sender,BankActions.ModifyCustomer);
        emit CustomerInfoModified();

        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   viewCustomerData
     *  Description :   This function allows a bank to view details of a customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function viewCustomerData(string memory custName) public payable returns(string memory,bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        auditBankAction(msg.sender,BankActions.ViewCustomer);
        return (customersInfo[custName].data,customersInfo[custName].kycStatus);
    }

    /********************************************************************************************************************
     *
     *  Name        :   getCustomerKycStatus
     *  Description :   This function is used to fetch customer kyc status from the smart contract. If true then the customer
     *                  is verified.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function getCustomerKycStatus(string memory custName) public payable returns(bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        auditBankAction(msg.sender,BankActions.ViewCustomer);
        return (customersInfo[custName].kycStatus);
    }

    /********************************************************************************************************************
     *
     *  Name        :   upVoteCustomer
     *  Description :   This function allows a bank to cast an upvote for a customer. This vote from a bank means that
     *                  it accepts the customer details as well acknowledge the KYC process done by some bank on the customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function upVoteCustomer(string memory custName) public payable returns(int){
        require(banks[msg.sender].votingPrivilege, "Requested Bank does not have Voting Privilege");
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        customersInfo[custName].upVotes++;
        customersInfo[custName].kycStatus = (customersInfo[custName].upVotes > customersInfo[custName].downVotes && customersInfo[custName].upVotes >  bankAddresses.length/3);
        upvotes[custName][msg.sender] = now;
        auditBankAction(msg.sender,BankActions.UpVoteCustomer);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   downVoteCustomer
     *  Description :   This function allows a bank to cast an downvote for a customer. This vote from a bank means that
     *                  it does not accept the customer details.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/
    function downVoteCustomer(string memory custName) public payable returns(int){
        require(banks[msg.sender].votingPrivilege, "Requested Bank does not have Voting Privilege");
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        customersInfo[custName].downVotes++;
        customersInfo[custName].kycStatus = (customersInfo[custName].upVotes > customersInfo[custName].downVotes && customersInfo[custName].upVotes >  bankAddresses.length/3);
        downvotes[custName][msg.sender] = now;
        auditBankAction(msg.sender,BankActions.DownVoteCustomer);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   reportSuspectedBank
     *  Description :   This function allows a bank to report doubt/suspicion about another bank
     *  Parameters  :
     *      @param  {string} custName :  The address of the bank which is suspicious
     *
     *******************************************************************************************************************/
    function reportSuspectedBank(address suspiciousBankAddress) public payable returns(int){
        require(banks[suspiciousBankAddress].ethAddress != address(0), "Requested Bank not found");
        banks[suspiciousBankAddress].suspiciousVotes++;

        auditBankAction(msg.sender,BankActions.ReportSuspectedBank);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   getReportCountOfBank
     *  Description :   This function is used to fetch bank doubt/suspicion reports from the smart contract.
     *  Parameters  :
     *      @param  {string} custName :  The address of the bank which is suspicious
     *
     *******************************************************************************************************************/
    function getReportCountOfBank(address suspiciousBankAddress) public payable returns(uint256){
        require(banks[suspiciousBankAddress].ethAddress != address(0), "Requested Bank not found");
        return banks[suspiciousBankAddress].suspiciousVotes;
    }



    /********************************************************************************************************************
     *
     *  Name        :   addBank
     *  Description :   This function is used by the admin to add a bank to the KYC Contract. You need to verify if the
     *                  user trying to call this function is admin or not.
     *  Parameters  :
     *      param  {string} bankName :  The name of the bank/organisation.
     *      param  {string} regNumber :   registration number for the bank. This is unique.
     *      param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function addBank(string memory bankName,string memory regNumber,address ethAddress) public payable {

        require(msg.sender==admin, "Only admin can add bank");
        require(!areBothStringSame(banks[ethAddress].name,bankName), "A Bank already exists with same name");
        require(bankVsRegNoMapping[bankName].ethAddress != address(0), "A Bank already exists with same registration number");

        banks[ethAddress] = Bank(bankName,regNumber,0,0,ethAddress,true,true,true);
        bankAddresses.push(ethAddress);

        emit NewBankCreated();
    }

    /********************************************************************************************************************
     *
     *  Name        :   removeBank
     *  Description :   This function is used by the admin to remove a bank from the KYC Contract.
     *                  You need to verify if the user trying to call this function is admin or not.
     *  Parameters  :
     *      @param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function removeBank(address ethAddress) public payable returns(int){
        require(msg.sender==admin, "Only admin can remove bank");
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");

        delete banks[ethAddress];

        emit BankRemoved();
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   blockBankFromKYC
     *  Description :   This function can only be used by the admin to change the status of kycPermission of any of the
     *                  banks at any point of the time.
     *  Parameters  :
     *      @param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function blockBankFromKYC(address ethAddress) public payable returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        banks[ethAddress].kycPrivilege = false;
        emit BankBlockedFromKYC();
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   blockBankFromVoting
     *  Description :   This function can only be used by the admin to change the voting privilegen of any of the
     *                  banks at any point of the time.
     *  Parameters  :
     *      @param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function blockBankFromVoting(address ethAddress) public payable returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        banks[ethAddress].votingPrivilege = false;
        emit BankBlockedFromKYC();
        return 1;
    }


    /*********************************************************
    *            Internal functions
    *********************************************************/

    /********************************************************************************************************************
     *
     *  Name        :   auditBankAction
     *  Description :   This is an internal function is to track all the actions done by any bank
     *  Parameters  :
     *      param  {address} changesDoneBy :   Ethereum address of the Bank who made the change
     *      param  {BankActions} bankAction :  The ENUM value of action done by the bank
     *
     *******************************************************************************************************************/

    function auditBankAction(address changesDoneBy, BankActions bankAction) private {
        bankActionsAudit[changesDoneBy][int(bankAction)] = now;
    }

    /********************************************************************************************************************
     *
     *  Name        :   areBothStringSame
     *  Description :   This is an internal function is verify equality of strings
     *  Parameters  :
     *      @param {string} a :   1st string
     *      @param  {string} b :   2nd string
     *
     *******************************************************************************************************************/
    function areBothStringSame(string memory a, string memory b) private pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}