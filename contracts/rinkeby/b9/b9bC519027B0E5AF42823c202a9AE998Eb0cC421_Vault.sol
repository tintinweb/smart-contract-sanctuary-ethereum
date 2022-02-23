//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Vault {
    struct User {
        address ethAddress;
        string algoAddress;
        uint256 amount;
    }

    address public owner;
    uint256 public userCount;

    mapping(uint256 => User) public users;
    mapping (address => uint256[]) public userIDsByETHAddress;

    event LockETH(address indexed ethAddress, string algoAddress, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }

    function lockETH(address _ethAddress, string calldata _algoAddress) external payable returns (uint256 _id) {
        _id = userCount;

        users[_id].ethAddress = _ethAddress;
        users[_id].algoAddress = _algoAddress;
        users[_id].amount = msg.value;

        userIDsByETHAddress[_ethAddress].push(_id);
        userCount ++;
        emit LockETH(users[_id].ethAddress, users[_id].algoAddress, users[_id].amount);

        return _id;
    }

    function addAmount(uint256 _id)	public payable { 
        require(msg.sender == users[_id].ethAddress, "Not vault owner");
        users[_id].amount += msg.value;
        emit LockETH(users[_id].ethAddress, users[_id].algoAddress, msg.value);
    }

    function unlockETH(uint256 _id, string calldata _algoAddress, uint256 _amount) external {
        require(msg.sender == users[_id].ethAddress, 'You are not the withdrawer!');
        require(keccak256(bytes(users[_id].algoAddress)) == keccak256(bytes(_algoAddress)), 'Algo address are not valid!');
        require(users[_id].amount > 0, 'balance is zero!');
        require(users[_id].amount >= _amount, 'balance is not enough to withdraw!');

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send ETH");

        users[_id].amount -= _amount;
    }

    function getUserIdByETHAddress(address _ethAddress) view external returns (uint256[] memory) {
        return userIDsByETHAddress[_ethAddress];
    }

    function getUserById(uint256 _id) view external returns (User memory) {
        return users[_id];
    }

    function getBalanceById(uint256 _id) public view returns (uint256) {
        return users[_id].amount;
    }
}