// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./DataTypes.sol";
import "./Events.sol";
import "../interfaces/ILinkModule4Note.sol";
import "../interfaces/IMintModule4Note.sol";

library PostLogic {
    function postNote4Link(
        DataTypes.PostNoteData calldata noteData,
        uint256 noteId,
        uint256 linklistId,
        bytes32 linkItemType,
        bytes32 linkKey,
        mapping(uint256 => mapping(uint256 => DataTypes.Note)) storage _noteByIdByProfile
    ) external {
        uint256 profileId = noteData.profileId;
        // save note
        if (linkItemType != bytes32(0)) {
            _noteByIdByProfile[profileId][noteId].linkItemType = linkItemType;
            _noteByIdByProfile[profileId][noteId].linklistId = linklistId;
            _noteByIdByProfile[profileId][noteId].linkKey = linkKey;
        }
        _noteByIdByProfile[profileId][noteId].contentUri = noteData.contentUri;
        _noteByIdByProfile[profileId][noteId].linkModule = noteData.linkModule;
        _noteByIdByProfile[profileId][noteId].mintModule = noteData.mintModule;

        // init link module
        bytes memory linkModuleReturnData = ILinkModule4Note(noteData.linkModule)
            .initializeLinkModule(profileId, noteId, noteData.linkModuleInitData);

        // init mint module
        bytes memory mintModuleReturnData = IMintModule4Note(noteData.mintModule)
            .initializeMintModule(profileId, noteId, noteData.mintModuleInitData);

        emit Events.SetLinkModule4Note(
            profileId,
            noteId,
            noteData.linkModule,
            linkModuleReturnData,
            block.timestamp
        );
        emit Events.SetMintModule4Note(
            profileId,
            noteId,
            noteData.mintModule,
            mintModuleReturnData,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library DataTypes {
    struct CreateProfileData {
        address to;
        string handle;
        string uri;
        address linkModule;
        bytes linkModuleInitData;
    }

    struct linkProfileLinkData {
        uint256 fromProfileId;
        bytes32 linkType;
        uint256 profileLinkFromProfileId;
        uint256 profileLinkToProfileId;
        bytes32 profileLinkLinkType;
    }

    struct LinkData {
        uint256 linklistId;
        uint256 linkItemType;
        uint256 linkingProfileId;
        address linkingAddress;
        uint256 linkingLinklistId;
        bytes32 linkKey;
    }

    struct PostNoteData {
        uint256 profileId;
        string contentUri;
        address linkModule;
        bytes linkModuleInitData;
        address mintModule;
        bytes mintModuleInitData;
    }

    // profile struct
    struct Profile {
        uint256 profileId;
        string handle;
        string uri;
        uint256 noteCount;
        address socialToken;
        address linkModule;
    }

    // note struct
    struct Note {
        bytes32 linkItemType;
        uint256 linklistId;
        bytes32 linkKey; // if linkKey is not empty, it is a note with link
        string contentUri;
        address linkModule;
        address mintModule;
        address mintNFT;
    }

    struct ProfileLinkStruct {
        uint256 fromProfileId;
        uint256 toProfileId;
        bytes32 linkType;
    }

    struct NoteStruct {
        uint256 profileId;
        uint256 noteId;
    }

    struct ERC721Struct {
        address tokenAddress;
        uint256 erc721TokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library Events {
    event BaseInitialized(string name, string symbol, uint256 timestamp);

    event Web3EntryInitialized(uint256 timestamp);

    event LinklistNFTInitialized(uint256 timestamp);

    event MintNFTInitialized(uint256 profileId, uint256 noteId, uint256 timestamp);

    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        uint256 timestamp
    );

    event SetPrimaryProfileId(address indexed account, uint256 indexed profileId);

    event SetHandle(address indexed account, uint256 indexed profileId, string newHandle);

    event SetSocialToken(
        address indexed account,
        uint256 indexed profileId,
        address indexed tokenAddress
    );

    event LinkProfile(
        address indexed account,
        uint256 indexed fromProfileId,
        uint256 indexed toProfileId,
        bytes32 linkType,
        uint256 linklistId
    );

    event UnlinkProfile(
        address indexed account,
        uint256 indexed fromProfileId,
        uint256 indexed toProfileId,
        bytes32 linkType
    );

    event LinkNote(
        uint256 indexed fromProfileId,
        uint256 indexed toProfileId,
        uint256 indexed toNoteId,
        bytes32 linkType,
        uint256 linklistId
    );

    event UnlinkNote(
        uint256 indexed fromProfileId,
        uint256 indexed toProfileId,
        uint256 indexed toNoteId,
        bytes32 linkType,
        uint256 linklistId
    );

    event LinkERC721(
        uint256 indexed fromProfileId,
        address indexed tokenAddress,
        uint256 indexed toNoteId,
        bytes32 linkType,
        uint256 linklistId
    );

    event LinkAddress(
        uint256 indexed fromProfileId,
        address indexed ethAddress,
        bytes32 linkType,
        uint256 linklistId
    );

    event UnlinkAddress(
        uint256 indexed fromProfileId,
        address indexed ethAddress,
        bytes32 linkType
    );

    event LinkAny(
        uint256 indexed fromProfileId,
        string toUri,
        bytes32 linkType,
        uint256 linklistId
    );

    event UnlinkAny(uint256 indexed fromProfileId, string toUri, bytes32 linkType);

    event LinkProfileLink(
        uint256 indexed fromProfileId,
        bytes32 indexed linkType,
        uint256 plFromProfileId,
        uint256 plToProfileId,
        bytes32 plLinkType
    );

    event UnlinkProfileLink(
        uint256 indexed fromProfileId,
        bytes32 indexed linkType,
        uint256 plFromProfileId,
        uint256 plToProfileId,
        bytes32 plLinkType
    );

    event UnlinkERC721(
        uint256 indexed fromProfileId,
        address indexed tokenAddress,
        uint256 indexed toNoteId,
        bytes32 linkType,
        uint256 linklistId
    );

    event LinkLinklist(
        uint256 indexed fromProfileId,
        uint256 indexed toLinklistId,
        bytes32 linkType,
        uint256 indexed linklistId
    );

    event UninkLinklist(
        uint256 indexed fromProfileId,
        uint256 indexed toLinklistId,
        bytes32 linkType,
        uint256 indexed linklistId
    );

    event MintNote(
        address indexed to,
        uint256 indexed profileId,
        uint256 indexed noteId,
        uint256 tokenId,
        bytes data,
        uint256 timestamp
    );

    event SetLinkModule4Profile(
        uint256 indexed profileId,
        address indexed linkModule,
        bytes returnData,
        uint256 timestamp
    );

    event SetLinkModule4Note(
        uint256 indexed profileId,
        uint256 indexed noteId,
        address indexed linkModule,
        bytes returnData,
        uint256 timestamp
    );

    event SetLinkModule4Address(
        address indexed account,
        address indexed linkModule,
        bytes returnData,
        uint256 timestamp
    );

    event SetLinkModule4ERC721(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address indexed linkModule,
        bytes returnData,
        uint256 timestamp
    );

    event SetLinkModule4Linklist(
        uint256 indexed linklistId,
        address indexed linkModule,
        bytes returnData,
        uint256 timestamp
    );

    event SetMintModule4Note(
        uint256 indexed profileId,
        uint256 indexed noteId,
        address indexed mintModule,
        bytes returnData,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ILinkModule4Note {
    function initializeLinkModule(
        uint256 profileId,
        uint256 noteId,
        bytes calldata data
    ) external returns (bytes memory);

    function processLink(
        uint256 profileId,
        uint256 noteId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMintModule4Note {
    function initializeMintModule(
        uint256 profileId,
        uint256 noteId,
        bytes calldata data
    ) external returns (bytes memory);

    function processMint(
        uint256 profileId,
        uint256 noteId,
        bytes calldata data
    ) external;
}