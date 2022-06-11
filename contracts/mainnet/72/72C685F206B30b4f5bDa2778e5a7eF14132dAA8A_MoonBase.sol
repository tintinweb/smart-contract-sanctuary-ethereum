/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.7;

interface IMoonLanderzNFT {
    function saleMint(uint256 amount) external payable;
}

contract MoonBase is Ownable {
    error InsufficientBalance();
    error CannotClaim();
    error NotTokenOwner();
    error InsufficientETHValue();
    error MaxMintTxReached();
    error MintOut();
    error MintPaused();

    uint256 private constant BATCH_SIZE = 3;
    uint256 private constant SALE_PRICE = 0.088 ether;
    address public mlz;
    uint256 public currentClaimId;
    uint256 public lastClaimId = 1420;
    uint256 public currentMintId;
    uint256 public lastMintId = 7885;
    uint256 public mintPrice = 0.044 ether;
    uint256 public maxMintTx = 3;
    bool public mintPaused;
    mapping(uint256 => bool) private claims;

    event UpdatedLastClaimId(uint256 last);
    event UpdatedCurrentClaimId(uint256 current);
    event UpdatedLastMintId(uint256 last);
    event UpdatedCurrentMintId(uint256 current);
    event UpdatedMintPrice(uint256 price);
    event UpdatedMaxMintTx(uint256 max);
    event UpdatedMintPaused(bool paused);
    event Claimed(uint256 amount);

    constructor(address _mlz) {
        mlz = _mlz;
    }

    function updateLastClaimId(uint256 id) external onlyOwner {
        lastClaimId = id;

        emit UpdatedLastClaimId(id);
    }

    function updateCurrentClaimId(uint256 id) external onlyOwner {
        currentClaimId = id;

        emit UpdatedCurrentClaimId(id);
    }

    function updateLastMintId(uint256 id) external onlyOwner {
        lastMintId = id;

        emit UpdatedLastMintId(id);
    }

    function updateCurrentMintId(uint256 id) external onlyOwner {
        currentMintId = id;

        emit UpdatedCurrentMintId(id);
    }

    function updateMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;

        emit UpdatedMintPrice(price);
    }

    function updateMaxMintTx(uint256 max) external onlyOwner {
        maxMintTx = max;

        emit UpdatedMaxMintTx(max);
    } 

    function updateMintPaused(bool paused) external onlyOwner {
        mintPaused = paused;

        emit UpdatedMintPaused(paused);
    } 

    function withdrawNFT(uint256 id) external onlyOwner {
        IERC721(mlz).transferFrom(address(this), mlz, id);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        (bool success, ) = mlz.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function mintBatches(uint256 batches) external onlyOwner {
        uint256 batchValue = BATCH_SIZE * SALE_PRICE;
        uint256 minBalance = batches * batchValue;

        if (address(this).balance < minBalance)
            revert InsufficientBalance();

        IMoonLanderzNFT mintContract = IMoonLanderzNFT(mlz);

        for (uint256 i; i < batches;) {
            mintContract.saleMint{value: batchValue}(BATCH_SIZE);

            unchecked {
                i++;
            }
        }
    }

    function mint(uint256 amount) external payable {
        IERC721 nftContract = IERC721(mlz);

        if (msg.value != amount * mintPrice)
            revert InsufficientETHValue();

        if (amount > maxMintTx)
            revert MaxMintTxReached();

        if (currentMintId + amount > lastMintId)
            revert MintOut();

        if (mintPaused)
            revert MintPaused();

        for (uint256 i; i < amount;) {
            nftContract.transferFrom(address(this), msg.sender, currentMintId + i);

            unchecked {
                i++;
            }
        }

        unchecked {
            currentMintId += amount;
        }
    }

    function canClaim(uint256 mlzId) external view returns (bool) {
        return IERC721(mlz).ownerOf(mlzId) == msg.sender &&
            (mlzId <= lastClaimId && !claims[mlzId]);
    }

    function canMint(uint256 amount) external view returns (bool) {
        return currentMintId + amount <= lastMintId;
    }

    function claim(uint256[] calldata tokenIds) external {
        uint256 tokensNb = tokenIds.length;
        IERC721 nftContract = IERC721(mlz);

        for (uint256 i; i < tokensNb;) {
            uint256 tokenId = tokenIds[i];

            if (tokenId > lastClaimId || claims[tokenId])
                revert CannotClaim();

            if (nftContract.ownerOf(tokenId) != msg.sender)
                revert NotTokenOwner();
            
            claims[tokenId] = true;

            nftContract.transferFrom(address(this), msg.sender, currentClaimId + i);
            
            unchecked {
                i++;
            }
        }

        unchecked {
            currentClaimId += tokensNb;
        }
        
        emit Claimed(tokensNb);
    }

    receive() external payable {}
}