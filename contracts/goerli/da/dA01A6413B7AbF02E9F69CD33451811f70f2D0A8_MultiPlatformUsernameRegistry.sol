pragma solidity 0.8.13;

contract MultiPlatformUsernameRegistry {
    struct User {
        address userAddress;
        mapping(string => string) platformUsernames;
    }

    mapping(address => User) public addressToUser;
    mapping(string => mapping(string => address)) public platformUsernameToAddress;
    address[] public userAddressList;

    function addUser(address userAddress, string memory platform, string memory username) public {
        require(platformUsernameToAddress[platform][username] == address(0), "Username already taken on this platform");
        require(bytes(username).length > 0, "Username cannot be empty");
        require(msg.sender == userAddress, "You can only add your own username");

        User storage user = addressToUser[userAddress];
        if (bytes(user.platformUsernames[platform]).length == 0) {
            userAddressList.push(userAddress);
        }

        user.userAddress = userAddress;
        user.platformUsernames[platform] = username;
        platformUsernameToAddress[platform][username] = userAddress;
    }

    function checkUsernameExists(string memory platform, string memory username) public view returns (bool) {
        if (platformUsernameToAddress[platform][username] == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function checkAddressExists(address userAddress, string memory platform) public view returns (bool) {
        if (bytes(addressToUser[userAddress].platformUsernames[platform]).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    function addMyUser(string memory platform, string memory username) public {
        this.addUser(msg.sender, platform, username);
    }

    function getUsername(address userAddress, string memory platform) public view returns (string memory) {
        return addressToUser[userAddress].platformUsernames[platform];
    }

    function searchUsername(string memory platform, string memory partialUsername) public view returns (address[] memory) {
        uint256 matchCount = 0;
        uint256 numUsers = userAddressList.length;
        address[] memory matches = new address[](numUsers);
        for (uint256 i = 0; i < numUsers; i++) {
            address currentUserAddress = userAddressList[i];
            string memory currentUsername = addressToUser[currentUserAddress].platformUsernames[platform];
            if (matchesPartial(currentUsername, partialUsername)) {
                matches[matchCount] = currentUserAddress;
                matchCount++;
            }
        }

        address[] memory trimmedMatches = new address[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            trimmedMatches[i] = matches[i];
        }

        return trimmedMatches;
    }

    function matchesPartial(string memory a, string memory b) public pure returns (bool) {
        bytes memory aBytes = bytes(a);
        bytes memory bBytes = bytes(b);
        if (bBytes.length > aBytes.length) {
            return false;
        }
        for (uint256 i = 0; i < bBytes.length; i++) {
            if (bBytes[i] != aBytes[i]) {
                return false;
            }
        }
        return true;
    }
}