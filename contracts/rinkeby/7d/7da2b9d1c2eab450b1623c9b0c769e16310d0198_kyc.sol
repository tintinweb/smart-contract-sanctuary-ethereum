/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity ^0.5.0;

contract kyc {
    
    // admin variable to store the address of the admin
    address admin;
    
    //  Struct customer
    //  uname - username of the customer
    //  dataHash - customer data
    //  rating - rating given to customer given based on regularity
    //  upvotes - number of upvotes recieved from banks
    //  bank - address of bank that validated the customer account

    struct Customer {
        string uname;
        string dataHash;
        uint rating;
        uint upvotes;
        address bank;
        string password;
    }

    //  Struct Bank/Organisation
    //  name - name of the bank/organisation
    //  ethAddress - ethereum address of the bank/organisation
    //  rating - rating based on number of valid/invalid verified accounts
    //  KYC_count - number of KYCs verified by the bank/organisation
    struct Bank {
        string name;
        address ethAddress;
        uint rating;
        uint KYC_count;
        string regNumber;
    }
    
    // Struct KYC_Request
    // uname - Username will be used to map the KYC request with the customer data. 
    // bankAddress - Bank address here is a unique account address for the bank, which can be used to track the bank.
    // dataHash - hash of the data or identification documents provided by the Customer.
    // isAllowed - request is added by a trusted bank or not.
    // Bank is not secure, then the IsAllowed is set to false for all the bank requests done by the bank.
    struct KYC_Request {
        string uname;
        address bankAddress;
        string dataHash;
        bool isAllowed;
    }
    
    //  Struct finalCustomer
    //  uname - username of the customer
    //  dataHash - customer data
    //  rating - rating given to customer given based on regularity
    //  upvotes - number of upvotes recieved from banks
    //  bank - address of bank that validated the customer account
    struct FinalCustomer {
        string uname;
        string dataHash;
        uint rating;
        uint upvotes;
        address bank;
        string password;
    }
    
    //  List of all customers
    Customer[] allCustomers;

    //  List of all Banks/Organisations
    Bank[] allBanks;

    
    // List of all KYC_Request
    KYC_Request[] allRequests;
    
    // List of all finalCustomers
    FinalCustomer[] allFinalCustomers;
    
    
    //Setting the admin as the person who deploys the smart contract onto the network.
    constructor() public {
        admin = msg.sender;
    }
    
    //ADMIN INTERFACE 
    
    //Function is used by the admin to add a bank to the KYC Contract.
    //@param bankName - Name of the bank
    //@param bankAddress - Address of the bank
    //@param bankRegistrationNumber - Bank registration number
    //@returns isAddedToBankListFlag - whether bank is added to the allBanks or not.
    function addBank(string memory bankName, address bankAddress, string memory bankRegistrationNumber) public payable returns(bool) {
        bool isAddedToBankListFlag = false;
        
        //verify if the user trying to call this function is admin or not.
        if(admin==msg.sender) {
            allBanks.length ++;
            //Initialise rating=0 and KYC_count=0
            allBanks[allBanks.length - 1] = Bank(bankName, bankAddress, 0, 0, bankRegistrationNumber);
            isAddedToBankListFlag = true;
            return isAddedToBankListFlag;
        }
    
        return isAddedToBankListFlag;
    }
    
    // Function is used by the admin to remove a bank from the KYC Contract. 
    // You need to verify if the user trying to call this function is admin or not.
    // @param bankAddress - address of the bank
    // @returns bool - flag stating the successful removal of the bank from the contract.
    function removeBank(address bankAddress) public payable returns(bool) {
        bool isRemovedFromBankListFlag = false;
        
        if(admin==msg.sender) {
            for(uint i = 0; i < allBanks.length; ++ i) {
                if(allBanks[i].ethAddress == bankAddress) {
                    for(uint j = i+1;j < allBanks.length; ++ j) {
                        allBanks[i-1] = allBanks[i];
                    }
                    allBanks.length --;
                    isRemovedFromBankListFlag = true;
                    return isRemovedFromBankListFlag;
                }
            }
        }
        return isRemovedFromBankListFlag;
    }
    
    // Function is used to fetch the bank details.
    // @param bankAddress-Bank address
    // @returns Bank details of type Bank
    function getBankDetails(address bankAddress) public payable returns( string memory name,
        address ethAddress,
        uint rating,
        uint KYC_count,
        string memory regNumber) {
        for(uint i = 0; i < allBanks.length; ++ i) {
            if(allBanks[i].ethAddress == bankAddress) {
                name = allBanks[i].name;
                ethAddress = allBanks[i].ethAddress;
                rating = allBanks[i].rating;
                KYC_count = allBanks[i].KYC_count;
                regNumber = allBanks[i].regNumber;
            }
        }
    }
    
    //BANK INTERFACE
    
    // Function upvotes to provide ratings on other Banks.
    // Add and update votes for the banks.
    // Also need to update the rating for the bank in this function.
    // @param bankAddress - address of the bank who is getting upvoted
    // @returns uint
    function upvotesForBank(address bankAddress) public payable returns(string memory) {
        for(uint i = 0; i < allBanks.length; ++ i) {
            if(allBanks[i].ethAddress == bankAddress) {
                    // Increase the KYC_count for bankAddress
                    allBanks[i].KYC_count ++;
                    // Rating for a Bank
                    allBanks[i].rating = (allBanks[i].KYC_count)/allBanks.length;
                    //“0” if the rating is successfully updated
                    string memory s = string(abi.encodePacked(allBanks[i].rating, " ", allBanks[i].KYC_count, " ", allBanks.length));
                    return s;
            }
        }
        // error-bank not found 
        return "error";
    }
    
    // Function is used to add the KYC request to the KYC_Request requests list.
    // If the bank rating is less than or equal to 0.5 then assign IsAllowed to false. 
    // Else assign IsAllowed to true. 
    // @param userName - customer name as string
    // @param dataHash - customer data as string
    // @return value “1” to determine the status of success, value “0” for the failure of the function.
    function addRequest(string memory userName, string memory dataHash) public payable returns(uint){
        //bool isAllowedValue;
        for(uint i = 0; i < allBanks.length; ++ i) {
                //If the bank rating is less than or equal to 0.5 then assign IsAllowed to false. 
                //Else assign IsAllowed to true. 
            if((allBanks[i].ethAddress == msg.sender)) {
                // Check the rating of the bank
                if(allBanks[i].rating*10 >= 0.5*10){
                    allRequests.length ++;
                    allRequests[allRequests.length - 1] = KYC_Request(userName, msg.sender, dataHash,true);
                }else{
                    allRequests.length ++;
                    allRequests[allRequests.length - 1] = KYC_Request(userName, msg.sender, dataHash,false);
                }
                //return "1"-Success
                return 1;
            }
        }
        //return "0" - Failure of the function
        return 0;
    }
    
    // Function will add a customer to the customer list. 
    // If IsAllowed is false then don't process the request. 
    // @param userName - customer name as the string
    // @param dataHash - customer data as string
    // @return value “1” to determine the status of success
    // @return value “0” for the failure of the function.
    function addCustomer(string memory userName, string memory dataHash) public payable returns(uint) {
        //  throw error if username already in use
        for(uint i = 0;i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName))
                // Failure of the function as user already exists
                return 0;
        }
        
        // If IsAllowed is false then dont process the request.
        for(uint i = 0; i < allRequests.length; ++i) {
            if(stringsEquals(allRequests[i].uname, userName) && allRequests[i].bankAddress == msg.sender && allRequests[i].isAllowed && stringsEquals(allRequests[i].dataHash,dataHash)) {
                allCustomers.length ++;
                // set rating = 0, upvotes = 0, bank = current node, password = 0
                allCustomers[allCustomers.length-1] = Customer(userName, dataHash, 0, 0, msg.sender, "0");
                return 1;
            }
        }
        // If request doesnot exists in the KYC_Request list.
        return 0;
    }
    
    // Function will remove the request from the requests list.
    // @param userName - customer name as string
    // @param dataHash - customer data as string
    // @return value “1” to determine the status of success 
    //         value “0” for the failure of the function.
    function removeRequest(string memory userName, string memory dataHash) public payable returns(uint){
         for(uint i = 0; i < allRequests.length; ++ i) {
            if(stringsEquals(allRequests[i].uname, userName) && allRequests[i].bankAddress == msg.sender && stringsEquals(allRequests[i].dataHash,dataHash)) {
                //Remove the request from the requestlist and send status as "1"
                    for(uint j = i+1;j < allRequests.length; ++ j) {
                        allRequests[i-1] = allRequests[i];
                    }
                    allRequests.length --;
                    return 1;
            }
        }
        return 0;
    }
    
    // Function will remove the customer from the customer list.
    // @param userName - customerName
    // @return value “1” to determine the status of success
    //         value “0” for the failure of the function
    function removeCustomer(string memory userName) public payable returns(uint) {
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName)) {
                for(uint j = i+1;j < allCustomers.length; ++ j) {
                    allCustomers[i-1] = allCustomers[i];
                }
                allCustomers.length --;
                return 1;
            }
        }
        //  throw error if userName not found
        return 0;
    }
    
    // Function allows a bank to view details of a customer.
    // @param userName - customer name as string.
    // @param password - password for the user.
    // If the password is not set for the customer, then the incoming password string should be equal to "0".
    // @return dataHash - hash of the customer data in form of a string
    function viewCustomer(string memory userName,string memory password) public payable returns(string memory) {
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName) && stringsEquals(allCustomers[i].password, password)) {
                return allCustomers[i].dataHash;
            }
        }
        return "Customer not found in the list!";
    }
    
    // Function fetches the KYC requests for a specific bank.
    // @param bankAddress - Unique bank address as address is provided to fetch the bank kyc requests.
    // @returns
    // List of all the requests initiated by the bank which are yet to be validated.
    function getBankRequests(address bankAddress) public payable returns(
        string memory uname,
        address bankAdressToView,
        string memory dataHash,
        bool isAllowed
        ) {
        for(uint i=0;i<allRequests.length;++i) {
            if(allRequests[i].bankAddress == bankAddress) {
                uname = allRequests[i].uname;
                bankAdressToView = allRequests[i].bankAddress;
                dataHash = allRequests[i].dataHash;
                isAllowed = allRequests[i].isAllowed;
            }
        }
    }
    
    // Function is used to fetch bank rating from the smart contract.
    // @param bankAddress is passed as address to fetch bank ratings.
    // @returns ratings as unsigned integer.
    function getBankRating(address bankAddress) public payable returns(uint) {
        for(uint i = 0; i < allBanks.length; ++ i) {
            if(allBanks[i].ethAddress == bankAddress) {
                return allBanks[i].rating;
            }
        }
        return 0;
    }
    
    // Function is used to set a password for customer data, which can be later be unlocked by using the password.
    // @param userName - Username as string
    // @param password - Password as string
    // returns bool - A boolean result is returned which determines if the password for the customer has been successfully updated.
    function setPasswordForCustomerData(string memory userName, string memory password) public payable returns(bool) {
        for(uint i=0;i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName) && stringsEquals(allCustomers[i].password, "0")) {
                allCustomers[i].password = password;
                return true;
            }
        }
        return false;
    }
    
    // Function allows a bank to cast an upvote for a customer. 
    // This vote from a bank means that it accepts the customer details as well acknowledge the KYC process done by some bank on the customer.
    // You also need to update the rating for a customer in this function.
    // The rating is calculated as the number of upvotes for the customer/total number of banks. 
    // If rating is more than 0.5, then you can add the customer to the final_customer list.
    // @param userName as customer name
    // @return “1” to determine the status of success
    //   value “0” for the failure of the function.
    function updateRatingCustomer(string memory userName) public payable returns(uint) {
        //Total number of banks
        uint totalNumberOfBanks = allBanks.length;
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName)) {
                    allCustomers[i].upvotes ++;
                    allCustomers[i].rating += (allCustomers[i].upvotes/totalNumberOfBanks);
                    if(allCustomers[i].rating*10 >= 0.5*10){
                        allFinalCustomers.length++;
                        allFinalCustomers[allFinalCustomers.length-1]=FinalCustomer(allCustomers[i].uname,allCustomers[i].dataHash,allCustomers[i].rating,allCustomers[i].upvotes,allCustomers[i].bank,allCustomers[i].password);
                    }
                return 1;
            }
        }
        //  throw error if bank not found
        return 0;
    }
    
    // Function is used to fetch the details of FinalCustomer
    // @param userName - Customer name
    // @return address - bank address
    function showFinalCustomer() public payable returns(string memory){
        string memory finalCustomerList;
        for(uint i = 0; i < allFinalCustomers.length; ++ i) {
                finalCustomerList = string(abi.encodePacked(allFinalCustomers[i].uname, " ", allFinalCustomers[i].rating, " ", allFinalCustomers[i].upvotes));
        }
        return finalCustomerList;
    }
    
    // Function is used to fetch customer rating from the smart contract.
    // @param userName as customer name
    // @returns rating as unsigned integer
    function getCustomerRating(string memory userName) public payable returns(uint) {
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName)) {
                return allCustomers[i].rating;
            }
        }
        return 0;
    }
    
    
    // Function allows a bank to modify a customer's data.
    // Only applicable for the customers whose request have been validated and present in the customer list.
    // If the user is present in the final customer list then remove it from the final list.
    // Change the upvotes and rating component of the customer in customer list to "0".
    // Remove all the previous upvotes for the customer. Hence, banks need to again upvote on the customer to acknowledge the modified data. 
    // @param username as Customer username
    // @param password - password of the user, if no password is set then "0"
    // @param newDataHash - new customer data
    // @returns value “1” to determine the status of success 
    //          value “0” for the failure of the function.
    function modifyCustomer(string memory userName,string memory password, string memory newDataHash) public payable returns(uint) {
        
        // If the user is present in the final customer list then remove it from the final list.
        for(uint i = 0; i < allFinalCustomers.length; ++ i) {
            if(stringsEquals(allFinalCustomers[i].uname, userName) && stringsEquals(allCustomers[i].password, password)) {
                for(uint j = i+1;j < allFinalCustomers.length; ++ j) {
                    allFinalCustomers[i-1] = allFinalCustomers[i];
                }
                allFinalCustomers.length --;
                return 1;
            }
        }
        
        // Change the upvotes and rating component of the customer in customer list to "0".
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName) && stringsEquals(allCustomers[i].password, password)) {
                allCustomers[i].dataHash = newDataHash;
                allCustomers[i].bank = msg.sender;
                allCustomers[i].upvotes = 0;
                allCustomers[i].rating = 0;
                return 1;
            }
        }
        //  value “0” for the failure of the function.
        return 1;
    }
    
    // Function is used to fetch the bank details which made the last changes to the customer data.
    // @param userName - Customer name
    // @return address - bank address
    function retrieveAccessHistory(string memory userName) public payable returns(address){
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].uname, userName)){
                return allCustomers[i].bank;
            }
        }
    }
    
    // Utility Function to check the equality of two string variables
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b); 
        if (a.length != b.length)
            return false;
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }
}