/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|                                                                                                                                                                                                                                           
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IThreetlRegistry.sol";

contract ThreetlRegistry is IThreetlRegistry {
    /// @dev Get UserInfo by UserId
    mapping (uint256 => UserInfo) public users;

    /// @dev Check user is registered by user address
    mapping (address => bool) public registeredUsers;

    /// @dev Get UserId by user address
    mapping (address => uint256) public userIds;

    /**
     * @dev Add New UserInfo
     *      Register userId & userInfo
     */
    function addPair(uint256 _userId, bytes calldata _userInfo) public {
        require(!registeredUsers[msg.sender], "ThreetlRegistry: Already registered");

        UserInfo storage user = users[_userId];
        require(user.userAddress == address(0), "ThreetlRegistry: UserID is already registered");

        // Add UserInfo
        user.userId = _userId;
        user.createdAt = block.timestamp;
        user.userAddress = msg.sender;
        user.userInfo = _userInfo;

        // Register user
        registeredUsers[msg.sender] = true;

        // Register userId by user address
        userIds[msg.sender] = _userId;

        emit NewPairAdded(_userId, msg.sender, _userInfo);
    }

    /**
     * @dev Update UserInfo
     *      Update userId & userInfo
     */
    function updatePair(uint256 _userId, uint256 _newUserId, bytes calldata _newUserInfo) external {
        UserInfo storage user = users[_userId];
        require(user.userAddress == msg.sender, "ThreetlRegistry: Only owner can update it");

        // Delete old data
        delete users[_userId];
        delete registeredUsers[msg.sender];
        delete userIds[msg.sender];
        emit PairDeleted(_userId, msg.sender);

        // Create new pair
        addPair(_newUserId, _newUserInfo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IThreetlRegistry {
    struct UserInfo {
        uint256 userId;
        uint256 createdAt;
        address userAddress;
        bytes userInfo;
    }

    event NewPairAdded(uint256 userId, address userAddress, bytes userInfo);
    event PairDeleted(uint256 userId, address userAddress);
}