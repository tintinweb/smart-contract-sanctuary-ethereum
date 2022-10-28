/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Portal {


    mapping(address => UserInfo) userInfo;

    struct UserInfo {
        string name;
        string telegram;
        string twitter;
        uint256 contribution;
    }

    uint256 public constant MAX_CONTRIBUTION = 1100000000000000000;
    bool public open;

    address public owner;

    event Contibuted(address user, string name, string telegram, string twitter, uint256 contribution);

    constructor() {
        owner = msg.sender;
    }

    function getUserInfo(address user) external view returns(string memory, string memory, string memory, uint256){
        return (userInfo[user].name, userInfo[user].telegram, userInfo[user].twitter, userInfo[user].contribution);
    }

    function contribute(string calldata _name, string calldata _telegram, string calldata _twitter) external payable{
        require(open, "Not open");
        require(msg.value > 0, "Not enough money");
        uint256 userContribution = userInfo[msg.sender].contribution;
        require(userContribution + msg.value <= MAX_CONTRIBUTION, "You are exceeding MAX CONTRIBUTION");
        userInfo[msg.sender] = UserInfo(_name, _telegram, _twitter, userContribution + msg.value);
        emit Contibuted(msg.sender, _name, _telegram, _twitter, msg.value);   
    }

    function changeOwner(address newOwner) external{
        require(owner == msg.sender, "You are not the owner");
        owner = newOwner;
    }

    function setOpen(bool status) external {
        require(owner == msg.sender, "You are not the owner");
        open = status;
    }

    function rescueWETH(uint256 amount) external{
        require(owner == msg.sender, "You are not the owner");
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

}