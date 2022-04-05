// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/INonFungibleOriginationPool.sol";
import "./interface/INonFungibleToken.sol";

contract NonFungibleOriginationPool is
    INonFungibleOriginationPool,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    //--------------------------------------------------------------------------
    // Constants
    //--------------------------------------------------------------------------
    uint256 constant TIME_PRECISION = 1e10;

    // address with manager capabilities
    address public manager;
    // the fee owed to the origination core when purchasing tokens (ex: 1e16 = 1% fee)
    uint256 public originationFee;
    // the origination core contract
    IOriginationCore private originationCore;
    // the erc-721 compatible nft being sold
    INonFungibleToken public nft;
    // max total mintable supply
    uint256 public maxTotalMintable;
    // max mintable nfts per address
    uint256 public maxMintablePerAddress;
    // max mintable nfts per whitelisted address
    uint256 public maxWhitelistMintable;
    // the sale starting price (in purchase token amount) - [whitelistStartingPrice, publicStartingPrice]
    uint256[] public startingPrices;
    // the sale ending price (in purchase token amount) - [whitelistEndingPrice, publicEndingPrice]
    uint256[] public endingPrices;
    // whitelist sale duration
    uint256 public whitelistSaleDuration;
    // public sale duration
    uint256 public publicSaleDuration;
    // total sale duration (in seconds)
    uint256 public saleDuration;
    // the whitelist data
    Whitelist public whitelist;

    // true if sale has started, false otherwise
    bool public saleInitiated;
    // the timestamp of the beginning of the sale
    uint256 public saleInitiatedTimestamp;
    // the timestamp of the end of the sale
    uint256 public saleEndTimestamp;

    mapping(address => uint256) userMints;

    // total mint count
    uint256 public totalMints;
    // whitelist mint count
    uint256 public whitelistMints;

    //--------------------------------------------------------------------------
    // Events
    //--------------------------------------------------------------------------

    event InitiateSale(uint256 saleInitiatedTimestamp);

    //--------------------------------------------------------------------------
    // Modifiers
    //--------------------------------------------------------------------------

    modifier onlyOwnerOrManager() {
        require(isOwnerOrManager(msg.sender), "Not owner or manager");
        _;
    }

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    function initialize(
        uint256 _originationFee,
        IOriginationCore _originationCore,
        address _admin,
        SaleParams calldata _saleParams
    ) external override initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        originationFee = _originationFee;
        originationCore = _originationCore;

        nft = INonFungibleToken(_saleParams.collection);

        maxTotalMintable = _saleParams.maxTotalMintable;
        maxMintablePerAddress = _saleParams.maxMintablePerAddress;
        maxWhitelistMintable = _saleParams.maxWhitelistMintable;

        startingPrices = _saleParams.startingPrices;
        endingPrices = _saleParams.endingPrices;

        whitelistSaleDuration = _saleParams.whitelistSaleDuration;
        publicSaleDuration = _saleParams.publicSaleDuration;

        _transferOwnership(_admin);
    }

    //--------------------------------------------------------------------------
    // Investor Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Purchases the offer token with a contribution amount of purchase tokens
     * @dev If purchasing with ETH, contribution amount must equal ETH sent
     *
     * @param _quantityToMint Number of NFTs to mint
     * @param _merkleProof The merkle proof associated with msg.sender to prove whitelisted
     */
    function whitelistMint(uint256 _quantityToMint, bytes32[] calldata _merkleProof) external payable {
        require(isWhitelistMintPeriod(), "Not whitelist period");

        address sender = msg.sender;
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        require(MerkleProof.verify(_merkleProof, whitelist.whitelistMerkleRoot, leaf), "Address not whitelisted");

        require(whitelistMints + _quantityToMint <= maxWhitelistMintable, "Exceeds whitelist supply");
        whitelistMints += _quantityToMint;

        _mint(_quantityToMint, sender);
    }

    function publicMint(uint256 _quantityToMint) external payable {
        require(isPublicMintPeriod(), "Not public mint period");

        _mint(_quantityToMint, msg.sender);
    }

    // TODO: make compatible with erc20 payment too
    function _mint(uint256 _quantityToMint, address _minter) private nonReentrant {
        require(saleInitiated, "Sale not initiated");

        require(userMints[_minter] + _quantityToMint <= maxMintablePerAddress, "User mint cap reached");
        userMints[_minter] += _quantityToMint;

        require(totalMints + _quantityToMint <= maxTotalMintable, "Total mint cap reached");
        totalMints += _quantityToMint;

        // calc price, return some eth if necessary
        // (in the case of ascending price auction, FE should send a little bit too much ETH to ensure tx succeeds)
        // problem above will not be an issue with erc20 payment
        uint256 currentMintPrice = getCurrentMintPrice();
        uint256 ethOwable = _quantityToMint * currentMintPrice;
        require(msg.value >= ethOwable, "Insufficient payment");

        uint256 amountToReturn = msg.value - ethOwable;
        if (amountToReturn > 0) {
            (bool success, ) = payable(_minter).call{ value: amountToReturn }("");
            require(success);
        }

        nft.mintTo(_minter, _quantityToMint);
    }

    //--------------------------------------------------------------------------
    // Admin Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Admin function to set a whitelist
     *
     * @param _whitelist The whitelist
     */
    function setWhitelist(Whitelist calldata _whitelist) external onlyOwnerOrManager {
        require(!saleInitiated, "Cannot set whitelist after sale initiated");

        whitelist = _whitelist;
    }

    /**
     * @dev Admin function used to initiate the sale
     * @dev Function will transfer the total offer tokens from admin to contract
     */
    // TODO: add manager functionality
    function initiateSale() external onlyOwnerOrManager {
        require(!saleInitiated, "Sale already initiated");

        saleInitiated = true;
        saleInitiatedTimestamp = block.timestamp;
        saleEndTimestamp = saleInitiatedTimestamp + saleDuration;

        emit InitiateSale(saleInitiatedTimestamp);
    }

    //--------------------------------------------------------------------------
    // View Functions
    //--------------------------------------------------------------------------

    function getCurrentMintPrice() public view returns (uint256) {
        require(isWhitelistMintPeriod() || isPublicMintPeriod(), "Inactive sale");
        uint256 timeElapsed = block.timestamp - saleInitiatedTimestamp;

        uint256 periodStartingPrice = isWhitelistMintPeriod() ? startingPrices[0] : startingPrices[1];
        uint256 periodEndingPrice = isWhitelistMintPeriod() ? endingPrices[0] : endingPrices[1];

        uint256 saleRange = periodStartingPrice < periodEndingPrice
            ? periodEndingPrice - periodStartingPrice
            : periodStartingPrice - periodEndingPrice;
        uint256 saleCompletionRatio = (saleDuration * TIME_PRECISION) / timeElapsed;
        uint256 saleDelta = (saleRange * TIME_PRECISION) / saleCompletionRatio;
    }

    function isWhitelistMintPeriod() public view returns (bool) {
        return
            block.timestamp > saleInitiatedTimestamp &&
            block.timestamp <= (saleInitiatedTimestamp + whitelistSaleDuration);
    }

    function isPublicMintPeriod() public view returns (bool) {
        uint256 blockTimestamp = block.timestamp;
        uint256 endOfWhitelistPeriod = blockTimestamp + whitelistSaleDuration;
        return blockTimestamp > endOfWhitelistPeriod && blockTimestamp <= (endOfWhitelistPeriod + publicSaleDuration);
    }

    /**
     * @dev Checks to see if address is an admin (owner or manager)
     *
     * @param _address The address of verify
     * @return True if owner of manager, false otherwise
     */
    function isOwnerOrManager(address _address) public view returns (bool) {
        return _address == owner() || _address == manager;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IOriginationCore.sol";

interface INonFungibleOriginationPool {
    struct Whitelist {
        bool enabled; // if disabled, the merkle root and purchase cap values are ignored
        bytes32 whitelistMerkleRoot; // the merkle root used to determine if an address is whitelisted
        uint256 purchaseCap; // the max amount of tokens an address can purchase
    }

    struct SaleParams {
        // the 721 NFT contract to mint
        address collection;
        // max supply mintable via Origination (maxWhitelistMint + implicit public sale mint)
        uint256 maxTotalMintable;
        // maximum a single address can mint
        uint256 maxMintablePerAddress;
        // max supply reserved for minters during whitelist period
        uint256 maxWhitelistMintable;
        // [whitelistStartingPrice, publicStartingPrice]
        uint256[] startingPrices;
        // [whitelistEndingPrice, publicEndingPrice]
        uint256[] endingPrices;
        // the whitelist sale duration
        uint256 whitelistSaleDuration;
        // the public sale duration
        uint256 publicSaleDuration;
    }

    struct VestingEntry {
        address user; // the user's address with the vesting position
        uint256 offerTokenAmount; // the total vesting position amount
        uint256 offerTokenAmountClaimed; // the amount of tokens claimed so far
    }

    function initialize(
        uint256 originationFee,
        IOriginationCore core,
        address admin,
        SaleParams calldata saleParams
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INonFungibleToken is IERC721 {
    function mintTo(address minter, uint256 quantityToMint) external;

    function setOriginationInstance(address instance) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IOriginationCore {
    function receiveFees() external payable;
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