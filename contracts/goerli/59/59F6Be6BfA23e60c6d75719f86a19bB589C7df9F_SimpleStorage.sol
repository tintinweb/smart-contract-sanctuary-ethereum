/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // This version or higher

/*
 * These contracts are compiled to EVM specifications.
 * Bcz of the EVM. Contracts in Solidity can be deployed to any EVM based blockchain
 * Fantom, polygon, Avalanche
 */

contract SimpleStorage {
    // This gets initialized as zero
    // Creates a getter fuction. In solidity variables are just function calls. And yes, they cost gas
    // By default variable are set to internal
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // View functions don't let it slide when you change the blockchain & Same for pure functions
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // These functions disallow both read and write on the blockchain
    // function add() public pure returns(uint256){
    //     return (1 + 1);
    // }

    /*
     * View and pure functions don't spend any gas fees. Because they don't change the blockchain (blue)
     * Basicly calling view and pure functions is free, unless called inside of function that costs gas
     * While other functions that change the blochains pay also the fees. (orange)
     */

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        /*
         * So memory can change, and calldata can't.
         * Storage is default for primitive types.
         * That's why we didn't use memory on _favoriteNumber
         */
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}