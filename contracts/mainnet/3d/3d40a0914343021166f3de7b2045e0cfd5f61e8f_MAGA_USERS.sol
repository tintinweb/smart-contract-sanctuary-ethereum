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

    // Registering and bind together
    function join(string memory signature, string memory username) public returns(bool success) {
        bool exclusive_lock;
        require(!exclusive_lock, "Reentrant!");
        exclusive_lock = true;
        bool _success = register(signature);
        require(_success, "Cannot register");
        _success = bind_username(msg.sender, signature, username);
        require(_success, "Cannot bind");
        exclusive_lock = false;
        return true;
    }

    // Registering  
    function register(string memory signature) public safe returns (bool){
        require(bytes(user[msg.sender].password).length < 1, "Password already set");
        user[msg.sender].password = signature;
        return true;
    }

    // Binding an username to an address, if not taken and authenticated
    function bind_username(address addy, string memory signature, string memory username)
                            public safe returns(bool success) {
        require(login(signature), "403");
        require(!(user[addy].is_associated), "Address already associated");
        user[addy].username = username;
        user[addy].is_associated = true;
        return true;
    }

    /****************************************************************
                                GETTERS
    ****************************************************************/

    function get_association(address addy, string memory signature) 
                             public view returns(string memory username_){
        // First check association
        if(user[addy].is_associated) {
            // Check signature value
            bool logged = login(signature);
            if(logged) {
                // If is all ok, return the value
                return(user[addy].username);
            }
        } else {
            // None is the fallback value returned
            return "None";
        }
    }

    // Check registration
    function is_registered() public view returns(bool status) {
        return (bytes(user[msg.sender].password).length < 1);
    }

    function login(string memory password) public view returns(bool success){
        bytes32 hashed = keccak256(abi.encodePacked(password));
        bytes32 hashed_couterpart = keccak256(abi.encodePacked(user[msg.sender].password));
        if(hashed==hashed_couterpart) {
            return(true);
        } else {
            return(false);
        }
    }

}