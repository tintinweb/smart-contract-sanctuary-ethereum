/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity >=0.4.24;
contract assignmentTwo {
    uint public studentNumber;
    address public student;
    uint public gasUsed;
    constructor() public {
        student = msg.sender;
    }
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    function setGasUsed(uint _gasUsed) public {
        gasUsed=_gasUsed;
    }
}