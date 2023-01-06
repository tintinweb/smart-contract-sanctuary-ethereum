// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract SimpleStorage{
 
uint  age;//initially has value of zero

mapping(string => uint) public nametoage;//mapping

struct People//making structures
{
    uint age;
    string name;
}
//making of arrays
People[] public people;

 function store(uint number) public {   //declararion of function
     age = number;
 }
// view, pure
   function retrieve() public view returns(uint){
   return age;
}
function addperson(string memory _name, uint number) public{ // memory, calldata,storage
    people.push(People(number, _name));
    nametoage[_name]=number;
}



}