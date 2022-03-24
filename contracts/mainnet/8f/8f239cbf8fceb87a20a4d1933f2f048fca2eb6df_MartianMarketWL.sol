/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/////////////////////////////////////////////////////////////////////////
//     __  ___         __  _             __  ___         __       __   //
//    /  |/  /__ _____/ /_(_)__ ____    /  |/  /__ _____/ /_____ / /_  //
//   / /|_/ / _ `/ __/ __/ / _ `/ _ \  / /|_/ / _ `/ __/  '_/ -_) __/  //
//  /_/  /_/\_,_/_/  \__/_/\_,_/_//_/ /_/  /_/\_,_/_/ /_/\_\\__/\__/   //
//                                                by 0xInuarashi.eth   //
/////////////////////////////////////////////////////////////////////////

/*
    Martian Market by 0xInuarashi for Message to Martians (Martians)
    A Fully functioning on-chain CMS system that can be tapped into front-ends
    and create a responsive website based on contract-specific databases.

    ** THIS IS A DECENTRALIZED AND TRUSTLESS WHITELIST MARKETPLACE CREATION SYSTEM **

    We chose not to use a proxy contract as multiple approvals have to be done
    for this contract. In this case, we chose the most decentralized approach
    which is to create an immutable contract with minimal owner access and 
    allow full control of contract owners' functions over their own database, 
    which is not editable or tamperable even by the Ownable owner themself.

    >>>> User Access <<<<

    For authorized controllers:
        
        Authorized controllers are able to: 
            - Create WL Vending Items 
            - Modify WL Vending Items 
    
    For ERC20 contract owners:

        Contract Owners are able to:
            - Register Project Info
            - Set Treasury Address
            - Manage Authorized Controllers
            - Add WL Vending Items
            - Modify WL Vending Items
            - Delete WL Vending Items 

    >>>> Interfacing <<<<<

    To draw a front-end interface:
    
        getAllEnabledContracts() - Enumerate all available contracts for selection
        (for contract-specific front-end interfaces, just pull data from your 
        contract only)
    
        getWLVendingItemsAll(address contract_) - Enumerate all vending items
        available for the contract. Supports over 1000 items in 1 call but
        if you get gas errors, use a pagination method instead.

        Pagination method: 
        getWLVendingItemsPaginated(address contract_, uint256 start_, uint256 end_)
        for the start_, generally you can use 0, and for end_, inquire from function
        getWLVendingItemsLength(address contract_)

    For interaction of users:

        purchaseWLVendingItem(address contract_, uint256 index_) can be used
        and automatically populated to the correct buttons for each WLVendingItem
        for that, an ethers.js call is invoked for the user to call the function
        which will transfer their ERC20 token and add them to the purchasers list

    For administration:

        setTreasuryAddress(address contract_, address treasury_) can only be set
        by the contract owner. For this, they are able to set where the ERC20 tokens
        from the whitelist marketplace sales go to. By default, this is 0x...dead
        effectively burning the tokens

        addWLVendingItem(address contract_, string calldata title_, 
        string calldata imageUri_, string calldata projectUri_,
        string calldata description_, uint32 amountAvailable_, uint32 deadline_,
        uint256 price_) is used to create a new WLVendingItem for your contract
        with the details as the input arguments stated.

        modifyWLVendingItem(address contract_, uint256 index_, 
        WLVendingItem memory WLVendingItem_) lets you modify a WLVendingItem.
        You have to pass in a tuple instead. Only use when necessary. Not
        recommended to use.

        deleteMostRecentWLVendingItem(address contract_) we use a .pop() for this so
        it can only delete the most recent item. For some mistakes that you made and
        want to erase them.

        manageController(address contract_, address operator_, bool bool_) is a special
        governance function which allows you to add controllers to the contract
        to do actions on your behalf. 
*/

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IERC20 {
    function owner() external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract MartianMarketWL is Ownable {

    // Governance
    IERC20 public MES = IERC20(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function setMES(address address_) external onlyOwner {
        MES = IERC20(address_);
    }

    // Setting the Governor
    address public governorAddress;
    address public registrationCollector;
    
    constructor() {
        governorAddress = msg.sender;
        registrationCollector = address(this);
    }

    uint256 public registrationPrice = 2000 ether; // 2000 $MES

    // Registry Fee Collector
    function withdrawMESfromContract(address receiver_) external onlyOwner {
        MES.transferFrom(address(this), receiver_, MES.balanceOf(address(this)));
    }
    function setRegistrationCollector(address collector_) external onlyOwner {
        registrationCollector = collector_;
    }

    // Governance Setup
    function setGovernorAddress(address governor_) external onlyOwner {
        governorAddress = governor_;
    }
    modifier onlyGovernor {
        require(msg.sender == governorAddress,
            "You are not the contract governor!");
        _;
    }
    function setRegistrationPrice(uint256 price_) external onlyOwner {
        registrationPrice = price_;
    }

    // Here be the core logic of WL Vending //
    struct ProjectInfo {
        string projectName;
        string tokenImageUri;
    }

    // Note: Add UNIX timestamp deadline (for active/past)
    struct WLVendingItem {
        string title;
        string imageUri;
        string projectUri;
        string description;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 deadline;
        uint256 price;
    }

    // Database of Project Info for ERC20
    mapping(address => ProjectInfo) public contractToProjectInfo;

    // Database of Vending Items for each ERC20
    mapping(address => WLVendingItem[]) public contractToWLVendingItems;
    
    // Database of Vending Items Purchasers for each ERC20
    mapping(address => mapping(uint256 => address[])) public contractToWLPurchasers;
    mapping(address => mapping(uint256 => mapping(address => bool))) public 
        contractToWLPurchased;

    function getWLPurchasersOf(address contract_, uint256 index_) external view 
    returns (address[] memory) { 
        return contractToWLPurchasers[contract_][index_];
    }

    // Database for Authorized Controllers of each ERC20 Contract
    mapping(address => mapping(address => bool)) public contractToControllersApproved;

    // Database for Receiver wallet of Project
    address internal burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => address) public contractToTreasuryAddress;
    function _getTreasury(address contract_) internal view returns (address) {
        return contractToTreasuryAddress[contract_] != address(0) ? 
            contractToTreasuryAddress[contract_] : burnAddress; 
    }

    // Database Entry for Project Infos
    function ownerSetContractToProjectInfo(address contract_, string calldata 
    projectName_, string calldata tokenImage_) external onlyOwner {
        contractToProjectInfo[contract_] = ProjectInfo(projectName_, tokenImage_);
        emit ProjectInfoPushed(contract_, msg.sender, projectName_, tokenImage_);
    }
    function registerProjectInfo(address contract_, string calldata projectName_,
    string calldata tokenImage_) external onlyContractOwner(contract_) {
        contractToProjectInfo[contract_] = ProjectInfo(projectName_, tokenImage_);
        emit ProjectInfoPushed(contract_, msg.sender, projectName_, tokenImage_);
    }

    // Database Entry for Enabled Addresses + Enumeration System //
    mapping(address => bool) public contractToEnabled;

    // Enumeration Tools 
    address[] public enabledContracts;
    mapping(address => uint256) public enabledContractsIndex;

    function getAllEnabledContracts() external view returns (address[] memory) {
        return enabledContracts;
    }
    function _addContractToEnum(address contract_) internal {
        enabledContractsIndex[contract_] = enabledContracts.length;
        enabledContracts.push(contract_);
    }
    function _removeContractFromEnum(address contract_) internal {
        uint256 _lastIndex = enabledContracts.length - 1;
        uint256 _currentIndex = enabledContractsIndex[contract_];

        // If the contract is not the last contract in the array
        if (_currentIndex != _lastIndex) {
            // Replace the to-be-deleted address with the last address
            address _lastAddress = enabledContracts[_lastIndex];
            enabledContracts[_currentIndex] = _lastAddress;
        }

        // Remove the last item
        enabledContracts.pop();
        // Delete the index
        delete enabledContractsIndex[contract_];
    }

    // Database Entry Tools
    function ownerSetContractToVending(address contract_, bool bool_) external
    onlyOwner {
        require(contractToEnabled[contract_] != bool_,
            "Contract Already Set as Boolean!");

        // Enum Tracking on bool_ statement
        contractToEnabled[contract_] = bool_;
        bool_ ? _addContractToEnum(contract_) : _removeContractFromEnum(contract_);
        emit ContractAdministered(contract_, msg.sender, bool_);
    }
    
    // Contract Registry
    function registerContractToVending(address contract_) external {
        require(msg.sender == IERC20(contract_).owner(),
            "You are not the Contract Owner!");
        require(!contractToEnabled[contract_],
            "Your contract has already been registered!");
        require(MES.balanceOf(msg.sender) > registrationPrice,
            "You don't have enough $MES!");
        
        MES.transferFrom(msg.sender, registrationCollector, registrationPrice);
        
        contractToEnabled[contract_] = true;
        _addContractToEnum(contract_);
        emit ContractRegistered(contract_, msg.sender, registrationPrice);
    }

    // Modifier of Authorization to Administrative Functions
    modifier onlyContractOwner (address contract_) {
        require(msg.sender == IERC20(contract_).owner(),
            "You are not the Contract Owner!");
        require(contractToEnabled[contract_],
            "Please register your Contract first!");
        _;
    }
    modifier onlyAuthorized (address contract_, address operator_) {
        require(contractToControllersApproved[contract_][operator_]
            || msg.sender == IERC20(contract_).owner(),
            "You are not Authorized for this ERC20 Contract!");
        _;
    }

    // Events
    event TreasuryManaged(address indexed contract_, address treasury_);
    event OperatorManaged(address indexed contract_, address operator_, bool bool_);
    event WLVendingItemAdded(address indexed contract_, string title_, string imageUri_,
        string projectUri_, string description_, uint32 amountAvailable_, 
        uint32 deadline_, uint256 price_);
    event WLVendingItemRemoved(address indexed contract_, address operator_,
        WLVendingItem item_);
    event WLVendingItemPurchased(address indexed contract_, uint256 index_, 
        address buyer_, WLVendingItem item_);
    event ContractRegistered(address indexed contract_, address registerer_,
        uint256 registrationPrice_);
    event ContractAdministered(address indexed contract_, address registerer_,
        bool bool_);
    event ProjectInfoPushed(address indexed contract_, address registerer_,
        string projectName_, string tokenImage_);
    event WLVendingItemModified(address indexed contract_, WLVendingItem before_,
        WLVendingItem after_);

    // Core Functions of WL Vending (Admin)
    function setTreasuryAddress(address contract_, address treasury_) external 
    onlyContractOwner(contract_) {
        contractToTreasuryAddress[contract_] = treasury_;
        emit TreasuryManaged(contract_, treasury_);
    }

    function manageController(address contract_, address operator_, bool bool_) 
    external onlyContractOwner(contract_) {
        contractToControllersApproved[contract_][operator_] = bool_;
        emit OperatorManaged(contract_, operator_, bool_);
    }

    function addWLVendingItem(address contract_, string calldata title_, 
    string calldata imageUri_, string calldata projectUri_, 
    string calldata description_, uint32 amountAvailable_, 
    uint32 deadline_, uint256 price_) external 
    onlyAuthorized(contract_, msg.sender) {
        require(bytes(title_).length > 0,
            "You must specify a Title!");
        require(uint256(deadline_) > block.timestamp,
            "Already expired timestamp!");

        contractToWLVendingItems[contract_].push(
            WLVendingItem(
                title_,
                imageUri_,
                projectUri_,
                description_,
                amountAvailable_,
                0,
                deadline_,
                price_
            )
        );
        emit WLVendingItemAdded(contract_, title_, imageUri_, projectUri_, description_,
        amountAvailable_, deadline_, price_);
    }
    function modifyWLVendingItem(address contract_, uint256 index_,
    WLVendingItem memory WLVendingItem_) external 
    onlyAuthorized(contract_, msg.sender) {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");
        
        contractToWLVendingItems[contract_][index_] = WLVendingItem_;
        emit WLVendingItemModified(contract_, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem(address contract_) external
    onlyAuthorized(contract_, msg.sender) {
        uint256 _lastIndex = contractToWLVendingItems[contract_].length - 1;

        WLVendingItem memory _item = contractToWLVendingItems[contract_][_lastIndex];

        require(_item.amountPurchased == 0,
            "Cannot delete item with already bought goods!");
        
        contractToWLVendingItems[contract_].pop();
        emit WLVendingItemRemoved(contract_, msg.sender, _item);
    }

    // Core Function of WL Vending (User)
    function purchaseWLVendingItem(address contract_, uint256 index_) external {
        
        // Load the WLVendingItem to Memory
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        // Check the necessary requirements to purchase
        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(_item.amountAvailable > _item.amountPurchased,
            "No more WL remaining!");
        require(_item.deadline > block.timestamp,
            "Passed deadline!");
        require(!contractToWLPurchased[contract_][index_][msg.sender], 
            "Already purchased!");
        require(IERC20(contract_).balanceOf(msg.sender) > _item.price,
            "Not enough tokens!");

        // Pay for the WL
        IERC20(contract_).transferFrom(
            msg.sender, _getTreasury(contract_), _item.price);
        
        // Add the address into the WL List 
        contractToWLPurchased[contract_][index_][msg.sender] = true;
        contractToWLPurchasers[contract_][index_].push(msg.sender);

        // Increment Amount Purchased
        contractToWLVendingItems[contract_][index_].amountPurchased++;

        emit WLVendingItemPurchased(contract_, index_, msg.sender, _item);
    }

    // Here be the core logic of CMS html element generation //
    function getWLVendingItemsAll(address contract_) external view 
    returns (WLVendingItem[] memory) {
        return contractToWLVendingItems[contract_];
    }
    function getWLVendingItemsLength(address contract_) external view 
    returns (uint256) {
        return contractToWLVendingItems[contract_].length;
    }
    function getWLVendingItemsPaginated(address contract_, uint256 start_, uint256 end_)
    external view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = contractToWLVendingItems[contract_][start_ + i];
        }

        return _items;
    }
}