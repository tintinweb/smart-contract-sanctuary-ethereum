/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Dvive_SignUp_logIn_ProfileSetUp_KYC
{
    uint[]  userSignUpInfo; //info: Mobile number
    address[]  userAddress;
    address public Owner; 

    struct userDetailsStruct  
    {
        uint pin;
        uint mobileNum;
        string password;
        string FullName;
        string gender;
        string Address;
        string documentName;
        string documentID;
    }
    
    mapping(address=>userDetailsStruct) userDetails; //key=user wallet address
    mapping(address=>bool) internal IsRegistered;
    mapping(address=>bool) internal IsloggedIn;
    mapping(address=>bool) internal KYSisDone;

    event eUserInfo(address user,uint _mobileNum);
    event eLogInInfo(uint _mobNum, uint _pin, string _password);
    event eProfileSetup(string _fullname,string _gender);
    event eKYC(address,string,string);
    event eTransferOwnership(address,address); 

    modifier mOwnerOnly
    {
               require(msg.sender==Owner,"only owner has access");
               _;
    }

    constructor()
    {  
               Owner=msg.sender;
    }

    function SignUp(uint _mobileNum) public returns(bool)
    {
               userDetails[msg.sender].mobileNum=_mobileNum;
               require(IsRegistered[msg.sender]==false,"You are already registered");  
               userSignUpInfo.push(_mobileNum);
               userAddress.push(msg.sender);
               IsRegistered[msg.sender]=true;
               emit eUserInfo(msg.sender,_mobileNum);
               return true;
    }

    function LogInDetails(uint _mobNum, uint _pin, string memory _password) public returns(bool)
    {
               require(IsRegistered[msg.sender]==true,"You are not registered");
               userDetails[msg.sender].pin=_pin;
               userDetails[msg.sender].password=_password;
               IsloggedIn[msg.sender]=true;
               emit eLogInInfo(_mobNum,_pin,_password);
               return true;
    }

    // mapped details of the user at profile setUp time to the existing MobileNumber 
    // fetched existing mobile number from the declared array  
    function ProfileSetUp(string memory _FullName,string memory _gender, string memory _Address,uint _pin) public
    {
               require(IsloggedIn[msg.sender]==true,"You have not logged In");
               userDetails[msg.sender].FullName=_FullName;
               userDetails[msg.sender].gender=_gender;
               userDetails[msg.sender].Address=_Address;
               userDetails[msg.sender].pin=_pin;
               emit eProfileSetup(_FullName,_gender);
    }

    function KYC(string memory _documentName, string memory _documentID ) public returns(bool)
    {
               require(IsRegistered[msg.sender]==true,"You are not registered");
               userDetails[msg.sender].documentName=_documentName;
               userDetails[msg.sender].documentID=_documentID;
               KYSisDone[msg.sender]=true;
               emit eKYC(msg.sender,_documentName,_documentID);
               return true;
    }

    function transferOwnership(address _newOwner) public mOwnerOnly returns(bool)
    {
               Owner=_newOwner;
               return true;
    }
        
    //  get user mobile number stored in array by providing index
    function getMobNum(uint _index) public view mOwnerOnly returns(uint)
    {
               return userSignUpInfo[_index];
    }

    // get struct mapped to a mobileNumber(key) by providing key(mobileNumber)
    function getUserDetails(address _user) public view mOwnerOnly returns(userDetailsStruct memory)
    {
               return userDetails[_user];
    }
    
    }