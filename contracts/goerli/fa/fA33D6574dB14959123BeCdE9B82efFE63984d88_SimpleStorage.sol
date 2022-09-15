// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract SimpleStorage{
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavroiteNumber;

    mapping(uint256 => People) public nameToStruct;

    People[] public people;


    struct People{
        uint256 favoriteNumber;
        string name;

    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber=_favoriteNumber;
        favoriteNumber=favoriteNumber +1 ;
    }

    function retrieve() public view returns(uint256){
          return favoriteNumber;
    }

    function addPerson(string memory _name , uint256 _favoriteNumber) public {
        People memory newPerson=People(_favoriteNumber,_name);
        people.push(newPerson);
        nameToFavroiteNumber[_name]=_favoriteNumber;
        nameToStruct[_favoriteNumber]=newPerson;
    }

    function getAge(uint256 _input) public view returns (string memory){
          string memory age= nameToStruct[_input].name;
          return age;
          
    }

    function addMe (uint256 _input) public view returns(uint256){
        uint256 azeez= nameToStruct[_input].favoriteNumber;
        return azeez;
    }

    
    

}