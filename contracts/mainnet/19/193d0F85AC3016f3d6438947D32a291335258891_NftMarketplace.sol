// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMarketplace is Ownable, ReentrancyGuard, Pausable {

    struct Asset {
        address collection;
        uint16[] ids;
        uint8 quantity;
    }

    enum Status {
        COMPLETED, CREATED, DELETED
    }

    struct Swap {
        address maker;
        mapping(address => uint16[]) assets;
        address[] assetsAddresses;
        mapping(address => uint8) quantity;
        mapping(address => uint16[]) requiredIds;
        address receiver;
        Status status;
    }

    struct Fees {
        uint swapFeePerNft;
        uint offerFee;
        uint swapFee;
    }

    Swap[] private swaps;
    Fees public fees;
    mapping(address => bool) allowedCollections;

    uint8 constant MAX_ASSET_SIZE = 3;
    uint8 constant MAX_QUANTITY = 10;

    event SwapCreated(uint id, address maker, Asset[] assets, Asset[] wantedAssets, address receiver, Status status);
    event SwapDeleted(uint id);
    event SwapCompleted(uint id);

    function create(Asset[] memory assets, Asset[] memory wantedAssets, address receiver) external whenNotPaused payable {
        require(msg.value >= fees.offerFee);
        validateInput(assets, wantedAssets, receiver, msg.sender);

        Swap storage swap = swaps.push();
        swap.maker = msg.sender;
        swap.receiver = receiver;

        address[] memory addresses = new address[](assets.length);
        for (uint8 i = 0; i < assets.length; i++) {
            Asset memory asset = assets[i];
            validateAsset(asset);
            for (uint8 j = 0; j < asset.ids.length; j++) {
                require(IERC721(asset.collection).ownerOf(asset.ids[j]) == msg.sender);
            }
            require(swap.assets[asset.collection].length == 0);
            swap.assets[asset.collection] = asset.ids;
            addresses[i] = asset.collection;
        }
        swap.assetsAddresses = addresses;

        for (uint8 i = 0; i < wantedAssets.length; i++) {
            Asset memory wantedAsset = wantedAssets[i];
            validateWantedAsset(wantedAsset);
            require(swap.quantity[wantedAsset.collection] == 0);
            swap.requiredIds[wantedAsset.collection] = wantedAsset.ids;
            swap.quantity[wantedAsset.collection] = wantedAsset.quantity;
        }
        swap.status = Status.CREATED;
        emit SwapCreated(swaps.length - 1, msg.sender, assets, wantedAssets, receiver, Status.CREATED);
    }

    function validateInput(Asset[] memory assets, Asset[] memory wantedAssets, address receiver, address sender) internal pure {
        require(receiver != sender);
        require(assets.length > 0 && assets.length <= MAX_ASSET_SIZE);
        require(wantedAssets.length > 0 && wantedAssets.length <= MAX_ASSET_SIZE);
    }

    function validateAsset(Asset memory asset) internal view {
        require(!ArrayUtils.hasDuplicate(asset.ids));
        require(asset.ids.length > 0 && asset.ids.length <= MAX_QUANTITY);
        require(isAllowedCollection(asset.collection));
    }

    function validateWantedAsset(Asset memory asset) internal view {
        require(asset.quantity > 0 && asset.quantity <= MAX_QUANTITY && asset.quantity >= asset.ids.length);
        require(!ArrayUtils.hasDuplicate(asset.ids));
        require(isAllowedCollection(asset.collection));
    }

    function isAllowedCollection(address collection) internal view returns (bool) {
        return allowedCollections[collection] == true;
    }

    function execute(uint swapId, Asset[] memory assets) public nonReentrant whenNotPaused payable {
        Swap storage swap = swaps[swapId];
        validateSender(msg.sender, swap.receiver);

        require(swap.status == Status.CREATED);
        require(swap.maker != msg.sender);

        uint nftCounter = 0;
        for (uint8 i = 0; i < assets.length; i++) {
            sendWantedAsset(assets[i], swap.requiredIds[assets[i].collection], swap.quantity[assets[i].collection], msg.sender, swap.maker);
            nftCounter = nftCounter + assets[i].ids.length;
        }

        for (uint8 i = 0; i < swap.assetsAddresses.length; i++) {
            address collectionAddress = swap.assetsAddresses[i];
            uint16[] memory ids = swap.assets[collectionAddress];
            for (uint8 j = 0; j < ids.length; j++) {
                IERC721(collectionAddress).safeTransferFrom(swap.maker, msg.sender, ids[j]);
            }
            nftCounter = nftCounter + ids.length;
        }
        require(msg.value >= nftCounter * fees.swapFeePerNft + fees.swapFee);
        swap.status = Status.COMPLETED;
        emit SwapCompleted(swapId);
    }

    function sendWantedAsset(Asset memory asset, uint16[] memory requiredIds, uint8 quantity, address from, address to) internal {
        require(quantity == asset.ids.length && quantity > 0);
        uint requiredIdsCount = 0;
        for (uint8 i = 0; i < asset.ids.length; i++) {
            if (ArrayUtils.contains(requiredIds, asset.ids[i])) {
                requiredIdsCount++;
            }
            IERC721(asset.collection).safeTransferFrom(from, to, asset.ids[i]);
        }
        require(requiredIdsCount == requiredIds.length);
    }

    function validateSender(address sender, address receiver) internal pure {
        bool receiverIsValid = true;
        if (receiver != address(0)) {
            receiverIsValid = sender == receiver;
        }
        require(receiverIsValid);
    }

    function deleteSwap(uint swapId) public whenNotPaused {
        Swap storage swap = swaps[swapId];
        require(swap.status == Status.CREATED);
        require(swap.maker == msg.sender);
        swap.status = Status.DELETED;

        emit SwapDeleted(swapId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function withdrawNft(address collection, uint id) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);
    }

    function addAllowedCollections(address[] memory collections) external onlyOwner {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = true;
        }
    }

    function removeAllowedCollections(address[] memory collections) external onlyOwner {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = false;
        }
    }

    function setFees(Fees memory newFees) external onlyOwner {
        fees = newFees;
    }

    constructor(address[] memory collections, Fees memory initialFees) {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = true;
        }
        fees = initialFees;
    }

    function withdraw() external onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

}

library ArrayUtils {

    function hasDuplicate(uint16[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint16 i = 0; i < A.length - 1; i++) {
            for (uint16 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function contains(uint16[] memory A, uint16 a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    function indexOf(uint16[] memory A, uint16 a) private pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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