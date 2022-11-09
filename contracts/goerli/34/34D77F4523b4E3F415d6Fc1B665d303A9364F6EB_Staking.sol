// SPDX-License-Identifier: MIT

/**
* Author: Goku153

*/
pragma solidity ^0.8.0;
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    /**
     * @dev A structure representing the data being stored for a staking pass.
     * It contains several pieces of information:
     * - owner            : The address of the owner who staked the pass
     * - beneficiary      : The beneficiary address that the owner want to use to access the platform from
     */
    struct StakeData {
        address owner;
        address beneficiary;
    }

    /**
     * @dev A structure representing the data being required  as a paramter for  staking a pass.
     * It contains several pieces of information:
     * - owner            : The address of the owner who staked the pass
     * - beneficiary      : The beneficiary address that the owner want to use to access the platform from
     */
    struct StakeParam {
        uint256 tokenId;
        address beneficiary;
    }

    IERC721A public collection;
    uint public totalStakedTokens;

    // Mapping of benefits balance for  addresses
    mapping(address => uint256) public benefitBalance;

    // Mapping of tokens staked by an owner address
    mapping(address => uint256[]) public tokensOwned;

    // Mapping of data stored for a token
    mapping(uint256 => StakeData) public tokenStaked;

    constructor(address collectionAddress_) {
        collection = IERC721A(collectionAddress_);
    }

    /**
     * @dev Set the collection that will be used for staking
     *
     * @param collectionAddress_ : the address of the contract you want to use for staking
     */
    function setCollection(address collectionAddress_) public onlyOwner {
        collection = IERC721A(collectionAddress_);
    }

    /**
     * @dev Internal function that stakes a pass
     *
     * @param tokenId_ : the tokenId of the pass being staked
     * @param beneficiary_ : the beneficiary address that would reap the benefits
     */
    function _stakeToken(uint256 tokenId_, address beneficiary_) internal {
        tokensOwned[msg.sender].push(tokenId_);
        tokenStaked[tokenId_] = StakeData(msg.sender, beneficiary_);
        if (beneficiary_ != address(0) && beneficiary_ != msg.sender) {
            benefitBalance[beneficiary_]++;
        }
        collection.transferFrom(msg.sender, address(this), tokenId_);
        totalStakedTokens++;
    }

    /**
     * @dev Stakes a single pass and verify the ownership
     *
     * @param tokenId_ : the tokenId of the pass being staked
     * @param beneficiary_ : the beneficiary address that would reap the benefits
     */
    function stakeToken(uint256 tokenId_, address beneficiary_) external {
        // revert conditions
        require(
            collection.ownerOf(tokenId_) == msg.sender,
            "Token is not owned by sender"
        );
        _stakeToken(tokenId_, beneficiary_);
    }

    /**
     * @dev Stakes a batch of passes and verify the ownership
     *
     * @param stakeParams_ : the stake data for the list of tokens containing beneficiary and tokenId
     */
    function batchStakeTokens(StakeParam[] calldata stakeParams_) external {
        unchecked {
            uint _len_ = stakeParams_.length;
            uint _index_ = 0;
            while (_index_ < _len_) {
                uint256 tokenId = stakeParams_[_index_].tokenId;
                if (collection.ownerOf(tokenId) == msg.sender) {
                    address beneficiary = stakeParams_[_index_].beneficiary;
                    _stakeToken(tokenId, beneficiary);
                }
                _index_++;
            }
        }
    }

    /**
     * @dev return the list of tokenId's of staked passes by an address
     *
     * @param tokenOwner_ : the owner of the list of passes
     */
    function getStakedTokens(address tokenOwner_)
        external
        view
        returns (uint[] memory)
    {
        return tokensOwned[tokenOwner_];
    }

    /**
     * @dev Internal function that unstakes a pass
     *
     * @param tokenId_ : the tokenId of the pass being unstaked
     */
    function _unstakeToken(uint256 tokenId_) internal {
        address _beneficiary_ = tokenStaked[tokenId_].beneficiary;
        if (_beneficiary_ != address(0) && _beneficiary_ != msg.sender) {
            benefitBalance[_beneficiary_]--;
        }
        delete tokenStaked[tokenId_];
        uint256 _len_ = tokensOwned[msg.sender].length;
        uint256 _index_ = _len_;

        while (_index_ > 0) {
            _index_--;
            if (tokensOwned[msg.sender][_index_] == tokenId_) {
                if (_index_ + 1 != _len_) {
                    tokensOwned[msg.sender][_index_] = tokensOwned[msg.sender][
                        _len_ - 1
                    ];
                }
                tokensOwned[msg.sender].pop();
                break;
            }
        }
        collection.transferFrom(address(this), msg.sender, tokenId_);
        totalStakedTokens--;
    }

    /**
     * @dev unstakes a single pass and verify the ownership
     *
     * @param tokenId_ : the tokenId of the pass being unstaked
     */
    function unstakeToken(uint256 tokenId_) external {
        // revert conditions
        require(
            tokenStaked[tokenId_].owner == msg.sender,
            "Token is not owned by sender"
        );
        _unstakeToken(tokenId_);
    }

    /**
     * @dev unstakes a batch of passes and verify the ownership
     *
     * @param tokenList_ : the list of tokenId of the passes being unstaked
     */
    function batchUnstakeTokens(uint256[] calldata tokenList_) external {
        unchecked {
            uint _len_ = tokenList_.length;
            uint _index_ = 0;
            while (_index_ < _len_) {
                uint _tokenId_ = tokenList_[_index_];
                if (tokenStaked[_tokenId_].owner == msg.sender) {
                    _unstakeToken(_tokenId_);
                }
                _index_++;
            }
        }
    }

    /**
     * @dev returns the benefit balance of an address
     *
     * @param wallet_ : the address for whom the user wants to check benefit balance
     */
    function balanceOf(address wallet_) external view returns (uint256) {
        return tokensOwned[wallet_].length + benefitBalance[wallet_];
    }

    /**
     * @dev returns the status of an address whether it is beneficiary or not
     *
     * @param wallet_ : the address for whom the user wants to check
     */
    function isBeneficiary(address wallet_) external view returns (bool) {
        if (benefitBalance[wallet_] != 0) {
            return true;
        }
        uint _length_ = tokensOwned[wallet_].length;
        uint _index_ = 0;
        while (_index_ < _length_) {
            uint _tokenId_ = tokensOwned[wallet_][_index_];
            if (tokenStaked[_tokenId_].beneficiary == msg.sender || tokenStaked[_tokenId_].beneficiary == address(0)) {
                return true;
            }
            _index_++;
        }
        return false;
    }

    /**
     * @dev updates the beneficiary address of a staked token
     *
     * @param tokenId_ : the tokenId of the staked pass
     * @param beneficiaryAddress_: the address that would be used as a beneficiary
     */
    function updateBeneficiary(uint256 tokenId_, address beneficiaryAddress_)
        external
    {
        require(
            tokenStaked[tokenId_].owner == msg.sender,
            "Token is not staked by sender"
        );
        address _oldBeneficiaryAddress_ = tokenStaked[tokenId_].beneficiary;
        if (
            _oldBeneficiaryAddress_ != address(0) &&
            _oldBeneficiaryAddress_ != msg.sender
        ) {
            benefitBalance[_oldBeneficiaryAddress_]--;
        }
        if (
            beneficiaryAddress_ != address(0) &&
            beneficiaryAddress_ != msg.sender
        ) {
            benefitBalance[beneficiaryAddress_]++;
        }

        tokenStaked[tokenId_].beneficiary = beneficiaryAddress_;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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