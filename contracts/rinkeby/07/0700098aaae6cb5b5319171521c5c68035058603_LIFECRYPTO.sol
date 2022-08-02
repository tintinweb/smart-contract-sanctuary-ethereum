/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

 
contract LIFECRYPTO {
    //user address wise multiple userName
    struct User_Address {
        string fullname;
        string[] user_name;
    }
    mapping(address => User_Address) private userInfobyAddress;
    address[] private _listOfUserAddress;
    string[] private _listOfUserName;
    string private _freeUserNameSymble = "user";
    uint256  private maxSLNum =1;
    mapping(string => address) public addressByUserName;
    uint256 public _decimals = 8;
    address public _owner = msg.sender;
    uint256 public _feeAmount;
    address public _collectionAddress;
    uint256 public _royalityAmount;
    address public _rewardAddress;


    constructor(
        uint256 feeAmount, 
        uint256 royalityAmount
    ){
       //_feeAmount = feeAmount * (10 ** uint256(_decimals));
       _feeAmount = feeAmount;
       _collectionAddress = msg.sender;
       //_royalityAmount = royalityAmount * (10 ** uint256(_decimals));
       _royalityAmount = royalityAmount;
       _rewardAddress = msg.sender;
    }

    //User address wise multiple user section
    //Write Method
    function createUserNameFree(address walletAddress) public returns (bool) {
        string memory generatedUserName = string(abi.encodePacked(_freeUserNameSymble,toString(maxSLNum)));
        _setUserName(generatedUserName,walletAddress);
        maxSLNum +=1;
        return true;
    }

    function createUserNameByOwner(string memory userName, address walletAddress) public returns (bool) {
        require(msg.sender== _owner,"Only owner can do it.");
        _setUserName(userName,walletAddress);
        return true;
    }
   
    function updateUserInfo( address addressVal,string memory fullName) public returns (bool) {
        require(bytes(fullName).length >0, "Full name cannot be left empty");
        require(addressVal != address(0), "LIFE: Address to the zero address");
        userInfobyAddress[addressVal].fullname = fullName;
        return true;
    }
    function updateFeeAmount(uint256 updateAmt) public returns (bool) {
        require(msg.sender== _owner,"Only owner can do it.");
        //_feeAmount = updateAmt * (10 ** uint256(_decimals));
        _feeAmount = updateAmt;
        return true;
    }
    function updateCollectionAddress(address updateCollAddress) public returns (bool) {
        require(msg.sender== _owner,"Only owner can do it.");
        _collectionAddress = updateCollAddress;
        return true;
    }
    function updateRoyalityAmount(uint256 updateRoyalityAmt) public returns (bool) {
        require(msg.sender== _owner,"Only owner can do it.");
        //_royalityAmount = updateRoyalityAmt * (10 ** uint256(_decimals));
        _royalityAmount = updateRoyalityAmt;
        return true;
    }
    function updateRewardAddress(address updateReAddress) public returns (bool) {
        require(msg.sender== _owner,"Only owner can do it.");
        _rewardAddress = updateReAddress;
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
    //Common  End
    
    //Read Method
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
    function getAllUserNamesByAddress(address walletAddress) public view virtual returns(string[] memory){ 
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
    // function guessThePassword(string memory _password) external view returns (bool) {
    //     return keccak256(abi.encodePacked(_password)) == hash2;
    // }
    
    //Read end
}