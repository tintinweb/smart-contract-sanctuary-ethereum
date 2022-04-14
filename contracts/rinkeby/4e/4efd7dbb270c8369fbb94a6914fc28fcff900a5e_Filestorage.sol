/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

///@author Blockchamp-project Team
///@title library-solidity for filestorage

contract Filestorage {
    address userAddress;
    struct FileProperty {
        string cid;
        bool status;
        string name;
        string description;
    }

    event StoreFile(address user, string name);
    ///@dev @dev Mapping of ether files of the contract.
    mapping(address => FileProperty[]) files;
    FileProperty[] publicFiles;

    ///@notice store function using five arugments for userAddress,cid,status,name,description
    function store(
        address _userAddress,
        string memory _cid,
        bool _status,
        string memory _name,
        string memory _description
    ) public {
        FileProperty memory singleFile = FileProperty(
            _cid,
            _status,
            _name,
            _description
        );
        if (_status == false) {
            publicFiles.push(singleFile);
        }
        files[_userAddress].push(singleFile);
        ///@dev Emit store event
        emit StoreFile(msg.sender, _name);
    }

    ///@notice function to retrieve private by the owner of contract
    function retrievePrivate(address _userAddress)
        public
        view
        returns (FileProperty[] memory)
    {
        return files[_userAddress];
    }

    ///@notice function to retrieve public to the owner of contract
    function retrievePublic() public view returns (FileProperty[] memory) {
        return publicFiles;
    }
}