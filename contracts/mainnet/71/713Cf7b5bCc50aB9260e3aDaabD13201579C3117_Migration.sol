/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
   
}
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Migration is Ownable{
    IERC20 public tokenToMigrateAddress = IERC20(0xa83055eaa689E477e7b2173eD7E3b55654b3A1f0); 
    IERC20 public newToken = IERC20(0x6bb570C82C493135cc137644b168743Dc1F7eb12);
    mapping (address => bool) public admins;
    mapping(address => bool) public isWhitelisted;
    bool private migrationActive = true;
    event userAdded(address addedAddress,uint256 timestamp,address author);
    event tokensMigrated(uint256 tokensMigrated, address userMigrated,uint256 timestamp);
     function addAdmin(address newAdmin) public onlyOwner{
        admins[newAdmin]=true;
    }

    function addToWhitelistAdmin(address newAddress) external{
        require(admins[msg.sender]==true,"Only admin function");
        isWhitelisted[newAddress]=true;
        emit userAdded(newAddress, block.timestamp, msg.sender);

    }
    function addToWhitelistOwner(address newAddress) public onlyOwner{
    isWhitelisted[newAddress]=true;
    emit userAdded(newAddress, block.timestamp, msg.sender);

    }
    function migrateTokens(uint256 tokenAmount)public{
        require(migrationActive,"migration not in progress come back soon");
        require(isWhitelisted[msg.sender],"You are not in the list");
        require(tokenToMigrateAddress.balanceOf(msg.sender)>0,"Cant migrate not enough funds");
        tokenToMigrateAddress.transferFrom(msg.sender,address(this),tokenAmount);
        newToken.transfer(msg.sender,tokenAmount);
        emit tokensMigrated(tokenAmount, msg.sender, block.timestamp);
    }
    function whitelistMultipleAddresses(address [] memory accounts, bool isWhitelist) public onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = isWhitelist;
        }
    }
    function returnCurrentTokenBalance()public view returns(uint256){
        return newToken.balanceOf(address(this));
    }
    function sendOldTokensToAddress(address payable destination,IERC20 tokenAddress) public onlyOwner{
        //require(tokenAddress.balanceOf(address(this))>0,"not enough balance here");
        uint256 currentTokens = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(destination,currentTokens);
    }
    function checkIfWhitelisted(address newAddress)public view returns (bool){
        return isWhitelisted[newAddress];

    }
    function updateNewToken(IERC20 updateToken) public onlyOwner{
        newToken = IERC20(updateToken);

    }
      function updatetokenToMigrate(IERC20 updateToken) public onlyOwner{
        tokenToMigrateAddress = IERC20(updateToken);

    }
    function pauseMigration(bool _isPaused) public onlyOwner{
        migrationActive=_isPaused;
    }
     function pauseMigrationAdmin(bool _isPaused) public onlyOwner{
         require(admins[msg.sender],"Only admin function");
         migrationActive=_isPaused;
    }
    function isMigrationActive() public view returns(bool){
        return migrationActive;
    }




}