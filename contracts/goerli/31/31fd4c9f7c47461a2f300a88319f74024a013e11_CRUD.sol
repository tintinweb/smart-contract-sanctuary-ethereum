/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity ^0.8.0;

contract CRUD {
    struct User {
        string account;
        string password;
        uint status;
        uint createdAt;
        uint updatedAt;
    }

    mapping (string => User) public users;

    function createUser(string memory _account, string memory _password, uint _status) public {
        users[_account] = User(_account, _password, _status, block.timestamp, block.timestamp);
    }

    function updateUser(string memory _account, string memory _password, uint _status) public {
        users[_account].password = _password;
        users[_account].status = _status;
        users[_account].updatedAt = block.timestamp;
    }

    function deleteUser(string memory _account) public {
        delete users[_account];
    }

    function getUser(string memory _account) public view returns (string memory, string memory, uint, uint, uint) {
        User memory user = users[_account];
        return (user.account, user.password, user.status, user.createdAt, user.updatedAt);
    }
}