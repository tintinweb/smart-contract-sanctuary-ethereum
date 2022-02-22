/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AccountLinks {
    mapping(address => address) public magicToTrust;
    mapping(address => address) public trustToMagic;
    mapping(uint256 => address) public magicUsers;
    mapping(address => uint256) public magicUsersToCount;
    uint256 public totalUsers;

    event AccountLinked(
        address MagicAddress,
        address TrustAddress,
        uint256 timestamp
    );
    event AccountChangeAddress(
        address MagicAddress,
        address TrustAddress,
        uint256 timestamp
    );

    function linkAccounts(address trustAddress) public {
        magicToTrust[msg.sender] = trustAddress;
        trustToMagic[trustAddress] = msg.sender;

        if (magicUsersToCount[msg.sender] == 0) {
            totalUsers += 1;
            magicUsers[totalUsers] = msg.sender;
            magicUsersToCount[msg.sender] = totalUsers;
        }

        emit AccountLinked(msg.sender, trustAddress, block.timestamp);
    }

    function changeAccountAddress() public {
        require(magicToTrust[msg.sender] != address(0), "No linked account");

        emit AccountChangeAddress(msg.sender, magicToTrust[msg.sender], block.timestamp);
    }
}