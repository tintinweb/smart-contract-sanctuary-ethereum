// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // This is initialised to 0 by default;
    uint256 public favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    uint256[] public favouriteNumberList;
    People[] public people;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage
    // calldata, memory -> temporary, storage -> exist outside of the function, vars declared without explicit location default to storage
    // calldata temp vars which can be modified, memory vars can be modified
    // structs, mappings, arrays need memory or calldata tags when given as function params.
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}