// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CompanyReceipts {
    address public owner;

    // --- STRUCTS ---
    // Struct representing a company
    struct Company {
        address owner; // Address of the company owner
        string companyName; // Name of the company
        string companyAddress; // Address of the company
        bool approved; // Whether the company is approved by an admin
        uint256 approvalDate; // Date the company was approved
        address approvedBy; // Address of the admin who approved the company
        uint256 totalSales; // Total sales for the company
        mapping(uint256 => uint256) monthlySales; // Mapping from month to total sales for that month
    }

    // Struct representing a receipt
    struct Receipt {
        address company; // Address of the company that issued the receipt
        uint256 saleDate; // Sale date for the receipt
        string[] itemNames; // Name of the items
        uint256[] itemPrices; // Price of the items
        uint256[] itemQuantities; // Quantity of the items
    }

    // --- MAPPINGS ---
    // Mapping from company addresses to company structs
    mapping(address => Company) private companies;

    // Mapping from receipt IDs to receipt structs
    mapping(uint256 => Receipt) private receipts;

    // Mapping for roles
    mapping(address => bool) private admins;
    mapping(address => bool) private superAdmins;

    address[] private adminAddresses;
    address[] private superAdminAddresses;

    // Counter for receipt IDs
    uint256 private receiptCounter;

    // --- EVENTS ---
    event CompanyRegistration(
        address indexed companyId,
        string indexed companyName,
        uint256 indexed date
    );
    event CompanyApproved(
        address indexed companyId,
        address indexed adminId,
        uint256 indexed date
    );
    event ReceiptIssued(
        address indexed company,
        uint256 indexed receiptId,
        uint256 indexed date
    );
    event AdminAdded(address indexed adminId);
    event AdminRemoved(address indexed adminId);
    event SuperAdminAdded(address indexed adminId);
    event SuperAdminRemoved(address indexed adminId);

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner,
            "Caller is not an admin"
        );
        _;
    }

    modifier onlySuperadmin() {
        require(
            superAdmins[msg.sender] || msg.sender == owner,
            "Caller is not a superadmin"
        );
        _;
    }

    // --- FUNCTIONS ---
    // Assign roles during contract deployment
    constructor() {
        owner = msg.sender;

        // Assign roles to addresses
        grantAdminRole(msg.sender);
        grantSuperadminRole(msg.sender);
    }

    // COMPANY FUNCTIONS
    // Function for a company to register itself
    function registerCompany(
        string memory _companyName,
        string memory _companyAddress
    ) public returns (address) {
        Company storage company = companies[msg.sender];

        require(
            !company.approved,
            "Company already registered, please wait for approval."
        );

        company.owner = msg.sender;
        company.companyName = _companyName;
        company.companyAddress = _companyAddress;

        emit CompanyRegistration(msg.sender, _companyName, block.timestamp);

        return msg.sender;
    }

    // Function for an admin to approve a company
    function approveCompany(
        address _companyId
    ) public onlyAdmin returns (bool) {
        Company storage company = companies[_companyId];

        require(!company.approved, "Company already approved.");

        company.approved = true;
        company.approvalDate = block.timestamp;
        company.approvedBy = msg.sender;

        emit CompanyApproved(_companyId, msg.sender, block.timestamp);

        return true;
    }

    function getCompany(
        address _companyId
    )
        public
        view
        returns (
            bool _approved,
            uint256 _approvalDate,
            address _approvedBy,
            address _owner,
            string memory _companyName,
            string memory _companyAddress,
            uint256 _totalSales
        )
    {
        Company storage company = companies[_companyId];

        _approved = company.approved;
        _approvalDate = company.approvalDate;
        _approvedBy = company.approvedBy;
        _owner = company.owner;
        _totalSales = company.totalSales;
        _companyName = company.companyName;
        _companyAddress = company.companyAddress;
    }

    // RECEIPT FUNCTIONS
    // Function for a company to issue a receipt
    function issueReceipt(
        string[] memory _names,
        uint256[] memory _prices,
        uint256[] memory _quantities
    ) public returns (Receipt memory, string memory companyName) {
        Company storage company = companies[msg.sender];

        require(company.approved, "Company not approved");
        require(
            _names.length == _prices.length &&
                _names.length == _quantities.length,
            "Data arrays provided are not of equal length!"
        );

        // Calculate the total
        uint256 _saleAmount = 0;
        for (uint i = 0; i < _prices.length; i++) {
            _saleAmount += _prices[i] * _quantities[i];
        }

        // Create a receipt
        uint256 receiptId = ++receiptCounter;
        Receipt storage receipt = receipts[receiptId];

        receipt.company = msg.sender;
        receipt.saleDate = block.timestamp;
        receipt.itemNames = _names;
        receipt.itemPrices = _prices;
        receipt.itemQuantities = _quantities;

        // Update the company's sales
        company.totalSales += _saleAmount;
        company.monthlySales[getMonth(block.timestamp)] += _saleAmount;

        emit ReceiptIssued(msg.sender, receiptId, block.timestamp);

        return getReceipt(receiptId);
    }

    // Function to get information about a receipt
    function getReceipt(
        uint256 _receiptId
    ) public view returns (Receipt memory, string memory companyName) {
        Receipt storage receipt = receipts[_receiptId];
        Company storage company = companies[receipt.company];

        return (receipt, company.companyName);
    }

    // SALES FUNCTIONS
    // Function to get total sales for a company
    function getTotalSales(address _company) public view returns (uint256) {
        return companies[_company].totalSales;
    }

    // Function to get total sales for a company in a given month
    function getMonthSales(
        address _company,
        uint256 _month
    ) public view returns (uint256) {
        return companies[_company].monthlySales[_month];
    }

    // ADMIN FUNCTIONS
    // Grant admin role
    function grantAdminRole(address _address) public onlySuperadmin {
        require(admins[_address] != true, "Admin already exist");
        admins[_address] = true;
        adminAddresses.push(_address);
        emit AdminAdded(_address);
    }

    // Revoke admin role
    function revokeAdminRole(address _address) public onlySuperadmin {
        require(admins[_address] == true, "Admin does not exist");
        admins[_address] = false;

        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == _address) {
                adminAddresses[i] = adminAddresses[adminAddresses.length - 1];
                adminAddresses.pop();
                break;
            }
        }
        emit AdminRemoved(_address);
    }

    // Grant superadmin role
    function grantSuperadminRole(address _address) public onlySuperadmin {
        require(superAdmins[_address] != true, "Superadmin already exist");
        superAdmins[_address] = true;
        superAdminAddresses.push(_address);
        emit SuperAdminAdded(_address);
    }

    // Revoke superadmin role
    function revokeSuperadminRole(address _address) public onlySuperadmin {
        require(superAdmins[_address] == true, "Superadmin does not exist");
        superAdmins[_address] = false;

        for (uint256 i = 0; i < superAdminAddresses.length; i++) {
            if (superAdminAddresses[i] == _address) {
                superAdminAddresses[i] = superAdminAddresses[
                    superAdminAddresses.length - 1
                ];
                superAdminAddresses.pop();
                break;
            }
        }
        emit SuperAdminRemoved(_address);
    }

    // Returns all admins
    function getAdmins() public view onlySuperadmin returns (address[] memory) {
        // Creates an empty array of total number of campaigns
        address[] memory _allAdmins = new address[](adminAddresses.length);

        for (uint i = 0; i < adminAddresses.length; i++) {
            _allAdmins[i] = adminAddresses[i];
        }

        return _allAdmins;
    }

    // Returns all super admins
    function getSuperAdmins()
        public
        view
        onlySuperadmin
        returns (address[] memory)
    {
        // Creates an empty array of total number of campaigns
        address[] memory _allAdmins = new address[](superAdminAddresses.length);

        for (uint i = 0; i < superAdminAddresses.length; i++) {
            _allAdmins[i] = superAdminAddresses[i];
        }

        return _allAdmins;
    }

    // --- HELPERS ---
    // Helper function to get the month from a Unix timestamp
    function getMonth(uint256 timestamp) private pure returns (uint256) {
        return timestamp / 1 days / 30;
    }
}