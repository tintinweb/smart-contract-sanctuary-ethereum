/**
 *Submitted for verification at Etherscan.io on 2022-06-15
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

contract wallchain is protected {

    struct USER {
        string[] messages;
        uint last_index;
        mapping(uint => string) address_indexes;
        uint timestamp;
        address[] followed;
    }

    mapping(address => USER) users;

    function post(string memory _msg) public safe {
        users[msg.sender].messages.push(_msg);
        users[msg.sender].address_indexes[users[msg.sender].last_index] = _msg;
        users[msg.sender].last_index += 1;
    }

    function get_posts(address addy) public view returns (string[] memory _msg) {
        return users[addy].messages;
    }


}