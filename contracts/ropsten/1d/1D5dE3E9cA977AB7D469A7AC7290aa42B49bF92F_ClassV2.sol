// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

contract ClassV2 {


    struct Student {
        string name;
        uint rollno;
        uint class;
        string section;

    }
    mapping ( uint => Student) public StudentInfo;
    address Owner;
    uint  public studentCount;
    bool private Isinitialized;
    uint rollcount ;

    function initialize() external {
        require (Isinitialized == false,"Already initialized");
          Owner = msg.sender;
          Isinitialized = true;
    }

    function create(string memory _name,uint _rollno ,uint _class,string memory _section) public {
             require (rollcount != _rollno, " account already register");
             StudentInfo[_rollno] = Student(_name, _rollno, _class, _section);
             studentCount++;
            rollcount = _rollno;
    }
 
    function update(string memory _name,uint _rollno ,uint _class,string memory _section) public {
         require(studentCount>0,"Create Your Id First");
         Student storage s = StudentInfo[_rollno] ;
       s.name = _name;
       s.rollno = _rollno;
       s.class = _class;
       s.section = _section;
    
    }

}