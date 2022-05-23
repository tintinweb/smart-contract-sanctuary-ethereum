// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title A contract for password managing
// @notice This contract have functions for set and retrieve user profiles
contract Blockword {
    address owner;
    uint price = 0.00001 ether;

    constructor(uint _price) {
        owner = msg.sender;
        price = _price;
    }

    struct Account {
        string account_name;
        string login_hash;
        string password_hash;
    }

    mapping (address => Account[]) internal accounts;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // @notice Add a user profile to the blockchain state
    // @param _account_name string name of user account
    // @param _login_hash user account login hashed with user wallet public key
    // @param _password_hash user account password hashed with user wallet public key
    // @dev This function internal for implementation of payable functions
    function set_account(string memory _account_name, string memory _login_hash, string memory _password_hash) internal {
        Account memory account = Account(_account_name, _login_hash, _password_hash);
        accounts[msg.sender].push(account);
    }

    // @param _user address of the user whose accounts retrieve
    // @return Returns list of user accounts information
    function get_accounts(address _user) public view returns(Account[] memory){
        return(accounts[_user]);
    }

    // @notice Pay for adding a user profile to the blockchain state
    // @param _account_name string name of user account
    // @param _login_hash user account login hashed with user wallet public key
    // @param _password_hash user account password hashed with user wallet public key
    function pay_set_account(string memory _account_name, string memory _login_hash, string memory _password_hash) public payable {
        require(msg.value == price);
        set_account(_account_name, _login_hash, _password_hash);
    }

    // @notice Transfer contract balance to owner
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // @notice Update the price of interaction with contract, available only for owner
    // @param _new_price uint new price of function
    function update_price(uint _new_price) external onlyOwner {
        price = _new_price;
    }

    // @notice Transfer contract ownership to another user, available only for owner
    // @param _new_owner address of the user who will become the owner of the contract
    function transfer_ownership(address _new_owner) external onlyOwner {
        owner = _new_owner;
    }

    // @return Returns the price of interaction with contract
    function get_price() public view returns(uint) {
        return(price);
    }
}

// TODO Implement function for profile updating
// TODO Implement function for profile deleting