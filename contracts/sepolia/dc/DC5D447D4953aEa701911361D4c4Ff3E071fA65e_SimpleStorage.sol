// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favouriteNumber;
    People public person = People({favouriteNumber: 9, name: "John"});
    People public person2 = People({favouriteNumber: 18, name: "Joy"});

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    struct DoYouAgree {
        bool yes;
        bool no;
    }

    People[] public people;
    DoYouAgree[] public trueFalses;

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(string => string) public firstNameToLastName;

    function store(uint256 _number) public virtual {
        favouriteNumber = _number;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _number) public {
        People memory newPerson = People({
            name: _name,
            favouriteNumber: _number
        });
        DoYouAgree memory agree = DoYouAgree({yes: true, no: false});
        nameToFavoriteNumber[_name] = _number;
        people.push(newPerson);
        trueFalses.push(agree);
    }

    function firstNameAndLastName(
        string memory _firstName,
        string memory _lastName
    ) public {
        firstNameToLastName[_firstName] = _lastName;
    }
}