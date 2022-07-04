/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {

    uint256 public favouriteNumber;
    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
	    uint256 favouriteNumber;
	    string name;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);

        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }
}

    //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4