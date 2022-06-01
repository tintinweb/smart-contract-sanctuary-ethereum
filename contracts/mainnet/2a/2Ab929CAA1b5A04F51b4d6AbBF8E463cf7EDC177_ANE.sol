/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: ANE.sol




// SPDX-License-Identifier: UNLICENSED




pragma solidity ^0.8.4;

/// @title Antonomous NFT Escrow Smart Contract
/// @author Adrien Jemba Koum
contract ANE is ERC721Holder, ERC1155Holder {

    // Created escrow number
    uint256 public counter;

    // Escrow ID <-> Escrow mapping
    mapping(bytes32 => AnscaEscrow) anscaEscrowList;
    // Wallet <-> Escrow ID mapping
    mapping(address => bytes32[]) ownerEscrowMapping;

    // Protocol Fee
    uint256 public FEE = 75;
    // If the contract is paused
    bool public paused;

    address owner;
    // Address receiving escrow fees
    address feeCollectorAddress;

    // NFT types enum
    enum NftType{NULL, ERC721, ERC1155}

    // List of escrow actions
    enum Action{ CREATE, BUY, CANCEL }

    // Escrow model
    struct AnscaEscrow {
        bytes32 id;
        uint256[] nftIds;
        uint256[] nftQuantities;
        uint256 price;     
        uint256 creationTimestamp;
        address seller;
        address buyer;
        address[] nftContractAddresses;
        NftType[] nftTypes;
        bool open;
        bool zero;
    }

    event ANEEvent(address indexed _from, bytes32 indexed _id, uint8 _action);

    constructor(address _feeCollectorAddress) {
        owner = msg.sender;
        feeCollectorAddress = _feeCollectorAddress;
    }

    /// @notice True if the escrow ended with a buy
    /// @param _id Id of the escrow
    function escrowWentWell(bytes32 _id) external view returns(bool) {
        return anscaEscrowList[_id].buyer != address(0);
    }

    /// @notice True if the provided address is involved in the escrow
    /// @param _id Id of the escrow
    /// @param _address the address to check
    function addressIsInvolved(bytes32 _id, address _address) external view returns(bool) {
        return anscaEscrowList[_id].buyer == _address || anscaEscrowList[_id].seller == _address;
    }

    /// @notice returns all the escrow ID for the calling wallet
    function getAllEscrowsForSender() external view returns(bytes32[] memory){
        return ownerEscrowMapping[msg.sender];
    }
    function getNftIdsByNftEscrowId(bytes32 _id) external view returns(uint256[] memory){
        return anscaEscrowList[_id].nftIds;
    }
    function getAddressesByNftEscrowId(bytes32 _id) external view returns(address[] memory){
        return anscaEscrowList[_id].nftContractAddresses;
    }
    function getNftQuantitiesByNftEscrowId(bytes32 _id) external view returns(uint256[] memory){
        return anscaEscrowList[_id].nftQuantities;
    }
    function getNftTypesByNftEscrowId(bytes32 _id) external view returns(ANE.NftType[] memory){
        return anscaEscrowList[_id].nftTypes;
    }

    /// @notice Get the escrow information by ID
    /// @param _id Id of the escrow
    function getEscrowById(bytes32 _id) external view returns(string memory) {
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];

        return string(abi.encodePacked(
            localAnscaEscrow.id,
            ";",
            Strings.toString(localAnscaEscrow.price),
            ";",
            localAnscaEscrow.open ? "TRUE" : "FALSE",
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.seller)))),
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.buyer)))),
            ";",
            Strings.toString(localAnscaEscrow.creationTimestamp)));
    }

    /// @notice Creates a new nft escrow. Called by the seller
    /// @param _id Id of the escrow
    //
    // The following properties are arrays which contains NFT(s) information organized by index : array[0] for the first NFT, array[1] for the second NFT and so on
    /// @param _nftIds List of NFTs Ids
    /// @param _nftContractAddresses List of NFTs contract address
    /// @param _nftQuantities List of NFTs quantity. In case of an ERC1155 NFT, the quantity may be greater than 1
    //
    /// @param _price The price to buy all the nfts
    function createEscrow(bytes32 _id, uint256[] calldata _nftIds, address[] calldata _nftContractAddresses, uint256[] calldata _nftQuantities, uint256 _price) external {
        //Checks
        require(!paused, "18");
        require(anscaEscrowList[_id].id != _id || (anscaEscrowList[_id].id == _id && anscaEscrowList[_id].zero),"10");
        require(_nftIds.length > 0 && _nftIds.length < 101, "11");
        require(_nftIds.length == _nftContractAddresses.length && _nftIds.length == _nftQuantities.length, "12");
        require(_price > 0,"13");

        //States        
        uint256  arrayLength = _nftIds.length;
        AnscaEscrow memory localAnscaEscrow = AnscaEscrow({
            id: _id,
            nftIds: _nftIds,
            nftQuantities: _nftQuantities,
            price: _price,
            seller: msg.sender,
            buyer: address(0),
            nftContractAddresses: _nftContractAddresses,
            nftTypes: new NftType[](arrayLength),
            open: true,
            zero: false,
            creationTimestamp: block.timestamp
        });
        counter++;

        ownerEscrowMapping[msg.sender].push(_id);
        anscaEscrowList[_id] = localAnscaEscrow;

        //Actions
        for (uint i=0; i<arrayLength; i++) {
            if(IERC165(address(_nftContractAddresses[i])).supportsInterface(0x80ac58cd)) { //ERC721
                anscaEscrowList[_id].nftTypes[i] = NftType.ERC721;
                IERC721 erc721Nft = IERC721(address(_nftContractAddresses[i]));
                require(erc721Nft.ownerOf(_nftIds[i]) == msg.sender, "14");
                erc721Nft.safeTransferFrom(msg.sender, address(this), _nftIds[i]);
            } else if (IERC165(address(_nftContractAddresses[i])).supportsInterface(0xd9b67a26)) { //ERC1155
                anscaEscrowList[_id].nftTypes[i] = NftType.ERC1155;
                IERC1155 erc1155Nft = IERC1155(address(_nftContractAddresses[i]));
                require(_nftQuantities[i] > 0, "15");
                require(erc1155Nft.balanceOf( msg.sender, _nftIds[i]) >= _nftQuantities[i], "16");
                erc1155Nft.safeTransferFrom(msg.sender, address(this), _nftIds[i], _nftQuantities[i] < 1 ? 1 : _nftQuantities[i], "");  
            } else {
                revert('17');
            }
        }
        emit ANEEvent(msg.sender, _id, uint8(Action.CREATE));    
    }

    /// @notice Allow the seller to cancel the escrow. This gives back all the NFTs to the seller
    /// @param _id The escrow ID
    function cancelEscrow(bytes32 _id) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(msg.sender == localAnscaEscrow.seller, "20");

        //States
        localAnscaEscrow.zero = true;
        localAnscaEscrow.open = false;
        anscaEscrowList[_id] = localAnscaEscrow;

        //Actions
        uint256  arrayLength = anscaEscrowList[_id].nftIds.length;
        for (uint i=0; i<arrayLength; i++) {
            if(anscaEscrowList[_id].nftTypes[i] == NftType.ERC721) {
                IERC721 erc721Nft = IERC721(address(anscaEscrowList[_id].nftContractAddresses[i]));
                erc721Nft.safeTransferFrom(address(this), msg.sender, anscaEscrowList[_id].nftIds[i]);
            } else if (anscaEscrowList[_id].nftTypes[i] == NftType.ERC1155) {
                IERC1155 erc1155Nft = IERC1155(address(anscaEscrowList[_id].nftContractAddresses[i]));
                erc1155Nft.safeTransferFrom(address(this), msg.sender, anscaEscrowList[_id].nftIds[i], anscaEscrowList[_id].nftQuantities[i] < 1 ? 1 : anscaEscrowList[_id].nftQuantities[i], "");            
            }
        }
        emit ANEEvent(msg.sender, _id, uint8(Action.CANCEL));  
    }

    /// @notice Allow any buyer to buy all the NFTs held by this escrow.
    /// @param _id The escrow ID
    function buyNft(bytes32 _id) external payable {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(localAnscaEscrow.open, "30");
        require(msg.value >= localAnscaEscrow.price, "31");

        //States
        localAnscaEscrow.zero = true;
        localAnscaEscrow.open = false;
        localAnscaEscrow.buyer = msg.sender;
        ownerEscrowMapping[msg.sender].push(_id);
        anscaEscrowList[_id] = localAnscaEscrow;

        //Actions
        uint256  arrayLength = anscaEscrowList[_id].nftIds.length;
        for (uint i=0; i<arrayLength; i++) {
            if(anscaEscrowList[_id].nftTypes[i] == NftType.ERC721) {
                IERC721 erc721Nft = IERC721(address(anscaEscrowList[_id].nftContractAddresses[i]));
                erc721Nft.safeTransferFrom(address(this), msg.sender, anscaEscrowList[_id].nftIds[i]);
            } else if (anscaEscrowList[_id].nftTypes[i] == NftType.ERC1155) {
                IERC1155 erc1155Nft = IERC1155(address(anscaEscrowList[_id].nftContractAddresses[i]));
                erc1155Nft.safeTransferFrom(address(this), msg.sender, anscaEscrowList[_id].nftIds[i], anscaEscrowList[_id].nftQuantities[i] < 1 ? 1 : anscaEscrowList[_id].nftQuantities[i], "");            
            }
        }
        uint256 fee = (localAnscaEscrow.price * FEE) / 10000;
        payable(localAnscaEscrow.seller).transfer(localAnscaEscrow.price - fee);
        payable(feeCollectorAddress).transfer(fee);

        emit ANEEvent(msg.sender, _id, uint8(Action.BUY));        
    }

    // ##############################################################
    // #####                                                    #####
    // #################### Privileged actions ######################
    // #####                                                    #####
    // ##############################################################

    function changeFeeCollectorAddress(address _adr) external {
        require(msg.sender == owner);
        feeCollectorAddress = _adr;
    }

    function changeFee(uint256 _fee) external {
        require(msg.sender == owner);
        require(_fee <= 100); // 100 = 1%
        FEE = _fee;
    }

    function pause(bool _pause) external {
        require(msg.sender == owner);
        paused = _pause;
    }
}