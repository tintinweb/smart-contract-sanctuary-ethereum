/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Encrypt {
    struct Profile {
        string handle;
        string encryptedString;
        string encryptedSymmetricKey;
    }
    mapping (address => Profile) userProfile;

    function setprofile (string memory _handle, string memory _encryptedString, string memory _encryptedSymmetricKey) public {
        Profile memory _user;
        _user.handle=_handle;
        _user.encryptedString= _encryptedString;
        _user.encryptedSymmetricKey=_encryptedSymmetricKey;
        userProfile[msg.sender]= _user;

    }
    function getProfile(address _profile) public view returns(Profile memory ){
        return userProfile[_profile];
    }
}