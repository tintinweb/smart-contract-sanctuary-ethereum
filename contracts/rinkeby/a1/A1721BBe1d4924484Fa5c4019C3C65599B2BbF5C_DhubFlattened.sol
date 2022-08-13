/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DhubFlattened {
    // User information data structure
    struct User {
        string name;
        string profileUrl;
    }

    // User file storage data structure
    struct UserFile {
        uint8 id;
        string url;
        string title;
        string description;
        string uploadDate;
        uint256 size;
        bool shareable;
    }

    // Track user information by address
    mapping(address => User) public users;

    // Track user files by address
    mapping(address => UserFile[]) public filesByUser;

    // Log transfer actions
    event Transfer(address indexed from, address indexed to, UserFile file);

    // Log upload actions
    event Upload(address indexed owner, UserFile file);

    //Validate user exists
    modifier onlyUser() {
        require(bytes(users[msg.sender].name).length > 0, "User not found");
        _;
    }

    /**
     * @notice Login into the application through a wallet connection
     * @dev Checks if the user exists and proceed to login in the application
     * @return User struct information
     */
    function login() external view onlyUser returns (User memory) {
        return users[msg.sender];
    }

    /**
     * @notice Register a new user into the application
     * @dev validate that the new user fields are not empty & user does not exist
     * @dev checks if the user already exists and proceed to register a new user
     * @dev Create a new record in users mapping
     */
    function register(string memory name, string memory profileUrl) external {
        User memory user = users[msg.sender];
        require(bytes(user.name).length == 0, "User already exists");

        require(bytes(name).length > 0, "Name is required");

        users[msg.sender] = User(name, profileUrl);
    }

    /**
     * @notice Allow to update user information such as "nickname" and "profile url"
     * @dev validate that the user exists
     * @dev math the field to edit and update the information otherwise will revert
     * @param field should be "name" or "profileUrl", mustn't be empty
     * @param value corresponding value to field, mustn't be empty
     */
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

    /**
     * Address agnostic add function to either upload file or transfer movement
     * @dev Create a new id based on filesByUser array size
     * @dev Create a new struct UserFile record in filesByUser mapping
     */
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
            file.size,
            false
        );

        filesByUser[user].push(newFile);

        return (newFile, idCounter - 1);
    }

    /**
     * Agnostic address remove function to either remove process or transfer movement
     * This function alters the order of user's file collection but keeps a lower complexity than a for loop ( O(1) )
     * @param position index of file in user's collection
     * @dev Swap lastFile onto to-remove file target and then executes a pop to remove the older lastFile copy
     */
    function _safeRemoveFile(address from, uint8 position) private {
        //Execute an swap and pop operation in the collection
        UserFile[] storage collection = filesByUser[from];

        //Find last element index in collection
        uint256 lastIndex = collection.length - 1;
        UserFile memory lastFile = collection[lastIndex];

        collection[position] = lastFile; // Move last file to the to-delete file index

        collection.pop(); // Remove last file leftover copy
    }

    /**
     * @notice Upload new file to the application
     * @param file receive UserFile data after been uploaded to IPFS by the client
     * @dev calls private function to build up the new file record
     */
    function uploadFile(UserFile calldata file)
        external
        onlyUser
        returns (uint8)
    {
        (UserFile memory newFile, uint8 fileIndex) = _addFile(msg.sender, file);

        emit Upload(msg.sender, newFile);

        return fileIndex;
    }

    /**
     * @notice retrieves user's files list
     * @return list of UserFile struct by user address
     */
    function getFilesByUser()
        external
        view
        onlyUser
        returns (UserFile[] memory)
    {
        return filesByUser[msg.sender];
    }

    /**
     * @notice retrieves user's specific file
     * @param position indicates the index of file in UserFile array
     * @dev search the file by its index position in array
     * @return UserFile corresponding struct
     */
    function getFileByPosition(uint8 position)
        external
        view
        onlyUser
        returns (UserFile memory)
    {
        return filesByUser[msg.sender][position];
    }

    /**
     * @notice retrieves user's shared file
     * @param shareAcc indicates what account is sharing the item
     * @dev search the file and validate if the owner setted it up as a shareable item
     * @return UserFile corresponding struct
     */
    function getFileByPosition(uint8 position, address shareAcc)
        external
        view
        returns (UserFile memory)
    {
        UserFile memory targetItem = filesByUser[shareAcc][position];

        require(targetItem.shareable, "This item is not shareable");

        return targetItem;
    }

    /**
     * @notice updates the fields "name" & "description" of a specific file of a user
     * @param position receive the index in array to access to target file
     * @param title new title to set to the fil
     * @param description new description to set to the file
     * @dev Only it's going to set up if the field is not empty & is not the same as older one
     */
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

    /**
     * @notice Automatically updates the share state of a item
     * @param position indicates the position of the target file
     * @dev toggle
     */
    function updateShareState(uint8 position) external onlyUser {
        UserFile storage file = filesByUser[msg.sender][position];

        file.shareable = !file.shareable;
    }

    /**
     * @notice remove a file from the collection
     * @dev calls private function to do the removing process
     */
    function removeFile(uint8 index) public onlyUser {
        _safeRemoveFile(msg.sender, index);
    }

    /**
     * @notice Transfer a file from a user to other
     * @param owner origin user address
     * @param destiny target user address
     * @param filePosition index in file array by users
     * This will add a new file into destiny user's file array and will remove from origin user's array the file
     * @dev calls private function to do the transfer movement
     */
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