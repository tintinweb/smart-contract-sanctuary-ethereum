/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;  

contract SimpleStorage {

    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
// [] is a dynamic aray [29] static array
    People [] public people;
    
    function store( uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

// View and pure do not cost any gas as you are only reading from the blockchain
    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }

// calldata = temporary data that can' be modified, memory temporary data that can be modified, storage permenant data that can be modified 
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}