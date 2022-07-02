//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    //boolean, uint(only positive whole numbers), int(pos or neg), address, bytes, string ""

    uint256 public favouriteNumber;
    mapping (string => uint256) public thisismapping;



    struct People {
        string name;
        uint256 favouriteNumber;
    }
  
   

    People [] public people;
  
   //variables to use the push function 

    function store (uint256 _favouriteNumber) public virtual {
    favouriteNumber = _favouriteNumber;}
   

    function addPerson(string memory _name, uint256 _favouriteNumber)public {
        people.push (People(_name, _favouriteNumber));
         thisismapping[_name]= _favouriteNumber;}
     //Capital People is from struct & people is from variable 

     
    
   

    function retrieve () public view returns (uint256){
        return favouriteNumber;
    }
}