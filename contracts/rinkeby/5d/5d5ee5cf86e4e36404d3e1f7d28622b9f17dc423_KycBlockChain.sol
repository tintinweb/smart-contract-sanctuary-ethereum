/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity >=0.4.21 ;

interface KYC_Functions{
    enum Status {Accepted, Rejected, Pending}
    // Checks if the current address is an Organisation(Bank) or not 
    function isOrg() external view returns(bool);
    // Checks if the current address is an Customer or not 
    function isCus() external view returns(bool);
    // A function to register as a new customer to get your KYC checked by a bank
    function newCustomer(string calldata _name, string calldata _hash, address _bank) external payable returns(bool);
    // A function that allows you to be a bank and audit KYC data of customers
    function newOrganisation(string calldata _name) external payable returns(bool);
    // A function which is only visible to the bankers so they can verify the data
    function viewCustomerData(address _address) external view returns(string memory);
    // Customers also can change the their data if the KYC request gets rejected
    function modifyCustomerData(string calldata _name,string calldata _hash, address _bank) 
    external payable returns(bool);
    // Checks the status of a customers KYC Request (Approved or Rejected or Pending)
    function checkStatus() external returns(Status);
    // Function that can change the status of a request (Only for banks)
    function changeStatusToAccepted(address _custaddress) external payable;
    // Function that can change the status of a request (Only for banks)
    function changeStatusToRejected(address _custaddress) external payable;
    // A function that enables the bank to lookup at all the KYC requests pointed at it
    function viewRequests() external view returns(address[] memory);
    // A function that returns the name of a customer
    function viewName(address _address) external view returns(string memory);

}

contract KycBlockChain is KYC_Functions{

    address[] public Banks;
    address[] public Requests;
    uint public bankslength=0;

    enum Entity { Customer, Organisation } 
    

    struct Customer{
        string c_name;
        string data_hash;
        address bank_address;
        bool exists;
        Entity entity;
    }

    struct Organisation{
        string b_name;
        bool exists;
        Entity entity;
        mapping(address => Status) requests;
        address[] allrequests;
    }

    mapping(address => Customer) allCustomers;
    mapping(address => Organisation) allOrganisations;

    function isOrg() public view returns(bool){
        if(allOrganisations[msg.sender].exists){
            return true;
        }
        return false;
    }

    function isCus() public view returns(bool){
        if(allCustomers[msg.sender].exists){
            return true;
        }
        return false;
    } 

    function newCustomer(string memory _name, string memory _hash, address _bank) public payable returns(bool){
        require(!isCus(),"Customer Already Exists!");
        require(allOrganisations[_bank].exists,"No such Bank!");
        allCustomers[msg.sender].c_name = _name;
        allCustomers[msg.sender].data_hash = _hash;
        allCustomers[msg.sender].bank_address = _bank;
        // allCustomers[msg.sender].access[msg.sender] = true;
        allCustomers[msg.sender].exists = true;
        allCustomers[msg.sender].entity = Entity.Customer;
        notifyBank(_bank);
        return true;

    }

    function newOrganisation(string memory _name) public payable returns(bool){
        require(!isOrg(),"Organisation already exists with the same address!");
        allOrganisations[msg.sender].b_name = _name;
        allOrganisations[msg.sender].exists = true;
        allOrganisations[msg.sender].entity = Entity.Organisation;
        Banks.push(msg.sender);
        bankslength++;
        return true;
    }

    function viewCustomerData(address _address) public view returns(string memory){
        require(isOrg(),"Access Denied");
        if(allCustomers[_address].exists){
            return allCustomers[_address].data_hash;
        }
        return "No such Customer in the database";
    }

    function modifyCustomerData(string memory _name,string memory _hash, address _bank) public payable returns(bool){
        require(isCus(),"You are not a customer");
        allCustomers[msg.sender].c_name = _name;
        allCustomers[msg.sender].data_hash = _hash;
        allCustomers[msg.sender].bank_address = _bank;
        return true;
    }

    function notifyBank(address _bankaddress) internal {
        allOrganisations[_bankaddress].requests[msg.sender] = Status.Pending;
        allOrganisations[_bankaddress].allrequests.push(msg.sender);
    }

    function checkStatus() public returns(Status) {
        require(isCus(),"You are not a customer");
        address _presbank = allCustomers[msg.sender].bank_address;
        return allOrganisations[_presbank].requests[msg.sender];
    }

    function changeStatusToAccepted(address _custaddress) public payable{
        require(isOrg(),"You are not permitted to use this function");
        address _bank = allCustomers[_custaddress].bank_address;
        require(_bank == msg.sender,"You dont have access to verify this data");
        allOrganisations[msg.sender].requests[_custaddress] = Status.Accepted;
    }

    function changeStatusToRejected(address _custaddress) public payable{
        require(isOrg(),"You are not permitted to use this function");
        address _bank = allCustomers[_custaddress].bank_address;
        require(_bank == msg.sender,"You dont have access to verify this data");
        allOrganisations[msg.sender].requests[_custaddress] = Status.Rejected;
    }

    function viewRequests() public view returns(address[] memory){
        require(isOrg(),"You are not Permitted");
        return allOrganisations[msg.sender].allrequests;
    }

    function viewName(address _address) public view returns(string memory){
        require(isOrg(),"Not an Organisation");
        return allCustomers[_address].c_name;
    } 

}