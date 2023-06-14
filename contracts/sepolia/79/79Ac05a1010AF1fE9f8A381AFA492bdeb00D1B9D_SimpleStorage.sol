// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 favNumber;
    struct People {
        uint256 favNumber;
        string name;
    }
    People[] public people;
    // mapping for a new people with a fav number
    mapping(string => uint256) public nameToFavNumber;

    // mapping a user address with a balance
    // mapping (address=>uint256) public balance;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
        // retriveFavNum();
    }

    // view , pure

    function retriveFavNum() public view returns (uint256) {
        return favNumber;
    }

    // function add() public pure returns(uint256) {
    //     return (1+1);
    // }

    function addPeople(string memory _name, uint256 _favNumber) public {
        // People memory newPerson = People(_favNumber,_name);
        // people.push(newPerson);
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }

    // function addBalance(address _address, uint256 _ammount) public {
    //     balance[_address] = _ammount;
    // }clear
}