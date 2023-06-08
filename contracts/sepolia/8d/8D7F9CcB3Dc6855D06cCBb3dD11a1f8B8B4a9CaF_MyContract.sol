// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

contract MyContract {
    string public name = "Rohit";

    struct User {
        string name;
        string email;
        string mobile;
    }

    mapping(uint256 => User) public users;
    uint256 public count;

    function setuser(
        string memory _name,
        string memory _email,
        string memory _mobile
    ) public returns (uint) {
        User storage user = users[count];

        user.name = _name;
        user.email = _email;
        user.mobile = _mobile;
        count++;
        return count;
    }
}