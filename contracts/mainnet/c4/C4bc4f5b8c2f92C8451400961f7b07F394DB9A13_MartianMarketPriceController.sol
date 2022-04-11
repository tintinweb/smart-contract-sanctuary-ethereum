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
}

contract MartianMarketPriceController is Ownable {

    // Interface of MM
    IMartianMarket public MM = 
        IMartianMarket(0xFD8f4aC172457FD30Df92395BC69d4eF6d92eDd4);
    function setMM(address address_) external onlyOwner {
        MM = IMartianMarket(address_);
    }

    // This is the lookup for price overrides
    mapping(address => mapping(uint256 => uint256)) public contractToIndexToPriceType;

    function getPriceOfItem(address contract_, uint256 index_) public view 
    returns (uint256) {
        if (contractToIndexToPriceType[contract_][index_] == 0) {
            return MM.getFixedPriceOfItem(contract_, index_);
        }
        else {
            revert("Override Unsupported!");
        }
    }
}