/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.6.0;

contract SimpleStorage {
    //Global elements declaration
    uint256 internal favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] internal people; 
    //People public person = People({favoriteNumber: 2, name: "Patric"  });
    mapping (string=>uint256) internal nameToFavoriteNumber;

    //Functions declaration
    function storeNumber(uint256 _favoriteNumber) public{
        favoriteNumber=_favoriteNumber;
    }

    function retriveNumber() public view returns(uint256){
        return (favoriteNumber);
    }

    function addPerson (string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //people.push(People({favoriteNumber: _favoriteNumber, name: _name  }));
        nameToFavoriteNumber [_name]=_favoriteNumber;
    }

    function getPersonNameById(uint256 _id) public view returns(string memory) {
        People memory person = people[_id];
        return(person.name);
    }
}