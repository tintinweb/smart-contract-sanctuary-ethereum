pragma solidity ^0.4.18;

contract Test {
    
   string fName;
   uint age;
    
    event Instructor(
       string name,
       uint age
    );   
   
   function setInstructor(string _fName, uint _age) public {
       fName = _fName;
       age = _age;
       Instructor(_fName, _age);   
   }
   
   function getInstructor() public constant returns (string, uint) {
       return (fName, age);
   }
    
}