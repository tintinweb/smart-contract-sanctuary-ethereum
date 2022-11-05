/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // bool public hasFavoriteNumber = true;
    uint256 public favoriteNumber;
    address public owner;
    // string public favoriteNumberString = "Eleven";
    // int256 public favoriteInt = -11;
    // address public myAddress = 0xbE9A8F63F9b16F62b4cd68f8202f649a2ee0eE7b;
    // bytes32 public favoriteBytes = "dog";

    // Manualy create person
    // People public person = People ({favoriteNumber: 11, name: "Dmitry"});

    constructor() {
        owner = msg.sender;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
        string favoriteAnimal;
    }

    // Build array
    People[] public people;

    function addPerson(string memory _name, uint256 _favoriteNumber, string memory _favoriteAnimal) public {
        // uint exactAmount = 3000;
        // require (msg.value == exactAmount); 
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name, favoriteAnimal: _favoriteAnimal});
        people.push(newPerson);

        // add to map
        nameToFavoriteNumber[_name] = _favoriteNumber;

        // Other option to add person to array
        // people.push(People(_favoriteNumber, _name));
        // nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    modifier onlyOwner() {
        require (msg.sender == owner, "Caller is not the owner");
        _;
    }
}