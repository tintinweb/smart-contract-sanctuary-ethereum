//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Owner {
    constructor() {
        owner = msg.sender;
    }

    uint256 counter = 0;

    struct Users {
        uint256 age;
        string name;
    }

    mapping(uint256 => Users) mapUser;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not Owner");
        _;
    }

    //Users[] public users;

    function addUser(string memory _name, uint256 _age) public {
        counter = counter + 1;
        mapUser[counter].age = _age;
        mapUser[counter].name = _name;
    }

    function getUser(uint256 _index)
        public
        view
        returns (uint256, string memory)
    {
        return (mapUser[_index].age, mapUser[_index].name);
    }

    function update(uint256 _index, uint256 _newAge) public onlyOwner {
        mapUser[_index].age = _newAge;
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }
}