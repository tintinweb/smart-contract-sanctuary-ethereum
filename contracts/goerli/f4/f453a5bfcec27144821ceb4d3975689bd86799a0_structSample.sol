/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: contracts/struct.sol


pragma solidity ^0.8.0;

    //Struct will make sure that all the "assets(student)" are present in the created 'struct'.
    //One asset may have multiple "properties/variables(name, age, ...)".
contract structSample{

struct student{
    string name;
    uint8 age;
    uint32 phoneNo;
    string addresses;
}

//syntax of mapping is mapping (key => value) mapping name
//1--> (Anjani,26,9010,KMM)
//2--> (Vara,38,0280,WGL)
//3--> (Prasad, 40, 0179, HYD)
mapping (uint8 => student) simpliStudents;

//memory and storage. Memory is in RAM and Storage is directly stored in Blockchain.
//Also for string only we have to use 'memory'
function studentDetails (uint8 _key, string memory _name, uint8 _age, uint32 _phoneNo, string memory _addresses) public{
    //simpliStudents[1].name="Anjani"
    //simpliStudents[1].age=26
    //simpliStudents[1].phoneNo=9010
    //simpliStudents[1].addresses="KMM"
    //In the above way data is stored in the Blockchain.
    simpliStudents[_key].name=_name;
    simpliStudents[_key].age=_age;
    simpliStudents[_key].phoneNo=_phoneNo;
    simpliStudents[_key].addresses=_addresses;
}

    //Read function
    function getSimpliStudentDetails(uint8 _key) public view returns (string memory, uint8, uint32, string memory) {
        return (simpliStudents[_key].name, simpliStudents[_key].age, simpliStudents[_key].phoneNo, simpliStudents[_key].addresses);
    }
}

//SC address for the above SC is --> 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
// New SC --> 0x798c101c3db3f7bd6d0169f8972d04742f3f0233bb895fbed840ecaf57aecf47