// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";

contract LIFECRYPTO is AccessControlEnumerable, Ownable{
    //user address wise multiple userName
    struct User_Address {
        string fullname;
        string[] user_name;
    }
    mapping(address => User_Address) private userInfobyAddress;
    address[] private _listOfUserAddress;
    string[] private _listOfUserName;
    mapping(string => address) private _addressByUserName; //map with username with address
    mapping(string => bool) private _isUserNameCreate;//username mapp
    mapping(address => bool) private _isAddressUsed;//Wallet Address mapp
    mapping(string => string) private _userNameMapByTxID;//for txid save
    mapping(string => string) private _txidMapByUsername; //for txid save
    mapping(string => bool) private _isUserNameFreeze; //for username freeze

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
    //Write Method
    function createCustomUsername(string calldata userName, address walletAddress) external returns (bool) {
        require(hasRole(CREATE_CUSERNAME_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have create cusername role");
        _setUserName(userName,walletAddress);
        return true;
    }
    
    function createPaidUsername(string calldata txid,string calldata userName, address walletAddress) external returns (bool) {
        require(hasRole(CREATE_PUSERNAME_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have create pusername role");
        require(!txIdExistCheck(userName,txid), "TXID or USERNAME Already exist!.");
        _userNameMapByTxID[txid]=userName;
        _txidMapByUsername[userName]=txid;
        _setUserName(userName,walletAddress);
        return true;
    }
    
    function batchUserNameCreateByOwner(string[] calldata userNames, address[] calldata walletAddresses) external onlyOwner returns (bool) {
        require(userNames.length == walletAddresses.length, "Usernames and Addresses length mismatch!");
        for (uint256 i = 0; i < userNames.length; ++i) {
            string memory name = userNames[i];
            address walAddress = walletAddresses[i];
            _setUserName(name,walAddress);
        }
        return true;
    }

    function batchUserNameCreateForSameAddress(string[] calldata userNames, address walletAddresses) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < userNames.length; ++i) {
            string memory name = userNames[i];
            _setUserName(name,walletAddresses);
        }
        return true;
    }
    function freezeUserName(string calldata userName) external returns (bool) {
        require(hasRole(USERNAME_TRANSFER_FREEZE_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have USERNAME TRANSFER FREEZE ROLE");
        require(_isUserNameCreate[userName], "UserName Not Found!.");
       _isUserNameFreeze[userName] = true;
        return true;
    }
    function unFreezeUserName(string calldata userName) external returns (bool) {
        require(hasRole(USERNAME_TRANSFER_FREEZE_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have USERNAME TRANSFER FREEZE ROLE");
        delete _isUserNameFreeze[userName];
        return true;
    }

    function transferUserName(string calldata userName, address fromAddress, address toAddress) external returns (bool) {
        require((_addressByUserName[userName] == _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have Admin Role!");
        require(!_isUserNameFreeze[userName], "UserName is Freeze for transfer.");
        require(_addressByUserName[userName] == fromAddress, "UserName not found!.");
        userInfobyAddress[toAddress].user_name.push(userName);
        removeItem(userName,fromAddress);
        _addressByUserName[userName]=toAddress;
        if(!_isAddressUsed[toAddress]) { //duplicate address check
            _listOfUserAddress.push(toAddress); 
            _isAddressUsed[toAddress]=true;
        }
        return true;
    }

    function bindUserPayment(string calldata txid, string calldata username) external returns (bool) {
        require(hasRole(BIND_USER_PAYMENT_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have BIND USER PAYMENT ROLE.");
        require(!txIdExistCheck(username,txid), "TXID or username Already exist!.");
        _userNameMapByTxID[txid]=username;
        _txidMapByUsername[username]=txid;
        return true;
    }
    function removeUserPayment(string calldata txid) external returns (bool) {
        require(hasRole(REMOVE_USER_PAYMENT_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have REMOVE USER PAYMENT_ROLE");
        string memory user_name = _userNameMapByTxID[txid];
        delete _userNameMapByTxID[txid];
        delete _txidMapByUsername[user_name];
        return true;
    }
   
    function updateUserInfo( address addressVal,string calldata fullName) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller Must have ADMIN ROLE.");
        require(bytes(fullName).length >0, "Full name cannot be left empty");
        require(addressVal != address(0), "Address to the zero address");
        userInfobyAddress[addressVal].fullname = fullName;
        return true;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        _revokeRole(DEFAULT_ADMIN_ROLE,_msgSender());
    }
    //Common Method

    function _setUserName(string memory userName, address wAddress) internal {
        require(bytes(userName).length >0, "User name cannot be left empty");
        require(wAddress != address(0), "wallet Address to the zero address");
        require(!_isUserNameCreate[userName], "UserName already exist!.");
        string memory fullName = userInfobyAddress[wAddress].fullname;
        if(bytes(fullName).length ==0){
            userInfobyAddress[wAddress].fullname = userName;
        }
        userInfobyAddress[wAddress].user_name.push(userName);
        if(!_isAddressUsed[wAddress]) { //duplicate address check
            _listOfUserAddress.push(wAddress); 
            _isAddressUsed[wAddress]=true;
        }
        _addressByUserName[userName]=wAddress;
        _isUserNameCreate[userName]=true;
        _listOfUserName.push(userName);
    }

    function removeItem(string memory userName,address wAddress) internal{
        uint256 totalUserName = userInfobyAddress[wAddress].user_name.length;
        string[] memory addreUserNames = userInfobyAddress[wAddress].user_name;
            bool flag=false;
            for(uint i=0;i<totalUserName;i++){
                if (keccak256(abi.encodePacked(addreUserNames[i])) == keccak256(abi.encodePacked(userName))) 
                {
                    //delete userInfobyAddress[wAddress].user_name[i];
                      //move last element to delete index.
                    userInfobyAddress[wAddress].user_name[i] = userInfobyAddress[wAddress].user_name[totalUserName-1];
                    //move delete element to last index
                    userInfobyAddress[wAddress].user_name[totalUserName-1] = userName;
                    userInfobyAddress[wAddress].user_name.pop();
                    flag=true;
                    break;
                }
                
            }
    }

    function txIdExistCheck(string memory user_name,string memory txId) internal virtual returns (bool) {
        bool flag=false;
        string memory username = _userNameMapByTxID[txId];
        string memory trxID = _txidMapByUsername[user_name];
        if (bytes(username).length == 0 && bytes(trxID).length == 0 ) {
           flag = false;
        } else {
            flag = true;
        }
        return flag;
    }
    

    function checkExistsUserAddress(address walletAddress) public view virtual returns (bool){
        return _isAddressUsed[walletAddress];
    }
    //End
    function checkUserNameAndAddress(string calldata userName,address walletAddress) external view virtual returns (bool){
        uint256 totalUserName = userInfobyAddress[walletAddress].user_name.length;
        string[] memory addreUserNames = userInfobyAddress[walletAddress].user_name;
        bool flag=false;
        for(uint i=0;i<totalUserName;i++){
            if (keccak256(abi.encodePacked(addreUserNames[i])) == keccak256(abi.encodePacked(userName))) 
            {
                flag=true;
                break;
            }
             
        }
        return flag;
    }
    function checkExistsUserName(string calldata userName) external view virtual returns (bool){
        return _isUserNameCreate[userName];
    }
    function getAllUsernameByAddress(address walletAddress) public view virtual returns(string[] memory){ 
        return userInfobyAddress[walletAddress].user_name; 
    }
    function getUserFullNameByAddress(address walletAddress) public view virtual returns(string memory fullName){ 
        return userInfobyAddress[walletAddress].fullname; 
    }
    function addressByUserName(string calldata username) external view virtual returns(address){ 
        return _addressByUserName[username]; 
    }
    function userAddressList() public view virtual returns (address[] memory) {
        return _listOfUserAddress;
    }
    function isUserNameFreeze(string calldata username) external view virtual returns (bool) {
        return _isUserNameFreeze[username];
    }
    function userNameList() public view virtual returns (string[] memory) {
        return _listOfUserName;
    }
    function getUsernameByPayment(string calldata txid) external view virtual returns (string memory) {
        return _userNameMapByTxID[txid];
    }
    
    //Read end
}