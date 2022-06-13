// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IVoid721.sol";

error CannotExceedPerTransactionCap();
error CannotExceedPerCallerCap();
error CannotExceedPrereleaseCap();
error CannotExceedTotalCap();
error InvalidPaymentAmount();
error WithdrawalFailed();
error MintPhaseNotOpen();
error MerkleProofInvalid();
error TooManyStaffMints();

// mint stages
enum Phase {
    OFF,
    ALLOWLIST,
    FRIENDS,
    PUBLIC
}

/**
  @title Sells NFTs for a flat price, with presales
  @notice This contract encapsulates all minting-related business logic, allowing
          the associated ERC-721 token to focus solely on ownership, metadata,
          and on-chain data storage

  Forked from DropShop721, by the SuperFarm team
  https://etherscan.io/address/ef1CE3D419D281FCBe9941F3b3A81299DD438C20#code

  Heavily upgraded for use by Void Runners
  https://voidrunners.io

  Featuring:

  - immutable shop configuration, set at construction.
    to change minting rules (e.g. lowering price), just deploy another DropShop
  - various minting rules and restrictions:
    - totalCap: limit total # of items this DropShop can createl; distinct from token totalSupply
    - callerCap: a per-address limit; easily avoided, but useful for allowlist/prerelase minting
    - transactionCap: a per-transaction limit, particularly useful for keeping ERC721A batches reasonable
  - withdrawal functions for both Ether and ERC-20 tokens
  - mint() calls our configured Void21 token, which provides privileges to this contract
     a `setAdmin` function and an `onlyAdmin` modifier

  Void Runners extensions to DropShop721:

  - mint phase control, instead of startTime/endTime
  - a merkle-tree-based allowlist, letting defined addresses mint early
  - "friend" contract allowlist, allowing holders of specified contracts to mint early
  - the two prerelease phases above are subject to an aggregate `prereleaseCap`,
    which counts against the buyer's total `callerCap`
  - staff minting, with an immutable `staffCap` maximum
  - removed refunds for excess payments; please only pay exact amount
  - individual requires() have been replaced with modifiers; which are cleaner
    and more composable, but slightly less gas-efficient
  - the custom Tiny721 token has been replaced with an ERC721A-based token, and
    ERC721's storage optimizations are leveraged for supply and `prereleaseCap` tracking
*/
contract DropShop721 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- STORAGE --- //

    /// address of the ERC-721 item being sold.
    address public immutable collection;

    /// maximum number of items from the `collection` that may be sold.
    uint256 public immutable totalCap;

    /// The maximum number of items that a single address may purchase.
    uint256 public immutable callerCap;

    /// The maximum number of items that may be purchased in a single transaction.
    uint256 public immutable transactionCap;

    /// limit number of items that can be purchased per-person during the pre-release window (allowlist/friends)
    uint256 public immutable prereleaseCap;

    /// limit to number of items that can be claimed by the staff
    uint256 public immutable staffCap;

    /// price at which to sell the item
    uint256 public immutable price;

    /// destination of withdrawn payments
    address public immutable paymentDestination;

    /// current phase of the mint; off -> allowlist -> friends -> public
    Phase public mintingPhase;

    /// Merkle tree roots for our two prerelease address lists
    bytes32 public allowlistMerkleRoot;
    bytes32 public friendlistMerkleRoot;

    /// list of other NFT contracts that are allowed to mint early
    mapping(address => bool) public friendContracts;

    /*
    @notice a struct for passing shop configuration details upon contract construction
            this is passed to constructor as a struct to help avoid stack-to-deep errors

    @param totalCap maximum number of items from the `collection` that may be sold.
    @param callerCap maximum number of items that a single address may purchase.
    @param transactionCap maximum number of items that may be purchased in a single transaction.
    @param prereleaseCap maximum number of items that may be purchased during the allowlist and friendlist phases (in aggregate)
    @param staffCap maximum number of items that staff can mint (for free)
    @param price the price for each item, in wei
    @param paymentDestination where to send withdrawals()
  */
    struct ShopConfiguration {
        uint256 totalCap;
        uint256 callerCap;
        uint256 transactionCap;
        uint256 prereleaseCap;
        uint256 staffCap;
        uint256 price;
        address paymentDestination;
    }

    // --- EVENTS --- //

    event MintingPhaseStarted(Phase phase);

    // --- MODIFIERS --- //

    /// @dev forbid minting until the allowed phase
    modifier onlyIfMintingPhaseIsSetToOrAfter(Phase minimumPhase) {
        if (mintingPhase < minimumPhase) revert MintPhaseNotOpen();
        _;
    }

    /// @dev do not allow minting past our totalCap (maxSupply)
    ///      we are re-using our ERC721's token totalMinted() for efficiency,
    ///      but this means DropShop.totalCap is directly tied to the token's totalSupply
    ///      if you want a shop to allow minting 1000, it needs to be "totalSupply + 1000"
    modifier onlyIfSupplyMintable(uint256 amount) {
        if (_totalMinted() + amount > totalCap) revert CannotExceedTotalCap();
        _;
    }

    /// @dev reject purchases that exceed the per-transaction cap.
    modifier onlyIfBelowTransactionCap(uint256 amount) {
        if (amount > transactionCap) {
            revert CannotExceedPerTransactionCap();
        }
        _;
    }

    /// @dev reject purchases that exceed the per-caller cap.
    modifier onlyIfBelowCallerCap(uint256 amount) {
        if (purchaseCounts(_msgSender()) + amount > callerCap) {
            revert CannotExceedPerCallerCap();
        }
        _;
    }

    /// @dev reject purchases that exceed the pre-release (allowlist/friends) per-caller cap.
    modifier onlyIfBelowPrereleaseCap(uint256 amount) {
        if (prereleasePurchases(_msgSender()) + amount > prereleaseCap) {
            revert CannotExceedPrereleaseCap();
        }
        _;
    }

    /// @dev requires msg.value be exactly the specified amount
    modifier onlyIfValidPaymentAmount(uint256 amount) {
        uint256 totalCharge = price * amount;
        if (msg.value != totalCharge) {
            revert InvalidPaymentAmount();
        }
        _;
    }

    /// @notice verify user's merkle proof is correct
    modifier onlyIfValidMerkleProof(
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) {
        if (!_verifyMerkleProof(proof, _msgSender(), merkleRoot)) {
            revert MerkleProofInvalid();
        }
        _;
    }

    // --- SETUP & CONFIGURATION --- //

    /// @notice construct a new shop with details about the intended sale, like price and mintable supply
    /// @param _collection address of the ERC-721 item being sold
    /// @param _configuration shop configuration information, passed as a struct to avoid stack-to-deep errors
    constructor(address _collection, ShopConfiguration memory _configuration) {
        collection = _collection;

        price = _configuration.price;
        totalCap = _configuration.totalCap;
        callerCap = _configuration.callerCap;
        transactionCap = _configuration.transactionCap;
        prereleaseCap = _configuration.prereleaseCap;
        staffCap = _configuration.staffCap;
        paymentDestination = _configuration.paymentDestination;
    }

    /// @notice set the phase of the mint. e.g. closed at first, then allowlist, then public to all
    /// @param _phase which phase to activate; an enum
    function setMintingPhase(Phase _phase) external onlyOwner {
        mintingPhase = _phase;
        emit MintingPhaseStarted(_phase);
    }

    // --- TREASURY MGMNT --- //

    /// @notice allow anyone to send this contract's ETH balance to the (hard-coded) payment destination
    function withdraw() external nonReentrant {
        (bool success, ) = payable(paymentDestination).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    /// @notice allow anyone to claim ERC-20 tokens that might've been sent to this contract, e.g. airdrops (or accidents)
    /// @param _token the token to sweep
    /// @param _amount the amount of token to sweep
    function withdrawTokens(address _token, uint256 _amount)
        external
        nonReentrant
    {
        IERC20(_token).safeTransfer(paymentDestination, _amount);
    }

    // --- SHARED MERKLE-TREE LOGIC --- //

    /// @dev verify a given Merkle proof against a given Merkle tree
    function _verifyMerkleProof(
        bytes32[] calldata proof,
        address sender,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        return
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(sender))
            );
    }

    // --- ALLOWLIST --- //

    /// @notice Test if a given **allowlist** merkle proof is valid for a given sender
    function verifyAllowlistProof(bytes32[] calldata proof, address sender)
        external
        view
        returns (bool)
    {
        return _verifyMerkleProof(proof, sender, allowlistMerkleRoot);
    }

    /// @notice Allows owner to set a merkle root for the Allowlist
    function setAllowlistMerkleRoot(bytes32 newRoot) external onlyOwner {
        allowlistMerkleRoot = newRoot;
    }

    // --- FRIENDLIST --- //

    /// @notice Test if a given **friendlist** merkle proof is valid for a given sender
    function verifyFriendlistProof(bytes32[] calldata proof, address sender)
        external
        view
        returns (bool)
    {
        return _verifyMerkleProof(proof, sender, friendlistMerkleRoot);
    }

    /// @notice Allows owner to set a merkle root for the friendlist
    function setFriendlistMerkleRoot(bytes32 newRoot) external onlyOwner {
        friendlistMerkleRoot = newRoot;
    }

    // --- MINTING --- //

    /// @notice total number of items minted; this is distinct from totalSupply(), which subtracts totalBurned()
    /// @dev in general we try to re-use data stored efficiently in our ERC721A token
    /// @dev this is only used inside one of our modifiers and could be confusing to external users, so we are keeping internal
    function _totalMinted() internal view returns (uint256) {
        return IVoid721(collection).totalMinted();
    }

    /// @notice how many tokens have been minted by given buyer, across all phases?
    function purchaseCounts(address buyer) public view returns (uint256) {
        return IVoid721(collection).numberMinted(buyer);
    }

    /// @notice how many tokens have been minted by given buyer during the prerelease phases? allowlist + friendlist
    function prereleasePurchases(address buyer) public view returns (uint64) {
        return IVoid721(collection).prereleasePurchases(buyer);
    }

    /// @dev update how many tokens a given buyer has bought during allowlist+friendlist period
    function _incrementPrereleasePurchases(address buyer, uint256 amount)
        internal
    {
        uint64 newTotal = prereleasePurchases(buyer) + uint64(amount);
        IVoid721(collection).setPrereleasePurchases(buyer, newTotal);
    }

    /// @dev a shared function for actually minting the specified tokens to the specified recipient
    function _mint(address recipient, uint256 amount)
        internal
        onlyIfSupplyMintable(amount)
        onlyIfBelowTransactionCap(amount)
    {
        IVoid721(collection).mint(recipient, amount);
    }

    /// @notice staff can mint up to staffCap, for free, at any point in the sale
    /// @param amount how many to mint
    function mintStaff(uint256 amount) external onlyOwner nonReentrant {
        if (purchaseCounts(paymentDestination) + amount > staffCap) {
            revert TooManyStaffMints();
        }
        _mint(paymentDestination, amount);
    }

    /// @notice mint NFTs if you're on the allowlist, a manually-curated list of addresses
    /// @param merkleProof a Merkle proof of the caller's address
    /// @param amount how many to mint
    function mintAllowlist(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
        onlyIfMintingPhaseIsSetToOrAfter(Phase.ALLOWLIST)
        onlyIfValidMerkleProof(merkleProof, allowlistMerkleRoot)
        onlyIfBelowPrereleaseCap(amount)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _incrementPrereleasePurchases(_msgSender(), amount);
        _mint(_msgSender(), amount);
    }

    /// @notice mint NFTs if you're on the friendlist, a compilation of owners of friendly NFT contracts
    /// @param merkleProof a Merkle proof of the caller's address
    /// @param amount how many to mint
    function mintFriendlist(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
        onlyIfMintingPhaseIsSetToOrAfter(Phase.FRIENDS)
        onlyIfValidMerkleProof(merkleProof, friendlistMerkleRoot)
        onlyIfBelowPrereleaseCap(amount)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _incrementPrereleasePurchases(_msgSender(), amount);
        _mint(_msgSender(), amount);
    }

    /// @notice mint NFTs during the public sale
    /// @param amount number of tokens to mint
    function mint(uint256 amount)
        public
        payable
        virtual
        onlyIfMintingPhaseIsSetToOrAfter(Phase.PUBLIC)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _mint(_msgSender(), amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVoid721 {
    function allTransfersLocked() external view returns (bool);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function getSecondsSinceLastTransfer(uint256 _id)
        external
        view
        returns (uint256);

    function getSecondsSinceStart() external view returns (uint256);

    function isAdmin(address addressToCheck) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function lockAllTransfers(bool _locked) external;

    function lockTransfer(uint256 _id, bool _locked) external;

    function maxSupply() external view returns (uint256);

    function baseURI() external view returns (string memory);

    function mint(address _recipient, uint256 _amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function royaltyAmount() external view returns (uint16);

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address, uint256);

    function royaltyRecipient() external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setAdmin(address _newAdmin, bool _isAdmin) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory newURI) external;

    function startTime() external view returns (uint256);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalBurned() external view returns (uint256);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferLocks(uint256) external view returns (bool);

    function transferOwnership(address newOwner) external;

    function numberMinted(address buyer) external view returns (uint256);

    function prereleasePurchases(address buyer) external view returns (uint64);

    function setPrereleasePurchases(address buyer, uint64 amount) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}