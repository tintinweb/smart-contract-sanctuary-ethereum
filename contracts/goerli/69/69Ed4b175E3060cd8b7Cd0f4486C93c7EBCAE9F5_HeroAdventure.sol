// By interacting with this code I agree to the Quest Terms at https://digidaigaku.com/hero-adventure-tos.pdf
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventure.sol";
import "./IMintableHero.sol";
import "./IQuestStakingERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title HeroAdventure contract
/// @notice This contract is the entry point into a quest where players will receive a hero NFT upon completion of the quest
/// @dev This adventure is intened to prevent the transfer of Adventure ERC721 tokens that are engaged in the quest.
/// This `questsLockTokens` value must be set to `true` when this adventure contract is whitelisted.
contract HeroAdventure is Context, Ownable, Pausable, ERC165, IAdventure {
    struct HeroQuest {
        uint16 genesisTokenId;
        uint16 spiritTokenId;
        address adventurer;
    }

    /// @dev The amount of time the user must remain in the quest to complete it and receive a hero
    uint256 public constant HERO_QUEST_DURATION = 1 days;

    /// @dev The identifier for the spirit quest
    uint256 public constant SPIRIT_QUEST_ID = 1;

    /// @dev The largest token id for genesis and spirit tokens
    uint256 public constant MAX_TOKEN_ID = 2022;

    /// @dev An unchangeable reference to the hero contract that is rewarded at the conclusion of adventure quest
    IMintableHero public immutable heroContract;

    /// @dev An unchangeable reference to the genesis token contract
    IERC721 public immutable genesisContract;

    /// @dev An unchangeable reference to the spirit token contract
    IQuestStakingERC721 public immutable spiritContract;

    /// @dev Map spirit token id to hero quest details
    mapping(uint256 => HeroQuest) public spiritQuestLookup;

    /// @dev Map genesis token id to hero quest details
    mapping(uint256 => HeroQuest) public genesisQuestLookup;

    /// @dev Specify the hero, genesis, and spirit token contract addresses during creation
    constructor(
        address heroAddress,
        address genesisAddress,
        address spiritAddress
    ) {
        heroContract = IMintableHero(heroAddress);
        genesisContract = IERC721(genesisAddress);
        spiritContract = IQuestStakingERC721(spiritAddress);
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Returns whether or not quests on this adventure lock tokens.
    function questsLockTokens() external pure override returns (bool) {
        return true;
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases because spirits contract did not implement the IAdventure checks and will not invoke this callback.
    function onQuestEntered(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256 /*questId*/
    )
        external
        pure
        override
    {
        revert("Callback not implemented");
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
    /// Throws in all cases because spirits contract did not implement the IAdventure checks and will not invoke this callback.
    function onQuestExited(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256, /*questId*/
        uint256 /*questStartTimestamp*/
    )
        external
        pure
        override
    {
        revert("Callback not implemented");
    }

    /// @dev Pauses and blocks adventurers from starting new hero quests
    /// Throws if the adventure is already paused
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses and allows adventurers to start new hero quests
    /// Throws if the adventure is already unpaused
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /// @dev Enters the hero quest with a spirit and an optional genesis token id
    /// Throws when the spirit has already been entered into the quest by the caller
    /// Throws when the specified non-zero genesis token id does not exist
    /// Throws when the specified non-zero genesis token id is not owned by the caller
    /// Throws if the genesis transferFrom function fails to transfer custody of genesis to this contract
    /// Throws when the specified spirit token id does not exist
    /// Throws when the specified spirit token id is not owned by the caller
    /// Throws if the spirit cannot enter quest, for example if this adventure has been removed from whitelist
    /// Throws if the contract is paused

    /// Postconditions:
    /// ---------------

    /// The specified non-zero genesis token id is owned by this contract
    /// The genesis quest lookup contains the quest details when a non-zero genesis token was specified
    /// The spirit quest lookup contains the quest details for the specified spirit token id
    /// The spirit token has been entered into quest #1 for this adventure

    /// Caveats/Special Cases:
    /// ----------------------

    /// 1. Bob enters the quest spirit token 1 with a genesis token
    /// 2. Bob uses the backdoor userExitQuest call on the spirit contract to exit the quest for spirit token 1.
    ///    This adventure contract still thinks spirit token 1 is on the quest.
    /// 3. Bob sells spirit token 1 to Amy (Bob's token is now orphaned, and can be recovered by calling recoverOrphanedGenesisToken).
    /// 4. Amy is allowed to call enterQuest with spirit token id 1.
    /// 5. Amy's progress starts when she enters the quest with the spirit, not when Bob entered the quest originally.
    function enterQuest(uint256 spiritTokenId, uint256 genesisTokenId)
        external
        whenNotPaused
    {
        address caller = _msgSender();
        require(spiritQuestLookup[spiritTokenId].adventurer != caller, "Spirit already entered into quest by caller");

        if (genesisTokenId > 0) {
            address genesisOwner = genesisContract.ownerOf(genesisTokenId);
            require(genesisOwner == caller, "Caller not owner of genesis");

            genesisQuestLookup[genesisTokenId] = HeroQuest({
                genesisTokenId: uint16(genesisTokenId),
                spiritTokenId: uint16(spiritTokenId),
                adventurer: genesisOwner
            });

            genesisContract.transferFrom(genesisOwner, address(this), genesisTokenId);
        }

        require(spiritContract.ownerOf(spiritTokenId) == caller, "Caller not owner of spirit");

        spiritQuestLookup[spiritTokenId] = HeroQuest({
            genesisTokenId: uint16(genesisTokenId),
            spiritTokenId: uint16(spiritTokenId),
            adventurer: caller
        });

        spiritContract.enterQuest(spiritTokenId, SPIRIT_QUEST_ID);
    }

    /// @dev Exits the hero quest for a specified spirit with the genesis token that it was paired with, if applicable.
    /// Throws when the spirit has not been entered into the quest by any caller.
    /// Throws when the owner of the spirit token is not the caller.
    /// Throws if the owner of the spirit is not the same as the original user that entered the quest with the the spirit.
    ///  - This can happen if a user does a backdoor userExitQuest on the spirit directly.
    ///  - The new owner needs to enterQuest with the spirit first before it can be exited from the quest to claim a reward.
    /// Throws if the parameter `redeemHero` is true and the quest has not been completed yet
    ///  - This prevents accidentally exiting the quest just before the quest ends, as the user's progress would be lost
    /// Throws if the parameter `redeemHero` is false and the quest is complete

    /// Postconditions:
    /// ---------------

    /// If a genesis token was paired with the spirit when the spirit entered the quest, the genesis token id is returned to the original
    /// address from which the genesis token came.
    /// The genesis quest mapping is cleared for the returned genesis token id.
    /// The quest on the spirit contract will be in the exited state.
    /// If the quest is exited after the quest timer has been completed, the spirit is burned
    /// and a hero with the proper bloodline is minted to the adventurer who completed the adventure.
    /// The spirit quest mapping is cleared for the specified spirit token id.

    /// Caveats/Special Cases:
    /// ----------------------

    /// 1. Bob previously entered the quest with spirit token 1 and with a genesis token
    /// 2. Bob uses the backdoor userExitQuest call on the spirit contract to exit the quest for spirit token 1.
    ///    This adventure contract still thinks spirit token 1 is in the quest.
    /// 3. Until Bob sells or transfers spirit token 1, Bob can still call exitQuest on this
    ///    contract to clear the quest state and retrieve their genesis token that was paired with the spirit.
    /// 4. Bob sells spirit token 1 to Amy (If Bob did not exitQuest first, Bob's genesis token is now orphaned, and can be recovered by calling recoverOrphanedGenesisToken).
    /// 5. Amy cannot call exitQuest for spirit 1 without first entering the quest with spirit 1. Amy's progress starts when she enters the quest.
    /// 6. Amy can exit the quest normally (before 30 days, she will not receive a reward, but after 30 days she will receive the reward).
    function exitQuest(uint256 spiritTokenId, bool redeemHero) external {
        address caller = _msgSender();

        HeroQuest memory quest = spiritQuestLookup[spiritTokenId];
        require(quest.adventurer != address(0), "Spirit token is not on quest");
        require(spiritContract.ownerOf(spiritTokenId) == caller, "Caller not owner of spirit");

        if (quest.genesisTokenId > 0) {
            returnGenesisToAdventurer(genesisQuestLookup[quest.genesisTokenId].adventurer, quest.genesisTokenId);
        }

        if (quest.adventurer == caller) {
            (bool participatingInQuest, uint256 startTimestamp,) =
            spiritContract.isParticipatingInQuest(spiritTokenId, address(this), SPIRIT_QUEST_ID);

            if (participatingInQuest) {
                bool questComplete =
                    block.timestamp - startTimestamp >= HERO_QUEST_DURATION;

                if (questComplete && !redeemHero) {
                    revert("Quest complete, must redeem hero");
                }

                if (!questComplete && redeemHero) {
                    revert("Complete quest to redeem hero");
                }

                spiritContract.exitQuest(spiritTokenId, SPIRIT_QUEST_ID);

                if (questComplete) {
                    spiritContract.adventureBurn(spiritTokenId);
                    heroContract.mintHero(caller, spiritTokenId, quest.genesisTokenId);
                }
            }
        } else {
            revert("New spirit owner must enter quest with spirit before exiting");
        }

        delete spiritQuestLookup[spiritTokenId];
    }

    /// @dev Used only to protect against an edge case where a backdoor exit and transfer occurs, locking up genesis tokens.

    /// This can be called by anyone generous enough to spend gas to help a player recover their genesis token,
    /// as it will always return to the original owner of the genesis token that entered a quest.

    /// Throws when the speicified genesis token id is not in an orphaned state.

    /// Postconditions:
    /// ---------------

    /// The orphaned genesis token is returned to the address that originally entered a quest with it.
    /// The genesis quest mapping is cleared, returning the contract to a consistent state.
    function recoverOrphanedGenesisToken(uint256 genesisTokenId) external {
        (bool isOrphaned, address returnAddress) =
            isGenesisTokenOrphaned(genesisTokenId);
        require(isOrphaned, "Genesis token is not orphaned");
        returnGenesisToAdventurer(returnAddress, genesisTokenId);
    }

    /// @dev Enumerates all hero quests/pairs that are currently entered into quests by the specified player.
    /// Never use this function in a transaction context - it is fine for a read-only query for
    /// external applications, but will consume a lot of gas when used in a transaction.
    function findHeroQuestsByPlayer(address player)
        external
        view
        returns (HeroQuest[] memory playerQuests)
    {
        unchecked {
            // First, find all the token ids owned by the player
            uint256 ownerBalance = spiritContract.balanceOf(player);
            uint256[] memory ownedTokenIds = new uint256[](ownerBalance);
            uint256 tokenIndex = 0;
            for (
                uint256 spiritTokenId = 1;
                spiritTokenId <= MAX_TOKEN_ID;
                ++spiritTokenId
            ) {
                try spiritContract.ownerOf(spiritTokenId) returns (address ownerOfToken) {
                    if(ownerOfToken == player) {
                        ownedTokenIds[tokenIndex++] = spiritTokenId;
                    }
                } catch {}

                if (tokenIndex == ownerBalance) {
                    break;
                }
            }

            // For each owned spirit token id, check the quest count
            // When 1 or greater, the spirit is engaged in a quest on this adventure.
            address thisAddress = address(this);
            uint256 numberOfQuests = 0;
            for (uint256 i = 0; i < ownerBalance; ++i) {
                if (
                    spiritContract.getQuestCount(ownedTokenIds[i], thisAddress) > 0
                ) {
                    ++numberOfQuests;
                }
            }

            // Finally, make one more pass and populate the player quests return array
            uint256 questIndex = 0;
            playerQuests = new HeroQuest[](numberOfQuests);

            for (uint256 i = 0; i < ownerBalance; ++i) {
                if (
                    spiritContract.getQuestCount(ownedTokenIds[i], thisAddress) > 0
                ) {
                    playerQuests[questIndex] =
                        spiritQuestLookup[ownedTokenIds[i]];
                    ++questIndex;
                }

                if (questIndex == numberOfQuests) {
                    break;
                }
            }
        }

        return playerQuests;
    }

    /// @dev Given a list of genesis token ids, returns whether or not each token id is considered orphaned.
    /// The length of orphanedStatuses return array always matches the length of the genesisTokenIds input array.
    /// When orphanedStatuses[i] == true, it means genesisTokenIds[i] was orphaned.
    /// When orphanedStatuses[i] == false, it means genesisTokenIds[i] was not orphaned.
    function areGenesisTokensOrphaned(uint256[] calldata genesisTokenIds)
        external
        view
        returns (bool[] memory orphanedStatuses)
    {
        unchecked {
            uint256 queryLength = genesisTokenIds.length;
            orphanedStatuses = new bool[](queryLength);
            for (uint256 i = 0; i < queryLength; i++) {
                (bool isOrphaned,) = isGenesisTokenOrphaned(genesisTokenIds[i]);
                orphanedStatuses[i] = isOrphaned;
            }
        }

        return orphanedStatuses;
    }

    /// @dev Given a list of spirit token ids, returns whether or not each token id is considered soulless.
    /// The length of soullessStatuses return array always matches the length of the spiritTokenIds input array.
    /// When soullessStatuses[i] == true, it means spiritTokenIds[i] was soulless.
    /// When soullessStatuses[i] == false, it means spiritTokenIds[i] was not soulless.
    function areSpiritTokensSoulless(uint256[] calldata spiritTokenIds)
        external
        view
        returns (bool[] memory soullessStatuses)
    {
        unchecked {
            uint256 queryLength = spiritTokenIds.length;
            soullessStatuses = new bool[](queryLength);
            for (uint256 i = 0; i < queryLength; i++) {
                (bool isSoulless,) = isSpiritTokenSoulless(spiritTokenIds[i]);
                soullessStatuses[i] = isSoulless;
            }
        }

        return soullessStatuses;
    }

    /// @dev Detects whether a genesis token has been orphaned.
    /// It is orphaned if the user backdoor exits the spirit from the quest and transferred it to a new user, who then entered the quest with the spirit.
    /// Alternately, if the known adventurer for the spirit doesn't match the owner that entered quest with the genesis token,
    /// the genesis token is orphaned.
    function isGenesisTokenOrphaned(uint256 genesisTokenId)
        public
        view
        returns (bool isOrphaned, address returnAddress)
    {
        HeroQuest memory questFromGenesisLookup =
            genesisQuestLookup[genesisTokenId];
        HeroQuest memory questFromSpiritLookup =
            spiritQuestLookup[questFromGenesisLookup.spiritTokenId];

        try spiritContract.ownerOf(questFromGenesisLookup.spiritTokenId) returns (address spiritOwner) {
            isOrphaned = questFromSpiritLookup.adventurer != questFromGenesisLookup.adventurer || questFromSpiritLookup.adventurer != spiritOwner;
            returnAddress = isOrphaned ? questFromGenesisLookup.adventurer : address(0);
            return (isOrphaned, returnAddress);
        } catch {}

        isOrphaned = questFromGenesisLookup.adventurer != address(0);
        returnAddress =
            isOrphaned ? questFromGenesisLookup.adventurer : address(0);
        return (isOrphaned, returnAddress);
    }

    /// @dev Detects whether a spirit token is currently soulless.
    /// It is considered soulless if the user backdoor exits the spirit from the quest and has not transferred it to a new user.
    /// In this case, the spirit cannot be burned to claim their hero until the user exits the quest and re-enters the quest.
    function isSpiritTokenSoulless(uint256 spiritTokenId)
        public
        view
        returns (bool isSoulless, address soullessOwner)
    {
        try spiritContract.ownerOf(spiritTokenId) returns (address spiritOwner) {
            (bool participatingInQuest,,) = spiritContract.isParticipatingInQuest(spiritTokenId, address(this), SPIRIT_QUEST_ID);
            isSoulless = spiritQuestLookup[spiritTokenId].adventurer == spiritOwner && !participatingInQuest;
            soullessOwner = isSoulless ? spiritOwner : address(0);
            return (isSoulless, soullessOwner);
        } catch {}

        return (false, address(0));
    }

    /// @dev Returns a genesis token to the specified adventurer
    function returnGenesisToAdventurer(
        address adventurer,
        uint256 genesisTokenId
    )
        private
    {
        genesisContract.transferFrom(
            address(this), 
            adventurer,
            genesisTokenId);

        delete genesisQuestLookup[genesisTokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Bloodlines.sol";

/**
 * @dev Required interface of mintable hero contracts.
 */
interface IMintableHero {
    /**
     * @notice Mints a hero with a specified token id and genesis token id
     */
    function mintHero(address to, uint256 tokenId, uint256 genesisTokenId)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of a contract that complies with the adventure/quest system that is permitted to interact with an AdventureERC721.
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
    function onQuestEntered(
        address adventurer,
        uint256 tokenId,
        uint256 questId
    )
        external;

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestExited(
        address adventurer,
        uint256 tokenId,
        uint256 questId,
        uint256 questStartTimestamp
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IQuestStaking.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev An interface for ERC-721s that implement IQuestStaking
 */
interface IQuestStakingERC721 is IERC721, IQuestStaking {}

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
pragma solidity 0.8.9;

library Bloodlines {
    /// @notice 1 => Rogue, 2 => Warrior, 3 => Royal
    enum Bloodline {
        None,
        Rogue,
        Warrior,
        Royal
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
pragma solidity ^0.8.9;

import "./Quest.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IQuestStaking is IERC165 {
    /**
     * @dev Emitted when a token enters or exists a quest
     */
    event QuestUpdated(
        uint256 indexed tokenId,
        address indexed tokenOwner,
        address indexed adventure,
        uint256 questId,
        bool active,
        bool booted
    );

    /**
     * @notice Allows an authorized game contract to transfer a player's token if they have opted in
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId)
        external;

    /**
     * @notice Allows an authorized game contract to safe transfer a player's token if they have opted in
     */
    function adventureSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external;

    /**
     * @notice Allows an authorized game contract to burn a player's token if they have opted in
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(
        uint256 tokenId,
        address adventure,
        uint256 questId
    )
        external
        view
        returns (
            bool participatingInQuest,
            uint256 startTimestamp,
            uint256 index
        );

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure)
        external
        view
        returns (Quest[] memory activeQuests);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Quest {
    uint64 questId;
    uint64 startTimestamp;
}