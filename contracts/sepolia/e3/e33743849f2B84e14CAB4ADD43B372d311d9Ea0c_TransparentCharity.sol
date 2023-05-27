//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import "./TCStoken.sol";

contract TransparentCharity {
    // TCStoken public token;
    // address public tokenContractAddress;

    struct Donor {
        string name;
        uint256 balance;
        address payable Address;
        mapping(uint256 => uint256) donations; // project ID => donation amount
        uint256[] transactionHistory;
    }

    struct CharityProject {
        address payable beneficiary;
        string name;
        string title;
        string desc;
        string image;
        uint256 goalAmount;
        uint256 currentAmount;
        //uint256 deadline;
        bool isActive;
        address[] donators;
        uint256[] donations;
    }

    struct Beneficiary {
        string name;
        string rescueInformation;
        // string[] documents;
        address payable Address;
        uint256 balance;
        // mapping(uint256 => uint256) etherUsage; // project ID => token usage
        uint256[] transactionHistory;
    }

    struct Product {
        string productId;
        string productName;
        uint256 price;
    }

    struct CooperativeStore {
        string storeName;
        address payable storeOwner;
        uint256 balance;
        mapping(string => Product) products;
        string[] productIds; // Maintain an array of product IDs
    }

    struct CharityOrg {
        string OrgName;
        address OrgAddress;
        string Desc;
        uint256 orgBalance;
    }

    CharityOrg public c;

    mapping(address => Donor) private donors;
    address[] private donorAddresses;

    mapping(address => Beneficiary) private beneficiaries;
    CooperativeStore public cooperativeStore;
    CharityProject[] private charityProjects;

    // Event emitted when a donation is made
    event DonationMade(
        address indexed donor,
        uint256 indexed projectId,
        uint256 amount
    );

    event ProjectApproved(
        address indexed beneficiary,
        uint256 indexed projectId
    );

    // Event emitted when tokens are exchanged for money
    event TokensExchangedForMoney(
        address indexed storeOwner,
        uint256 tokenAmount
    );

    event TokensAllocatedToBeneficiary(
        address indexed beneficiary,
        uint256 tokenAmount
    );

    event FundsDepositedToBeneficiary(
        address donor,
        uint256 indexed projectId,
        uint256 amount
    );

    event TokenSpentInStore(address beneficiary, uint256 amount);

    event FundsRefunded(address donor, uint256 amount);

    event CharityProjectUpdated(uint256 indexed projectId, bool isActive);

    // constructor() {
    //     //constructor

    //     token = TCStoken(0x3221F2317a265711f9eb990099f41cF79204A332);
    //     tokenContractAddress = token.getTokenAddress();
    // }

    //----------Donor Functions---------------------------------

    // Function to create an account for a donor
    function createDonorAccount(string memory _name) external {
        require(donors[msg.sender].balance == 0, "Account already exists.");
        donors[msg.sender].Address = payable(msg.sender);
        donors[msg.sender].balance = payable(msg.sender).balance;
        donors[msg.sender].name = _name;
        donorAddresses.push(msg.sender);
    }

    modifier onlyDonor() {
        require(
            donors[msg.sender].Address == msg.sender,
            "Only donor can call this function."
        );
        _;
    }

    function getDonorDetails()
        external
        view
        onlyDonor
        returns (
            string memory,
            uint256,
            address
        )
    {
        Donor storage donor = donors[msg.sender];
        return (donor.name, donor.balance, donor.Address);
    }

    // Function to deposit funds into a donor's account
    function depositFunds(uint256 amount) external payable onlyDonor {
        payable(msg.sender).transfer(amount);
        donors[msg.sender].balance += amount;
    }

    // Function to get the balance of a donor's account
    function getDonorAccountBalance()
        external
        view
        onlyDonor
        returns (uint256)
    {
        return donors[msg.sender].balance;
    }

    // Function to donate to a specific charity project
    function donateToProject(uint256 projectId) external payable onlyDonor {
        uint256 amount = msg.value;
        require(projectId < charityProjects.length, "Invalid project ID.");
        require(charityProjects[projectId].isActive, "Project is not active.");
        require(amount > 0, "Donation amount must be greater than zero.");
        require(donors[msg.sender].balance >= amount, "Insufficient funds.");

        // if (msg.value > amount) {
        //     // Excess funds, refund the excess to the donor
        //     uint256 refundAmount = msg.value - amount;
        //     donors[msg.sender].balance += refundAmount;
        //     payable(msg.sender).transfer(refundAmount);
        //     emit FundsRefunded(msg.sender, refundAmount);
        // }

        // uint256 etherAmount = msg.value;

        //payable(charityProjects[projectId].beneficiary).transfer(amount);

        (bool sent, ) = payable(charityProjects[projectId].beneficiary).call{
            value: amount
        }("");

        if (sent) {
            donors[msg.sender].balance -= amount;
            donors[msg.sender].donations[projectId] += amount;

            charityProjects[projectId].currentAmount += amount;
            charityProjects[projectId].donators.push(msg.sender);
            charityProjects[projectId].donations.push(amount);

            donors[msg.sender].transactionHistory.push(amount);
        } else {
            revert("Failed to send donation to the beneficiary.");
        }

        emit DonationMade(msg.sender, projectId, amount);
    }

    // Function to get the transaction history of a donor
    function getDonorTransactionHistory()
        external
        view
        onlyDonor
        returns (uint256[] memory)
    {
        return donors[msg.sender].transactionHistory;
    }

    //------------Beneficiary Functions-----------------------------------------------------

    // Function to create an account for a beneficiary
    function createBeneficiaryAccount(
        string memory _name,
        string memory _rescueInformation //address payable _address
    ) external {
        require(
            bytes(beneficiaries[msg.sender].name).length == 0,
            "Account already exists."
        );
        beneficiaries[msg.sender].name = _name;
        beneficiaries[msg.sender].rescueInformation = _rescueInformation;
        beneficiaries[msg.sender].Address = payable(msg.sender);
        beneficiaries[msg.sender].balance = payable(msg.sender).balance;
    }

    modifier onlyBeneficiary() {
        require(
            beneficiaries[msg.sender].Address == msg.sender,
            "Only beneficiary can call this function."
        );
        _;
    }

    function getBeneficiaryDetails()
        public
        view
        onlyBeneficiary
        returns (
            string memory,
            string memory,
            address,
            uint256
        )
    {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        return (
            beneficiary.name,
            beneficiary.rescueInformation,
            beneficiary.Address,
            beneficiary.balance
        );
    }

    // Function to update a beneficiary's rescue information
    function updateRescueInformation(string memory _rescueInformation)
        external
        onlyBeneficiary
    {
        beneficiaries[msg.sender].rescueInformation = _rescueInformation;
    }

    // // Function to upload a document or evidence for a beneficiary's project
    // function uploadDocument(string memory _document) external {
    //     beneficiaries[msg.sender].documents.push(_document);
    // }

    // Function to get the balance of a beneficiary's account
    function getBeneficiaryBalance()
        external
        view
        onlyBeneficiary
        returns (uint256)
    {
        return beneficiaries[msg.sender].balance;
    }

    // Function to show the transaction history of token usage and remaining balance
    function getBeneficiaryTransactionHistory()
        external
        view
        onlyBeneficiary
        returns (uint256[] memory)
    {
        return beneficiaries[msg.sender].transactionHistory;
    }

    // Function for beneficiaries to spend tokens in cooperative stores
    function spendTokens(string memory productId)
        external
        payable
        onlyBeneficiary
    {
        uint256 productPrice = cooperativeStore.products[productId].price;

        require(productPrice > 0, "Invalid product");

        require(
            beneficiaries[msg.sender].balance >= productPrice,
            "Insufficient ethers."
        );

        // require(msg.value== productPrice, "Wrong price of product");

        (bool sent, ) = payable(cooperativeStore.storeOwner).call{
            value: msg.value
        }("");

        if (sent) {
            beneficiaries[msg.sender].balance -= msg.value;
            beneficiaries[msg.sender].transactionHistory.push(msg.value);
            cooperativeStore.balance += msg.value;
        } else {
            revert("Failed to send payment to the store owner.");
        }
        emit TokenSpentInStore(msg.sender, msg.value);
    }

    // Function to deposit funds into a beneficiary's account
    // function depositFundsToBeneficiary(
    //     address _address,
    //     uint256 projectId,
    //     uint256 _amount
    // ) external payable {
    //     require(_amount > 0, "Amount must be greater than zero.");
    //     require(projectId < charityProjects.length, "Invalid project ID.");

    //     uint256 amount = _amount;

    //     // Mint ERC20 tokens to the beneficiary
    //     // token.mint(beneficiaries[msg.sender].Address, amount);

    //     beneficiaries[_address].balance += amount;

    //     // Update the project's current amount
    //     charityProjects[projectId].currentAmount += amount;

    //     payable(charityProjects[projectId].beneficiary).transfer(amount);

    //     // Emit an event to indicate the funds deposited
    //     emit FundsDepositedToBeneficiary(_address, projectId, amount);
    // }

    //-----------------Charity Project---------------------------------------------------

    // Function to create a charity project

    function createCharityProject(
        string memory _title,
        string memory _desc,
        string memory _image,
        //address payable _beneficiary,
        uint256 _goalAmount
    ) external onlyBeneficiary returns (uint256) {
        // require(
        //     beneficiaries[msg.sender].Address == _beneficiary,
        //     "Only beneficiary can create a project."
        // );

        CharityProject memory project;
        project.name = beneficiaries[msg.sender].name;
        project.title = _title;
        project.desc = _desc;
        project.image = _image;
        project.beneficiary = payable(msg.sender);
        project.goalAmount = _goalAmount;
        project.currentAmount = 0;
        project.isActive = false;
        uint256 projectId = charityProjects.length;
        charityProjects.push(project);
        return projectId;
    }

    function getCharityProjects()
        external
        view
        returns (CharityProject[] memory)
    {
        return charityProjects;
    }

    function getProjectDonators(uint256 projectId)
        external
        view
        returns (address[] memory)
    {
        require(charityProjects[projectId].isActive, "Invalid project");

        return charityProjects[projectId].donators;
    }

    function getApprovedProjects()
        external
        view
        returns (CharityProject[] memory)
    {
        uint256 approvedCount = 0;
        for (uint256 i = 0; i < charityProjects.length; i++) {
            if (charityProjects[i].isActive) {
                approvedCount++;
            }
        }

        CharityProject[] memory approvedProjects = new CharityProject[](
            approvedCount
        );
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < charityProjects.length; i++) {
            if (charityProjects[i].isActive) {
                approvedProjects[currentIndex] = charityProjects[i];
                currentIndex++;
            }
        }

        return approvedProjects;
    }

    // ---------------------- Cooperative Store Section --------------------------------------------

    modifier onlyStoreOwner() {
        require(
            msg.sender == cooperativeStore.storeOwner,
            "Only store owner can call this function"
        );
        _;
    }

    function createCooperativeStore(string memory _storeName) external {
        require(
            cooperativeStore.storeOwner == address(0),
            "Store already exists."
        );

        cooperativeStore.storeName = _storeName;
        cooperativeStore.storeOwner = payable(msg.sender);
        cooperativeStore.balance = payable(msg.sender).balance;
    }

    function getCooperativeStoreDetails()
        external
        view
        returns (
            string memory storeName,
            address payable storeOwner,
            uint256 balance,
            string[] memory productIds
        )
    {
        return (
            cooperativeStore.storeName,
            cooperativeStore.storeOwner,
            cooperativeStore.balance,
            cooperativeStore.productIds
        );
    }

    function addProduct(
        string memory productId,
        string memory productName,
        uint256 price
    ) external onlyStoreOwner {
        require(
            cooperativeStore.products[productId].price == 0,
            "Product already exists"
        );

        Product memory newProduct = Product(productId, productName, price);
        cooperativeStore.products[productId] = newProduct;
        cooperativeStore.productIds.push(productId); // Add the product ID to the array
    }

    function getProduct(string memory productId)
        external
        view
        returns (Product memory)
    {
        return cooperativeStore.products[productId];
    }

    function getAllProducts() external view returns (Product[] memory) {
        CooperativeStore storage store = cooperativeStore;
        uint256 productCount = store.productIds.length;
        Product[] memory products = new Product[](productCount);

        uint256 index = 0;
        for (uint256 i = 0; i < productCount; i++) {
            string memory productId = store.productIds[i];
            Product memory product = store.products[productId];
            products[index] = product;
            index++;
        }

        return products;
    }

    //---------Charity Organization--------------------
    // Function to create or log in to the charity organization account
    function createOrganization(
        string memory orgName,
        string memory description
    ) external {
        require(
            c.OrgAddress == address(0),
            "Charity organization already exists."
        );

        c = CharityOrg({
            OrgName: orgName,
            OrgAddress: payable(msg.sender),
            Desc: description,
            orgBalance: payable(msg.sender).balance
        });
    }

    modifier onlyOrganization() {
        require(
            msg.sender == c.OrgAddress,
            "Only Charity Organization can call this function"
        );
        _;
    }

    // Function to create or update a charity project
    // function updateCharityProject(
    //     uint256 _projectId,
    //     string memory _beneficiaryName,
    //     string memory _projectTitle,
    //     string memory _projectDesc,
    //     string memory _projectImg,
    //     uint256 _goalAmount,
    //     address payable _receiver
    // ) external onlyOrganization {
    //     require(_projectId < charityProjects.length, "Invalid project ID.");

    //     CharityProject storage project = charityProjects[_projectId];
    //     project.name = _beneficiaryName;
    //     project.title = _projectTitle;
    //     project.desc = _projectDesc;
    //     project.image = _projectImg;
    //     project.goalAmount = _goalAmount;
    //     project.beneficiary = _receiver;

    //     emit CharityProjectUpdated(_projectId, project.isActive);
    // }

    // Function to review and approve beneficiary projects
    function approveBeneficiaryProject(uint256 projectId, bool approve)
        external
        onlyOrganization
    {
        require(projectId < charityProjects.length, "Invalid project ID.");

        CharityProject storage project = charityProjects[projectId];
        require(!project.isActive, "Project is already active.");

        if (approve) {
            project.isActive = true;
        }

        emit CharityProjectUpdated(projectId, project.isActive);
    }

    function checkProjectCompletion(uint256 projectId) external {
        require(projectId < charityProjects.length, "Invalid project ID");

        CharityProject storage project = charityProjects[projectId];

        require(project.isActive, "Project is already inactive");

        if (project.currentAmount == project.goalAmount) {
            project.isActive = false;
        }
    }

    // Function to get the status and progress of an ongoing project
    function getProjectStatus(uint256 projectId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            bool
        )
    {
        require(projectId < charityProjects.length, "Invalid project ID.");

        CharityProject storage project = charityProjects[projectId];

        return (
            project.name,
            project.title,
            project.desc,
            project.image,
            project.goalAmount,
            project.currentAmount,
            project.beneficiary,
            project.isActive
        );
    }
}