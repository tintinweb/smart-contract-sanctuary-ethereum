// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLock {

    uint public transactions;

    // User stucture
    struct user {
        uint256 timelock;
        uint deposit;
        bool userFound;
    }
    // Mapping address to users
    mapping(address => user) users;

    // Helper function to store user deposit and timelock
    function store(uint256 _timelock, uint _deposit) private {
        users[msg.sender] = user(
            {
                timelock: _timelock+ block.number,
                deposit: _deposit,
                userFound: true
            }
        );
    }

    // Deposit functiont take in timelock parameter to store in struct with deposit.
    function deposit(uint64 timelock) external payable {
        require(findUser() == false, "User has already made a deposit");
        store(timelock, msg.value);
        transactions ++;
    }

    // Helper function to check if user is in map. 
    function findUser() private view returns (bool) {
        return users[msg.sender].userFound;
    }

    // Withdraw function checks if current block is ahead of timeblock. 
    function withdraw() external {
        require(block.number >= users[msg.sender].timelock, "Current block number is behind timelock");
        payable(msg.sender).transfer(users[msg.sender].deposit);
        delete users[msg.sender];
    }

    // Returns users balance
    function getBalance() public view returns (uint) {
        return users[msg.sender].deposit;
    }

    // Returns users timelock
    function getTimeLock() public view returns (uint256) {
        return users[msg.sender].timelock;
    }
    
    // Returns the current block number. 
    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }
}