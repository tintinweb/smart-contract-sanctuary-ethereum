/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Yasin{
    string public  name;
    int public  RollNo;
    uint public PhoneNumber;
    bool public Alive;
    int public constant  cnic=1730100002;
    string public constant FatherName="Qadir Khan";
     address public MetaMaskAddress;
     
     function setVariable(string memory _name,int _Rollno,uint _PhoneNumber,address _MetaMaskAddress,bool _Alive)public {
     name=_name;
     RollNo=_Rollno;
     PhoneNumber=_PhoneNumber;
     Alive=_Alive;
     MetaMaskAddress=_MetaMaskAddress;

     }

     }