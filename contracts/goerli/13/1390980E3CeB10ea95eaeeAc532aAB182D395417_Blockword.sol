// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Blockword {

    struct Account {
        string account_name;
        string email;
        string username;
        string password_hash;
    }

    mapping(address => Account[]) public profiles;

    function set_account(string memory _account_name,
                         string memory _email, string memory _username,
                         string memory _password_hash) public {
        Account memory account = Account({account_name: _account_name, email: _email, username: _username, password_hash: _password_hash});
        profiles[msg.sender].push(account);
    }

    function get_accounts() public view returns(Account[] memory) {
        return(profiles[msg.sender]);
    }
}

// TODO Replace email and username with one login field
// TODO Implement contract initializing
// TODO Optimize conract with replacing strings with bytes type where it possible
// TODO Implement function for contract balance withdraw
// TODO Delete redudant comments 
// TODO Implement payable functions