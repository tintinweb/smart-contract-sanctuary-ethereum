/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// File: contracts/SimpleStorage.sol


pragma solidity 0.8.7;
// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns (uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// File: contracts/StorageFactory.sol


pragma solidity ^0.8.0;

// Can import path or github


contract StorageFactory {
    // Class, Visibility, Name
    SimpleStorage public simpleStorage;

    // Find Contracts Created
    address[] public contracts;

    event contractCreated(address newAddress);

    function createSimpleStorageContract() public {
        simpleStorage = new SimpleStorage();
        contracts.push(address(simpleStorage));
    }
}