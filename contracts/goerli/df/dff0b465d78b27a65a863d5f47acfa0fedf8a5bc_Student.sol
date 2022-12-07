/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.8.0;

contract Student{
    string name;
    uint rollNo;
    uint marks;
    string status;
    constructor(string memory _name, uint _rollNo, uint _marks){
      name = _name;
      rollNo = _rollNo;   
      marks = _marks;
      if(_marks>50){
          status = "Pass";
      }else{
          status = "Fail";
      }
    }
    function setName(string memory _name)public{
        name = _name;
    }
    function setRollNo(uint _rollNo)public{
        rollNo = _rollNo;
    }
    function setMarks(uint _marks)public{
        if(_marks >= 0 && _marks <= 100){
            rollNo = _marks;
        }
    }
    function getName()public view returns(string memory){
        return name;
    }
    function getRollNo()public view returns(uint){
        return rollNo;
    }
    function getMarks()public view returns(uint){
        return marks;
    }
    function getStatus()public view returns(string memory){
        return status;
    }
}