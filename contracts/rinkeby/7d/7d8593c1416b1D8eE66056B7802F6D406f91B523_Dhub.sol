/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dhub {
    struct User {
        string name;
        string profileUrl;
    }

    struct UserFile {
        uint8 id;
        string url;
        string title;
        string description;
        string uploadDate;
        uint256 size;
    }

    mapping(address => User) public users;

    mapping(address => UserFile[]) public filesByUser;

    event Transfer(address indexed from, address indexed to, UserFile file);

    event Upload(address indexed owner, UserFile file);

    modifier onlyUser() {
        require(bytes(users[msg.sender].name).length > 0, "User not found");
        _;
    }

    function login() external view onlyUser returns (User memory) {
        return users[msg.sender];
    }

    function register(string memory name, string memory profileUrl) external {
        User memory user = users[msg.sender];
        require(bytes(user.name).length == 0, "User already exists");

        require(bytes(name).length > 0, "Name is required");

        users[msg.sender] = User(name, profileUrl);
    }

    function editUser(string memory field, string memory value)
        external
        onlyUser
    {
        User storage user = users[msg.sender];

        bytes32 fieldToCompare = keccak256(abi.encodePacked(field));

        if (fieldToCompare == keccak256(abi.encodePacked("name"))) {
            require(bytes(value).length > 0, "Name is required");
            user.name = value;
        } else if (
            fieldToCompare == keccak256(abi.encodePacked("profileUrl"))
        ) {
            require(bytes(value).length > 0, "Profile url is required");
            user.profileUrl = value;
        } else {
            revert("Field not found");
        }
    }

    function _addFile(address user, UserFile memory file)
        private
        returns (UserFile memory, uint8)
    {
        uint8 idCounter = uint8(filesByUser[user].length + 1);

        UserFile memory newFile = UserFile(
            idCounter,
            file.url,
            file.title,
            file.description,
            file.uploadDate,
            file.size
        );

        filesByUser[user].push(newFile);

        return (newFile, idCounter - 1);
    }

    function _safeRemoveFile(address from, uint8 position) private {
        UserFile[] storage collection = filesByUser[from];

        uint256 lastIndex = collection.length - 1;
        UserFile memory lastFile = collection[lastIndex];

        collection[position] = lastFile; 

        collection.pop(); 
    }

    function uploadFile(UserFile calldata file)
        external
        onlyUser
        returns (uint8)
    {
        (UserFile memory newFile, uint8 fileIndex) = _addFile(msg.sender, file);

        emit Upload(msg.sender, newFile);

        return fileIndex;
    }


    function getFilesByUser()
        external
        view
        onlyUser
        returns (UserFile[] memory)
    {
        return filesByUser[msg.sender];
    }


    function getFileByPosition(uint8 position)
        external
        view
        onlyUser
        returns (UserFile memory)
    {
        return filesByUser[msg.sender][position];
    }

    function editFile(
        uint8 position,
        string calldata title,
        string calldata description
    ) external onlyUser {
        bool isTitle = bytes(title).length > 0;
        bool isDescription = bytes(description).length > 0;

        require(isTitle || isDescription, "Both fields are empty");

        UserFile storage file = filesByUser[msg.sender][position];

        if (
            isTitle &&
            keccak256(abi.encode(file.title)) != keccak256(abi.encode(title))
        ) {
            file.title = title;
        }

        if (
            isDescription &&
            keccak256(abi.encode(file.description)) !=
            keccak256(abi.encode(description))
        ) {
            file.description = description;
        }
    }

    function removeFile(uint8 index) public onlyUser {
        _safeRemoveFile(msg.sender, index);
    }

    function transferFile(
        address owner,
        address destiny,
        uint8 filePosition
    ) external onlyUser {
        require(msg.sender == owner, "You're not the owner");
        require(
            bytes(users[destiny].name).length > 0,
            "Destiny user doesn't exist"
        );

        UserFile memory file = filesByUser[owner][filePosition];

        _addFile(destiny, file);
        _safeRemoveFile(owner, filePosition);

        emit Transfer(owner, destiny, file);
    }
}