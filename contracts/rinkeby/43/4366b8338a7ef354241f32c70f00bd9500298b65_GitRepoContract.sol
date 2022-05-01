/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract GitRepoContract {
    Repo[] private repositories;
    // The keys will be encrypted using public key of reciever
    mapping(uint256 => mapping(address => Key)) public keys;
    mapping(uint256 => mapping(address => Permissions)) public userPermissions;

    enum Permissions {
            None,
            Reader,
            Writer,
            Maintainer,
            Admin
    }
    struct Repo {
        uint256 uuid;
        string storage_address;
        string integrity;  // SHA256 hash of the file, to verify if stored repo is intact
    }

    struct Key {
        string key;
        string iv;
    }

    function initializeRepo(string memory _storage_address, string calldata _integrity, string calldata _key, string calldata _iv) public returns (uint256 uuid){
        uint256 _uuid = repositories.length;
        repositories.push(Repo({
            uuid: _uuid,
            storage_address: _storage_address,
            integrity: _integrity
        }));

        userPermissions[_uuid][msg.sender] = Permissions.Admin;
        keys[_uuid][msg.sender] = Key({
            key: _key,
            iv: _iv
        });

        return uuid;
    }

    function grantAccess(uint256 _uuid, address _address, Permissions _role, string calldata _key, string calldata _iv) public {
        // check if caller is Admin
        require(userPermissions[_uuid][msg.sender] == Permissions.Admin);

        require(_role != Permissions.Admin);
        userPermissions[_uuid][_address] = _role;

        keys[_uuid][_address] = Key({
            key: _key,
            iv: _iv
        });
    }

    function pushToRepo(uint256 _uuid, string memory _storage_address, string calldata _integrity) public {
        // check if user has writer or admin permission
        require(
            userPermissions[_uuid][msg.sender] == Permissions.Admin || 
            userPermissions[_uuid][msg.sender] == Permissions.Writer
        );

        repositories[_uuid].storage_address = _storage_address;
        repositories[_uuid].integrity = _integrity;
    }

    function getRepoInfo(uint256 _uuid) public view returns (string memory storage_address, string memory integrity){
        require(
            userPermissions[_uuid][msg.sender] == Permissions.Admin || 
            userPermissions[_uuid][msg.sender] == Permissions.Writer ||
            userPermissions[_uuid][msg.sender] == Permissions.Reader
        );
        return (repositories[_uuid].storage_address, repositories[_uuid].integrity);
    }
}