/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract log{
    mapping (address => string) public nicknameOf;
    event log(address indexed challenger, string nickname, string message);

    function ping() public {
        emit log(msg.sender, nicknameOf[msg.sender], "text" );
    }
    function setNickname(string memory _nickname) public {
        nicknameOf[msg.sender] = _nickname;
    }
}