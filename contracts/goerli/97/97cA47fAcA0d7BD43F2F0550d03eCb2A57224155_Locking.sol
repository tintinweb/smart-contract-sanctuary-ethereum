// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Locking {

    /**
    * @dev Interfaces with the nft contract
    * @dev Contract address is defined in the constructor
    *
    */
    IERC721 public iERC721;

    /**
    * @dev Maps to tokenId => owner address
    *
    */
    mapping (uint256 => address) public lockedTokenOwner;

    /**
    * @dev Fired in `lock()` when a single token is locked
    *
    * @param _tokenId token to be locked
    * @param _tokenOwner owner of the token to be locked
    */
    event NFTSingleLock(uint256 _tokenId, address _tokenOwner);

    /**
    * @dev Fired in `unlock()' when a single token is unlocked
    *
    * @param _tokenId token to be unlocked
    * @param _tokenOwner owner of the token to be unlocked
    */
    event NFTSingleUnlock(uint256 _tokenId, address _tokenOwner);

    /**
    * @dev Fired in `batchLock()' when a batch of tokens is locked
    *
    * @param _tokenIds batch of tokens to be locked
    * @param _tokenOwner owner of the batch of tokens to be locked
    */
    event NFTBatchLock(uint256[] _tokenIds, address _tokenOwner);

    /**
    * @dev Fired in `batchUnlock()' when a batch of tokens is unlocked
    *
    * @param _tokenIds batch of tokens to be unlocked
    * @param _tokenOwner owner of the batch of tokens to be unlocked
    */
    event NFTBatchUnlock(uint256[] _tokenIds, address _tokenOwner);

    /**
    * @dev Defines nft contract address
    *
    * @param _erc721Address nft address
    */
    constructor(address _erc721Address) {
        iERC721 = IERC721(_erc721Address);
    }

    /**
    * @dev Used in private function _lock()
    * @dev Throws if the the mapping returns a non-zero address. It means
    *      that the token is already locked
    *
    * @param _tokenId token to be locked
    */
    modifier isTokenNotLocked(uint256 _tokenId) {
        require(lockedTokenOwner[_tokenId] == address(0), "The token is currently locked");
        _;
    }

    /**
    * @dev Used in private function _lock()
    * @dev Throws if the caller is not the token owner
    *
    * @param _tokenId token to be locked
    */
    modifier isTokenOwner(uint256 _tokenId) {
        require(iERC721.ownerOf(_tokenId) == msg.sender, "The caller is not the owner of the token");
        _;
    }

    /**
    * @dev Used in private function _lock()
    * @dev Throws if this contract is not approved to transfer the token
    *
    * @param _tokenId token to be locked and checked for transfer approval
    */
    modifier isTokenApproved(uint256 _tokenId) {
        require(iERC721.getApproved(_tokenId) == address(this), "The contract is not approved to transfer the token");
        _;
    }

    /**
    * @dev Used in the private function _unlock()
    * @dev Throws if the mapping does not return the address of this contract
    *      It means that the token is not locked.
    *
    * @param _tokenId token to be unlocked
    */
    modifier isTokenLocked(uint256 _tokenId) {
        require(iERC721.ownerOf(_tokenId) == address(this), "The token is not locked");
        _;
    }

    /**
    * @dev Used in private function _unlock()
    * @dev Throws if the mapping does not return the address of the caller
    *      It means that the caller is not the owner of the locked token
    *
    * @param _tokenId token to be unlocked
    */
    modifier isLockedTokenOwner(uint256 _tokenId) {
        require(lockedTokenOwner[_tokenId] == msg.sender, "The caller is not the owner of the locked token");
        _;
    }

    /**
    * @dev Private function for lock() and reused in private function _batchLock()
    *
    * @param _tokenId token to be locked
    */
    function _lock(
        uint256 _tokenId
    )
        private
        isTokenNotLocked(_tokenId)
        isTokenOwner(_tokenId)
        isTokenApproved(_tokenId)
    {
        lockedTokenOwner[_tokenId] = msg.sender;
        iERC721.transferFrom(msg.sender, address(this), _tokenId);
    }

    /**
    * @dev Private function for unlock() and reused in private function _batchUnlock()
    *
    * @param _tokenId token to be unlocked
    */
    function _unlock(
        uint256 _tokenId
    )
        private
        isTokenLocked(_tokenId)
        isLockedTokenOwner(_tokenId)
    {
        lockedTokenOwner[_tokenId] = address(0);
        iERC721.transferFrom(address(this), msg.sender, _tokenId);
    }

    /**
    * @dev Private function for batchLock()
    *
    * @param _tokenIds batch of tokens in an array to be locked
    */
    function _batchLock(
        uint256[] calldata _tokenIds
    )
        private
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _lock(tokenId);
        }
    }

    /**
    * @dev Private function for batchUnlock()
    *
    * @param _tokenIds batch of tokens in an array to be unlocked
    */
    function _batchUnlock(
        uint256[] calldata _tokenIds
    )
        private
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _unlock(tokenId);
        }
    }

    /**
    * @dev Locks a single token
    *
    * @param _tokenId token to be locked
    */
    function lock(uint256 _tokenId) external {
        _lock(_tokenId);

        emit NFTSingleLock(_tokenId, msg.sender);
    }

    /**
    * @dev Unlocks a single token
    *
    * @param _tokenId token to be unlocked
    */
    function unlock(uint256 _tokenId) external {
        _unlock(_tokenId);

        emit NFTSingleUnlock(_tokenId, msg.sender);
    }

    /**
    * @dev Locks a batch of tokens
    *
    * @param _tokenIds array of batch tokens to be locked
    */
    function batchLock(uint256[] calldata _tokenIds) external {
        _batchLock(_tokenIds);

        emit NFTBatchLock(_tokenIds, msg.sender);
    }

    /**
    * @dev Unlocks a batch of tokens
    *
    * @param _tokenIds array of batch tokens to be unlocked
    */
    function batchUnlock(uint256[] calldata _tokenIds) external {
        _batchUnlock(_tokenIds);

        emit NFTBatchUnlock(_tokenIds, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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