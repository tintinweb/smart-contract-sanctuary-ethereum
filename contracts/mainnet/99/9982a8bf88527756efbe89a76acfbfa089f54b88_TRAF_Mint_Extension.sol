/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
// Developed by Orcania (https://orcania.io/)
// For TRAF Ep3 mint (https://theredapefamily.com/mint)
pragma solidity =0.7.6;

interface ITRAF {

    function adminMint(address to, uint256 amount) external;

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns(uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

}

abstract contract OMS { //Orcania Management Standard

    address private _owner;
    mapping(address => bool) private _manager;

    event OwnershipTransfer(address indexed newOwner);
    event SetManager(address indexed manager, bool state);

    receive() external payable {}
    
    constructor() {
        _owner = msg.sender;
        _manager[msg.sender] = true;

        emit SetManager(msg.sender, true);
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }

    modifier Manager() {
      require(_manager[msg.sender], "OMS: MOT_MANAGER");
      _;  
    }

    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }

    function manager(address user) external view returns(bool) {
        return _manager[user];
    }

    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

    function setManager(address user, bool state) external Owner {
        _manager[user] = state;
        emit SetManager(user, state);
    }

    //===============

    function withdraw(address payable to, uint256 value) external Manager {
        require(to.send(value), "OMS: ISSUE_SENDING_FUNDS");
    }

}

contract TRAF_Mint_Extension is OMS {

    ITRAF TRAF;
    uint256 private _startingTotalSupply; //TRAF total supply at the beginning of this mint

    uint256 private _availableMints; //Available amount of NFTs left to mint
    uint256 private _holdersReserve; //NFTs reserved for ep1 and ep2 holders

    //HM: Ep1-Ep2 Holders Mint
    mapping(address => uint256) private HM_Mints;
    uint256 private HM_User_Limit = 10; //User Mint Limit
    uint256 private HM_TotalMinted;
    uint256 private HM_Price = 250000000000000000;
    uint256 private HM_Active;

    //PRM: Prime Mint / Kind of like an early WL mint
    mapping(address => uint256) private PRM_Mints;
    mapping(address => uint256) private PRM_AllowListed;
    uint256 private PRM_User_Limit = 2; //User Mint Limit
    uint256 private PRM_Price = 350000000000000000;
    uint256 private PRM_Active;

    //GHM: General Holders Mint
    mapping(address => uint256) private GHM_Mints;
    uint256 private GHM_User_Limit; //User Mint Limit
    uint256 private GHM_Price;
    uint256 private GHM_Active;

    //PM: Partners Mint
    mapping(address => uint256) private PM_Mints;
    uint256 private PM_User_Limit = 2; //User Mint Limit
    uint256 private PM_Price = 350000000000000000;
    uint256 private PM_Active;

    //ALM: AllowList
    mapping(address => uint256) private ALM_AllowListed;
    mapping(address => uint256) private ALM_Mints;
    uint256 private ALM_User_Limit = 2; //User Mint Limit
    uint256 private ALM_Price = 350000000000000000;
    uint256 private ALM_Active;

    //PUM: Public Mint
    mapping(address => uint256) private PUM_Mints;
    uint256 private PUM_User_Limit = 2; //User Mint Limit
    uint256 private PUM_Price = 400000000000000000;
    uint256 private PUM_Active;

    mapping(address => uint256) private _partner; //If the following contract is partner or not

    constructor(address _traf, uint256 availableMints, uint256 holdersReserve) {
        TRAF = ITRAF(_traf);
        _availableMints = availableMints;
        _holdersReserve = holdersReserve;

        _startingTotalSupply = TRAF.totalSupply();
    }

    //Read Functions =================================================================================================================================

    function Get_HM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 totalMinted, uint256 price, bool active) {
        user_mints = HM_Mints[user];
        user_mint_limit = HM_User_Limit;
        totalMinted = HM_TotalMinted;
        price = HM_Price;
        active = HM_Active == 1;
    }

    function Get_PRM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 price, bool listed, bool active) {
        user_mints = PRM_Mints[user];
        user_mint_limit = PRM_User_Limit;
        price = PRM_Price;
        active = PRM_Active == 1;
        listed = PRM_AllowListed[user] == 1;
    }

    function Get_GHM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 price, bool active) {
        user_mints = GHM_Mints[user];
        user_mint_limit = GHM_User_Limit;
        price = GHM_Price;
        active = GHM_Active == 1;
    }

    function Get_PM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 price, bool active) {
        user_mints = PM_Mints[user];
        user_mint_limit = PM_User_Limit;
        price = PM_Price;
        active = PM_Active == 1;
    }

    function Get_ALM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 price, bool listed, bool active) {
        user_mints = ALM_Mints[user];
        user_mint_limit = ALM_User_Limit;
        price = ALM_Price;
        listed = ALM_AllowListed[user] == 1;
        active = ALM_Active == 1;
    }

    function Get_PUM_Data(address user) external view returns(uint256 user_mints, uint256 user_mint_limit, uint256 price, bool active) {
        user_mints = PUM_Mints[user];
        user_mint_limit = PUM_User_Limit;
        price = PUM_Price;
        active = PUM_Active == 1;
    }

    function Check_Partner(address partner) external view returns(bool) {
        return _partner[partner] == 1;
    }

    function Mints_Left() external view returns(uint256) {
        return _availableMints;
    }

    function General_Mints_Left() external view returns(uint256) {
        return _availableMints - HoldersReservedMints();
    }
    //Mints ==========================================================================================================================================

    function HM(uint256 NFT_ID /*ID of the ep1 or ep2 token this user holds*/) external payable{
        require(HM_Active == 1, "MINT_OFF");
        require(NFT_ID < 667, "NOT_HOLDER");
        require(TRAF.ownerOf(NFT_ID) == msg.sender, "NOT_HOLDER");

        uint256 price = HM_Price;
        require(msg.value % price == 0, "WRONG_VALUE");
        uint256 amount = msg.value / price;

        require((_availableMints -= amount) < 10000, "MINT_LIMIT_EXCEEDED");

        require((HM_Mints[msg.sender] += amount) <= HM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); //Total mints of 10 per wallet

        TRAF.adminMint(msg.sender, amount);
    }

    function PRM() external payable {
        require(PRM_Active == 1, "MINT_OFF");
        require(PRM_AllowListed[msg.sender] == 1, "NOT_ALLOW_LISTED");

        uint256 price = PRM_Price;
        require(msg.value % price == 0, "INVALID_MSG_VALUE");
        uint256 amount = msg.value / price;

        require(amount <= GeneralMintLeft(), "MINT_LIMIT_EXCEEDED");

        require((PRM_Mints[msg.sender] += amount) <= PRM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); // Toal mint of 2 per wallet

        _availableMints -= amount;

        TRAF.adminMint(msg.sender, amount);
    }

    function GHM(uint256 NFT_ID /*ID of the ep token this user holds cannot be the episode they are currently minting*/) external payable{
        require(GHM_Active == 1, "MINT_OFF");
        require(NFT_ID <= _startingTotalSupply, "NOT_HOLDER");
        require(TRAF.balanceOf(msg.sender) > 0, "NOT_HOLDER");

        uint256 price = GHM_Price;
        require(msg.value % price == 0, "WRONG_VALUE");
        uint256 amount = msg.value / price;

        require(amount <= GeneralMintLeft(), "MINT_LIMIT_EXCEEDED");
        
        require((GHM_Mints[msg.sender] += amount) <= GHM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); //Total mints of 10 per wallet

        _availableMints -= amount;

        TRAF.adminMint(msg.sender, amount);

    }

    function PM(address partner) external payable{
        require(PM_Active == 1, "MINT_OFF");
        require(_partner[partner] == 1, "NOT_PARTNER");
        require(ITRAF(partner).balanceOf(msg.sender) > 0, "NOT_PARTNER_HOLDER");

        uint256 price = PM_Price;
        require(msg.value % price == 0, "WRONG_VALUE");
        uint256 amount = msg.value / price;

        require(amount <= GeneralMintLeft(), "MINT_LIMIT_EXCEEDED");

        require((PM_Mints[msg.sender] += amount) <= PM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); //Total mints of 2 per wallet

        _availableMints -= amount;

        TRAF.adminMint(msg.sender, amount);

    }

    function ALM() external payable {
        require(ALM_Active == 1, "MINT_OFF");
        require(ALM_AllowListed[msg.sender] == 1, "NOT_ALLOW_LISTED");

        uint256 price = ALM_Price;
        require(msg.value % price == 0, "INVALID_MSG_VALUE");
        uint256 amount = msg.value / price;

        require(amount <= GeneralMintLeft(), "MINT_LIMIT_EXCEEDED");

        require((ALM_Mints[msg.sender] += amount) <= ALM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); // Toal mint of 2 per wallet

        _availableMints -= amount;

        TRAF.adminMint(msg.sender, amount);
    }

    function PUM() external payable {
        require(PUM_Active == 1, "MINT_OFF");

        uint256 price = PUM_Price;
        require(msg.value % price == 0, "INVALID_MSG_VALUE");
        uint256 amount = msg.value / price;

        require(amount <= GeneralMintLeft(), "MINT_LIMIT_EXCEEDED");

        require((PUM_Mints[msg.sender] += amount) <= PUM_User_Limit, "USER_MINT_LIMIT_EXCEEDED"); // Toal mint of 10 per wallet

        _availableMints -= amount;

        TRAF.adminMint(msg.sender, amount);
    }

    //Moderator Functions ==========================================================================================================================

    function Change_HM_Data(uint256 hm_User_Limit, uint256 hm_Price) external Manager {
        HM_User_Limit = hm_User_Limit;
        HM_Price = hm_Price;
    }

    function Change_PRM_Data(uint256 prm_User_Limit, uint256 prm_Price) external Manager {
        PRM_User_Limit = prm_User_Limit;
        PRM_Price = prm_Price;
    }

    function Change_GHM_Data(uint256 ghm_User_Limit, uint256 ghm_Price) external Manager {
        GHM_User_Limit = ghm_User_Limit;
        GHM_Price = ghm_Price;
    }

    function Change_PM_Data(uint256 pm_User_Limit, uint256 pm_Price) external Manager {
        PM_User_Limit = pm_User_Limit;
        PM_Price = pm_Price;
    }

    function Change_ALM_Data(uint256 alm_User_Limit, uint256 alm_Price) external Manager {
        ALM_User_Limit = alm_User_Limit;
        ALM_Price = alm_Price;
    }

    function Change_PUM_Data(uint256 pum_User_Limit, uint256 pum_Price) external Manager {
        PUM_User_Limit = pum_User_Limit;
        PUM_Price = pum_Price;
    }

    function Activate_Mint(uint256 hm_Active, uint256 prm_Active, uint256 ghm_Active, uint256 pm_Active, uint256 alm_Active, uint256 pum_Active) external Manager {
        HM_Active = hm_Active;
        GHM_Active = ghm_Active;
        PM_Active = pm_Active;
        ALM_Active = alm_Active;
        PUM_Active = pum_Active; 
        PRM_Active = prm_Active;
    }

    function Set_ALM_Users(address[] calldata users) external Manager {
        uint256 length = users.length;

        for(uint256 t=0; t < length; ++t) {
            ALM_AllowListed[users[t]] = 1;
        }
    }

    function Set_PRM_Users(address[] calldata users) external Manager {
        uint256 length = users.length;

        for(uint256 t=0; t < length; ++t) {
            PRM_AllowListed[users[t]] = 1;
        }
    }

    function Add_Partner(address partner) external Manager {
        _partner[partner] = 1;
    }

    function Remove_Partber(address partner) external Manager {
        _partner[partner] = 0;
    }

    function Increase_Mints(uint256 amount) external Manager {
        _availableMints += amount;
    }

    function Decrease_Mints(uint256 amount) external Manager {
        _availableMints -= amount;
    }

    //Internal Functions ===========================================================================================================================

    function HoldersReservedMints() internal view returns(uint256) {
        if(HM_TotalMinted >= _holdersReserve) {return 0;}
        else {return _holdersReserve - HM_TotalMinted;}
    }

    function GeneralMintLeft() internal view returns (uint256){
        return _availableMints - HoldersReservedMints();
    }

}