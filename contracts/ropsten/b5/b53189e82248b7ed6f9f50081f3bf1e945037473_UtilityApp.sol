/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

contract UtilityApp{

    /*Structs*/

    // Stores the default name of an user and other info
    struct user {
        string name;
        address userAddress;
        string RSA_Key;
    }

    // message construct stores the single chat message and its metadata
    struct message {
        address sender;
        uint256 timestamp;
        string msg;
        string msgType;
    }
   
    /*Mappings*/

    // Collection of users registered on the application
    mapping(address => user) public userList;

    // Collection of users by searching username
    mapping(string => address) internal userData;

    // Collection of messages communicated in a channel between two users
    mapping(bytes32 => message[]) allMessages; // key : Hash(user1,user2)

    /*Modifiers*/

    // Modifier for only users that registered
      modifier onlyMember() {
        require(checkUserExists(msg.sender) == true, "caller is not member");
        _;
    }

    /*Contract helper functions*/

    // Helper function to check if user exist or not
      function checkUserExists(address walletAddress) public view returns(bool) {
        return bytes(userList[walletAddress].name).length > 0;
    }

    // Returns a unique code for the channel created between the two users
    // Hash(key1,key2) where key1 is lexicographically smaller than key2
    function _getChatCode(address pubkey1, address pubkey2) internal pure returns(bytes32) {
        if(pubkey1 < pubkey2)
            return keccak256(abi.encodePacked(pubkey1, pubkey2));
        else
            return keccak256(abi.encodePacked(pubkey2, pubkey1));
    }


    /*Public Functions*/

    // Registration of new Users
    /**
     * @param userName string
     * @param _RSA_Public_Key string
     */
    function userRegistration(string calldata userName, string memory _RSA_Public_Key) public {
        require(bytes(userName).length>0, "Username cannot be empty!");
        userList[msg.sender].name = userName; 
        userList[msg.sender].userAddress = msg.sender;
        userList[msg.sender].RSA_Key = _RSA_Public_Key;
        userData[userName] = msg.sender;
    }

    // Sends a new message to a given friend
    /**
     * @param to address
     * @param _msg string
     * @param msgType string
     */
    function sendMessage(address to, string calldata _msg, string calldata msgType) external {
        require(checkUserExists(msg.sender), "Create an account first!");
        require(checkUserExists(to), "User is not registered!");

        bytes32 chatCode = _getChatCode(msg.sender, to);
        message memory newMsg = message(msg.sender, block.timestamp, _msg, msgType);
        allMessages[chatCode].push(newMsg);
    }

    /*Set functions*/

     // Set function to update RSA-key of users
     /**
     * @param newRSAkey string
     */
    function updateRSAkey(string memory newRSAkey) public onlyMember{
        userList[msg.sender].RSA_Key = newRSAkey;
    }
    
    /*View functions*/

    // View funtion to see users RSA-key
    function viewRSAKey() public view returns(string memory){
        return userList[msg.sender].RSA_Key;
    }

     // View function to find user and get in-return their data
     /**
     * @param username string
     */
    function findUser(string memory username) public view returns(user memory ) {
        address data = userData[username];
        return userList[data];
    }

     // Returns all the chat messages communicated to different users
     /**
     * @param to address
     */
    function readMessage(address to) external view returns(message[] memory) {
        require(checkUserExists(msg.sender), "Create an account first!");
        bytes32 chatCode = _getChatCode(msg.sender, to);
        return allMessages[chatCode];
    }
}