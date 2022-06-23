/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.14;

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract MAGA_USERS is protected {

    // Database prototype
    struct USER {
        string username;
        bool is_associated;
        string password;
        uint lastlogin;
    }

    // On chain logins
    bool password_on_chain = false;

    // Database object
    mapping(address => USER) private user;

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    function set_auth(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    function harakiri() public onlyAuth {
        selfdestruct(payable(msg.sender));
    }

    /****************************************************************
                                 SETTERS
    ****************************************************************/

    // Binding an username to an address, if not taken and authenticated
    function bind_username(address addy, string memory username)
                            public safe returns(bool success) {
        require(!password_on_chain, "Authentication on chain needed");
        require(msg.sender == addy, "Login failed");
        require(!(user[addy].is_associated), "Address already associated");
        user[addy].username = username;
        user[addy].is_associated = true;
        return true;
    }

    function bind_username_with_onchain_authentication(address addy, string memory username, string memory password)
                                                       public safe returns(bool success) {
        require(password_on_chain, "Authentication off chain needed");
        string memory user_password = user[msg.sender].password;
        require(keccak256(abi.encode(password)) == keccak256(abi.encode(user_password)), "Login failed on chain");
        require(msg.sender == addy, "Login failed");
        require(!(user[addy].is_associated), "Address already associated");
        user[addy].username = username;
        user[addy].is_associated = true;
        return true;                                      
    }

    function set_password(string memory password) public safe returns(bool success) {
        require(password_on_chain, "Password is not meant to be on chain");
        user[msg.sender].password = password;
        return true;
    }

    function set_on_chain_authentication(bool booly) public onlyAuth {
        password_on_chain = booly;
    }

    /****************************************************************
                                GETTERS
    ****************************************************************/

    function get_association(address addy) 
                             public view returns(string memory username_){
        require(!password_on_chain, "Authentication on chain needed");
        // First check association
        if(user[addy].is_associated) {
            // Check signature value
            require(msg.sender==addy, "Not authorized on getting association for address");
            // If is all ok, return the value
            return(user[addy].username);
        } else {
            revert("No association");
        }
    }

    function get_association_with_onchain_authentication(address addy, string memory password) 
                                                            public view returns(string memory username_) {
        require(password_on_chain, "Authentication off chain needed");
        string memory user_password = user[msg.sender].password;
        require(keccak256(abi.encode(password)) == keccak256(abi.encode(user_password)), "Login failed on chain");
        // First check association
        if(user[addy].is_associated) {
            // Check signature value
            require(msg.sender==addy, "Not authorized on getting association for address");
            // If is all ok, return the value
            return(user[addy].username);
        } else {
            revert("No association");
        }
    }

}