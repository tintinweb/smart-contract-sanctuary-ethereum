// SPDX-License-Identifier: MIT
pragma solidity 0.8.9; 

contract SimpleStorage {

    uint256  favoriteNumber; 

    mapping (string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }


    function add() public pure returns(uint256) {
        return 1+1;
    }
    function retrieve() public view returns(uint256) {
       return favoriteNumber;
    }


    function addPerson(string memory _name, uint256  _favoriteNumber) public {
        People memory  newPerson = People({favoriteNumber: _favoriteNumber, name : _name});
        people.push(newPerson);

        nameToFavoriteNumber[_name]=_favoriteNumber;
    }

}