/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract AttendanceRegister{
    struct Students{
        uint256 roll;string name;uint256 class;uint256 joiningdate;
    }
    
    mapping(uint256=>Students) public studentsData;
    uint256 id=1;
    address admin;

    constructor(){
      admin=msg.sender;
    }

    event NewStudent(string _name,uint256 indexed _class,uint256 indexed _joiningdate,uint256 indexed roll);

    function addStudent(string memory _name,uint256 _class,uint256 _joiningdate) public OnlyAdmin{
          require(bytes(_name).length>0,"Name can't be empty");
          require(_class>=1&&_class<=12,"Please enter a valid class number");
          studentsData[id]=Students(id,_name,_class,_joiningdate);
          emit NewStudent(_name,_class,_joiningdate,id);
          id++;
    }
 modifier OnlyAdmin{
     require(msg.sender==admin);
     _;
}

}