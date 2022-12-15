/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Holder {
    struct UserProfile {
        string aId;
        string Name;
        string Dob;
        string Gender;
        string Address;
        string Mobile;
        string email;
        string cId;
        uint256 age;
    }

    mapping(string => UserProfile) private _users;

    UserProfile Profile;

    function setProfile(
        string memory aId,
        string memory Name,
        string memory Dob,
        string memory Gender,
        string memory Address,
        string memory Mobile,
        string memory email,
        string memory cId,
        uint256 age
    ) public {
        Profile = UserProfile(
            aId,
            Name,
            Dob,
            Gender,
            Address,
            Mobile,
            email,
            cId,
            age
        );
        _users[aId] = Profile;
    }

    function getProfile(string memory aId)
        public
        view
        returns (UserProfile memory)
    {
        return _users[aId];
    }
}