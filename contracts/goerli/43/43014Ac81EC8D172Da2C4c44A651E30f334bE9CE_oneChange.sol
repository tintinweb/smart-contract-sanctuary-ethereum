/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier:MIT
pragma solidity >=0.8.17 <=0.9.0;

contract oneChange {

    // This is the address of admin/contract creator likely to be state/central government, Only contract creator will add approved government officials
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    // struct to store details of a citizen
    struct userDetails {
        string userFullName;
        uint8 userAge; // User age, it is useful in tax calculations.
        uint8 userLevel; // 1: Citizen 2: People Representative like minister(MLA, MP, Chief minister, Prime minister) 3: Government Organisation 4: Private Organisation
        uint256 userAadharNumber; // Unique Id given by government - by which till now user is recognised uniquely.
        address userPayId; // blockchain public address from where user wants to pay taxes.
        uint256 userPincode; // suburb or location where user stays.
        bytes32 userOneChangeId; // new Unique id is assigned to every citizen: Which is generated when user registers.
        bool userStatus; // To check current status of this account, whether this account is available or not.
        string additionalInformation; // This is extra information to be stored on blockchain when account is closed we will write minimal reason for closing account, or we can store on IPFS and link it.
    }

    // struct to store tax details and salary or income details
    struct userTaxDetails {
        bytes32 userOneChangeId;
        uint256 userAnnualIncome; // annual income as per payslip
        uint256 userTaxToBePaid; // Calculated tax amount to be paid by the user as per user income and age - calculated and stored in this variable. 
        uint256 userTotalTaxPaid; // Total tax paid till date  
        uint256 userLastPaymentYear; // Used to calculate tax user has to pay. 
        bool userPaidTax; // whether user has paid tax this year
    }

    // Used to store overall details of all citizens where key is "oneChangeId"
    mapping (bytes32 => userDetails) private populationDetails;
    mapping (bytes32 => userTaxDetails) private populationTaxDetails;

    // Used to restore/recover user oneChnageId with the help of userAadharNumber or previous government unique id.
    mapping (uint256 => bytes32) private aadharMappedToOneChangeId;

    // Used to restore/recover user oneChangeId with the help of user tax PayId.
    mapping (address => bytes32) private payIdMappedToOneChangeId;

    // List of government officials who can add citizens to this project, government officials can only be appointed by admin.
    mapping (address => bool) private approvedGovernmentOfficials;

    // Counts population in the particular area
    mapping (uint256 => uint256) private populationCensusByPincode;

    // Modifier - Only admin or Contract creator
    modifier onlyAdmin() {
        require (msg.sender == admin, "Only admin can access this functionality.");
        _;
    }  

    // Modifier - only government officials
    modifier onlyGovtOfficials() {
        require (approvedGovernmentOfficials[msg.sender] == true, "Only government officials can call this method.");
        _;
    }

    // Function to add government officials
    function addGovernmentOfficals (address _newGovtOfficialAddress) public onlyAdmin {
        approvedGovernmentOfficials[_newGovtOfficialAddress] = true;
    }

    // Function to generate new oneChangeId
    function generateOneChangeId(uint256 _userAadharNumber) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_userAadharNumber));
    }

    // Function to calculate tax
    function calculateTaxAmount(uint256 _userAnnualIncome) internal pure returns (uint256) {
        // Tax calculations based only on user annual Income, but we can use user age as well, but for this calculations we have used only income
        if (_userAnnualIncome <= 18000){ return 0; }
        else if (_userAnnualIncome > 18000 && _userAnnualIncome <= 45000) { return ((_userAnnualIncome - 18000)*(19))/100;}
        else if (_userAnnualIncome > 45000 && _userAnnualIncome <= 120000) { return (((_userAnnualIncome - 45000)*(325))/1000 + 5092);}
        else if (_userAnnualIncome > 120000 && _userAnnualIncome <= 180000) { return (((_userAnnualIncome - 120000)*(37))/100 + 29467);}
        else { return (((_userAnnualIncome - 180000)*(45))/100 + 51667); }

        // Note: Formula is designed based on information from "https://www.hrblock.com.au/tax-academy/australian-income-tax-system"
    }

    // Function to add population details
    function addPopulationDetails (string calldata _userFullName, uint8 _userAge, uint8 _userLevel, uint256 _userAadharNumber, address _userPayId, uint256 _userPincode, uint256 _userAnnualIncome) public onlyGovtOfficials{
        // Generate UserOneChangeId for new user.
        bytes32 _newUserOneChangeId = generateOneChangeId(_userAadharNumber);

        // Create record of userDetails
        userDetails memory newUserDetails = userDetails({
            userFullName : _userFullName,
            userAge : _userAge,
            userLevel : _userLevel,
            userAadharNumber : _userAadharNumber,
            userPayId : _userPayId,
            userPincode : _userPincode,
            userOneChangeId : _newUserOneChangeId,
            userStatus : true,
            additionalInformation : ""
        });

        // Create record of tax details
        userTaxDetails memory newUserTaxDetails = userTaxDetails({
            userOneChangeId : _newUserOneChangeId,
            userAnnualIncome : _userAnnualIncome,
            userTotalTaxPaid : 0,
            userTaxToBePaid : calculateTaxAmount(_userAnnualIncome),
            userLastPaymentYear : 0,
            userPaidTax : false
        });

        // add newUserDetails record to population data
        populationDetails[_newUserOneChangeId] = newUserDetails;

        // add newUserTaxDetails record to population Tax Details
        populationTaxDetails[_newUserOneChangeId] = newUserTaxDetails;

        // Map the user aadhar address - Previous Unique Govt Id with newly generated One Change Id.
        aadharMappedToOneChangeId[_userAadharNumber] = _newUserOneChangeId;

        // Map the user payid with newly generated One Change Id.
        payIdMappedToOneChangeId[_userPayId] = _newUserOneChangeId;

        // Increment or update the population count by pincode - population census by pincode
        populationCensusByPincode[_userPincode]++;
    }

    // Functions to update details : Update user Full Name
    function updateUserFullName (string calldata _updUserFullName, bytes32 _userOneChangeId) public onlyGovtOfficials {
        userDetails storage updateUserDetails = populationDetails[_userOneChangeId];
        updateUserDetails.userFullName = _updUserFullName;
    }

    // Functions to update details : Update user Pay Id
    function updateUserPayId (address _updUserPayId, bytes32 _userOneChangeId) public onlyGovtOfficials {
        userDetails storage updateUserDetails = populationDetails[_userOneChangeId];
        address oldPayId = updateUserDetails.userPayId;
        updateUserDetails.userPayId = _updUserPayId;

        // delete old payid mapping
        payIdMappedToOneChangeId[oldPayId] = 0x00;

        // update payId to oneChangeId mapping
        payIdMappedToOneChangeId[_updUserPayId] = updateUserDetails.userOneChangeId;
    }

    // Functions to update details : Update user level
    function updateUserPayId (uint8 _userLevel, bytes32 _userOneChangeId) public onlyGovtOfficials {
        userDetails storage updateUserDetails = populationDetails[_userOneChangeId];
        updateUserDetails.userLevel = _userLevel;
    }

    // Function to update details: Update user pincode
    function updateUserPincode (uint256 _updUserPincode, bytes32 _userOneChangeId) public onlyGovtOfficials {     
        userDetails storage updateUserDetails = populationDetails[_userOneChangeId];
        uint256 previousPincode = updateUserDetails.userPincode;
        updateUserDetails.userPincode = _updUserPincode;

        // update population census by pincode
        populationCensusByPincode[previousPincode]--;
        populationCensusByPincode[_updUserPincode]++;
    }

    // Functions to update details: Update User annual Income
    function updateUserAnnualIncome (uint256 _updUserAnnualIncome, bytes32 _userOneChangeId) public onlyGovtOfficials {
        userTaxDetails storage updateUserTaxDetails = populationTaxDetails[_userOneChangeId];
        updateUserTaxDetails.userAnnualIncome = _updUserAnnualIncome;
        updateUserTaxDetails.userTaxToBePaid = calculateTaxAmount(_updUserAnnualIncome);
    }

    // function to retrive user OneChangeId
    function getOneChangeId(uint256 _userAadharNumber) public view returns (bytes32) {
        return (aadharMappedToOneChangeId[_userAadharNumber]);
    }

    // function to get tax information of an user profile - Directly loggedin user can access
    function getMyTaxProfile () public view returns (uint256, uint256, uint256, uint256, bool){
        bytes32 payeeOneChangeId = payIdMappedToOneChangeId[msg.sender];
        require (payeeOneChangeId != 0x000, "User with this PayId is not registered.");
        
        // If user is registered, then update the contract details
        userTaxDetails memory payeeTaxDetails = populationTaxDetails[payeeOneChangeId];
        return (payeeTaxDetails.userAnnualIncome, payeeTaxDetails.userTaxToBePaid, payeeTaxDetails.userTotalTaxPaid, payeeTaxDetails.userLastPaymentYear, payeeTaxDetails.userPaidTax);
    }

    // function to get tax information of an user profile - only govt official
    function getUserTaxProfile (address _userPayId) public onlyGovtOfficials view returns (uint256, uint256, uint256, uint256, bool) {
        bytes32 payeeOneChangeId = payIdMappedToOneChangeId[_userPayId];
        require (payeeOneChangeId != 0x000, "User with this PayId is not registered.");
        
        // If user is registered, then update the contract details
        userTaxDetails memory payeeTaxDetails = populationTaxDetails[payeeOneChangeId];
        return (payeeTaxDetails.userAnnualIncome, payeeTaxDetails.userTaxToBePaid, payeeTaxDetails.userTotalTaxPaid, payeeTaxDetails.userLastPaymentYear, payeeTaxDetails.userPaidTax);
    }

    // function to get user details - only govt official 
    function getRegisteredUserDetails (bytes32 _userOneChangeId) public onlyGovtOfficials view returns (string memory, uint8, uint8, uint256, address, uint256, bytes32, bool, string memory){
        // retriving details
        userDetails memory registeredUserDetails = populationDetails[_userOneChangeId];
        return (registeredUserDetails.userFullName, registeredUserDetails.userAge, registeredUserDetails.userLevel, registeredUserDetails.userAadharNumber, registeredUserDetails.userPayId, registeredUserDetails.userPincode, registeredUserDetails.userOneChangeId, registeredUserDetails.userStatus, registeredUserDetails.additionalInformation);
    }

    // function to pay taxes - automatically takes account names
    function wantToPayTax() public payable {
        bytes32 payeeOneChangeId = payIdMappedToOneChangeId[msg.sender];
        require (payeeOneChangeId != 0x000, "User with this PayId is not registered.");
        
        // check the account status
        userDetails memory payeeDetails = populationDetails[payeeOneChangeId];
        require (payeeDetails.userStatus == true, "Sorry, This user profile is closed");

        // If user is registered, then update the contract details
        userTaxDetails storage payeeTaxDetails = populationTaxDetails[payeeOneChangeId];
        
        // Checking whether tax amount to be paid is equal to paid amount
        require (payeeTaxDetails.userTaxToBePaid == msg.value, "Invalid funds, please check tax information");

        // if everything is perfect we are processing transaction        
        payeeTaxDetails.userTotalTaxPaid += msg.value;
        payeeTaxDetails.userLastPaymentYear = block.timestamp;
        payeeTaxDetails.userPaidTax = true;
    }

    // Function to close the account
    function lockAccount (bytes32 _userOneChangeId, address _userPayId) public onlyGovtOfficials {

        // Retriving records
        userDetails storage closingUserProfile = populationDetails[_userOneChangeId]; 

        // Checking given details
        require (closingUserProfile.userPayId == _userPayId, "Incorrect Information");

        closingUserProfile.userStatus = false;
        closingUserProfile.additionalInformation = "closed due to xxxxx reason";
    }

    // function to return govt balance
    function getGovtBalance () public view returns(uint256){
        return address(this).balance;
    }

    // ------------------ Functions that are called from another contract ------------------
    
    mapping (address => bool) private permissionedContracts;

    // modifier for permissioned contracts
    modifier onlyPermissionedContracts() {
        require(permissionedContracts[msg.sender] == true, "Caller contract doesn't has permission to access oneChange contract.");
        _;
    }

    // address of this contract
    function getThisContractAddress() public view returns (address) {
        return address(this);
    } 

    // function to update who can access current contracts data from external contracts - only admin
    function addPermissionedContracts (address _contractAddress) public onlyAdmin {
        permissionedContracts[_contractAddress] = true;
    }

    // function to return whether user has paid tax this year or not
    function getUserTaxPayStatus(address _payeeAddress) external onlyPermissionedContracts view returns(bool) {
        // Checking whether user with public address is registered in the system or not.
        bytes32 payeeOneChangeId = payIdMappedToOneChangeId[_payeeAddress];
        require (payeeOneChangeId != 0x000, "User with this PayId is not registered.");

        // if user exists we will check whether user paid tax or not
        userTaxDetails memory payeeTaxDetails = populationTaxDetails[payeeOneChangeId];
        if (block.timestamp - payeeTaxDetails.userLastPaymentYear <= 365 days && payeeTaxDetails.userPaidTax){ return true; }
        else { return false; }
    }

    // function to return userlevel
    function getUserLevel(address _payeeAddress) external onlyPermissionedContracts view returns (uint8){
        // checking whether user with this public address is registered in the system or not
        bytes32 payeeOneChangeId = payIdMappedToOneChangeId[_payeeAddress];
        require (payeeOneChangeId != 0x000, "User with this PayId is not registered.");

        //retriving the user details
        return populationDetails[payeeOneChangeId].userLevel;
    }

    // function to return population census in a particular area / pincode
    function getPopulationCensusByPincode(uint256 _pincode) external onlyPermissionedContracts view returns (uint256) {
        return populationCensusByPincode[_pincode];
    }
}