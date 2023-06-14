/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract UserInformation {
    struct UserInfo {
        string firstName;
        string lastName;
        uint256 age;
        string sex;
        string ipfsHash;
    }

    mapping(address => UserInfo) private users;

    event UserAdded(
        address indexed userAddress,
        string firstName,
        string lastName,
        uint256 age,
        string sex,
        string ipfsHash
    );

    function addUser(
        string memory _firstName,
        string memory _lastName,
        uint256 _age,
        string memory _sex,
        string memory _ipfsHash
    ) public {
        require(bytes(_firstName).length > 0, "First name cannot be empty");
        require(bytes(_lastName).length > 0, "Last name cannot be empty");

        UserInfo storage user = users[msg.sender];
        user.firstName = _firstName;
        user.lastName = _lastName;
        user.age = _age;
        user.sex = _sex;
        user.ipfsHash = _ipfsHash;

        emit UserAdded(msg.sender, _firstName, _lastName, _age, _sex, _ipfsHash);
    }

    function getUser(
        address _userAddress
    )
        public
        view
        returns (
            string memory firstName,
            string memory lastName,
            uint256 age,
            string memory sex,
            string memory ipfsHash
        )
    {
        UserInfo storage user = users[_userAddress];
        return (user.firstName, user.lastName, user.age, user.sex, user.ipfsHash);
    }
}