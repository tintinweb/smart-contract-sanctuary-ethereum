// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Registry {
    /// @notice Map of Addresses to Usernames that they own.
    /// @dev The usernames are encoded as bytes32.
    mapping(address => bytes32) public addressToUsername;

    /// @notice A struct used to store a URL in the Registry.
    /// @dev Always set initialized=true when the value is set. This makes presence checks easy.
    struct UrlEntry {
        string url;
        bool initialized;
    }

    /// @notice Map of Usernames to Directory urls.
    /// @dev The usernames are encoded as bytes32 and the Directory is structured as UrlEntry.
    mapping(bytes32 => UrlEntry) public usernameToUrl;

    /// @notice Event fired when a new username is registered
    /// @dev Can probably save gas costs by reducing indexes and making anonymous events if needed.
    /// @param owner - the address that owns the username.
    /// @param username - the username that was registered.
    event RegisterName(address indexed owner, bytes32 indexed username);

    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    /// @notice Register a new username.
    /// @param username the username string (e.g. alice) encoded as byte32.
    /// @param url the url string that points to the user's profile.
    function register(bytes32 username, string memory url) public {
        require(username != 0, "Username cannot be empty");
        require(
            _isAllowedAsciiString(username) == true,
            "Username must be lowercase alphanumeric"
        );
        require(
            addressToUsername[_msgSender()] == 0,
            "Sender already registered a username"
        );
        require(
            usernameToUrl[username].initialized == false,
            "This username was already registered"
        );

        addressToUsername[_msgSender()] = username;
        usernameToUrl[username] = UrlEntry({url: url, initialized: true});
        emit RegisterName(_msgSender(), username);
    }

    /// @notice Checks if a string contains valid username ASCII characters [0-1], [a-z] and _.
    /// @param str the string to be checked.
    /// @return true if the string contains only valid characters, false otherwise.
    function _isAllowedAsciiString(bytes32 str) internal pure returns (bool) {
        for (uint256 i = 0; i < str.length; i++) {
            uint8 charInt = uint8(str[i]);
            if (
                (charInt >= 1 && charInt <= 47) ||
                (charInt >= 58 && charInt <= 94) ||
                charInt == 96 ||
                charInt >= 123
            ) {
                return false;
            }
        }
        return true;
    }
}