/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

pragma solidity ^0.4.21;

contract InfoContract {

    string fName;
    uint age;

    event Instructor(
       string name,
       uint age
    );

    function setInfo(string _fName, uint _age) public returns(string){
       fName = _fName;
       age = _age;
       emit Instructor(_fName, _age);
       return fName;
   }

    function getInfo() public constant returns (string, uint) {
       return (fName, age);
   }

}