//SPX-License-Identifier:MIT

pragma solidity ^0.8.13;

contract SimpleStorage{
    uint favNumber;
    mapping(string=>uint) public nameToFavoriteNumber;
    struct People{
        string name;
        uint favNumber;
    }
    People [] people;
    function store(uint _favNumber) public {
        favNumber=_favNumber;
    }
    function retrieve()public view returns(uint){
        return favNumber;
    }
    function addPerson(string memory _name,uint _favNumber)public {
        // people.push(People({name:_name,favNumber:_favNumber}));this is same as
        people.push(People(_name,_favNumber));
        nameToFavoriteNumber[_name]=_favNumber;
    }
}