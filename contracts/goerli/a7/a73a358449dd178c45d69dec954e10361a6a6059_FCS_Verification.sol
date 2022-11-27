/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

contract FCS_Verification{

    struct HashStatus{
        bool verifiedByAdmin;
        address owner;
    }
    //  =====================================
    //                 STORAGE
    // =======================================

    mapping (address => bool) admins;
    mapping(bytes32 => HashStatus) database;

    modifier onlyAdmin(){
        require(admins[msg.sender], "Only Admin Can Verify");
        _;
    }
    // =======================================
    //                 FUNCTIONS
    // =======================================

    constructor(address _admin){
        admins[_admin] = true;
    }

    function depositHash(bytes32 _hash) public{
        require(database[_hash].owner == address(0));
        database[_hash] = HashStatus(false, msg.sender);
    }

    function approveHash(bytes32 _hash) public onlyAdmin(){
        database[_hash].verifiedByAdmin = true;
    }

    function revokeHashApproval(bytes32 _hash) public onlyAdmin(){
        database[_hash].verifiedByAdmin = false;
    }

    function removeHashFromDatabase(bytes32 _hash) public onlyAdmin(){
        database[_hash] = HashStatus(false, address(0));
    }

    function verifyHash(bytes32 _hash, address _owner) public view returns(bool){
        return database[_hash].owner == _owner && database[_hash].verifiedByAdmin;
    }

    function verifyHashOwner(bytes32 _hash, address _owner) public view returns(bool){
        return database[_hash].owner == _owner;
    }

    function verifyAdminApproval(bytes32 _hash) public view returns(bool){
        return database[_hash].verifiedByAdmin;
    }

    function getHashOwner(bytes32 _hash) public view returns(address){
        return database[_hash].owner;
    }

    function addAdmin(address _newAdmin) public onlyAdmin(){
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _admin) public onlyAdmin(){
        admins[_admin] = false;
    }

}