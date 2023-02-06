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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoZooRefund is Ownable, ReentrancyGuard {
    struct RefundInfo {
        uint32 tokenId;
        bool isAnimal;
    }

    /// @notice the address used to burn the NFTs
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    /// @notice the address of the baseAnimal contract
    IERC721Enumerable public immutable baseAnimalContract;
    /// @notice the address of the baseEgg contract
    IERC721Enumerable public immutable baseEggContract;
    /// @notice the total supply of baseEggs
    uint256 public immutable baseEggTotalSupply;
    /// @notice the total amount of ETH/BNB to be used as a refund reserve
    uint256 public immutable totalRefundReserve;
    /// @notice the amount of ETH/BNB to be refunded per baseEgg/baseAnimal
    uint256 public immutable individualRefundAmount;
    /// @notice the amount of ETH/BNB left in the refund reserve
    uint256 public refundReserve;
    /// @notice flag to enable/disable refunds
    bool public refundEnabled = true;
    /// @notice the address of the operator
    address public operator;

    /**
     * @notice Modifier to check if the refund is enabled
     */
    modifier onlyRefundEnabled() {
        require(refundEnabled, "refund is disabled");
        _;
    }

    /**
     * @notice Modifier to check if the refund is disabled
     */
    modifier onlyRefundDisabled() {
        require(!refundEnabled, "refund is enabled");
        _;
    }

    /**
     * @notice Modifier to check if the caller is the owner or the operator
     */
    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "not owner or operator");
        _;
    }

    /**
     * @notice Constructor for the Refund contract. The contract is used to refund users for the
     * BaseEgg and BaseAnimals NFTs they sent to the contract. The NFTs will be burned and the
     * refund amount will be defined by the individualRefundAmount variable times the number of NFTs
     * sent.
     * @param baseAnimalContract_ the address of the baseAnimal contract
     * @param baseEggContract_ the address of the baseEgg contract
     * @param baseEggTotalSupply_ the total supply of baseEggs
     * @param totalRefundReserve_ the total amount of ETH/BNB to be used as a refund reserve
     */
    constructor(
        address baseEggContract_,
        address baseAnimalContract_,
        uint256 baseEggTotalSupply_,
        uint256 totalRefundReserve_
    ) {
        baseEggContract = IERC721Enumerable(baseEggContract_);
        baseAnimalContract = IERC721Enumerable(baseAnimalContract_);
        totalRefundReserve = totalRefundReserve_;
        require(
            baseEggContract.totalSupply() == baseEggTotalSupply_,
            "baseEggTotalSupply does not match"
        );
        baseEggTotalSupply = baseEggTotalSupply_;
        individualRefundAmount = totalRefundReserve_ / baseEggTotalSupply_;
    }

    /**
     * @notice Set the operator address. Can only be called by the owner. Operators are only allowed
     * to toggle the refund functionality.
     */
    function setOperator(address operator_) external onlyOwner {
        operator = operator_;
    }

    /**
     * @notice Initialize the refund reserve. This function can only be called once and the paid
     * amount sent must be equal to the totalRefundReserve variable.
     */
    function createRefundReserve() external payable onlyOwner {
        require(refundReserve == 0, "reserve already initialized");
        require(msg.value == totalRefundReserve, "incorrect value sent to initialize the reserve");
        refundReserve = msg.value;
    }

    /**
     * @notice enable/disable the refund functionality. Can only be called by the owner.
     */
    function toggleRefund() external onlyOwnerOrOperator {
        refundEnabled = !refundEnabled;
    }

    /**
     * @notice Withdraw the refund reserve. Can only be called by the owner and only if the refund
     * functionality is disabled.
     */
    function withdrawRefundReserve() external onlyOwner onlyRefundDisabled {
        require(refundReserve > 0, "refund reserve is empty");
        refundReserve = 0;
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Refund users for the BaseEgg and baseAnimals NFTs they sent to the contract. The
     * refund amount is defined by the individualRefundAmount variable times the number of NFTs
     * sent.
     * @param refundList a list of structs containing the refund information. The refund info is
     * composed of the NFT tokenId to be burned and a boolean flag specifying if the NFT is
     * is baseAnimal (true) or not (false = baseEgg).
     */
    function refund(RefundInfo[] calldata refundList) external onlyRefundEnabled nonReentrant {
        require(refundReserve > 0, "refund reserve is empty");
        require(refundList.length > 0, "the number of tokens for refund is 0");
        for (uint256 i = 0; i < refundList.length; i++) {
            if (refundList[i].isAnimal) {
                require(
                    baseAnimalContract.ownerOf(refundList[i].tokenId) == msg.sender,
                    "not an animal or user not own animal"
                );
                baseAnimalContract.safeTransferFrom(msg.sender, deadAddress, refundList[i].tokenId);
            } else {
                require(
                    baseEggContract.ownerOf(refundList[i].tokenId) == msg.sender,
                    "not an egg or user not own egg"
                );
                baseEggContract.safeTransferFrom(msg.sender, deadAddress, refundList[i].tokenId);
            }
        }
        uint256 refundAmount = individualRefundAmount * refundList.length;
        require(refundReserve >= refundAmount, "not enough reserve to refund");
        refundReserve -= refundAmount;
        payable(msg.sender).transfer(refundAmount);
    }
}