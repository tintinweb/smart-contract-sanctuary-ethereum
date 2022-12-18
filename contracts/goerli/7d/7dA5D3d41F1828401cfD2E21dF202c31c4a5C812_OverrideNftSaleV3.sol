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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IOverrideNft { 
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function mintBatch(address to, uint256[] memory tokenIds) external;
}

contract OverrideNftSaleV3 is Ownable, ReentrancyGuard {

    // Subtract Final NEON PLEXUS: Override Collection 0xDd782034307ff54C4F0BF2719C9d8e78FCEFDD40
    uint256 public constant OVERRIDE_TOTAL_SUPPLY = 1006; // 1006 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY = 9000 - OVERRIDE_TOTAL_SUPPLY; // 7994 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY_INDEX = OVERRIDE_TOTAL_SUPPLY + DIFFUSION_MAX_SUPPLY ; // 9000

    uint256 public constant HOLDER_FREE_MINT_AMOUT = 3; 
    uint256 public constant PUBLIC_FREE_MINT_AMOUT = 5; 

    uint256 public mintLimitPerTx = 90;

    address public overrideNftContract;
    address public diffusionNftContract;

    uint64 public holderFreeMinted;
    uint64 public publicFreeMinted;

    uint256 public holderFreeMintStartTime; // See holderMint
    uint256 public publicFreeMintStartTime; // See freeMint

    // uncompressed balances by type
    mapping(uint64 => uint64) fabFreeBalanceByFabId;

    event Minted(address sender, uint256 count);

    constructor(address _overrideNftContract, 
        address _diffusionNftContract, 
        uint256 _publicFreeMintStartTime,
        uint256 _holderFreeMintStartTime) Ownable() ReentrancyGuard() {
        overrideNftContract = _overrideNftContract;
        diffusionNftContract = _diffusionNftContract;
        publicFreeMintStartTime = _publicFreeMintStartTime;
        holderFreeMintStartTime = _holderFreeMintStartTime;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMintLimit(uint256 _mintLimitPerTx) external onlyOwner {
        mintLimitPerTx = _mintLimitPerTx;
    }

    function setTimes(uint256 _publicFreeMintStartTime, uint256 _holderFreeMintStartTime) external onlyOwner {
        publicFreeMintStartTime = _publicFreeMintStartTime;
        holderFreeMintStartTime = _holderFreeMintStartTime;
    }

    function setNftContracts(address _overrideNftContract, address _diffusionNftContract) public onlyOwner {
        overrideNftContract = _overrideNftContract;
        diffusionNftContract = _diffusionNftContract;
    }
    
    function fabFreeBalance(uint256 fabId) public view returns (uint256) {
        return fabFreeBalanceByFabId[uint64(fabId)];
    }

    function publicFreeBalance(address who) public view returns (uint256) {
        return IOverrideNft(diffusionNftContract).balanceOf(who);
    }
    
    function publicFreeAvailable(address who) public view returns (uint256) {
        return PUBLIC_FREE_MINT_AMOUT - publicFreeBalance(who);
    }

    function holderFreeAvailable(address who) public view returns (uint256) {

        uint256 targetMintIndex = currentMintIndex();

        uint256 fabBalance = IOverrideNft(overrideNftContract).balanceOf(who);
        uint256 quantity = 0;

        for (uint256 ownerFabIndex; ownerFabIndex < fabBalance; ++ownerFabIndex) {
            uint256 fabId = IOverrideNft(overrideNftContract).tokenOfOwnerByIndex(who, ownerFabIndex);
            uint256 fabIdAvailable = HOLDER_FREE_MINT_AMOUT - fabFreeBalance(fabId);
            uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1 - quantity; 
            uint256 fabIdQuantity = fabIdAvailable < supplyAvailable ? fabIdAvailable : supplyAvailable; 
            // ignore tx limit (just info for holders)

            if (fabIdQuantity > 0) {
                quantity += fabIdQuantity;
            }
        }
        return quantity;
    }

    function holderFreeMint() external nonReentrant callerIsUser {

        require(
        holderFreeMintStartTime != 0 && block.timestamp >= holderFreeMintStartTime,
        "holder mint has not started yet"
        );

        uint256 targetMintIndex = currentMintIndex();
        require(targetMintIndex <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256 fabBalance = IOverrideNft(overrideNftContract).balanceOf(msg.sender);
        require(fabBalance > 0, "No Fabricants sorry!");

        uint256 quantity = 0;

        for (uint256 ownerFabIndex; ownerFabIndex < fabBalance; ++ownerFabIndex) {
            uint256 fabId = IOverrideNft(overrideNftContract).tokenOfOwnerByIndex(msg.sender, ownerFabIndex);
            uint256 fabIdAvailable = HOLDER_FREE_MINT_AMOUT - fabFreeBalance(fabId);
            uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1 - quantity; 
            uint256 fabIdQuantity = fabIdAvailable < supplyAvailable ? fabIdAvailable : supplyAvailable; // min fabIdAvailable, supplyAvailable
            fabIdQuantity = fabIdQuantity < mintLimitPerTx ? fabIdQuantity : mintLimitPerTx; // min fabIdQuantity, mintLimitPerTx

            if (fabIdQuantity > 0) {
                holderFreeMinted += uint64(fabIdQuantity);
                fabFreeBalanceByFabId[uint64(fabId)] += uint64(fabIdQuantity);
                quantity += fabIdQuantity;
            }
        }

        require(quantity > 0, "Cannot mint 0");
        require((targetMintIndex - 1 + quantity) <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        IOverrideNft(diffusionNftContract).mintBatch(msg.sender, ids);

        emit Minted(msg.sender, quantity);
    }

    function publicFreeMint(uint256 quantity) external nonReentrant callerIsUser {

        require(
        publicFreeMintStartTime != 0 && block.timestamp >= publicFreeMintStartTime,
        "free mint has not started yet"
        );

        uint256 targetMintIndex = currentMintIndex();
        require(targetMintIndex <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1; // 9000 - 1007 - 1
        quantity = quantity < supplyAvailable ? quantity : supplyAvailable;

        require(quantity > 0, "Cannot mint 0");
        require(quantity <= publicFreeAvailable(msg.sender), "addr free limit 5: can not mint this many");

        publicFreeMinted += uint64(quantity);

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        IOverrideNft(diffusionNftContract).mintBatch(msg.sender, ids);

        emit Minted(msg.sender, quantity);
    }

    function currentMintIndex() public view returns (uint256) {
        // Add Final NEON PLEXUS: Override Collection 0xDd782034307ff54C4F0BF2719C9d8e78FCEFDD40
        return totalSupply() + OVERRIDE_TOTAL_SUPPLY + 1;
    }

    function totalSupply() public view returns (uint256) {
        // remaining supply
        return IERC721Enumerable(diffusionNftContract).totalSupply();
    }
}