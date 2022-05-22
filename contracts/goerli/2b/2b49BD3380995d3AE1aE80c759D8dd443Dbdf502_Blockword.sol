// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Blockword {
    address owner;
    uint price = 0.00001 ether;

    constructor(uint _price) {
        owner = msg.sender;
        price = _price;
    }

    struct Account {
        string account_name;
        string login;
        string password_hash;
    }

    mapping (address => Account[]) internal accounts;

    // ownable
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function pay_set_account(string memory _account_name, string memory _login, string memory _password_hash) public payable {
        require(msg.value >= price);
        set_account(_account_name, _login, _password_hash);
    }

    function set_account(string memory _account_name, string memory _login, string memory _password_hash) internal {
        Account memory account = Account(_account_name, _login, _password_hash);
        accounts[msg.sender].push(account);
    }

    function get_accounts(address _user) public view returns(Account[] memory){
        return(accounts[_user]);
    }

    // ownable
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function update_price(uint _new_price) external onlyOwner {
        price = _new_price;
    }

    function transfer_ownership(address _new_owner) external onlyOwner {
        owner = _new_owner;
    }
}