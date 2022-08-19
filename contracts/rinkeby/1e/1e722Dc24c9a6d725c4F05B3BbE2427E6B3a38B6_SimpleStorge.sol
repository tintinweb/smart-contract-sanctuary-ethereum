//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorge {
    uint256 favourateNumber;
    mapping(string => uint256) public nameToFavourateNumber;

    function store(uint256 _favourateNumber) public {
        favourateNumber = _favourateNumber;
    }

    function retrive() public view returns (uint256) {
        return favourateNumber;
    }

    struct People {
        uint256 favourateNumber;
        string name;
    }

    People public p = People({favourateNumber: 2, name: "Ankit"});
    People[] public people;

    function addPerson(string memory _name, uint256 _favourateNumber) public {
        People memory p1 = People({
            favourateNumber: _favourateNumber,
            name: _name
        });
        people.push(p1);
        nameToFavourateNumber[_name] = _favourateNumber;
    }
}