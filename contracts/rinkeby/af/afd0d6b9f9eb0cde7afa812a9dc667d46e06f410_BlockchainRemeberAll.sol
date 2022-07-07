/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity 0.8.0;

contract BlockchainRemeberAll {

    struct User{
        string fullName;
        uint8 age;
        string country;
        string city;
    }

    mapping (address => User) public users;

    function AddMe(string memory _fullName, uint8 _age, string memory _country, string memory _city) public returns(bool) {
        User storage user = users[msg.sender];
        require (user.age == 0, "user already exists");
        require (_age != 0, "Incorrect age");
        user.fullName = _fullName;
        user.age = _age;
        user.country = _country;
        user.city = _city;
      
        return true;
    }
}