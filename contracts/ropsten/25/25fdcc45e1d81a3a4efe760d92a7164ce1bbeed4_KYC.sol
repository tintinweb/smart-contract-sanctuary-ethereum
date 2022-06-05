/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.5.16;

contract KYC {

    address kycadmin;
   
    constructor() public {
        kycadmin = msg.sender;
    }
   
    modifier onlyadmin(){
        require(msg.sender==kycadmin);
        _;
    }

    struct Bank {
        string name;
        uint256 kycCount;
        address Address;
        bool isAllowedToAddCustomer;
        bool kycPrivilege;
    }

    struct Customer {
        string name;
        string AdhaarNumber;
        address validatedBank;
        bool kycStatus;
    }

 mapping(address => Bank) banks; //  Mapping a bank's address to the Bank
    mapping(string => Customer) customersInfo;  //  Mapping a customer's username to the Customer

//addNewBank

 function addNewBank(string memory bankName,address add) public onlyadmin {
        require(!areBothStringSame(banks[add].name,bankName), "A Bank already exists with same name");
        banks[add] = Bank(bankName,0,add,true,true);
    }

//addNewCustomerRequestForKYC

 function addNewCustomerRequestForKYC(string memory custName) public returns(int){
        require(banks[msg.sender].kycPrivilege, "Requested Bank does'nt have KYC Privilege");
        customersInfo[custName].kycStatus= true;
        banks[msg.sender].kycCount++;

        return 1;
    }


//addNewCustomerToBank

  function addNewCustomerToBank(string memory custName,string memory custAdhaarNumber) public {
        require(banks[msg.sender].isAllowedToAddCustomer, "Requested Bank is blocked to add new customers");
        require(customersInfo[custName].validatedBank == address(0), "Requested Customer already exists");

        customersInfo[custName] = Customer(custName, custAdhaarNumber,msg.sender,false);
    }

//allowBankFromAddingNewCustomers

function allowBankFromAddingNewCustomers(address add) public onlyadmin returns(int){
        require(banks[add].Address != address(0), "Bank not found");
        require(!banks[add].isAllowedToAddCustomer, "Requested Bank is already allowed to add new customers");
        banks[add].isAllowedToAddCustomer = true;
        return 1;
}
// allowBankFromKYC

 function allowBankFromKYC(address add) public onlyadmin returns(int) {
        require(banks[add].Address != address(0), "Bank not found");
        banks[add].kycPrivilege = true;
        return 1;
    }


// blockBankFromAddingNewCustomers


 function blockBankFromAddingNewCustomers(address add) public onlyadmin returns(int){
        require(banks[add].Address != address(0), "Bank not found");
        require(banks[add].isAllowedToAddCustomer, "Requested Bank is already blocked to add new customers");
        banks[add].isAllowedToAddCustomer = false;
        return 1;
 }



//blockBankFromKYC

 function blockBankFromKYC(address add) public onlyadmin returns(int) {
        require(banks[add].Address != address(0), "Bank not found");
        banks[add].kycPrivilege = false;
        return 1;
    }

//viewCustomerData

  function viewCustomerData(string memory custName) public view returns(string memory,bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        return (customersInfo[custName].AdhaarNumber,customersInfo[custName].kycStatus);
    }

//getCustomerKycStatus

function getCustomerKycStatus(string memory custName) public view returns(bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        return (customersInfo[custName].kycStatus);
}
//areBothStringSame

  function areBothStringSame(string memory a, string memory b) private pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}