// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract WithdrawTokens {

    struct WithdrawRequest {
        uint256 withdrawRequestID;
        uint256 nftID;
        uint256 chainID;
        address user;
        address token;
        uint256 amount;
        bool isMB1;
        address recipient;
    }
/*     struct WithdrawMultipleRequest {
        uint256 withdrawMultipleRequestID;
        uint256[] nftIDs;
        uint256[] chainIDs;
        address user;
        address[] tokens;
        uint256[] amounts;
        bool isMB1;
        address recipient;
    } */

    uint256 public withdrawRequestCount;
    mapping(uint256 => WithdrawRequest) public WithdrawRequests;
    //uint256 public withdrawMultipleRequestCount;
    //mapping(uint256 => WithdrawMultipleRequest) public WithdrawMultipleRequests;

    constructor() {
    }

    function withdraw(uint256 _nftID, address _token, uint256 _amount, uint256 _chainID, bool _isMB1,
        address _recipient) external 
    {
        // require((_isMB1 && IERC721(MB1Address).ownerOf(_nftID) == msg.sender)
        //     || (!_isMB1 && IERC721(GGAddress).ownerOf(_nftID) == msg.sender), "NOT_NFT_OWNER");
        WithdrawRequests[withdrawRequestCount] = WithdrawRequest({ 
            withdrawRequestID: withdrawRequestCount, 
            nftID: _nftID,
            chainID: _chainID,
            user: msg.sender,
            token: _token,
            amount: _amount,
            isMB1: _isMB1,
            recipient: _recipient
        });
        emit Withdraw(withdrawRequestCount, msg.sender, _nftID, _token, _amount, _chainID, _isMB1, _recipient);
        withdrawRequestCount++;
    }

    function withdrawMultiple(uint256[] calldata _nftIDs, address[] calldata _tokens, uint256[] calldata _amounts, 
        uint256[] calldata _chainIDs, bool _isMB1, address _recipient) external
    {
        // if (_isMB1) {
        //     for(uint256 x; x < _nftIDs.length; x++) {
        //         require(IERC721(MB1Address).ownerOf(_nftIDs[x]) == msg.sender, "NOT_NFT_OWNER");
        //     }
        // } else {
        //     for(uint256 x; x < _nftIDs.length; x++) {
        //         require(IERC721(GGAddress).ownerOf(_nftIDs[x]) == msg.sender, "NOT_NFT_OWNER");
        //     }
        // }
        for(uint256 x; x < _chainIDs.length; x++) {
            WithdrawRequests[withdrawRequestCount] = WithdrawRequest({ 
                withdrawRequestID: withdrawRequestCount, 
                nftID: _nftIDs[x],
                chainID: _chainIDs[x],
                user: msg.sender,
                token: _tokens[x],
                amount: _amounts[x],
                isMB1: _isMB1,
                recipient: _recipient
            });        
            emit Withdraw(withdrawRequestCount, msg.sender, _nftIDs[x], _tokens[x], _amounts[x], _chainIDs[x], _isMB1, _recipient);
            withdrawRequestCount++;
        }
    }

    event Withdraw(uint256 indexed withdrawRequestID, address indexed user, uint256 indexed nftID, 
        address token, uint256 amount, uint256 chainID, bool isMB1, address recipient);
/*     event WithdrawMultiple(uint256 indexed withdrawRequestID, address indexed user, uint256[] indexed nftIDs, 
        address[] tokens, uint256[] amounts, uint256[] chainIDs, bool isMB1, address recipient); */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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