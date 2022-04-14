// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Filestorage {
    address userAddress;
    struct FileProperty {
        string cid;
        bool status;
        string name;
        string description;
    }

    event StoreFile(address user, string name);

    mapping(address => FileProperty[]) files;
    FileProperty[] publicFiles;

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
        emit StoreFile(msg.sender, _name);
    }

    function retrievePrivate(address _userAddress)
        public
        view
        returns (FileProperty[] memory)
    {
        return files[_userAddress];
    }

    function retrievePublic() public view returns (FileProperty[] memory) {
        return publicFiles;
    }
}