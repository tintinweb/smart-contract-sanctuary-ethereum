/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract BlindboxLog {

    address private _owner;
    address private _admin;
    mapping(address => bool) private whitelists;

    constructor() {
        _owner = msg.sender;
        _admin = msg.sender;
    }
    

    event Open(uint256 boxId, address owner);
    event Opened(uint256 boxId, address nftContract, uint256 tokenId, address owner);
    event Transfer(address from, address to, uint256 boxId, uint256 projectId, address boxContract);

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender || _owner == msg.sender, "caller is not the admin");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelists[msg.sender], "caller is not the whitelists");
        _;
    }

    function Openlog(uint256 boxId, address owner) public onlyWhitelist{
        emit Open(boxId, owner);
    }

    function Openedlog(uint256 boxId, address nftContract, uint256 tokenId, address owner) public onlyWhitelist{
        emit Opened(boxId, nftContract, tokenId, owner);
    }

    function Transferlog(address from, address to, uint256 boxId, uint256 projectId) public onlyWhitelist{
        emit Transfer(from, to, boxId, projectId, msg.sender);
    }

    function addWhitelist(address[] memory items) public onlyAdmin {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        for (uint i=0; i<items.length; i++) {
            whitelists[items[i]] = true;
        }
    }

    function setAdmin(address newAdmin) public onlyOwner {
        _admin = newAdmin;
    }
}