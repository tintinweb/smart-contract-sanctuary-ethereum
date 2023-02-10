/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // ^ above OR >=0.8.7 <0.9.0

contract SimpleStorage {
    uint256 favoriteNumber; //initialized to 0
    struct People {
        uint256 favoriteNumber;
        string name;
    } /*Not efficient
    People public person= People({favoriteNumber: 2, name: "rabia"});
    People public person= People({favoriteNumber: 3, name: "ali"});// using struct
    */
    People[] public people; // dynamic array
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber; // blue button only for view and pure, means no modification
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson= People({favoriteNumber: _favoriteNumber, name: _name});
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    } /* six places to store data stack, memory, storage, calldata, code, logs*/
}