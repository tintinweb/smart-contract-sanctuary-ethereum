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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity 0.8.9;

import "./IAdventureApproval.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title DarkSpiritCustodian
 * @author Limit Break, Inc.
 * @notice Holds dark spirit and dark hero spirit tokens that are currently on potion crafting quest.
 */
contract DarkSpiritCustodian {

    /// @dev Specify the potion crafting adventure, dark spririt, and dark hero spirit token contract addresses during creation
    constructor(address potionCraftingAdventure, address darkSpiritsAddress, address darkHeroSpiritsAddress) {
        IERC721(darkSpiritsAddress).setApprovalForAll(potionCraftingAdventure, true);
        IERC721(darkHeroSpiritsAddress).setApprovalForAll(potionCraftingAdventure, true);
        IAdventureApproval(darkSpiritsAddress).setAdventuresApprovedForAll(potionCraftingAdventure, true);
        IAdventureApproval(darkHeroSpiritsAddress).setAdventuresApprovedForAll(potionCraftingAdventure, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAdventureApproval {
    function setAdventuresApprovedForAll(address operator, bool approved) external;
    function areAdventuresApprovedForAll(address owner, address operator) external view returns (bool);
    function isAdventureWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface of mintable potion contracts.
 */
interface IMintablePotion {

    /**
     * @notice Mints multiple potions crafted with the specified dark spirit token ids and dark hero spirit token ids
     */
    function mintPotionsBatch(address to, uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface to determine if a minter is whitelisted
 */
interface IMinterWhitelist {
    /**
     * @notice Determines if an address is a whitelisted minter
     */
    function whitelistedMinters(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventureApproval.sol";
import "./IMintablePotion.sol";
import "./IMinterWhitelist.sol";
import "./DarkSpiritCustodian.sol";
import "limit-break-contracts/contracts/adventures/IAdventure.sol";
import "limit-break-contracts/contracts/adventures/IAdventurousERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CallbackNotImplemented();
error CallerDidNotCreateClaimId();
error CallerNotOwnerOfDarkSpirit();
error CallerNotOwnerOfDarkHeroSpirit();
error CannotExceedOneThousandQueriesPerCall();
error CannotSpecifyZeroAddressForDarkSpiritsContract();
error CannotSpecifyZeroAddressForDarkHeroSpiritsContract();
error CannotSpecifyZeroAddressForVillainPotionContract();
error CannotSpecifyZeroAddressForSuperVillainPotionContract();
error ClaimIdOverflow();
error CompleteQuestToRedeemPotion();
error InputArrayLengthMismatch();
error MustIncludeAtLeastOneSpirit();
error NoPotionQuestFoundForSpecifiedClaimId();
error QuantityMustBeGreaterThanZero();
error QuestCompletePotionMustBeRedeemed();

/**
 * @title PotionCraftingAdventure
 * @author Limit Break, Inc.
 * @notice An adventure that burns crafted spirits into potions.
 */
contract PotionCraftingAdventure is Ownable, Pausable, ERC165, IAdventure {

    struct PotionQuest {
        uint64 startTimestamp;
        uint16 darkSpiritTokenId;
        uint16 darkHeroSpiritTokenId;
        address adventurer;
    }

    /// @dev The amount of time the user must remain in the quest to complete it and receive a hero
    uint256 public constant CRAFTING_DURATION = 7 days;

    /// @dev An unchangeable reference to the villain potion contract that is rewarded at the conclusion of adventure quest if a single dark spirit was used
    IMintablePotion immutable public villainPotionContract;

    /// @dev An unchangeable reference to the super villain potion contract that is rewarded at the conclusion of adventure quest if two dark spirits were used
    IMintablePotion immutable public superVillainPotionContract;

    /// @dev An unchangeable reference to the dark spirit token contract
    IAdventurousERC721 immutable public darkSpiritsContract;

    /// @dev An unchangeable reference to the dark hero spirit token contract
    IAdventurousERC721 immutable public darkHeroSpiritsContract;

    /// @dev An unchangeable reference to a custodial holding contract for dark spirits
    DarkSpiritCustodian immutable public custodian;

    /// @dev A counter for claim ids
    uint256 public lastClaimId;

    /// @dev Map claim id to potion quest details
    mapping (uint256 => PotionQuest) public potionQuestLookup;

    /// @dev Emitted when an adventurer abandons/cancels a potion currently being crafted
    event AbandonedPotion(address indexed adventurer, uint256 indexed claimId);

    /// @dev Emitted when an adventurer starts crafting a potion
    event CraftingPotion(address indexed adventurer, uint256 indexed claimId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId);

    /// @dev Emitted when an adventurer redeems a crafted a potion
    event CraftedPotion(address indexed adventurer, uint256 indexed claimId);

    /// @dev Specify the potion, dark spririt, and dark hero spirit token contract addresses during creation
    constructor(address villainPotionAddress, address superVillainPotionAddress, address darkSpiritsAddress, address darkHeroSpiritsAddress) {
        if(villainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForVillainPotionContract();
        }

        if(superVillainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForSuperVillainPotionContract();
        }

        if(darkSpiritsAddress == address(0)) {
            revert CannotSpecifyZeroAddressForDarkSpiritsContract();
        }

        if(darkHeroSpiritsAddress == address(0)) {
            revert CannotSpecifyZeroAddressForDarkHeroSpiritsContract();
        }

        villainPotionContract = IMintablePotion(villainPotionAddress);
        superVillainPotionContract = IMintablePotion(superVillainPotionAddress);
        darkSpiritsContract = IAdventurousERC721(darkSpiritsAddress);
        darkHeroSpiritsContract = IAdventurousERC721(darkHeroSpiritsAddress);

        custodian = new DarkSpiritCustodian(address(this), darkSpiritsAddress, darkHeroSpiritsAddress);
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases quest entry for this adventure is fulfilled via adventureTransferFrom instead of enterQuest, and this callback should not be triggered.
    function onQuestEntered(address /*adventurer*/, uint256 /*tokenId*/, uint256 /*questId*/) external override pure {
        revert CallbackNotImplemented();
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases quest exit for this adventure is fulfilled via transferFrom or adventureBurn instead of exitQuest, and this callback should not be triggered.
    function onQuestExited(address /*adventurer*/, uint256 /*tokenId*/, uint256 /*questId*/, uint256 /*questStartTimestamp*/) external override pure {
        revert CallbackNotImplemented();
    }

    /// @dev Returns false - spirits are transferred into this contract for crafting
    function questsLockTokens() external override pure returns (bool) {
        return false;
    }

    /// @dev Pauses and blocks adventurers from starting new potion crafting quests
    /// Throws if the adventure is already paused
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses and allows adventurers to start new potion crafting quests
    /// Throws if the adventure is already unpaused
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /// @notice Enters the potion crafting quests with a batch of specified dark spirits and dark hero spirits.
    /// Dark spirit token ids may be 0, in which case it means no dark spirit will be included in the potion.
    /// Dark hero spirit token ids may be 0, in which case it means no dark hero spirit will be included in the potion.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the token id arrays.
    /// Throws when token id array lengths don't match.
    /// Throws when the caller does not own a specified dark spirit token.
    /// Throws when the caller does not own a specified dark hero spirit token.
    /// Throws when neither a dark spirit or dark hero spirit token are specified (0 values for both ids at the same array index).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for dark spirit or dark hero spirit contract.
    ///   - The caller has not set adventure approval for this contract.
    /// /// Throws when the contract is paused
    ///
    /// Postconditions:
    /// ---------------
    /// The specified dark spirits are now owned by this contract.
    /// The specified dark hero spirits are now owned by this contract.
    /// The value of the lastClaimId counter has increased by `quantity`, where `quantity` is the length of the token id arrays.
    /// The potion quest lookup for the newly created claim ids contains the following information:
    ///   - The block timestamp of this transaction (the time at which crafting the potion began).
    ///   - The specified dark spirit token id.
    ///   - The specified dark hero spirit token id.
    ///   - The address of the adventurer that is permitted to retrieve their spirits or redeem their potion.
    /// `quantity` CraftingPotion events have been emitted, where `quantity` is the length of the token id arrays.
    function startCraftingPotionsBatch(uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external whenNotPaused {
        if(darkSpiritTokenIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        if(darkHeroSpiritTokenIds.length != darkSpiritTokenIds.length) {
            revert InputArrayLengthMismatch();
        }

        uint256 claimId;
        unchecked {
            claimId = lastClaimId;
            lastClaimId = claimId + darkSpiritTokenIds.length;
            ++claimId;
        }

        for(uint256 i = 0; i < darkSpiritTokenIds.length;) {
            _startCraftingPotion(claimId + i, darkSpiritTokenIds[i], darkHeroSpiritTokenIds[i]);
            
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Abandons multiple potion crafting quests referenced by the specifed claim ids before the required crafting duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no potion quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim id (adventurer not the same as caller).
    /// Throws when the one or more of the potions are ready to redeem (required crafting duration has been met or exceeded).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft the potions have been returned to the adventurer that started crafting with them.
    /// The potion quest lookup entry for the specified claim ids have been removed.
    /// `quantity` AbandonedPotion events have been emitted, where `quantity` is the length of the claim id array.
    function abandonPotionsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        for(uint256 i = 0; i < claimIds.length;) {
            _abandonPotion(claimIds[i]);
            
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Redeems multiple crafted potions referenced by the specifed claim ids after the required crafting duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no potion quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim ids (adventurer not the same as caller).
    /// Throws when one or more of the potions is not ready to redeem (required crafting duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been burned.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// A potion has been minted to the adventurer who crafted the potion.
    /// `quantity` CraftedPotion events have been emitted, where `quantity` is the length of the claim id arrays.
    function redeemPotionsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        uint256[] memory darkSpiritTokenIds = new uint256[](claimIds.length);
        uint256[] memory darkHeroSpiritTokenIds = new uint256[](claimIds.length);

        uint256 numVillainPotions = 0;
        uint256 numSuperVillainPotions = 0;

        for(uint256 i = 0; i < claimIds.length;) {
            (uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId) = _redeemPotion(claimIds[i]);
            darkSpiritTokenIds[i] = darkSpiritTokenId;
            darkHeroSpiritTokenIds[i] = darkHeroSpiritTokenId;
            
            unchecked {
                ++i;

                if(darkSpiritTokenId == 0 || darkHeroSpiritTokenId == 0) {
                    ++numVillainPotions;
                } else {
                    ++numSuperVillainPotions;
                }
            }
        }

        uint256[] memory villainDarkSpiritTokenIds = new uint256[](numVillainPotions);
        uint256[] memory villainDarkHeroSpiritTokenIds = new uint256[](numVillainPotions);

        uint256[] memory superVillainDarkSpiritTokenIds = new uint256[](numSuperVillainPotions);
        uint256[] memory superVillainDarkHeroSpiritTokenIds = new uint256[](numSuperVillainPotions);

        uint256 villainPotionCounter = 0;
        uint256 superVillainPotionCounter = 0;

        unchecked {
            for(uint256 i = 0; i < claimIds.length; ++i) {
                uint256 darkSpiritTokenId = darkSpiritTokenIds[i];
                uint256 darkHeroSpiritTokenId = darkHeroSpiritTokenIds[i];
    
                if(darkSpiritTokenId == 0 || darkHeroSpiritTokenId == 0) {
                    villainDarkSpiritTokenIds[villainPotionCounter] = darkSpiritTokenId;
                    villainDarkHeroSpiritTokenIds[villainPotionCounter] = darkHeroSpiritTokenId;
                    ++villainPotionCounter;
                } else {
                    superVillainDarkSpiritTokenIds[superVillainPotionCounter] = darkSpiritTokenId;
                    superVillainDarkHeroSpiritTokenIds[superVillainPotionCounter] = darkHeroSpiritTokenId;
                    ++superVillainPotionCounter;
                }
            }
        }

        if(numVillainPotions > 0) {
            villainPotionContract.mintPotionsBatch(_msgSender(), villainDarkSpiritTokenIds, villainDarkHeroSpiritTokenIds);
        }

        if(numSuperVillainPotions > 0) {
            superVillainPotionContract.mintPotionsBatch(_msgSender(), superVillainDarkSpiritTokenIds, superVillainDarkHeroSpiritTokenIds);
        }
    }

    /// @dev Enumerates all specified claim ids and returns the potion quest details for each.
    /// Never use this function in a transaction context - it is fine for a read-only query for 
    /// external applications, but will consume a lot of gas when used in a transaction.
    function getPotionQuestDetailsBatch(uint256[] calldata claimIds) external view returns (PotionQuest[] memory potionQuests) {
        potionQuests = new PotionQuest[](claimIds.length);
        unchecked {
             for(uint256 i = 0; i < claimIds.length; ++i) {
                 potionQuests[i] = potionQuestLookup[claimIds[i]];
             }
        }

        return potionQuests;
    }

    /// @dev Records details of a potion quests with the specified claim id and transfers 
    /// specified dark spirit and dark hero spirit tokens to the contract.
    ///
    /// Throws when the caller does not own the specified dark spirit token.
    /// Throws when the caller does not own the specified dark hero spirit token.
    /// Throws when neither a dark spirit or dark hero spirit token are specified (0 values for both ids).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for dark spirit or dark hero spirit contract.
    ///   - The caller has not set adventure approval for this contract.
    ///
    /// Postconditions:
    /// ---------------
    /// The specified dark spirit is now owned by this contract.
    /// The specified dark hero spirit is now owned by this contract.
    /// The potion quest lookup for the specified created claim id contains the following information:
    ///   - The block timestamp of this transaction (the time at which crafting the potion began).
    ///   - The specified dark spirit token id.
    ///   - The specified dark hero spirit token id.
    ///   - The address of the adventurer that is permitted to retrieve their spirits or redeem their potion.
    /// A CraftingPotion event has been emitted.
    function _startCraftingPotion(uint256 claimId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId) private {
        if(darkSpiritTokenId == 0 && darkHeroSpiritTokenId == 0) {
            revert MustIncludeAtLeastOneSpirit();
        }

        address caller = _msgSender();

        potionQuestLookup[claimId].startTimestamp = uint64(block.timestamp);
        potionQuestLookup[claimId].darkSpiritTokenId = uint16(darkSpiritTokenId);
        potionQuestLookup[claimId].darkHeroSpiritTokenId = uint16(darkHeroSpiritTokenId);
        potionQuestLookup[claimId].adventurer = caller;

        emit CraftingPotion(caller, claimId, darkSpiritTokenId, darkHeroSpiritTokenId);

        if(darkSpiritTokenId > 0) {
            address darkSpiritTokenOwner = darkSpiritsContract.ownerOf(darkSpiritTokenId);
            if(darkSpiritTokenOwner != caller) {
                revert CallerNotOwnerOfDarkSpirit();
            }

            darkSpiritsContract.adventureTransferFrom(darkSpiritTokenOwner, address(custodian), darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            address darkHeroSpiritTokenOwner = darkHeroSpiritsContract.ownerOf(darkHeroSpiritTokenId);
            if(darkHeroSpiritTokenOwner != caller) {
                revert CallerNotOwnerOfDarkHeroSpirit();
            }

            darkHeroSpiritsContract.adventureTransferFrom(darkHeroSpiritTokenOwner, address(custodian), darkHeroSpiritTokenId);
        }
    }

    /// @dev Abandons the potion crafting quest referenced by the claim id before the required crafting duration has been met.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the potion is ready to redeem (required crafting duration has been met or exceeded).
    ///  - One exception to this rule is if the potion crafting adventure is removed from the whitelist of either dark spirit contract.
    ///    In that case, the user can abandon the potion to recover their dark spirits since redemption is not possible.
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been returned to the adventurer that started crafting with them.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// An AbandonedPotion event has been emitted.
    function _abandonPotion(uint256 claimId) private {
        (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) = _getAndClearPotionQuestStatus(claimId);

        bool allowUserToAbandonQuestsAfterQuestCompleted = false;
        if(!IAdventureApproval(address(darkSpiritsContract)).isAdventureWhitelisted(address(this)) || 
           !IAdventureApproval(address(darkHeroSpiritsContract)).isAdventureWhitelisted(address(this)) ||
           !IMinterWhitelist(address(villainPotionContract)).whitelistedMinters(address(this)) ||
           !IMinterWhitelist(address(superVillainPotionContract)).whitelistedMinters(address(this))) {
          allowUserToAbandonQuestsAfterQuestCompleted = true;
        }

        if(questCompleted && !allowUserToAbandonQuestsAfterQuestCompleted) {
            revert QuestCompletePotionMustBeRedeemed();
        }

        emit AbandonedPotion(adventurer, claimId);

        if(darkSpiritTokenId > 0) {
            darkSpiritsContract.transferFrom(address(custodian), adventurer, darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            darkHeroSpiritsContract.transferFrom(address(custodian), adventurer, darkHeroSpiritTokenId);
        }
    }

    /// @dev Redeems a crafted potion referenced by the claim id after the required crafting duration has been met.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the potion is not ready to redeem (required crafting duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been burned.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// A potion has been minted to the adventurer who crafted the potion.
    /// A CraftedPotion event has been emitted.
    function _redeemPotion(uint256 claimId) private returns (uint256, uint256) {
        (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) = _getAndClearPotionQuestStatus(claimId);

        if(!questCompleted) {
            revert CompleteQuestToRedeemPotion();
        }

        emit CraftedPotion(adventurer, claimId);

        if(darkSpiritTokenId > 0) {
            darkSpiritsContract.adventureBurn(darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            darkHeroSpiritsContract.adventureBurn(darkHeroSpiritTokenId);
        }

        return (darkSpiritTokenId, darkHeroSpiritTokenId);
    }

    /// @dev Returns potion quest details by claim id and removes the potion quest lookup entry.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    function _getAndClearPotionQuestStatus(uint256 claimId) private returns (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) {
        PotionQuest memory potionQuest = potionQuestLookup[claimId];

        uint256 startTimestamp = potionQuest.startTimestamp;
        adventurer = potionQuest.adventurer;
        darkSpiritTokenId = potionQuest.darkSpiritTokenId;
        darkHeroSpiritTokenId = potionQuest.darkHeroSpiritTokenId;

        if(startTimestamp == 0) {
            revert NoPotionQuestFoundForSpecifiedClaimId();
        }

        if(adventurer != _msgSender()) {
            revert CallerDidNotCreateClaimId();
        }

        unchecked {
            questCompleted = block.timestamp - startTimestamp >= CRAFTING_DURATION;
        }

        delete potionQuestLookup[claimId];

        return (adventurer, darkSpiritTokenId, darkHeroSpiritTokenId, questCompleted);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventure
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventure` contracts must conform to.
 * @dev All contracts that implement the adventure/quest system and interact with an {IAdventurous} token are required to implement this interface.
 */
interface IAdventure is IERC165 {

    /**
     * @dev Returns whether or not quests on this adventure lock tokens.
     * Developers of adventure contract should ensure that this is immutable 
     * after deployment of the adventure contract.  Failure to do so
     * can lead to error that deadlock token transfers.
     */
    function questsLockTokens() external view returns (bool);

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestEntered(address adventurer, uint256 tokenId, uint256 questId) external;

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestExited(address adventurer, uint256 tokenId, uint256 questId, uint256 questStartTimestamp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Quest.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventurous
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventurous` token contracts must conform to in order to support adventures and quests.
 * @dev All contracts that support adventures and quests are required to implement this interface.
 */
interface IAdventurous is IERC165 {

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
     */ 
    event AdventureApprovalForAll(address indexed tokenOwner, address indexed operator, bool approved);

    /**
     * @dev Emitted when a token enters or exits a quest
     */
    event QuestUpdated(uint256 indexed tokenId, address indexed tokenOwner, address indexed adventure, uint256 questId, bool active, bool booted);

    /**
     * @notice Transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Safe transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Burns a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Enters a player's token into a quest if they have opted into an authorized, whitelisted adventure.
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Exits a player's token from a quest if they have opted into an authorized, whitelisted adventure.
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure) external view returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (bool participatingInQuest, uint256 startTimestamp, uint256 index);

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure) external view returns (Quest[] memory activeQuests);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAdventurous.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IAdventurousERC721
 * @author Limit Break, Inc.
 * @notice Combines all {IAdventurous} and all {IERC721} functionality into a single, unified interface.
 * @dev This interface may be used as a convenience to interact with tokens that support both interface standards.
 */
interface IAdventurousERC721 is IERC721, IAdventurous {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Quest
 * @author Limit Break, Inc.
 * @notice Quest data structure for {IAdventurous} contracts.
 */
struct Quest {
    bool isActive;
    uint32 questId;
    uint64 startTimestamp;
    uint32 arrayIndex;
}