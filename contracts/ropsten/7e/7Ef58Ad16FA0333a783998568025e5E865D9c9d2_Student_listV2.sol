// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Student_listV2 {
    struct Student {
        string name;
        uint rollno;
        string class;
        string batch;
      
        
    }
    mapping( uint =>Student) public Studentlist;
    
    uint  STUDENT;
    uint rollcount;
    address manager;
     bool private isInitialized ;

    function initialize() external {
        require(!isInitialized , "Function already initialized");
        manager = msg.sender;
        isInitialized =true;
    }

    // function initalize() external {
    //     manager = msg.sender;
    // }
    
    function create(string memory _name,uint _rollno,string memory _class,string memory _batch) public {
         require(_rollno != rollcount ,"To Update go To Update Details");
         Studentlist[_rollno] = Student(_name,_rollno,_class,_batch);
         
         STUDENT++;
         rollcount++;    

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
    function StudentCount() view public returns(uint){
        return STUDENT;
    }

}