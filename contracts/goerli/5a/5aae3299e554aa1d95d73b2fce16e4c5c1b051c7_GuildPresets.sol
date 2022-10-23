pragma solidity ^0.8.13;
import './interfaces/IGuilds.sol';

contract GuildPresets {
    IGuilds guilds;
    constructor(address guildsContractAddress) public {
        guilds = IGuilds(guildsContractAddress);
    }

    event NewPreset(
        address indexed user, 
        bytes32 indexed contentHash, 
        uint32 indexed guildId, 
        bytes32 title,
        bytes32[9] encryptedContentKey,
        bytes32[6] publicKey);

    // allows querying what samples are in a preset (if any)
    event PresetSample(bytes32 indexed contentHash, bytes32 indexed sampleHash, uint32 indexed guildId);

    // allow querying the tags of a PresetSample
    event PresetTagged(address user, bytes32 indexed contentHash, bytes32 indexed tag, uint32 indexed guildId);

    // allow querying user's favorite PresetSample
    event PresetFavorited(address indexed user, bytes32 indexed contentHash);

    // allow querying user's favorite PresetSample
    event PresetInstrumentType(bytes32 indexed contentHash, bytes32 indexed instrumentType, uint32 indexed guildId);


    function newPreset(
        bytes32 contentHash,
        bytes32 title, // encrypted if guildId != 0
        bytes32 sampleHash,
        bytes32 instrumentType,
        uint32 guildId,
        bytes32[9] memory encryptedContentKey,
        bytes32[6] memory publicKey) 
    public {
        if (guildId != 0 && !guilds.isGuildMember(guildId, msg.sender)) {
            return;
        }
        emit NewPreset(
            msg.sender, 
            contentHash, 
            guildId, 
            title, 
            encryptedContentKey, 
            publicKey);

        if (sampleHash != 0x0) {
            emit PresetSample(contentHash, sampleHash, guildId);
        }

        if (instrumentType != 0x0) {
            emit PresetInstrumentType(contentHash, instrumentType, guildId);
        }
    }

    function newPresets(
        bytes32[] memory contentHashes,
        bytes32[] memory titles, // encrypted if guildId != 0
        bytes32 instrumentType,
        uint32 guildId,
        bytes32[9] memory encryptedContentKey,
        bytes32[6] memory publicKey) 
    public {
        if (guildId != 0 && !guilds.isGuildMember(guildId, msg.sender)) {
            return;
        }
        for (uint256 i=0; i < contentHashes.length; i++) {
            emit NewPreset(
                msg.sender, 
                contentHashes[i], 
                guildId, 
                titles[i], 
                encryptedContentKey, 
                publicKey);
            if (instrumentType != 0x0) {
                emit PresetInstrumentType(contentHashes[i], instrumentType, guildId);
            }
        }
    }

    function tagPreset(bytes32 contentHash, bytes32[4] memory tags, uint32 guildId) public {
        if (guildId != 0 && !guilds.isGuildMember(guildId, msg.sender)) {
            return;
        }
        for (uint8 i=0; i < 4; i++) {
            if (tags[i] != 0x0) {
                emit PresetTagged(msg.sender, contentHash, tags[i], guildId);
            }
        }
    }

    function favoritePreset(bytes32 contentHash) public {
        emit PresetFavorited(msg.sender, contentHash);
    }
}

pragma solidity ^0.8.13;

interface IGuilds {
    function newGuild(
        bytes32[6] memory guildPublicKey,
        string memory name,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory userPublicKey
    ) external returns (uint32);

    function connectWithUser(
        address user, 
        bytes32[6] memory guildPublicKey,
        string memory name,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory userPublicKey)
    external returns (uint32);

    function requestToAddMember(
        uint32 guildId,
        address potentialMember,
        bytes32 encryptedKeyIpfsHash,
        bytes32[9] memory contentKey,
        bytes32[6] memory publicKey)
    external;  

    function setPublicKeyForGuild(uint32 guildId, bytes32[6] memory publicKey) external; 
    
    function isGuildMember(uint32 guildId, address member) external view returns (bool);
}