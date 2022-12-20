/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

pragma solidity ^0.4.24;

contract Mapping {
    // Define the struct
    struct User {
        uint age;
        string name;
    }

    // Define the mapping from address to struct
    mapping(address => User) public users;

    // Function to add a user to the mapping
    function addUser(address _address, uint _age, string memory _name) public {
        // Set the values for the struct
        users[_address].age = _age;
        users[_address].name = _name;
    }

    // Function to retrieve a user from the mapping
    function getUser(address _address) public view returns (uint, string memory) {
        // Return the values from the struct
        return (users[_address].age, users[_address].name);
    }
}