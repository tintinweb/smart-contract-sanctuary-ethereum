// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../interfaces/IMintNFT.sol";
import "./Events.sol";
import "./DataTypes.sol";
import "../interfaces/IMintModule4Note.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library InteractionLogic {
    using Strings for uint256;

    function mintNote(
        uint256 profileId,
        uint256 noteId,
        address to,
        bytes calldata mintModuleData,
        address mintNFTImpl,
        mapping(uint256 => DataTypes.Profile) storage _profileById,
        mapping(uint256 => mapping(uint256 => DataTypes.Note)) storage _noteByIdByProfile
    ) external returns (uint256 tokenId) {
        address mintNFT = _noteByIdByProfile[profileId][noteId].mintNFT;
        if (mintNFT == address(0)) {
            mintNFT = _deployMintNFT(
                profileId,
                noteId,
                _profileById[profileId].handle,
                mintNFTImpl
            );
            _noteByIdByProfile[profileId][noteId].mintNFT = mintNFT;
        }

        // mint nft
        tokenId = IMintNFT(mintNFT).mint(to);

        address mintModule = _noteByIdByProfile[profileId][noteId].mintModule;
        IMintModule4Note(mintModule).processMint(profileId, noteId, mintModuleData);

        emit Events.MintNote(to, profileId, noteId, tokenId, mintModuleData, block.timestamp);
    }

    function _deployMintNFT(
        uint256 profileId,
        uint256 noteId,
        string memory handle,
        address mintNFTImpl
    ) private returns (address) {
        address mintNFT = Clones.clone(mintNFTImpl);

        bytes4 firstBytes = bytes4(bytes(handle));

        string memory NFTName = string(
            abi.encodePacked(handle, "-Mint-", profileId.toString(), "-", noteId.toString())
        );
        string memory NFTSymbol = string(
            abi.encodePacked(firstBytes, "-Mint-", profileId.toString(), "-", noteId.toString())
        );

        IMintNFT(mintNFT).initialize(profileId, noteId, address(this), NFTName, NFTSymbol);
        return mintNFT;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMintNFT {
    function initialize(
        uint256 profileId,
        uint256 noteId,
        address web3Entry,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(address to) external returns (uint256);

    function getSourcePublicationPointer() external view returns (uint256, uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}