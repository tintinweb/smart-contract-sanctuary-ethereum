//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //solidity version to be used

/*"^0.8.7" means every version after and including 0.8.7
>=0.8.7<0.9.0 means every version after and including 0.8.7 but older than 0.9.0*/

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    /* a mapping is a data structure where a key 
    is mapped to a single value aka a dictionary*/

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    /* initialisation of a dynamic array of People 
    type called people*/

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions don't allow for modifications of state
    // they don't spend any gas
    function retrieve() public view returns (uint256) {
        /* this function is the equivalent of what gets
        created when using the 'public' keyword with
        variables such as favorite number*/
        return favoriteNumber;
    }

    /* calling view functions is free unless they are called
    inside of a function that costs gas*/

    /* calldata-temporary memory that can't be modified
       memory - temporary memory that can be modified
       storage - permanent memory that can be modified
       temporary memory gets destroyed after function call is complete 
       Only arrays, structs and mappings need memory allocation specified*/
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}