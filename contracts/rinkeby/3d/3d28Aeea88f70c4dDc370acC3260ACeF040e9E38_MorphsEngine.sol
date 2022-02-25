// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

            ███╗   ███╗ ██████╗ ██████╗ ██████╗ ██╗  ██╗███████╗
            ████╗ ████║██╔═══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝
            ██╔████╔██║██║   ██║██████╔╝██████╔╝███████║███████╗
            ██║╚██╔╝██║██║   ██║██╔══██╗██╔═══╝ ██╔══██║╚════██║
            ██║ ╚═╝ ██║╚██████╔╝██║  ██║██║     ██║  ██║███████║
            ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝

                         Genesis II - 2022-02-25

                           https://morphs.wtf

    Dreamt up and built at Playgrounds <https://playgrounds.wtf>
    Powered by shell <https://heyshell.xyz>
    Designed by @polyforms_ <https://twitter.com/polyforms_>

    ---

    This is the second official Morphs engine from Playgrounds 🪐

    It adds a few twists for the final days of minting and leaves some open
    ended ideas to explore in future engines.

    You are free to iterate on any Morphs tokens you own! If others like the
    updates you've made to the project, they could join your fork too.

    Join us in the lab: https://discord.gg/uskZYttHw6

*/

import "@r-group/shell-contracts/contracts/engines/ShellBaseEngine.sol";
import "@r-group/shell-contracts/contracts/engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MorphsEngine is ShellBaseEngine, OnChainMetadataEngine {
    /// @notice Attempted mint after minting period has ended
    error MintingPeriodHasEnded();

    /// @notice Attempted cutover for a collection that already switched, or
    /// from incorrect msg sender
    error InvalidCutover();

    /// @notice Some actions require msg.sender to own the token being
    /// interacting with
    error NotTokenOwner();

    /// @notice Morphs only works with ERC-721s for now, since we are allowing
    /// owner-specific behavior with sigils and balance checks for entangled
    /// Morphs. It could be made compat with ERC-1155s with some finessing if desired
    error InvalidCollection();

    /// @notice Sigil attempted to be set that didnt pass verification
    error InvalidSigil();

    /// @notice Can't mint after March 1st midnight CST
    uint256 public constant MINTING_ENDS_AT_TIMESTAMP = 1646114400;

    /// @notice Displayed on heyshell.xyz
    function name() external pure returns (string memory) {
        return "morphs-v2";
    }

    /// @notice Mint a morph!
    /// @param flag Permenantly written into the NFT. Cannot be modified after mint
    function mint(IShellFramework collection, uint256 flag)
        external
        returns (uint256)
    {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= MINTING_ENDS_AT_TIMESTAMP) {
            revert MintingPeriodHasEnded();
        }

        IntStorage[] memory intData;

        // flag is written to token mint data if set
        if (flag != 0) {
            intData = new IntStorage[](1);
            intData[0] = IntStorage({key: "flag", value: flag});
        } else {
            intData = new IntStorage[](0);
        }

        uint256 tokenId = collection.mint(
            MintEntry({
                to: msg.sender,
                amount: 1,
                options: MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: new StringStorage[](0),
                    intData: intData
                })
            })
        );

        return tokenId;
    }

    /// @notice Mint several Morphs in a single transaction (flag=0 for all)
    function batchMint(IShellFramework collection, uint256 count) external {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= MINTING_ENDS_AT_TIMESTAMP) {
            revert MintingPeriodHasEnded();
        }

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        for (uint256 i = 0; i < count; i++) {
            collection.mint(
                MintEntry({
                    to: msg.sender,
                    amount: 1,
                    options: MintOptions({
                        storeEngine: false,
                        storeMintedTo: false,
                        storeTimestamp: false,
                        storeBlockNumber: false,
                        stringData: stringData,
                        intData: intData
                    })
                })
            );
        }
    }

    /// @notice start using the new token rolling logic, can only be called once
    /// and by the root fork owner of the collection
    function cutover(IShellFramework collection) external {
        if (collection.readForkInt(StorageLocation.ENGINE, 0, "cutover") != 0) {
            revert InvalidCutover();
        }
        if (msg.sender != collection.getForkOwner(0)) {
            revert InvalidCutover();
        }

        // cutover token = next token ID, all future tokens will use new algo
        collection.writeForkInt(
            StorageLocation.ENGINE,
            0,
            "cutover",
            collection.nextTokenId()
        );
    }

    /// @notice Owner of a token may write a "sigil" string value to token
    /// storage at any time
    function updateSigil(
        IShellFramework collection,
        uint256 tokenId,
        string memory sigil
    ) external {
        IERC721 erc721 = IERC721(address(collection));

        if (erc721.ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }

        if (bytes(sigil).length > 8) {
            revert InvalidSigil();
        }

        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "sigil",
            sigil
        );
    }

    /// @dev because of the owner semantics, we want to be able to assume the
    /// collection is a 721
    function afterEngineSet(uint256)
        external
        view
        override(IEngine, ShellBaseEngine)
    {
        IShellFramework collection = IShellFramework(msg.sender);
        bool is721 = collection.supportsInterface(type(IERC721).interfaceId);

        if (!is721) {
            revert InvalidCollection();
        }
    }

    /// @notice Gets the flag value written at mint time for a specific NFT
    function getFlag(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            collection.readTokenInt(StorageLocation.MINT_DATA, tokenId, "flag");
    }

    /// @notice Returns true if this token was minted after the engine cutover
    function isCutoverToken(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (bool)
    {
        uint256 transitionTokenId = collection.readForkInt(
            StorageLocation.ENGINE,
            0,
            "cutover"
        );

        return transitionTokenId != 0 && tokenId >= transitionTokenId;
    }

    /// @notice Get the palette index (1-based) for a specific token
    function getPaletteIndex(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        // new logic, select palette 7-24
        if (isCutoverToken(collection, tokenId)) {
            return selectInRange(tokenId, 7, 24);
        }

        // OG logic - only selects palette 1-6
        return selectInRange(tokenId, 1, 6);
    }

    /// @notice Get the edition index (0-based) for a specific token
    function getEditionIndex(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 flag = getFlag(collection, tokenId);
        bool isCutover = isCutoverToken(collection, tokenId);

        // celestial = always use 0th edition
        if (flag > 2) {
            return 0;
        }

        // OG tokens always = edition 1
        if (!isCutover) {
            return 1;
        }

        // else, edition is strictly a function of the palette
        // palette will be 7-24 since this is a post-cutover token
        uint256 palette = getPaletteIndex(collection, tokenId);

        if (palette < 13) {
            return 2;
        }
        if (palette < 19) {
            return 3;
        }

        return 4;
    }

    /// @notice Get the variation for a specific token
    function getVariation(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bool isCutover = isCutoverToken(collection, tokenId);
        uint256 flag = getFlag(collection, tokenId);

        // all celestials (old and new) roll a variation based on flag value
        if (flag > 2) {
            // 5 celestials, Z1-Z5
            return
                string.concat("Z", Strings.toString(selectInRange(flag, 1, 5)));
        }

        // OG logic
        if (!isCutover) {
            if (flag == 2) {
                // Only 1 OG cosmic
                return "X1";
            } else if (flag == 1) {
                // 4 OG mythicals, M1-M4
                return
                    string.concat(
                        "M",
                        Strings.toString(selectInRange(tokenId, 1, 4))
                    );
            }

            // 10 OG citizen, C1-C10
            return
                string.concat(
                    "C",
                    Strings.toString(selectInRange(tokenId, 1, 10))
                );
        }

        // post-cutover logic
        if (flag == 2) {
            // 4 new cosmic, X2-5
            return
                string.concat(
                    "X",
                    Strings.toString(selectInRange(tokenId, 2, 5))
                );
        } else if (flag == 1) {
            // 11 new mythicals, M5-15
            return
                string.concat(
                    "M",
                    Strings.toString(selectInRange(tokenId, 5, 15))
                );
        }

        // 15 new citizens, C11-25
        return
            string.concat(
                "C",
                Strings.toString(selectInRange(tokenId, 11, 25))
            );
    }

    /// @dev return a number between lower and upper, inclusive... based on seed
    function selectInRange(
        uint256 seed,
        uint256 lower,
        uint256 upper
    ) private pure returns (uint256) {
        uint256 i = uint256(keccak256(abi.encodePacked(seed))) %
            (upper - lower + 1);
        return lower + i;
    }

    /// @notice Get the name of a palette by index
    function getPaletteName(uint256 index) public pure returns (string memory) {
        if (index == 1) {
            return "Greyskull";
        } else if (index == 2) {
            return "Ancient Opinions";
        } else if (index == 3) {
            return "The Desert Sun";
        } else if (index == 4) {
            return "The Deep";
        } else if (index == 5) {
            return "The Jade Prism";
        } else if (index == 6) {
            return "Cosmic Understanding";
        } else if (index == 7) {
            return "Ancient Grudges";
        } else if (index == 8) {
            return "Radiant Beginnings";
        } else if (index == 9) {
            return "Desert Sand";
        } else if (index == 10) {
            return "Arcane Slate";
        } else if (index == 11) {
            return "The Vibrant Forest";
        } else if (index == 12) {
            return "Evening Star";
        } else if (index == 13) {
            return "Dawn";
        } else if (index == 14) {
            return "Calm Air";
        } else if (index == 15) {
            return "Solarion";
        } else if (index == 16) {
            return "Morning Sun";
        } else if (index == 17) {
            return "Emerald";
        } else if (index == 18) {
            return "Stellaris";
        } else if (index == 19) {
            return "Future Island";
        } else if (index == 20) {
            return "Scorched Emerald";
        } else if (index == 21) {
            return "Stone";
        } else if (index == 22) {
            return "The Night Sky";
        } else if (index == 23) {
            return "The Beacon";
        } else if (index == 24) {
            return "Blackskull";
        }

        return "";
    }

    /// @notice Read the sigil value in storage for a specific token
    function getSigil(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            collection.readTokenString(
                StorageLocation.ENGINE,
                tokenId,
                "sigil"
            );
    }

    /// @notice Returns true if a token has an address as a flag that has at
    /// least 1 Morph
    function isEntangled(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (bool)
    {
        uint256 flag = getFlag(collection, tokenId);
        IERC721 erc721 = IERC721(address(collection));
        address subject = address(uint160(flag));

        return flag > 0 && erc721.balanceOf(subject) > 0;
    }

    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        uint256 flag = getFlag(collection, tokenId);
        bool entangled = isEntangled(collection, tokenId);

        return
            string(
                abi.encodePacked(
                    "Morph #",
                    Strings.toString(tokenId),
                    entangled ? ": Entangled Scroll of " : flag > 2
                        ? ": Celestial Scroll of "
                        : flag == 2
                        ? ": Cosmic Scroll of "
                        : flag == 1
                        ? ": Mythical Scroll of "
                        : ": Scroll of ",
                    getPaletteName(getPaletteIndex(collection, tokenId))
                )
            );
    }

    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        uint256 flag = getFlag(collection, tokenId);

        return
            string.concat(
                flag > 2
                    ? "A mysterious scroll... you feel it pulsating with celestial energy. Its presence bridges the gap between old and new."
                    : flag == 2
                    ? "A mysterious scroll... you feel it pulsating with cosmic energy. Its whispers speak secrets of cosmic significance."
                    : flag == 1
                    ? "A mysterious scroll... you feel it pulsating with mythical energy. You sense its power is great."
                    : "A mysterious scroll... you feel it pulsating with energy. What secrets might it hold?",
                isEntangled(collection, tokenId)
                    ? string.concat(
                        "\\n\\nThis Morph is entangled with address ",
                        Strings.toHexString(flag)
                    )
                    : flag > 2
                    ? string.concat(
                        "\\n\\nEternal celestial signature: ",
                        Strings.toString(flag)
                    )
                    : "",
                isCutoverToken(collection, tokenId)
                    ? "\\n\\nThis Morph was minted in the Genesis II era."
                    : "\\n\\nThis Morph was minted in the Genesis I era.",
                "\\n\\nhttps://playgrounds.wtf"
            );
    }

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        uint256 edition = getEditionIndex(collection, tokenId);
        uint256 palette = getPaletteIndex(collection, tokenId);
        string memory variation = getVariation(collection, tokenId);

        string memory image = string.concat(
            "S",
            Strings.toString(edition),
            "-",
            "P",
            Strings.toString(palette),
            "-",
            variation,
            ".png"
        );

        return
            string.concat(
                "ipfs://ipfs/QmeQi6Ufs4JyrMR54o9TRraKMRhp1MTL2Bn811ad8Y7kK1/",
                image
            );
    }

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://morphs.wtf";
    }

    function _computeAttributes(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (Attribute[] memory)
    {
        uint256 palette = getPaletteIndex(collection, tokenId);
        string memory sigil = getSigil(collection, tokenId);

        Attribute[] memory attributes = new Attribute[](8);

        attributes[0] = Attribute({
            key: "Palette",
            value: getPaletteName(palette)
        });

        attributes[1] = Attribute({
            key: "Variation",
            value: getVariation(collection, tokenId)
        });

        uint256 flag = getFlag(collection, tokenId);
        attributes[2] = Attribute({
            key: "Affinity",
            value: flag > 2 ? "Celestial" : flag == 2 ? "Cosmic" : flag == 1
                ? "Mythical"
                : "Citizen"
        });

        attributes[3] = Attribute({
            key: "Era",
            value: isCutoverToken(collection, tokenId)
                ? "Genesis II"
                : "Genesis I"
        });

        attributes[4] = Attribute({
            key: "Signature",
            value: flag > 2 ? Strings.toString(flag) : "None"
        });

        attributes[5] = Attribute({
            key: "Group",
            value: string.concat(
                "Group ",
                Strings.toString(getEditionIndex(collection, tokenId))
            )
        });

        attributes[6] = Attribute({
            key: "Sigil",
            value: bytes(sigil).length > 0 ? sigil : "Unaligned"
        });

        attributes[7] = Attribute({
            key: "Quantum Status",
            value: isEntangled(collection, tokenId)
                ? "Entangled"
                : "Independent"
        });

        return attributes;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../IEngine.sol";

// simple starting point for engines
// - default name
// - proper erc165 support
// - no royalties
// - nop on beforeTokenTransfer and afterEngineSet hooks
abstract contract ShellBaseEngine is IEngine {

    // nop
    function beforeTokenTransfer(
        address,
        address,
        address,
        uint256,
        uint256
    ) external pure virtual override {
        return;
    }

    // nop
    function afterEngineSet(uint256) external view virtual override {
        return;
    }

    // no royalties
    function getRoyaltyInfo(
        IShellFramework,
        uint256,
        uint256
    ) external view virtual returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "../IShellFramework.sol";
import "../IEngine.sol";

struct Attribute {
    string key;
    string value;
}

abstract contract OnChainMetadataEngine is IEngine {
    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name = _computeName(collection, tokenId);
        string memory description = _computeDescription(collection, tokenId);
        string memory image = _computeImageUri(collection, tokenId);
        string memory externalUrl = _computeExternalUrl(collection, tokenId);
        Attribute[] memory attributes = _computeAttributes(collection, tokenId);

        string memory attributesInnerJson = "";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributesInnerJson = string(
                bytes(
                    abi.encodePacked(
                        attributesInnerJson,
                        i > 0 ? ", " : "",
                        '{"trait_type": "',
                        attributes[i].key,
                        '", "value": "',
                        attributes[i].value,
                        '"}'
                    )
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                image,
                                '", "external_url": "',
                                externalUrl,
                                '", "attributes": [',
                                attributesInnerJson,
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    // compute the metadata name for a given token
    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    function _computeAttributes(IShellFramework collection, uint256 token)
        internal
        view
        virtual
        returns (Attribute[] memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = 0x0b1d171c
interface IEngine is IERC165 {
    // Get the name for this engine
    function name() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // collection = msg.sender
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    // Called by the framework whenever an engine is set on a fork, including
    // the collection (fork id = 0). Can be used by engine developers to prevent
    // an engine from being installed in a collection or non-canonical fork if
    // desired
    // collection = msg.sender
    function afterEngineSet(uint256 forkId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./libraries/IOwnable.sol";
import "./IEngine.sol";

// storage flag
enum StorageLocation {
    INVALID,
    // set by the engine at any time, mutable
    ENGINE,
    // set by the engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

// string key / value
struct StringStorage {
    string key;
    string value;
}

// int key / value
struct IntStorage {
    string key;
    uint256 value;
}

// data provided when minting a new token
struct MintEntry {
    address to;
    uint256 amount;
    MintOptions options;
}

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Information about a fork
struct Fork {
    IEngine engine;
    address owner;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = TBD
interface IShellFramework is IERC165, IERC2981 {
    // ---
    // Framework errors
    // ---

    // an engine was provided that did no pass the expected erc165 checks
    error InvalidEngine();

    // a write was attempted that is not allowed
    error WriteNotAllowed();

    // an operation was attempted but msg.sender was not the expected engine
    error SenderNotEngine();

    // an operation was attempted but msg.sender was not the fork owner
    error SenderNotForkOwner();

    // a token fork was attempted by an invalid msg.sender
    error SenderCannotFork();

    // ---
    // Framework events
    // ---

    // a fork was created
    event ForkCreated(uint256 forkId, IEngine engine, address owner);

    // a fork had a new engine installed
    event ForkEngineUpdated(uint256 forkId, IEngine engine);

    // a fork had a new owner set
    event ForkOwnerUpdated(uint256 forkId, address owner);

    // a token has been set to a new fork
    event TokenForkUpdated(uint256 tokenId, uint256 forkId);

    // ---
    // Storage events
    // ---

    // A fork string was stored
    event ForkStringUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        string value
    );

    // A fork int was stored
    event ForkIntUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        uint256 value
    );

    // A token string was stored
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A token int was stored
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Collection base
    // ---

    // called immediately after cloning
    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external;

    // ---
    // General collection info / metadata
    // ---

    // collection owner (fork 0 owner)
    function owner() external view returns (address);

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // next fork id serial number
    function nextForkId() external view returns (uint256);

    // ---
    // Fork functionality
    // ---

    // Create a new fork with a specific engine, fork all the tokenIds to the
    // new engine, and return the fork ID
    function createFork(
        IEngine engine,
        address owner,
        uint256[] calldata tokenIds
    ) external returns (uint256);

    // Set the engine for a specific fork. Must be fork owner
    function setForkEngine(uint256 forkId, IEngine engine) external;

    // Set the fork owner. Must be fork owner
    function setForkOwner(uint256 forkId, address owner) external;

    // Set the fork of a specific token. Must be token owner
    function setTokenFork(uint256 tokenId, uint256 forkId) external;

    // Set the fork for several tokens. Must own all tokens
    function setTokenForks(uint256[] memory tokenIds, uint256 forkId) external;

    // ---
    // Fork views
    // ---

    // Get information about a fork
    function getFork(uint256 forkId) external view returns (Fork memory);

    // Get a fork's engine
    function getForkEngine(uint256 forkId) external view returns (IEngine);

    // Get a fork's owner
    function getForkOwner(uint256 forkId) external view returns (address);

    // Get a token's fork ID
    function getTokenForkId(uint256 tokenId) external view returns (uint256);

    // Get a token's engine. getFork(getTokenForkId(tokenId)).engine
    function getTokenEngine(uint256 tokenId) external view returns (IEngine);

    // Determine if a given msg.sender can fork a token
    function canSenderForkToken(address sender, uint256 tokenId)
        external
        view
        returns (bool);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by collection engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage. Only callable by collection engine
    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage. Only callable by collection engine
    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// (semi) standard ownable interface
interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://github.com/Brechtpd/base64/blob/main/base64.sol

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}