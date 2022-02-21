// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

/// @title RaidParty Party Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "../interfaces/IParty.sol";
import "../interfaces/IDamageCalculator.sol";
import "../interfaces/IHero.sol";
import "../interfaces/IFighter.sol";
import "../interfaces/IEquipment.sol";
import "../interfaces/IHeroURIHandler.sol";
import "../interfaces/IFighterURIHandler.sol";
import "../interfaces/IEquipmentURIHandler.sol";
import "../lib/Damage.sol";

contract DamageCalculator is IDamageCalculator {
    IHero private _hero;
    IFighter private _fighter;

    uint32 private constant PRECISION = 1000;

    constructor(address hero, address fighter) {
        _hero = IHero(hero);
        _fighter = IFighter(fighter);
    }

    function getHero() external view returns (address) {
        return address(_hero);
    }

    function getFighter() external view returns (address) {
        return address(_fighter);
    }

    // getDamageComponents computes and returns a large array of damage components maintaining input ordering
    function getDamageComponents(
        uint256[] calldata heroIds,
        uint256[] calldata fighterIds
    ) external view override returns (Damage.DamageComponent[] memory) {
        // Initialize equipped array
        Damage.DamageComponent[]
            memory components = new Damage.DamageComponent[](
                heroIds.length + fighterIds.length
            );
        uint256 idx;

        idx = _getHeroComponents(components, heroIds, idx);
        idx = _getFighterComponents(components, fighterIds, idx);

        return components;
    }

    // Returns a hero damage component given an enhancement value
    function getHeroDamageComponent(uint256 hero, uint8 enhancement)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getHeroDamageComponentEnhancement(hero, enhancement);
    }

    // Returns a fighter damage component given an enhancement value
    function getFighterDamageComponent(uint256 fighter, uint8 enhancement)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getFighterDamageComponentEnhancement(fighter, enhancement);
    }

    // Returns a hero damage component
    function getHeroDamageComponent(uint256 hero)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getHeroDamageComponent(hero);
    }

    // Returns a fighter damage component
    function getFighterDamageComponent(uint256 fighter)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getFighterDamageComponent(fighter);
    }

    // Collection of internal functions to get property damage components
    function _getFighterDamageComponent(uint256 id)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.FighterStats memory fStats = IFighterURIHandler(
            _fighter.getHandler()
        ).getStats(id);

        return
            Damage.DamageComponent(
                0,
                uint32(
                    fStats.dmg +
                        _getFighterEnhancementAdjustment(
                            fStats.enhancement,
                            fStats.dmg
                        )
                )
            );
    }

    function _getHeroDamageComponent(uint256 id)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.HeroStats memory hStats = IHeroURIHandler(_hero.getHandler())
            .getStats(id);

        return
            Damage.DamageComponent(
                uint32(
                    hStats.dmgMultiplier +
                        _getHeroEnhancementMultiplier(hStats.enhancement, id)
                ),
                0
            );
    }

    // Collection of internal functions to get property damage components with caller provided enhancement values
    function _getFighterDamageComponentEnhancement(
        uint256 id,
        uint8 enhancement
    ) internal view returns (Damage.DamageComponent memory) {
        Stats.FighterStats memory fStats = IFighterURIHandler(
            _fighter.getHandler()
        ).getStats(id);

        return
            Damage.DamageComponent(
                0,
                uint32(
                    fStats.dmg +
                        _getFighterEnhancementAdjustment(
                            enhancement,
                            fStats.dmg
                        )
                )
            );
    }

    function _getHeroDamageComponentEnhancement(uint256 id, uint8 enhancement)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.HeroStats memory hStats = IHeroURIHandler(_hero.getHandler())
            .getStats(id);

        return
            Damage.DamageComponent(
                uint32(
                    hStats.dmgMultiplier +
                        _getHeroEnhancementMultiplier(enhancement, id)
                ),
                0
            );
    }

    // Collection of internal functions to return components to caller provided component array
    function _getHeroComponents(
        Damage.DamageComponent[] memory components,
        uint256[] memory heroes,
        uint256 idx
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < heroes.length; i++) {
            components[idx] = _getHeroDamageComponent(heroes[i]);
            idx += 1;
        }

        return idx;
    }

    function _getFighterComponents(
        Damage.DamageComponent[] memory components,
        uint256[] memory fighters,
        uint256 idx
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < fighters.length; i++) {
            components[idx] = _getFighterDamageComponent(fighters[i]);
            idx += 1;
        }

        return idx;
    }

    // Collection of internal functions for enhancement computations
    function _getHeroEnhancementMultiplier(uint8 enhancement, uint256 tokenId)
        internal
        pure
        returns (uint8 multiplier)
    {
        if (tokenId <= 1111 && enhancement >= 5) {
            multiplier = 4 + 3 * (enhancement - 4);
        } else if (enhancement >= 5) {
            multiplier = 4 + 2 * (enhancement - 4);
        } else {
            multiplier = enhancement;
        }
    }

    function _getFighterEnhancementAdjustment(uint8 enhancement, uint32 damage)
        internal
        pure
        returns (uint32)
    {
        if (enhancement == 0) {
            return 0;
        } else if (enhancement == 1) {
            return (160 * damage) / 100;
        } else if (enhancement == 2) {
            return (254 * damage) / 100;
        } else if (enhancement == 3) {
            return (320 * damage) / 100;
        } else if (enhancement == 4) {
            return (372 * damage) / 100;
        } else if (enhancement == 5) {
            return (414 * damage) / 100;
        } else if (enhancement == 6) {
            return (449 * damage) / 100;
        } else if (enhancement == 7) {
            return (480 * damage) / 100;
        } else if (enhancement == 8) {
            return (507 * damage) / 100;
        } else if (enhancement == 9) {
            return (532 * damage) / 100;
        } else if (enhancement == 10) {
            return (554 * damage) / 100;
        } else if (enhancement == 11) {
            return (574 * damage) / 100;
        } else if (enhancement == 12) {
            return (592 * damage) / 100;
        } else if (enhancement == 13) {
            return (609 * damage) / 100;
        } else if (enhancement == 14) {
            return (625 * damage) / 100;
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";
import "../lib/Damage.sol";

interface IDamageCalculator {
    function getDamageComponents(
        uint256[] calldata heroIds,
        uint256[] calldata fighterIds
    ) external view returns (Damage.DamageComponent[] memory);

    function getHeroDamageComponent(uint256 id, uint8 enhancement)
        external
        view
        returns (Damage.DamageComponent memory);

    function getFighterDamageComponent(uint256 id, uint8 enhancement)
        external
        view
        returns (Damage.DamageComponent memory);

    function getHeroDamageComponent(uint256 id)
        external
        view
        returns (Damage.DamageComponent memory);

    function getFighterDamageComponent(uint256 id)
        external
        view
        returns (Damage.DamageComponent memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnhanceable {
    struct EnhancementRequest {
        uint256 id;
        address requester;
    }

    event EnhancementRequested(
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    event EnhancementCompleted(
        uint256 indexed tokenId,
        uint256 indexed timestamp,
        bool success,
        bool degraded
    );

    event SeederUpdated(address indexed caller, address indexed seeder);

    function enhancementCost(uint256 tokenId)
        external
        view
        returns (uint256, bool);

    function enhance(uint256 tokenId, uint256 burnTokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IEquipmentURIHandler.sol";

interface IEquipment is IERC1155 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    function setHandler(IEquipmentURIHandler handler) external;

    function getHandler() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IEquipmentURIHandler {
    function uri(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.EquipmentStats memory);

    function updateStats(uint256 tokenId, Stats.EquipmentStats memory stats)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRaidERC721.sol";
import "./IFighterURIHandler.sol";
import "./ISeeder.sol";

interface IFighter is IRaidERC721 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    function setHandler(IFighterURIHandler handler) external;

    function getHandler() external view returns (address);

    function getSeeder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnhanceable.sol";
import "../lib/Stats.sol";

interface IFighterURIHandler is IEnhanceable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.FighterStats memory);

    function getSeeder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRaidERC721.sol";
import "./IHeroURIHandler.sol";
import "./ISeeder.sol";

interface IHero is IRaidERC721 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    function setHandler(IHeroURIHandler handler) external;

    function getHandler() external view returns (address);

    function getSeeder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnhanceable.sol";
import "../lib/Stats.sol";

interface IHeroURIHandler is IEnhanceable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.HeroStats memory);

    function getSeeder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IParty {
    event Equipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event Unequipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event DamageUpdated(address indexed user, uint32 damageCurr);

    struct PartyData {
        uint256 hero;
        mapping(uint256 => uint256) fighters;
    }

    struct Action {
        ActionType action;
        uint256 id;
        uint8 slot;
    }

    enum Property {
        HERO,
        FIGHTER
    }

    enum ActionType {
        UNEQUIP,
        EQUIP
    }

    function act(
        Action[] calldata heroActions,
        Action[] calldata fighterActions
    ) external;

    function equip(
        Property item,
        uint256 id,
        uint8 slot
    ) external;

    function unequip(Property item, uint8 slot) external;

    function enhance(
        Property item,
        uint8 slot,
        uint256 burnTokenId
    ) external;

    function getUserHero(address user) external view returns (uint256);

    function getUserFighters(address user)
        external
        view
        returns (uint256[] memory);

    function getDamage(address user) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRaidERC721 is IERC721 {
    function getSeeder() external view returns (address);

    function burn(uint256 tokenId) external;

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function mint(address owner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISeeder {
    struct SeedData {
        uint256 batch;
        bytes32 randomnessId;
    }

    event Requested(address indexed origin, uint256 indexed identifier);

    event Seeded(bytes32 identifier, uint256 randomness);

    function getIdReferenceCount(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx
    ) external view returns (uint256);

    function getIdentifiers(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx,
        uint256 count
    ) external view returns (uint256[] memory);

    function requestSeed(uint256 identifier) external;

    function getSeed(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function getSeedSafe(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function executeRequest(address origin, uint256 identifier) external;

    function executeRequestMulti() external;

    function isSeeded(address origin, uint256 identifier)
        external
        view
        returns (bool);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Damage {
    struct DamageComponent {
        uint32 m;
        uint32 d;
    }

    uint256 public constant PRECISION = 10;

    function computeDamage(DamageComponent memory dmg)
        public
        pure
        returns (uint256)
    {
        return (dmg.m * dmg.d) / PRECISION;
    }

    // This function assumes a hero is equipped after state change
    function getDamageUpdate(
        Damage.DamageComponent calldata dmg,
        Damage.DamageComponent[] calldata removed,
        Damage.DamageComponent[] calldata added
    ) public pure returns (Damage.DamageComponent memory) {
        Damage.DamageComponent memory updatedDmg = Damage.DamageComponent(
            dmg.m,
            dmg.d
        );

        for (uint256 i = 0; i < removed.length; i++) {
            updatedDmg.m -= removed[i].m;
            updatedDmg.d -= removed[i].d;
        }

        for (uint256 i = 0; i < added.length; i++) {
            updatedDmg.m += added[i].m;
            updatedDmg.d += added[i].d;
        }

        return updatedDmg;
    }

    // This function assumes a hero is equipped after state change
    function getDamageUpdate(
        Damage.DamageComponent calldata dmg,
        Damage.DamageComponent calldata removed,
        Damage.DamageComponent calldata added
    ) public pure returns (Damage.DamageComponent memory) {
        Damage.DamageComponent memory updatedDmg = Damage.DamageComponent(
            dmg.m,
            dmg.d
        );

        updatedDmg.m -= removed.m;
        updatedDmg.d -= removed.d;

        updatedDmg.m += added.m;
        updatedDmg.d += added.d;

        return updatedDmg;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Stats {
    struct HeroStats {
        uint8 dmgMultiplier;
        uint8 partySize;
        uint8 enhancement;
    }

    struct FighterStats {
        uint32 dmg;
        uint8 enhancement;
    }

    struct EquipmentStats {
        uint32 dmg;
        uint8 dmgMultiplier;
        uint8 slot;
    }
}