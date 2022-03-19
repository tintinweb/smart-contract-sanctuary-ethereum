/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

//SPDX-Licence-Identifier: MIT

pragma solidity 0.8.0;

contract Verify{

    // Student data, mapped to address 
    constructor(uint256 _rollNo) {
        registrar = msg.sender;
        rollNo = _rollNo;
    }
    uint256 rollNo;
    uint8 grades;
    address student;
    address[] students;

    address registrar;
    mapping (address => uint256) rollNos;

    struct StudentData{
        uint256 rollNo;
        uint8 grade;
        string firstName;
    }
    mapping(address => StudentData) sData;

    function addStudent(address _new, string memory _fName) public  {
        require(msg.sender == registrar, "Only registrar");
        rollNo++;
        rollNos[_new] = rollNo;
        students.push(_new);
        sData[_new] = StudentData(rollNo,0,_fName);

    }

    function viewStudents()public view returns(address[] memory){
        return students;
    }
    function addGrades(address _student, uint8 _grades)public {
        sData[_student].grade = _grades;
    }
    uint8[] gradesAll;
    function addGradesAll(address[] memory _addr, uint8[] memory _grades) public {
        require(_addr.length == _grades.length, "Array of diff lengths");
        // _addr[0]  => _grades[0]
        for(uint i =0; i<_addr.length; i++){
            sData[_addr[i]].grade = _grades[i];
            gradesAll.push(_grades[i]);
        }

    }

    function viewResult(address _addr) public view returns(string memory , uint8) {
        return (sData[_addr].firstName,sData[_addr].grade);
    }
    function viewResultAll() public view returns(address[] memory, uint8[] memory){
        return (students,gradesAll);
    }

    function viewRollNo() public view returns(uint256) {
        return rollNo;
    }
//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

}