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

interface IAdventureApproval {
    function setAdventuresApprovedForAll(address operator, bool approved) external;
    function areAdventuresApprovedForAll(address owner, address operator) external view returns (bool);
    function isAdventureWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface of mintable villain contracts.
 */
interface IMintableVillain {

    /**
     * @notice Mints multiple villains unmasked with the specified masked villain token ids
     */
    function unmaskVillainsBatch(address to, uint256[] calldata villainTokenIds, uint256[] calldata potionTokenIds) external;
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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title VillainCustodian
 * @author Limit Break, Inc.
 * @notice Holds masked villain and potion tokens that are currently on a villain unmasking adventure.
 */
contract VillainCustodian {

    /// @dev Specify the villain unmasking adventure, masked villain, super villain potion and villain potion contract addresses during creation
    constructor(address villainUnmaskingAdventure, address maskedVillainAddress, address superVillainPotionAddress, address villainPotionAddress) {
        IERC721(maskedVillainAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IERC721(superVillainPotionAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IERC721(villainPotionAddress).setApprovalForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(maskedVillainAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(superVillainPotionAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
        IAdventureApproval(villainPotionAddress).setAdventuresApprovedForAll(villainUnmaskingAdventure, true);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IMintableVillain.sol";
import "./IMinterWhitelist.sol";
import "./VillainCustodian.sol";
import "@limit-break/adventures/IAdventure.sol";
import "@limit-break/adventures/IAdventurousERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CallbackNotImplemented();
error CallerDidNotCreateClaimId();
error CallerNotOwnerOfSuperVillainPotion();
error CallerNotOwnerOfMaskedVillain();
error CallerNotOwnerOfVillainPotion();
error CannotIncludeMoreThanOnePotion();
error CannotSpecifyZeroAddressForSuperVillainContract();
error CannotSpecifyZeroAddressForVillainContract();
error CannotSpecifyZeroAddressForSuperVillainPotionContract();
error CannotSpecifyZeroAddressForMaskedVillainContract();
error CannotSpecifyZeroAddressForVillainPotionContract();
error CompleteQuestToUnmaskVillain();
error InputArrayLengthMismatch();
error MustIncludeMaskedVillain();
error NewUnmaskingDurationMustBeLessThanCurrentDuration();
error NoUnmaskingQuestFoundForSpecifiedClaimId();
error PotionGreaterThanAllocatedSpace();
error QuantityMustBeGreaterThanZero();
error QuestCompleteVillainMustBeUnmasked();

/**
 * @title VillainUnmaskingAdventure
 * @author Limit Break, Inc.
 * @notice An adventure that unmasks villains based on the provided potion
 */
contract VillainUnmaskingAdventure is Ownable, Pausable, ERC165, IAdventure {

    struct UnmaskingQuest {
        uint64 startTimestamp;
        uint16 villainTokenId;
        uint16 potionBitmap;
        address adventurer;
    }

    /// @dev An unchangeable reference to the villain potion contract optionally used in an unmasking quest
    IAdventurousERC721 immutable public villainPotionContract;

    /// @dev An unchangeable reference to the super villain potion contract optionally used in an unmasking quest
    IAdventurousERC721 immutable public superVillainPotionContract;

    /// @dev An unchangeable reference to the masked villain contract to be unmasked
    IAdventurousERC721 immutable public maskedVillainContract;

    /// @dev An unchangeable reference to the villain contract unmasked at the end of a quest
    IMintableVillain immutable public villainContract;

    /// @dev An unchangeable reference to the super villain contract unmasked at the end of a quest
    IMintableVillain immutable public superVillainContract;

    /// @dev An unchangeable reference to a custodial holding contract for masked villains and potions
    VillainCustodian immutable public custodian;

    /// @dev A counter for claim ids
    uint256 public lastClaimId;

    /// @dev The amount of time the user must remain in a quest to complete it and receive their unmasked villain
    uint256 public unmaskingDuration = 7 days;
    
    /// @dev Map claim id to unmasking quest details
    mapping (uint256 => UnmaskingQuest) public unmaskingQuestLookup;

    /// @dev Designation of uint(1) to be used for bitmap functions
    uint constant private ONE = uint(1);

    /// @dev Maximum value stored in 15 bits.  Used to prevent falsely setting the 16th bit on the potionBitmap.
    uint256 constant private MAX_15_BIT_VALUE = 32767;

    /// @dev Emitted when an adventurer cancels a villain unmasking
    event VillainMasked(address indexed adventurer, uint256 indexed claimId, bool isSuperVillain);

    /// @dev Emitted when the unmaskingDuration is updated.
    event UnmaskingDurationUpdated(uint256 oldUnmaskingDuration, uint256 newUnmaskingDuration);

    /// @dev Emitted when an adventurer starts unmasking a villain
    event UnmaskingVillain(address indexed adventurer, uint256 indexed claimId, uint256 potionTokenId, uint256 villainTokenId, bool isSuperVillain);

    /// @dev Emitted when an adventurer unmasks their villain
    event UnmaskedVillain(address indexed adventurer, uint256 indexed claimId, bool isSuperVillain);

    constructor(address villainPotionAddress, address superVillainPotionAddress, address maskedVillainAddress, address villainAddress, address superVillainAddress) {
        if(villainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForVillainPotionContract();
        }

        if(superVillainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForSuperVillainPotionContract();
        }

        if(maskedVillainAddress == address(0)) {
            revert CannotSpecifyZeroAddressForMaskedVillainContract();
        }

        if(villainAddress == address(0)) { 
            revert CannotSpecifyZeroAddressForVillainContract();
        }

        if(superVillainAddress == address(0)) {
            revert CannotSpecifyZeroAddressForSuperVillainContract();
        }

        villainPotionContract = IAdventurousERC721(villainPotionAddress);
        superVillainPotionContract = IAdventurousERC721(superVillainPotionAddress);
        maskedVillainContract = IAdventurousERC721(maskedVillainAddress);
        
        villainContract = IMintableVillain(villainAddress);
        superVillainContract = IMintableVillain(superVillainAddress);

        custodian = new VillainCustodian(address(this), maskedVillainAddress, superVillainPotionAddress, villainPotionAddress);
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

    /// @dev Returns false - this quest uses hard staking
    function questsLockTokens() external override pure returns (bool) {
        return false;
    }

    /// @dev Pauses and blocks adventurers from starting new villain unmasking quests
    /// Throws if the adventure is already paused
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses and allows adventurers to start new villain unmasking quests
    /// Throws if the adventure is already unpaused
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /// @dev Sets the unmasking duration for the quest
    /// Throws if the unmasking duration is greater than current unmasking duration
    ///
    /// Postconditions:
    /// ---------------
    /// The unmasking duration is updated to the provided new unmasking duration.
    function setUnmaskingDuration(uint256 unmaskingDuration_) external onlyOwner {
        uint256 currentUnmaskingDuration = unmaskingDuration;
        if(unmaskingDuration_ >= currentUnmaskingDuration) {
            revert NewUnmaskingDurationMustBeLessThanCurrentDuration();
        }
        emit UnmaskingDurationUpdated(currentUnmaskingDuration, unmaskingDuration_);
        unmaskingDuration = unmaskingDuration_;
    }

    /// @notice Returns the mask to multiple villains referenced by the specifed claim ids before the required unmasking duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no unmasking quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim id (adventurer not the same as caller).
    /// Throws when the one or more of the villains are ready to redeem (required unmasking duration has been met or exceeded).
    ///  - This is invalid if any of the potions or masked villain contracts are removed from the adventure whitelist or the adventure is removed
    ///    as a whitelisted minter for the villain or super villain contracts.
    ///    In these cases, the user can remask the villain to recover their potion and masked villain since redemption is not possible.
    ///
    /// Postconditions:
    /// ---------------
    /// The masked villains that were in use to unmask have been returned to the adventurer that started the quest.
    /// The potions that were in use to unmask the villains have been returned to the adventurer that started the quest.
    /// The unmasking quest lookup entries for the specified claim ids have been removed.
    /// `quantity` VillainMasked events have been emitted, where `quantity` is the length of the claim id array.
    function maskVillainsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        for(uint256 i = 0; i < claimIds.length;) {
            _maskVillain(claimIds[i]);
            
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Enters the villain unmasking quests with a batch of specified masked villains and optional potions.
    /// Villain Potion token ids may be 0, in which case it means no villain potion will be used to enhance the unmasking.
    /// Super Villain token ids may be 0, in which case it means no super villain potion will be used to enhance the unmasking.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the token id arrays.
    /// Throws when token id array lengths don't match.
    /// Throws when the caller does not own a specified masked villain token.
    /// Throws when the caller does not own a specified villain potion token.
    /// Throws when the caller does not own a specified super villain potion token.
    /// Throws when both a villain potion and super villain potion token are specified (non 0 values for both ids at the same array index).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for included contracts.
    ///   - The caller has not set adventure approval for this contract.
    /// Throws when the contract is paused
    ///
    /// Postconditions:
    /// ---------------
    /// The specified masked villains are now owned by the custodian.
    /// The specified potions are now owned by the custodian.
    /// The value of the lastClaimId counter has increased by `quantity`, where `quantity` is the length of the token id arrays.
    /// The unmasking quest lookup for the newly created claim ids contains the following information:
    ///   - The block timestamp of this transaction (the time at which unmasking the villain began).
    ///   - The specified masked villain token id.
    ///   - A bitmap containing the potion token ID and an indicator in the 16th bit, `1` if it is a super villain, `0` otherwise.
    ///   - The address of the adventurer that is permitted to retrieve their masked villain and potion or unmask their villain.
    /// `quantity` UnmaskingVillain events have been emitted, where `quantity` is the length of the token id arrays.
    function startUnmaskingVillainsBatch(uint256[] calldata maskedVillainTokenIds, uint256[] calldata villainPotionTokenIds, uint256[] calldata superVillainPotionTokenIds) external whenNotPaused {
        if(maskedVillainTokenIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        if(maskedVillainTokenIds.length != villainPotionTokenIds.length || villainPotionTokenIds.length != superVillainPotionTokenIds.length) {
            revert InputArrayLengthMismatch();
        }

        uint256 claimId;
        unchecked {
            claimId = lastClaimId;
            lastClaimId = claimId + maskedVillainTokenIds.length;
            ++claimId;
        }

        for(uint256 i = 0; i < maskedVillainTokenIds.length;) {
            _startUnmaskingVillain(claimId + i, maskedVillainTokenIds[i], villainPotionTokenIds[i], superVillainPotionTokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Unmasks multiple villains referenced by the specifed claim ids after the required unmasking duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no unmasking quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim ids (adventurer not the same as caller).
    /// Throws when one or more of the villains is not ready to unmask (required unmasking duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The villain or super villain potion that was in use to unmask the villain has been burnt.
    /// The masked villain that was in use to unmask has been burnt.
    /// The unmasking quest lookup entry for the specified claim id has been removed.
    /// An unmasked villain or super villain has been minted to the adventurer who completed the quest.
    /// `quantity` UnmaskedVillain events have been emitted, where `quantity` is the length of the claim id arrays.
    function unmaskVillainsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        uint256[] memory tempVillainTokenIds = new uint256[](claimIds.length);
        uint256[] memory tempSuperVillainTokenIds = new uint256[](claimIds.length);
        uint256[] memory potionTokenIds = new uint256[](claimIds.length);

        uint256 villainCounter = 0;
        uint256 superVillainCounter = 0;

        for(uint256 i = 0; i < claimIds.length;) {
            (uint256 villainTokenId, uint256 potionTokenId, bool isSuperVillain) = _unmaskVillain(claimIds[i]);
            unchecked {
                if (isSuperVillain) {
                    tempSuperVillainTokenIds[i] = villainTokenId;
                    ++superVillainCounter;
                } else {
                    tempVillainTokenIds[i] = villainTokenId;
                    ++villainCounter;
                }
                potionTokenIds[i] = potionTokenId;
                ++i;
            }
        }

        uint256[] memory villainTokenIds = new uint256[](villainCounter);
        uint256[] memory villainPotionTokenIds = new uint256[](villainCounter);

        uint256[] memory superVillainTokenIds = new uint256[](superVillainCounter);
        uint256[] memory superVillainPotionTokenIds = new uint256[](superVillainCounter);

        uint256 villainPotionCounter = 0;
        uint256 superVillainPotionCounter = 0;

        unchecked {
            for(uint256 i = 0; i < claimIds.length; ++i) {
                uint256 villainTokenId = tempVillainTokenIds[i];        
                uint256 superVillainTokenId = tempSuperVillainTokenIds[i];

                if(villainTokenId > 0) {
                    villainPotionTokenIds[villainPotionCounter] = potionTokenIds[i];
                    villainTokenIds[villainPotionCounter] = villainTokenId;
                    ++villainPotionCounter;
                } else {
                    superVillainPotionTokenIds[superVillainPotionCounter] = potionTokenIds[i];
                    superVillainTokenIds[superVillainPotionCounter] = superVillainTokenId;
                    ++superVillainPotionCounter;
                }
            }
        }

        if(villainCounter > 0) {
            villainContract.unmaskVillainsBatch(_msgSender(), villainTokenIds, villainPotionTokenIds);
        }

        if(superVillainCounter > 0) {
            superVillainContract.unmaskVillainsBatch(_msgSender(), superVillainTokenIds, superVillainPotionTokenIds);
        }
    }


    /// @dev Enumerates all specified claim ids and returns the unmasking quest details for each.
    /// Never use this function in a transaction context - it is fine for a read-only query for 
    /// external applications, but will consume a lot of gas when used in a transaction.
    function getUnmaskingQuestDetailsBatch(uint256[] calldata claimIds) external view returns (UnmaskingQuest[] memory unmaskingQuests) {
        unmaskingQuests = new UnmaskingQuest[](claimIds.length);
        unchecked {
             for(uint256 i = 0; i < claimIds.length; ++i) {
                 unmaskingQuests[i] = unmaskingQuestLookup[claimIds[i]];
             }
        }
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Records the details of an unmasking quest with the specified claim id and transfers
    /// specified masked villain token and potion to the custodian
    ///
    /// Throws when the caller does not own a specified masked villain token.
    /// Throws when the caller does not own a specified villain potion token.
    /// Throws when the caller does not own a specified super villain potion token.
    /// Throws when both a villain potion and super villain potion token are specified (non 0 values for both ids at the same array index).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for included contracts.
    ///   - The caller has not set adventure approval for this contract.
    /// Throws when the contract is paused
    ///
    /// Postconditions:
    /// ---------------
    /// The specified masked villain is now owned by the custodian.
    /// The specified potion is now owned by the custodian.
    /// The unmasking quest lookup for the newly created claim ids contains the following information:
    ///   - The block timestamp of this transaction (the time at which unmasking the villain began).
    ///   - The specified masked villain token id.
    ///   - A bitmap containing the potion token ID and an indicator in the 16th bit `1` if it is a super villain, `0` otherwise.
    ///   - The address of the adventurer that is permitted to retrieve their masked villain and potion or unmask their villain.
    /// A UnmaskingVillain event has been emitted.
    function _startUnmaskingVillain(uint256 claimId, uint256 maskedVillainTokenId, uint256 villainPotionTokenId, uint256 superVillainPotionTokenId) private {
        if(villainPotionTokenId != 0 && superVillainPotionTokenId != 0) {
            revert CannotIncludeMoreThanOnePotion();
        }
        if(maskedVillainTokenId == 0) {
            revert MustIncludeMaskedVillain();
        }
        
        if(superVillainPotionTokenId > MAX_15_BIT_VALUE || villainPotionTokenId > MAX_15_BIT_VALUE) {
            revert PotionGreaterThanAllocatedSpace();
        }

        address caller = _msgSender();
        uint16 potionTokenId = villainPotionTokenId == 0 ? uint16(superVillainPotionTokenId) : uint16(villainPotionTokenId);
        uint16 potionBitmap = potionTokenId;
        if(superVillainPotionTokenId > 0) {
            potionBitmap = potionBitmap | uint16(ONE << 15);
        }

        unmaskingQuestLookup[claimId].startTimestamp =  uint64(block.timestamp);
        unmaskingQuestLookup[claimId].villainTokenId = uint16(maskedVillainTokenId);
        unmaskingQuestLookup[claimId].potionBitmap = potionBitmap;
        unmaskingQuestLookup[claimId].adventurer = caller;

        emit UnmaskingVillain(caller, claimId, potionTokenId, unmaskingQuestLookup[claimId].villainTokenId, superVillainPotionTokenId > 0);

        if (maskedVillainContract.ownerOf(maskedVillainTokenId) != caller) {
            revert CallerNotOwnerOfMaskedVillain();
        }
        maskedVillainContract.adventureTransferFrom(caller, address(custodian), maskedVillainTokenId);

        if (villainPotionTokenId > 0) {
            if (villainPotionContract.ownerOf(villainPotionTokenId) != caller) {
                revert CallerNotOwnerOfVillainPotion();
            }
            villainPotionContract.adventureTransferFrom(caller, address(custodian), villainPotionTokenId);
        }

        if (superVillainPotionTokenId > 0) {
            if (superVillainPotionContract.ownerOf(superVillainPotionTokenId) != caller) {
                revert CallerNotOwnerOfSuperVillainPotion();
            }
            superVillainPotionContract.adventureTransferFrom(caller, address(custodian), superVillainPotionTokenId);
        }
    }

    /// @dev Returns the mask to the villain referenced by the claim id before the required unmasking duration has been met.
    ///
    /// Throws when no unmasking quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the villain is ready to unmask (required unmasking duration has been met or exceeded).
    ///  - This is invalid if any of the potions or masked villain contracts are removed from the adventure whitelist or the adventure is removed
    ///    as a whitelisted minter for the villain or super villain contracts.
    ///    In these cases, the user can remask the villain to recover their potion and masked villain since redemption is not possible.
    ///
    /// Postconditions:
    /// ---------------
    /// The masked villain that was in use to unmask has been returned to the adventurer that started the quest.
    /// The potion that was in use to unmask the villain has been returned to the adventurer that started the quest.
    /// The unmasking quest lookup entry for the specified claim id has been removed.
    /// A VillainMasked event has been emitted.
    function _maskVillain(uint256 claimId) private {
        (address adventurer, uint256 villainTokenId, uint256 potionTokenId, bool isSuperVillain, bool questCompleted) = _getAndClearUnmaskingQuestStatus(claimId);

        bool allowUserToReturnMaskAfterQuestCompleted = false;
        if(!IAdventureApproval(address(maskedVillainContract)).isAdventureWhitelisted(address(this)) || 
            !IAdventureApproval(address(villainPotionContract)).isAdventureWhitelisted(address(this)) || 
            !IAdventureApproval(address(superVillainPotionContract)).isAdventureWhitelisted(address(this)) || 
            !IMinterWhitelist(address(villainContract)).whitelistedMinters(address(this)) ||
            !IMinterWhitelist(address(superVillainContract)).whitelistedMinters(address(this))) {
            allowUserToReturnMaskAfterQuestCompleted = true;
        }

        if(questCompleted && !allowUserToReturnMaskAfterQuestCompleted) {
            revert QuestCompleteVillainMustBeUnmasked();
        }

        emit VillainMasked(adventurer, claimId, isSuperVillain);

        maskedVillainContract.transferFrom(address(custodian), adventurer, villainTokenId);

        if(potionTokenId > 0) {
            if(isSuperVillain) {
                superVillainPotionContract.transferFrom(address(custodian), adventurer, potionTokenId);
            } else {
                villainPotionContract.transferFrom(address(custodian), adventurer, potionTokenId);
            }
        }
    }

    /// @dev Unmasks a villain referenced by the claim id after the required unmasking duration has been met.
    ///
    /// Throws when no unmasking quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the villain is not ready to unmask (required unmasking duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The villain or super villain potion used to unmask has been burned.
    /// The masked villain has been burned.
    /// The unmasking quest lookup entry for the specified claim id has been removed.
    /// A villain or super villain has been minted to the adventurer who removed the mask.
    /// A UnmaskedVillain event has been emitted.
    function _unmaskVillain(uint256 claimId) private returns (uint256, uint256, bool) {
        (address adventurer, uint256 villainTokenId, uint256 potionTokenId, bool isSuperVillain, bool questCompleted) = _getAndClearUnmaskingQuestStatus(claimId);

        if(!questCompleted) {
            revert CompleteQuestToUnmaskVillain();
        }

        emit UnmaskedVillain(adventurer, claimId, isSuperVillain);

        if(isSuperVillain) {
            superVillainPotionContract.adventureBurn(potionTokenId);
        } else if(potionTokenId > 0) {
            villainPotionContract.adventureBurn(potionTokenId);
        }

        maskedVillainContract.adventureBurn(villainTokenId);

        return (villainTokenId, potionTokenId, isSuperVillain);
    }


    /// @dev Returns unmasking quest details and removes the lookup entry
    ///
    /// Throws when no unmasking quest is found
    /// Throws when the caller did not create the claim id (caller != adventurer)
    function _getAndClearUnmaskingQuestStatus(uint256 claimId) private returns (address adventurer, uint256 villainTokenId, uint256 potionTokenId, bool isSuperVillain, bool questCompleted) {
        UnmaskingQuest memory unmaskingQuest = unmaskingQuestLookup[claimId];

        uint256 startTimestamp = unmaskingQuest.startTimestamp;
        adventurer = unmaskingQuest.adventurer;
        villainTokenId = unmaskingQuest.villainTokenId;
        uint16 potionBitmap = unmaskingQuest.potionBitmap;
        isSuperVillain = potionBitmap >> 15 & 1 == 1;
        potionTokenId = potionBitmap & ~(ONE << 15);

        if (startTimestamp == 0) {
            revert NoUnmaskingQuestFoundForSpecifiedClaimId();
        }

        if (adventurer != _msgSender()) {
            revert CallerDidNotCreateClaimId();
        }

        unchecked {
            questCompleted = block.timestamp - startTimestamp >= unmaskingDuration;
        }

        delete unmaskingQuestLookup[claimId];
        return (adventurer, villainTokenId, potionTokenId, isSuperVillain, questCompleted);
    }

}