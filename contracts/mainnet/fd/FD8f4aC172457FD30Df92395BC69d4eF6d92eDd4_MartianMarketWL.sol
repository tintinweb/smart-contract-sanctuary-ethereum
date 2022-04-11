/**
 *Submitted for verification at Etherscan.io on 2022-04-10
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

    >>>> Governance Model <<<<

        Ownable Owner 
            - Set Super Governor Address
            - Renounce Super Governor Address (1-way)
            - Set Governor Address
            - Set $MES Address 

        Super Governor
            - Enable / Disable Projects
            - Set Project Infos 
            - Unstuck Owners (On Super Governor Enabled Projects Only)

        Governor
            - Set Registry Price
            - Set Registry Treasury Address
            - Withdraw $MES from Contract

        Contract Owner
            - Register Their Contract with $MES
            - Set Project Info
            - Set Treasury Address
            - Set Contract Controllers
            - Add Items 
            - Modify Items
            - Remove Items

        Contract Controller
            - Add Items 
            - Modify Items
            - Remove Items

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

/*
    Patch Notes:

     - start timestamp [/]

     - priceController? [/]
     - tokenController? [/]

     - multi-token support? [~] managed by TokenController
     - da module? [~] managed by PriceController
     - bid auction module? [~] managed by MarketBidder

     - public view of contract + override owner (controller) for interfaces [/]
     - owner of erc721 -> erc20 mapping for erc20 native token returns [/]

     - metadata url option? [~] front-end managed through title tag and then leaving
       everything else blank
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
    function transfer(address to_, uint256 amount_) external returns (bool);
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

interface IOwnable {
    function owner() external view returns (address);
}

interface IPriceController {
    function getPriceOfItem(address contract_, uint256 index_) external view
    returns (uint256);
}

interface ITokenController {
    function getTokenNameOfItem(address contract_, uint256 index_) external view
    returns (string memory);
    function getTokenImageOfItem(address contract_, uint256 index_) external view
    returns (string memory);
    function getTokenOfItem(address contract_, uint256 index_) external view
    returns (address);
}

contract MartianMarketWL is Ownable {

    // Events
    event TreasuryManaged(address indexed contract_, address indexed operator_,
        address treasury_);
    event TokenManaged(address indexed contract_, address indexed operator_,
        address token_);

    event OperatorManaged(address indexed contract_, address operator_, bool bool_);
    event MarketAdminManaged(address indexed contract_, address admin_, bool bool_);

    event GovernorUnstuckOwner(address indexed contract_, address indexed operator_,
        address unstuckOwner_);

    event WLVendingItemAdded(address indexed contract_, address indexed operator_,
        WLVendingItem item_);
    event WLVendingItemModified(address indexed contract_, address indexed operator_, 
        WLVendingItem before_, WLVendingItem after_);
    event WLVendingItemRemoved(address indexed contract_, address indexed operator_,
        WLVendingItem item_);
    event WLVendingItemPurchased(address indexed contract_, address indexed purchaser_, 
        uint256 index_, WLVendingObject object_);
    event WLVendingItemGifted(address indexed contract_, address indexed gifted_,
        uint256 index_, WLVendingObject object_);

    event ContractRegistered(address indexed contract_, address registerer_,
        uint256 registrationPrice_);
    event ContractAdministered(address indexed contract_, address registerer_,
        bool bool_);

    event ProjectInfoPushed(address indexed contract_, address registerer_,
        string projectName_, string tokenImage_);

    // Governance
    IERC20 public MES = 
        IERC20(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function O_setMES(address address_) external onlyOwner {
        MES = IERC20(address_);
    } // good

    ITokenController public TokenController = 
        ITokenController(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function O_setTokenController(address address_) external onlyOwner {
        TokenController = ITokenController(address_);
    } // good

    IPriceController public PriceController = 
        IPriceController(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function O_setPriceController(address address_) external onlyOwner {
        PriceController = IPriceController(address_);
    } // good

    // Setting the Governor - good
    address public superGovernorAddress;
    address public governorAddress;
    address public registrationCollector;
    
    constructor() {
        superGovernorAddress = msg.sender;
        governorAddress = msg.sender;
        registrationCollector = address(this);
    } 

    // Ownable Governance Setup - good
    function O_setSuperGovernorAddress(address superGovernor_) external onlyOwner {
        // If superGovernor has been renounced, it is never enabled again.
        require(superGovernorAddress != address(0),
            "Super Governor Access has been renounced");

        superGovernorAddress = superGovernor_;
    } 
    modifier onlySuperGovernor {
        require(msg.sender == superGovernorAddress,
            "You are not the contract super governor!");
        _;
    } 
    function O_setGovernorAddress(address governor_) external onlyOwner {
        governorAddress = governor_;
    }
    modifier onlyGovernor {
        require(msg.sender == governorAddress,
            "You are not the contract governor!");
        _;
    }

    // Project Control (Super Governor) - good
    mapping(address => address) contractToUnstuckOwner;

    function SG_SetContractToVending(address contract_, bool bool_) external
    onlySuperGovernor {
        require(contractToEnabled[contract_] != bool_,
            "Contract Already Set as Boolean!");

        // Set contract as enabled
        contractToEnabled[contract_] = bool_;
        
        // Enum Tracking on bool_ statement
        bool_ ? _addContractToEnum(contract_) : _removeContractFromEnum(contract_);
        
        emit ContractAdministered(contract_, msg.sender, bool_);
    }
    function SG_SetContractToProjectInfo(address contract_, string calldata 
    projectName_, string calldata tokenName_, string calldata tokenImage_) 
    external onlySuperGovernor {
        
        contractToProjectInfo[contract_] = ProjectInfo(
            projectName_, 
            tokenName_,
            tokenImage_
        );
        
        emit ProjectInfoPushed(contract_, msg.sender, projectName_, tokenImage_);
    }
    function SG_SetStuckOwner(address contract_, address unstuckOwner_) 
    external onlySuperGovernor {

        // Onboarding for ERC20 of non-initialized contracts
        // In case of renounced or unretrievable owners

        // I the contract was not enabled by the super governor, but 
        // through user registration by paying $MES, this function 
        // is forever disabled for them.
        require(!contractToMESRegistry[contract_],
            "Ownership has been proven through registration.");

        // For maximum trustlessness, this can only be used if there has never been
        // an item created in their store. Once they create an item, this effectively
        // proves ownership is intact and disables this ability forever.
        require(contractToWLVendingItems[contract_].length == 0,
            "Ownership has been proven.");
            
        contractToUnstuckOwner[contract_] = unstuckOwner_;

        // 2022-04-07 ~0xInuarashi removed this because it stucks on invalid owner()
        // emit GovernorUnstuckOwner(contract_, msg.sender, 
            // IERC20(contract_).owner(), unstuckOwner_);

        // 2022-04-07 ~0xInuarashi added this as no interface event
        emit GovernorUnstuckOwner(contract_, msg.sender, unstuckOwner_);
    }
    
    // Registry Control (Governor) - ok
    uint256 public registrationPrice = 2000 ether; // 2000 $MES
    function G_setRegistrationPrice(uint256 price_) external onlyGovernor {
        registrationPrice = price_;
    }
    function G_setRegistrationCollector(address collector_) external onlyGovernor {
        registrationCollector = collector_;
    }
    function G_withdrawMESfromContract(address receiver_) external onlyGovernor {
        // 2022-04-08 ~0xInuarashi using ERC20 transfer-from-self must use transfer
        // MES.transferFrom(address(this), receiver_, MES.balanceOf(address(this)));
        MES.transfer(receiver_, MES.balanceOf(address(this)));
    }

    // Registry Logic
    // Database Entry for Enabled Addresses + Enumeration System // - good
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

    // Registry (Contract Owner) - good
    mapping(address => bool) public contractToMESRegistry;

    function registerContractToVending(address contract_) external {
        require(msg.sender == IOwnable(contract_).owner(),
            "You are not the Contract Owner!");
        require(!contractToEnabled[contract_],
            "Your contract has already been registered!");
        require(MES.balanceOf(msg.sender) >= registrationPrice,
            "You don't have enough $MES!");
        
        MES.transferFrom(msg.sender, registrationCollector, registrationPrice);
        
        contractToEnabled[contract_] = true;
        contractToMESRegistry[contract_] = true;

        _addContractToEnum(contract_);
        
        emit ContractRegistered(contract_, msg.sender, registrationPrice);
    }

    // Contract Owner Governance Control - ok
    function contractOwner(address contract_) public view returns (address) { 
        // If there is a contractToUnstuckOwner, return that. otherwise, return Ownable
        return contractToUnstuckOwner[contract_] != address(0) ?
            contractToUnstuckOwner[contract_] : IOwnable(contract_).owner();
    }
    modifier onlyContractOwnerEnabled (address contract_) {
        require(msg.sender == contractOwner(contract_),
            "You are not the Contract Owner!");
        require(contractToEnabled[contract_],
            "Please register your Contract first!");
        _;
    }
    modifier onlyAuthorized (address contract_, address operator_) {
        require(contractToControllersApproved[contract_][operator_]
            || msg.sender == contractOwner(contract_),
            "You are not Authorized for this Contract!");
        require(contractToEnabled[contract_],
            "Contract is not enabled!");
        _;
    }

    // External Interface Access - ok
    function isContractOwner(address contract_, address sender_) public 
    view returns (bool) {
        return contractOwner(contract_) == sender_;    
    }
    function isAuthorized(address contract_, address operator_) public
    view returns (bool) {
        if (contractToControllersApproved[contract_][operator_]) return true;
        else return contractOwner(contract_) == operator_;
    }

    // Project Control (Contract Owner) - ok
    struct ProjectInfo {
        string projectName;
        string tokenName;
        string tokenImageUri;
    }
    
    mapping(address => ProjectInfo) public contractToProjectInfo;
    
    function registerProjectInfo(address contract_, string calldata projectName_,
    string calldata tokenName_, string calldata tokenImage_) 
    external onlyContractOwnerEnabled(contract_) {
    
        contractToProjectInfo[contract_] = ProjectInfo(
            projectName_, 
            tokenName_,
            tokenImage_
        );
    
        emit ProjectInfoPushed(contract_, msg.sender, projectName_, tokenImage_);
    }

    mapping(address => mapping(address => bool)) public contractToControllersApproved;
    
    function manageController(address contract_, address operator_, bool bool_) 
    external onlyContractOwnerEnabled(contract_) {

        contractToControllersApproved[contract_][operator_] = bool_;
        
        emit OperatorManaged(contract_, operator_, bool_);
    }

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => address) public contractToTreasuryAddress;
    
    function getTreasury(address contract_) public view returns (address) {
        // if contractToTreasuryAddress is set, use that, otherwise, burnAddress
        return contractToTreasuryAddress[contract_] != address(0) ? 
            contractToTreasuryAddress[contract_] : burnAddress; 
    }
    function setTreasuryAddress(address contract_, address treasury_) external 
    onlyContractOwnerEnabled(contract_) {

        contractToTreasuryAddress[contract_] = treasury_;

        emit TreasuryManaged(contract_, msg.sender, treasury_);
    }

    // Whitelist Marketplace - ok
    struct WLVendingItem {
        string title; // for metadata uri, set title to metadata uri instead
        string imageUri;
        string projectUri;
        string description;

        uint32 amountAvailable;
        uint32 amountPurchased;

        uint32 startTime;
        uint32 endTime;
        
        uint256 price;
    }

    // Database of Vending Items for each ERC20
    mapping(address => WLVendingItem[]) public contractToWLVendingItems;
    
    // Database of Vending Items Purchasers for each ERC20
    mapping(address => mapping(uint256 => address[])) public contractToWLPurchasers;
    mapping(address => mapping(uint256 => mapping(address => bool))) public 
        contractToWLPurchased;

    function addWLVendingItem(address contract_, WLVendingItem memory WLVendingItem_)
    external onlyAuthorized(contract_, msg.sender) {
        require(bytes(WLVendingItem_.title).length > 0,
            "You must specify a Title!");
        require(uint256(WLVendingItem_.endTime) > block.timestamp,
            "Already expired timestamp!");
        require(WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime > startTime!");
        
        // Make sure that amountPurchased on adding is always 0
        WLVendingItem_.amountPurchased = 0;

        // Push the item to the database array
        contractToWLVendingItems[contract_].push(WLVendingItem_);
        
        emit WLVendingItemAdded(contract_, msg.sender, WLVendingItem_);
    }

    function modifyWLVendingItem(address contract_, uint256 index_,
    WLVendingItem memory WLVendingItem_) external 
    onlyAuthorized(contract_, msg.sender) {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(bytes(WLVendingItem_.title).length > 0,
            "Title must not be empty!");
        
        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");
        
        contractToWLVendingItems[contract_][index_] = WLVendingItem_;
        
        emit WLVendingItemModified(contract_, msg.sender, _item, WLVendingItem_);
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

    // Core Function of WL Vending (User) - ok
    // ~0xInuarashi @ 2022-04-08
    // As of Martian Market V2 this uses PriceController and TokenController values.
    // We wrap it all in a WLVendingObject item which aggregates WLVendingItem data
    function purchaseWLVendingItem(address contract_, uint256 index_) external {
        
        // Load the WLVendingObject to Memory
        WLVendingObject memory _object = getWLVendingObject(contract_, index_);

        // Check the necessary requirements to purchase
        require(bytes(_object.title).length > 0,
            "This WLVendingObject does not exist!");
        require(_object.amountAvailable > _object.amountPurchased,
            "No more WL remaining!");
        require(_object.startTime <= block.timestamp,
            "Not started yet!");
        require(_object.endTime >= block.timestamp,
            "Past deadline!");
        require(!contractToWLPurchased[contract_][index_][msg.sender], 
            "Already purchased!");
        require(_object.price != 0,
            "Item does not have a set price!");
        require(IERC20(contract_).balanceOf(msg.sender) >= _object.price,
            "Not enough tokens!");

        // Pay for the WL
        IERC20( _object.tokenAddress ) // aggregated thru TokenController
        .transferFrom(msg.sender, getTreasury(contract_), _object.price);
        
        // Add the address into the WL List 
        contractToWLPurchased[contract_][index_][msg.sender] = true;
        contractToWLPurchasers[contract_][index_].push(msg.sender);

        // Increment Amount Purchased
        contractToWLVendingItems[contract_][index_].amountPurchased++;

        emit WLVendingItemPurchased(contract_, msg.sender, index_, _object);
    }

    // Governance / Ownable Functions Related to Marketplace - ok
    // ~0xInuarashi 2022-04-11 - this is for something like bidding style 
    //  auction, gifting, etc and generally a good thing to include 
    //  for future interfaces.
    mapping(address => mapping(address => bool)) public contractToMarketAdminsApproved;

    function manageMarketAdmin(address contract_, address operator_, bool bool_) 
    external onlyContractOwnerEnabled(contract_) {

        contractToMarketAdminsApproved[contract_][operator_] = bool_;
        
        emit MarketAdminManaged(contract_, operator_, bool_);
    }

    modifier onlyMarketAdmin (address contract_, address operator_) {
        require(contractToMarketAdminsApproved[contract_][operator_]
            || msg.sender == contractOwner(contract_),
            "You are not a Market Admin!");
        require(contractToEnabled[contract_],
            "Contract is not enabled!");
        _;
    }

    function giftPurchaserAsMarketAdmin(address contract_, uint256 index_,
    address giftedAddress_) external onlyMarketAdmin(contract_, msg.sender) {

        // Load the WLVendingObject to Memory
        WLVendingObject memory _object = getWLVendingObject(contract_, index_);

        // Check the necessary requirements to gift
        require(bytes(_object.title).length > 0,
            "This WLVendingObject does not exist!");
        require(_object.amountAvailable > _object.amountPurchased,
            "No more WL remaining!");
        require(!contractToWLPurchased[contract_][index_][giftedAddress_],
            "Already added!");

        // Add the address into the WL List
        contractToWLPurchased[contract_][index_][giftedAddress_] = true;
        contractToWLPurchasers[contract_][index_].push(giftedAddress_);

        // Increment Amount Purchased
        contractToWLVendingItems[contract_][index_].amountPurchased++;

        emit WLVendingItemGifted(contract_, giftedAddress_, index_, _object);
    }

    // External Interface Communication
    function getFixedPriceOfItem(address contract_, uint256 index_) external 
    view returns (uint256) {
        return contractToWLVendingItems[contract_][index_].price;
    }
    function getDefaultTokenOfContract(address contract_) external 
    pure returns (address) {
        return contract_;
    }
    function getDefaultTokenNameOfContract(address contract_) external
    view returns (string memory) {
        return contractToProjectInfo[contract_].tokenName;
    }
    function getDefaultTokenImageOfContract(address contract_) external 
    view returns (string memory) {
        return contractToProjectInfo[contract_].tokenImageUri;
    }

    // Read Functions

    struct WLVendingObject {
        string title;
        string imageUri;
        string projectUri;
        string description;
        
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;

        string tokenName;
        string tokenImageUri;
        address tokenAddress;

        uint256 price;
    }

    function getWLPurchasersOf(address contract_, uint256 index_) public view 
    returns (address[] memory) { 
        return contractToWLPurchasers[contract_][index_];
    }

    // Generally, this is the go-to read function for front-end interface to call
    // getWLVendingObjectsPaginated
    function getWLVendingItemsLength(address contract_) public view 
    returns (uint256) {
        return contractToWLVendingItems[contract_].length;
    }

    function raw_getWLVendingItemsAll(address contract_) public view 
    returns (WLVendingItem[] memory) {
        return contractToWLVendingItems[contract_];
    }
    function raw_getWLVendingItemsPaginated(address contract_, uint256 start_, 
    uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = contractToWLVendingItems[contract_][start_ + i];
        }

        return _items;
    }

    // Generally, this is the go-to read function for front-end interfaces.
    function getWLVendingObject(address contract_, uint256 index_) public 
    view returns (WLVendingObject memory) {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];
        WLVendingObject memory _object = WLVendingObject(
            _item.title,
            _item.imageUri,
            _item.projectUri,
            _item.description,

            _item.amountAvailable,
            _item.amountPurchased,
            _item.startTime,
            _item.endTime,

            TokenController.getTokenNameOfItem(contract_, index_),
            TokenController.getTokenImageOfItem(contract_, index_),
            TokenController.getTokenOfItem(contract_, index_),

            PriceController.getPriceOfItem(contract_, index_)
        );
        return _object;
    }

    function getWLVendingObjectsPaginated(address contract_, uint256 start_, 
    uint256 end_) public view returns (WLVendingObject[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingObject[] memory _objects = new WLVendingObject[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {

            uint256 _itemIndex = start_ + i;
            
            WLVendingItem memory _item = contractToWLVendingItems[contract_][_itemIndex];
            WLVendingObject memory _object = WLVendingObject(
                _item.title,
                _item.imageUri,
                _item.projectUri,
                _item.description,

                _item.amountAvailable,
                _item.amountPurchased,
                _item.startTime,
                _item.endTime,

                TokenController.getTokenNameOfItem(contract_, (_itemIndex)),
                TokenController.getTokenImageOfItem(contract_, (_itemIndex)),
                TokenController.getTokenOfItem(contract_, (_itemIndex)),

                PriceController.getPriceOfItem(contract_, (_itemIndex))
            );

            _objects[_index++] = _object;
        }

        return _objects;
    }
}