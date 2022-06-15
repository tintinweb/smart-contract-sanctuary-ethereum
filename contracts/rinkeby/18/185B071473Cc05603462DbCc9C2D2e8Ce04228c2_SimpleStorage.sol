//SPDX-License-Identifier:MIT
pragma solidity >=0.6.0 <=0.9.0;

contract SimpleStorage {
    uint public favouriteNumber;

    People[] public people;
    mapping(string => uint256) public nameToNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function addPeople(uint _favouriteNumber, string memory _name) public {
        people.push(People(_favouriteNumber, _name));
        nameToNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}