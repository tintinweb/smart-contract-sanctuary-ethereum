/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OdysseyRegistry {
    string[] private usernames;
    mapping(string => uint256) private usernameToIndex;
    mapping(address => uint256) private addressToIndex;
    mapping(string => address) private usernameToAddress;

    function setUsername(string calldata _username) external {
        require(bytes(_username).length >= 7 && bytes(_username).length <= 20, "Username must be between 7 and 20 characters");
        require(isAlphanumeric(_username), "Username must be alphanumeric");
        require(usernameToIndex[_username] == 0, "Username is already taken");
        usernames.push(_username);
        usernameToIndex[_username] = usernames.length;
        addressToIndex[msg.sender] = usernames.length;
        usernameToAddress[_username] = msg.sender;
    }

    function getUsernameByAddress(address _address) external view returns (string memory) {
        uint256 index = addressToIndex[_address];
        require(index > 0, "No username found for this address");
        return usernames[index - 1];
    }


    function getAddressByUsername(string calldata _username) external view returns (address) {
        address userAddress = usernameToAddress[_username];
        require(userAddress != address(0), "No address found for this username");
        return userAddress;
    }

    function searchUsername(string calldata _query) external view returns (string[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < usernames.length; i++) {
            if (bytes(usernames[i]).length >= bytes(_query).length) {
                bool isMatch = true;
                for (uint256 j = 0; j < bytes(_query).length; j++) {
                    if (bytes(usernames[i])[j] != bytes(_query)[j]) {
                        isMatch = false;
                        break;
                    }
                }
                if (isMatch) {
                    count++;
                }
            }
        }
        string[] memory results = new string[](count);
        count = 0;
        for (uint256 i = 0; i < usernames.length; i++) {
            if (bytes(usernames[i]).length >= bytes(_query).length) {
                bool isMatch = true;
                for (uint256 j = 0; j < bytes(_query).length; j++) {
                    if (bytes(usernames[i])[j] != bytes(_query)[j]) {
                        isMatch = false;
                        break;
                    }
                }
                if (isMatch) {
                    results[count] = usernames[i];
                    count++;
                }
            }
        }
        return results;
    }

    function isAlphanumeric(string memory _str) internal pure returns (bool) {
        bytes memory b = bytes(_str);
        for (uint256 i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (!((char >= 0x30 && char <= 0x39) || (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A))) {
                return false;
            }
        }
        return true;
    }
}