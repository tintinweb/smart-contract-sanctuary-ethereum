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
        uint256[] receiptIds; // Ids of receipts
    }

    // Struct representing a receipt
    struct Receipt {
        address company; // Address of the company that issued the receipt
        uint256 saleDate; // Sale date for the receipt
        string[] itemNames; // Name of the items
        uint256[] itemPrices; // Price of the items
        uint256[] itemQuantities; // Quantity of the items
        uint256 saleTotal; // Sale total price
    }

    // Struct representing an admin
    struct Admin {
        address adminId;
        bool isAdmin;
        bool isSuperAdmin;
    }

    // --- MAPPINGS ---
    // Mapping from company addresses to company structs
    mapping(address => Company) private companies;

    // Mapping from receipt IDs to receipt structs
    mapping(uint256 => Receipt) private receipts;

    // Mapping for roles
    mapping(address => Admin) private admins;

    // Track for total admins
    address[] private adminKeys;

    // Track for unapproved companies
    address[] private unapprovedCompanies;

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
    event AdminAdded(address indexed adminId, bool indexed isSuperAdmin);
    event AdminRemoved(address indexed adminId);

    // --- MODIFIERS ---
    // Modifier that only allows existing admins
    modifier onlyAdmin() {
        require(
            admins[msg.sender].isAdmin || msg.sender == owner,
            "Caller is not an admin"
        );
        _;
    }

    // Modifier that only allows super admins
    modifier onlySuperadmin() {
        require(
            admins[msg.sender].isSuperAdmin || msg.sender == owner,
            "Caller is not a superadmin"
        );
        _;
    }
    // Modifier that only allows existing admins or company owners
    modifier onlyAdminOrOwner(address _company) {
        require(
            admins[msg.sender].isAdmin || msg.sender == _company,
            "Only existing admin can perform this action"
        );
        _;
    }

    // --- FUNCTIONS ---
    // Assign roles during contract deployment
    constructor() {
        owner = msg.sender;

        // Assign roles to addresses
        addAdmin(msg.sender, true);
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

        unapprovedCompanies.push(msg.sender);

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

        for (uint256 i = 0; i < unapprovedCompanies.length; i++) {
            if (unapprovedCompanies[i] == _companyId) {
                unapprovedCompanies[i] = unapprovedCompanies[
                    unapprovedCompanies.length - 1
                ];
                unapprovedCompanies.pop();
                break;
            }
        }

        emit CompanyApproved(_companyId, msg.sender, block.timestamp);

        return true;
    }

    function getCompany(
        address _companyId
    ) public view returns (Company memory) {
        Company storage company = companies[_companyId];

        return company;
    }

    // Returns all admins
    function getUnapprovedCompanies() public view returns (Company[] memory) {
        Company[] memory result = new Company[](unapprovedCompanies.length);

        for (uint256 i = 0; i < unapprovedCompanies.length; i++) {
            result[i] = companies[unapprovedCompanies[i]];
        }

        return result;
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
        receipt.saleTotal = _saleAmount;

        // Update the company's sales
        company.totalSales += _saleAmount;
        company.receiptIds.push(receiptId);

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

    // Function to get all receipts of a company
    function getCompanyReceipts(
        address companyId
    ) public view returns (Receipt[] memory) {
        Company storage company = companies[companyId];

        Receipt[] memory result = new Receipt[](company.receiptIds.length);

        for (uint256 i = 0; i < company.receiptIds.length; i++) {
            Receipt storage receipt = receipts[company.receiptIds[i]];
            result[i] = receipt;
        }

        return result;
    }

    // SALES FUNCTIONS
    // Function to get total sales for a company
    function getTotalSales(address _company) public view returns (uint256) {
        return companies[_company].totalSales;
    }

    // ADMIN FUNCTIONS
    // Function to add a new admin
    function addAdmin(
        address _address,
        bool _isSuperAdmin
    ) public onlySuperadmin returns (address) {
        require(!admins[_address].isAdmin, "Admin already exist");

        admins[_address].adminId = _address;
        admins[_address].isSuperAdmin = _isSuperAdmin;
        admins[_address].isAdmin = true;

        adminKeys.push(_address);

        emit AdminAdded(_address, _isSuperAdmin);

        return _address;
    }

    // Function to remove an existing admin
    function removeAdmin(
        address _address
    ) public onlySuperadmin returns (address) {
        require(_address != msg.sender, "Cannot remove yourself");
        require(admins[_address].isAdmin, "Admin does not exist");

        for (uint256 i = 0; i < adminKeys.length; i++) {
            if (adminKeys[i] == _address) {
                adminKeys[i] = adminKeys[adminKeys.length - 1];
                adminKeys.pop();
                break;
            }
        }

        delete admins[_address];

        emit AdminRemoved(_address);

        return _address;
    }

    // Returns all admins
    function getAdmins() public view returns (Admin[] memory) {
        Admin[] memory result = new Admin[](adminKeys.length);

        for (uint256 i = 0; i < adminKeys.length; i++) {
            if (admins[adminKeys[i]].isAdmin) {
                result[i] = admins[adminKeys[i]];
            }
        }

        return result;
    }

    // --- HELPERS ---
    // Helper function to get the month from a Unix timestamp
    function getMonth(uint256 timestamp) private pure returns (uint256) {
        return timestamp / 1 days / 30;
    }
}