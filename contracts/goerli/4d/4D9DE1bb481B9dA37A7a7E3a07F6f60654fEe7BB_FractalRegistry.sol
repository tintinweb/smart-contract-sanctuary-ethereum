// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Fractal registry v0
/// @author Antoni Dikov and Shelby Doolittle
contract FractalRegistry {
    address root;
    mapping(address => bool) public delegates;

    mapping(address => bytes32) fractalIdForAddress;
    mapping(string => mapping(bytes32 => bool)) userLists;

    constructor(address _root) {
        root = _root;
    }

    /// @param addr is Eth address
    /// @return FractalId as bytes32
    function getFractalId(address addr) external view returns (bytes32) {
        return fractalIdForAddress[addr];
    }

    /// @notice Adds a user to the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    /// @param fractalId is FractalId in bytes32.
    function addUserAddress(address addr, bytes32 fractalId) external {
        requireMutatePermission();
        fractalIdForAddress[addr] = fractalId;
    }

    /// @notice Removes an address from the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    function removeUserAddress(address addr) external {
        requireMutatePermission();
        delete fractalIdForAddress[addr];
    }

    /// @notice Checks if a user by FractalId exists in a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    /// @return bool if the user is the specified list.
    function isUserInList(bytes32 userId, string memory listId)
        external
        view
        returns (bool)
    {
        return userLists[listId][userId];
    }

    /// @notice Add user by FractalId to a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function addUserToList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        userLists[listId][userId] = true;
    }

    /// @notice Remove user by FractalId from a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function removeUserFromList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        delete userLists[listId][userId];
    }

    /// @notice Only root can add delegates. Delegates have mutate permissions.
    /// @param addr is Eth address
    function addDelegate(address addr) external {
        require(msg.sender == root, "Must be root");
        delegates[addr] = true;
    }

    /// @notice Removing delegates is only posible from root or by himself.
    /// @param addr is Eth address
    function removeDelegate(address addr) external {
        require(
            msg.sender == root || msg.sender == addr,
            "Not allowed to remove address"
        );
        delete delegates[addr];
    }

    function requireMutatePermission() private view {
        require(
            msg.sender == root || delegates[msg.sender],
            "Not allowed to mutate"
        );
    }
}