/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-Licence-Indentifier: MIT

pragma solidity 0.6.0;

contract SimpleStorage {
    uint256 favouriteNumber = 5;
    //bool favouriteBool = true;
    //string favouriteString = "String";
    //address favouriteAddress = 0x9591F37cB3AD63e718A72D16a2B548204f9c1397;    

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}