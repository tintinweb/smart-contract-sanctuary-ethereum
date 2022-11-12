// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AdminConsole {
    address public immutable i_owner;
    address[] adminMembers;
    address feeAccount;
    uint feePercent;

    constructor() {
        i_owner = msg.sender;
    }

    function addMember(address account) external {
        require(
            msg.sender == i_owner,
            "You do not have permission to add members"
        );
        adminMembers.push(account); //add event
    }

    function removeMember(address account) external {
        require(
            msg.sender == i_owner,
            "You do not have permission to add members"
        );
        for (uint i = 0; i < adminMembers.length; i++) {
            if (adminMembers[i] == account) {
                adminMembers[i] = adminMembers[adminMembers.length - 1];
                adminMembers.pop();
            }
        }
    }

    function isAdmin(address account) public view returns (bool) {
        for (uint i = 0; i < adminMembers.length; i++) {
            if (adminMembers[i] == account) {
                return true;
            }
        }
        return false;
    }

    function setFeeAccount(address account) public {
        require(msg.sender == i_owner, "You do not have set this value!");
        feeAccount = account;
    }

    function getFeeAccount() public view returns (address) {
        return feeAccount;
    }

    function setFeePercent(uint _feePercent) public {
        require(msg.sender == i_owner, "You do not have set this value!");
        feePercent = _feePercent;
    }

    function getFeePercent() public view returns (uint) {
        return feePercent;
    }
}