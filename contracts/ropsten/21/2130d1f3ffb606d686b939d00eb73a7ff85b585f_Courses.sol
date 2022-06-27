/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity ^0.4.0;
contract Courses {
 string fName;
 uint age;
 event onSetData(bool);
 function setInstructor(string _fName, uint _age) public {
    fName = _fName;
    age = _age;
    emit onSetData(true);
 }
 function getInstructor() public constant returns (string, uint) {
    return (fName, age);
 }
}