/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Nadra{
    uint public NadraCount;

    struct NadraStruct {
        address UserAddress;
        uint NIC_No ;
        uint Id_Number;
        uint Age;
        string message;
        }

    NadraStruct[] NadraUser;
    mapping (uint=> NadraStruct ) private CheckNadraData;

    function EnterUserData (address _UserAddress , uint _NIC_no  ,uint _Id_number ,uint _Age , string memory _message)public{
         NadraCount +=1;
         CheckNadraData[NadraCount].UserAddress = _UserAddress;
         CheckNadraData[NadraCount].NIC_No = _NIC_no;
         CheckNadraData[NadraCount].Id_Number = _Id_number;
         CheckNadraData[NadraCount].Age = _Age;
         CheckNadraData[NadraCount].message = _message;
         NadraUser.push(NadraStruct(_UserAddress ,  _NIC_no ,_Id_number , _Age , _message ));
        } 
    function GetAllData()public view returns(NadraStruct[] memory){
       return NadraUser;
    }

    function GetUserById(uint _id) public view returns (address ,uint ,uint ,uint ,string memory) {
        return ( 
            CheckNadraData[_id].UserAddress,
            CheckNadraData[_id].NIC_No,
            CheckNadraData[_id].Id_Number,
            CheckNadraData[_id].Age,
            CheckNadraData[_id].message

        );
     }
   
}