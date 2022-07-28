// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Student_list {
    struct Student {
        string name;
        uint rollno;
        string class;
        string batch;
      
        
    }
    mapping( uint =>Student) public Studentlist;
    
    uint public STUDENT;
    uint rollcount;
    address manager;
    bool private isInitialized ;

    function initialize() external {
        require(!isInitialized , "Function already initialized");
        manager = msg.sender;
        isInitialized =true;
    }
    
    function create(string memory _name,uint _rollno,string memory _class,string memory _batch) public {
         Studentlist[_rollno] = Student(_name,_rollno,_class,_batch);
         
         STUDENT++;
           

    }
     function updatedetails( string memory _name,uint _rollno,string memory _class,string memory _batch) public {
         require (msg.sender ==manager,"Only Manager Can Update Details");
         require(STUDENT>0,"Create id First");
         Student storage s1 = Studentlist[_rollno];
         s1.name = _name;
         s1.rollno =_rollno;
         s1.class = _class;
         s1.batch= _batch;


    }

}