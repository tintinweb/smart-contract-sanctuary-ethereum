//  SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
 
contract SimpleStorage {
    //Data types-  boolean,int,uint,address,bytes,string
    uint256 favoriteNumber; //intialized to 0 and default visibility is internal and stored in storage
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual { 
        favoriteNumber =_favoriteNumber;
    }
    
    function retrieve() public view returns(uint){
        return favoriteNumber;
    }

    function addPerson(string memory _name,uint256 _favoriteNumber) public{
        people.push(People(_favoriteNumber, _name));
        // or 
        // People memory newPerson = People({favoriteNumber: _favoriteNumber,name: _name});
        // people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;   
    }

}