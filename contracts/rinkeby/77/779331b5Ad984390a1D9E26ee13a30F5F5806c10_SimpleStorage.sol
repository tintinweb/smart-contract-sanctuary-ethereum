// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// import "hardhat/console.sol";

contract SimpleStorage {
    uint256 public myNumber;

    struct People {
        uint256 myNumber;
        string name;
    }

    People[] public person;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store (uint _myNumber) public {
        myNumber = _myNumber;
    }

    function retrieve() public view returns (uint256) {
        return myNumber;
    }

    function addPerson(uint256 _addNumber, string memory _addPerson) public {
        person.push(People({myNumber : _addNumber, name : _addPerson}));
        nameToFavoriteNumber[_addPerson] = _addNumber;
    }
}



// pragma solidity 0.8.7;

// contract SimpleStorage {

//     uint256 public favouriteNo;
    
//     struct People {
//         uint256 favouriteNo;
//         string name;
//     }

//     People[] public person;
//     mapping(string => uint256) public nameToFavoriteNumber;

//     function store (uint _favouriteNo) public {
//         favouriteNo = _favouriteNo;
//     }

//     function retrieve() public view returns (uint256) {
//         return favouriteNo;
//     }

//     function addPerson (string memory _name, uint256 _favouriteNo) public {
//         person.push(People({favouriteNo : _favouriteNo, name : _name}));
//         nameToFavoriteNumber[_name] = _favouriteNo;
//     }
    
// }