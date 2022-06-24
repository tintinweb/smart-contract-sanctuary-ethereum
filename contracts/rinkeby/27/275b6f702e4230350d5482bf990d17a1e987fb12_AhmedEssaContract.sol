/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract OOPcontract{
    
    uint private myData ; // private state variable
    uint public myData2 ; // public state variable
    
    constructor() {
        myData2 = 30;
    }
    
    //public function
    function changeData(uint num) public {
        myData = num;
    }
     function readData() public view returns(uint){
      return  myData  ;
    }
     function addData(uint x , uint y) internal pure returns(uint){
      return  x + y  ;
    } 
     
}

contract MuhammedContract{
    function essa() public returns(uint){
        OOPcontract c = new OOPcontract();
        c.changeData(12);
        return c.readData();
    }
}

contract HameedContract is OOPcontract{
    uint private mySum;
    
    constructor() {
        
    }
    
    function getResult() public{
        mySum = addData(100,20);
    }
    
    function getTotalSum() public view returns(uint){
        return mySum;
    }
    
    function getMyData() public view returns(uint){
        return myData2;
    }
}



abstract contract ADDnumContract{
    function getSum() public virtual pure returns(uint);
}

contract OsamaContract is ADDnumContract{
    function getSum() public override pure returns(uint){
        uint x = 10;
        uint y = 200;
        uint z = 90;
        uint result = x+ y + z;
        return result;
    } 
}


interface SUBnumbers{
     function getSub() external pure returns(uint);
}

contract AhmedEssaContract is SUBnumbers{
   
     function getSub() external override pure returns(uint){
     
        uint y = 200;
        uint z = 100;
        uint result =   y - z;
        return result;
     }
}