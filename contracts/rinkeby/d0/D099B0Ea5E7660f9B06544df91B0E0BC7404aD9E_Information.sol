/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Information {
    constructor(){
        isAdmin[msg.sender] = true;
    }

   struct Student{
     uint sid;    // student id
     string firstName;
     string lastName;
     string fatherName;
     string motherName;
     string gender;
     string dateOfBirth;
     string emailId;
     string collegeName;
     string level;
     string course;
     string mobileNumber;
     bool flag;
   }

    struct College{
        uint cid; // college id
        string collegeName;
        string collegeAddress;
        string tel;
        string website;
        bool aicteCertified;
        bool mhrdCertified;
        bool flag;
    }

    mapping(address => bool) isAdmin;
    uint sid = 1000;// student id
    uint cid = 1000;// college id
    Student[] private studentList;
    College[] private collegeList;
    mapping(uint => Student) private idToStudent;
    mapping(uint => College) private idToCollege;


 // ----------------------- STUDENT FUNCTIONS -----------------------------

    function registerStudent(
        string memory _firstName,
        string memory _lastName,
        string memory _fatherName,
        string memory _motherName,
        string memory _gender,
        string memory _dob,
        string memory _email,
        string memory _collegeName,
        string memory _level,
        string memory _course,
        string memory _mobileNumber) public {

        Student memory s1 = Student(sid,_firstName, _lastName,_fatherName,_motherName,
        _gender,_dob,_email,_collegeName,_level,_course,_mobileNumber, true);

        studentList.push(s1);
        idToStudent[sid] = s1;
        sid++;
    }

     function getAllStudents() public view onlyAdmin returns(Student[] memory){
        return studentList;
    }

    function getStudentByID(uint  _uid) public view onlyAdmin returns(Student memory){
        require(idToStudent[_uid].flag ,"Student does not exist");
        return idToStudent[_uid];
    }


    function updateStudentData(
        string memory _firstName,
        string memory _lastName,
        string memory _fatherName,
        string memory _motherName,
        string memory _gender,
        string memory _dob,
        string memory _email,
        string memory _collegeName,
        string memory _level,
        string memory _course,
        string memory _mobileNumber
      ) public {

       uint idx = checkDatabase(_email);
       uint len = studentList.length;

      require( (idx != len) , "Your data is not found in the database.");

       Student memory s1 = Student( studentList[idx].sid ,_firstName, _lastName,_fatherName,_motherName,
        _gender,_dob,_email,_collegeName,_level, _course, _mobileNumber, true);

          studentList[idx]=s1;
          idToStudent[studentList[idx].sid] = s1;

      }



   function checkDatabase(
        string memory email1
      ) public view returns (uint) {

      uint i = 0;

     while(i<studentList.length){
       string memory a = studentList[i].emailId;
       string memory b = email1;
         if( keccak256(bytes(a)) == keccak256(bytes(b)) ){
             return i;
         }
           i++;
    }

         return studentList.length;
      }



// ----------------------- COLLEGE FUNCTIONS -----------------------------

    function registerCollege(
        string memory _collegeName,
        string memory _address,
        string memory _tel,
        string memory _website,
        bool _aicteCertified,
        bool _mhrdCertified
    ) public onlyAdmin {
        College memory newCollege = College(cid,_collegeName,_address,_tel,_website,_aicteCertified,_mhrdCertified,true);
        collegeList.push(newCollege);
        idToCollege[cid] = newCollege;
        cid++;
    }

    function getAllColleges() public view returns(College[] memory) {
        return collegeList;
    }

    function getCollegeById(uint _id) public view returns(College memory){
        require(idToCollege[_id].flag ,"Collge does not exist");
        return idToCollege[_id];
    }

// ----------------------------- ADMIN FUNCTIONS ----------------------------

    function addAdmin(address newAddress) public onlyAdmin {
        isAdmin[newAddress] = true;
    }

    function checkIfAdmin() public view returns(bool){
        return isAdmin[msg.sender];
    }


//---------------------------------HELPER FUNCTIONS-----------------------------

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Permission Denied. You do not have admin access.");
        _;  }

    }