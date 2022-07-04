/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //currently one of the most stable

contract SimpleStorage {
    //variable types: boolean, uint, int, address, bytes
    uint256 public favoriteNumber; //initialized to 0 if not specified, global scope
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People public person = People("patrick", 2);

    //alternate declaration style:
    //People public person = People({favoriteNumber: 2, name: "patrick"});

    People[] public peopleArray;

    mapping(string => uint256) public nameToFavNumMapping;

    //the "virtual" keyword identifier indicates that this function can be overridden by a child contract
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //add the following code will cause the function to use more gas because it makes it computatioinally more expensive
        // favoriteNumber += 1;
    }

    //struct, mapping and array need to be specified as memory or calldata when passed as a parameter to a function
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peopleArray.push(People(_name, _favoriteNumber));
        peopleArray.push(person);
        nameToFavNumMapping[_name] = _favoriteNumber;
    }

    function getFavNum() public view returns (uint256) {
        return favoriteNumber;
    }

    function getFavNumMapping(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavNumMapping[_name];
    }
}