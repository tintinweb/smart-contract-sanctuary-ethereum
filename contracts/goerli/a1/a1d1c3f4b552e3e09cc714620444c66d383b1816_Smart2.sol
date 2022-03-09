/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Smart2 {

    mapping(address => uint8) private userAges;
    mapping(address => string) private userNames;

    function setUserInfo(uint8 newUserAge, string memory newUserName) public {
        userAges[msg.sender] = newUserAge;
        userNames[msg.sender] = newUserName;
    }

    function getUserInfo() public view returns (uint8, string memory){
        return (userAges[msg.sender], userNames[msg.sender]);
    }
}