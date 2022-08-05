pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {ERC1155NT} from "../erc1155/ERC1155NT.sol";
import {IDopaminePartyNFT} from "../interfaces/IDopaminePartyNFT.sol";

/// @title Dopamine Party NFTs
/// @notice Dopamine Party NFTs are non-transferable ERC-1155s given to
///  attendees of Dopamine's various IRL or virtual events & parties. This
///  ERC-1155 implementation additionally supports per NFT type supply tracking
///  and minting through airdrops or merkle allowlist claims. Each NFT type
///  uniquely identifies a specific party, thus attendees may own 1 max of each.
contract DopaminePartyNFT is ERC1155NT, IDopaminePartyNFT {

    string public name = "Dopamine Party NFTs";

    string public symbol = "PARTY";

    /// @notice The address administering NFT distributions and metadata.
    address public owner;

    /// @notice The URI each NFT initially points to for metadata resolution.
    /// @dev Before URI finalization, `uri()` resolves to "{baseURI}/{id}".
    string public baseURI;

    /// @notice Maps the id of an NFT type to its finalized metadata URI.
    /// @dev After URI finalization, `uri()` resolves to "{tokenURI[id]}".
    mapping(uint256 => string) public tokenURI;

    /// @notice Gets for a specific NFT type its total supply.
    mapping(uint256 => uint256) public totalSupply;

    // Merkle roots for each NFT type (null if NFT type is not claimable).
    mapping(uint256 => bytes32) private _allowlist;

    // Counter for tracking the current NFT type id.
    uint256 private _id;

    /// @dev Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Initializes contract with given base URI and sender as owner.
    /// @param baseURI_ The base URI address involved in fetching NFT metadata.
    constructor(string memory baseURI_) {
        baseURI = baseURI_;
        emit BaseURISet(baseURI);

        owner = msg.sender;
        emit OwnerChanged(address(0), owner);
    }

    /// @inheritdoc IDopaminePartyNFT
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @inheritdoc IDopaminePartyNFT
    function setOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    /// @inheritdoc IDopaminePartyNFT
    function setTokenURI(uint256 id, string calldata newTokenURI)
        external
        onlyOwner
    {
        if (id >= _id) {
            revert TokenNonExistent();
        }
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }
        tokenURI[id] = newTokenURI;
        emit TokenURISet(id, newTokenURI);
    }

    /// @notice Returns the metadata URI for NFT type with id `id`.
    /// @param id The id of the type of NFT being queried.
    function uri(uint256 id) external view returns (string memory) {
        if (totalSupply[id] == 0) {
            revert TokenNonExistent();
        }

        if (bytes(tokenURI[id]).length == 0) {
            return string(abi.encodePacked(baseURI, _toString(id)));
        } else {
            return tokenURI[id];
        }
    }

    /// @inheritdoc IDopaminePartyNFT
    function allowlist(uint256 id, bytes32 allowlistRoot) external onlyOwner {
        if (id > _id) {
            revert TokenNonExistent();
        }

        // Retroactive claim changes are disallowed once metadata is immutable.
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }

        _allowlist[id] = allowlistRoot;
        if (id == _id) {
            _id += 1;
            emit PartyNFTCreated(id, allowlistRoot);
        } else {
            emit PartyNFTUpdated(id, allowlistRoot);
        }
    }

    /// @inheritdoc IDopaminePartyNFT
    function airdrop(uint256 id, address[] calldata addresses)
        external
        onlyOwner
    {
        if (id > _id) {
            revert TokenNonExistent();
        }

        // Retroactive airdrops are disallowed once metadata is immutable.
        if (bytes(tokenURI[id]).length != 0) {
            revert TokenImmutable();
        }

        if (id == _id) {
            _id += 1;
            emit PartyNFTCreated(id, "");
        } else {
            emit PartyNFTUpdated(id, "");
        }

        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; i++) {
            _mint(addresses[i], id);
        }
        totalSupply[id] += numAddresses;
    }

    // @inheritdoc IDopaminePartyNFT
    function claim(bytes32[] calldata proof, uint256 id) external {
        bytes32 tokenAllowlist = _allowlist[id];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!_verify(tokenAllowlist, proof, leaf)) {
            revert ProofInvalid();
        }

        _mint(msg.sender, id);
        totalSupply[id]++;
    }

    /// @dev Checks whether `leaf` is part of merkle tree rooted at `merkleRoot`
    ///  using proof `proof`. Merkle tree generation and proof construction is
    ///  done using the following JS library: github.com/miguelmota/merkletreejs
    /// @param merkleRoot The hexlified merkle root as a bytes32 data type.
    /// @param proof The abi-encoded proof formatted as a bytes32 array.
    /// @param leaf The leaf node being checked (uses keccak-256 hashing).
    /// @return True if `leaf` is in `merkleRoot`-rooted tree, False otherwise.
    function _verify(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (hash <= proofElement) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }
        }
        return hash == merkleRoot;
    }

    /// @dev Converts a uint256 into a string.
    function _toString(uint256 value) private pure returns (string memory) {
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {IERC1155NTErrors} from "../interfaces/IERC1155NTErrors.sol";

/// @title Dopamine non-transferable ERC-1155 contract
/// @notice This is a minimal ERC-1155 implementation that does not support
///  transfers outside of minting, throwing in all such cases.
contract ERC1155NT is IERC1155, IERC1155NTErrors {

    /// @notice Gets for an address the number of NFTs owned of a specific type.
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC1155_METADATA_INTERFACE_ID = 0x0e89341c;

    /// @notice Transfers an NFT from a source to a destination address.
    ///  WARNING: This will always throw as transfers are unsupported.
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Transfers multiple NFTs from a source to a destination address.
    ///  WARNING: This will always throw as transfers are unsupported.
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Retrieves balances of multiple account / NFT type pairs.
    /// @param owners List of NFT owner addresses.
    /// @param ids List of ids of NFT types.
    /// @return balances List of balances corresponding to the owner / id pairs.
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](owners.length);
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// @notice Checks if an operator is an authorized operator for an owner.
    ///  WARNING: This will always return false as operators are unsupported.
    function isApprovedForAll(address, address)
        external
        view
        virtual
        returns (bool)
    {
        return false;
    }

    /// @notice Sets the operator for the sender address.
    ///  WARNING: This will always throw as operators are unsupported.
    function setApprovalForAll(address, bool) public virtual {
        revert TokenNonTransferable();
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, False otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC1155_INTERFACE_ID ||
            id == _ERC1155_METADATA_INTERFACE_ID;
    }

    /// @notice Mints NFT of type `id` to address `to`.
    /// @param to Address receiving the minted NFT.
    /// @param id The id of the NFT type being minted.
    function _mint(address to, uint256 id) internal virtual {
        if (balanceOf[to][id] == 1) {
            revert TokenAlreadyMinted();
        }
        balanceOf[to][id] = 1;
        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                1,
                ""
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IDopaminePartyNFTEventsAndErrors} from "../interfaces/IDopaminePartyNFTEventsAndErrors.sol";

/// @title Dopamine Party NFT Interface
interface IDopaminePartyNFT is IDopaminePartyNFTEventsAndErrors {

    /// @notice returns the URI of the specified token
    /// @param id The queried token id.
    function uri(uint256 id) external returns (string memory);

    /// @notice Sets the base URI to `newBaseURI`.
    /// @param newBaseURI The new base metadata URI to set for the collection.
    /// @dev This function is only callable by the owner address.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Sets the final metadata URI for NFT type `id` to `uri`.
    /// @dev This function is only callable by the owner address, and reverts
    ///  if the specified NFT of type `id` does not exist.
    /// @param id The id of the NFT whose final metadata URI is being set.
    /// @param newTokenURI The finalized IPFS / Arweave metadata URI.
    function setTokenURI(uint256 id, string calldata newTokenURI) external;

    /// @notice Sets the owner address to `newOwner`.
    /// @param newOwner The address of the new owner.
    /// @dev This function is only callable by the owner address.
    function setOwner(address newOwner) external;

    /// @notice Creates for NFT type `id` an allowlist for claiming.
    /// @dev This function is only callable by the contract owner.
    /// @param id The id of the NFT being made claimable.
    /// @param allowlistRoot The merkle root of the allowlist for this NFT type.
    function allowlist(uint256 id, bytes32 allowlistRoot) external;

    /// @notice Mints NFTs of type `id` to all specified addresses `addresses`.
    /// @dev This function is only callable by the contract owner.
    /// @param id The id of the NFT type being minted.
    /// @param addresses The list of addresses receiving the minted NFT.
    function airdrop(uint256 id, address[] calldata addresses) external;

    /// @notice Mints allowlisted NFT of type `id` to the sender address if
    ///  merkle proof `proof` proves they were allowlisted for that NFT type.
    /// @dev Reverts if invalid proof is provided or claimer isn't allowlisted.
    /// The allowlist is formed using sender addresses as leaves.
    /// @param proof The Merkle proof of the claim as a bytes32 array.
    /// @param id The id of the Dopamine party NFT being claimed.
    function claim(
        bytes32[] calldata proof,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC1155NT Errors Interface
interface IERC1155NTErrors {

    /// @notice Mismatch between input arrays.
    error ArityMismatch();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Token has already been minted.
    error TokenAlreadyMinted();

    /// @notice Token may not be transferred.
    error TokenNonTransferable();

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Party NFT Events & Errors Interface
interface IDopaminePartyNFTEventsAndErrors {

    /// @notice Emits when the Dopamine tab base URI is set to `baseURI`.
    /// @param baseURI The base URI of the Dopamine tab contract, as a string.
    event BaseURISet(string baseURI);

    /// @notice Emits when NFT type of id `id` has its URI set to `tokenURI`.
    /// @param id  The id of the type of NFT whose URI was set.
    /// @param tokenURI The metadata URI of the token, as a string.
    event TokenURISet(uint256 id, string tokenURI);

    /// @notice Emits when owner is changed from `oldOwner` to `newOwner`.
    /// @param oldOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emits when a new party NFT type is created.
    /// @param id The id of the new party NFT type.
    /// @param allowlistRoot The merkle root, if any, for minting to claimants.
    event PartyNFTCreated(
        uint256 indexed id,
        bytes32 allowlistRoot
    );

    /// @notice Emits when an existing party NFT type is updated.
    /// @param id The id of the party NFT type.
    /// @param allowlistRoot The updated merkle root, if any, of the allowlist.
    event PartyNFTUpdated(
        uint256 indexed id,
        bytes32 allowlistRoot
    );

    /// @notice Claim drop identifier is invalid.
    error ClaimInvalid();

    /// @notice Function callable only by the owner.
    error OwnerOnly();

    /// @notice Proof for claim is invalid.
    error ProofInvalid();

    /// @notice NFT of the specified type does not exist.
    error TokenNonExistent();

    /// @notice NFTs of the specified type may not be minted or modified.
    error TokenImmutable();

}