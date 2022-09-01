/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract PoolMatrixGame {
    struct User {
        bool registered;
        uint registrationTimestamp;
        address userAddr;
        address referrer;
        uint256 balance;
    }

    address public owner;
    mapping (address => User) internal users;
    address[] userAddresses;
    uint256[] refPercents = [14, 7, 3];

    event ContractCreated(string msg, address indexed owner, uint timestamp);
    event PaymentReceived(string msg, address indexed sender, uint amount, address indexed refferer);

    constructor() {
        owner = msg.sender;
        emit ContractCreated("Contract has been created", owner, block.timestamp);
        tryRegisterUser(address(0), address(0));
    }

    receive() payable external {
        emit PaymentReceived("Payment received", msg.sender, msg.value, address(0));
        tryRegisterUser(msg.sender, address(0));
        users[msg.sender].balance += msg.value;
        invest(msg.sender, msg.value);
    }

    fallback() external payable {
        bytes memory data = msg.data;
        address referrer;

        assembly {
            referrer := mload(add(data, 20))
        }
        
        emit PaymentReceived("Payment received with referrer", msg.sender, msg.value, referrer);
        tryRegisterUser(msg.sender, referrer);
        users[msg.sender].balance += msg.value;
        invest(msg.sender, msg.value);
    }

    function tryRegisterUser(address userAddr, address referrer) internal {
        if (users[userAddr].registered)
            return;

        users[userAddr].registered = true;
        users[userAddr].registrationTimestamp = block.timestamp;
        users[userAddr].userAddr = userAddr;
        users[userAddr].referrer = referrer;
        users[userAddr].balance = 0;
        userAddresses.push(userAddr);
    }

    function invest(address userAddr, uint256 amount) internal {
        address referrer = users[userAddr].referrer;
        for (uint i = 0; i < 3; i++) {
            if (referrer != address(0)) {
                uint256 value = amount * refPercents[i] / 100;
                payable(referrer).transfer(value);
                users[userAddr].balance -= value;
                users[referrer].balance += value;
                referrer = users[referrer].referrer;
            }
            else 
                break;
        }
    }

    function getOwner() public view returns(address) {
        return owner;
    } 

    function getUser(address userAddress) public view returns(bool registered, uint registrationTimestamp, address userAddr, address referrer, uint256 balance) {
        User memory user = users[userAddress];
        return (
            user.registered,
            user.registrationTimestamp,
            user.userAddr,
            user.referrer,
            user.balance
        );
    }

    function getUserAddresses() public view returns(address[] memory) {
        return userAddresses;
    }

    function getUsers() public view returns(User[] memory) {
        User[] memory list = new User[](userAddresses.length);

        for (uint i = 0; i < userAddresses.length; i++)
            list[i] = users[userAddresses[i]];

        return list;
    }

    function deleteAllUsers() public {
        for (uint i = 0; i < userAddresses.length; i++) {
            address addr = userAddresses[i];
            users[addr].registered = false;
            users[addr].registrationTimestamp = 0;
            users[addr].userAddr = address(0);
            users[addr].referrer = address(0);
            users[addr].balance = 0;
        }

        while (userAddresses.length > 0)
            userAddresses.pop();
    }

}