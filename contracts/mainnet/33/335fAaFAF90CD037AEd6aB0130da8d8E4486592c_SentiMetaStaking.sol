// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ISentiMetaStaking.sol";

contract SentiMetaStaking is Ownable, ISentiMetaStaking {

    // Events
    event Stake(uint8 opType, address indexed owner, address indexed project, uint96 indexed tokenId, uint96 totalStaked);

    // Target NFT contract (OnChainPixels)
    IERC721Enumerable _targetContract;

    /* Stake mapping */
    mapping(address => uint96) _projectAddressToStakedCounts;
    mapping(uint256 => TokenStake) _storageIdToToken;
    mapping(uint96 => uint256) _tokenIdToStorageId;

    /* Approval mapping */
    mapping(address => mapping(address => address)) private _operatorApprovals;

    constructor(address target_){
        _targetContract = IERC721Enumerable(target_);
    }

    // Extensibility function to allow for er-targeting should the OnChainPixels contract ever need to be migrated
    function updateTarget (address target_) external onlyOwner {
        _targetContract = IERC721Enumerable(target_);
    }

    // Extracts an address from a uint256 sotage id
    function _extractProjectAddressFromStorageId(uint256 storageId_) private pure returns (address) {
        return address(uint160((storageId_ >> 96)));
    }

    // Creates a storage ID from an address and index
    function _createStorageId(address projectAddress_, uint256 index_) private pure returns (uint256) {
        return (uint256(uint160(projectAddress_)) << 96) + index_;
    }

    // Stakes at a new index
    function _stake(uint96 tokenId_, address projectAddress_, address owner_) private {
        uint256 newIndex = _projectAddressToStakedCounts[projectAddress_];
        uint256 newStorageId = _createStorageId(projectAddress_, newIndex);

        uint48 timestamp = uint48(block.timestamp);
        _storageIdToToken[newStorageId] = TokenStake({
            tokenId: tokenId_,
            timestamp: timestamp
        });
        _tokenIdToStorageId[tokenId_] = newStorageId;
        _projectAddressToStakedCounts[projectAddress_]++;

        emit Stake(uint8(1), owner_, projectAddress_, tokenId_, _projectAddressToStakedCounts[projectAddress_]);
    }

    // Unstakes, moving last index to deleted index and removing the last enty (allowing reuse of indexes and preventing potential overflow)
    function _unstake(address projectAddress_, uint256 storageId_, uint96 tokenId_, address owner_) private {
        _projectAddressToStakedCounts[projectAddress_]--;
        
        uint256 lastIndex = _projectAddressToStakedCounts[projectAddress_];
        uint256 lastStorageId = _createStorageId(projectAddress_, lastIndex);
        uint96 lastTokenId = _storageIdToToken[lastStorageId].tokenId;

        _storageIdToToken[storageId_] = _storageIdToToken[lastStorageId];
        _tokenIdToStorageId[lastTokenId] = storageId_;
        delete _storageIdToToken[lastStorageId];
        delete _tokenIdToStorageId[tokenId_];

        emit Stake(uint8(0), owner_, projectAddress_, tokenId_, uint96(lastIndex));
    }

    /**
        @dev Stakes a tokenId_ against a projectAddress_
    */
    function stake(uint96 tokenId_, address projectAddress_) public override {
        require(projectAddress_ != address(0), "Project address must not be 0");

        address owner = _targetContract.ownerOf(tokenId_);
        require(owner == msg.sender || isApprovedForProject(projectAddress_, owner, msg.sender), "Must own token or be approved");

        uint256 storageId = _tokenIdToStorageId[tokenId_];

        if(storageId == 0) {
            _stake(tokenId_, projectAddress_, owner);
        }
        else {
            address prevProjectAddress = _extractProjectAddressFromStorageId(storageId);

            require(projectAddress_ != prevProjectAddress, "Already staked");

            _unstake(prevProjectAddress, storageId, tokenId_, owner);

            _stake(tokenId_, projectAddress_,owner);
        }
    }

    /**
        @dev Untakes a tokenId_ from its currently staked project
    */
    function unstake(uint96 tokenId_) public override {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        address projectAddress = _extractProjectAddressFromStorageId(storageId);

        address owner = _targetContract.ownerOf(tokenId_);
        require(owner == msg.sender || isApprovedForProject(projectAddress, owner, msg.sender), "Must own token or be approved");

        _unstake(projectAddress, storageId, tokenId_, owner);
    }

    /**
        @dev Stakes multiple 
    */
    function stakeMultiple(uint96[] calldata tokenIds_, address[] calldata projectAddresses_) external override {
        require(tokenIds_.length == projectAddresses_.length, "Invalid input lengths");

        for(uint256 i = 0; i < tokenIds_.length; i++) {
            stake(tokenIds_[i], projectAddresses_[i]);
        }
    }

    /**
        @dev Untakes multiple 
    */
    function unstakeMultiple(uint96[] calldata tokenIds_) external override {
        require(tokenIds_.length > 0);

        for(uint256 i = 0; i < tokenIds_.length; i++) {
            unstake(tokenIds_[i]);
        }
    }

    /* APPROVALS */

    /**
        @dev Approves an address to be able to stake and unstake
    */
    function approveForProject(address projectAddress_, address operator_) external {
        _operatorApprovals[msg.sender][projectAddress_] = operator_;
    }

    /**
        @dev Revokes address approval
    */
    function revokeProjectApproval(address projectAddress_) external {
        delete _operatorApprovals[msg.sender][projectAddress_];
    }

    /**
        @dev Returns a boolean indicated whether am address is approved to stake/unstake by an owner
    */
    function isApprovedForProject(address projectAddress_, address owner_, address operator_) public view returns (bool) {
        return (_operatorApprovals[owner_][projectAddress_] == operator_);
    }

    /* VIEW UTILITIES */

    /**
        @dev Gets a count of how many projects are staked against a project
    */
    function getCountByProjectAddress(address projectAddress_) external view override returns (uint256) {
        return _projectAddressToStakedCounts[projectAddress_];
    }

    /**
        @dev Gets a tokenId at index that is staked against a project
    */
    function getTokenIdByProjectAddressAndIndex(address projectAddress_, uint96 index_) external view override returns (uint256) {
        uint256 count = _projectAddressToStakedCounts[projectAddress_];
        require(count > 0, "No tokens staked");
        
        uint256 storageId = _createStorageId(projectAddress_, index_);
        return _storageIdToToken[storageId].tokenId;
    }

    /**
        @dev Get project address that a token is currently staked against
    */
    function getProjectAddressByTokenId(uint96 tokenId_) public view override returns (address) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        address projectAddress = _extractProjectAddressFromStorageId(storageId);

        return projectAddress;
    }

    /**
        @dev Get project addresses that an array of tokens are currently staked against
    */
    function getProjectAddressesByTokenIds(uint96[] calldata tokenIds_) external view override returns (address[] memory) {
        address[] memory result = new address[](tokenIds_.length);
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            result[i] = getProjectAddressByTokenId(tokenIds_[i]);
        }

        return result;
    }

    /**
        @dev Returns an array of booleans indicated whether the tokens are currently staked
    */
    function checkTokenIdsStaked(uint96[] calldata tokenIds_) external view override returns (bool[] memory) {
        bool[] memory result = new bool[](tokenIds_.length);
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            result[i] = (_tokenIdToStorageId[tokenIds_[i]] != 0);
        }

        return result;
    }

    /**
        @dev Returns an array of tokenIds that an account currently has staked
    */
    function getStakedTokenIdsOfOwner(address owner_) external view override returns (uint256[] memory) {
        uint256 balance = _targetContract.balanceOf(owner_);

        uint256 count = 0;
        uint256[] memory allTokenIds = new uint256[](balance);  
        for(uint256 i = 0; i < balance; i++) {
            uint256 tokenId = _targetContract.tokenOfOwnerByIndex(owner_, i);
            uint256 storageId = _tokenIdToStorageId[uint96(tokenId)];
            allTokenIds[i] = tokenId;
            if(storageId != 0) {
                count++;
            }
        }

        uint256 tokenCounter = 0;
        uint256[] memory tokenIds = new uint256[](count);  
        for(uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 storageId = _tokenIdToStorageId[uint96(allTokenIds[i])];
            if(storageId != 0) {
                tokenIds[tokenCounter] = allTokenIds[i];
                tokenCounter++;
            }

            if(tokenCounter == count) {
                break;
            }
        }

        return tokenIds;
    }

    /* CONTRACT HELPER METHODS */

    /**
        @dev Returns a boolean indicating whether a token is staked against a particular project,
        needed for wrapper contracts to verufy that a token is staked against 1 or more projects that it approves rewards for
    */
    function checkTokenIdStakedToProject(uint96 tokenId_, address projectAddress_) external view override returns (bool) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        if(storageId == 0) {
            return false;
        }

        address projectAddress = _extractProjectAddressFromStorageId(storageId);
        if(projectAddress != projectAddress_) {
            return false;
        }

        return true;
    }

    /**
        @dev Returns the TokenStake instance containing the tokennId and timstamp of when it was staked against the project
        allowing wrapper contracts to calculate the rewards
    */
    function getStakedTokenById(uint96 tokenId_) external view override returns (TokenStake memory) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        return _storageIdToToken[storageId];
    }

    /* Only used for unit tests via a wrapper contract but may also be used by other wrapper contracts in the future */
    function getStorageIdByTokenId(uint96 tokenId_) external view returns (uint256) {
        return _tokenIdToStorageId[tokenId_];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ISentiMetaStaking {
    struct TokenStake {
        uint48 timestamp;
        uint96 tokenId;
    }

    function stake(uint96 tokenId_, address projectAddress_) external;

    function unstake(uint96 tokenId_) external;

    function stakeMultiple(uint96[] calldata tokenIds_, address[] calldata projectAddresss_) external;

    function unstakeMultiple(uint96[] calldata tokenIds_) external;

    function getCountByProjectAddress(address projectAddress_) external view returns (uint256);

    function getTokenIdByProjectAddressAndIndex(address projectAddress_, uint96 index_) external view returns (uint256);

    function getProjectAddressByTokenId(uint96 tokenId_) external view returns (address);

    function getProjectAddressesByTokenIds(uint96[] calldata tokenIds_) external view returns (address[] memory);

    function checkTokenIdsStaked(uint96[] calldata tokenIds_) external view returns (bool[] memory);

    function getStakedTokenIdsOfOwner(address owner_) external view returns (uint256[] memory);

    /* CONTRACT HELPER METHODS */
    function checkTokenIdStakedToProject(uint96 tokenId_, address projectAddress_) external view returns (bool);

    function getStakedTokenById(uint96 tokenId_) external view returns (TokenStake memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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