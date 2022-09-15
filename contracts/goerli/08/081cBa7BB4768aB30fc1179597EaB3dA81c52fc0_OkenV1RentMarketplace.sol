// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/interfaces/IERC4907.sol";
import "./interfaces/IOkenV1RentMarketplace.sol";
import "../utils/OkenV1Errors.sol";

contract OkenV1RentMarketplace is Ownable, ReentrancyGuard, IOkenV1RentMarketplace {
    //--------------------------------- state variables

    // ERC4907 contract address -> token id -> Listing
    mapping(address => mapping(uint256 => Listing)) private _listings;

    // operator address -> token address -> proceeds
    mapping(address => mapping(address => uint256)) private _proceeds;

    // Rent fee, 123 = 1.23%, fee <= 10000
    uint16 private _platformFee;

    // address the platform fees are transferred to
    address payable private _feeRecipient;

    bytes4 private constant ON_ERC721_RECEIVED = 0x150b7a02;
    uint64 private constant MAX_UINT64 = 0xffffffffffffffff;

    //--------------------------------- misc functions

    constructor(uint16 platformFee, address payable feeRecipient) {
        _platformFee = platformFee;
        _feeRecipient = feeRecipient;
    }

    receive() external payable {
        _proceeds[_msgSender()][address(0)] += msg.value;
    }

    fallback() external payable {
        revert InvalidCall(_msgData());
    }

    //--------------------------------- marketplace functions

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    ) external override {
        IERC721 nft = IERC721(nftAddress);
        // require `msg.sender` is owner
        if (nft.ownerOf(tokenId) != _msgSender()) {
            revert NotOwner(_msgSender());
        }
        // require item is not listed
        if (_listings[nftAddress][tokenId].pricePerSecond > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        // require `address(this)` is either approved or approved for all
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(_msgSender(), address(this))
        ) {
            revert NotApproved(nftAddress, tokenId);
        }

        // check `expires`, `pricePerToken`, `payToken`
        _validateListing(expires, MAX_UINT64, pricePerSecond, 1, payToken);

        // modify listing
        _listings[nftAddress][tokenId] = Listing(_msgSender(), expires, pricePerSecond, payToken);
        emit ItemListed(nftAddress, tokenId, _msgSender(), expires, pricePerSecond, payToken);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    ) external override {
        Listing memory listing = _listings[nftAddress][tokenId];
        // require item is listed
        if (listing.pricePerSecond <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        // require `msg.sender` is the address which listed the item
        if (IERC721(nftAddress).ownerOf(tokenId) != _msgSender()) {
            revert NotOwner(_msgSender());
        }

        // check `expires`, `pricePerSecond`, `payToken`
        _validateListing(expires, MAX_UINT64, pricePerSecond, 1, payToken);

        // update listing
        _listings[nftAddress][tokenId] = Listing(_msgSender(), expires, pricePerSecond, payToken);
        emit ListingUpdated(nftAddress, tokenId, _msgSender(), expires, pricePerSecond, payToken);
    }

    // might want to check that the nft owner hasn't changed (possible vulnerability if nft is transferred between listing and renting)
    function rentItem(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        address payToken
    ) external payable override {
        Listing memory listing = _listings[nftAddress][tokenId];
        // require item is listed
        if (listing.pricePerSecond <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        // require item is not currently rented
        if (IERC4907(nftAddress).userOf(tokenId) != address(0)) {
            revert CurrentlyRented(nftAddress, tokenId);
        }

        // compute minimum rent price and platform fees
        uint256 minRentPrice = (expires - block.timestamp + 1) * listing.pricePerSecond;
        uint256 fee = (minRentPrice * uint256(_platformFee)) / 10000;

        // check `expires`, `minRentPrice`, `payToken`
        _validateListing(expires, listing.expires, msg.value, minRentPrice, payToken);

        // transfer rented Nft from owner to `address(this)`
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != address(this)) {
            nft.safeTransferFrom(listing.owner, address(this), tokenId);
        }

        // set user to rent Nft
        IERC4907(nftAddress).setUser(tokenId, _msgSender(), expires);

        // update proceeds
        _proceeds[_feeRecipient][payToken] += fee;
        _proceeds[listing.owner][payToken] += msg.value - fee;

        emit ItemRented(
            nftAddress,
            tokenId,
            listing.owner,
            _msgSender(),
            expires,
            msg.value,
            listing.payToken
        );
    }

    function redeemItem(address nftAddress, uint256 tokenId) external override {
        // require item is not currently rented
        if (IERC4907(nftAddress).userOf(tokenId) != address(0)) {
            revert CurrentlyRented(nftAddress, tokenId);
        }
        // require sender is owner
        address owner = _listings[nftAddress][tokenId].owner;
        if (owner != _msgSender()) {
            revert NotOwner(_msgSender());
        }
        // require item has been rented (so address(this) is owner)
        if (IERC721(nftAddress).ownerOf(tokenId) != address(this)) {
            revert NotRedeemable(nftAddress, tokenId);
        }

        IERC721(nftAddress).transferFrom(address(this), owner, tokenId);
        emit ItemRedeemed(nftAddress, tokenId, owner);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external override {
        // require item is not currently rented
        if (IERC4907(nftAddress).userOf(tokenId) != address(0)) {
            revert CurrentlyRented(nftAddress, tokenId);
        }
        // require `msg.sender` is owner
        if (IERC721(nftAddress).ownerOf(tokenId) != _msgSender()) {
            revert NotOwner(_msgSender());
        }
        // require item is listed
        if (_listings[nftAddress][tokenId].pricePerSecond <= 0) {
            revert NotListed(nftAddress, tokenId);
        }

        delete (_listings[nftAddress][tokenId]);
        emit ListingCanceled(nftAddress, tokenId, _msgSender());
    }

    /*
    function withdrawProceeds(address token) external override {
        // check if there are proceeds
        uint256 proceeds = _proceeds[_msgSender()][token];
        if (proceeds <= 0) {
            revert NoProceeds(_msgSender(), token);
        }

        // set proceeds to zero
        delete (_proceeds[_msgSender()][token]);

        // transfer balance and verify
        if (token == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: proceeds}("");
            if (!success) revert TransferFailed();
        } else {
            bool success = IERC20(token).transferFrom(address(this), _msgSender(), proceeds);
            if (!success) revert TransferFailed();
        }
        emit ProceedsWithdrawn(_msgSender(), token, proceeds);
    }
    */

    /// @notice Handle the receipt of an Nft
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The Nft identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        return ON_ERC721_RECEIVED;
    }

    //--------------------------------- internal functions

    function _validateListing(
        uint64 expires,
        uint64 maxExpires,
        uint256 price,
        uint256 minPrice,
        address payToken
    ) internal view {
        // require `expires` now or in the future and smaller than or equal to maximum
        if ((expires < block.timestamp) || (expires > maxExpires)) {
            revert InvalidExpires(expires);
        }
        // require `price` is larger than or equal to minimum
        if (price < minPrice) {
            revert InvalidAmount(price);
        }
        // require pay token is valid
        if (payToken != address(0)) {
            revert InvalidPayToken(payToken);
        }
    }

    //--------------------------------- accessors

    function getFeeRecipient() external view override returns (address) {
        return _feeRecipient;
    }

    function setFeeRecipient(address payable newFeeRecipient) external override onlyOwner {
        _feeRecipient = newFeeRecipient;
    }

    function getPlatformFee() external view override returns (uint16) {
        return _platformFee;
    }

    function setPlatformFee(uint16 newPlatformFee) external override onlyOwner {
        _platformFee = newPlatformFee;
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        override
        returns (Listing memory)
    {
        return _listings[nftAddress][tokenId];
    }

    function getProceeds(address operator, address payToken)
        external
        view
        override
        returns (uint256)
    {
        return _proceeds[operator][payToken];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an Nft or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a Nft
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid Nft
    /// @param user  The new user of the Nft
    /// @param expires  UNIX timestamp, The new user could use the Nft before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /// @notice Get the user address of an Nft
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The Nft to get the user address for
    /// @return The user address for this Nft
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an Nft
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The Nft to get the user expires for
    /// @return The user expires for this Nft
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title List and rent ERC4907 NFTs
interface IOkenV1RentMarketplace is IERC721Receiver {
    //--------------------------------- types

    struct Listing {
        // item owner
        address owner;
        // Rent time limit, given by `block.timestamp`
        uint64 expires;
        // Minimum rent price per second
        uint256 pricePerSecond;
        // ERC20 token used to pay for rent
        address payToken;
    }

    //--------------------------------- events

    /// @notice Emitted when a new item is listed
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the listed NFT
    /// @param owner Owner of the NFT
    /// @param expires Rent time limit, given by `block.timestamp`
    /// @param pricePerSecond Minimum rent price per second
    /// @param payToken ERC20 token used to pay for rent
    event ItemListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    );

    /// @notice Emitted when an existing item listing is modified
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the listed NFT
    /// @param owner Owner of the NFT
    /// @param expires Rent time limit, given by `block.timestamp`
    /// @param pricePerSecond Minimum rent price per second
    /// @param payToken ERC20 token used to pay for rent
    event ListingUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    );

    /// @notice Emitted when an item is rented
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the listed NFT
    /// @param lessor Item owner
    /// @param renter Item renter
    /// @param expires Time until which the item is rented, given by `block.timestamp`
    /// @param pricePaid Rent price + platform fee
    /// @param payToken ERC20 token used to pay for rent
    event ItemRented(
        address indexed nftAddress,
        uint256 tokenId,
        address indexed lessor,
        address indexed renter,
        uint64 expires,
        uint256 pricePaid,
        address payToken
    );

    /// @notice Emitted when an item has been transferred from `address(this)` to the original owner
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the listed NFT
    /// @param owner Owner of the NFT
    event ItemRedeemed(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);

    /// @notice Emitted when an item listing is deleted
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the listed NFT
    /// @param owner Owner of the NFT
    event ListingCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner
    );

    /*
    /// @notice Emitted when proceeds are withdrawn
    /// @param operator Address withdrawing their proceeds
    /// @param payToken ERC20 the proceeds are withdrawn in
    /// @param proceeds Proceeds amount withdrawn
    event ProceedsWithdrawn(address indexed operator, address indexed payToken, uint256 proceeds);
    */

    //--------------------------------- marketplace functions

    /// @notice List a ERC4907 NFT for rent
    /// @dev `msg.sender` must be the NFT owner. The transaction will revert if a listing already exists for this item.
    /// @param nftAddress Address of the ERC4907 contract. The contract must implement the ERC4907 and ERC721 interfaces.
    /// @param tokenId Token ID of the NFT. `address(this)` must either be approved or approved for all.
    /// @param expires Rent time limit, given by `block.timestamp`. This value must be larger or equal to `block.timestamp`.
    /// @param pricePerSecond Rent price per second. This value cannot be zero.
    /// @param payToken ERC20 token used to pay rent price. The token must be authorized by `OkenV1TokenRegistry`
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    ) external;

    /// @notice Updates an item listing
    /// @dev The item must already be listed.
    /// @dev `msg.sender` and the address which originally listed the NFT must be equal.
    /// @param nftAddress Address of the ERC4907 contract.
    /// @param tokenId Token ID of the NFT.
    /// @param expires Rent time limit, given by `block.timestamp`. This value must be larger or equal to `block.timestamp`.
    /// @param pricePerSecond Rent price per second. This value cannot be zero.
    /// @param payToken ERC20 token used to pay rent price. The token must be authorized by `OkenV1TokenRegistry`
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        uint256 pricePerSecond,
        address payToken
    ) external;

    /// @notice Rent a NFT
    /// @dev The NFT must be listed and must not already be rented.
    /// @param nftAddress Address of the ERC4907 contract
    /// @param tokenId Token ID of the NFT
    /// @param expires Rental expiry time, given by `block.timestamp`
    /// @param payToken ERC20 token used to pay for rent
    function rentItem(
        address nftAddress,
        uint256 tokenId,
        uint64 expires,
        address payToken
    ) external payable;

    function redeemItem(address nftAddress, uint256 tokenId) external;

    function cancelListing(address nftAddress, uint256 tokenId) external;

    /*
    function withdrawProceeds(address token) external;
    */

    //--------------------------------- accessors

    function getFeeRecipient() external view returns (address);

    function setFeeRecipient(address payable newFeeRecipient) external;

    function getPlatformFee() external view returns (uint16);

    function setPlatformFee(uint16 newFee) external;

    /// @return Item listing
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory);

    /// @return Proceeds of `addr`
    function getProceeds(address operator, address currency) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//------------------------------------- ETH transfer

/// @dev Thrown when not enough ETH is transferred
error InsufficientFunds(uint256 expected, uint256 actual);

/// @dev Thrown if `address.call{value: value}("")` returns false
error TransferFailed();

error InvalidCall(bytes data);

//------------------------------------- Nft

/// @dev Thrown if token ID does NOT exist
error NotExists(uint256 tokenId);

error NotOwner(address operator);

error NotApproved(address nftAddress, uint256 tokenId);

/// @dev Thrown if `operator` is neither owner nor approved for token ID nor approved for all
error NotOwnerNorApproved(address operator);

error InvalidNftAddress(address nftAddress);

error ContractAlreadyExists(address nftAddress);

error ContractNotExists(address nftAddress);

//------------------------------------- Marketplace

error NotListed(address nftAddress, uint256 tokenId);

error AlreadyListed(address nftAddress, uint256 tokenId);

error CurrentlyRented(address nftAddress, uint256 tokenId);

error InvalidExpires(uint64 expires);

error InvalidAmount(uint256 price);

error InvalidPayToken(address payToken);

error NoProceeds(address operator, address token);

error NotRedeemable(address nftAddress, uint256 tokenId);

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}