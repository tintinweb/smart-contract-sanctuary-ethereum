// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;
    
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    // Arrays
    // uint256[] public favouriteNumbersList;
    People[] public peopleList;

    function store (uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // calldata -> variable can not be updated & it's only visible inside the function
    // memory -> variable is only visible inside the function
    // storage -> we can access variable in global scope
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // People memory newPerson = People({name: _name, favouriteNumber: _favouriteNumber});
        People memory newPerson = People(_name, _favouriteNumber);
        peopleList.push(newPerson);

        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // view & pure functions don't spend any gas
    // it only consts gas if you call this functions inside function which update blockchain state

    // view -> do not update our blockchain state in any way
    function retrieve () public view returns(uint256) {
        return favouriteNumber;
    }

    // pure -> do not update our blockchain state in any way & do not even read anything 
    // function add () public pure returns(uint256) {
    //     return (1 + 1);
    // }
}