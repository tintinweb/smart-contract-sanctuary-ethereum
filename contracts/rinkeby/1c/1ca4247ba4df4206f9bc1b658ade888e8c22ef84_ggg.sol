// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fd
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//    /**                                                                                                                                         //
//     *Submitted for verification at Etherscan.io on 2022-06-09                                                                                  //
//    */                                                                                                                                          //
//                                                                                                                                                //
//    // ERC721A Contracts v4.0.0                                                                                                                 //
//    // Creator: Chiru Labs                                                                                                                      //
//                                                                                                                                                //
//    pragma solidity ^0.8.4;                                                                                                                     //
//                                                                                                                                                //
//    /**                                                                                                                                         //
//     * @dev Interface of an ERC721A compliant contract.                                                                                         //
//     */                                                                                                                                         //
//    interface IERC721A {                                                                                                                        //
//        /**                                                                                                                                     //
//         * The caller must own the token or be an approved operator.                                                                            //
//         */                                                                                                                                     //
//        error ApprovalCallerNotOwnerNorApproved();                                                                                              //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The token does not exist.                                                                                                            //
//         */                                                                                                                                     //
//        error ApprovalQueryForNonexistentToken();                                                                                               //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The caller cannot approve to their own address.                                                                                      //
//         */                                                                                                                                     //
//        error ApproveToCaller();                                                                                                                //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The caller cannot approve to the current owner.                                                                                      //
//         */                                                                                                                                     //
//        error ApprovalToCurrentOwner();                                                                                                         //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Cannot query the balance for the zero address.                                                                                       //
//         */                                                                                                                                     //
//        error BalanceQueryForZeroAddress();                                                                                                     //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Cannot mint to the zero address.                                                                                                     //
//         */                                                                                                                                     //
//        error MintToZeroAddress();                                                                                                              //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The quantity of tokens minted must be more than zero.                                                                                //
//         */                                                                                                                                     //
//        error MintZeroQuantity();                                                                                                               //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The token does not exist.                                                                                                            //
//         */                                                                                                                                     //
//        error OwnerQueryForNonexistentToken();                                                                                                  //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The caller must own the token or be an approved operator.                                                                            //
//         */                                                                                                                                     //
//        error TransferCallerNotOwnerNorApproved();                                                                                              //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The token must be owned by `from`.                                                                                                   //
//         */                                                                                                                                     //
//        error TransferFromIncorrectOwner();                                                                                                     //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.                                           //
//         */                                                                                                                                     //
//        error TransferToNonERC721ReceiverImplementer();                                                                                         //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Cannot transfer to the zero address.                                                                                                 //
//         */                                                                                                                                     //
//        error TransferToZeroAddress();                                                                                                          //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * The token does not exist.                                                                                                            //
//         */                                                                                                                                     //
//        error URIQueryForNonexistentToken();                                                                                                    //
//                                                                                                                                                //
//        struct TokenOwnership {                                                                                                                 //
//            // The address of the owner.                                                                                                        //
//            address addr;                                                                                                                       //
//            // Keeps track of the start time of ownership with minimal overhead for tokenomics.                                                 //
//            uint64 startTimestamp;                                                                                                              //
//            // Whether the token has been burned.                                                                                               //
//            bool burned;                                                                                                                        //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the total amount of tokens stored by the contract.                                                                      //
//         *                                                                                                                                      //
//         * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.                                     //
//         */                                                                                                                                     //
//        function totalSupply() external view returns (uint256);                                                                                 //
//                                                                                                                                                //
//        // ==============================                                                                                                       //
//        //            IERC165                                                                                                                   //
//        // ==============================                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns true if this contract implements the interface defined by                                                               //
//         * `interfaceId`. See the corresponding                                                                                                 //
//         * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]                                                    //
//         * to learn more about how these ids are created.                                                                                       //
//         *                                                                                                                                      //
//         * This function call must use less than 30 000 gas.                                                                                    //
//         */                                                                                                                                     //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool);                                                            //
//                                                                                                                                                //
//        // ==============================                                                                                                       //
//        //            IERC721                                                                                                                   //
//        // ==============================                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Emitted when `tokenId` token is transferred from `from` to `to`.                                                                //
//         */                                                                                                                                     //
//        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);                                                      //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.                                                          //
//         */                                                                                                                                     //
//        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);                                               //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.                                   //
//         */                                                                                                                                     //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                                                   //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the number of tokens in ``owner``'s account.                                                                            //
//         */                                                                                                                                     //
//        function balanceOf(address owner) external view returns (uint256 balance);                                                              //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the owner of the `tokenId` token.                                                                                       //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - `tokenId` must exist.                                                                                                              //
//         */                                                                                                                                     //
//        function ownerOf(uint256 tokenId) external view returns (address owner);                                                                //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Safely transfers `tokenId` token from `from` to `to`.                                                                           //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - `from` cannot be the zero address.                                                                                                 //
//         * - `to` cannot be the zero address.                                                                                                   //
//         * - `tokenId` token must exist and be owned by `from`.                                                                                 //
//         * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.                    //
//         * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.    //
//         *                                                                                                                                      //
//         * Emits a {Transfer} event.                                                                                                            //
//         */                                                                                                                                     //
//        function safeTransferFrom(                                                                                                              //
//            address from,                                                                                                                       //
//            address to,                                                                                                                         //
//            uint256 tokenId,                                                                                                                    //
//            bytes calldata data                                                                                                                 //
//        ) external;                                                                                                                             //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients                                   //
//         * are aware of the ERC721 protocol to prevent tokens from being forever locked.                                                        //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - `from` cannot be the zero address.                                                                                                 //
//         * - `to` cannot be the zero address.                                                                                                   //
//         * - `tokenId` token must exist and be owned by `from`.                                                                                 //
//         * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.           //
//         * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.    //
//         *                                                                                                                                      //
//         * Emits a {Transfer} event.                                                                                                            //
//         */                                                                                                                                     //
//        function safeTransferFrom(                                                                                                              //
//            address from,                                                                                                                       //
//            address to,                                                                                                                         //
//            uint256 tokenId                                                                                                                     //
//        ) external;                                                                                                                             //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Transfers `tokenId` token from `from` to `to`.                                                                                  //
//         *                                                                                                                                      //
//         * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.                                              //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - `from` cannot be the zero address.                                                                                                 //
//         * - `to` cannot be the zero address.                                                                                                   //
//         * - `tokenId` token must be owned by `from`.                                                                                           //
//         * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.                    //
//         *                                                                                                                                      //
//         * Emits a {Transfer} event.                                                                                                            //
//         */                                                                                                                                     //
//        function transferFrom(                                                                                                                  //
//            address from,                                                                                                                       //
//            address to,                                                                                                                         //
//            uint256 tokenId                                                                                                                     //
//        ) external;                                                                                                                             //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Gives permission to `to` to transfer `tokenId` token to another account.                                                        //
//         * The approval is cleared when the token is transferred.                                                                               //
//         *                                                                                                                                      //
//         * Only a single account can be approved at a time, so approving the zero address clears previous approvals.                            //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - The caller must own the token or be an approved operator.                                                                          //
//         * - `tokenId` must exist.                                                                                                              //
//         *                                                                                                                                      //
//         * Emits an {Approval} event.                                                                                                           //
//         */                                                                                                                                     //
//        function approve(address to, uint256 tokenId) external;                                                                                 //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Approve or remove `operator` as an operator for the caller.                                                                     //
//         * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.                                           //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - The `operator` cannot be the caller.                                                                                               //
//         *                                                                                                                                      //
//         * Emits an {ApprovalForAll} event.                                                                                                     //
//         */                                                                                                                                     //
//        function setApprovalForAll(address operator, bool _approved) external;                                                                  //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the account approved for `tokenId` token.                                                                               //
//         *                                                                                                                                      //
//         * Requirements:                                                                                                                        //
//         *                                                                                                                                      //
//         * - `tokenId` must exist.                                                                                                              //
//         */                                                                                                                                     //
//        function getApproved(uint256 tokenId) external view returns (address operator);                                                         //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.                                                    //
//         *                                                                                                                                      //
//         * See {setApprovalForAll}                                                                                                              //
//         */                                                                                                                                     //
//        function isApprovedForAll(address owner, address operator) external view returns (bool);                                                //
//                                                                                                                                                //
//        // ==============================                                                                                                       //
//        //        IERC721Metadata                                                                                                               //
//        // ==============================                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the token collection name.                                                                                              //
//         */                                                                                                                                     //
//        function name() external view returns (string memory);                                                                                  //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the token collection symbol.                                                                                            //
//         */                                                                                                                                     //
//        function symbol() external view returns (string memory);                                                                                //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.                                                              //
//         */                                                                                                                                     //
//        function tokenURI(uint256 tokenId) external view returns (string memory);                                                               //
//    }                                                                                                                                           //
//                                                                                                                                                //
//    pragma solidity ^0.8.4;                                                                                                                     //
//                                                                                                                                                //
//    /**                                                                                                                                         //
//     * @dev ERC721 token receiver interface.                                                                                                    //
//     */                                                                                                                                         //
//    interface ERC721A__IERC721Receiver {                                                                                                        //
//        function onERC721Received(                                                                                                              //
//            address operator,                                                                                                                   //
//            address from,                                                                                                                       //
//            uint256 tokenId,                                                                                                                    //
//            bytes calldata data                                                                                                                 //
//        ) external returns (bytes4);                                                                                                            //
//    }                                                                                                                                           //
//                                                                                                                                                //
//    /**                                                                                                                                         //
//     * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including                             //
//     * the Metadata extension. Built to optimize for lower gas during batch mints.                                                              //
//     *                                                                                                                                          //
//     * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).                                  //
//     *                                                                                                                                          //
//     * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.                                                   //
//     *                                                                                                                                          //
//     * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).                                                       //
//     */                                                                                                                                         //
//    contract ERC721A is IERC721A {                                                                                                              //
//        // Mask of an entry in packed address data.                                                                                             //
//        uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;                                                                    //
//                                                                                                                                                //
//        // The bit position of `numberMinted` in packed address data.                                                                           //
//        uint256 private constant BITPOS_NUMBER_MINTED = 64;                                                                                     //
//                                                                                                                                                //
//        // The bit position of `numberBurned` in packed address data.                                                                           //
//        uint256 private constant BITPOS_NUMBER_BURNED = 128;                                                                                    //
//                                                                                                                                                //
//        // The bit position of `aux` in packed address data.                                                                                    //
//        uint256 private constant BITPOS_AUX = 192;                                                                                              //
//                                                                                                                                                //
//        // Mask of all 256 bits in packed address data except the 64 bits for `aux`.                                                            //
//        uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;                                                                       //
//                                                                                                                                                //
//        // The bit position of `startTimestamp` in packed ownership.                                                                            //
//        uint256 private constant BITPOS_START_TIMESTAMP = 160;                                                                                  //
//                                                                                                                                                //
//        // The bit mask of the `burned` bit in packed ownership.                                                                                //
//        uint256 private constant BITMASK_BURNED = 1 << 224;                                                                                     //
//                                                                                                                                                //
//        // The bit position of the `nextInitialized` bit in packed ownership.                                                                   //
//        uint256 private constant BITPOS_NEXT_INITIALIZED = 225;                                                                                 //
//                                                                                                                                                //
//        // The bit mask of the `nextInitialized` bit in packed ownership.                                                                       //
//        uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;                                                                           //
//                                                                                                                                                //
//        // The tokenId of the next token to be minted.                                                                                          //
//        uint256 private _currentIndex;                                                                                                          //
//                                                                                                                                                //
//        // The number of tokens burned.                                                                                                         //
//        uint256 private _burnCounter;                                                                                                           //
//                                                                                                                                                //
//        // Token name                                                                                                                           //
//        string private _name;                                                                                                                   //
//                                                                                                                                                //
//        // Token symbol                                                                                                                         //
//        string private _symbol;                                                                                                                 //
//                                                                                                                                                //
//        // Mapping from token ID to ownership details                                                                                           //
//        // An empty struct value does not necessarily mean the token is unowned.                                                                //
//        // See `_packedOwnershipOf` implementation for details.                                                                                 //
//        //                                                                                                                                      //
//        // Bits Layout:                                                                                                                         //
//        // - [0..159]   `addr`                                                                                                                  //
//        // - [160..223] `startTimestamp`                                                                                                        //
//        // - [224]      `burned`                                                                                                                //
//        // - [225]      `nextInitialized`                                                                                                       //
//        mapping(uint256 => uint256) private _packedOwnerships;                                                                                  //
//                                                                                                                                                //
//        // Mapping owner address to address data.                                                                                               //
//        //                                                                                                                                      //
//        // Bits Layout:                                                                                                                         //
//        // - [0..63]    `balance`                                                                                                               //
//        // - [64..127]  `numberMinted`                                                                                                          //
//        // - [128..191] `numberBurned`                                                                                                          //
//        // - [192..255] `aux`                                                                                                                   //
//        mapping(address => uint256) private _packedAddressData;                                                                                 //
//                                                                                                                                                //
//        // Mapping from token ID to approved address.                                                                                           //
//        mapping(uint256 => address) private _tokenApprovals;                                                                                    //
//                                                                                                                                                //
//        // Mapping from owner to operator approvals                                                                                             //
//        mapping(address => mapping(address => bool)) private _operatorApprovals;                                                                //
//                                                                                                                                                //
//        constructor(string memory name_, string memory symbol_) {                                                                               //
//            _name = name_;                                                                                                                      //
//            _symbol = symbol_;                                                                                                                  //
//            _currentIndex = _startTokenId();                                                                                                    //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the starting token ID.                                                                                                  //
//         * To change the starting token ID, please override this function.                                                                      //
//         */                                                                                                                                     //
//        function _startTokenId() internal view virtual returns (uint256) {                                                                      //
//            return 0;                                                                                                                           //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the next token ID to be minted.                                                                                         //
//         */                                                                                                                                     //
//        function _nextTokenId() internal view returns (uint256) {                                                                               //
//            return _currentIndex;                                                                                                               //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the total number of tokens in existence.                                                                                //
//         * Burned tokens will reduce the count.                                                                                                 //
//         * To get the total number of tokens minted, please see `_totalMinted`.                                                                 //
//         */                                                                                                                                     //
//        function totalSupply() public view override returns (uint256) {                                                                         //
//            // Counter underflow is impossible as _burnCounter cannot be incremented                                                            //
//            // more than `_currentIndex - _startTokenId()` times.                                                                               //
//            unchecked {                                                                                                                         //
//                return _currentIndex - _burnCounter - _startTokenId();                                                                          //
//            }                                                                                                                                   //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the total amount of tokens minted in the contract.                                                                      //
//         */                                                                                                                                     //
//        function _totalMinted() internal view returns (uint256) {                                                                               //
//            // Counter underflow is impossible as _currentIndex does not decrement,                                                             //
//            // and it is initialized to `_startTokenId()`                                                                                       //
//            unchecked {                                                                                                                         //
//                return _currentIndex - _startTokenId();                                                                                         //
//            }                                                                                                                                   //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev Returns the total number of tokens burned.                                                                                      //
//         */                                                                                                                                     //
//        function _totalBurned() internal view returns (uint256) {                                                                               //
//            return _burnCounter;                                                                                                                //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev See {IERC165-supportsInterface}.                                                                                                //
//         */                                                                                                                                     //
//        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {                                            //
//            // The interface IDs are constants representing the first 4 bytes of the XOR of                                                     //
//            // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165                                             //
//            // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`                                                                 //
//            return                                                                                                                              //
//                interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.                                                                 //
//                interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.                                                                 //
//                interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.                                                           //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * @dev See {IERC721-balanceOf}.                                                                                                        //
//         */                                                                                                                                     //
//        function balanceOf(address owner) public view override returns (uint256) {                                                              //
//            if (owner == address(0)) revert BalanceQueryForZeroAddress();                                                                       //
//            return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;                                                                      //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Returns the number of tokens minted by `owner`.                                                                                      //
//         */                                                                                                                                     //
//        function _numberMinted(address owner) internal view returns (uint256) {                                                                 //
//            return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;                                            //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Returns the number of tokens burned by or on behalf of `owner`.                                                                      //
//         */                                                                                                                                     //
//        function _numberBurned(address owner) internal view returns (uint256) {                                                                 //
//            return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;                                            //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).                                                  //
//         */                                                                                                                                     //
//        function _getAux(address owner) internal view returns (uint64) {                                                                        //
//            return uint64(_packedAddressData[owner] >> BITPOS_AUX);                                                                             //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).                                                     //
//         * If there are multiple variables, please pack them into a uint64.                                                                     //
//         */                                                                                                                                     //
//        function _setAux(address owner, uint64 aux) internal {                                                                                  //
//            uint256 packed = _packedAddressData[owner];                                                                                         //
//            uint256 auxCasted;                                                                                                                  //
//            assembly { // Cast aux without masking.                                                                                             //
//                auxCasted := aux                                                                                                                //
//            }                                                                                                                                   //
//            packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);                                                             //
//            _packedAddressData[owner] = packed;                                                                                                 //
//        }                                                                                                                                       //
//                                                                                                                                                //
//        /**                                                                                                                                     //
//         * Returns the packed ownership data of `tokenId`.                                                                                      //
//         */                                                                                                                                     //
//        function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {                                                           //
//            uint256 curr = tokenId;                                                                                                             //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ggg is ERC721Creator {
    constructor() ERC721Creator("fd", "ggg") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}