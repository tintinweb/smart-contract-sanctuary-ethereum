/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    struct User {
        uint256 feePaid; // total fees paid
        uint256 size; // current font size
        uint256 current; // current domain
        uint256 color; // current color
    }

    struct Domain {
        address owner;
        string name; // domain name (normalized)
    }

    mapping(address => User) public users;
    mapping(uint256 => Domain) public domains;
    mapping(address => bool) allow;

    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function getUser(address _user) public view returns (User memory user) {
        return users[_user];
    }

    function getDomain(uint256 _tokenId) public view returns (Domain memory domain) {
        return domains[_tokenId];
    }

    function setOwner(address __owner) public onlyOwner {
        _owner = __owner;
    }

    function add(address _nft) public onlyOwner {
        allow[_nft] = true;
    }

    function remove(address _nft) public onlyOwner {
        allow[_nft] = false;
    }

    function setSize(address _user, uint256 _size) public {
        require(allow[msg.sender], "[db] not allowed");
        users[_user].size = _size;
    }
    
    function setColor(address _user, uint256 _color) public {
        require(allow[msg.sender], "[db] not allowed");
        users[_user].color = _color;
    }

    function mint(
        string calldata label,
        address _user,
        uint256 tokenId,
        uint256 feesPaid
    ) external {
        require(allow[msg.sender], "[db] not allowed");
        if (users[_user].current != 0) domains[users[_user].current].owner = address(0);
        domains[tokenId] = Domain(_user, label);
        if (users[_user].size == 0) users[_user].size = 256;
        users[_user].feePaid += feesPaid;
        users[_user].current = tokenId;
        assert(domains[tokenId].owner == _user);
        assert(users[_user].current == tokenId);
    }
}