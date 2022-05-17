/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Signal {
    address public owner;
    uint256 public subscriptionFee = 1 ether;
    uint256 public totalUsers = 0;
    uint8 public referrerShare = 10;

    constructor() {
        owner = msg.sender;
    }

    struct User {
        uint256 payment;
        address wallet;
        bytes32 telegramId;
    }

    mapping(uint256 => User) private Users;
    mapping(address => uint256) private walletAccounts;
    mapping(address => uint256) private referrals;
    mapping(address => bool) private isUser;

    /**************************************************************************************************
     * @dev modifiers
     **************************************************************************************************/
    modifier nonContract() {
        require(tx.origin == msg.sender, "Contract not allowed");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier minimumPayment() {
        require(msg.value >= subscriptionFee, "Registeration fee is low");
        _;
    }

    /**************************************************************************************************
     * @dev  Functions
     **************************************************************************************************/
    function TransferOwnership(address newOwner) external onlyOwner nonContract {
        owner = newOwner;
    }

    function SetSubscriptionFee(uint256 newFee) external onlyOwner nonContract {
        subscriptionFee = newFee;
    }

    function SetReferrerShare(uint8 newShare) external onlyOwner nonContract {
        referrerShare = newShare;
    }

    function GetUsers() external view onlyOwner nonContract returns (User[] memory) {
        User[] memory users = new User[](totalUsers);
        for (uint256 i = 0; i < totalUsers; i++) {
            users[i] = Users[i];
        }
        return users;
    }

    function TransferBNB(address to, uint256 amount) public onlyOwner nonContract {
        _transferTokens(to, amount);
    }

    function _transferTokens(address _to, uint256 _amount) private onlyOwner nonContract {
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= _amount, "insufficient contract balance");
        payable(_to).transfer(_amount);
    }

    /**************************************************************************************************
     * @user  Functions
     **************************************************************************************************/
    function Register(bytes32 _telegram) external payable nonContract minimumPayment {
        Users[totalUsers] = User({
            payment: msg.value,
            wallet: msg.sender,
            telegramId: _telegram
        });
        walletAccounts[msg.sender] = walletAccounts[msg.sender] + 1;
        isUser[msg.sender] = true;
        totalUsers++;
    }

    function RefRegister(bytes32 _telegram, address ref)
        external
        payable
        nonContract
        minimumPayment
    {
        Users[totalUsers] = User({
            payment: msg.value,
            wallet: msg.sender,
            telegramId: _telegram
        });
        walletAccounts[msg.sender] = walletAccounts[msg.sender] + 1;
        isUser[msg.sender] = true;
        totalUsers++;

        if (isUser[ref] && ref != msg.sender) {
            referrals[ref] = referrals[ref] + 1;
            _transferTokens(ref, (msg.value * referrerShare) / 100);
        }
    }

    function GetMyInformation() public view returns (User[] memory) {
        uint256 size = walletAccounts[msg.sender];
        User[] memory users = new User[](size);
        uint256 index = 0;

        for (uint256 i = 0; i < totalUsers; i++) {
            if (Users[i].wallet == msg.sender) {
                users[index] = Users[i];
                index++;
            }
        }

        return users;
    }

    function IsAdmin() public view returns (bool) {
        return address(msg.sender) == address(owner);
    }
}