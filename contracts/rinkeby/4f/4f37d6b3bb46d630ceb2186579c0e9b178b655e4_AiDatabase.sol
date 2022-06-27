/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract AiDatabase {

    struct Owners {
        uint id;
        bool superAdmin;
        bool admin;
    }
    mapping(address => Owners) owner;
    uint countOwner = 0;

    constructor() {
        countOwner ++;
        owner[msg.sender] = Owners(
            countOwner,
            true,
            true
        );
    }

    struct Users {
        address owner;
        uint id;
        string metadataUrl;
    }
    mapping(uint => Users) User;
    uint countUsers = 0;

    event setAddOwner (
        address indexed _superOwner,
        uint _id,
        bool _isSuperOwner,
        bool _isOwner
    );

    event setRemoveOwner (
        address indexed _superOwner,
        uint _id,
        bool _isSuperOwner,
        bool _isOwner
    );

    event setUser (
        address indexed _owner,
        uint _id,
        string metadataUrl
    );

    event updateUser (
        address indexed _owner,
        uint _id,
        string metadataUrl
    );

    event deleteUser (
        address indexed _owner,
        uint _id,
        string metadataUrl
    );

    modifier onlySuperOwner() {
        require(owner[msg.sender].superAdmin,
            "Only Super Owners");
        _;
    }

    modifier onlyOwner() {
        require(owner[msg.sender].admin,
            "Only Owners");
        _;
    }

    function countOwners()
        view
        public
        returns(uint)
    {
        return countOwner;
    }

    function addOwner(address newOwner_)
        public onlySuperOwner
    {
        require(owner[newOwner_].admin == false, 
            "Before Added Address");

        countOwner ++;
        owner[newOwner_] = Owners(
            countOwner,
            false,
            true
        );

        emit setAddOwner (
            msg.sender,
            owner[newOwner_].id,
            owner[newOwner_].superAdmin,
            owner[newOwner_].admin
        );
    }

    function addOwnerBatch(
        address[] memory newOwners_
    )
        public onlySuperOwner
    {
        for (uint i = 0; i < newOwners_.length; ++i)
        {
            addOwner(newOwners_[i]);
        }
    }

    function removeOwner(address owner_)
        public onlySuperOwner
    {
        require(owner[owner_].admin == true, 
            "it's not Owner");
        require(owner[owner_].superAdmin == false, 
            "Super Owner can not deleted");

        emit setRemoveOwner (
            msg.sender,
            owner[owner_].id,
            owner[owner_].superAdmin,
            owner[owner_].admin
        );

        countOwner --;
        owner[owner_] = Owners(
            owner[owner_].id,
            false,
            false
        );

        emit setRemoveOwner (
            msg.sender,
            owner[owner_].id,
            owner[owner_].superAdmin,
            owner[owner_].admin
        );
    }

    function removeOwnerBatch(
        address[] memory owners_
    )
        public onlySuperOwner
    {
        for (uint i = 0; i < owners_.length; ++i)
        {
            removeOwner(owners_[i]);
        }
    }

    function lastId()
        view public returns(uint)
    {
        return countUsers;
    }

    function set(string memory metadataUrl)
        public onlyOwner
    {
        countUsers ++;
        User[countUsers] = Users(
            msg.sender,
            countUsers,
            metadataUrl
        );

        emit setUser (
            msg.sender,
            countUsers,
            metadataUrl
        );
    }

    function setBatch(
        string[] memory metadataUrls
    )
        public onlyOwner
    {
        for (uint i = 0; i < metadataUrls.length; ++i)
        {
            set(metadataUrls[i]);
        }
    }

    function get(uint id_)
        view
        public
        returns(Users memory)
    {
        return User[id_];
    }

    function getBatch(uint[] memory ids_)
        view
        public
        returns(Users[] memory)
    {
        Users[] memory usersIds =
            new Users[](ids_.length);

        for (uint i = 0; i < ids_.length; ++i)
        {
            usersIds[i] = get(ids_[i]);
        }
        return usersIds;
    }

    function update(
        uint id,
        string memory metadataUrl
    )
        public onlyOwner
    {
        emit updateUser (
            User[id].owner,
            User[id].id,
            User[id].metadataUrl
        );

        User[id] = Users(
            msg.sender,
            id,
            metadataUrl
        );

        emit updateUser (
            msg.sender,
            id,
            metadataUrl
        );
    }

    function updateBatch(
        uint[] memory ids,
        string[] memory metadataUrls
    )
        public onlyOwner
    {
        for (uint i = 0; i < metadataUrls.length; ++i)
        {
            update(ids[i], metadataUrls[i]);
        }
    }

    function remove(uint id)
        public onlyOwner
    {
        emit deleteUser (
            User[id].owner,
            User[id].id,
            User[id].metadataUrl
        );

        delete User[id];

        emit deleteUser (
            User[id].owner,
            User[id].id,
            User[id].metadataUrl
        );
    }

    function removeBatch(uint[] memory ids)
        public onlyOwner
    {
        for (uint i = 0; i < ids.length; ++i)
        {
            remove(ids[i]);
        }
    }
}