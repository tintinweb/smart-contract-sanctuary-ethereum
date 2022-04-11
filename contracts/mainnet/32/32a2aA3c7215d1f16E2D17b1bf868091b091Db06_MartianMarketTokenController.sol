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

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IMartianMarket {
    // For Access Control
    function isAuthorized(address contract_, address operator_) external 
    view returns (bool);

    // For Price Controller
    function getFixedPriceOfItem(address contract_, uint256 index_) external 
    view returns (uint256);

    // For Token Controller
    function getDefaultTokenOfContract(address contract_) external 
    view returns (address);
    function getDefaultTokenNameOfContract(address contract_) external
    view returns (string memory);
    function getDefaultTokenImageOfContract(address contract_) external 
    view returns (string memory);
}

contract MartianMarketTokenController is Ownable {

    // Events
    event OverrideToken(address indexed contract_, address indexed operator_,
        uint256 index_, address token_);
    event SetOverride(address indexed operator_, bool bool_);
    event TokenEnabled(address indexed tokenAddress_, address indexed operator_,
        string tokenName_, string tokenImageUri_);
    event TokenDisabled(address indexed tokenAddress, address indexed operator_);

    // Interface of MM
    IMartianMarket public MM = 
        IMartianMarket(0xFD8f4aC172457FD30Df92395BC69d4eF6d92eDd4);
    function setMM(address address_) external onlyOwner {
        MM = IMartianMarket(address_);
    }

    // Ownable Override Permissions
    bool public overrideEnabled; // default as false

    function setOverrideEnabled(bool bool_) external onlyOwner {
        
        overrideEnabled = bool_; 

        emit SetOverride(msg.sender, bool_);
    }
    modifier onlyOverrideEnabled {
        require(overrideEnabled,
            "Token Overrides are not enabled!");
        _;
    }

    // This is access of token address through controllers
    modifier onlyAuthorized(address contract_, address operator_) {
        require(MM.isAuthorized(contract_, operator_),
            "You are not authorized!");
        _;
    }

    // This is the lookup for token overrides
    struct TokenInfo {
        string tokenName;
        string tokenImageUri;
        address tokenAddress;
    }

    mapping(address => TokenInfo) public contractToTokenInfo;
    mapping(address => mapping(uint256 => address)) public contractToIndexToToken;

    // Enabling Tokens
    function enableToken(address tokenAddress_, string calldata tokenName_, 
    string calldata tokenImageUri_) external onlyOwner {
        
        contractToTokenInfo[tokenAddress_] = TokenInfo(
            tokenName_,
            tokenImageUri_,
            tokenAddress_
        );

        emit TokenEnabled(tokenAddress_, msg.sender, tokenName_, tokenImageUri_);
    }
    function disableToken(address tokenAddress_) external onlyOwner {
        
        delete contractToTokenInfo[tokenAddress_];
        
        emit TokenDisabled(tokenAddress_, msg.sender);
    }

    // Override Token Info
    function overrideIndexToToken(address contract_, uint256 index_, 
    address tokenAddress_) external onlyAuthorized(contract_, msg.sender) 
    onlyOverrideEnabled {
        require(contractToTokenInfo[tokenAddress_].tokenAddress != address(0),
            "Token has not been enabled!");
        
        contractToIndexToToken[contract_][index_] = tokenAddress_;

        emit OverrideToken(contract_, msg.sender, index_, tokenAddress_);
    }

    // Read Token Info for Interfacing and Controlling
    function getTokenNameOfItem(address contract_, uint256 index_) public view
    returns (string memory) {
        address _token = contractToIndexToToken[contract_][index_];
        return _token == address(0) ? 
            MM.getDefaultTokenNameOfContract(contract_) :
            contractToTokenInfo[_token].tokenName;
    }
    function getTokenImageOfItem(address contract_, uint256 index_) public view
    returns (string memory) {
        address _token = contractToIndexToToken[contract_][index_];
        return _token == address(0) ? 
            MM.getDefaultTokenImageOfContract(contract_) :
            contractToTokenInfo[_token].tokenImageUri;
    }
    function getTokenOfItem(address contract_, uint256 index_) public view 
    returns (address) {
        address _token = contractToIndexToToken[contract_][index_];
        return _token == address(0) ? 
            MM.getDefaultTokenOfContract(contract_) :
            contractToTokenInfo[_token].tokenAddress;
    }
}