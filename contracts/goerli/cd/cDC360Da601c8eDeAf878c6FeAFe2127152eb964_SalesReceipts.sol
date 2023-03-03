// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SalesReceipts {
    struct Company {
        string name;
        address owner;
        address wallet;
        bool isRegistered;
        bool isApproved;
    }

    struct Receipt {
        address company;
        string itemName;
        uint256 quantity;
        uint256 price;
        uint256 timestamp;
    }

    struct Admin {
        bool isSuperAdmin;
        bool isAdmin;
    }

    mapping(address => Company) public companies;
    mapping(uint256 => Receipt) public receipts;
    mapping(address => mapping(uint256 => bool)) public monthlySales;
    mapping(address => Admin) public admins;

    uint256 public receiptCount = 0;
    address public superAdmin;

    event CompanyRegistered(
        address indexed company,
        string name,
        address owner,
        address wallet
    );
    event CompanyApproved(address indexed company);
    event ReceiptIssued(
        address indexed company,
        uint256 receiptNumber,
        string itemName,
        uint256 quantity,
        uint256 price
    );
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    constructor() {
        superAdmin = msg.sender;
        admins[msg.sender].isSuperAdmin = true;
        emit AdminAdded(msg.sender);
    }

    // --- MODIFIERS ---
    modifier onlySuperAdmin() {
        require(
            msg.sender == superAdmin,
            "Only super admin can call this function"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            admins[msg.sender].isSuperAdmin || admins[msg.sender].isAdmin,
            "Only admin can call this function"
        );
        _;
    }

    // --- MODIFIERS ---

    // --- ADMIN ---
    function addAdmin(address adminAddress) public onlySuperAdmin {
        require(
            !admins[adminAddress].isSuperAdmin && !admins[adminAddress].isAdmin,
            "Address is already an admin"
        );
        admins[adminAddress].isAdmin = true;
        emit AdminAdded(adminAddress);
    }

    function removeAdmin(address adminAddress) public onlySuperAdmin {
        require(
            admins[adminAddress].isSuperAdmin || admins[adminAddress].isAdmin,
            "Address is not an admin"
        );
        admins[adminAddress].isAdmin = false;
        emit AdminRemoved(adminAddress);
    }

    // --- ADMIN ---

    // --- COMPANY ---
    function registerCompany(string memory name, address wallet) public {
        require(
            !companies[msg.sender].isRegistered,
            "Company already registered"
        );
        companies[msg.sender] = Company(name, msg.sender, wallet, true, false);
        emit CompanyRegistered(msg.sender, name, msg.sender, wallet);
    }

    function approveCompany(address companyAddress) public onlyAdmin {
        require(
            companies[companyAddress].isRegistered,
            "Company not registered"
        );
        require(
            !companies[companyAddress].isApproved,
            "Company already approved"
        );
        companies[companyAddress].isApproved = true;
        emit CompanyApproved(companyAddress);
    }

    function getCompany(
        address companyAddress
    ) public view returns (string memory, address, bool) {
        require(companies[companyAddress].isRegistered, "Company not found");
        Company memory company = companies[companyAddress];
        return (company.name, company.owner, company.isApproved);
    }

    // --- COMPANY ---

    // --- RECEIPTS ---
    function issueReceipt(
        string memory itemName,
        uint256 quantity,
        uint256 price
    ) public {
        require(companies[msg.sender].isApproved, "Company not approved");
        receiptCount++;
        receipts[receiptCount] = Receipt(
            msg.sender,
            itemName,
            quantity,
            price,
            block.timestamp
        );
        monthlySales[msg.sender][getMonth(block.timestamp)] = true;
        emit ReceiptIssued(msg.sender, receiptCount, itemName, quantity, price);
    }

    function getReceipt(
        uint256 receiptNumber
    ) public view returns (address, string memory, uint256, uint256, uint256) {
        require(
            receiptNumber > 0 && receiptNumber <= receiptCount,
            "Invalid receipt number"
        );
        Receipt memory receipt = receipts[receiptNumber];
        return (
            receipt.company,
            receipt.itemName,
            receipt.quantity,
            receipt.price,
            receipt.timestamp
        );
    }

    // --- RECEIPTS ---

    // --- SALES ---
    function getTotalSalesMonthly() public view returns (uint256) {
        uint256 totalSales = 0;
        for (uint256 i = 1; i <= receiptCount; i++) {
            if (
                receipts[i].company == msg.sender &&
                monthlySales[msg.sender][getMonth(receipts[i].timestamp)]
            ) {
                totalSales += receipts[i].quantity * receipts[i].price;
            }
        }
        return totalSales;
    }

    function getTotalSales(
        address companyAddress
    ) public view onlyAdmin returns (uint256) {
        uint256 totalSales = 0;
        for (uint256 i = 1; i <= receiptCount; i++) {
            if (
                receipts[i].company == companyAddress &&
                monthlySales[companyAddress][getMonth(receipts[i].timestamp)]
            ) {
                totalSales += receipts[i].quantity * receipts[i].price;
            }
        }
        return totalSales;
    }

    // --- SALES ---

    // --- HELPERS ---
    function getMonth(uint256 timestamp) private pure returns (uint256) {
        return (timestamp / 1 days) * 1 days;
    }
    // --- HELPERS ---
}