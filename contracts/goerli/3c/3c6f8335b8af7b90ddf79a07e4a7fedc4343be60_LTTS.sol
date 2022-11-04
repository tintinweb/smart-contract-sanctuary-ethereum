/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;
contract LTTS
{

    //comments-
    /*
------------------------
This is my first contract
-------------------------
*/
//CamelCase- isOpenToAllToday
//State Vriables - Value Type and reference type
//value type
//Boolean- Bool
 bool isValid; //true or false
bool isOpen;

// //Integer- Int & uint

// int Temperature; //-10,0,10,100...
// uint8 percentage; //0,99,100 => 2*8 , 0-255
// uint16 yearOfBirth; // 1950-2000
// uint256 distance; //1,1000,1000000000=> 2*256-1

// constuctor- Executes only one- Exectues at the time of demployement of contract- and there is only one constructor fnction.
 constructor(){
     admin =payable (msg.sender);
     isOpen=true;
    //  distance = _distance;
     startTime = uint32(block.timestamp) +30;
     stopTime = startTime + 60;
     

 }
    address payable admin;
    event voting(address voter, uint256 Time);
    function vote()external payable {
        // uint bal = msg.sender.balance;
        // if (bal>= 1 ether){
        //     require(msg.value==99 ether,"Incorrect ether");
        // } else {
        //     require(msg.value== 1 wei, "Incorrect wei");
        // }
        require(msg.value== 1 ether, "Incorrect wei send");
        admin.transfer(1 ether);
        (bool success,) = admin.call{value : 1 ether}("");
        require(success,"call failed");
        // (bool done, uint amt) = getbalance();
        // require(done,"Not done");
        // require(block.timestamp>startTime , "Too early");
        // require(block.timestamp<stopTime , "Time is Up");
        // emit voting (msg.sender, block.timestamp);
    }
    function getbalance()external view returns(uint){
        return address(this).balance;
    }

    //send or receive Ether
    //msg.value - Amount wei send with message
    //transfer ether - to.transfer(amount)
//Functions- Executable code

/*function viewOwner() public view returns(address,bool,bool)
{
return (owner, isOpen , isValid);
}*/

// function setPercentage(uint8 _percentage)public {
//     percentage= _percentage;
//     isOpen=false;
    
// }

// //the function that read from ledger is called View function.
// function viewPercentage()public view returns(uint8){
//     return percentage;
// }
// //the function that does not read and write from ledger is called Pure function.
//  function calculate (uint a, uint b) public pure returns(uint){
//      return(a+b);
//  }
//  // address- public key 20 byte
 address owner;
//  address manager;
//  address employee;
//msg.sender

//  function addEmpolyee(address _employee) public {
//      employee= _employee;
//  }

 
//  /*function addMe() public{
//      employee= msg.sender;
//  }
 

//   function viewEmpolyee() public view returns(address) {
//      return employee;
//  }*/
// //reference
// //Array- collection of element of similar type, fixed or dyanamic
// //Fixed
// uint8[2] percentages;
// address[2] owners;
// //Dynamic

// address[] employees;
// function addMe() public{
//      employee= msg.sender;
//      employees.push(msg.sender);
//  }

//  function viewEmployees() public view returns(address[] memory)
//  {
//      return employees;
//  }
// function removeLast() public{
//     employees.pop();
// }

// function checkLength()public view returns(uint){
//     return employees.length;
// }
//  function asssignOwners(address _owner2) public  {
//      owners[0]=msg.sender;
//      owners[1]=_owner2;
//  }
//  function viewOwners() public view returns(address[2] memory)
//  {
//      return owners;
//  }
 //string- string, alphanumeric data
//  string firstName;
//  string postalAddress;
//  string welcome;
//  function welcomeMessage( string memory _welcome)public{
//      welcome=_welcome;
//  }

//  function viewWelcome() public view returns(string memory){
//      return welcome;
//  }
 
 // Mapping - key value pair.
//  mapping (address =>uint)balances;
//  mapping(uint =>uint)transactions;
//  mapping(address =>bool)validity; 
//  mapping(address =>mapping(uint=>bool))nested;
//  mapping (uint=>uint[])empNos;
//  address[] depositors;

//  function updateMyBalance(uint _credit) public {
//      balances[msg.sender]=_credit;
//     // some code to check if address is unique
//     // if()
//     // { depositors.push(msg.sender);
//     // }
//  } 

//  function addToBalance(uint _credit) public {
//      balances[msg.sender]+= _credit;
//  }
 
//  function viewMyBalance() public view returns(uint){
//      return balances[msg.sender];
//  }

//  //struct -struct- elementof different type 
// struct employeeData{

//        uint emplNo;

//        bool isJoinded;

//        string teamName;

//    }
// mapping (address => employeeData) masterRecord;

function newJoinee(uint _no, string memory _team)public {

       masterRecord[msg.sender]= employeeData(_no,true,_team);
}

function viewMyTeamName()public view returns(string memory, uint){

       return (masterRecord[msg.sender].teamName,

       masterRecord[msg.sender].emplNo);

   }

struct ownerData{
 address owner;
  bool isOwner;
 string coName;
  }

  struct employeeData{

      uint emplNo;

      bool isJoined;

      string teamName;

  }

  employeeData[] public eDatas;

  mapping (address=> employeeData) masterRecord;



  function makestruct() public{

    employeeData memory eData=employeeData(2,true,"meta");

    employeeData memory eData1=employeeData({isJoined:true,teamName:"Metaverse",emplNo:32});

    employeeData memory d1data;

    d1data.emplNo=22;

    d1data.isJoined=true;

    d1data.teamName="Meta1";

    eDatas.push(eData);

    eDatas.push(eData1);

    eDatas.push(d1data);



      }

   //visibility: external, Internal, public & private

   //Function that is only called from internally in contract is called internal function.

 function ext() external{
       //Some code
      }

     function intr() internal{
         //ext();
     }

     function pub1() public{

     }


     
     function pvt() private{

     }

     function changeOwner(address _newOwner, uint _number)external onlyOwner(_number){
         owner=_newOwner;
         emit ChangeOwner(owner,msg.sender,_number);
     }

     // modifier

     modifier onlyOwner(uint _x){
         require(msg.sender==owner, "Error ::: only for owner");
         require(isValid || isOpen, "Error :: Not valid");
         require(_x<100, "Error: Greater than 100");
         _;
         isOpen = false;
     }

     // Event
     event ChangeOwner(address indexed NewOwner, address indexed OutgoingOwner, uint Number);

    
    //Time - Unix timestamp : 1st jan 1970 =0
    uint32 startTime;
    uint32 stopTime;
    // time right now - block.timestamp (now)

   
}