/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;



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

    receive() external payable {}
    fallback() external payable {}
}


contract ANFT is protected {

    string public content;
    bytes32 public name;

    constructor(address new_owner, string memory _content, bytes32 _name) {
        owner = new_owner;
        is_auth[new_owner] = true;
        content = _content;
        name = _name;
    }

}

contract ANFT_Collection is protected {

    mapping(uint96 => string) public content;
    uint96 public last_id;
    bytes32 public name;

    constructor(address new_owner, bytes32 _name) {
        owner = new_owner;
        is_auth[new_owner] = true;
        name = _name;
    }

    function store(string calldata to_store) public onlyAuth {
        content[last_id] = to_store;
        last_id += 1;
    }

}

contract AFS is protected {

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    uint64 fee = 20000000000000000;

    function set_fee(uint64 nufee) public onlyAuth {
        fee = nufee;
    }

    function create_single_storage(bytes32 name, string calldata content) public payable returns(address location) {
        if(!is_auth[msg.sender]) {
            require(msg.value == fee);
        }
        ANFT resulting_token = new ANFT(msg.sender, content, name);
        return(address(resulting_token));
    }

    function create_collection_storage(bytes32 name) public payable returns(address location) {        
        if(!is_auth[msg.sender]) {
            require(msg.value == fee*2);
        }
        ANFT_Collection resulting_token = new ANFT_Collection(msg.sender, name);
        return(address(resulting_token));
    }


}