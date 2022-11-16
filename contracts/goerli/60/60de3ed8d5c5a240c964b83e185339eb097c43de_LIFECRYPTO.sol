// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";


contract LIFECRYPTO is AccessControlEnumerable,Ownable{
    //user address wise multiple userName
    struct User_Address {
        string fullname;
        string[] user_name;
    }
    mapping(address => User_Address) private userInfobyAddress;
    address[] private _listOfUserAddress;
    string[] private _listOfUserName;
    string private _freeUserNameSymble = "user";
    uint256  private _maxSLNum =1;
    mapping(string => address) public addressByUserName;
    mapping(string => string) private _userNameMapByTxID;//for txid save
    mapping(string => string) private _txidMapByUsername; //for txid save
    uint256 public decimal = 8;
    uint256 public feeamount;
    address public collectionAddress;
    uint256 public royalityamount;
    address public rewardAddress;


    constructor(
        uint256 feeAmount, 
        uint256 royalityAmount
    ){
       //feeamount = feeAmount * (10 ** uint256(decimal));
        //royalityamount = royalityAmount * (10 ** uint256(decimal));
       feeamount = feeAmount;
       collectionAddress = msg.sender;
       royalityamount = royalityAmount;
       rewardAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    
    //User address wise multiple user section
    //Write Method
    function createRandomUsername(address walletAddress) public returns (bool) {
        string memory generatedUserName = string(abi.encodePacked(_freeUserNameSymble,toString(_maxSLNum)));
        _setUserName(generatedUserName,walletAddress);
        _maxSLNum +=1;
        return true;
    }

    function createCustomUsername(string memory userName, address walletAddress) public returns (bool) {
        require(hasRole(CREATE_CUSERNAME_ROLE, _msgSender()) || owner() == _msgSender(), "Life Crypto: Caller Must have CREATE_CUSERNAME_ROLE to create custom username");
        _setUserName(userName,walletAddress);
        return true;
    }
    function createPaidUsername(string memory txid,string memory userName, address walletAddress) public returns (bool) {
        require(hasRole(CREATE_PUSERNAME_ROLE, _msgSender()) || owner() == _msgSender(), "Life Crypto: Caller Must have CREATE_PUSERNAME_ROLE to create paid username");
        require(!txIdExistCheck(userName,txid), "LIFE: TXID or USERNAME Already exist!.");
        _userNameMapByTxID[txid]=userName;
        _txidMapByUsername[userName]=txid;
        _setUserName(userName,walletAddress);
        return true;
    }
    
    function batchUserNameCreateByOwner(string[] memory userNames, address[] memory walletAddresses) public onlyOwner returns (bool) {
        require(userNames.length == walletAddresses.length, "Life Crypto: Usernames and Wallet Addresses length mismatch!");
        for (uint256 i = 0; i < userNames.length; ++i) {
            string memory name = userNames[i];
            address walAddress = walletAddresses[i];
            _setUserName(name,walAddress);
        }
        return true;
    }

    function batchUserNameCreateForSameAddress(string[] memory userNames, address walletAddresses) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < userNames.length; ++i) {
            string memory name = userNames[i];
            _setUserName(name,walletAddresses);
        }
        return true;
    }

    function transferUserName(string memory userName, address fromAddress, address toAddress) public onlyOwner returns (bool) {
        require(!checkUserNameAndAddress(userName,toAddress), "UserName Already exist!.");
        require(checkUserNameAndAddress(userName,fromAddress), "UserName not found!.");
        userInfobyAddress[toAddress].user_name.push(userName);
        removeItem(userName,fromAddress);
        return true;
    }

    function bindUserPayment(string memory txid, string memory username) public returns (bool) {
        require(hasRole(BIND_USER_PAYMENT_ROLE, _msgSender()) || owner() == _msgSender(), "Life Crypto: Caller Must have BIND_USER_PAYMENT_ROLE to create username.");
        require(!txIdExistCheck(username,txid), "LIFE: TXID or username Already exist!.");
        _userNameMapByTxID[txid]=username;
        _txidMapByUsername[username]=txid;
        return true;
    }
    function removeUserPayment(string memory txid) public returns (bool) {
        require(hasRole(REMOVE_USER_PAYMENT_ROLE, _msgSender()) || owner() == _msgSender(), "Life Crypto: Caller Must have REMOVE_USER_PAYMENT_ROLE For Remove Payment.");
        string memory user_name = _userNameMapByTxID[txid];
        delete _userNameMapByTxID[txid];
        delete _txidMapByUsername[user_name];
        return true;
    }
   
    function updateUserInfo( address addressVal,string memory fullName) public returns (bool) {
        require(bytes(fullName).length >0, "Full name cannot be left empty");
        require(addressVal != address(0), "LIFE: Address to the zero address");
        userInfobyAddress[addressVal].fullname = fullName;
        return true;
    }
    function updateFeeAmount(uint256 updateAmt) public onlyOwner returns (bool) {
        //feeamount = updateAmt * (10 ** uint256(decimal));
        feeamount = updateAmt;
        return true;
    }
    function updateCollectionAddress(address updateCollAddress) public onlyOwner returns (bool) {
        collectionAddress = updateCollAddress;
        return true;
    }
    function updateRoyalityAmount(uint256 updateRoyalityAmt) public onlyOwner returns (bool) {
        //royalityamount = updateRoyalityAmt * (10 ** uint256(decimal));
        royalityamount = updateRoyalityAmt;
        return true;
    }
    function updateRewardAddress(address updateReAddress) public onlyOwner returns (bool) {
        rewardAddress = updateReAddress;
        return true;
    }
    //Common Method

    function _setUserName(string memory userName, address walletAddress) internal {
        require(bytes(userName).length >0, "User name cannot be left empty");
        require(walletAddress != address(0), "LIFE: walletAddress to the zero address");
        require(!checkExistsUserName(userName), "LIFE: UserName already exist!.");
        string memory fullName = userInfobyAddress[walletAddress].fullname;
        if(bytes(fullName).length ==0){
            userInfobyAddress[walletAddress].fullname = userName;
        }
        userInfobyAddress[walletAddress].user_name.push(userName);
        if(!checkExistsUserAddress(walletAddress)) { //duplicate address check
            _listOfUserAddress.push(walletAddress); 
        }
        addressByUserName[userName]=walletAddress;
        _listOfUserName.push(userName);
    }

    function removeItem(string memory userName,address walletAddress) internal{
        uint256 totalUserName = userInfobyAddress[walletAddress].user_name.length;
        string[] memory addreUserNames = userInfobyAddress[walletAddress].user_name;
            bool flag=false;
            for(uint i=0;i<totalUserName;i++){
                if (keccak256(abi.encodePacked(addreUserNames[i])) == keccak256(abi.encodePacked(userName))) 
                {
                    delete userInfobyAddress[walletAddress].user_name[i];
                    flag=true;
                    break;
                }
                
            }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
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
    

    function checkExistsUserAddress(address walletAddress) internal virtual returns (bool){
            uint256 totalUserAddress = _listOfUserAddress.length;
            bool flag=false;
            for(uint j=0;j<totalUserAddress;j++){
            if (_listOfUserAddress[j] == walletAddress) //address comparer
                {
                    flag=true;
                    break;
                }
            }
            return flag;
    }
    //End
    function checkUserNameAndAddress(string memory userName,address walletAddress) public view virtual returns (bool){
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
    function checkExistsUserName(string memory userName) public view virtual returns (bool){
            uint256 totalUsers = _listOfUserName.length;
            bool flag=false;
            for(uint j=0;j<totalUsers;j++){
                string memory userNameA = _listOfUserName[j];
            if (keccak256(abi.encodePacked(userNameA)) == keccak256(abi.encodePacked(userName))) //string memory comparer
                {
                    flag=true;
                    break;
                }
            }
            return flag;
    }
    function getAllUsernameByAddress(address walletAddress) public view virtual returns(string[] memory){ 
        return userInfobyAddress[walletAddress].user_name; 
    }
    function getUserFullNameByAddress(address walletAddress) public view virtual returns(string memory fullName){ 
        return userInfobyAddress[walletAddress].fullname; 
    }

    function userAddressList() public view virtual returns (address[] memory) {
        return _listOfUserAddress;
    }
    function userNameList() public view virtual returns (string[] memory) {
        return _listOfUserName;
    }
    function getUsernameByPayment(string memory txid) public view virtual returns (string memory) {
        return _userNameMapByTxID[txid];
    }
    //Read end
}