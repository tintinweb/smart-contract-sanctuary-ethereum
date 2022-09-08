// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////


import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721} from "./ERC721.sol";
import {IERC721PNFT} from "../interfaces/IERC721PNFT.sol";
import {IERC721PNFTRegistrar} from "../interfaces/IERC721PNFTRegistrar.sol";

/// @title Dopamine ERC-721 PNFT (Physical-bound NFT)
/// @notice This is a ERC-721 implementation that does not support transfers,
///  and instead functions as a proxy that forwards NFT queries to a registrar.
contract ERC721PNFT is ERC721, IERC721PNFT {

    IERC721PNFTRegistrar registrar;

    string public baseURI;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x0e89341c;

    modifier onlyRegistrar() {
        if (msg.sender != address(registrar)) {
            revert RegistrarOnly();
        }
        _;
    }

    /// @notice Instantiates a new ERC-721 PNFT contract.
    constructor(address registrar_, string memory baseURI_)
        ERC721("Test", "TestR", 99) {
        registrar = IERC721PNFTRegistrar(registrar_);
        baseURI = baseURI_;
    }

    function tokenURI(uint256 id) external view override(ERC721) returns (string memory) {
        if (_ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }
        return string(abi.encodePacked(baseURI, _toString(id)));
    }

    function bind(
        address from,
        address to,
        uint256 id,
        address,
        uint256 registrarId
    ) public {
        if (from != _ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        address binder = address(uint160(registrarId));

        delete getApproved[id];

        unchecked {
            _balanceOf[from]--;
            _balanceOf[binder]++; // NFT balance of the chip
        }

        _ownerOf[id] = binder;

        if (
            registrar.onERC721Bind(id, registrarId)
            !=
            IERC721PNFTRegistrar.onERC721Bind.selector
        ) {
            revert BindInvalid();
        } 

        emit Bind(id, address(registrar), registrarId);
        if (from != to) {
            emit Transfer(from, to, id);
        }
    }

    function unbind(
        address from,
        address to,
        uint256 id,
        address,
        uint256 registrarId
    ) public {

        address binder = address(uint160(registrarId));
        address owner = registrar.ownerOf(uint256(uint160(binder)));

        if (from != owner) {
            revert OwnerInvalid();
        }

        if (msg.sender != from) {
            revert SenderUnauthorized();
        }

        unchecked {
            _balanceOf[binder]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        if (
            registrar.onERC721Unbind(id, registrarId)
            !=
            IERC721PNFTRegistrar.onERC721Unbind.selector
        ) {
            revert UnbindInvalid();
        }

        emit Unbind(id);
        if (from != to) {
            emit Transfer(from, to, id);
        }
    }

    function mint(
        uint256 id,
        uint256 registrarId
    ) public onlyRegistrar returns (uint256) {

        address to = address(registrar);

        if (_ownerOf[id] != address(0)) {
            revert TokenAlreadyMinted();
        }

        address binder = address(uint160(registrarId));

        unchecked {
            totalSupply++;
            _balanceOf[binder]++;
        }

        if (totalSupply > maxSupply) {
            revert SupplyMaxCapacity();
        }

        _ownerOf[id] = binder;

        if (
            registrar.onERC721Bind(id, registrarId)
            !=
            IERC721PNFTRegistrar.onERC721Bind.selector
        ) {
            revert BindInvalid();
        } 

        emit Transfer(address(0), to, id);
        emit Bind(id, to, registrarId);

        return id;
    }

    /// @inheritdoc ERC721
    function ownerOf(uint256 id) public view override(ERC721, IERC721) returns (address) {
        return registrar.ownerOf(uint256(uint160(_ownerOf[id])));
    }

    /// @inheritdoc ERC721
    function balanceOf(address owner) public view override(ERC721, IERC721) returns (uint256) {
        if (registrar.ownerOf(uint256(uint160(owner))) == address(0)) {
            return registrar.balanceOf(address(this), owner);
        } else {
            return _balanceOf[owner];
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// Transfer & minting methods derive from ERC721.sol of Rari Capital's solmate.

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IERC721Errors} from "../interfaces/IERC721Errors.sol";
import {IERC2981} from "../interfaces/IERC2981.sol";

/// @title Dopamine Minimal ERC-721 Contract
/// @notice This is a minimal ERC-721 implementation that supports the metadata
///  extension, tracks total supply, and includes a capped maximum supply.
/// @dev This ERC-721 implementation is optimized for mints and transfers of
///  individual tokens (as opposed to bulk). It also includes EIP-712 methods &
///  data structures to allow for signing processes to be built on top of it.
contract ERC721 is IERC721, IERC721Errors, IERC721Metadata, IERC2981 {

    /// @notice The maximum number of NFTs that can ever exist.
    /// @dev For tabs this is also capped by the emissions plan (e.g. 1 / day).
    uint256 public immutable maxSupply;

    /// @notice The name of the NFT collection.
    string public name;

    /// @notice The abbreviated name of the NFT collection.
    string public symbol;

    /// @notice The total number of NFTs in circulation.
    uint256 public totalSupply;

    /// @notice Gets the approved address for an NFT.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(uint256 => address) public getApproved;

    /// @notice Gets the number of NFTs owned by an address.
    mapping(address => uint256) internal _balanceOf;

    /// @dev Tracks the assigned owner of an address.
    mapping(uint256 => address) internal _ownerOf;

    /// @dev Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @dev EIP-2981 collection-wide royalties information.
    RoyaltiesInfo internal _royaltiesInfo;

    /// @dev  EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
    bytes4 private constant _ERC2981_METADATA_INTERFACE_ID = 0x2a55205a;

    /// @notice Instantiates a new ERC-721 contract.
    /// @param name_ The name of the NFT collecton.
    /// @param symbol_ The abbreviated name of the NFT collection.
    /// @param maxSupply_ The maximum supply for the NFT collection.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) {
        name = name_;
        symbol = symbol_;
        maxSupply = maxSupply_;
    }

    /// @notice Gets the assigned owner for token `id`.
    /// @param id The id of the NFT being queried.
    /// @return The address of the owner of the NFT of id `id`.
    function ownerOf(uint256 id) external view virtual returns (address) {
        return _ownerOf[id];
    }

    /// @notice Gets number of NFTs owned by address `owner`.
    /// @param owner The address whose balance is being queried.
    /// @return The number of NFTs owned by address `owner`.
    function balanceOf(address owner) external view virtual returns (uint256) {
        return _balanceOf[owner];
    }

    /// @notice Sets approved address of NFT of id `id` to address `approved`.
    /// @param approved The new approved address for the NFT.
    /// @param id The id of the NFT to approve.
    function approve(address approved, uint256 id) external virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert SenderUnauthorized();
        }

        getApproved[id] = approved;
        emit Approval(owner, approved, id);
    }

    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @param owner The address of the owner.
    /// @param operator The address of the owner's operator.
    /// @return True if `operator` is approved operator of `owner`, else False.
    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address that will manage the sender's NFTs.
    /// @param approved Whether operator is allowed to operate sender's NFTs.
    function setApprovalForAll(address operator, bool approved) external virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns the metadata URI associated with the NFT of id `id`.
    /// @return A string URI pointing to metadata of the queried NFT.
    function tokenURI(uint256) external view virtual returns (string memory) {
        return "";
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id) external pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC721_INTERFACE_ID ||
            id == _ERC721_METADATA_INTERFACE_ID ||
            id == _ERC2981_METADATA_INTERFACE_ID;
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view virtual returns (address, uint256) {
        RoyaltiesInfo memory royaltiesInfo = _royaltiesInfo;
        uint256 royalties = (salePrice * royaltiesInfo.royalties) / 10000;
        return (royaltiesInfo.receiver, royalties);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals, but `Approval` events are omitted.
    /// @param from The existing owner address of the NFT being transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param id The id of the NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        _beforeTokenTransfer(from, to, id);

        delete getApproved[id];

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    /// @dev Mints NFT of id `id` to address `to`. To save gas, it is assumed
    ///  that `maxSupply` < `type(uint256).max` (ex. for tabs, cap is very low).
    /// @param to Address receiving the minted NFT.
    /// @param id Identifier of the NFT being minted.
    /// @return The id of the minted NFT.
    function _mint(address to, uint256 id) internal virtual returns (uint256) {
        if (to == address(0)) {
            revert ReceiverInvalid();
        }
        if (_ownerOf[id] != address(0)) {
            revert TokenAlreadyMinted();
        }

        _beforeTokenTransfer(address(0), to, id);

        unchecked {
            totalSupply++;
            _balanceOf[to]++;
        }

        if (totalSupply > maxSupply) {
            revert SupplyMaxCapacity();
        }

        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
        return id;
    }

    /// @dev Burns NFT of id `id`, removing it from existence.
    /// @param id Identifier of the NFT being burned
    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) {
            revert TokenNonExistent();
        }

        _beforeTokenTransfer(owner, address(0), id);

        unchecked {
            totalSupply--;
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];
        emit Transfer(owner, address(0), id);
    }

    /// @notice Pre-transfer hook for embedding additional transfer behavior.
    /// @param from The address of the existing owner of the NFT.
    /// @param to The address of the new owner of the NFT.
    /// @param id The id of the NFT being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 id)
        internal
        virtual
        {}

    /// @dev Sets the royalty information for all NFTs in the collection.
    /// @param receiver Address which will receive token royalties.
    /// @param royalties Royalties amount, in bips.
    function _setRoyalties(address receiver, uint96 royalties) internal {
        if (royalties > 10000) {
            revert RoyaltiesTooHigh();
        }
        if (receiver == address(0)) {
            revert ReceiverInvalid();
        }
        _royaltiesInfo = RoyaltiesInfo(receiver, royalties);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721PNFTEventsAndErrors} from "./IERC721PNFTEventsAndErrors.sol";

/// @title IERC721 Physical-bound NFT Interface
interface IERC721PNFT is IERC721, IERC721PNFTEventsAndErrors {

    function mint(
        uint256 id,
        uint256 registrarId
    ) external returns (uint256);

    function bind(
        address from,
        address to,
        uint256 id,
        address registrar,
        uint256 registrarId
    ) external;

    function unbind(
        address from,
        address to,
        uint256 id,
        address registrar,
        uint256 registrarId
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-721 PNFT Registrar Interface
interface IERC721PNFTRegistrar {

    /// @notice Gets the number of PNFT tokens `pnft` owned by address `owner`.
    /// @param pnft The address of the PNFT contract.
    /// @param owner The token owner's address.
    /// @return The number of tokens address `owner` owns for the PNFT `pnft`.
    function balanceOf(
        address pnft,
        address owner
    ) external view returns (uint256);

    function onERC721Bind(
        uint256 id,
        uint256 registrarId
    ) external returns (bytes4);

    function onERC721Unbind(
        uint256 id,
        uint256 registrarId
    ) external returns (bytes4);

    /// @notice Gets the owning address of the chip with id `id`.
    /// @param id The id of the chip being queried.
    /// @return The address of the owner for chip id `id`.
    function ownerOf(uint256 id) external view returns (address);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Errors Interface
interface IERC721Errors {

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice NFT supply has hit maximum capacity.
    error SupplyMaxCapacity();

    /// @notice Token has already minted.
    error TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error TokenNonExistent();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC2981Errors} from "./IERC2981Errors.sol";

/// @title Interface for the ERC-2981 royalties standard.
interface IERC2981 is IERC2981Errors {

    /// @notice RoyaltiesInfo stores token royalties information.
    struct RoyaltiesInfo {

        /// @notice The address to which royalties will be directed.
        address receiver;

        /// @notice The royalties amount, in bips.
        uint96 royalties;

    }

    /// @notice Returns the address to which royalties are received along with
    ///  the royalties amount to be paid to them for a given sale price.
    /// @param id The id of the NFT being queried for royalties information.
    /// @param salePrice The sale price of the NFT, in some unit of exchange.
    /// @return receiver The address of the royalties receiver.
    /// @return royaltyAmount The royalty payment to be made given `salePrice`.
    function royaltyInfo(
        uint256 id,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC721 Physical-bound NFT Events & Errors Interface
interface IERC721PNFTEventsAndErrors {

    event Bind(uint256 id, address registrar, uint256 registrarId);

    event Unbind(uint256 id);

    error BindInvalid();

    error RegistrarOnly();

    error UnbindInvalid();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-2981 Errors Interface
interface IERC2981Errors {

    /// @notice Royalties are set too high.
    error RoyaltiesTooHigh();

}