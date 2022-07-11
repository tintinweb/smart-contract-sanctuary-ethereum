// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title OnChainRandom
 * @author BaseLabs
 */
contract OnChainRandom {
    uint256 private _seed;
    /**
     * @notice _unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners,
     * so VRF is recommended for most security-sensitive scenarios.
     * @return randomly generated number.
     */
    function _unsafeRandom() internal returns (uint256) {
    unchecked {
        _seed++;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                block.difficulty,
                block.timestamp,
                block.coinbase,
                _seed,
                tx.origin
            )));
    }
    }
}

/**
 * @title RandomPairs
 * @author BaseLabs
 */
contract RandomPairs is OnChainRandom {
    struct Uint256Pair {
        uint256 key;
        uint256 value;
    }

    function _getPairsValueSum(Uint256Pair[] memory pairs_) internal pure returns (uint256) {
        unchecked {
            uint256 totalSize = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                totalSize += pairs_[i].value;
            }
            return totalSize;
        }
    }

    /**
     * @notice _genRandKeyByPairsWithSize is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @param totalSize_ the sum probabilities.
     * @return the key.
     */
    function _genRandKeyByPairsWithSize(Uint256Pair[] memory pairs_, uint256 totalSize_) internal returns (uint256) {
        unchecked {
            if (pairs_.length == 1) {
                return pairs_[0].key;
            }
            uint256 entropy = _unsafeRandom() % totalSize_;
            uint256 step = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                step += pairs_[i].value;
                if (entropy < step) {
                    return pairs_[i].key;
                }
            }
            revert("unreachable code");
        }
    }

    /**
     * @notice _genRandKeyByPairs is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @return the key.
     */
    function _genRandKeyByPairs(Uint256Pair[] memory pairs_) internal returns (uint256) {
        return _genRandKeyByPairsWithSize(pairs_, _getPairsValueSum(pairs_));
    }
}


/**
 * @title IExtendableERC1155
 * @author BaseLabs
 */
abstract contract IExtendableERC1155 is IERC1155 {
    /**
     * @dev Transfers `amount_` tokens of token type `id_` from `from_` to `to`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - `from_` must have a balance of tokens of type `id_` of at least `amount`.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawSafeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     * Emits a {TransferBatch} event.
     * Requirements:
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawSafeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Creates `amount_` tokens of token type `id_`, and assigns them to `to_`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawMint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawMintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Destroys `amount_` tokens of token type `id_` from `from_`
     * Requirements:
     * - `from_` cannot be the zero address.
     * - `from_` must have at least `amount` tokens of token type `id`.
     */
    function rawBurn(address from_, uint256 id_, uint256 amount_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     */
    function rawBurnBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external virtual;

    /**
     * @dev Approve `operator_` to operate on all of `owner_` tokens
     * Emits a {ApprovalForAll} event.
     */
    function rawSetApprovalForAll(address owner_, address operator_, bool approved_) external virtual;
}

/**
 * @title CheersUpEmojiAirdrop
 * @author BaseLabs
 */
contract CheersUpEmojiAirdrop is Ownable, RandomPairs {
    event CUPOrientedAirdrop(uint256 indexed cupTokenId_, address indexed address_, uint256 indexed emojiTokenId_);
    event Airdrop(address indexed address_, uint256 indexed tokenId_);
    IExtendableERC1155 private _basic;
    IERC721 private _cheersup;

    constructor(address basicAddress_, address cheersUpAddress_) {
        _basic = IExtendableERC1155(basicAddress_);
        _cheersup = IERC721(cheersUpAddress_);
    }

    /**
     * @notice airdropByNum is used to airdrop tokens to the given address.
     * @param accounts_ the address to airdrop
     * @param nums_ number of tokens to airdrop for each address
     * @param numPairs_ define the tokenId and the corresponding quantity of this airdrop
     */
    function airdropByNum(address[] calldata accounts_, uint256[] calldata nums_, Uint256Pair[] calldata numPairs_) external onlyOwner {
        require(accounts_.length == nums_.length, "accounts_ and nums_ must have the same length");
    unchecked {
        uint256 total = 0;
        for (uint256 i = 0; i < nums_.length; i++) {
            total += nums_[i];
        }
        uint256[] memory bucket = _generateBucket(total, numPairs_);
        uint256 cursor = 0;
        for (uint256 i = 0; i < accounts_.length; i++) {
            uint256 num = nums_[i];
            address account = accounts_[i];
            for (uint256 j = 0; j < num; j++) {
                _basic.rawMint(account, bucket[cursor], 1, "");
                emit Airdrop(account, bucket[cursor]);
                cursor++;
            }
        }
    }
    }

    /**
     * @notice airdropByProbability is used to airdrop tokens to the given address.
     * @param accounts_ the address to airdrop
     * @param nums_ number of tokens to airdrop for each address
     * @param probabilityPairs_ define the tokenId and the corresponding probability of this airdrop
     */
    function airdropByProbability(address[] calldata accounts_, uint256[] calldata nums_, Uint256Pair[] calldata probabilityPairs_) external onlyOwner {
        require(accounts_.length == nums_.length, "accounts_ and nums_ must have the same length");
    unchecked {
        uint256 totalSize = _getPairsValueSum(probabilityPairs_);
        for (uint256 i = 0; i < accounts_.length; i++) {
            uint256 num = nums_[i];
            address account = accounts_[i];
            for (uint256 j = 0; j < num; j++) {
                uint256 tokenId = _genRandKeyByPairsWithSize(probabilityPairs_, totalSize);
                _basic.rawMint(account, tokenId, 1, "");
                emit Airdrop(account, tokenId);
            }
        }
    }
    }

    /**
     * @notice airdropToCUPByNum is used to airdrop based on the CUP token id.
     * @param cupTokenIds_ cheers up token ids
     * @param nums_ number of tokens to airdrop for each cup token id
     * @param numPairs_ define the tokenId and the corresponding quantity of this airdrop
     */
    function airdropToCUPByNum(uint256[] calldata cupTokenIds_, uint256[] calldata nums_, Uint256Pair[] calldata numPairs_) external onlyOwner {
        require(cupTokenIds_.length == nums_.length, "cupTokenIds_ and nums_ must have the same length");
    unchecked {
        uint256 total = 0;
        for (uint256 i = 0; i < nums_.length; i++) {
            total += nums_[i];
        }
        uint256[] memory bucket = _generateBucket(total, numPairs_);
        uint256 cursor = 0;
        for (uint256 i = 0; i < cupTokenIds_.length; i++) {
            uint256 num = nums_[i];
            uint256 cupTokenId = cupTokenIds_[i];
            address tokenOwner = _cheersup.ownerOf(cupTokenId);
            for (uint256 j = 0; j < num; j++) {
                _basic.rawMint(tokenOwner, bucket[cursor], 1, "");
                emit CUPOrientedAirdrop(cupTokenId, tokenOwner, bucket[cursor]);
                cursor++;
            }
        }
    }
    }

    /**
     * @notice airdropToCUPByProbability is used to airdrop based on the CUP token id.
     * @param cupTokenIds_ cheers up token ids
     * @param nums_ number of tokens to airdrop for each cup token id
     * @param probabilityPairs_ define the tokenId and the corresponding probability of this airdrop
     */
    function airdropToCUPByProbability(uint256[] calldata cupTokenIds_, uint256[] calldata nums_, Uint256Pair[] calldata probabilityPairs_) external onlyOwner {
        require(cupTokenIds_.length == nums_.length, "cupTokenIds_ and nums_ must have the same length");
        uint256 totalSize = _getPairsValueSum(probabilityPairs_);
        for (uint256 i = 0; i < cupTokenIds_.length; i++) {
            uint256 cupTokenId = cupTokenIds_[i];
            uint256 num = nums_[i];
            address tokenOwner = _cheersup.ownerOf(cupTokenId);
            for (uint256 j = 0; j < num; j++) {
                uint256 tokenId = _genRandKeyByPairsWithSize(probabilityPairs_, totalSize);
                _basic.rawMint(tokenOwner, tokenId, 1, "");
                emit CUPOrientedAirdrop(cupTokenId, tokenOwner, tokenId);
            }
        }
    }

    /**
     * @notice generate a random array based on numPairs_
     * @param total_ total number of elements
     * @param numPairs_ array of Uint256Pair, it defines the number of each TokenId.
     * @return array of tokenId
     */
    function _generateBucket(uint256 total_, Uint256Pair[] memory numPairs_) internal returns (uint256[] memory) {
    unchecked {
        uint256[] memory bucket = new uint256[](total_);
        uint256 sum;
        uint256 cursor;
        for (uint256 i = 0; i < numPairs_.length; i++) {
            sum += numPairs_[i].value;
            for (uint256 j = 0; j < numPairs_[i].value; j++) {
                bucket[cursor] = numPairs_[i].key;
                cursor++;
            }
        }
        require(total_ == sum, "total_ must equal to sum");
        _shuffle(bucket);
        return bucket;
    }
    }

    /**
     * @notice _shuffle the array
     * @param items_ array to be shuffled
     */
    function _shuffle(uint256[] memory items_) internal {
    unchecked {
        for (uint256 i = items_.length - 1; i > 0; i--) {
            uint256 j = _unsafeRandom() % (i + 1);
            (items_[j], items_[i]) = (items_[i], items_[j]);
        }
    }
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