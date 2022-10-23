pragma solidity ^0.8.13;
import './interfaces/IEncryption.sol';

contract Guilds {

    uint8 YES = 2;
    uint8 NO = 1;
    uint16 VOTE_THRESHOLD = 50;

    uint32 counter;
    IEncryption encryption;

    constructor(address encryptionContractAddress) public {
        counter = 1;
        encryption = IEncryption(encryptionContractAddress);
    }

    struct Guild {
        bytes32[6] publicKey;
        string name;
        address foundingMember;
    }

    // instead of samples
    mapping(uint32 => Guild) guilds;
    mapping(uint32 => address[]) guildToUsers;
    mapping(address => uint32[]) userToGuilds;

    // ex bytes32 for remix: 0x7465737400000000000000000000000000000000000000000000000000000000

    // users make requests to other users to join their guilds
    // once a user has accepted this request, they get added
    // to the newMemberPropsoals list in the Guilds struct
    mapping(address => uint32[]) userToGuildRequests;

    // user, guildId, name
    event NewGuild(address indexed, uint32 indexed, string name);
    event NewGuildMember(address indexed, uint32 indexed);
    event NewGuildMemberRequest(address indexed, address indexed, uint32 indexed);
    event NewGuildMemberRequestAccepted(address indexed, uint32 indexed);
    event NewGuildMemberRequestRejected(address indexed, uint32 indexed);
    event GuildMemberLeft(address indexed, uint32 indexed);
    event GuildPublicKeyChanged(uint32 indexed, bytes32[6] indexed);

    // guild key shared with user: user, guildId, ipfs address of guild key encrypted
    // then use the Encryption.sol contract to decrypt the guild key
    // kinda sucks cuz if ipfs gets lost then cant decrypt. but as following as there are otheres
    // they can reshare
    event GuildKeyEncrypted(address indexed,  uint32 indexed, bytes32 indexed);

    function newGuild(
        bytes32[6] memory guildPublicKey,
        string memory name,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory userPublicKey
        ) public returns (uint32) {
        uint32 guildId = counter;
        guilds[guildId].publicKey = guildPublicKey;
        guilds[guildId].name = name;
        guilds[guildId].foundingMember = msg.sender;
        guildToUsers[guildId].push(msg.sender);
        userToGuilds[msg.sender].push(guildId);
        counter++;

        emit NewGuild(msg.sender, guildId, name);

        // store the encrypted guild key to the block chain
        encryption.newEncryptedContent(
            0x00, encryptedKeyIpfsHash, 0x00, 3, contentKey, userPublicKey);
        emit GuildKeyEncrypted(msg.sender, guildId, encryptedKeyIpfsHash);
        emit GuildPublicKeyChanged(guildId, guildPublicKey);
        return guildId;
    }

    // a utility method for quickly creating a new guildId
    // and requesting that a user joins.
    function connectWithUser(
        address user, 
        bytes32[6] memory guildPublicKey,
        string memory name,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory userPublicKey)
    public returns (uint32) {
        uint32 guildId = newGuild(guildPublicKey, name, encryptedKeyIpfsHash, contentKey, userPublicKey);
        requestToAddMember(guildId, user, encryptedKeyIpfsHash, contentKey, userPublicKey);

        return guildId;
    }

    // request user joins a guild, encrypting the guild's key and giving to user
    function requestToAddMember(
        uint32 guildId,
        address potentialMember,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory publicKey)
    public  {
        if (!isGuildMember(guildId, msg.sender) || potentialMember == msg.sender) {
            return;
        }

        // first share the guild key with the potential user
        encryption.shareEncryptedContentWith(
            potentialMember, encryptedKeyIpfsHash, contentKey, publicKey);
        emit GuildKeyEncrypted(potentialMember, guildId, encryptedKeyIpfsHash);

        // then notify the user that there is a new request (so they can accept/reject)
        userToGuildRequests[potentialMember].push(guildId);
        emit NewGuildMemberRequest(msg.sender, potentialMember, guildId);
    }

    function addMemberToGuild(uint32 guildId, address user) private {
        // TODO: make it democratic such that voting occurs to add members
        if (!hasIndexAddress(guildToUsers[guildId], user)) {
            // the msg.sender is part of the guild and user
            // they want to add is not part of the guild
            guildToUsers[guildId].push(user);
            userToGuilds[user].push(guildId);
            emit NewGuildMember(msg.sender, guildId);
        }
    }

    function isGuildMember(uint32 guildId, address member) private view returns (bool) {
        return hasIndexAddress(guildToUsers[guildId], member);
    }

    function removeMemberFromGuild(uint32 guildId, address user) private {
        // only founding member can do this
        // TODO: make it democratic such that voting occurs to remove members
        if (guilds[guildId].foundingMember == msg.sender &&
            hasIndexAddress(guildToUsers[guildId], user)) {
            guildToUsers[guildId] = deleteAtIndexAddress(
                guildToUsers[guildId], getIndexAddress(guildToUsers[guildId], user));
            userToGuilds[user] = deleteAtIndexuint32(
                userToGuilds[user], getIndexuint32(userToGuilds[user], guildId));
            emit GuildMemberLeft(msg.sender, guildId);
        }
    }


    function setPublicKeyForGuild(uint32 guildId, bytes32[6] memory publicKey) public {
        // only founding member can change the public key
        // TODO: make it democratic such that voting occurs to remove members
        if (!isGuildMember(guildId, msg.sender)) {
          return;
        }
        guilds[guildId].publicKey = publicKey;
        emit GuildPublicKeyChanged(guildId, publicKey);

    }

    function setNameForGuild(uint32 guildId, string memory name) public {
        // TODO: make it democratic such that voting occurs to remove members
        if (!isGuildMember(guildId, msg.sender)) {
          return;
        }
        guilds[guildId].name = name;
    }

    function getTotalGuildUsers(uint32 guildId) public view returns (uint256) {
        return guildToUsers[guildId].length;
    }

    function getUserFromGuild(uint32 guild, uint32 i) public view returns (address) {
        return guildToUsers[guild][i];
    }

    function getGuildName(uint32 guildId) public view returns (string memory) {
        return guilds[guildId].name;
    }

    // returns total number of guilds a user is a part of
    function getTotalGuildsForSelf() public view returns (uint256) {
        return userToGuilds[msg.sender].length;
    }

    // returns i'th guildId for user
    function getGuildForSelf(uint32 i) public view returns (uint32) {
        return userToGuilds[msg.sender][i];
    }

    // returns total number of guilds a user is a part of
    function getTotalGuildsForUser(address user) public view returns (uint256) {
        return userToGuilds[user].length;
    }

    // returns i'th guildId for user
    function getGuildForUser(address user, uint32 i) public view returns (uint32) {
        return userToGuilds[user][i];
    }



    function rejectRequestToAddToGuild(uint32 guildId) public {
      if (hasIndexuint32(userToGuildRequests[msg.sender], guildId)) {
          // delete from list of potential guilds
          userToGuildRequests[msg.sender] = deleteAtIndexuint32(
              userToGuildRequests[msg.sender],
              getIndexuint32(userToGuildRequests[msg.sender], guildId));

          emit NewGuildMemberRequestRejected(msg.sender, guildId);
      }
    }

    function acceptRequestToAddToGuild(uint32 guildId) public {
        if (hasIndexuint32(userToGuildRequests[msg.sender], guildId)) {
            // delete from list of potential guilds
            userToGuildRequests[msg.sender] = deleteAtIndexuint32(
                userToGuildRequests[msg.sender],
                getIndexuint32(userToGuildRequests[msg.sender], guildId));

            emit NewGuildMemberRequestAccepted(msg.sender, guildId);

            addMemberToGuild(guildId, msg.sender);
        }
    }

    // the following functions help vote for new users

    // the remaining functions are helper functions for arrays

    function hasIndexAddress(address[] storage list, address data) private view returns (bool) {
        for (uint32 i=0; i < list.length; i++) {
            if (list[i] == data) {
	            return true;
            }
        }
        return false;
    }

    function getIndexAddress(address[] storage list, address data) private view returns (uint32) {
        for (uint32 i=0; i < list.length; i++) {
            if (list[i] == data) {
	            return i;
            }
        }
        return 0;
    }

    function deleteAtIndexAddress(address[] storage list, uint32 index) private returns (address[] storage) {
        if (index == list.length - 1) {
            delete list[index];
            //list.length--;
            return list;
        }

	    delete list[index];
        list[index] = list[list.length - 1];
        //        list.length--;
	    return list;
    }

    function hasIndexuint32(uint32[] storage list, uint32 data) private view returns (bool) {
        for (uint32 i=0; i < list.length; i++) {
            if (list[i] == data) {
	            return true;
            }
        }
        return false;
    }

    function getIndexuint32(uint32[] storage list, uint32 data) private view returns (uint32) {
        for (uint32 i=0; i < list.length; i++) {
            if (list[i] == data) {
	            return i;
            }
        }
        return 0;
    }

    function deleteAtIndexuint32(uint32[] storage list, uint32 index) private returns (uint32[] storage) {
        if (index == list.length - 1) {
            delete list[index];
            //list.length--;
            return list;
        }

	    delete list[index];
        list[index] = list[list.length - 1];
        //list.length--;
	    return list;
    }
}

pragma solidity ^0.8.13;

interface IEncryption {
    function newEncryptedContent(
        bytes32 previousContentHash,
        bytes32 newContentHash,
        bytes32 encryptedName,
        int8 contentType,
        bytes32[9] memory encryptedContentKey,
        bytes32[6] memory publicKey) external;

    function shareEncryptedContentWith(
        address sharedWith,
        bytes32 contentHash,
        bytes32[9] memory encryptedContentKey,
        bytes32[6] memory publicKey) external;
}