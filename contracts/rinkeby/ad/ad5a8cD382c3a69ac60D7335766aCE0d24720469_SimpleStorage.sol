//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleStorage{

uint256  favNumber; 

// People  firstPerson = People({favNumber:7,name:"Joan"});
// People  secondPerson = People({favNumber:17,name:"James"});

mapping  (string=>uint256) public nametofavNum;
mapping (uint256=>string) public favNumToName;

struct People{          
    uint256 favNumber;
    string name;    
}

People[] public peoples;  

function Store (uint256 _favNumber, uint _newNumber) public  {
    favNumber = _newNumber*_favNumber ;    
}

function retrieve() public view returns(uint256){
      return favNumber;
}

function addPeople( uint256   _favNumber, string memory _name) public {
    
   peoples.push(People(_favNumber,_name));
   nametofavNum [_name] = _favNumber;
 favNumToName [_favNumber]=_name;

}
}