/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Banking KYC contract. 
 * @author Nitin Sharma
 * @notice This contract can be used by banking system to use kyc functionality in a decentralized manner
 */

contract BankingKyc {
    
    struct Customer {
        bool kycStatus;
        address bankAddress;
        string name;
        string phNumber;
    }

    struct Bank {
        address bankAddress;
        bool kycEnabled;
        bool customerOnBoardingEnabled;
        string name;
        string[] customers; //Customers phNumber
    }

    /**
     * @notice This function is used to get the bank info
     */
    Bank[] public banks;

    /**
     * @notice This function is used to get the customer info
     */
    Customer[] public customers;

    mapping(address => uint) private mapBanks;
    mapping(string => uint) private mapCustomers;
    address public owner;

    event NewBankAdded(string name, address bankAddress);
    event NewCustomerAdded(string name, string phNumber, string bankName);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Allowes only owner to execute the method
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can perform this transaction.");
        _;
    }

    /**
     * @notice Allowes only Banks with KYC priviledges to execute the method
     */
    modifier onlyKycEnabledBank() {
        uint index = mapBanks[msg.sender];
        require(index > 0, "Invalid Bank Address");
        require(banks[index-1].kycEnabled, "Only KYC Enabled Banks can perform this transaction.");
        _;
    }

    /**
     * @notice Allowes only Banks with Customer Onboarding priviledges to execute the method
     */
    modifier onlyCustAllowedBanks() {
        uint index = mapBanks[msg.sender];
        require(index > 0, "Invalid Bank Address");
        require(banks[index-1].customerOnBoardingEnabled, "Only Banks with Customer Onboarding enabled can perform this transaction.");
        _;
    }

    /**
     * @notice Adds a new bank into the contract.
     * @param name Name of the bank
     * @param bankAdd Ethereum address of the bank
     * @dev Make sure private keys of bank address are known to the owner.
                They will be used by the banks to perform the certain APIs.
            Only Owner can perform this trasaction
     */

    function addNewBank(string memory name, address bankAdd) external onlyOwner {
        uint index = mapBanks[bankAdd];
        require(index == 0, "Bank is already Added");

        Bank storage bank = banks.push();

        bank.name = name;
        bank.kycEnabled = false;
        bank.customerOnBoardingEnabled = false;
        bank.bankAddress = bankAdd;

        mapBanks[bankAdd] = banks.length;
        emit NewBankAdded(name, bankAdd);
    }

    /**
     * @notice Adds a customer to the bank.
     * @param custName Customer name 
     * @param phNumber Phone number of the customer. This field must be unique across 
            all the customers associated with the contract.
     * @dev Only banks with customer onboarding priviledges can perform this transaction
     */

    function addNewCustomer(string calldata custName, string memory phNumber) external onlyCustAllowedBanks {
        uint index = mapCustomers[phNumber];
        uint bankIndex = mapBanks[msg.sender];
        require(index == 0, "Customer is already added.");

        Customer storage customer = customers.push();
        customer.name = custName;
        customer.phNumber = phNumber;
        customer.bankAddress = msg.sender;
        customer.kycStatus = false;

        Bank storage bank = banks[bankIndex-1];
        bank.customers.push(phNumber);

        mapCustomers[phNumber] = customers.length;
        emit NewCustomerAdded(custName, phNumber, bank.name);
    }

    /**
     * @notice Returns the KYC status of the customer
     * @param phNumber Customer's unique phone number
     * @return status KYC status of the customer
     */
    function getKycStatusForCustomer(string calldata phNumber) external view returns(bool status) {
        uint index = mapCustomers[phNumber];
        require(index > 0, "Not a valid customer");

        return customers[index-1].kycStatus;
    }

    /**
     * @notice Performs Customer KYC. 
     * @param phNumber Customers unique phone number to update KYC status
     * @dev Only banks with KYC priviledge can perform this trasaction
     */
    function performCustomerKyc(string calldata phNumber) external onlyKycEnabledBank {
        uint custIndex = mapCustomers[phNumber];
        require(custIndex > 0, "Not a valid customer");
        require(customers[custIndex-1].bankAddress == msg.sender, "KYC can only be performed by customer's bank");

        customers[custIndex-1].kycStatus = true;
    }

    /**
     * @notice Blocks the customer Onboarding capability for the bank
     * @param bankAddress Unique address of the bank which needs to be blocked for customer onboarding
     * @dev Only Owner can perform this transaction
     */
    function blockBankCustOnBoarding(address bankAddress) external onlyOwner {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        banks[index-1].customerOnBoardingEnabled = false;
    }

    /**
     * @notice Blocks the KYC capability for the bank
     * @param bankAddress Unique address of the bank which needs to be blocked for customer KYC
     * @dev Only Owner can perform this transaction
     */
    function blockBankForKyc(address bankAddress) external onlyOwner {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        banks[index-1].kycEnabled = false;
    }

    /**
     * @notice Allows the customer Onboarding capability for the bank
     * @param bankAddress Unique address of the bank which needs to be alloed for customer onboarding
     * @dev Only Owner can perform this transaction
     */
    function allowBankCusOnBoarding(address bankAddress) external onlyOwner {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        banks[index-1].customerOnBoardingEnabled = true;
    }

    /**
     * @notice Allows the customer KYC capability for the bank
     * @param bankAddress Unique address of the bank which needs to be allowed for customer KYC
     * @dev Only Owner can perform this transaction
     */
    function allowBankForKyc(address bankAddress) external onlyOwner {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        banks[index-1].kycEnabled = true;
    }

    /**
     * @notice Get the customer data by phone number
     * @param phNumber Unique phone number of the customer
     * @return customer A customer structure is returned as a disctionary
     */
    function getCustomerData(string calldata phNumber) external view returns(Customer memory customer) {
        uint custIndex = mapCustomers[phNumber];
        require(custIndex > 0, "Not a valid customer");

        return customers[custIndex-1];
    }

    /**
     * @notice Get the bank's data by bank address
     * @param bankAddress Unique ethereum address of the bank
     * @return bank A Bank structure is returned as a disctionary
     */
    function getBankInfo(address bankAddress) external view returns(Bank memory bank) {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        bank = banks[index-1];
    }

    /**
     * @notice Get the customers by bank address
     * @param bankAddress Unique ethereum address of the bank
     * @return phNumbers Array of phone numbers of associated customer with the bank
     */
    function getCustomersNumberByBank(address bankAddress) external view returns(string[] memory phNumbers) {
        uint index = mapBanks[bankAddress];
        require(index > 0, "Not a valid bank address");

        return banks[index-1].customers;
    }

    /**
     * @notice Get all the banks info added in the contract
     * @return Array of Banks
     */
    function getAllBanks() external view returns(Bank[] memory) {
        return banks;
    }

    /**
     * @notice Get all the customer's info added in the contract
     * @return Array of Customers
     */
    function getAllCustomers() external view returns(Customer[] memory) {
        return customers;
    }
}