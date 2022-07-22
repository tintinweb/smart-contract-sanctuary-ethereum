/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

 
contract LIFECRYPTO {
   string  internal symblename = "";
    //user address wise multiple userName
    struct User_Address {
        string fullname;
        string[] user_name;
    }
    mapping(address => User_Address) private userInfobyAddress;
    address[] private _listOfUserAddress;
    string[] private _listOfUserName;
    mapping(string => address) public addressByUserName;


    constructor(string memory sybValue){
        symblename=sybValue;
    }

    //User address wise multiple user section
    //Write Method
    function setUserNameByAddress(string memory userName, address walletAddress) public returns (bool) {
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
        return true;
    }
    function updateUserInfo( address addressVal,string memory fullName) public returns (bool) {
        require(bytes(fullName).length >0, "Full name cannot be left empty");
        require(addressVal != address(0), "LIFE: Address to the zero address");
        userInfobyAddress[addressVal].fullname = fullName;
        return true;
    }

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
}