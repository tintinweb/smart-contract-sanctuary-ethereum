/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract Dvive_SignUp_logIn
{
    bytes32[] public userSignUpInfo; //info: Mobile number
    struct SecurityDetails
    {
        uint key;
        string password;
    }
    mapping(uint=>SecurityDetails)  public logInCredentials;
    event eUserInfo(uint _mobileNum);
    event eLogInInfo(uint _mobNum, uint _key, string _password);
    function SignUpInfo(uint _mobileNum) public returns(bool)
    {
        userSignUpInfo.push(bytes32(_mobileNum));
        emit eUserInfo(_mobileNum);
        return true;
    }
    function LogInDetails(uint _mobNum, uint _key, string memory _password) public returns(bool)
    {
        logInCredentials[_mobNum].key=_key;
        logInCredentials[_mobNum].password=_password;
        emit eLogInInfo(_mobNum,_key,_password);
        return true;
    }
    
}