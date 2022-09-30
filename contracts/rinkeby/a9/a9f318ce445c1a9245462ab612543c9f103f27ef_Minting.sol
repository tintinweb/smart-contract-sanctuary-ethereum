/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//Developed by Orcania (https://orcania.io/)
pragma solidity ^0.7.6;

// Developed by Orcania (https://orcania.io/)
interface IERC20{
         
    function transfer(address recipient, uint256 amount) external;
    
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
        sendValue(to, value);  
    }

    function withdrawERC20(address token, address to, uint256 value) external Manager {
        IERC20(token).transfer(to, value);   
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "UNABLE_TO_SEND_VALUE RECIPIENT_MAY_HAVE_REVERTED");
    }

}
interface ICDS {
    function adminMint(address to, uint256 amount) external;
}

contract Minting is OMS {

    ICDS immutable CDS;

    uint256 private _wlPrice;
    uint256 private _wlUserMintLimit;
    bool private _wlActive;
    mapping(address => uint256) _wlUserMints; //Amount of mints performed by this user

    uint256 private _glPrice;
    uint256 private _glUserMintLimit;
    bool private _glActive;
    mapping(address => uint256) _glUserMints; //Amount of mints performed by this user

    uint256 private _pmPrice;
    uint256 private _pmUserMintLimit;
    bool private _pmActive;
    mapping(address => uint256) _pmUserMints; //Amount of mints performed by this user

    uint256 _maxSupply;

    constructor(address cds) {
        CDS = ICDS(cds);
    }

   //Read Functions===========================================================================================================================================================

   function wlData(address user) external view returns(uint256 userMints, uint256 price, uint256 userMintLimit, bool active) {
        userMints = _wlUserMints[user];
        price = _wlPrice;
        userMintLimit = _wlUserMintLimit;
        active = _wlActive;
    }
    
    function glData(address user) external view returns(uint256 userMints, uint256 price, uint256 userMintLimit, bool active) {
        userMints = _glUserMints[user];
        price = _glPrice;
        userMintLimit = _glUserMintLimit;
        active = _glActive;
    }

    function pmData(address user) external view returns(uint256 userMints, uint256 price, uint256 userMintLimit, bool active) {
        userMints = _pmUserMints[user];
        price = _pmPrice;
        userMintLimit = _pmUserMintLimit;
        active = _pmActive;
    }

    function maxSupply() external view returns(uint256) {return _maxSupply;}

    //Moderator Functions======================================================================================================================================================

    function setWlData(uint256 price, uint256 userMintLimit, bool active) external Manager {
        _wlPrice = price;
        _wlUserMintLimit = userMintLimit;
        _wlActive = active;
    }

    function setGlData(uint256 price, uint256 userMintLimit, bool active) external Manager {
        _glPrice = price;
        _glUserMintLimit = userMintLimit;
        _glActive = active;
    }

    function setPmData(uint256 price, uint256 userMintLimit, bool active) external Manager {
        _pmPrice = price;
        _pmUserMintLimit = userMintLimit;
        _pmActive = active;
    }

    function setMaxSupply(uint256 maxSupply) external Manager {
        _maxSupply = maxSupply;
    }

    //User Functions======================================================================================================================================================

    function wlMint() external payable {
        require(_wlActive, "MINT_NOT_ACTIVE");
        require(msg.value % _wlPrice == 0, "INVALID_AMOUNT");

        uint256 amount = msg.value / _wlPrice;

        require((_wlUserMints[msg.sender] += amount) <= _wlUserMintLimit, "MINT_LIMIT_EXCEEDED");

        CDS.adminMint(msg.sender, amount);
    }

    function glMint() external payable {
        require(_glActive, "MINT_NOT_ACTIVE");
        require(msg.value % _glPrice == 0, "INVALID_AMOUNT");

        uint256 amount = msg.value / _glPrice;

        require((_glUserMints[msg.sender] += amount) <= _glUserMintLimit, "MINT_LIMIT_EXCEEDED");

        CDS.adminMint(msg.sender, amount);
    }

    function pmMint() external payable {
        require(_pmActive, "MINT_NOT_ACTIVE");
        require(msg.value % _pmPrice == 0, "INVALID_AMOUNT");

        uint256 amount = msg.value / _pmPrice;

        require((_pmUserMints[msg.sender] += amount) <= _pmUserMintLimit, "MINT_LIMIT_EXCEEDED");

        CDS.adminMint(msg.sender, amount);
    }
}