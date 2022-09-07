/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    /**
     * @dev map for list of owners
     */
    address creator;
    mapping(address => uint256) public owner;
    uint256 index = 0;

    /**
     * @dev constructor, where first user is an administrator
     */
    constructor() {
        owner[msg.sender] = ++index;
        creator = msg.sender;
    }

    /**
     * @dev modifier which check the status of user and continue only if msg.sender is administrator
     */
    modifier onlyOwner() {
        require(owner[msg.sender] > 0, "onlyOwner exception");
        _;
    }

    /**
     * @dev adding new owner to list of owners
     * @param newOwner address of new administrator
     * @return true when operation is successful
     */
    function addNewOwner(address newOwner) public onlyOwner returns(bool) {
        owner[newOwner] = ++index;
        return true;
    }

    /**
     * @dev remove owner from list of owners
     * @param removedOwner address of removed administrator
     * @return true when operation is successful
     */
    function removeOwner(address removedOwner) public onlyOwner returns(bool) {
        require(msg.sender != removedOwner, "Denied deleting of yourself");
        owner[removedOwner] = 0;
        return true;
    }
}


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