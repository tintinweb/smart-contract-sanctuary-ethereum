// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Bedu2117Upgradeable.sol";

contract SwapERC721Bedu2117HbtUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Swap contract config params
    uint256 private constant _TOKEN_LIMIT_PER_CLAIM_TRANSACTION = 30;
    address private _erc721Bedu2117CitAddress;
    address private _erc721Bedu2117HbtAddress;

    // Swap contract stats params
    uint256 private _usedCitTokenCount;

    // Mapping for used Cit token ids by addresses
    mapping(uint256 => address) private _usedCitTokenIds;
    // Mapping for received Hbt tokens
    mapping(address => uint256) private _receivedHbtTokens;

    // Auto pause timestamp
    uint256 private _pauseAfterTimestamp;

    // Emitted when `account` claim tokens
    event TokenClaimed(address indexed account, uint256 tokenCount);

    // Emitted when `pauseAfterTimestamp` updated
    event PauseAfterTimestampUpdated(uint256 pauseAfterTimestamp);

    function initialize(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) public virtual initializer {
        __SwapERC721Bedu2117Hbt_init(
            erc721Bedu2117CitAddress_,
            erc721Bedu2117HbtAddress_
        );
    }

    function __SwapERC721Bedu2117Hbt_init(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721Bedu2117Hbt_init_unchained(
            erc721Bedu2117CitAddress_,
            erc721Bedu2117HbtAddress_
        );
    }

    function __SwapERC721Bedu2117Hbt_init_unchained(
        address erc721Bedu2117CitAddress_,
        address erc721Bedu2117HbtAddress_
    ) internal initializer {
        require(erc721Bedu2117CitAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(erc721Bedu2117HbtAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        _erc721Bedu2117CitAddress = erc721Bedu2117CitAddress_;
        _erc721Bedu2117HbtAddress = erc721Bedu2117HbtAddress_;
        _pause();
    }

    function config() external view virtual returns (
        address erc721Bedu2117CitAddress,
        address erc721Bedu2117HbtAddress,
        uint256 tokenLimitPerClaimTransaction,
        uint256 pauseAfterTimestamp,
        uint256 currentTimestamp
    ) {
        return (
            _erc721Bedu2117CitAddress,
            _erc721Bedu2117HbtAddress,
            _TOKEN_LIMIT_PER_CLAIM_TRANSACTION,
            _pauseAfterTimestamp,
            block.timestamp
        );
    }

    function stats() external view virtual returns (uint256 usedCitTokenCount) {
        return _usedCitTokenCount;
    }

    function checkCitTokensUsageAddressesBatch(uint256[] memory citTokenIds_) external view virtual returns (address[] memory citTokenIdUsageAddresses) {
        citTokenIdUsageAddresses = new address[](citTokenIds_.length);
        for (uint256 i = 0; i < citTokenIds_.length; ++i) {
            citTokenIdUsageAddresses[i] = _usedCitTokenIds[citTokenIds_[i]];
        }
        return (
            citTokenIdUsageAddresses
        );
    }

    function receivedHbtTokens(address account_) external view virtual returns (uint256) {
        return _receivedHbtTokens[account_];
    }

    function getHolderCitTokensUsage(address citHolder_) public view virtual returns (uint256[] memory citTokenIds, bool[] memory citTokenIdUsages) {
        require(citHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        uint256 citHolderBalance = IERC721Bedu2117Upgradeable(_erc721Bedu2117CitAddress).balanceOf(citHolder_);
        citTokenIds = new uint256[](citHolderBalance);
        citTokenIdUsages = new bool[](citHolderBalance);
        for (uint256 i = 0; i < citHolderBalance; ++i) {
            citTokenIds[i] = IERC721Bedu2117Upgradeable(_erc721Bedu2117CitAddress).tokenOfOwnerByIndex(citHolder_, i);
            citTokenIdUsages[i] = _usedCitTokenIds[citTokenIds[i]] != address(0);
        }
        return (
            citTokenIds,
            citTokenIdUsages
        );
    }

    function getHolderNotUsedCitTokenIds(address citHolder_, uint256 maxTokenCount_) public view virtual returns (uint256[] memory notUsedCitTokenIds) {
        (uint256[] memory citTokenIds, bool[] memory citTokenIdUsages) = getHolderCitTokensUsage(citHolder_);
        uint256 notUsedCitTokenCount;
        for (uint256 i = 0; i < citTokenIdUsages.length; ++i) {
            notUsedCitTokenCount += citTokenIdUsages[i] ? 0 : 1;
        }
        uint256 tokensToReturn = notUsedCitTokenCount > maxTokenCount_
            ? maxTokenCount_
            : notUsedCitTokenCount;
        notUsedCitTokenIds = new uint256[](tokensToReturn);
        if (tokensToReturn != 0) {
            uint256 notUsedCitTokenIndex;
            for (uint256 i = 0; i < citTokenIdUsages.length; ++i) {
                if (!citTokenIdUsages[i]) {
                    notUsedCitTokenIds[notUsedCitTokenIndex] = citTokenIds[i];
                    notUsedCitTokenIndex++;
                    if (notUsedCitTokenIndex >= tokensToReturn) {
                        break;
                    }
                }
            }
        }
        return notUsedCitTokenIds;
    }

    function checkBeforeClaimByCitHolder(address citHolder_) public view virtual returns (uint256[] memory notUsedCitTokenIds) {
        // validate params
        require(citHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        // check contracts params
        require(!paused(), "SwapERC721Bedu2117: contract is paused");
        (bool mintingEnabled, ,) = IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).getContractWorkModes();
        require(mintingEnabled, "SwapERC721Bedu2117: erc721 minting is disabled");
        require(IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).isTrustedMinter(address(this)), "SwapERC721Bedu2117: erc721 wrong trusted minter");
        notUsedCitTokenIds = getHolderNotUsedCitTokenIds(citHolder_, _TOKEN_LIMIT_PER_CLAIM_TRANSACTION);
        require(notUsedCitTokenIds.length != 0, "SwapERC721Bedu2117: CIT holder has no tokens to use");
        return notUsedCitTokenIds;
    }

    function claimTokensByCitHolder() external virtual nonReentrant whenNotPaused {
        _claimTokensByCitHolder(_msgSender());
    }


    function paused() public view virtual override returns (bool) {
        return (block.timestamp > _pauseAfterTimestamp) || super.paused();
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function setPauseAfterTimestamp(uint256 pauseAfterTimestamp_) external virtual onlyOwner {
        _pauseAfterTimestamp = pauseAfterTimestamp_;
        emit PauseAfterTimestampUpdated(pauseAfterTimestamp_);
    }

    function _claimTokensByCitHolder(address citHolder_) internal virtual {
        // check before claim and get not used cit token ids
        uint256[] memory notUsedCitTokenIds = checkBeforeClaimByCitHolder(citHolder_);
        // update cit tokens usage and calculate tokenCount
        uint256 tokenCount;
        for (uint256 i = 0; i < notUsedCitTokenIds.length; ++i) {
            if (_usedCitTokenIds[notUsedCitTokenIds[i]] == address(0)) {
                _usedCitTokenIds[notUsedCitTokenIds[i]] = citHolder_;
                tokenCount++;
            }
        }
        require(tokenCount != 0, "SwapERC721Bedu2117: no CIT tokens for use");
        // update received tokens
        _receivedHbtTokens[citHolder_] += tokenCount;
        // update stats params
        _usedCitTokenCount += tokenCount;
        // mint HBT tokens
        IERC721Bedu2117Upgradeable(_erc721Bedu2117HbtAddress).mintTokenBatchByTrustedMinter(citHolder_, tokenCount);
        emit TokenClaimed(citHolder_, tokenCount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC721Bedu2117Upgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    // public read methods
    function owner() external view returns (address);
    function getTotalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function defaultURI() external view returns (string memory);
    function mainURI() external view returns (string memory);
    function getContractWorkModes() external view returns (bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled);
    function checkFrozenTokenStatusesBatch(uint256[] memory tokenIds) external view returns (bool[] memory frozenTokenStatuses);
    function isTrustedMinter(address account) external view returns (bool);
    function isTrustedAdmin(address account) external view returns (bool);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    // public write methods
    function burn(uint256 tokenId) external;

    // trusted minter write methods
    function mintTokenBatchByTrustedMinter(address recipient, uint256 tokenCount) external;

    // trusted admin write methods
    function freezeTokenTransferBatchByTrustedAdmin(uint256[] memory tokenIds, bool freeze) external;
    function burnTokenBatchByTrustedAdmin(uint256[] memory tokenIds) external;

    // owner write methods
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function setDefaultURI(string memory uri) external;
    function setMainURI(string memory uri) external;
    function setContractWorkModes(bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled) external;
    function updateTrustedMinterStatus(address account, bool isMinter) external;
    function updateTrustedAdminStatus(address account, bool isAdmin) external;
    function updateRoyaltyParams(address account, uint256 percent) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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