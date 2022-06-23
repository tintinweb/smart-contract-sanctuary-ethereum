//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage{
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct people{
        uint256 favoriteNumber;
        string name;
    }

    people[] public People;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrive() public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber)public {
        People.push(people(_favoriteNumber,_name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}