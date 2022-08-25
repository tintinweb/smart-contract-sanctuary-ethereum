/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract studentRecord
{
    
    struct student
    {
        string Name;
        string Address;
        string Phone_Num;
        uint16 Roll_Num;
        string DOB;
        uint8 Sem;
        uint8 CGPA;
        string Uni_Name;
    }

    student[] public StudentRecord;
function setStudentRecords(string memory _name,
 string memory _address,
  string memory _phoneNumber, 
  uint16 _rollNumber,
 string memory _DOB,
 uint8 _sem, uint8 _CGPA, 
 string memory _UniName) public
{
    StudentRecord.push(student(_name,
            _address,
            _phoneNumber,
            _rollNumber,
            _DOB,
            _sem,
            _CGPA,
            _UniName
        )
    );
}

function returnlength()public view returns(uint){
    return StudentRecord.length;
}

function findaverage () public view returns(uint){
    uint sum = 0;
    for(uint i =0; i<StudentRecord.length; i++){
        sum = sum + StudentRecord[i].CGPA;
    }
    return sum/StudentRecord.length ;
}
function sortbasedonroll() public{
    student memory temporary;
    for(uint i=0;i<StudentRecord.length-1;i++){
        if(StudentRecord[i].Roll_Num > StudentRecord[i+1].Roll_Num){
            temporary = StudentRecord[i+1];
            StudentRecord[i+1] = StudentRecord[i];
            StudentRecord[i] = temporary;
        }
    }
}
function seestruct()public view returns(student[] memory){
return StudentRecord;
}

}