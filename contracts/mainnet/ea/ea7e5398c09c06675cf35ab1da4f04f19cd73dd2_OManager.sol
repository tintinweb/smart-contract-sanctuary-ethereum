/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED
/*
   ___  __  __                                   
  / _ \|  \/  | __ _ _ __   __ _  __ _  ___ _ __ 
 | | | | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
 | |_| | |  | | (_| | | | | (_| | (_| |  __/ |   
  \___/|_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|   
                                 |___/                     
*/ 
contract OManager {
    address private owner;
    uint256 public tokenPrice = 500000000000000000; // 0.5 Eth
    uint256 public renewPrice = 300000000000000000; // 0.3 Eth
    uint256 public transferPrice = 30000000000000000; // 0.03 Eth
    uint256 public expirationPeriod = 15 days;
    bool public saleIsActive = false;
    uint256 public maxSupply = 10;
    string public appVersion;

    mapping(address => AllowedUserStruct) private _allowedUsersStructs;
    address[] _allowedUsersList;

    struct AllowedUserStruct {
        uint256 timestamp;
        uint256 listPointer;
    }

    mapping(address => KeyOwnerStruct) private _keyOwnersStructs;
    address[] _keyOwnersList;

    struct KeyOwnerStruct {
        uint256 listPointer;
        uint256 expiration;
    }

    constructor() {
        owner = msg.sender;
        ownerAllowUser(msg.sender);
        ownerAddKey(msg.sender);
        appVersion = "1.0.0";
    }

    modifier requireOwner() {
        require(owner == msg.sender, "not an owner");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller cannot be a contract");
        _;
    }

    function _isAllowedUser(address userAddress)
        private
        view
        returns (bool isIndeed)
    {
        if (_allowedUsersList.length == 0) return false;
        return (_allowedUsersList[
            _allowedUsersStructs[userAddress].listPointer
        ] == userAddress);
    }
    
    function _isKeyOwner(address ownerAddress)
        private
        view
        returns (bool isIndeed)
    {
        if (_keyOwnersList.length == 0) return false;
        return (_keyOwnersList[_keyOwnersStructs[ownerAddress].listPointer] ==
            ownerAddress);
    }

    function ownerGetAllowedUsers()
        public
        view
        requireOwner
        returns (address[] memory)
    {
        return _allowedUsersList;
    }
    
    function ownerGetKeys()
        public
        view
        requireOwner
        returns (address[] memory)
    {
        return _keyOwnersList;
    }

    function getAllowedUsersCount()
        public
        view
        requireOwner
        returns (uint256 usersCount)
    {
        return _allowedUsersList.length;
    }

    function getKeyOwnersCount()
        public
        view
        requireOwner
        returns (uint256 ownersCount)
    {
        return _keyOwnersList.length;
    }

    function ownerChangeTokenPrice(uint256 newPrice) external requireOwner returns (bool success){
        tokenPrice = newPrice;
        return true;
    }

    function ownerChangeRenewPrice(uint256 newPrice) external requireOwner returns (bool success){
        renewPrice = newPrice;
        return true;
    }

    function ownerChangeTransferPrice(uint256 newPrice) external requireOwner returns (bool success){
        transferPrice = newPrice;
        return true;
    }

    function ownerChangeExpirationPeriod(uint256 newPeriod) external requireOwner returns (bool success){
        expirationPeriod = newPeriod;
        return true;
    }

    function ownerChangeTokensAmount(uint256 newTokensAmount) external requireOwner returns (bool success){
        maxSupply = newTokensAmount;
        return true;
    }

    function ownerChangeAppVersion(string calldata newAppVersion) external requireOwner returns (bool success){
        appVersion = newAppVersion;
        return true;
    }

    function toggleSale() external requireOwner {
        saleIsActive = !saleIsActive;
    }

    function ownerAllowUser(address userAddress)
        public
        requireOwner
        returns (bool success)
    {
        if (_isAllowedUser(userAddress)) revert();
        _allowedUsersStructs[userAddress].timestamp = block.timestamp;
        _allowedUsersList.push(userAddress);
        _allowedUsersStructs[userAddress].listPointer =
            _allowedUsersList.length -
            1;
        return true;
    }

    function ownerRemovePermission(address userAddress)
        external
        requireOwner
        returns (bool success)
    {
        require(_isAllowedUser(userAddress), "User is not whitelisted");
        uint256 rowToDelete = _allowedUsersStructs[userAddress].listPointer;
        delete _allowedUsersStructs[userAddress];
        delete _allowedUsersList[rowToDelete];
        return true;
    }

    function ownerAddKey(address key)
        public
        requireOwner
        returns (bool success)
    {
        require(!_isKeyOwner(key), "Already key owner");
        _keyOwnersList.push(key);
        _keyOwnersStructs[key].listPointer = _keyOwnersList.length - 1;
        _keyOwnersStructs[key].expiration = block.timestamp + expirationPeriod;
        return true;
    }

    function ownerRemoveKey(address key)
        external
        requireOwner
        returns (bool success)
    {
        require(_isKeyOwner(key), "There is no that key");
        uint256 rowToDelete = _keyOwnersStructs[key].listPointer;
        delete _keyOwnersStructs[key];
        delete _keyOwnersList[rowToDelete];
        return true;
    }

    function ownerRemoveKeyandPermission(address userAddress)
        external
        requireOwner
        returns (bool success)
    {
        require(_isAllowedUser(userAddress) || _isKeyOwner(userAddress), "User is neither whitelisted nor key owner");
        if(_isKeyOwner(userAddress)){
            uint256 rowToDelete = _keyOwnersStructs[userAddress].listPointer;
            delete _keyOwnersStructs[userAddress];
            delete _keyOwnersList[rowToDelete];
        }
        if(_isAllowedUser(userAddress)){
            uint256 rowToDelete = _allowedUsersStructs[userAddress].listPointer;
            delete _allowedUsersStructs[userAddress];
            delete _allowedUsersList[rowToDelete];
        }
        return true;
    }
    
    function ownerRenewKey(address key) public requireOwner {
        require(_isKeyOwner(key), "Token doesn't exist.");
        uint256 _currentExpiryTime = _keyOwnersStructs[key].expiration;
        if (block.timestamp > _currentExpiryTime) {
            _keyOwnersStructs[key].expiration = block.timestamp + expirationPeriod;
        } else {
            _keyOwnersStructs[key].expiration += expirationPeriod;
        }
    }

    function ownerIsKeyRenewed(address key) public view requireOwner returns (bool) {
        require(_isKeyOwner(key), "Token doesn't exist.");
        return _keyOwnersStructs[key].expiration > block.timestamp;
    }

    function ownerCheckTokenExpiry(address key) public view requireOwner returns (uint256) {
        require(_isKeyOwner(key), "Token doesn't exist.");
        return _keyOwnersStructs[key].expiration;
    }

    function withdrawBalance() external requireOwner returns (bool) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        return success;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external requireOwner {
        _transferOwnership(address(0));
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external requireOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    //
    //

    function isUserAdded(address userAddress)
        public
        view
        returns (bool)
    {
        return _isAllowedUser(userAddress);
    }

    function userHasKey(address userAddress)
        public
        view
        returns (bool)
    {
        return _isKeyOwner(userAddress);
    }

    function isKeyRenewed(address userAddress)
        public
        view
        returns (bool)
    {
        require(_isKeyOwner(userAddress), "Token doesn't exist");
        uint256 _currentExpiryTime = _keyOwnersStructs[userAddress].expiration;
        if (block.timestamp > _currentExpiryTime) {
            return false;
        } else {
            return true;
        }    
    }

    function amIAllowedToCheckout() public view returns (bool) {
        return _isAllowedUser(msg.sender);
    }

    function doIHaveAKey() public view returns (bool) {
        return (_isKeyOwner(msg.sender));
    }

    event KeyMinted(address key, uint pointer, uint expiration);

    function publicSaleCheckout() external payable callerIsUser {
        require(!_isKeyOwner(msg.sender), "Already key owner");
        require(!_isAllowedUser(msg.sender), "You have permission, check out from the dash");
        require(saleIsActive, "Public sale is not active");
        require(_keyOwnersList.length<maxSupply, "Max supply exceeded");
        require(msg.value >= tokenPrice, "Not enough ether sent");
        _keyOwnersList.push(msg.sender);
        _keyOwnersStructs[msg.sender].listPointer = _keyOwnersList.length - 1;
        _keyOwnersStructs[msg.sender].expiration = block.timestamp + expirationPeriod;
        _allowedUsersList.push(msg.sender);
        _allowedUsersStructs[msg.sender].timestamp = block.timestamp;
        _allowedUsersStructs[msg.sender].listPointer =_allowedUsersList.length -1;
        emit KeyMinted(msg.sender, _keyOwnersStructs[msg.sender].listPointer, _keyOwnersStructs[msg.sender].expiration);
    }

    function checkOut() external payable callerIsUser {
        require(_isAllowedUser(msg.sender), "This address isnt whitelisted");
        require(msg.value >= tokenPrice, "Not enough ether sent");
        require(!_isKeyOwner(msg.sender), "Already key owner");
        _keyOwnersList.push(msg.sender);
        _keyOwnersStructs[msg.sender].listPointer = _keyOwnersList.length - 1;
        _keyOwnersStructs[msg.sender].expiration = block.timestamp + expirationPeriod;
        emit KeyMinted(msg.sender, _keyOwnersStructs[msg.sender].listPointer, _keyOwnersStructs[msg.sender].expiration);
    } // view - cant modify, pure - cant modify or read

    event KeyTransferred(address oldOwner, address newOwner, uint256 expiration);
    event PermissionTransferred(address oldOwner, address newOwner);

    function transferKeyandPermission(address newOwner) external payable {
        require(_isAllowedUser(msg.sender) || _isKeyOwner(msg.sender), "User is neither whitelisted nor key owner");
        require(msg.value >= transferPrice, "Not enough ether sent");
        // require(!_isKeyOwner(msg.sender), "Already key owner");
        if(_isAllowedUser(msg.sender)){
            uint256 rowToDelete = _allowedUsersStructs[msg.sender].listPointer;
            delete _allowedUsersStructs[msg.sender];
            delete _allowedUsersList[rowToDelete];
            _allowedUsersStructs[newOwner].timestamp = block.timestamp;
            _allowedUsersList.push(newOwner);
            _allowedUsersStructs[newOwner].listPointer = _allowedUsersList.length - 1;
            emit PermissionTransferred(msg.sender, newOwner);
        }
        if(_isKeyOwner(msg.sender) && !_isKeyOwner(newOwner)){
            uint256 rowToDelete = _keyOwnersStructs[msg.sender].listPointer;
            uint256 expiration = _keyOwnersStructs[msg.sender].expiration;
            delete _keyOwnersStructs[msg.sender];
            delete _keyOwnersList[rowToDelete];
            _keyOwnersList.push(newOwner);
            _keyOwnersStructs[newOwner].listPointer = _keyOwnersList.length - 1;
            _keyOwnersStructs[newOwner].expiration = expiration;  
            emit KeyTransferred(msg.sender, newOwner, expiration);    
        }
    } // view - cant modify, pure - cant modify or read

    function renewKey() external payable {
        require(_isAllowedUser(msg.sender), "This address isnt allowed to renew");
        require(_isKeyOwner(msg.sender), "Token doesn't exist");
        require(msg.value >= renewPrice, "Not enough ether sent");
        uint256 _currentExpiryTime = _keyOwnersStructs[msg.sender].expiration;
        if (block.timestamp > _currentExpiryTime) {
            _keyOwnersStructs[msg.sender].expiration = block.timestamp + expirationPeriod;
        } else {
            _keyOwnersStructs[msg.sender].expiration += expirationPeriod;
        }
    }

    // function isKeyRenewed() public view returns (bool) {
    //     return _keyOwnersStructs[msg.sender].expiration > block.timestamp;
    // }

    function totalSupply() public view returns (uint){
        return _keyOwnersList.length;
    }

    function checkTokenExpiry() public view returns (uint256) {
        require(_isKeyOwner(msg.sender), "Token doesn't exist.");
        return _keyOwnersStructs[msg.sender].expiration;
    }
    // function balanceOf(address _owner) public view returns(uint256 balance){
    //     return _owner.balance;
    // }
    receive() external payable {} //fallback function
}